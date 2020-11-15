" heresy.vim - Make Vim behave more like a "normal" editor
" Author:       j-james
" Version:      0.1
"
" ============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Choose what groups of shortcuts to use (default: all)
" 0 is off, 1 is on
" 'shortcuts' controls all but 'better_wrap_navigation'
let s:settings = {
  \ 'shortcuts': 1,
  \ 'app_shortcuts': 1,
  \ 'copypaste_shortcuts': 1,
  \ 'undo_shortcuts': 1,
  \ 'find_shortcuts': 1,
  \ 'line_shortcuts': 1,
  \ 'tab_shortcuts': 1,
  \ 'pane_shortcuts': 1,
  \ 'indentation_shortcuts': 1,
  \ 'navigation_fixes': 1,
  \ 'better_wrap_navigation': 1
\}

" Fetches existing values from user and sets defaults if not set.
function! s:init_settings(settings)
  for [key, value] in items(a:settings)
    let sub = ''
    if type(value) == 0
      let sub = '%d'
    elseif type(value) == 1
      let sub = '"%s"'
    endif
    let fmt = printf("let g:heresy_%%s=get(g:, 'heresy_%%s', %s)",
          \ sub)
    exec printf(fmt, key, key, value)
  endfor
endfunction

call s:init_settings(s:settings)

if has('timers') == 0
  echo "vim-heresy: Your Vim version (Vim <7.5 or Neovim <0.1.5) doesn't "
  echo "support `timer()`, which causes a bug where Insert Mode is "
  echo "inappropriately set for some panes."
endif

" Plugin entry point
call g:heresy#StartHeresy()

let &cpo = s:save_cpo
unlet s:save_cpo
