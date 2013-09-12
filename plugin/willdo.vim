if exists('g:willdo_loaded') || &cp
  finish
endif

let g:willdo_loaded = 1

if !exists('g:willdo_ruby')
  let g:willdo_ruby = 'ruby'
endif

if !exists('g:willdo_runner')
  let path = expand('<sfile>:p:h') . '/..'
  let g:willdo_runner = path . '/run.rb'
end

if !exists('g:willdo_map')
  let g:willdo_map = 1
end

let s:locals = []

function s:local(def)
  let s:locals += [a:def]
endfunction

function s:define_locals()
  for local in s:locals
    exe local
  endfor
endfunction

call s:local('command! -buffer -nargs=0 Wview :call willdo#OpenView()')
call s:local('command! -buffer -nargs=0 Wjump :call willdo#JumpToItem()')
call s:local('command! -buffer -nargs=0 Wrun  :call willdo#ExecuteView()')
call s:local('command! -buffer -nargs=0 Wdone :call willdo#MarkDone()')
call s:local('command! -buffer -nargs=? Wtag  :call willdo#Tag(<q-args>)')
call s:local('command! -buffer -nargs=? WTag  :call willdo#TagAbove(<q-args>)')

if g:willdo_map == 1
  call s:local('nnoremap <silent> <buffer> <cr>      :Wjump<cr>')
  call s:local('nnoremap <silent> <buffer> <Leader>r :Wrun<cr>')
  call s:local('nnoremap <silent> <buffer> <Leader>d :Wdone<cr>')
  call s:local('nnoremap <silent> <buffer> <Leader>t :Wtag<cr>')
  call s:local('nnoremap <silent> <buffer> <Leader>T :WTag<cr>')
endif

augroup willdo
  autocmd!
  autocmd FileType wdo,wdov call s:define_locals()
  autocmd BufEnter *.wdo call s:enable_calender()
augroup END


function willdo#OpenView()
  let nr = bufwinnr(b:willdo_view)
  if nr != -1
    exe nr . 'wincmd w'
  else
    exe 'vsplit ' . b:willdo_view
  endif
endfunction

function willdo#JumpToItem()
  let filenr = bufwinnr(b:willdo_file)

  if filenr == -1
    echo "No main buffer"
    return
  end

  let winnr = bufwinnr('%')
  let win = winsaveview()
  let ref = expand('<cWORD>')

  if strlen(ref) == 0
    echo "No reference under cursor"
    return
  end

  exe filenr . 'wincmd w'
  let matches = search('^* '.ref, 'ws')

  if matches == 0
    exe winnr . 'wincmd w'
    call winrestview(win)
    echo "Couldn't find reference: ".ref
    return
  end

  normal! zz
  echo "Jumped to ".ref
endfunction

function willdo#ExecuteView() abort
  let viewnr = bufwinnr(b:willdo_view)

  if viewnr == -1
    echo "No view buffer"
    return
  end

  let winnr = bufwinnr('%')
  let win = winsaveview()

  exe viewnr . 'wincmd w'
  let viewwin = winsaveview()
  write
  silent exe "%!".shellescape(g:willdo_ruby).' '.shellescape(g:willdo_runner).' '.shellescape(bufname('%'))
  write
  call winrestview(viewwin)

  exe winnr . 'wincmd w'
  call winrestview(win)
endfunction

function willdo#Tag(args)
  exe "normal! o\<esc>I  :".a:args
  startinsert!
endfunction

function willdo#TagAbove(args)
  exe "normal! O\<esc>I  :".a:args
  startinsert!
endfunction

function willdo#MarkDone()
  let win = winsaveview()
  let date = strftime('%Y-%m-%d')
  exe "normal! o\<esc>I  :done ".date."\<esc>"
  call winrestview(win)
endfunction

" calendar.vim integration

function s:enable_calender()
  let g:calendar_action = "willdo#calendar_action"
  let s:calendar_return = bufwinnr('%')
endfunction

function willdo#calendar_action(day, month, year, week, dir)
  " Close calendar
  wincmd q
  " Jump back to file
  exe s:calendar_return . 'wincmd w'

  let char = getline(".")[col(".")-1]
  if char != " "
    exe "normal! a "
  endif

  exe "normal! a".printf('%04d-%02d-%02d', a:year, a:month, a:day)
endfunction

