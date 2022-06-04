if isdirectory($GOROOT)
    set runtimepath+=$GOROOT/misc/vim
endif

"Discuss  Auto-commands
filetype plugin indent on

augroup cprog
  au!
  autocmd BufRead,BufNewFile *
	\ setlocal formatoptions=tcqln autoindent tw=75 comments&
        \ formatlistpat=^\\s*\\(\\d\\+[\\]:.)}\t\ ]\\\\|\\[.\\]\\)\\s*
  autocmd BufRead *.c,*.h
        \ setlocal formatoptions=croql cindent comments=sr:/*,mb:*,el:*/,://
  autocmd BufRead *.bib
        \ setlocal nocindent
  autocmd BufRead *.tex
        \ syn region texZone
                \ start="\\begin{program}"
                \ end="\\end{program}\|%stopzone\>"
                \ contains=@Spell
  autocmd BufRead *.tex
        \ syn region texZone
                \ start="\\code\*\=\z([^\ta-zA-Z]\)"
                \ end="\z1\|%stopzone\>"
                \ contains=@Spell
  autocmd BufRead,BufNewFile *.rb,Rakefile,*.htm,*.html,*.json,*.js
        \ setlocal shiftwidth=2 softtabstop=2
  autocmd BufRead,BufNewFile *.js,*.html
        \ setlocal indentkeys=!^F,o
  " :setfileytype only sets filetype if it isn’t already set
  autocmd BufNewFile,BufRead *.md
        \ setlocal filetype=markdown | syntax clear
  autocmd BufNewFile,BufRead Vagrantfile,Capfile,*.thor
        \ setlocal filetype=ruby
  autocmd BufNewFile,BufRead *.go
        \ setlocal filetype=go smartindent noexpandtab
        \ tabstop=8 shiftwidth=8 softtabstop=8
  autocmd BufNewFile,BufRead *.gradle
        \ setlocal filetype=groovy
  autocmd BufNewFile,BufRead *
        \ if getline(1) =~# '^#.*chef-apply.*' |
        \  set filetype=ruby |
        \ endif

  autocmd BufNewFile,BufRead ~/programming/ruby/* set filetype=ruby
  autocmd BufNewFile,BufRead ~/programming/chef/* set filetype=ruby
  autocmd BufNewFile,BufRead ~/programming/python/* set filetype=python
  autocmd BufNewFile,BufRead ~/programming/js/* set filetype=javascript
  " the above are a little bit heavy-handed sometimes, so here’s an override
  autocmd BufNewFile,BufRead COMMIT_EDITMSG set filetype=gitcommit

  autocmd BufNewFile,BufRead *.ts set filetype=javascript
  autocmd BufNewFile,BufRead Makefile set filetype=make
  autocmd BufNewFile,BufRead ~/.aws/credentials
        \ setlocal directory= undodir= viewdir= viminfo=
  autocmd BufNewFile,BufRead /var/tmp/hosts.*
        \ setlocal directory= undodir= viewdir= viminfo=
  autocmd BufNewFile,BufRead ~/.ansible/tmp/*
        \ setlocal directory= undodir= viewdir= viminfo=
augroup END

autocmd BufNewFile,BufRead *.lytex
        \ setlocal filetype=tex

autocmd BufRead *.kid
        \ setfiletype xml

" Jump to last visited location in file
autocmd BufReadPost *
	\ if line("'\"") > 0 && line("'\"") <= line("$") |
	\   exe "normal g`\"" |
	\ endif
" Check spelling everywhere
if v:version>=700
    autocmd BufReadPost *
            \ syntax spell toplevel
endif

" Wrap when editing brand-new text files
autocmd BufRead,BufNewFile *.txt,*.md
    \ setlocal tw=75 formatoptions+=t noshiftround

"" Syntax highlighting

syntax enable

if &term == "xterm" || &term == "xterm-256color"
    set background=light
    " Turn on 256 colours for xterms
    set t_Co=256 t_AF=[38;5;%dm t_AB=[48;5;%dm t_me=[0m
    " Very bright search highlighting
    highlight Search ctermbg=226
    highlight IncSearch ctermbg=226 ctermfg=0 cterm=bold
    highlight Visual ctermbg=183
    highlight StatusLineNC ctermfg=0 ctermbg=252 cterm=NONE
    highlight StatusLine ctermfg=0 ctermbg=252 cterm=bold
    highlight SpellCap ctermbg=254
    highlight SpellLocal ctermbg=254
endif
if &term == "xterm-color"
    " test: collr color. colour
    set background=light
    highlight SpellBad ctermbg=NONE ctermfg=magenta cterm=NONE
    highlight SpellCap ctermbg=NONE ctermfg=cyan cterm=NONE
    highlight SpellLocal ctermbg=NONE ctermfg=cyan cterm=NONE
endif
if &term == "cygwin"
    highlight Search ctermbg=Black ctermfg=Yellow cterm=reverse,bold
endif
highlight Folded term=NONE cterm=NONE ctermbg=230 ctermfg=240
highlight FoldColumn ctermfg=240 ctermbg=7

set fillchars=fold:\ 
function MyFoldText()
    let line = getline(v:foldstart)
    "let sub = substitute(line, '/\*\|\*/\|{{{\d\=', '', 'g')
    "return v:folddashes . sub
    return printf('%4d lines %-3s %s',
                \ v:foldend - v:foldstart + 1,
                \ v:folddashes, line)
endfunction
set foldtext=MyFoldText()

" Highlight trailing spaces, too-long lines in red in source code
" the cino+= thing sets (mostly) Two Sigma indent rules
" if your shiftwidth and tabstop and friends are set correctly
" set verbose=9
autocmd BufReadPost *.cc,*.cpp,*.cxx,*.C,*.java,*.c
    \ setlocal cino+=(s,W1,U1,u0
autocmd BufReadPost *.java
    \ syntax region javaComment start=+/\*+ end=+\*/+
    \ contains=@javaCommentSpecial,javaTodo,@Spell,Error
" This would be useful if it only applied to source code
highlight TooLongLineError ctermbg=225
autocmd BufNewfile,BufReadPost * match TooLongLineError /\%>80v.\+/
highlight TrailingSpaceError ctermbg=196
if v:version>=700
    autocmd BufNewFile,BufReadPost * 2match TrailingSpaceError /\s\+$/
endif
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""XX
"                                                 Test lines               
""""""""""""			""""""""""""""""""""""""""""""""""""""""""""""""XX

"" Key mappings
map Q gq

imap <C-C> "*y
vmap <C-C> "*y

" Windows-style shortcuts for moving around multiple windows
map <C-Tab> <C-W>w
map <C-F4> <C-W>c

" Uncomment to turn off man search (too easy to hit accidentally)
map K k

" Uncomment to turn off command window (too easy to open accidentally)
" map q: :q

" Thanks http://www.shallowsky.com/blog/index.cgi/linux/editors/index.html
imap <Nul> <Space>

" This makes shift-backspace act the same as backspace
imap <Esc>[3;2~ <C-h>
cmap <Esc>[3;2~ <C-h>

" Tab should indent (jump up to the next indent increment multiple), and
" shift-tab should unindent
" inoremap <Tab> <C-T>
inoremap <S-Tab> <C-D>

" remove trailing whitespace
map ,w :s/\s\+$//g <CR>
map ,W :s/\s\{2,}/ /g <CR>
map ,D :s/[0-9]\+◆\ // <CR>
map ,d :r!date <CR>o<CR>
" add line of `---` or `===`, same width as current line
map ,- yyp:s/./-/g<CR>
map ,= yyp:s/./=/g<CR>
map ,2 :r!2md <CR>
" comment out:
map ,# :s/^\(.\+\)/# \1/ <CR> :'<,'>s/^$/#/ <CR>
map ,m a◆<Esc>

" Emacs compatibility
nnoremap <C-x>o <C-w>w
nnoremap <C-x>1 :only<return>
nnoremap <C-x>0 :close<return>
" Don't know how to get this in search of command mode...
inoremap <Esc><Backspace> <Esc>ldBi

"Ctrl-home/end
noremap <Esc>[1;5H gg
noremap <Esc>[1;5F G

"" Terminal stuff
" Misc backspace/delete stuff
set t_kD=[3~
set t_kb=
set t_ks=[?1h t_ke=[?1l

" make numpad keys work in linux, and turn off screen blinking when it
" thinks it should beep
set <k0>=Op <k1>=Oq <k2>=Or
set <k3>=Os <k4>=Ot <k5>=Ou
set <k6>=Ov <k7>=Ow <k8>=Ox
set <k9>=Oy <kPoint>=On
set <Home>=[H <End>=Ow
set <kPlus>=Ol <kMinus>=OS
set <kDivide>=OQ <kMultiply>=OR
set <kEnter>=OM

set <kPlus>=Ok
set <kMinus>=Om
set <kMultiply>=Oj
set <kDivide>=Oo

"" Settings
if !isdirectory($HOME . "/.vimtmp")
    call mkdir($HOME . "/.vimtmp", "", 0700)
endif
set backspace=2
set directory=.,~/.vimtmp
set encoding=utf-8
set expandtab
set ffs=unix,dos
set guioptions-=T
set hidden
set history=1000
set hlsearch
set ignorecase
set incsearch
set isfname-==
set modelines=5
if empty($SSH_CONNECTION)
  set mouse=a
endif
set nocompatible
set nojoinspaces
set ruler
set scrolloff=3
set shiftround
set shiftwidth=4
set showcmd
set smartcase
set softtabstop=4
set statusline=%<%f\ %h%m%r%=%-14.(%l/%L,%c%V%)\ %P
set t_vb=
set tabstop=8
set title
if has_key(environ(), 'IN_PRESENTATION')
    set titlestring=vim\ %t
end
if v:version>=703
    au BufWritePre /private/var/tmp/hosts.* setlocal noundofile
    au BufWritePre hg-editor-*.txt setlocal noundofile
    au BufWritePre svn-commit*.tmp setlocal noundofile
    set undodir=.undo
    set undodir+=~/.vimtmp
    set undofile
endif
set undolevels=10000
set vb
set viminfo='10,\"50
set viewdir=~/.vimtmp/view
set visualbell t_vb=
set whichwrap+=h,l,<,>,[,]

" I hope this doesn't slow things down too much
runtime! ftplugin/man.vim


"" Error formats
" Guile
let &errorformat="ERROR:\ %f:%l:%c:\ %m," . &errorformat
let &errorformat="iconv:\ %f:%l:%c:\ %m," . &errorformat
let &errorformat="l.%l \ %m," . &errorformat
" Go
let &errorformat="vet:\ %f:\ %*[^:]:%l:%c:\ %m," . &errorformat
" Rubber
let &errorformat="WARNING:rubber.cmdline:%f:%c:\ %m," . &errorformat
" This isn't quite right, but will be helpful for perl.
set errorformat+=%m\ at\ %f\ line\ %l\\,\ near\ \"%.%#\"
set errorformat+=%m\ at\ %f\ line\ %l\\,%.%#
set errorformat+=%m\ at\ %f\ line\ %l.
" GNU error format
set errorformat+=%f:%l.%c-%*\\d.%*\\d:\ %m
" Python tracebacks
set errorformat+=%-C\ \ \ \ \ %\\\ %#\^
set errorformat+=%C\ \ \ \ %m
set errorformat+=%A\ \ File\ \"%f\"\\,\ line\ %l%.%#
    " look for an Error: or Exception:
set errorformat+=%+Z%[A-Za-z0-9_]%\\+E%[A-Za-z0-9_]%\\+:\ %\\@=%m
" Ruby backtraces
set errorformat+=%*\\s#%*\\s%f:%l:%m
set errorformat+=%+E%>%[A-Z]%*[a-z]Error:%m
set errorformat+=%Z\ \ \ \ %f:%l:%m
set errorformat+=%^\ \ \ \ %f:%l:%m
set errorformat+=\	from\ %f:%l:%m
set errorformat+=%f:%l:%mError)
" Skip the default error format that matches timestamps in compile output
set errorformat-=%f:%l:%m
set errorformat+=%[0-9/:\ -]%#\ %f:%l:\ %m
set errorformat+=%f:%l:\ %m

"" Paths
set path+=/usr/include/g++-3
set path+=/usr/include/linux
set path+=/usr/lib/gcc-lib/i386-redhat-linux/3.2/include
set path+=/usr/X11R6/include/X11
set path+=/usr/include/w32api
set path+=/usr/include/mingw
set path+=/usr/include/c++/3.3.1
set path+=/usr/include/c++/3.3.1/i686-pc-mingw32
set path+=/opt/local/include
set path+=/opt/X11/include
set path+=/opt/local/Library/Frameworks/Python.framework/Versions/2.6/include/python2.6
set path+=/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Headers

autocmd GUIEnter * set t_vb=

if v:version>=700
    set spell
    set spelllang=en_ca
    set spellfile=~/.vimspell.en.utf-8.add,~/.vimspell.extra.add
endif

" For browsing by regexes...
" nmap <Esc>n nz<CR>
" nmap <Esc>N Nz<CR>

autocmd FileType make
    \ setlocal list listchars=tab:t\ 
    \ softtabstop=4
autocmd FileType ruby,eruby,javascript
    \ setlocal sw=2 softtabstop=2
autocmd FileType xml
    \ setlocal sw=2
autocmd FileType gitconfig
    \ setlocal sw=8 noexpandtab
autocmd BufReadPost *
    \ if &readonly |
    \     setlocal nomodifiable |
    \ endif
autocmd FileType yaml
    \ setlocal sw=2 indentkeys-=0#

" Indent Python in the Google way.
" from http://vimingwithbuttar.googlecode.com/hg/hacks.vim
autocmd FileType python setlocal indentexpr=GetPythonIndent(v:lnum)
autocmd FileType python setlocal indentexpr=GetPythonIndent(v:lnum)

let s:maxoff = 100 " maximum number of lines to look backwards.

let pyindent_nested_paren="&sw*2"
let pyindent_open_paren="&sw*2"

autocmd FileType python let pyindent_nested_paren="&sw*2"
autocmd FileType python let pyindent_open_paren="&sw*2"
" END -- Indent Python in the Google way.

au BufWinLeave outline.txt mkview
au BufRead outline.txt silent loadview
" au BufWinLeave msc.tex mkview
" au BufRead msc.tex silent loadview

let perl_include_pod = 1
let g:js_indent_log = 0
let g:ruby_path = "/usr/bin/ruby"

autocmd FileType tex setlocal indentexpr=
autocmd FileType tex hi texItalStyle cterm=none ctermfg=52

function s:prettier()
    :let s:autoread = &autoread
    try
        :set autoread
        :w
        !prettier --write %
    finally
        :let &autoread = s:autoread
    endtry
endfunction
command Pretty call s:prettier()

function s:black()
    :let s:autoread = &autoread
    try
        :set autoread
        :w
        !black -l 80 %
    finally
        :let &autoread = s:autoread
    endtry
endfunction
command Black call s:black()

function s:swiftformat()
    :let s:autoread = &autoread
    try
        :set autoread
        :w
        !swiftformat --swiftversion 5.4 %
    finally
        :let &autoread = s:autoread
    endtry
endfunction
command SF call s:swiftformat()

function s:clangformat()
    :let s:autoread = &autoread
    try
        :set autoread
        :w
        !clang-format -i --style=webkit %
    finally
        :let &autoread = s:autoread
    endtry
endfunction
command CF call s:clangformat()
