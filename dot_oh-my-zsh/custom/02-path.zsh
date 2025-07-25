#!/env zsh

# Setup path
OLD_PATH=$PATH
PATH_PIECES=(
  $HOME/.jenv/bin
  # $PYENV_ROOT/bin
  # $PYTHON_VERSION/bin
  # $PYTHON_PACKAGES
  $HOME/go/bin
  $HOME/.local/bin
  $OLD_PATH
  ~/Applications/brew/bin
)

# build path from array
path=""
for piece in "${PATH_PIECES[@]}"
do
  path="$path:$piece"
done
export PATH=$path

# initialize jenv
eval "$(jenv init -)"
