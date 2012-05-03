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

if [ -f $DOTFILE/bash/filenavigation   ]; then
  source $DOTFILE/bash/filenavigation  
else
  echo "not exits '$DOTFILE/bash/filenavigation'"
fi

if [ -f $DOTFILE/bash/ruby ]; then
  source $DOTFILE/bash/ruby  
else
  echo "not exits '$DOTFILE/bash/ruby'"
fi  

if [ -f $DOTFILE/bash/rails ]; then
  source $DOTFILE/bash/rails  
else
  echo "not exits '$DOTFILE/bash/rails'"
fi

if [ -f $DOTFILE/bash/git ]; then
  source $DOTFILE/bash/git  
else
  echo "not exits '$DOTFILE/bash/git'"
fi 

if [ -f $DOTFILE/bash/osx ]; then
  source $DOTFILE/bash/osx  
else
  echo "not exits '$DOTFILE/bash/osx'"
fi

if [ -f $DOTFILE/bash/linux ]; then
  source $DOTFILE/bash/linux 
else
  echo "not exits '$DOTFILE/bash/linux'"
fi
if [ -f $DOTFILE/bash/system ]; then
  source $DOTFILE/bash/system 
else
  echo "not exits '$DOTFILE/bash/system'"
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
