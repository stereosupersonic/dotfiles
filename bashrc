#Alias erzeugen ~/.bashrc
##aliases and functions

. ~/bin/dotfiles/bash/env
. ~/bin/dotfiles/bash/config
. ~/bin/dotfiles/bash/aliases
if [ "$OS" = "darwin" ] ; then
. ~/bin/dotfiles/bash/motd
fi
#for special alias path etc...
if [ -f ~/.bashrc_local ]; then
  source ~/.bashrc_local
fi

if [ -f ~/bin/dotfiles/bash/radio ]; then
  source ~/bin/dotfiles/bash/radio
fi

