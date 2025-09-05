if which cursor &> /dev/null; then
  export EDITOR='cursor --wait'
else
  export EDITOR='vim'
fi