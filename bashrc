#Alias erzeugen $HOME/.bashrc  
#for shared with dropbox for private config       

#load miceportal settings
if [ -f $HOME/entwicklung/miceportal/git/dotfiles/bash/env   ]; then
  source $HOME/entwicklung/miceportal/git/dotfiles/bash/env   
fi

if [ -f $HOME/entwicklung/miceportal/git/dotfiles/bash/config   ]; then
  source $HOME/entwicklung/miceportal/git/dotfiles/bash/config   
fi  

if [ -f $HOME/entwicklung/miceportal/git/dotfiles/bash/aliases   ]; then
  source $HOME/entwicklung/miceportal/git/dotfiles/bash/aliases     
fi

if [ -f "`pwd`/DOTFILE" ]; then   
  source "`pwd`/DOTFILE" 
else
  echo "DOTFILE not exits"   
  #exit
fi   

if [ -n "${DOTFILESPATH+x}" ]; then
  export DOTFILE=$DOTFILESPATH 
else
  echo "DOTFILESPATH not exits" 
fi 

#aliases and functions  
if [ -f $DOTFILE/bash/env   ]; then
  source $DOTFILE/bash/env  
else
  echo "not exits '$DOTFILE/bash/env'"
fi   

if [ -f $DOTFILE/bash/prompt   ]; then
  source $DOTFILE/bash/prompt  
else
  echo "not exits '$DOTFILE/bash/prompt'"
fi

if [ -f $DOTFILE/bash/aliases   ]; then
  source $DOTFILE/bash/aliases  
else
  echo "not exits '$DOTFILE/bash/aliases'"
fi
 
if [ -f $DOTFILE/bash/motd ]; then 
  source $DOTFILE/bash/motd
fi   

#for special alias path etc...
if [ -f $HOME/.bashrc_local ]; then
  source $HOME/.bashrc_local
else
  echo "not exits ' $HOME/.bashrc_local'"
fi

if [ -f $DOTFILE/bash/radio ]; then
  source $DOTFILE/bash/radio
fi
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
