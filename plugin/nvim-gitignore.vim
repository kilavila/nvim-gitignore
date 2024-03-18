if exists('g:loaded_nvim_gitignore') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! Gitignore lua require'nvim-gitignore'.gitignore()
command! Licenses lua require'nvim-licenses'.licenses()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_nvim_gitignore = 1
