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

" Função global que permite fechar o popup executando :call ClosePopupSearch()
function! ClosePopupSearch() abort
    call s:CloseSearchPopup()
endfunction

" Inicia a pesquisa dentro do popup atual.
function! SearchInsidePopup() abort
    " Só executa se houver um popup válido.
    if s:search_popup_id <= 0
        return
    endif

    " Obtém o buffer utilizado pelo popup.
    let l:popup_buffer = winbufnr(s:search_popup_id)

    if l:popup_buffer <= 0
        return
    endif

    " Guarda somente o conteúdo original dos resultados.
    let s:popup_search_message = getbufline(l:popup_buffer, 3, '$')

    " Ativa o modo de pesquisa interna.
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
    " win_execute() roda a string como um comando Ex, não como expressão —
    " por isso precisa do "call" explícito antes de cursor(...).
    call win_execute(s:search_popup_id, 'call cursor(1, ' .
                \ (strlen(l:search_field) + 1) . ')')
endfunction

" Executa a pesquisa dentro dos resultados exibidos no popup.
function! s:ExecutePopupSearch() abort
    if s:search_popup_id <= 0
        return
    endif

    let l:query = tolower(s:popup_search_query)
    let l:filtered = []

    " Pesquisa literalmente dentro de cada linha do popup.
    " stridx() permite caracteres especiais sem tratá-los como regex.
    for l:line in s:popup_search_message
        if stridx(tolower(l:line), l:query) >= 0
            call add(l:filtered, l:line)
        endif
    endfor

    " Caso não encontre nada, informa o usuário dentro do próprio popup.
    if empty(l:filtered)
        let l:filtered = [' No matching text in search results.']
    endif

    " Mantém o campo de pesquisa no topo e substitui apenas os resultados.
    call popup_settext(s:search_popup_id, [
                \ ' Search: ' . s:popup_search_query,
                \ '',
                \ ] + l:filtered)

    " Posiciona o cursor no campo de pesquisa.
    call win_execute(s:search_popup_id, 'call cursor(1, ' .
                \ (strlen(' Search: ') + strlen(s:popup_search_query) + 1) . ')')
endfunction

" Processa teclas recebidas pelo popup de resultados.
function! s:SearchPopupFilter(popup_id, key) abort
    " Quando a pesquisa interna está ativa, as teclas são direcionadas
    " para o campo de pesquisa em vez de executar as funções do popup.
    if s:popup_search_mode
        " Enter executa a pesquisa.
        if a:key ==# "\<CR>"
            call s:ExecutePopupSearch()
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
            return s:SearchPopupFilter(a:popup_id, a:key)
        endif

        " Aceita caracteres digitados pelo usuário literalmente.
        " Caracteres especiais não são tratados como expressões regulares.
        if strlen(a:key) > 0
            let s:popup_search_query .= a:key
            call s:UpdatePopupSearchField()
            return 1
        endif

        return 1
    endif

    " Pressionar / dentro do popup inicia a pesquisa interna.
    " Na prática, o "/" quase nunca chega até aqui: o nnoremap global de "/"
    " tem prioridade sobre o filtro do popup, então quem trata esse caso de
    " verdade é o próprio CustomizedSearch() (veja o comentário lá).
    " Mantemos a checagem aqui como reforço, caso o filtro chegue a receber
    " a tecla em algum cenário (ex.: se o mapeamento global for removido).
    if a:key ==# '/'
        call SearchInsidePopup()
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
    " Removemos o título em texto rígido e deixamos o corpo mais limpo.
    let l:message = [
                \ ' Query: "' . strtrans(a:word) . '"',
                \ ' Matches: ' . len(a:found_lines),
                \ '',
                \ ]

    " Quando não há correspondências, finaliza a mensagem com um aviso claro.
    if empty(a:found_lines)
        call add(l:message, ' No matching text in this buffer.')
        return l:message
    endif

    " Adiciona uma linha para cada ocorrência encontrada no buffer atual.
    " Incluímos o texto da linha (não só o número) porque a pesquisa
    " interna do popup (SearchInsidePopup) filtra exatamente estas
    " strings — sem o conteúdo aqui, ela nunca teria uma palavra real
    " pra comparar, só números de linha.
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

    " Título embutido na borda do popup, separando visualmente do conteúdo.
    let l:options.title = ' Search Results '

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

    " Melhoria Visual: Usa cores normais e uma borda discreta.
    let l:options.highlight = 'Normal'
    let l:options.borderhighlight = ['Comment']

    " Melhoria Visual: Usa linhas contínuas para desenhar as bordas.
    let l:options.borderchars = ['─', '│', '─', '│', '┌', '┐', '┘', '└']

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

    " Por padrão (mapping = v:true), o Vim resolve cada tecla digitada como
    " mapeamento/comando normal ANTES de oferecê-la ao filtro — e só chega
    " ao filtro o que sobra, ou seja, teclas sem nenhum comando associado.
    " É por isso que "/" (busca nativa) e Enter (mover uma linha) nunca
    " chegavam ao filtro: o Vim já tinha "resolvido" as duas por conta
    " própria. Com mapping = v:false, toda tecla vai direto pro filtro,
    " sem passar pela resolução de comandos do Vim.
    let l:options.mapping = v:false

    return l:options
endfunction

" Exibe uma mensagem no popup e usa as mensagens do Vim como alternativa.
function! s:ShowSearchMessage(word, message) abort
    " Uma nova busca substitui visualmente o resultado da busca anterior.
    call s:CloseSearchPopup()

    " MELHORIA DE DESTAQUE: O Vim usa nativamente o grupo 'PopupSelected'.
    highlight! link PopupSelected WildMenu

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
        " Guarda o conteúdo original para a pesquisa interna.
        let s:popup_search_message = copy(a:message)

        " Adiciona o campo de pesquisa na parte superior do popup.
        let l:popup_message = [
                    \ ' Search: type / to search',
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
        echomsg 'CustomizedSearch: unable to display the search results popup.'
        echohl None
    endtry
endfunction

" Lê o termo digitado, procura-o no buffer atual e mostra o resultado.
function! CustomizedSearch() abort
    " O "/" é global (nnoremap), então ele chega aqui mesmo com o popup de
    " resultados já aberto — o filtro do popup nunca chega a ver essa tecla,
    " porque o mapeamento tem prioridade. Por isso, se já existe um popup
    " aberto, redirecionamos para a busca interna dele em vez de abrir uma
    " nova busca no arquivo.
    if s:search_popup_id > 0
        call SearchInsidePopup()
        return
    endif

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
        call s:ShowSearchMessage(
                    \ l:word,
                    \ s:BuildSearchMessage(l:word, l:found_lines))
        return
    endif

    " Converte o termo de busca para minúsculo uma única vez.
    let l:word_lower = tolower(l:word)

    " Percorre todas as linhas existentes no buffer atual.
    for l:line_number in range(1, line('$'))
        let l:line_content = getline(l:line_number)

        " Converte o conteúdo da linha para minúsculo no momento da verificação.
        if stridx(tolower(l:line_content), l:word_lower) >= 0
            call add(l:found_lines, l:line_number)
        endif
    endfor

    " Constrói e apresenta a lista final de resultados ao usuário.
    call s:ShowSearchMessage(
                \ l:word,
                \ s:BuildSearchMessage(l:word, l:found_lines))
endfunction

" Substitui / no modo normal pela busca personalizada, sem ecoar o comando.
nnoremap <silent> / :call CustomizedSearch()<CR>
