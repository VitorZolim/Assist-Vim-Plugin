"referencia do arquivo: [ $VIMRUNTIME/mswin.vim ] 

"funcao de ativacao dos atalhos

function! shortcut#Enable() abort
    "forca setas funcionarem
    set nocompatible

    " corrige o mapeamento das setas  
    if &term =~ 'xterm' || &term =~ 'vt100' || &term =~ 'screen' || &term =~ 'linux'
        set t_ku= OA
        set t_kd= OB
        set t_kr= OC
        set t_kl= OD
    endif

    "setas funcionando para todos os modos
    nnoremap <Up> k
    nnoremap <Down> j
    nnoremap <Left> h
    nnoremap <Right> l
    
    inoremap <Up> <C-o>k
    inoremap <Down> <C-o>j
    inoremap <Left> <C-o>h
    inoremap <Right> <C-o>l

    " ativa os atalhos padrões de editores 
    silent! source $VIMRUNTIME/mswin.vim

endfunction

" funcao de desativacao dos atalhos

function! shortcut#Disable() abort
    
    " remove Setas adicionadas pelo plugin
    
    silent! nunmap <Up>
    silent! nunmap <Down>
    silent! nunmap <Left>
    silent! nunmap <Right>

    silent! iunmap <Up>
    silent! iunmap <Down>
    silent! iunmap <Left>
    silent! iunmap <Right>


    
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

    "  alt+spaço = menu do sistema
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

endfunction

"ajustes a fazer: .revisar algumas configuracoes do mswin.vim nao referentes a atalho
"                  .testar no sistema inteiro chamada e encerramento
                   