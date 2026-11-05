[🇧🇷 Leia esta documentação em Português (LEIAME.md)](./LEIAME.md)
# ♿ Vim Accessibility Plugin (assist-plugin)

> **Integrative Project II (PI-II) — Open4Community**  
> **FATEC Ribeirão Preto** — Higher Technology Degree in Systems Analysis and Development  
> **Topic:** Accessibility and Cognitive Load Reduction in the Vim Editor

---

## 📌 About the Project

The **Vim Accessibility Plugin** is an extension written in **Vim Script** designed to improve usability, accessibility, and inclusivity within the Vim text editor.

Historically, Vim is known for its steep learning curve and modal interfaces that demand high shortcut retention and complex syntax handling (such as regular expressions). This project aims to lower entry barriers for beginners, neurodivergent users, and individuals who require cognitive or working-memory support, aligning with universal digital accessibility principles.

---

## ✨ Key Features

### 1. 🔍 Assisted Literal Search with Floating Popup (`autoload/assist/search.vim`)
Replaces default search behavior with an intuitive lateral popup experience without compromising the original file buffer:
- **Direct Literal Search:** Remaps `/` to perform automatic literal searches without requiring prior knowledge or manual escaping of special characters and Regular Expressions (Regex).
- **Lateral Popup Panel:** Displays matches grouped by line in a floating window anchored to the top-right corner (`topright`), complete with custom borders and a scrollbar.
- **In-Popup Filtering:** Press `/` directly inside the popup window to interactively filter and refine query results.
- **Quick Jump & Viewport Centering:** Press `<Ctrl+g>` to instantly jump to the selected line in the file and center the viewport (`zz`).
- **Graceful Fallback:** If the terminal environment or Vim build lacks popup window support (`popupwin`), matches safely degrade to standard editor status messages.

---

### 2. 🧭 StatusLine & Adaptive Visual Key Guide (`autoload/assist/statusline.vim`)
Inspired by the ergonomic usability of terminal-based editors such as GNU Nano:
- **Explicit Mode Identification:** Displays the active mode clearly on the `statusline` (`[NORMAL]`, `[INSERT]`, `[VISUAL]`, `[REPLACE]`, `[COMMAND]`), preventing contextual disorientation.
- **Essential Keys Helper:** Provides a bottom-pinned visual helper listing essential navigation, file manipulation, and help commands.
- **Responsive Layout:** Automatically adapts column count based on terminal width (`&columns`):
  * **≥ 90 columns:** 6-column matrix (2x6 layout);
  * **≥ 70 columns:** 4-column matrix;
  * **≥ 55 columns:** 3-column matrix;
  * **< 55 columns:** 2-column vertical matrix for narrow terminal windows.
- **State Preservation:** When toggling the UI on or off, previous user configurations (`&cmdheight`, `&statusline`, `&laststatus`) are fully restored.

---

## 📦 Installation

You can install **assist-plugin** using your favorite plugin manager or natively using Vim's built-in package system.

### Option 1: Via Plugin Manager (`vim-plug`)

1. Add the following line to your `_vimrc` (Windows) or `.vimrc` (Linux/macOS) between `plug#begin()` and `plug#end()`:

```vim
call plug#begin()

Plug 'VitorZolim/Assist-Vim-Plugin'

call plug#end()
```

2. Open Vim and execute:
```vim
:PlugInstall
```

---

### Option 2: Native Manual Installation (Vim 8+)

Vim 8.0+ supports native plugin loading from the `pack/` directory without requiring external managers.

**Windows (Command Prompt / PowerShell):**
```powershell
git clone https://github.com/VitorZolim/Assist-Vim-Plugin.git %USERPROFILE%\vimfiles\pack\plugins\start\assist-vim-plugin
```

**Linux / macOS / WSL:**
```bash
git clone https://github.com/VitorZolim/Assist-Vim-Plugin.git ~/.vim/pack/plugins/start/assist-vim-plugin
```

---

## ⌨️ Commands and Keybindings

### Terminal Commands (`:` Command Mode)
| Command | Description |
| :--- | :--- |
| `:AssistOn` / `:AssistOff` | **Enables / disables the whole plugin** (search on `/`, StatusLine, shortcuts); `:AssistOff` restores previous settings. |
| `:AssistSearch` | Opens the literal search prompt and results popup (also bound to `/`). |
| `:AssistSearchClose` | Closes the lateral search results popup. |
| `:AssistStatusLineOn` / `:AssistStatusLineOff` | Enables / disables the educational StatusLine + Nano-style key guide, restoring previous settings. |
| `:AssistShortcutsOn` / `:AssistShortcutsOff` | Enables / disables common editor shortcuts (arrows, Ctrl+C/V/X/S/Z...). |

`<Plug>AssistSearch` can be mapped to any key (`nmap <Leader>f <Plug>AssistSearch`). To keep Vim's default `/`, add `let g:assist_plugin_no_mappings = 1` to your vimrc. See `:help assist-plugin`.

---

### Navigation & Search Shortcuts
| Keybinding | Mode | Action |
| :--- | :---: | :--- |
| `/` | Normal | Opens the prompt for buffer-wide literal search. |
| `/` | Popup | Starts internal filtering within existing search results. |
| `<Ctrl+j>` / `<Ctrl+Down>` | Popup | Scrolls popup results downward. |
| `<Ctrl+k>` / `<Ctrl+Up>` | Popup | Scrolls popup results upward. |
| `<Ctrl+g>` | Popup | Jumps directly to the selected line in the file and centers the view. |
| `<Esc>` or `q` | Popup | Closes the search popup and clears highlights. |

---

## 📁 Directory Structure

```plaintext
├── plugin/
│   └── assist-plugin.vim              # Commands and <Plug> mapping
├── autoload/
│   ├── assist.vim                     # :AssistOn / :AssistOff (single activation)
│   └── assist/
│       ├── search.vim                 # Literal search logic, lateral popups, and navigation
│       ├── statusline.vim             # Accessible StatusLine and adaptive key guide
│       └── shortcut.vim               # Common editor shortcuts (based on mswin.vim)
├── doc/
│   ├── assist-plugin.txt              # Vim help (English)
│   └── assist-plugin.ptx              # Vim help (Português)
└── README.md                          # Project documentation
```