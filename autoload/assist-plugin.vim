" Vim 9.1 - busca literal personalizada com resultados em um popup lateral.

" Impede que este mesmo arquivo seja carregado e mapeado mais de uma vez.
if exists('g:loaded_assist_plugin_search')
    finish
endif

" Marca o script como carregado para a próxima tentativa de source/autoload.
let g:loaded_assist_plugin_search = 1

" Guarda o identificador do popup atualmente aberto; zero significa nenhum.
let s:search_popup_id = 0

" Fecha o popup de resultado que a pesquisa anterior deixou aberto.
function! s:CloseSearchPopup() abort
    " Só tenta fechar quando há um ID válido e a função existe nesta instalação.
    if s:search_popup_id > 0 && exists('*popup_close')
        " silent! evita uma mensagem de erro se o usuário já fechou o popup.
        silent! call popup_close(s:search_popup_id)
    endif

    " Limpa o ID mesmo se não havia popup ou se ele já estava fechado.
    let s:search_popup_id = 0
endfunction

" Processa teclas recebidas pelo popup de resultados.
function! s:SearchPopupFilter(popup_id, key) abort
    " Esc e q fecham somente a janela de resultados, sem alterar o buffer.
    if a:key ==# "\<Esc>" || a:key ==# 'q'
        call s:CloseSearchPopup()

        " Informa ao Vim que a tecla foi consumida por este filtro.
        return 1
    endif

    " Devolve as demais teclas ao Vim, inclusive as usadas para rolagem.
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
"
" Construída com atribuições separadas (uma linha por chave), em vez de um
" dicionário literal continuado com "\", porque comentários colocados como
" linhas de continuação isoladas quebram o parser do Vim: todas as linhas
" de continuação são concatenadas em uma única linha lógica ANTES de serem
" interpretadas, e a primeira aspa dupla de um comentário abre uma string
" que só termina na aspa dupla do comentário seguinte - engolindo os pares
" chave/valor que ficariam no meio do caminho. Aqui cada comentário fica em
" sua própria linha completa (não em continuação), o que é seguro.
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

    " Evita quebrar linhas compridas e mantém os itens alinhados.
    let l:options.wrap = 0

    " Adiciona um botão de fechamento ao popup.
    let l:options.close = 'button'

    " Liga o filtro que permite fechar por Esc ou q.
    let l:options.filter = function('s:SearchPopupFilter')

    return l:options
endfunction

" Exibe uma mensagem no popup e usa as mensagens do Vim como alternativa.
function! s:ShowSearchMessage(message) abort
    " Uma nova busca substitui visualmente o resultado da busca anterior.
    call s:CloseSearchPopup()

    " Alguns builds do Vim não foram compilados com suporte a janelas popup.
    if !exists('*popup_create')
        echohl WarningMsg
        echomsg 'CustomizedSearch: popup windows are not available in this Vim.'
        echohl None

        " Mantém o resultado acessível mesmo sem suporte a +popupwin.
        for l:line in a:message
            echomsg l:line
        endfor
        return
    endif

    " A criação pode falhar por configuração do Vim ou limitação do terminal.
    try
        let s:search_popup_id = popup_create(a:message, s:BuildSearchPopupOptions())
    catch /^Vim\%((\a\+)\)\=:E/
        " Não mantém um ID inválido se o popup não pôde ser criado.
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

    " Um buffer novo/vazio aparece no Vim como uma linha vazia; trata-o como
    " arquivo vazio, em vez de considerar essa linha como conteúdo pesquisável.
    if line('$') == 1 && getline(1) ==# ''
        call s:ShowSearchMessage(s:BuildSearchMessage(l:word, l:found_lines))
        return
    endif

    " Percorre todas as linhas existentes no buffer atual, da primeira à última.
    for l:line_number in range(1, line('$'))
        " Obtém o conteúdo da linha que está sendo analisada.
        let l:line_content = getline(l:line_number)

        " stridx() procura um trecho literal, sensível a maiúsculas/minúsculas.
        if stridx(l:line_content, l:word) >= 0
            " Registra o número da linha quando o trecho é encontrado.
            call add(l:found_lines, l:line_number)
        endif
    endfor

    " Constrói e apresenta a lista final de resultados ao usuário.
    call s:ShowSearchMessage(s:BuildSearchMessage(l:word, l:found_lines))
endfunction

" Substitui / no modo normal pela busca personalizada, sem ecoar o comando.
nnoremap <silent> / :call CustomizedSearch()<CR>