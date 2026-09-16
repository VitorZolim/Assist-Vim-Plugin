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
    " Modificado: Agora captura tanto 'R' (Replace) quanto 'r' (hit-enter / single replace)
    elseif l:m ==# 'R' || l:m ==# 'r' || l:m ==# 'Rv'
        return 'REPLACE'
    elseif l:m ==# 'v' || l:m ==# 'V' || l:m ==# "\<C-v>"
        return 'VISUAL'
    elseif l:m ==# 'c'
        return 'COMMAND'
    else
        return 'VIM'
    endif
endfunction

" 2. Função para desenhar o Popup de Acessibilidade responsivo
function! s:DrawNanoPopup()
    " Verifica se o Vim possui suporte a popups (Vim 8.2+)
    if !has('popupwin')
        echohl WarningMsg
        echo "Aviso: O seu Vim não suporta popup_create. Atualize para a versão 8.2+"
        echohl None
        return
    endif

    " Se o popup já existir, fecha-o antes de recriar
    if s:nano_popup_id != -1
        call popup_close(s:nano_popup_id)
    endif

    " --- LÓGICA DE RESPONSIVIDADE ---
    let l:width = &columns
    if l:width >= 90
        " Padrão / Tela Larga: 6 colunas (Layout 2x6 solicitado)
        let l:content = [
            \ '  <Esc> Normal     i Insert       v Visual       R Replace      a Append       o New line',
            \ '  :     Command    :help Help     :w Save        :q Quit        :e Edit/Open   :! Ext cmd'
            \ ]
        let l:popup_content_height = 2
    elseif l:width >= 70
        " Tela Média-Grande: 4 colunas
        let l:content = [
            \ '  <Esc> Normal       i Insert        v Visual       R Replace',
            \ '  a     Append       o New line      : Command      :help Help',
            \ '  :w    Save         :q Quit         :e Edit/Open   :! Ext cmd'
            \ ]
        let l:popup_content_height = 3
    elseif l:width >= 55
        " Tela Média: 3 colunas
        let l:content = [
            \ '  <Esc> Normal     i Insert      v Visual',
            \ '  R     Replace    a Append      o New line',
            \ '  :     Command    :help Help    :w Save',
            \ '  :q    Quit       :e Edit/Open  :! Ext cmd'
            \ ]
        let l:popup_content_height = 4
    else
        " Tela Estreita: 2 colunas
        let l:content = [
            \ '  <Esc> Normal     i Insert',
            \ '  v     Visual     R Replace',
            \ '  a     Append     o New line',
            \ '  :     Command    :help Help',
            \ '  :w    Save       :q Quit',
            \ '  :e    Edit/Open  :! Ext cmd'
            \ ]
        let l:popup_content_height = 6
    endif

    " --- CÁLCULO DE ESPAÇO E POSIÇÃO ---
    let l:needed_cmdheight = l:popup_content_height + 3
    if &cmdheight != l:needed_cmdheight
        let &cmdheight = l:needed_cmdheight
    endif

    " --- ESTILIZAÇÃO DO POPUP ---
    highlight default NanoBorder ctermfg=Cyan guifg=#00FFFF
    highlight default NanoShortcut ctermfg=0 ctermbg=7 guifg=#000000 guibg=#ffffff

    let s:nano_popup_id = popup_create(l:content, #{
        \ line: &lines - &cmdheight + 2,
        \ col: 1,
        \ minwidth: &columns - 2,
        \ maxwidth: &columns - 2,
        \ wrap: 0,
        \ mapping: 0,
        \ zindex: 50,
        \ highlight: 'Normal',
        \ border: [1, 1, 1, 1],
        \ borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
        \ borderhighlight: ['NanoBorder']
        \ })

    " Aplica o highlight (Modificado para :[a-z!]* permitindo que o ':' isolado seja grifado)
    call win_execute(s:nano_popup_id, 'syntax match NanoShortcut /\(<Esc>\|:[a-z!]*\|\s\zs[iavoVR]\ze\s\+\)/')
endfunction

" 3. Comando de Ativação
function! s:EnableAccessibilityUI()
    " Salva as configurações atuais
    let s:old_cmdheight = &cmdheight
    let s:old_statusline = &statusline
    let s:old_laststatus = &laststatus
    set laststatus=2

    " Monta a StatusLine (Mantida intacta)
    let l:stl = ''
    let l:stl .= ' [%{AccessibilityGetVimMode()}] ' 
    let l:stl .= '%='                               
    let l:stl .= 'Line: %l/%L '                     
    let l:stl .= '| Col: %c '                       
    let l:stl .= '| %p%% '                          
    let l:stl .= '| File: %t %m %r '                
    let &statusline = l:stl

    " Desenha o popup
    call s:DrawNanoPopup()

    " Configura autocommands (Restaurado o comportamento anterior para o Cmdline)
    augroup AccessibilityUIGroup
        autocmd!
        autocmd VimResized * call s:DrawNanoPopup()
        " Esconde o popup ao entrar no modo de comando para liberar a visualização
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