#!/bin/zsh

#######
# Helper script to automate setting up and updating a dev environment
#######

autoload -U colors && colors

# constants
NODE="^(v20.11.0|v18.19.1)$"
NPM=10.3
ANGULAR_LIBS=('@angular/cli' 'pnpm' '@aws-amplify/cli' 'aws-amplify' 'aws-amplify-angular' 'typescript')  #skipped
NPM_GLOBAL_LIBS=('pnpm' 'typescript')

typeset -A ZSH_PLUGINS=(
  'zsh-nvm' 'https://github.com/lukechilds/zsh-nvm'
  'azure-cli' 'git@github.com:Azure/azure-cli.git'
)

typeset -A STEP_FUNCTIONS=(
  'brew' brew_setup
  'zsh' zsh_setup
  'core' core_setup
  'java' java_setup
  'docker' docker_setup
  'node' node_setup
)

# global flags
flag_dry_run=false

function print_message() {
    local message="$1"
    local color_code="${2:-black}"
    echo $fg[$color_code]$message$reset_color
}

function run_if_needed() {
    local name=$1
    local expected=$2
    local actual=$3
    local command=$4
    
    if [[ "$expected" =~ "$actual" ]]; then
        print_message "\t$name: Verified correct version [$actual]" green
    else
        print_message "\t$name: Incorrect version. Expected [$expected]. Using [$actual]. Running command." red
        if [[ $flag_dry_run != true ]]; then
          zsh -i -c "$command"    # some tools (e.g. omz) are only loaded in the interactive shell
        fi
        print_message "\t$name: Success."
    fi
}

###
# upgrade brew and dependencies
###
function brew_setup() {
    print_message "updating brew..." yellow
    if [[ $flag_dry_run != true ]]; then
      brew update -v
      brew upgrade && brew upgrade --cask && brew cleanup
    fi
}

###
# Always required
###
function core_setup() {
    # git
    print_message "setting up git..." yellow
    expected=$(brew list --versions git | cut -c 5-)    # git 2.43.0
    actual=$(git --version | cut -c 13-)                # git version 2.43.0
    run_if_needed git "$expected" "$actual" "brew install git git-gui"

    # chezmoi
    print_message "setting up chezmoi..." yellow
    expected="/usr/local/bin/chezmoi"
    actual=$(which chezmoi)
    run_if_needed "chezmoi" "$expected" "$actual" "brew install chezmoi"

    # act
    print_message "setting up act..." yellow
    expected="0.2.60"
    actual=$(act --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')  # act version 0.2.60
    run_if_needed "act" "$expected" "$actual" "brew install act"
}

###
# Zsh, themes, plugins
###
function zsh_setup() {
    print_message "setting up oh-my-zsh..." yellow

    ## install
    print_message "\toh-my-zsh..." yellow
    if [[ ! -f "$ZSH/oh-my-zsh.sh" ]]; then
      print_message "\t\toh-my-zsh: running installer" red
      if [[ $flag_dry_run != true ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
      fi
    fi

    ## update
    print_message "\toh-my-zsh version..." yellow
    expected="master"
    actual=$(zsh -i -c "omz version" | cut -c -6)                   # master (d43f03b)
    run_if_needed "\t\toh-my-zsh" "$expected" "$actual" "omz update && omz reload"

    ## theme
    print_message "\toh-my-zsh theme..." yellow
    theme_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    if [[ ! -d "$theme_dir" ]]; then
      print_message "\t\toh-my-zsh theme not found, pulling..." red
      if [[ $flag_dry_run != true ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
      fi
    fi

    ## plugins
    print_message "\toh-my-zsh plugins..." yellow
    plugin_root_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins
    for name repo in "${(@kv)ZSH_PLUGINS}"; do
      plugin_dir=${plugin_root_dir}/$name
      if [[ ! -d "$plugin_dir" ]]; then
        print_message "\t\tinstalling plugin ${name}" red
        if [[ $flag_dry_run != true ]]; then
          git clone --depth=1 $repo $plugin_dir
        fi
      fi
    done
}

function java_setup() {
    # jenv/java
    print_message "setting up jenv..." yellow
    expected="Jenv is correctly loaded"
    actual=$(zsh -i -c "jenv doctor" | grep -Eo 'Jenv is correctly loaded' )
    run_if_needed "jenv" "$expected" "$actual" "brew install jenv"
}

function docker_setup() {
    print_message "setting up docker..." yellow
    expected="25.0.3"
    actual=$(docker --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')                    # Docker version 25.0.3, build 4debf41
    run_if_needed "brew" "$expected" "$actual" "brew install docker --cask"
}

function node_setup() {
    # nvm
    print_message "setting up nvm..." yellow
    # Check if NVM is installed
    NVM_PATH="$HOME/.nvm/nvm.sh"
    if [ ! -f "$NVM_PATH" ]; then
      print_message "nvm not installed, pulling" red
      if [[ $flag_dry_run != true ]]; then
        PROFILE=/dev/null zsh -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
      fi
    fi
    expected="$NODE"
    actual=$(zsh -i -c "nvm current")
    run_if_needed "nvm" "$expected" "$actual" \
        "nvm install $NODE && \
         nvm alias default $NODE && \
         npm install npm@$NPM"

    print_message "setting up global npm libs..." yellow
    for lib in $NPM_GLOBAL_LIBS; do
      if npm list -g "$lib" | grep -q "(empty)"; then
        print_message "\t$lib not installed, installing..." red
        if [[ $flag_dry_run != true ]]; then
          npm install -g "$lib"
          if [[ lib == "pnpm" ]]; then pnpm setup; fi
        fi
      fi
    done
    unset lib
}

function help() {
  echo "Invalid arguments passed. Usage:
    setup [--dry-run] [--brew] [--zsh] [--core] [--java] [--docker] [--node]"
  exit 1
}

function run() {
  # define the steps in order with enabled flags
  typeset -A steps=(
    'brew'   false
    'core'   false
    'zsh'    false
    'java'   false
    'docker' false
    'node'   false
  )

  # parse flags
  while [[ "$#" -gt 0 ]]
    do
      case $1 in
        -d|--dry-run) flag_dry_run=true;;
        -b|--brew) steps[brew]=true;;
        -c|--core) steps[core]=true;;
        -z|--zsh) steps[zsh]=true;;
        -j|--java) steps[java]=true;;
        -d|--docker) steps[docker]=true;;
        -n|--node) steps[node]=true;;
        *) help
      esac
      shift
    done

  # execute each enabled step
  for key val in "${(@kv)steps}"; do
    if [[ $val == true ]];
    then
      eval "$STEP_FUNCTIONS[$key]"
    fi
  done

  # zsh -i -c "omz reload"
  print_message "Successfully setup new environment" green
}

run $@
