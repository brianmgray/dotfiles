#!/env zsh

# Setup path
OLD_PATH=$PATH
PATH_PIECES=(
  # $PYENV_ROOT/bin
  # $PYTHON_VERSION/bin
  # $PYTHON_PACKAGES
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

