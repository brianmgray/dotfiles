#!/bin/zsh

#######
# Helper script to automate setting up and updating a dev environment
#######

autoload -U colors && colors

# constants
JAVA_VERSION=21\.0\.2
NODE="^(v20.11|v18.19)$"
NPM=10.3
BREW_APPS=('azure-cli' 'jq')
CASK_APPS=('iterm2' 'webstorm' 'azure-cli')
ANGULAR_LIBS=('@angular/cli' 'pnpm' '@aws-amplify/cli' 'aws-amplify' 'aws-amplify-angular' 'typescript')  #skipped
NPM_GLOBAL_LIBS=('pnpm' 'typescript' '@azure/static-web-apps-cli')
THEME_FONTS=('MesloLGS%20NF%20Regular.ttf' 'MesloLGS%20NF%20Bold.ttf' 'MesloLGS%20NF%20Italic.ttf' 'MesloLGS%20NF%20Bold%20Italic.ttf')

typeset -A ZSH_PLUGINS=(
  'zsh-nvm' 'https://github.com/lukechilds/zsh-nvm'
  'azure-cli' 'git@github.com:Azure/azure-cli.git'
)

typeset -A STEP_FUNCTIONS=(
  'brew' brew_setup
  'apps' apps_setup
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
    expected="chezmoi"
    actual=$(which chezmoi | grep -Eo 'chezmoi')
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

    ## fonts
    print_message "\toh-my-zsh fonts..." yellow
    fonts_src="https://github.com/romkatv/powerlevel10k-media/raw/master/"
    fonts_dir=/Library/Fonts/
    for font in "${THEME_FONTS[@]}"; do
      expected="${font}"
      actual=$(ls "${fonts_dir}" | grep -F "${font}")
      run_if_needed "\ttheme font $font" "$expected" "$actual" "curl -sSL \"${fonts_src}${font}\" -o \"${fonts_dir}${expected}\""
    done

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

    ## update
    print_message "\toh-my-zsh version..." yellow
    expected="master"
    actual=$(zsh -i -c "omz version | cut -c -6")                   # master (d43f03b)
    run_if_needed "\t\toh-my-zsh" "$expected" "$actual" "omz update && omz reload"
}

function java_setup() {
    # jenv/java
    print_message "setting up jenv..." yellow
    expected="Jenv is correctly loaded"
    actual=$(zsh -i -c "jenv doctor" | grep -Eo 'Jenv is correctly loaded' )
    run_if_needed "jenv" "$expected" "$actual" "brew install jenv"

    print_message "setting up java..." yellow
    expected="$JAVA_VERSION"
    actual=$(jenv versions | grep -Eo "$JAVA_VERSION" | head -n 1 )
    run_if_needed "java" "$expected" "$actual" "brew install openjdk \
      brew pin openjdk \
      sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk \
      jenv add /Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home/ \
      jenv global 21
      "
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
    actual=$(zsh -i -c "nvm current | grep -Eo '[0-9]+\.[0-9]+'")
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

function apps_setup() {
    print_message "setting up apps..." yellow
    for app in $BREW_APPS; do
      expected=${app}
      actual=$(brew list | grep ${app})
      run_if_needed "app" "$expected" "$actual" "brew install ${app}"
    done
    for app in $CASK_APPS; do
      expected=${app}
      actual=$(brew list | grep ${app})
      run_if_needed "app" "$expected" "$actual" "brew install --cask ${app}"
    done
}

function help() {
  echo "Invalid arguments passed. Usage:
    setup [--dry-run] [--brew] [-apps] [--zsh] [--core] [--java] [--docker] [--node]"
  exit 1
}

function run() {
  # define the steps in order with enabled flags
  typeset -A steps=(
  )

  # parse flags
  while [[ "$#" -gt 0 ]]
    do
      case $1 in
        -d|--dry-run) flag_dry_run=true;;
        -b|--brew) steps[brew]=true;;
        -p|--apps) steps[apps]=true;;
        -c|--core) steps[core]=true;;
        -z|--zsh) steps[zsh]=true;;
        -j|--java) steps[java]=true;;
        -d|--docker) steps[docker]=true;;
        -n|--node) steps[node]=true;;
        -a|--all)
            steps[brew]=true
            steps[apps]=true
            steps[core]=true
            steps[zsh]=true
            steps[java]=true
            steps[docker]=true
            steps[node]=true
            ;;
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
