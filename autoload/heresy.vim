" A fundamental question for this plugin is whether insertmode
" is always relevant. This is where we try to get an answer.
function! s:IsEditableBuffer()
  if &buftype ==# 'nofile'
     \|| !&modifiable
     \|| &readonly
    return 0
  else
    return 1
  endif
endfunction

" Make sure insert mode is the default mode only when opening/switching
" to files that you want to edit.
function! s:InsertMode()
  if s:IsEditableBuffer() == 1
    exe "set insertmode"
  else
    exe "set noinsertmode"
  endif
endfunction

" Count number of open buffers. They don't have to be visible.
function! s:CountListedBuffers()
  let bfr_count = 0
  for bfr in range(1, bufnr("$"))
    if buflisted(bfr)
       \&& ! empty(bufname(bfr))
       \|| getbufvar(bfr, '&buftype') ==# 'help'
       let bfr_count += 1
    endif
  endfor
  return bfr_count
endfunction

" The number of visible lines in the current buffer.
" TODO: Include wrapped lines in the total, so that we can start scrolling
"       through *visible* lines rather than file lines.
function! s:BufferLines()
  return line('w$') - line('w0')
endfunction

function! s:InsertAndSelectionBehaviour()
  " Intelligently set/unset insertmode
  augroup start_insertmode
    autocmd!
    if has('timers') == 1
      " The timer here delays the call to check whether the current buffer
      " is an editable one. Without the delay, the check is often too early
      " to correctly get the value of `&buftype`, etc.
      autocmd BufEnter * call timer_start(1, {->execute('call s:InsertMode()')})
    else
      autocmd BufEnter * call s:InsertMode()
    endif
  augroup END

  " Mostly changes the way selection works.
  " See: http://vimdoc.sourceforge.net/htmldoc/gui.html#:behave
  " An extract from the docs about the difference between `behave mswin`
  " and `behave xterm`:
  "               mswin              xterm
  "  'selectmode' 'mouse,key'        ''
  "  'mousemodel' 'popup'            'extend'
  "  'keymodel'   'startsel,stopsel' ''
  "  'selection'  'exclusive'        'inclusive'
  behave mswin

  " Make 'v' commands default to Visual mode.
  " Not sure how useful this is because the mappings that use 'v'-based
  " commands don't seem to follow this option. Thus why you will see <C-G>
  " after some selection-based commands to switch from Visual to Selection
  " Mode. So might be better to give experienced users who are pressing
  " 'v' in normal mode the expected behaviour.
  set selectmode+=cmd
endfunction

" All shortcuts in one function so they can be more easily controlled.
function! g:SetShortcuts()

  if g:heresy_app_shortcuts == 1
    " Completely exit vim
    inoremap <silent> <C-Q> <C-O>:call heresy#CloseVim()<CR>
    snoremap <silent> <C-Q> <C-O>:call heresy#CloseVim()<CR>
    nnoremap <silent> <C-Q> :call heresy#CloseVim()<CR>
    " Close current pane-like things.
    inoremap <silent> <C-W> <C-O>:call heresy#ClosePane()<CR>
    snoremap <silent> <C-W> <C-O>:call heresy#ClosePane()<CR>
    nnoremap <silent> <C-W> :call heresy#ClosePane()<CR>
    " Save file
    inoremap <silent> <C-S> <C-O>:update<CR>
    " New file
    inoremap <C-N> <C-O>:edit<Space>
    " Open file (TODO: hook into netrw or NERDTree)
    inoremap <C-O> <C-O>:edit<Space>
  endif

  if g:heresy_copypaste_shortcuts == 1
    " One of those curious features of Vim: without `onemore` when pasting
    " at the end of a line, pasted text gets put *before* the cursor.
    set virtualedit=onemore
    " Cut selected text / current line
    snoremap <C-X> <C-O>"+xi
    inoremap <C-X> <C-O>"+dd
    " Copy selected text / current line
    snoremap <C-C> <C-O>"+ygv
    inoremap <C-C> <C-O>"+Y
    " Paste system clipboard
    inoremap <C-V> <C-O>:call heresy#Paste()<CR>
    " The odd <Space><Backspace> here is because one-off Normal Mode commands
    " don't seem to work as expected when some text is selected. Also just
    " using <Backspace> on its own seems to cause weird behaviour too.
    snoremap <C-V> <Space><Backspace><C-O>:call heresy#Paste()<CR>
    cnoremap <C-V> <C-R>"
  endif

  " Use <M-o><C-Z> for native terminal backgrounding.
  " The <Esc>s used in the `snoremap` commands seem to prevent the selection
  " process itself being put in the undo history - so now the undo actually
  " undoes the last *text* activity.
  if g:heresy_undo_shortcuts == 1
    " Undo
    inoremap <silent> <C-Z> <C-O>u
    snoremap <silent> <C-Z> <Esc><C-O>u
    " Redo
    inoremap <silent> <C-Y> <C-O><C-R>
    snoremap <silent> <C-Y> <Esc><C-O><C-R>
  endif

  if g:heresy_plugin_shortcuts == 1
    " Update plugins
    inoremap <C-U> <C-O>:PlugUpdate<CR>
    " Install plugins
    " TODO: The tab key outputs CTRL+I instead of Tab -_-
    " inoremap <C-I> <C-O>:PlugInstall<CR>
  endif

  if g:heresy_find_shortcuts == 1
    " Find
    inoremap <C-F> <C-O>/
    " Find selected word under cursor
    snoremap <C-F> <C-O>y/<C-R>"<CR>
    " Find next
    " inoremap <F3> <C-O>n
    " Find previous
    " inoremap <S-F3> <C-O>N
    " Find and replace
    inoremap <C-G> <C-O>:%s/[FIND]/[REPLACE]/g
    " Jump to a line
    " inoremap <C-?> <C-O>:call heresy#GotoLine()<CR>
    " Multi-select VSCode style
    " snoremap <C-D> ???
  endif

  if g:heresy_line_shortcuts == 1
    " Move the current / selected line(s) up
    inoremap <silent> <C-Up> <C-O>:m -2<CR>
    snoremap <silent> <C-Up> <C-O>:m '<-2<CR>gv=gv<C-G>
    inoremap <silent> <C-K> <C-O>:m -2<CR>
    snoremap <silent> <C-K> <C-O>:m '<-2<CR>gv=gv<C-G>
    " Move the current / selected line(s) down
    inoremap <silent> <C-Down> <C-O>:m +1<CR>
    snoremap <silent> <C-Down> <C-O>:m '>+1<CR>gv=gv<C-G>
    inoremap <silent> <C-J> <C-O>:m +1<CR>
    snoremap <silent> <C-J> <C-O>:m '>+1<CR>gv=gv<C-G>
  endif

  if g:heresy_tab_shortcuts == 1
    " Open a new tab
    inoremap <silent> <C-T> <C-O>:tabnew<CR>
    snoremap <silent> <C-T> <C-O>:tabnew<CR>
    " Cycle through tabs
    inoremap <silent> <C-Tab> <C-O>:tabnext<CR>
    snoremap <silent> <C-Tab> <C-O>:tabnext<CR>
    " Cycle backwards through tabs
    inoremap <silent> <C-S-Tab> <C-O>:tabprevious<CR>
    snoremap <silent> <C-S-Tab> <C-O>:tabprevious<CR>
  endif

  if g:heresy_pane_shortcuts == 1
    " Move between splits, panes, windows, etc and close them
    inoremap <silent> <M-Left>  <C-O><C-W><Left>
    snoremap <silent> <M-Left>  <Esc><C-W><Left>
    nnoremap <silent> <M-Left>  <C-W><Left>
    inoremap <silent> <M-Down>  <C-O><C-W><Down>
    snoremap <silent> <M-Down>  <Esc><C-W><Down>
    nnoremap <silent> <M-Down>  <C-W><Down>
    inoremap <silent> <M-Up>    <C-O><C-W><Up>
    snoremap <silent> <M-Up>    <Esc><C-W><Up>
    nnoremap <silent> <M-Up>    <C-W><Up>
    inoremap <silent> <M-Right> <C-O><C-W><Right>
    snoremap <silent> <M-Right> <Esc><C-W><Right>
    nnoremap <silent> <M-Right> <C-W><Right>

    " This allows unsaved buffers to be kept in the background.
    set hidden
  end

  " TODO: Shift+TAB doesn't work in insert mode, but does in selection mode??
  " TODO: In Neovim TAB doesn't work in mswin selection mode, but SHIFT+TAB does??
  if g:heresy_indentation_shortcuts == 1
    " Indenting
    snoremap <Tab> <C-O>>gv
    inoremap <M-]> <C-T>
    snoremap <M-]> <C-O>>gv
    " Unindenting
    snoremap <S-Tab> <C-O><gv
    inoremap <M-[> <C-D>
    snoremap <M-[> <C-O><gv
  endif

  if g:heresy_navigation_fixes == 1
    " Fix HOME to go back to the first non-whitespace character of the line.
    inoremap <silent> <Home> <C-O>^
    " The same but for selection behaviour
    inoremap <silent> <S-Home> <S-Left><C-G><C-O>^
    snoremap <silent> <S-Home> <C-O>^

    " Tweaks PageUp behaviour to get cursor to first line on top page
    inoremap <silent> <PageUp> <C-O>:call heresy#PageUp()<CR>
  endif

endfunction

" TODO: Mention any unsaved buffers
function! heresy#CloseVim()
  let l:confirmed = confirm('Do you really want to quit Vim?', "&Yes\n&No", 2)
  if l:confirmed == 1
    quitall!
  endif
endfunction

" Try to intuitively and intelligently close things like buffers, splits,
" panes, quicklist, etc, basically anything that looks like a pane.
function! heresy#ClosePane()
  if s:IsEditableBuffer() == 1
    " TODO: These aren't actually formally associated with a buffer, although
    "       conceptually they often are (eg; linting errors, file search).
    " Close any location lists on screen.
    exe "lclose"
    " Close any quickfix lists on screen.
    exe "cclose"

    if s:CountListedBuffers() > 1
      " By default if the buffer is the only one on screen, closing it closes the
      " tab/window. So this little trick does a switch to the next buffer,
      " then closes the previous buffer.
      exe "bp\|bd #"
    else
      quit
    endif
  else
    quit
  endif
endfunction

" By default Vim treats wrapped text as a single line even though it may
" appear as many lines on screen. So here we try to make wrapped text behave
" more conventionally. Please add any new types you might come across.
function! s:SetWrappedTextNavigation()
  autocmd BufNewFile,BufRead *.{
    \md,
    \mdown,
    \markdown,
    \txt,
    \textile,
    \rdoc,
    \org,
    \creole,
    \mediawiki
  \} setlocal filetype=markdown
  autocmd FileType \
	\markdown,
	\rst,
    \asciidoc,
    \pod,
    \txt
    \ call s:WrappedTextBehaviour()
endfunction

function! s:WrappedTextBehaviour()
  " Allow text to wrap in text files
  setlocal linebreak wrap

  " Make arrow keys move through wrapped lines
  " TODO:
  "   * Scroll window 1 wrapped soft line at a time rather than entire block
  "     of wrapped lines -- I'm as good as certain this will need a patch to
  "     (n)vim's internals.
  inoremap <buffer> <Up> <C-O>gk
  inoremap <buffer> <Down> <C-O>gj
  " For selection behaviour
  snoremap <buffer> <S-Up> <C-O>gk
  snoremap <buffer> <S-Down> <C-O>gj
  " HOME/END for *visible* lines, not literal lines
  inoremap <buffer> <silent> <Home> <C-O>g^
  inoremap <buffer> <silent> <End> <C-O>g$
  " For selection behaviour
  inoremap <buffer> <silent> <S-Home> <S-Left><C-G><C-O>g^
  snoremap <buffer> <silent> <S-Home> <C-O>g^
  inoremap <buffer> <silent> <S-End> <S-Right><C-G><C-O>g$
  snoremap <buffer> <silent> <S-End> <C-O>g$
endfunction

function! heresy#GotoLine()
  let l:line_number = input('Goto line: ')
  execute line_number
endfunction

" Just to get PAGEUP to move to the first line when on the first page.
function! heresy#PageUp()
  " If current line is higher than the size of the buffer
  if line(".") > s:BufferLines()
    " Normal PageUp
    execute "normal! \<C-b>"
  else
    " Goto first line
    execute "normal! gg"
  endif
endfunction

function! heresy#Paste()
  set paste
  execute 'normal! "+P'
  set nopaste
  call feedkeys("\<Right>")
endfunction

function! g:heresy#StartHeresy()
  call s:InsertAndSelectionBehaviour()

  if g:heresy_better_wrap_navigation == 1
    call s:SetWrappedTextNavigation()
  endif

  if g:heresy_shortcuts == 1
    call g:SetShortcuts()
  endif
endfunction

" ALT+; for command prompt
" inoremap <M-;> <C-O>:
" snoremap <M-;> <C-O>:
" inoremap <M-c> <C-O>:
" snoremap <M-c> <C-O>:
" nnoremap <M-;> :
" nnoremap <M-c> :

" <ALT+o> replaces native <C-O> for one-time normal mode commands.
" inoremap <M-o> <C-O>
" snoremap <M-o> <C-O>

" Select word under cursor
" inoremap <C-D> <C-O>viw<C-G>
" Select current line
" inoremap <C-L> <C-O>V<C-G>
" Append next line to selection
" snoremap <C-L> <C-O>gj

" CTRL-A for selecting all text
" inoremap <C-A> <C-O>gg<C-O>gH<C-O>G
" snoremap <C-A> <C-O><C-C>gggH<C-O>G

" CTRL+ALTt+k deletes the current line under the cursor
" TODO: Doesn't work in terminal vim, even with vim-fixkey
" inoremap <silent> <C-M-K> <C-O>"_dd

" CTRL+ALT+d duplicates current line.
" NB. Uses the named 'd' register.
" TODO: Doesn't work in terminal vim, even with vim-fixkey
" inoremap <silent> <C-M-D> <C-O>"dyy<C-O>"dp
