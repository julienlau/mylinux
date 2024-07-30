set nocompatible
filetype off
" Set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
" Download plug-ins to the ~/.vim/plugged/ directory
call vundle#begin('~/.vim/plugged')
" Let Vundle manage Vundle
Plugin 'VundleVim/Vundle.vim'
call vundle#end()
filetype plugin indent on

set nu     " Enable line numbers
syntax on  " Enable syntax highlighting
" How many columns of whitespace a \t is worth
set tabstop=4
" How many columns of whitespace a "level of indentation" is worth
set shiftwidth=4
" Use spaces when tabbing
set expandtab
set incsearch  " Enable incremental search
set hlsearch   " Enable highlight search
" set termwinsize=12x0   " Set terminal size
set splitbelow         " Always split below
set mouse=a            " Enable mouse drag on window splits

Plugin 'sheerun/vim-polyglot'
Plugin 'scheakur/vim-scheakur'
set background=dark   " dark or light
colorscheme scheakur  " Your favorite color scheme's name
Plugin 'jiangmiao/auto-pairs'
Plugin 'preservim/nerdtree'

Plugin 'dyng/ctrlsf.vim'
" Use the ack tool as the backend
let g:ctrlsf_backend = 'ack'
" Auto close the results panel when opening a file
let g:ctrlsf_auto_close = { "normal":0, "compact":0 }
" " Immediately switch focus to the search window
let g:ctrlsf_auto_focus = { "at":"start" }
" " Don't open the preview window automatically
let g:ctrlsf_auto_preview = 0
" " Use the smart case sensitivity search scheme
let g:ctrlsf_case_sensitive = 'smart'
" " Normal mode, not compact mode
let g:ctrlsf_default_view = 'normal'
" " Use absoulte search by default
let g:ctrlsf_regex_pattern = 0
" " Position of the search window
let g:ctrlsf_position = 'right'
" " Width or height of search window
let g:ctrlsf_winsize = '46'
" " Search from the current working directory
let g:ctrlsf_default_root = 'cwd'
" (Ctrl+F) Open search prompt (Normal Mode)
nmap <C-F>f <Plug>CtrlSFPrompt
" (Ctrl-F + f) Open search prompt with selection (Visual Mode)
xmap <C-F>f <Plug>CtrlSFVwordPath
" (Ctrl-F + F) Perform search with selection (Visual Mode)
xmap <C-F>F <Plug>CtrlSFVwordExec
" (Ctrl-F + n) Open search prompt with current word (Normal Mode)
nmap <C-F>n <Plug>CtrlSFCwordPath
" (Ctrl-F + o )Open CtrlSF window (Normal Mode)
nnoremap <C-F>o :CtrlSFOpen<CR>
" (Ctrl-F + t) Toggle CtrlSF window (Normal Mode)
nnoremap <C-F>t :CtrlSFToggle<CR>
" (Ctrl-F + t) Toggle CtrlSF window (Insert Mode)
inoremap <C-F>t <Esc>:CtrlSFToggle<CR>
