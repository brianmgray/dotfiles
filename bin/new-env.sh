#!/bin/zsh

#######
# Helper script to automate setting up and updating a dev environment
#######

# constants
NODE=v20.11.0
NPM=10.3
ANGULAR_LIBS=('@angular/cli' 'pnpm' '@aws-amplify/cli' 'aws-amplify' 'aws-amplify-angular' 'typescript')  #skipped
NPM_GLOBAL_LIBS=('pnpm' 'typescript')

autoload -U colors && colors

typeset -A STEP_FUNCTIONS=(
  'brew' brew_setup
  'core' core_setup
  'java' java_setup
  'docker' docker_setup
  'node' node_setup
)

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
    
    if [ "$2" = "$3" ]; then
        print_message "\t$name: Verified correct version [$actual]" green
    else
        print_message "\t$name: Incorrect version. Expected [$expected]. Using [$actual]. Running command." red
        zsh -i -c "$command"    # some tools (e.g. omz) are only loaded in the interactive shell
        print_message "\t$name: Success."
    fi
}

###
# upgrade brew and dependencies
###
function brew_setup() {
    print_message "updating brew..." yellow
    brew update -v
    brew upgrade && brew upgrade --cask && brew cleanup
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

    # zsh
    print_message "setting up oh-my-zsh..." yellow
    ## install
    if [[ ! -f "$ZSH/oh-my-zsh.sh" ]]; then
      print_message "\toh-my-zsh: running installer" red
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    ## update
    expected="master"
    actual=$(zsh -i -c "omz version" | cut -c -6)                   # master (d43f03b)
    run_if_needed "oh-my-zsh" "$expected" "$actual" "omz update && omz reload"
    ## theme
    theme_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    if [[ ! -d "$theme_dir" ]]; then
      echo "oh-my-zsh theme not found, pulling..."
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
    fi

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
      PROFILE=/dev/null zsh -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
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
        npm install -g "$lib"
        if [[ lib == "pnpm" ]]; then pnpm setup; fi
      fi
    done
    unset lib
}

function help() {
  echo "Invalid arguments passed. Usage:
    setup [--skip-brew] [--skip-core] [--skip-java] [--skip-docker] [--skip-node]"
  exit 1
}

function run() {
  # define the steps in order with enabled flags
  typeset -A steps=(
    'brew' true
    'core' true
    'java' true
    'docker' true
    'node' true
  )

  # parse flags
  while [[ "$#" -gt 0 ]]
    do
      case $1 in
        -sb|--skip-brew) steps[brew]=false;;
        -sc|--skip-core) steps[core]=false;;
        -sj|--skip-java) steps[java]=false;;
        -sd|--skip-docker) steps[docker]=false;;
        -sn|--skip-node) steps[node]=false;;
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

  zsh -i -c "omz reload"
  print_message "Successfully setup new environment" green
}

run $@
