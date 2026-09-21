" Impede que o plugin seja carregado mais de uma vez.
if exists('g:loaded_assist_plugin')
    finish
endif
let g:loaded_assist_plugin = 1

" Carrega todos os scripts dentro de autoload/, em qualquer subpasta
" (autoload/customized-search/, autoload/keyboard-shortcuts/, etc.),
" sem precisar listar cada arquivo aqui manualmente.
runtime! autoload/**/*.vim
