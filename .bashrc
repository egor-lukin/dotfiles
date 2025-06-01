# load env vars
export $(cat ~/dotfiles/.env | xargs)

  # echo env/$key | xargs -I % export "$key=$(pass show "%")"
# for key in $(pass ls env | grep -v '^env$' | awk '{print $2}'); do
#   echo env/$key | xargs -I % pass show "%" | echo "$key=$(pass show "%")"
# done

# for key in $(pass ls env | grep -v '^env$' | awk '{print $2}'); do
#   echo "$key=$(pass show env/$key)"
# done

export OPENAI_API_KEY=$(pass show env/OPENAI_API_KEY)
export GEMINI_API_KEY=$(pass show env/GEMINI_API_KEY)
export ANTHROPIC_API_KEY=$(pass show env/ANTHROPIC_API_KEY)


export EDITOR="emacsclient -r"

#git
alias g='git'
alias gc='git commit'
alias gs='git status'
alias gco='git checkout'
alias gap='git add -p'
alias gsl='git stash list'
alias gaa='git add .; git commit --amend --no-edit'

# Grep with color
alias grep='grep --color=auto '

alias pbcopy='xsel --clipboard --input'

alias enw='emacs -nw'
alias se='eval `ssh-agent`'

## History configuration
# Appending history instead of rewriting
shopt -s histappend

# Ignore duplicates while appending and erase duplicates from old history
HISTCONTROL=ignoredups:erasedups

# Ignore aliases and some other patterns when write history
HISTIGNORE="$(alias | cut -d' ' -f2 | cut -d'=' -f1 | tr '\n' ':')[bf]g:exit:pwd:ls:cd:vi"

# Show unstaged (*) and staged (+) changes next to the branch name.
GIT_PS1_SHOWDIRTYSTATE=1
# If something is stashed, then a '$' will be shown next to the branch name.
GIT_PS1_SHOWSTASHSTATE=1
# If there're untracked files, then a '%' will be shown next to the branch name.
GIT_PS1_SHOWUNTRACKEDFILES=1
# Show the difference between HEAD and its upstream with number of commits ahead/behind (+/-) upstream
GIT_PS1_SHOWUPSTREAM="auto verbose"

alias __git_ps1="git branch 2>/dev/null | grep '*' | sed 's/* \(.*\)/(\1)/'"

set_prompt () {
    orange='\[\033[0;33m\]'
    reset='\[\e[00m\]'
    PS1="$(__git_ps1) \A $orange\W\$$reset "
}
PROMPT_COMMAND=set_prompt

export VISUAL="vim"
export PATH=$HOME/bin:$PATH
export PATH="/home/azx/Projects:${PATH}"
export PATH=$HOME/.local/bin:$PATH
export PATH=~/.npm-global/bin:$PATH

export GEM_HOME="$HOME/.gems"
export GEM_PATH="$GEM_HOME:/var/lib/ruby/gems/3.0"

export PATH=/usr/local/bin/rvm/bin:$PATH

export PATH=$GEM_HOME/bin:$PATH

export FLYCTL_INSTALL="/home/azx/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

export PATH=~/.fly/bin:$PATH
export KUBECONFIG=$HOME/.kube/config

export PATH=/home/azx/.gems/bin:$PATH

export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

export TERM=xterm-256color

# asdf
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash

# Automatically added by the Guix install script.
if [ -n "$GUIX_ENVIRONMENT" ]; then
    if [[ $PS1 =~ (.*)"\\$" ]]; then
        PS1="${BASH_REMATCH[1]} [env]\\\$ "
    fi
fi
