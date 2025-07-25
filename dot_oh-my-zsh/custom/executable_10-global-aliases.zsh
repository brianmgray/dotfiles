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
alias create='caffeinate -i -s $FUGU_CORE/tools/azure/deployment/create_azure_environment.sh'
alias rcreate='caffeinate -i -s ./tools/azure/deployment/create_azure_environment.sh'
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

applydb() {
  # Get the current branch name
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  # Find all remote branches with the prefix dependabot/npm_and_yarn
  remote_branches=()
    while IFS= read -r branch; do
      remote_branches+=("$branch")
    done < <(git branch -r | grep 'origin/dependabot/npm_and_yarn')

  # Initialize an array to keep track of branches that couldn't be applied
  failed_branches=()

  # Loop through each remote branch and apply its changes
  git fetch origin
  for branch in "${remote_branches[@]}"; do
    branch=$(echo "$branch" | sed 's|refs/heads/||')
    echo "BRANCH=$branch..."

#    echo "Applying changes from $branch..."
    base_commit=$(git merge-base main $branch)
    git cherry-pick --strategy=recursive -X theirs $base_commit..$branch
#    if [[ $? -ne 0 ]]; then
#      git diff --name-only --diff-filter=U | grep -E 'package-lock.json|pnpm-lock.yaml' | xargs git update-index --skip-worktree
#      if [[ $? -ne 0 ]]; then
#        echo "Failed to apply changes from $branch"
#        failed_branches+=($branch)
#        git cherry-pick --abort
#      else
#        git commit -m "Merged changes from $branch with conflicts resolved"
#      fi
#    else
#      git commit -m "Merged changes from $branch"
#    fi
  done

  # Switch back to the original branch
  git checkout "$current_branch"

  # Output the branches that couldn't be applied
  if [[ ${#failed_branches[@]} -ne 0 ]]; then
    echo "The following branches couldn't be applied:"
    for branch in $failed_branches; do
      echo $branch
    done
  fi
}

curl_with_redirects() {
  curl -Ls -o /dev/null -w $'Final URL: %{url_effective}\n' -D - "$1" | awk '
    BEGIN { redirects = 0 }
    tolower($1) == "location:" { redirects++; print }
    tolower($1) == "link:" { print }
    /^Final URL:/ { final = $0 }
    END {
      if (final) print final;
      print "Number of redirects followed:", redirects;
    }
  '
}

