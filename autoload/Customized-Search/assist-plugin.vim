" Vim 9.1 - busca literal personalizada com resultados em um popup lateral.

" Impede que este mesmo arquivo seja carregado e mapeado mais de uma vez.
if exists('g:loaded_assist_plugin_search')
    finish
endif

" Marca o script como carregado para a próxima tentativa de source/autoload.
let g:loaded_assist_plugin_search = 1

" Guarda o identificador do popup e do grifo; zero significa nenhum.
let s:search_popup_id = 0
let s:search_match_id = 0

" Estado da pesquisa interna do popup.
let s:popup_search_mode = 0
let s:popup_search_query = ''
let s:popup_search_message = []

" Fecha o popup de resultado e limpa o grifo do arquivo.
function! s:CloseSearchPopup() abort
    " Só tenta fechar o popup se houver um ID válido.
    if s:search_popup_id > 0 && exists('*popup_close')
        silent! call popup_close(s:search_popup_id)
    endif
    let s:search_popup_id = 0

    " Remove o grifo (highlight) da palavra no arquivo principal.
    if s:search_match_id > 0
        silent! call matchdelete(s:search_match_id)
    endif
    let s:search_match_id = 0

    " Limpa o estado da pesquisa interna.
    let s:popup_search_mode = 0
    let s:popup_search_query = ''
    let s:popup_search_message = []
endfunction

" =====================================================================
" Comandos Públicos para o Usuário
" =====================================================================
command! AssistSearchClose call s:CloseSearchPopup()
command! AssistSearch call s:CustomizedSearch()


" Inicia a pesquisa dentro do popup atual.
function! s:SearchInsidePopup() abort
    " Só executa se houver um popup válido.
    if s:search_popup_id <= 0
        return
    endif

    " Ativa o modo de pesquisa interna.
    " OBS: Não capturamos mais as linhas com getbufline() aqui, 
    " pois a variável s:popup_search_message já mantém o estado real e atualizado.
    let s:popup_search_mode = 1
    let s:popup_search_query = ''

    " Atualiza o campo de pesquisa no topo do popup.
    call s:UpdatePopupSearchField()
endfunction

" Atualiza o campo de pesquisa no topo do popup.
function! s:UpdatePopupSearchField() abort
    if s:search_popup_id <= 0
        return
    endif

    " O texto explica ao usuário o propósito do campo.
    let l:search_field = ' Search: press / to type'

    if s:popup_search_mode
        let l:search_field = ' Search: ' . s:popup_search_query
    endif

    " Reconstrói o conteúdo sem alterar o buffer principal.
    call popup_settext(s:search_popup_id, [
                \ l:search_field,
                \ '',
                \ ] + s:popup_search_message)

    " Mantém o cursor visual no campo de pesquisa.
    call win_execute(s:search_popup_id, 'call cursor(1, ' .
                \ (strlen(l:search_field) + 1) . ')')
endfunction

" Executa a pesquisa e atualiza permanentemente os resultados exibidos.
function! s:ExecutePopupSearch() abort
    if s:search_popup_id <= 0
        return
    endif

    let l:word = s:popup_search_query
    let l:found_lines = []

    " Se a busca não for vazia, faz uma nova varredura completa no buffer atual.
    if !empty(l:word)
        let l:word_lower = tolower(l:word)
        for l:line_number in range(1, line('$'))
            let l:line_content = getline(l:line_number)
            if stridx(tolower(l:line_content), l:word_lower) >= 0
                call add(l:found_lines, l:line_number)
            endif
        endfor
    endif

    " ATUALIZAÇÃO 1: Substitui permanentemente a pesquisa anterior pela nova
    let s:popup_search_message = s:BuildSearchMessage(l:word, l:found_lines)

    " ATUALIZAÇÃO 1.1: Atualiza o destaque (highlight) no buffer principal
    if s:search_match_id > 0
        silent! call matchdelete(s:search_match_id)
    endif
    
    if !empty(l:word)
        let l:pattern = '\c\V' . escape(l:word, '\')
        let s:search_match_id = matchadd('Search', l:pattern)
    else
        let s:search_match_id = 0
    endif
endfunction

" Processa teclas recebidas pelo popup de resultados.
function! s:SearchPopupFilter(popup_id, key) abort
    " Quando a pesquisa interna está ativa, as teclas são direcionadas
    " para o campo de pesquisa em vez de executar as funções do popup.
    if s:popup_search_mode
        " ATUALIZAÇÃO 2: Enter executa a pesquisa e SAI do modo de edição.
        if a:key ==# "\<CR>"
            call s:ExecutePopupSearch()
            let s:popup_search_mode = 0
            call s:UpdatePopupSearchField()
            return 1
        endif

        " Esc cancela a pesquisa interna e restaura os resultados originais.
        if a:key ==# "\<Esc>"
            let s:popup_search_mode = 0
            let s:popup_search_query = ''
            call s:UpdatePopupSearchField()
            return 1
        endif

        " Backspace remove o último caractere digitado.
        if a:key ==# "\<BS>" || a:key ==# "\<Del>"
            if !empty(s:popup_search_query)
                let s:popup_search_query =
                            \ strpart(
                            \ s:popup_search_query,
                            \ 0,
                            \ strlen(s:popup_search_query) - 1)

                call s:UpdatePopupSearchField()
            endif
            return 1
        endif

        " Ctrl+U limpa o campo de pesquisa.
        if a:key ==# "\<C-u>"
            let s:popup_search_query = ''
            call s:UpdatePopupSearchField()
            return 1
        endif

        " Ctrl+G continua funcionando mesmo durante a pesquisa.
        if a:key ==# "\<C-g>"
            let s:popup_search_mode = 0
            call s:UpdatePopupSearchField()
            return s:SearchPopupFilter(a:popup_id, a:key)
        endif

        " Aceita caracteres digitados pelo usuário literalmente.
        if strlen(a:key) > 0
            let s:popup_search_query .= a:key
            call s:UpdatePopupSearchField()
            return 1
        endif

        return 1
    endif

    " Pressionar / dentro do popup inicia a pesquisa interna.
    if a:key ==# '/'
        call s:SearchInsidePopup()
        return 1
    endif

    " Esc e q fecham somente a janela de resultados, sem alterar o buffer.
    if a:key ==# "\<Esc>" || a:key ==# 'q'
        call s:CloseSearchPopup()
        return 1
    endif

    " Rola o popup para baixo usando Ctrl + j (ou Ctrl + Down)
    if a:key ==# "\<C-j>" || a:key ==# "\<C-Down>"
        call win_execute(a:popup_id, 'normal! j')
        return 1
    endif

    " Rola o popup para cima usando Ctrl + k (ou Ctrl + Up)
    if a:key ==# "\<C-k>" || a:key ==# "\<C-Up>"
        call win_execute(a:popup_id, 'normal! k')
        return 1
    endif

    " Vai até a linha referenciada no popup usando Ctrl + g (Go to)
    if a:key ==# "\<C-g>"
        let l:popup_line_nr = str2nr(trim(win_execute(a:popup_id, 'echo line(".")')))
        let l:popup_line_text = getbufline(winbufnr(a:popup_id), l:popup_line_nr)[0]
        let l:target_line = matchstr(l:popup_line_text, 'Line \zs\d\+')

        if !empty(l:target_line)
            call cursor(str2nr(l:target_line), 1)
            normal! zz
        endif

        return 1
    endif

    " Devolve as demais teclas ao Vim (permite editar texto, usar j/k, Enter, etc)
    return 0
endfunction

" Monta as linhas de texto que serão exibidas no popup ou nas mensagens.
function! s:BuildSearchMessage(word, found_lines) abort
    let l:message = [
                \ ' Query: "' . strtrans(a:word) . '"',
                \ ' Matches: ' . len(a:found_lines),
                \ '',
                \ ]

    if empty(a:found_lines)
        call add(l:message, ' No matching text in this buffer.')
        return l:message
    endif

    call add(l:message, ' Found in lines:')
    for l:line_number in a:found_lines
        call add(l:message,
                    \ printf('   Line %d: %s', l:line_number, getline(l:line_number)))
    endfor

    return l:message
endfunction

" Monta as opções de posição/aparência do popup lateral.
function! s:BuildSearchPopupOptions() abort
    let l:options = {}

    let l:options.title = ' Search Results '
    let l:options.line = 1
    let l:options.col = &columns
    let l:options.pos = 'topright'
    let l:options.minwidth = 32
    let l:options.maxwidth = 46
    let l:options.minheight = 8
    let l:options.maxheight = 22
    let l:options.padding = [0, 1, 0, 1]
    let l:options.border = [1, 1, 1, 1]
    let l:options.highlight = 'Normal'
    let l:options.borderhighlight = ['Comment']
    let l:options.borderchars = ['─', '│', '─', '│', '┌', '┐', '┘', '└']
    let l:options.scrollbar = 1
    let l:options.cursorline = 1
    let l:options.wrap = 0
    let l:options.close = 'button'
    let l:options.filter = function('s:SearchPopupFilter')
    let l:options.mapping = v:false

    return l:options
endfunction

" Exibe uma mensagem no popup e usa as mensagens do Vim como alternativa.
function! s:ShowSearchMessage(word, message) abort
    call s:CloseSearchPopup()

    highlight! link PopupSelected WildMenu

    if !exists('*popup_create')
        echohl WarningMsg
        echomsg 'AssistSearch: popup windows are not available in this Vim.'
        echohl None

        for l:line in a:message
            echomsg l:line
        endfor
        return
    endif

    try
        " Guarda o conteúdo original para a pesquisa interna.
        let s:popup_search_message = copy(a:message)

        " Adiciona o campo de pesquisa na parte superior do popup.
        let l:popup_message = [
                    \ ' Search: press / to type',
                    \ '',
                    \ ] + a:message

        let s:search_popup_id =
                    \ popup_create(l:popup_message, s:BuildSearchPopupOptions())

        " Destaca a palavra buscada no arquivo principal.
        let l:pattern = '\c\V' . escape(a:word, '\')
        let s:search_match_id = matchadd('Search', l:pattern)
    catch /^Vim\%((\a\+)\)\=:E/
        let s:search_popup_id = 0
        echohl ErrorMsg
        echomsg 'AssistSearch: unable to display the search results popup.'
        echohl None
    endtry
endfunction

" Lê o termo digitado, procura-o no buffer atual e mostra o resultado.
" ATUALIZAÇÃO 3: Transformada em função interna (s:) acessada por comando
function! s:CustomizedSearch() abort
    if s:search_popup_id > 0
        call s:SearchInsidePopup()
        return
    endif

    let l:word = input('/')

    if type(l:word) != v:t_string || empty(l:word)
        return
    endif

    if stridx(l:word, "\n") >= 0 || stridx(l:word, "\r") >= 0
        echohl WarningMsg
        echomsg 'AssistSearch: use a single-line search term.'
        echohl None
        return
    endif

    let l:found_lines = []

    if line('$') == 1 && getline(1) ==# ''
        call s:ShowSearchMessage(
                    \ l:word,
                    \ s:BuildSearchMessage(l:word, l:found_lines))
        return
    endif

    let l:word_lower = tolower(l:word)

    for l:line_number in range(1, line('$'))
        let l:line_content = getline(l:line_number)

        if stridx(tolower(l:line_content), l:word_lower) >= 0
            call add(l:found_lines, l:line_number)
        endif
    endfor

    call s:ShowSearchMessage(
                \ l:word,
                \ s:BuildSearchMessage(l:word, l:found_lines))
endfunction

" ATUALIZAÇÃO 3: Utilizando o novo comando público para o atalho
nnoremap <silent> / :AssistSearch<CR>