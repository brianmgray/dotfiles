#!/env zsh

# utilities
alias name='hostname -f | tee /dev/tty | pbcopy'
alias kexternal="lsof | grep /Volumes/BG\ Archive | awk '{print(\$2)}'  | xargs -I '{}' kill {}"
alias kbackup="lsof | grep /Volumes/BG\ Backup | awk '{print(\$2)}'  | xargs -I '{}' kill {}"
alias ktm="lsof | grep /Volumes/BGTimeMachine | awk '{print(\$2)}'  | xargs -I '{}' kill {}"
alias spacer="defaults write com.apple.dock persistent-apps -array-add '{tile-data={}; tile-type="spacer-tile";}' && killall Dock"

# convenience commands
alias netlify='npx netlify'
# alias ng='node node_modules/.bin/ng'
# alias act='act --container-architecture linux/amd64'

# environment files
ALIASES="$ZSH_CUSTOM/10-global-aliases.zsh"
alias ea='chezmoi edit --apply $ALIASES && omz reload'
alias fa='less $ALIASES | grep'
alias setup='$(chezmoi source-path)/bin/new-env.sh'
alias cp-to-envfiles='~/workspaces/environment-files/bin/cp-to-envfiles'
alias cp-from-envfiles='~/workspaces/environment-files/bin/cp-from-envfiles'

# dirs
alias dcc='~/workspaces/RainyMrGab/comedy-connector'

## fugu
FUGU_CORE=~/workspaces/fuguUX/core
alias create='$FUGU_CORE/tools/azure/deployment/create_azure_environment.sh'
alias rcreate='./tools/azure/deployment/create_azure_environment.sh'
alias redeployj='$FUGU_CORE/apps/processors/scripts/redeploy-java.sh --stack=brian'
alias redeployr='$FUGU_CORE/apps/processors/scripts/redeploy-rust.sh --stack=brian --target=image --all_binaries'
alias redeployf='create --force=frontend,redeploy --resources=redeploy'

alias df='~/workspaces/fuguUX'
alias dfc='$FUGU_CORE'
alias dff='$FUGU_CORE/apps/frontend'
alias dfa='$FUGU_CORE/apps/processors/processor_analyzer'
alias dfh='$FUGU_CORE/apps/ml/heuristics'
alias dft='$FUGU_CORE/tools'
alias dfo='$FUGU_CORE/org'
alias dfr='$FUGU_CORE/releases'

alias dfs='~/workspaces/fuguUX/scripting'
alias dfpr='~/workspaces/fuguUX/pr'

# frontend
alias prb='pnpm run build'
alias prd='pnpm run dev'
alias dcheck='pnpm run clean && pnpm run lint && pnpm run build && pnpm run dev && pnpm outdated > outdated.log'

# brian
alias dns='~/workspaces/brian/next-sandbox'

## admin
alias denv='~/workspaces/environment-files'

# Tool Aliases
alias pnpm='npx pnpm'

## Azure
alias azl='az login'
alias azs='az account set --subscription $AZ_SUBSCRIPTION_ID'

## npm
alias no='npm outdated'
alias nds='npm update --save'
alias ndd='npm update -D'
alias nis='npm install --save'
alias nid='npm install -D'
alias nus='npm uninstall --save'

## Docker
alias dk='docker'
alias dki='docker images'
alias dkl='docker logs'
alias dklf='docker logs -f'
alias dkps='docker ps --format "{{.ID}} - {{.Names}} - {{.Status}} - {{.Image}}"'
dkln() {
  docker logs -f `docker ps | grep $1 | awk '{print $1}'`
}
alias dkb='docker build -t ${(L)${PWD##*/}} .'
alias dkr='docker run -it -p 8080:8080 ${(L)${PWD##*/}}:latest'
alias dkri='docker run -it ${(L)${PWD##*/}}:latest /bin/bash'
alias dkbr='dkb && dkr'

alias dkip='dk image prune -a --filter "until=24h"'
alias dkcp='dk container prune --filter "until=24h"'
alias dkvp='dk volume prune --filter "label!=keep"'
alias dksp='docker system prune --volumes'

alias dc='docker-compose'
alias dcu='dc up'
alias dcb='dc up --build'
alias dcd'=dc down'
alias dcr='dc run'

## Python
alias pip='pip3'
alias python='python3'
alias python36='/Library/Frameworks/Python.framework/Versions/3.6/bin/python3'
alias python37='/Library/Frameworks/Python.framework/Versions/3.7/bin/python3'

## mvn
alias mi='mvn install'

## github
alias ghcl='gh cache list'
alias ghcd='gh cache delete'

# git

# system aliases
# alias vi='vim' # included in git
# alias reboot='shutdown /r'

#### colors (from mac-dev-setup)

# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
  colorflag="--color"
else # macOS `ls`
  colorflag="-G"
fi

# List all files colorized in long format, including dot files
alias ll="ls -alF ${colorflag}"

# List all files colorized in long format
# alias la="ls -laF ${colorflag}"
alias la="ls -A ${colorflag}"

# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"

# Always use color output for `ls`
alias ls="command ls ${colorflag}"
export LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'


### Functions

function applydb() {
  # Fetch all remote branches
  git fetch --all

  # Get the list of remote branches that start with 'dependabot/npm_and_yarn/'
  branches=$(git branch -r | grep 'origin/dependabot/npm_and_yarn/')

  # Iterate through each branch
  for branch in $branches; do
    # Strip the 'origin/' prefix from the branch name
    branch_name=${branch#origin/}

    # Attempt to merge the branch into the current branch
    echo "Merging $branch_name into the current branch..."
    git merge --no-ff --no-commit -X theirs $branch_name

    # Check if the merge was successful
    if [[ $? -ne 0 ]]; then
      echo "Conflict detected in $branch_name. Attempting to resolve automatically..."
      git merge --abort
      git merge -X theirs $branch_name

      if [[ $? -ne 0 ]]; then
        echo "Could not merge $branch_name automatically. Please resolve manually."
        echo $branch_name >> merge_failures.txt
      else
        echo "Successfully merged $branch_name with automatic conflict resolution."
        git commit -m "Merged $branch_name with automatic conflict resolution"
      fi
    else
      echo "Successfully merged $branch_name."
      git commit -m "Merged $branch_name"
    fi
  done

  # Output branches that could not be merged
  if [[ -f merge_failures.txt ]]; then
    echo "The following branches could not be merged automatically:"
    cat merge_failures.txt
    rm merge_failures.txt
  else
    echo "All branches merged successfully."
  fi
}

