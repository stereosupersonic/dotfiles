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
