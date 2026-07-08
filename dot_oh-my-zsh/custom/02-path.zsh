#!/env zsh

# pnpm has to go AFTER nvm which has been setup elsewhere
export PNPM_HOME="$HOME/Library/pnpm"

# Setup path
OLD_PATH=$PATH
PATH_PIECES=(
  $HOME/.jenv/bin
  # $PYENV_ROOT/bin
  # $PYTHON_VERSION/bin
  # $PYTHON_PACKAGES
  $HOME/go/bin
  $HOME/.local/bin
  ~/.npm-global/bin
  /opt/homebrew/opt/libpq/bin
  $OLD_PATH
  $PNPM_HOME
  ~/Applications/brew/bin
)

# build path from array
path=""
for piece in "${PATH_PIECES[@]}"
do
  path="$path:$piece"
done
export PATH=$path

# pnpm - needed for pnpm env
# export PNPM_HOME="/Users/brian/Library/pnpm"
# case ":$PATH:" in
#   *":$PNPM_HOME:"*) ;;
#   *) export PATH="$PNPM_HOME:$PATH" ;;
# esac
# pnpm end

# initialize jenv
eval "$(jenv init -)"
