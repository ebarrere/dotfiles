if which code &> /dev/null; then
  export EDITOR='code --wait'
elif which cursor &> /dev/null; then
  export EDITOR='cursor --wait'
else
  export EDITOR='vim'
fi