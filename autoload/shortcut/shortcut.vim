" referencia do arquivo: [ $VIMRUNTIME/mswin.vim ] 

" funcao de ativacao dos atalhos
function! shortcut#Enable() abort
    " forca setas funcionarem
    set nocompatible

    " corrige o mapeamento das setas nas emulacoes de terminal  
    if &term =~ 'xterm' || &term =~ 'vt100' || &term =~ 'screen' || &term =~ 'linux' || &term =~ 'tmux'
        let &t_ku = "\<Esc>OA"
        let &t_kd = "\<Esc>OB"
        let &t_kr = "\<Esc>OC"
        let &t_kl = "\<Esc>OD"
    endif

    " setas funcionando para modo Normal
    nnoremap <Up> k
    nnoremap <Down> j
    nnoremap <Left> h
    nnoremap <Right> l
    
    " setas funcionando para modo Inserção
    inoremap <Up> <C-o>k
    inoremap <Down> <C-o>j
    inoremap <Left> <C-o>h
    inoremap <Right> <C-o>l

    " CORREÇÃO: setas funcionando para modo Visual e Select
    vnoremap <Up> k
    vnoremap <Down> j
    vnoremap <Left> h
    vnoremap <Right> l

    " Salva as configurações originais do usuário antes do mswin.vim
    let s:save_keymodel = &keymodel
    let s:save_selection = &selection
    let s:save_selectmode = &selectmode
    let s:save_backspace = &backspace

    " ativa os atalhos padrões de editores do windows
    silent! source $VIMRUNTIME/mswin.vim

    " CORREÇÃO: O mswin.vim ativa o 'stopsel', que faz as setas (sem shift) 
    " saírem do modo visual. Isso remove essa limitação.
    set keymodel-=stopsel

    " ativa os atalhos padrões de editores do windows
    silent! source $VIMRUNTIME/mswin.vim

    " CORREÇÃO: O mswin.vim ativa o 'stopsel', que faz as setas (sem shift) 
    " saírem do modo visual. Isso remove essa limitação.
    set keymodel-=stopsel
endfunction

" funcao de desativacao dos atalhos
function! shortcut#Disable() abort
    
    " remove Setas adicionadas pelo plugin (Normal, Insert e Visual)
    silent! nunmap <Up>
    silent! nunmap <Down>
    silent! nunmap <Left>
    silent! nunmap <Right>

    silent! iunmap <Up>
    silent! iunmap <Down>
    silent! iunmap <Left>
    silent! iunmap <Right>

    silent! vunmap <Up>
    silent! vunmap <Down>
    silent! vunmap <Left>
    silent! vunmap <Right>
    
    " remove atalhos criados pelo mswin.vim
    " ctrl-x e shift-del 
    silent! vunmap <C-X>
    silent! vunmap <S-Del>

    " ctrl-c e ctrl-insert 
    silent! vunmap <C-C>
    silent! vunmap <C-Insert>

    " ctrl-v / shift-insert
    silent! nunmap <C-V>
    silent! vunmap <C-V>
    silent! iunmap <C-V>
    silent! cunmap <C-V>

    silent! nunmap <S-Insert>
    silent! vunmap <S-Insert>
    silent! iunmap <S-Insert>
    silent! cunmap <S-Insert>

    " tecla de espaco no modo Visual
    silent! vunmap <BS>

    " ctrl-Q = ctrl-V
    silent! nunmap <C-Q>

    " ctrl-s 
    silent! nunmap <C-S>
    silent! vunmap <C-S>
    silent! iunmap <C-S>

    " ctrl-z 
    silent! nunmap <C-Z>
    silent! iunmap <C-Z>

    " ctrl-y
    silent! nunmap <C-Y>
    silent! iunmap <C-Y>

    "  alt+espaco = menu do sistema
    silent! nunmap <M-Space>
    silent! iunmap <M-Space>
    silent! cunmap <M-Space>

    " ctrl-a 
    silent! nunmap <C-A>
    silent! iunmap <C-A>
    silent! cunmap <C-A>
    silent! ounmap <C-A>
    silent! sunmap <C-A>
    silent! xunmap <C-A>

    " ctrl-tab
    silent! nunmap <C-Tab>
    silent! iunmap <C-Tab>
    silent! cunmap <C-Tab>
    silent! ounmap <C-Tab>

    " ctrl-f4
    silent! nunmap <C-F4>
    silent! iunmap <C-F4>
    silent! cunmap <C-F4>
    silent! ounmap <C-F4>

    " ctrl-f 
    silent! nunmap <C-F>
    silent! iunmap <C-F>
    silent! cunmap <C-F>

    " ctrl-h
    silent! nunmap <C-H>
    silent! iunmap <C-H>
    silent! cunmap <C-H>

    " CORREÇÃO: Restaura opções exatas que o usuário tinha antes
    if exists('s:save_keymodel')
        let &keymodel = s:save_keymodel
    else
        set keymodel&
    endif

    if exists('s:save_selection')
        let &selection = s:save_selection
    else
        set selection&
    endif

    if exists('s:save_selectmode')
        let &selectmode = s:save_selectmode
    else
        set selectmode&
    endif

    if exists('s:save_backspace')
        let &backspace = s:save_backspace
    else
        set backspace&
    endif
endfunction


" Define o comando para ativar os atalhos
command! AssistShortcutsOn call shortcut#Enable()

" Define o comando para desativar os atalhos
command! AssistShortcutsOff call shortcut#Disable()