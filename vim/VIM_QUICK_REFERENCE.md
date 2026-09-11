# Vim IDE - Quick Reference Card

## 🎯 Menu (bash vim.sh)

```
1. Full setup (ALL)              → Cài tất cả + 12 language servers
2. Update system                 → pacman -Syu
3. Reinstall Vim                 → Gỡ + cài lại Vim
4. Install plugins only          → Chỉ plugins (không servers)
5. Select & install languages    → Menu chọn ngôn ngữ
6. Install all language servers  → Cài lại tất cả servers
7. Exit
```

---

## ⌨️ Essential Keybindings

### Navigation
| Phím | Hành động |
|------|----------|
| `Ctrl+P` | Fuzzy file search |
| `Ctrl+F` | Ripgrep text search |
| `Ctrl+N` | Toggle file explorer |
| `gd` | Go to definition |
| `K` | Show documentation |

### Editing
| Phím | Hành động |
|------|----------|
| `Ctrl+S` | Save |
| `Ctrl+Q` | Quit |
| `Leader+f` | Format code |
| `Leader+rn` | Rename symbol |
| `Tab` | Autocomplete next |
| `Shift+Tab` | Autocomplete prev |

### Git
| Phím | Hành động |
|------|----------|
| `Leader+gs` | Git status |
| `Leader+gd` | Git diff |

---

## 🌐 Language Selection Menu

```
1.  Python              → pylint, flake8, black, pyright
2.  JavaScript/TypeScript → eslint, prettier, typescript
3.  HTML/CSS            → prettier, stylelint
4.  Lua                 → lua-language-server, stylua
5.  Rust                → rust-analyzer, clippy, rustfmt
6.  Go                  → gopls, golangci-lint, gofmt
7.  C/C++               → clang, clang-tidy, lldb
8.  Java                → jdk, maven, gradle
9.  PHP                 → php-language-server, php-cs-fixer
10. Shell/Bash          → shellcheck, shfmt, bash-language-server
11. YAML/JSON           → yaml-language-server, jsonlint
12. Docker              → dockerfile-language-server, hadolint
13. Install ALL         → Tất cả 12 + 14 ngôn ngữ
```

**Ví dụ nhập**: `1,2,5` → Python + JS/TS + Rust

---

## 🔍 Vim Commands

### CoC Commands
```vim
:CocStatus              → Kiểm tra LSP status
:CocList extensions     → Danh sách plugins CoC
:CocInstall coc-go      → Cài CoC extension
:CocCommand <cmd>       → Chạy CoC command
```

### ALE Commands
```vim
:ALEToggle              → Bật/tắt ALE
:ALEFix                 → Fix hiện tại
:ALEDetail              → Xem lỗi chi tiết
```

### FZF Commands
```vim
:FZF                    → File search (Ctrl+P)
:Rg <pattern>           → Text search (Ctrl+F)
:Buffers                → List open buffers
:BLines                 → Search in current file
```

### Git Commands
```vim
:G                      → Git status (Leader+gs)
:Gdiff                  → Git diff (Leader+gd)
:Gblame                 → Show git blame
:Glog                   → Git log
```

### NERDTree
```vim
:NERDTree               → Toggle file explorer (Ctrl+N)
:NERDTreeFind           → Find current file
:NERDTreeCWD            → Change to cwd
```

---

## 📦 Installed Plugins

### Core
- `coc.nvim` - LSP engine
- `ale` - Linting & fixing
- `fzf.vim` - Fuzzy search
- `vim-polyglot` - Syntax (20+ languages)

### UI/UX
- `onedark.vim` - Theme
- `lightline.vim` - Status bar
- `vim-devicons` - Icons
- `indentLine` - Indent visual

### Editing
- `vim-surround` - Quotes/brackets
- `auto-pairs` - Auto close
- `vim-commentary` - Comments

### Version Control
- `vim-fugitive` - Git
- `vim-gitgutter` - Git diff sidebar

### Language-specific
- `rust.vim`, `vim-go`, `typescript-vim`, `python-syntax`

---

## 🛠️ Troubleshooting

### LSP không hoạt động?
```bash
# Kiểm tra
:CocStatus
:checkhealth coc

# Reinstall
bash vim.sh → 5 → chọn ngôn ngữ
```

### Plugins không cài?
```bash
vim +PlugInstall +qall
```

### Vim chậm?
```vim
" Tắt indentLine
let g:indentLine_enabled = 0

" Tắt auto-format
let g:ale_fix_on_save = 0
```

### Language server báo lỗi?
```vim
:CocCommand workspace.showOutput
" Kiểm tra tab "CocExplorer"
```

---

## 📁 Config Files

| File | Vị trí | Mục đích |
|------|--------|---------|
| .vimrc | `~/.vimrc` | Main config |
| coc-settings.json | `~/.vim/coc-settings.json` | LSP config |
| plugged/ | `~/.vim/plugged/` | Plugins directory |
| autoload/ | `~/.vim/autoload/` | Vim-plug |

---

## 💡 Quick Tips

```vim
" Auto-format on save
:CocCommand editor.action.formatDocument

" Rename all occurrences
:CocCommand editor.action.rename

" Show references
:CocList references

" Go to definition
gd

" Hover info
K

" Quick fix
:CocCommand quickfix

" Code actions
:CocCommand codeAction.doCodeAction
```

---

## 🔗 Language Docs

- Python: `pyright` check, pylint rules
- JavaScript: ESLint config, Prettier settings
- Rust: rust-analyzer commands, Clippy lints
- Go: gopls diagnostics, golangci-lint
- C/C++: clang-format, clang-tidy rules

---

## 🚀 First Steps

1. **Cài đặt**:
   ```bash
   bash vim.sh
   1  # Full setup hoặc
   5  # Chọn ngôn ngữ
   ```

2. **Verify**:
   ```bash
   vim file.py
   :CocStatus  # Xem LSP hoạt động
   ```

3. **Config**:
   - Sửa `~/.vimrc` cho keybindings custom
   - Sửa `~/.vim/coc-settings.json` cho LSP config

4. **Enjoy**: 
   ```bash
   vim myproject/
   Ctrl+P → files
   gd → definition
   K → docs
   Leader+f → format
   ```

---

**Version**: 2.0 | **Supported**: 12 Languages | **Last Updated**: 2026-09-11
