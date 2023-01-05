
""-- vim-go specific configuration
"" run :GoBuild or :GoTestCompile based on the go file
"function! s:build_go_files()
"  let l:file = expand('%')
"  if l:file =~# '^\f\+_test\.go$'
"    call go#test#Test(0, 1)
"  elseif l:file =~# '^\f\+\.go$'
"    call go#cmd#Build(0)
"  endif
"endfunction


" autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
" autocmd FileType go nmap <leader>c <Plug>(go-coverage-toggle)
" autocmd FileType go nmap <leader>t <Plug>(go-test)

" autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
" autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
" autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
" autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')

" autocmd FileType go setlocal foldmethod=expr foldexpr=getline(v:lnum)=~'^\s*'.&commentstring[0]

" let g:go_list_type = "quickfix"    " error lists are of type quickfix
" let g:go_fmt_command = "goimports" " automatically format and rewrite imports
" let g:go_auto_sameids = 1          " highlight matching identifiers
" let g:go_sameids = 1          " highlight matching identifiers


" go syntax highlighting
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_generate_tags = 1
let g:go_gopls_enabled = 0 " disable vim-go lsp (we're using coc instead)
" disable vim-go :GoDef short cut (gd)
" this is handled by LanguageClient [LC]
let g:go_def_mapping_enabled = 0
    
" " modify the godebug panes to a more minamalist look
" let g:go_debug_windows = {
"       \ 'vars':       'rightbelow 50vnew',
"       \ 'stack':      'rightbelow 10new',
"       \ }
"       " \ 'goroutines':      'rightbelow 10new',
" let g:go_debug_mappings = {
"       \ '(go-debug-continue)': {'key': 'c', 'arguments': '<nowait>'},
"       \ '(go-debug-next)': {'key': 'n', 'arguments': '<nowait>'},
"       \ '(go-debug-step)': {'key': 's'},
"       \ '(go-debug-print)': {'key': 'p'},
"   \}

" " preserve debugging layout
" let g:go_debug_preserve_layout = 1

" " breakpoint sign text
" let g:go_debug_breakpoint_sign_text = '>'

" map <leader>ds :GoDebugTest<cr>
" map <leader>dt :GoDebugStop<cr>
" map <leader>db :GoDebugBreakpoint<cr>

