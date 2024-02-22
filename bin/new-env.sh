#!/bin/zsh
# Run to setup new environment

# constants
NODE=v20.11.0
NPM=10.3
ANGULAR_LIBS=('@angular/cli' 'pnpm' 'nx' '@aws-amplify/cli' 'aws-amplify' 'aws-amplify-angular' 'serverless' 'typescript')

autoload -U colors && colors

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
    run_if_needed git "$expected" "$actual" "brew install git"

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

    # chezmoi
    print_message "setting up chezmoi..." yellow
    expected="/usr/local/bin/chezmoi"
    actual=$(which chezmoi)
    run_if_needed "chezmoi" "$expected" "$actual" "brew install chezmoi"
}

function angular_setup() {
    print_message "setting up angular global libs..." yellow
    for lib in $ANGULAR_LIBS; do
      if npm list -g "$lib" | grep -q "(empty)"; then
        print_message "\t$lib not installed, installing..." red
        npm install -g "$lib"
      fi
    done;
    unset lib;
}

function run() {
    brew_setup
    core_setup
    angular_setup

    zsh -i -c "omz reload"
    print_message "Successfully setup new environment" green
}

run
