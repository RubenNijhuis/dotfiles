" Basic Vim Configuration
" Minimal, sensible defaults for when VS Code isn't available

" --- General Settings ---
set nocompatible              " Don't try to be vi compatible
filetype plugin indent on     " Enable filetype detection
syntax on                     " Enable syntax highlighting

" --- UI ---
set number                    " Show line numbers
set relativenumber            " Relative line numbers
set showcmd                   " Show command in status line
set cursorline                " Highlight current line
set wildmenu                  " Visual autocomplete for command menu
set showmatch                 " Highlight matching parentheses
set laststatus=2              " Always show status line

" --- Indentation ---
set tabstop=2                 " Tab width
set shiftwidth=2              " Indent width
set expandtab                 " Use spaces instead of tabs
set autoindent                " Copy indent from current line
set smartindent               " Smart indenting for new lines

" --- Search ---
set incsearch                 " Search as you type
set hlsearch                  " Highlight search results
set ignorecase                " Case insensitive search
set smartcase                 " Case sensitive if uppercase used

" --- Performance ---
set lazyredraw                " Don't redraw during macros
set ttyfast                   " Faster scrolling

" --- Backups ---
set nobackup                  " Don't create backup files
set noswapfile                " Don't create swap files
set nowritebackup             " Don't backup before overwriting

" --- Clipboard ---
set clipboard=unnamed         " Use system clipboard

" --- Encoding ---
set encoding=utf-8            " UTF-8 encoding
set fileencoding=utf-8        " File encoding

" --- Key Mappings ---
" Set leader key to space
let mapleader = " "

" Clear search highlighting
nnoremap <leader>/ :nohlsearch<CR>

" Save with Ctrl+S (normalize with VS Code muscle memory)
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a

" Navigate splits with Ctrl+hjkl
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" --- Colors ---
" Use 256 colors if available
if has('termguicolors')
  set termguicolors
endif

" Status line (simple, no plugins needed)
set statusline=%F\ %m%r%h%w\ [%{&ff}]\ [%Y]\ [%04l,%04v]\ [%p%%]\ [%L]

" --- File Type Specific ---
autocmd FileType javascript,typescript,json setlocal ts=2 sw=2 sts=2 expandtab
autocmd FileType python setlocal ts=4 sw=4 sts=4 expandtab
autocmd FileType go setlocal ts=4 sw=4 sts=4 noexpandtab
autocmd FileType markdown setlocal wrap linebreak
