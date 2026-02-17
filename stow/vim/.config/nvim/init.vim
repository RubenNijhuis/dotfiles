" Neovim configuration
" Source the main .vimrc for shared config
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" Neovim-specific enhancements
if has('nvim')
  " Use true colors
  set termguicolors

  " Better escape
  set ttimeout
  set ttimeoutlen=0
endif
