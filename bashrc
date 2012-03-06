#Alias erzeugen ~/.bashrc  
#for shared with dropbox for private config   


if [ -f ~/entwicklung/miceportal/git/dotfiles/bash/env   ]; then
  source ~/entwicklung/miceportal/git/dotfiles/bash/env   
else
  echo "not exits '~/entwicklung/miceportal/git/dotfiles/bash/env'"
fi  


if [ -f ~/entwicklung/miceportal/git/dotfiles/bash/config   ]; then
  source ~/entwicklung/miceportal/git/dotfiles/bash/config   
else
  echo "not exits '~/entwicklung/miceportal/git/dotfiles/bash/config'"
fi   

if [ -f ~/entwicklung/miceportal/git/dotfiles/bash/aliases   ]; then
  source ~/entwicklung/miceportal/git/dotfiles/bash/aliases   
else
  echo "not exits '~/entwicklung/miceportal/git/dotfiles/bash/aliases'"
fi

##aliases and functions
. ~/bin/dotfiles/bash/env
. ~/bin/dotfiles/bash/config
. ~/bin/dotfiles/bash/aliases
if [ "$OS" = "darwin" ] ; then
. ~/bin/dotfiles/bash/motd
else
  echo "not exits '~/bin/dotfiles/bash/motd'"
fi

#for shared with dropbox for private config
if [ -f ~/Dropbox/bash/bashrc_local ]; then
  source ~/Dropbox/bash/bashrc_local 
else
  echo "not exits '~/Dropbox/bash/bashrc_local'"
fi

#for special alias path etc...
if [ -f ~/.bashrc_local ]; then
  source ~/.bashrc_local
else
  echo "not exits ' ~/.bashrc_local'"
fi

if [ -f ~/bin/dotfiles/bash/radio ]; then
  source ~/bin/dotfiles/bash/radio
fi
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
