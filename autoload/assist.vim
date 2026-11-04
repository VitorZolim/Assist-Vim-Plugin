" Vim autoload script: assist#*
" Ativa/desativa o plugin inteiro com um único comando.
" Maintainer:  victorfg-dev
" License:     veja o arquivo LICENSE na raiz do plugin
"
" Os comandos :AssistOn e :AssistOff são definidos em plugin/assist-plugin.vim.

let s:save_cpo = &cpo
set cpo&vim

let s:enabled = 0
let s:mapped_slash = 0

" Ativa busca assistida (/), StatusLine com guia de teclas e atalhos.
function! assist#Enable() abort
    if s:enabled
        echo 'Assist-Plugin: já está ativo (use :AssistOff para desativar)'
        return
    endif
    let s:enabled = 1

    " Mapeia "/" apenas se estiver livre e o usuário não optou por não mapear.
    if !exists('g:assist_plugin_no_mappings') && !hasmapto('<Plug>AssistSearch', 'n')
                \ && maparg('/', 'n') ==# ''
        nmap <silent> / <Plug>AssistSearch
        let s:mapped_slash = 1
    endif

    call assist#statusline#Enable()
    call assist#shortcut#Enable()

    redraw
    echo 'Assist-Plugin ativado (:AssistOff para desativar)'
endfunction

" Desfaz tudo e restaura as configurações anteriores do usuário.
function! assist#Disable() abort
    if !s:enabled
        echo 'Assist-Plugin: não está ativo'
        return
    endif
    let s:enabled = 0

    call assist#shortcut#Disable()
    call assist#statusline#Disable()
    call assist#search#Close()

    " Só remove o "/" se foi o plugin quem mapeou e ainda é o mesmo mapeamento.
    if s:mapped_slash && maparg('/', 'n') ==# '<Plug>AssistSearch'
        silent! nunmap /
    endif
    let s:mapped_slash = 0

    redraw
    echo 'Assist-Plugin desativado'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
