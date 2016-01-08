#Alias erzeugen $HOME/.bashrc
#for shared with dropbox for private config
if [ -f $HOME/Dropbox/bash/bashrc_local ]; then
  source $HOME/Dropbox/bash/bashrc_local
fi

if [ -f "$HOME/.DOTFILE" ]; then
  source "$HOME/.DOTFILE"
else
  echo "DOTFILE not exits"
fi

if [ -n "${DOTFILESPATH+x}" ]; then
  export DOTFILE=$DOTFILESPATH
else
  echo "DOTFILESPATH not exits"
fi

if [ -f $DOTFILESPATH/bash/aliases   ]; then
  source $DOTFILESPATH/bash/aliases
fi


FILES=$DOTFILE/bash/*
for f in $FILES
do
   source $f
done


#for special alias path etc...
if [ -f $HOME/.bashrc_local ]; then
  source $HOME/.bashrc_local
else
  echo "not exits ' $HOME/.bashrc_local'"
fi

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*


### Added by the Heroku Toolbelt
#export PATH="/usr/local/heroku/bin:$PATH"
#export PATH="/Users/deimel/entwicklung/projects/prchecker/bin:$PATH"
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
