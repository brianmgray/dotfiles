#!/bin/zsh
# Run to setup new environment

function verify() {
    name=$1
    expected=$2
    actual=$3
    
    if [ "$2" = "$3" ]; then
        echo "Verified correct version for $name [$actual]"
    else
        echo "Incorrect version for $name. Expected [$expected]. Using [$actual]"
        exit 1
    fi
}

function run() {
    # upgrade brew and dependencies
    echo "updating brew..."
    brew update -v 
    brew upgrade 
    brew upgrade --cask 
    brew cleanup                                                                  SIGINT(2) ↵  1681  12:36:52

    # git
    echo "setting up git..."
    brew install git
    expected=$(brew list --versions git | cut -c 5-)    # git 2.43.0
    actual=$(git --version | cut -c 13-)                # git version 2.43.0
    verify git $expected $actual

    # nvm
    # pulled automatically by oh-my-zsh
    echo "setting up chezmoi..."
    nvm install --lts                                   # install long-term stable version
    nvm install-latest-npm
    # verify later

    # chezmoi
    echo "setting up chezmoi..."
    brew install chezmoi



    echo "Successfully setup new environment"
}

run