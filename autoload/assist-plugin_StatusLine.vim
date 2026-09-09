" ==============================================================================
" Acessibility StatusLine & Nano-like Popup Helper
" ==============================================================================

" Variáveis de controle para salvar o estado anterior e restaurar depois
let s:old_cmdheight = &cmdheight
let s:old_statusline = &statusline
let s:old_laststatus = &laststatus
let s:nano_popup_id = -1

" 1. Função que retorna o modo atual em inglês para a StatusLine
function! AccessibilityGetVimMode()
    let l:m = mode()
    if l:m ==# 'n'
        return 'NORMAL'
    elseif l:m ==# 'i'
        return 'INSERT'
    elseif l:m ==# 'R'
        return 'REPLACE'
    elseif l:m ==# 'v' || l:m ==# 'V' || l:m ==# "\<C-v>"
        return 'VISUAL'
    elseif l:m ==# 'c'
        return 'COMMAND'
    else
        return 'VIM'
    endif
endfunction

" 2. Função para desenhar o Popup de Acessibilidade (estilo nano)
function! s:DrawNanoPopup()
    " Verifica se o Vim possui suporte a popups (Vim 8.2+)
    if !has('popupwin')
        echohl WarningMsg
        echo "Aviso: O seu Vim não suporta popup_create. Atualize para a versão 8.2+"
        echohl None
        return
    endif

    " Se o popup já existir, fecha-o antes de recriar (útil para redimensionamento)
    if s:nano_popup_id != -1
        call popup_close(s:nano_popup_id)
    endif

    " Grade minimalista, idêntica ao padrão nano com colunas retas e diretas (3 linhas)
    let l:content = [
        \ '  <Esc> Normal       i Insert        v Visual       : Command',
        \ '  :w    Save         a Append        o New line     :help Help',
        \ '  :q    Quit         :e Edit/Open    :! Ext cmd     R Replace'
        \ ]

    " Cria o popup. O cálculo '&lines - 3' garante que o popup desça mais, 
    " deixando exatamente o último espaço da tela para ver os comandos digitados.
    let s:nano_popup_id = popup_create(l:content, #{
        \ line: &lines - 3,
        \ col: 1,
        \ minwidth: &columns,
        \ maxwidth: &columns,
        \ wrap: 0,
        \ mapping: 0,
        \ zindex: 50,
        \ highlight: 'Normal'
        \ })

    " --- ESTILIZAÇÃO NANO ---
    " Cria um Highlight group para inverter as cores (texto preto, fundo branco)
    highlight default NanoShortcut ctermfg=0 ctermbg=7 guifg=#000000 guibg=#ffffff
    
    " Aplica a sintaxe apenas dentro do buffer do popup para destacar os atalhos
    call win_execute(s:nano_popup_id, 'syntax match NanoShortcut /\(<Esc>\|:[a-z!]\+\|\s\zs[iavoVR]\ze\s\)/')
endfunction

" 3. Comando de Ativação
function! s:EnableAccessibilityUI()
    " Salva as configurações atuais
    let s:old_cmdheight = &cmdheight
    let s:old_statusline = &statusline
    let s:old_laststatus = &laststatus

    " Ajuste para 5, mantendo um espaço bom na base para o popup e o input
    set cmdheight=5
    set laststatus=2

    " Monta a StatusLine isolando o Modo à esquerda e o resto à direita
    let l:stl = ''
    let l:stl .= ' [%{AccessibilityGetVimMode()}] ' " Modo atual na extrema ESQUERDA
    let l:stl .= '%='                               " Empurra TODO O RESTO para a DIREITA
    let l:stl .= 'Line: %l/%L '                     " Linha atual / Total de linhas
    let l:stl .= '| Col: %c '                       " Coluna atual
    let l:stl .= '| %p%% '                          " Porcentagem atual do arquivo
    let l:stl .= '| File: %t %m %r '                " Nome do arquivo por último

    let &statusline = l:stl

    " Desenha o popup pela primeira vez
    call s:DrawNanoPopup()

    " Configura autocommands para o comportamento responsivo do popup
    augroup AccessibilityUIGroup
        autocmd!
        " Redesenha o popup ao redimensionar a janela do terminal
        autocmd VimResized * call s:DrawNanoPopup()
        " Esconde o popup ao entrar no modo de comando
        autocmd CmdlineEnter * if s:nano_popup_id != -1 | call popup_hide(s:nano_popup_id) | endif
        autocmd CmdlineLeave * if s:nano_popup_id != -1 | call popup_show(s:nano_popup_id) | endif
    augroup END

    redraw
    echo "Accessibility UI Enabled"
endfunction

" 4. Comando de Desativação
function! s:DisableAccessibilityUI()
    " Restaura as opções antigas
    let &cmdheight = s:old_cmdheight
    let &statusline = s:old_statusline
    let &laststatus = s:old_laststatus

    " Fecha e reseta o popup
    if s:nano_popup_id != -1 && has('popupwin')
        call popup_close(s:nano_popup_id)
        let s:nano_popup_id = -1
    endif

    " Limpa os eventos do autocommand
    augroup AccessibilityUIGroup
        autocmd!
    augroup END

    redraw
    echo "Accessibility UI Disabled"
endfunction

" ==============================================================================
" Comandos para o Usuário
" ==============================================================================
command! AccessibilityOn call s:EnableAccessibilityUI()
command! AccessibilityOff call s:DisableAccessibilityUI()