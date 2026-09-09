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
endfunction

" Função global que permite fechar o popup executando :call ClosePopupSearch()
function! ClosePopupSearch() abort
    call s:CloseSearchPopup()
endfunction

" Processa teclas recebidas pelo popup de resultados.
function! s:SearchPopupFilter(popup_id, key) abort
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
        " 1. Obtém o número da linha selecionada DENTRO do popup
        let l:popup_line_nr = str2nr(trim(win_execute(a:popup_id, 'echo line(".")')))
        
        " 2. Pega o conteúdo de texto dessa linha no popup
        let l:popup_line_text = getbufline(winbufnr(a:popup_id), l:popup_line_nr)[0]

        " 3. Extrai apenas o número da string (ex: de '   Line 14' pega '14')
        let l:target_line = matchstr(l:popup_line_text, 'Line \zs\d\+')

        " 4. Se a linha contiver um número de fato, faz o salto no arquivo
        if !empty(l:target_line)
            " Move o cursor para a linha extraída (1 = primeira coluna)
            call cursor(str2nr(l:target_line), 1)
            
            " Centraliza a tela na nova posição (boa prática de usabilidade)
            normal! zz
        endif
        
        return 1
    endif

    " Devolve as demais teclas ao Vim (permite editar texto, usar j/k, Enter, etc)
    return 0
endfunction

" Monta as linhas de texto que serão exibidas no popup ou nas mensagens.
function! s:BuildSearchMessage(word, found_lines) abort
    " strtrans() torna caracteres especiais legíveis sem mudar o termo buscado.
    let l:message = [
                \ ' Search Results ',
                \ '',
                \ ' Query: "' . strtrans(a:word) . '"',
                \ '',
                \ ' Matches: ' . len(a:found_lines),
                \ ]

    " Quando não há correspondências, finaliza a mensagem com um aviso claro.
    if empty(a:found_lines)
        call add(l:message, ' No matching text in this buffer.')
        return l:message
    endif

    " Adiciona uma linha para cada ocorrência encontrada no buffer atual.
    call add(l:message, ' Found in lines:')
    for l:line_number in a:found_lines
        call add(l:message, printf('   Line %d', l:line_number))
    endfor

    return l:message
endfunction

" Monta as opções de posição/aparência do popup lateral.
function! s:BuildSearchPopupOptions() abort
    let l:options = {}

    " Ancora o popup no canto superior direito da área de edição.
    let l:options.line = 1
    let l:options.col = &columns
    let l:options.pos = 'topright'

    " Mantém uma largura confortável sem ocupar toda a tela.
    let l:options.minwidth = 32
    let l:options.maxwidth = 46

    " Limita a altura e deixa a lista utilizável em resultados longos.
    let l:options.minheight = 8
    let l:options.maxheight = 22

    " Insere espaço interno entre o texto e a borda.
    let l:options.padding = [0, 1, 0, 1]

    " Desenha uma borda simples ao redor da janela lateral.
    let l:options.border = [1, 1, 1, 1]

    " Exibe uma barra de rolagem se as linhas ultrapassarem a altura.
    let l:options.scrollbar = 1
    
    " Ativa o destaque da linha atual selecionada no popup.
    let l:options.cursorline = 1

    " Evita quebrar linhas compridas e mantém os itens alinhados.
    let l:options.wrap = 0

    " Adiciona um botão de fechamento ao popup.
    let l:options.close = 'button'

    " Liga o filtro que permite fechar por Esc ou q e navegar com j/k/Setas.
    let l:options.filter = function('s:SearchPopupFilter')

    return l:options
endfunction

" Exibe uma mensagem no popup e usa as mensagens do Vim como alternativa.
function! s:ShowSearchMessage(word, message) abort
    " Uma nova busca substitui visualmente o resultado da busca anterior.
    call s:CloseSearchPopup()

    " Alguns builds do Vim não foram compilados com suporte a janelas popup.
    if !exists('*popup_create')
        echohl WarningMsg
        echomsg 'CustomizedSearch: popup windows are not available in this Vim.'
        echohl None

        for l:line in a:message
            echomsg l:line
        endfor
        return
    endif

    " A criação pode falhar por configuração do Vim ou limitação do terminal.
    try
        let s:search_popup_id = popup_create(a:message, s:BuildSearchPopupOptions())
        
        " Destaca (highlight) a palavra buscada no arquivo principal (janela atual).
        let l:pattern = '\V' . escape(a:word, '\')
        let s:search_match_id = matchadd('Search', l:pattern)
    catch /^Vim\%((\a\+)\)\=:E/
        let s:search_popup_id = 0
        echohl ErrorMsg
        echomsg 'CustomizedSearch: unable to display the search results popup.'
        echohl None
    endtry
endfunction

" Lê o termo digitado, procura-o no buffer atual e mostra o resultado.
function! CustomizedSearch() abort
    " input() retorna texto vazio tanto ao pressionar Esc como ao enviar vazio.
    let l:word = input('/')

    " Nos dois casos não há pesquisa a executar nem popup a criar.
    if type(l:word) != v:t_string || empty(l:word)
        return
    endif

    " O termo aparece em uma única linha no popup; rejeita quebras de linha.
    if stridx(l:word, "\n") >= 0 || stridx(l:word, "\r") >= 0
        echohl WarningMsg
        echomsg 'CustomizedSearch: use a single-line search term.'
        echohl None
        return
    endif

    " Armazena os números das linhas que contêm o termo pesquisado.
    let l:found_lines = []

    " Um buffer novo/vazio aparece no Vim como uma linha vazia.
    if line('$') == 1 && getline(1) ==# ''
        call s:ShowSearchMessage(l:word, s:BuildSearchMessage(l:word, l:found_lines))
        return
    endif

    " Percorre todas as linhas existentes no buffer atual, da primeira à última.
    for l:line_number in range(1, line('$'))
        let l:line_content = getline(l:line_number)

        if stridx(l:line_content, l:word) >= 0
            call add(l:found_lines, l:line_number)
        endif
    endfor

    " Constrói e apresenta a lista final de resultados ao usuário.
    call s:ShowSearchMessage(l:word, s:BuildSearchMessage(l:word, l:found_lines))
endfunction

" Substitui / no modo normal pela busca personalizada, sem ecoar o comando.
nnoremap <silent> / :call CustomizedSearch()<CR>