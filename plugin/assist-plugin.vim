" Impede que o plugin seja carregado mais de uma vez.
if exists('g:loaded_assist_plugin')
    finish
endif
let g:loaded_assist_plugin = 1

" Carrega o script principal em autoload/, que define as funções
" de busca (CustomizedSearch, ShowSearchMessage etc.) e o mapeamento do "/".
runtime! autoload/assist-plugin.vim
