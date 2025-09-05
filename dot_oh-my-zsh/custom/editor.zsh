if which cursor &> /dev/null; then
  export EDITOR='cursor --wait'
elif which code &> /dev/null; then
  export EDITOR='code --wait'
else
  export EDITOR='vim'
fi