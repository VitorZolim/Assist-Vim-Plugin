[🇺🇸 Read this documentation in English (README.md)](./README.md)
# ♿ Vim Accessibility Plugin (assist-plugin)

> **Projeto Integrador II (PI-II) — Open4Community**  
> **FATEC Ribeirão Preto** — Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas  
> **Tema:** Acessibilidade e Redução de Carga Cognitiva no Editor Vim

---

## 📌 Sobre o Projeto

O **Vim Accessibility Plugin** é uma extensão desenvolvida em **Vim Script** focada em aprimorar a usabilidade, acessibilidade e inclusão dentro do editor de texto Vim. 

Historicamente, o Vim é conhecido por sua curva de aprendizado íngreme e por interfaces modais que exigem alta retenção de atalhos e sintaxes complexas (como expressões regulares). Este projeto tem como propósito reduzir as barreiras de entrada para usuários iniciantes, pessoas neurodivergentes e profissionais com necessidades de apoio à memória operacional ou orientação contextual, alinhando-se aos princípios universais de acessibilidade digital.

---

## ✨ Principais Funcionalidades

### 1. 🔍 Busca Literal Assistida com Janela Flutuante (`assist-plugin.vim`)
Substitui a busca padrão por uma experiência intuitiva em popup lateral sem interferir na integridade do arquivo original:
* **Busca Literal Direta:** Remapeia o atalho `/` para efetuar buscas literais automáticas, sem exigir conhecimento prévio ou escape manual de caracteres especiais e Regex.
* **Painel Lateral em Popup:** Exibe as correspondências agrupadas por linha em uma janela flutuante no canto superior direito (`topright`) com moldura visual e barra de rolagem.
* **Filtro Interno:** Permite pressionar `/` dentro da própria janela flutuante para refinar os resultados exibidos.
* **Salto Rápido e Centralização:** Atalho `<Ctrl+g>` pula instantaneamente para a linha destacada no popup e centraliza o cursor na tela (`zz`).
* **Fallback Automático:** Caso o ambiente do terminal ou versão do Vim não possua suporte a popups (`popupwin`), os resultados são exibidos com segurança via mensagens do próprio editor.

---

### 2. 🧭 Barra de Status e Guia Visual Adaptativo (`assist-plugin_StatusLine.vim`)
Inspirado na facilidade ergonômica de editores de terminal como o GNU Nano:
* **Identificação Explícita do Modo de Operação:** Exibe na `statusline` o modo ativo de forma clara e legível (`[NORMAL]`, `[INSERT]`, `[VISUAL]`, `[REPLACE]`, `[COMMAND]`), evitando desorientações contextuais.
* **Guia Visual de Teclas Essenciais:** Apresenta uma régua inferior com os comandos mais utilizados para manipulação de arquivos, navegação e ajuda.
* **Layout Responsivo:** A quantidade de colunas do popup adapta-se automaticamente à largura da janela (`&columns`):
  * **≥ 90 colunas:** Matriz de 6 colunas (Layout 2x6);
  * **≥ 70 colunas:** Matriz de 4 colunas;
  * **≥ 55 colunas:** Matriz de 3 colunas;
  * **< 55 colunas:** Matriz vertical de 2 colunas para terminais estreitos.
* **Preservação de Estado:** Ao ativar/desativar a interface, as configurações originais do usuário (`&cmdheight`, `&statusline`, `&laststatus`) são restauradas integralmente.

---

## ⌨️ Tabela de Comandos e Atalhos

### Comandos de Terminal (`:` Command Mode)
| Comando | Descrição |
| :--- | :--- |
| `:AccessibilityOn` | Ativa a interface de acessibilidade (StatusLine didática + Guia Nano de atalhos). |
| `:AccessibilityOff` | Desativa a interface e restaura as configurações visuais anteriores do usuário. |
| `:call ClosePopupSearch()` | Fecha manualmente o popup de busca lateral aberto. |

---

### Navegação e Busca
| Atalho | Modo | Ação |
| :--- | :---: | :--- |
| `/` | Normal | Abre o prompt para busca literal de termos no buffer atual. |
| `/` | Popup | Inicia a filtragem interna nos resultados da busca. |
| `<Ctrl+j>` / `<Ctrl+Down>` | Popup | Rola os resultados para baixo. |
| `<Ctrl+k>` / `<Ctrl+Up>` | Popup | Rola os resultados para cima. |
| `<Ctrl+g>` | Popup | Pula diretamente para a linha selecionada no arquivo e centraliza a tela. |
| `<Esc>` ou `q` | Popup | Fecha o popup de busca e limpa o destaque de grifo. |

---

## 📁 Estrutura de Diretórios

```plaintext
├── autoload/
│   ├── assist-plugin.vim              # Lógica de busca literal, popups laterais e navegação
│   └── assist-plugin_StatusLine.vim   # StatusLine didática, guia de teclas adaptativo e comandos UI
└── README.md                          # Documentação do repositório
