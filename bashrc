#Alias erzeugen ~/.bashrc  
#for shared with dropbox for private config   


#aliases and functions  
if [ -f ~/bin/dotfiles/bash/env   ]; then
  source ~/bin/dotfiles/bash/env  
else
  echo "not exits '~/bin/dotfiles/bash/env'"
fi   

if [ -f ~/bin/dotfiles/bash/prompt   ]; then
  source ~/bin/dotfiles/bash/prompt  
else
  echo "not exits '~/bin/dotfiles/bash/prompt'"
fi

if [ -f ~/bin/dotfiles/bash/aliases   ]; then
  source ~/bin/dotfiles/bash/aliases  
else
  echo "not exits '~/bin/dotfiles/bash/aliases'"
fi
 
if [ -f ~/bin/dotfiles/bash/motd ]; then 
  source ~/bin/dotfiles/bash/motd
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
