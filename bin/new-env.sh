#!/bin/zsh
# Run to setup new environment

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
        eval "$command"
        print_message "\t$name: Success."
    fi
}

function run() {
    # upgrade brew and dependencies
    print_message "updating brew..." yellow
    # brew update -v
    # brew upgrade && brew upgrade --cask && brew cleanup

    # git
    print_message "setting up git..." yellow
    expected=$(brew list --versions git | cut -c 5-)    # git 2.43.0
    actual=$(git --version | cut -c 13-)                # git version 2.43.0
    run_if_needed git "$expected" "$actual" "brew install git"

    # zsh
    print_message "setting up oh-my-zsh..." yellow
    expected="master"
    actual=$(omz version | cut -c -6)                   # master (d43f03b)
    run_if_needed "oh-my-zsh" "$expected" "$actual" "omz update"

    # zsh theme
    theme_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    if [[ ! -d "$directory_path" ]]; then
      echo "oh-my-zsh theme not found, pulling..."
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
    fi

    # nvm
    print_message "setting up nvm..." yellow
    # Check if NVM is installed
    NVM_PATH="$HOME/.nvm/nvm.sh"
    if [ ! -f "$NVM_PATH" ]; then
      PROFILE=/dev/null zsh -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | zsh'
    fi
    latest_stable_version=$(nvm version-remote --lts)
    current_version=$(nvm current)
    run_if_needed nvm "$latest_stable_version" "$current_version" "nvm install --lts && nvm install-latest-npm"

    # chezmoi
    print_message "setting up chezmoi..." yellow
    expected="/usr/local/bin/chezmoi"
    actual=$(which chezmoi)
    run_if_needed "chezmoi" "expected" "actual" "brew install chezmoi"

    print_message "Successfully setup new environment" green
}

run