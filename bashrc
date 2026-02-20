#Alias erzeugen $HOME/.bashrc
#for shared with dropbox for private config

# Alles, was Output erzeugt, nur bei interaktiven Sessions ausführen.
if [[ $- != *i* ]]; then
  return
fi

# Identify OS and Machine -----------------------------------------
export OS=`uname -s | sed -e 's/ *//g;y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/'`
export OSVERSION=`uname -r`; OSVERSION=`expr "$OSVERSION" : '[^0-9]*\([0-9]*\.[0-9]*\)'`
export MACHINE=`uname -m | sed -e 's/ *//g;y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/'`
export PLATFORM="$MACHINE-$OS-$OSVERSION"

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

#PATH
if [ -d $HOME/bin ]; then
 PATH="$PATH:$HOME/bin"
fi

if [ -d $HOME/bin/scripts ]; then
 PATH="$PATH:$HOME/bin/scripts"
fi

if [ -d $DOTFILE/bash/bin ]; then
 PATH="$PATH:$DOTFILE/bash/bin"
fi

if [ -d $DOTFILE/bin ]; then
 PATH="$PATH:$DOTFILE/bin"
fi

if [ -d $DOTFILE/scripts ]; then
 PATH="$PATH:$DOTFILE/scripts"
fi

#shared scripts
if [ -d $HOME/Dropbox/bash/bin ]; then
 PATH="$PATH:$HOME/Dropbox/bash/bin"
fi


PATH="/usr/local/sbin:$PATH"
PATH="/usr/local/bin:$PATH"
export PATH

# dropbox shared
if [ -f $HOME/Dropbox/bash/bashrc_local ]; then
  source $HOME/Dropbox/bash/bashrc_local
fi

#for special alias path etc...
if [ -f $HOME/.bashrc_local ]; then
  source $HOME/.bashrc_local
else
  echo "not exits ' $HOME/.bashrc_local'"
fi


[ -f ~/.fzf.bash ] && source ~/.fzf.bash
# export PATH="/usr/local/opt/node@18/bin:$PATH"
# export PATH="/opt/homebrew/opt/icu4c/bin:$PATH"

# Added by `rbenv init` on Mi Okt 15 16:18:49 CEST 2025
if command -v rbenv &> /dev/null; then
  eval "$(rbenv init - --no-rehash bash)"
fi
