" ==============================================================================
" Acessibility StatusLine & Nano-like Popup Helper
" ==============================================================================

" Variáveis de controle para salvar o estado anterior e restaurar depois
let s:old_cmdheight = &cmdheight
let s:old_statusline = &statusline
let s:old_laststatus = &laststatus
let s:nano_popup_id = -1

" Variável de estado (Trava) para evitar dupla execução (Problema 1)
let s:ui_active = 0

" 1. Função que retorna o modo atual em inglês para a StatusLine
function! AccessibilityGetVimMode()
    let l:m = mode()
    if l:m ==# 'n'
        return 'NORMAL'
    elseif l:m ==# 'i'
        return 'INSERT'
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
    if !has('popupwin')
        echohl WarningMsg
        echo "Aviso: O seu Vim não suporta popup_create. Atualize para a versão 8.2+"
        echohl None
        return
    endif

    if s:nano_popup_id != -1
        call popup_close(s:nano_popup_id)
    endif

    " --- LÓGICA DE RESPONSIVIDADE ---
    let l:width = &columns
    if l:width >= 90
        let l:content = [
            \ '  <Esc> Normal     i Insert       v Visual       R Replace      a Append       o New line',
            \ '  :     Command    :help Help     :w Save        :q Quit        :e Edit/Open   :! Ext cmd'
            \ ]
        let l:popup_content_height = 2
    elseif l:width >= 70
        let l:content = [
            \ '  <Esc> Normal       i Insert        v Visual       R Replace',
            \ '  a     Append       o New line      : Command      :help Help',
            \ '  :w    Save         :q Quit         :e Edit/Open   :! Ext cmd'
            \ ]
        let l:popup_content_height = 3
    elseif l:width >= 55
        let l:content = [
            \ '  <Esc> Normal     i Insert      v Visual',
            \ '  R     Replace    a Append      o New line',
            \ '  :     Command    :help Help    :w Save',
            \ '  :q    Quit       :e Edit/Open  :! Ext cmd'
            \ ]
        let l:popup_content_height = 4
    else
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
        " noautocmd impede que a mudança dispare o OptionSet novamente (evita loop infinito)
        noautocmd let &cmdheight = l:needed_cmdheight
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

    call win_execute(s:nano_popup_id, 'syntax match NanoShortcut /\(<Esc>\|:[a-z!]*\|\s\zs[iavoVR]\ze\s\+\)/')
endfunction

" 3. Comando de Ativação
function! s:EnableAccessibilityUI()
    " Proteção: Se já estiver ativo, não faz nada (preserva as variáveis old)
    if s:ui_active == 1
        return
    endif
    let s:ui_active = 1

    let s:old_cmdheight = &cmdheight
    let s:old_statusline = &statusline
    let s:old_laststatus = &laststatus
    set laststatus=2

    let l:stl = ''
    let l:stl .= ' [%{AccessibilityGetVimMode()}] ' 
    let l:stl .= '%='                               
    let l:stl .= 'Line: %l/%L '                     
    let l:stl .= '| Col: %c '                       
    let l:stl .= '| %p%% '                          
    let l:stl .= '| File: %t %m %r '                
    let &statusline = l:stl

    call s:DrawNanoPopup()

    augroup AccessibilityUIGroup
        autocmd!
        autocmd VimResized * call s:DrawNanoPopup()
        autocmd CmdlineEnter * if s:nano_popup_id != -1 | call popup_hide(s:nano_popup_id) | endif
        autocmd CmdlineLeave * if s:nano_popup_id != -1 | call popup_show(s:nano_popup_id) | endif
        
        " Auto-Correção: Se o usuário alterar o cmdheight, recalcula e restaura o layout (Problema 2)
        if exists('##OptionSet')
            autocmd OptionSet cmdheight call s:DrawNanoPopup()
        endif
    augroup END

    redraw
    echo "Accessibility UI Enabled"
endfunction

" 4. Comando de Desativação
function! s:DisableAccessibilityUI()
    " Proteção: Se já estiver desativado, não faz nada
    if s:ui_active == 0
        return
    endif
    let s:ui_active = 0

    " noautocmd usado para devolver o cmdheight antigo sem acionar o OptionSet
    noautocmd let &cmdheight = s:old_cmdheight
    let &statusline = s:old_statusline
    let &laststatus = s:old_laststatus

    if s:nano_popup_id != -1 && has('popupwin')
        call popup_close(s:nano_popup_id)
        let s:nano_popup_id = -1
    endif

    augroup AccessibilityUIGroup
        autocmd!
    augroup END

    redraw
    echo "Accessibility UI Disabled"
endfunction

" ==============================================================================
" Comandos para o Usuário
" ==============================================================================
command! AssistStatusLineOn call s:EnableAccessibilityUI()
command! AssistStatusLineOff call s:DisableAccessibilityUI()