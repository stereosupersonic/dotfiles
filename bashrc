#Alias erzeugen ~/.bashrc  
#for shared with dropbox for private config   


#load miceportal settings
if [ -f ~/entwicklung/miceportal/git/dotfiles/bash/env   ]; then
  source ~/entwicklung/miceportal/git/dotfiles/bash/env   
else
  #echo "not exits '~/entwicklung/miceportal/git/dotfiles/bash/env'"
fi   

if [ -f ~/entwicklung/miceportal/git/dotfiles/bash/config   ]; then
  source ~/entwicklung/miceportal/git/dotfiles/bash/config   
else
  #echo "not exits '~/entwicklung/miceportal/git/dotfiles/bash/config'"
fi   

if [ -f ~/entwicklung/miceportal/git/dotfiles/bash/aliases   ]; then
  source ~/entwicklung/miceportal/git/dotfiles/bash/aliases   
else
  #echo "not exits '~/entwicklung/miceportal/git/dotfiles/bash/aliases'"
fi

##aliases and functions  
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

#for shared with dropbox for private config
if [ -f ~/Dropbox/bash/bashrc_local ]; then
  source ~/Dropbox/bash/bashrc_local 
else
  #echo "not exits '~/Dropbox/bash/bashrc_local'"
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
