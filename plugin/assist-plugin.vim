" Vim global plugin: busca literal em popup, StatusLine acessível e atalhos
" Last Change:  2026 Nov 04
" Maintainer:   victorfg-dev
" License:      veja o arquivo LICENSE na raiz do plugin
"
" Use :AssistOn para ativar o plugin inteiro e :AssistOff para desativar.
" Este arquivo só define comandos e mapeamentos. A lógica fica em autoload/assist/
" e só é carregada quando um comando é usado pela primeira vez (|autoload|).

" Impede que o plugin seja carregado mais de uma vez ou quando o usuário o
" desativa definindo g:loaded_assist_plugin = 1 no vimrc.
if exists('g:loaded_assist_plugin')
    finish
endif
let g:loaded_assist_plugin = 1

let s:save_cpo = &cpo
set cpo&vim

" ---------------------------------------------------------------------------
" Comandos
" ---------------------------------------------------------------------------
if !exists(':AssistOn')
    command -bar AssistOn call assist#Enable()
endif
if !exists(':AssistOff')
    command -bar AssistOff call assist#Disable()
endif
if !exists(':AssistSearch')
    command -bar AssistSearch call assist#search#Start()
endif
if !exists(':AssistSearchClose')
    command -bar AssistSearchClose call assist#search#Close()
endif
if !exists(':AssistShortcutsOn')
    command -bar AssistShortcutsOn call assist#shortcut#Enable()
endif
if !exists(':AssistShortcutsOff')
    command -bar AssistShortcutsOff call assist#shortcut#Disable()
endif
if !exists(':AssistStatusLineOn')
    command -bar AssistStatusLineOn call assist#statusline#Enable()
endif
if !exists(':AssistStatusLineOff')
    command -bar AssistStatusLineOff call assist#statusline#Disable()
endif

" ---------------------------------------------------------------------------
" Mapeamentos
" <Plug>AssistSearch fica disponível para o usuário mapear a tecla que quiser:
"     nmap <Leader>f <Plug>AssistSearch
" ---------------------------------------------------------------------------
nnoremap <silent> <script> <Plug>AssistSearch :AssistSearch<CR>

" O mapeamento padrão de "/" só é criado por :AssistOn (e removido por
" :AssistOff). Sem :AssistOn, o plugin não altera nenhum comportamento do Vim.
" Use g:assist_plugin_no_mappings para impedir que :AssistOn mapeie "/".

let &cpo = s:save_cpo
unlet s:save_cpo
