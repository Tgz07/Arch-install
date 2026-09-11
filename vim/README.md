# Vim IDE - Multi-Language Setup

Vim IDE configuration với hỗ trợ **12 ngôn ngữ lập trình** + LSP + CoC + ALE.

## 🚀 Quick Start

### 1. Cài đặt tất cả (Recommended)
```bash
chmod +x vim.sh
./vim.sh
# Chọn: 1
```

Hoàn thành trong ~15 phút. Cài:
- ✅ Vim + dependencies
- ✅ vim-plug + 15 plugins
- ✅ Coc.nvim + 8 extensions
- ✅ ALE linter/fixer
- ✅ **Tất cả 12 language servers**

### 2. Chọn ngôn ngữ cụ thể
```bash
./vim.sh
# Chọn: 5
# Nhập: 1,2,3  (Python, JS/TS, HTML/CSS)
```

### 3. Kiểm tra hoạt động
```bash
vim test.py
:CocStatus        # Kiểm tra LSP
:checkhealth      # Check health
```

---

## 🌐 Ngôn ngữ được hỗ trợ

| # | Ngôn ngữ | Tools |
|---|----------|-------|
| 1 | Python | pyright, pylint, black |
| 2 | JavaScript | eslint, prettier, typescript |
| 3 | TypeScript | typescript-language-server |
| 4 | HTML | html-language-server, prettier |
| 5 | CSS | stylelint, prettier |
| 6 | Rust | rust-analyzer, clippy, rustfmt |
| 7 | Go | gopls, golangci-lint, gofmt |
| 8 | C/C++ | clang, clang-tidy, lldb |
| 9 | Lua | lua-language-server, stylua |
| 10 | Shell/Bash | shellcheck, shfmt, bash-language-server |
| 11 | YAML/JSON | yaml-language-server, jsonlint |
| 12 | Docker | dockerfile-language-server |
| + | Java | jdk, maven, gradle, eclipsejdtls |
| + | PHP | php-language-server, php-cs-fixer |

---

## ⌨️ Essential Keybindings

```vim
Ctrl+P          Fuzzy file search
Ctrl+F          Ripgrep text search
Ctrl+N          File explorer (NERDTree)
Ctrl+S          Save
Ctrl+Q          Quit

gd              Go to definition
gy              Go to type definition
gr              Find references
K               Show documentation
Leader+rn       Rename symbol
Leader+f        Format code

Leader+gs       Git status
Leader+gd       Git diff

Tab             Next autocomplete
Shift+Tab       Prev autocomplete
Enter           Select autocomplete
```

---

## 🛠️ Menu Options

```
1. Full setup (ALL)
   → Cài Vim + plugins + tất cả 12 language servers

2. Update system
   → pacman -Syu

3. Reinstall Vim
   → Gỡ cài lại Vim + config

4. Install plugins only
   → Chỉ Vim plugins (không language servers)

5. Select & install languages
   → Menu chọn ngôn ngữ (1,2,3,... hoặc 13 cho all)

6. Install all language servers
   → Cài lại tất cả language servers

7. Exit
```

---

## 📚 Documentation

### Chi tiết đầy đủ
👉 **VIM_MULTILANG_GUIDE.md** - Hướng dẫn chi tiết 12 ngôn ngữ

### Lệnh & Keybindings
👉 **VIM_QUICK_REFERENCE.md** - Quick reference card

### Script
👉 **vim.sh** - Main installation script

---

## 🎨 Plugins cài đặt

### Core IDE Features
- **coc.nvim** - Language Server Protocol
- **ale** - Linting & auto-fixing
- **fzf.vim** - Fuzzy file finder
- **vim-fugitive** + **vim-gitgutter** - Git integration
- **nerdtree** - File explorer

### UI/Themes
- **onedark.vim** - Dark theme
- **lightline.vim** - Status bar
- **vim-devicons** - File icons
- **indentLine** - Indent guides

### Editing
- **vim-surround** - Quote/bracket management
- **vim-commentary** - Quick comments
- **auto-pairs** - Auto close brackets
- **vim-polyglot** - Syntax highlighting (20+ languages)

---

## ⚙️ Config Files

### `~/.vimrc` - Main configuration
```vim
set number
set relativenumber
set tabstop=4
set expandtab
set clipboard=unnamedplus

" Plugins auto-installed via vim-plug
" Language servers auto-configured via CoC
" Linting/fixing via ALE
```

### `~/.vim/coc-settings.json` - Language server config
```json
{
  "coc.preferences.formatOnSave": true,
  "python.formatting.provider": "black",
  "eslint.autoFixOnSave": true,
  ...
}
```

---

## 🐛 Troubleshooting

### LSP không hoạt động
```bash
vim +CocStatus +q    # Kiểm tra status

# Hoặc trong Vim:
:CocStatus
:checkhealth coc
:CocCommand workspace.showOutput
```

### Plugins không cài?
```bash
vim +PlugInstall +qall
```

### Language server cho ngôn ngữ X?
```bash
# Cài lại
./vim.sh → 5 → chọn ngôn ngữ
```

### Vim chậm?
```vim
" Tắt linting trên save
let g:ale_fix_on_save = 0

" Tắt indent visual
let g:indentLine_enabled = 0
```

---

## 💾 Backup & Restore

### Backup config
```bash
tar -czf vim-backup.tar.gz ~/.vim ~/.vimrc
```

### Restore
```bash
tar -xzf vim-backup.tar.gz -C ~/
```

---

## 📊 What's Included

| Thành phần | Số lượng | Status |
|-----------|---------|--------|
| Plugins | 15+ | ✅ Auto-installed |
| CoC Extensions | 8+ | ✅ Auto-installed |
| Language Servers | 12 | ✅ Selectable |
| Keybindings | 20+ | ✅ Ready to use |
| Themes | 1 | ✅ Onedark |

---

## 🔗 Useful Commands

### Inside Vim
```vim
:CocList extensions       " List CoC extensions
:CocCommand <cmd>         " Run CoC command
:ALEToggle               " Toggle ALE
:FZF                     " Fuzzy find
:Rg <pattern>            " Ripgrep
:G                       " Git status
```

### Outside Vim
```bash
./vim.sh                 " Run setup
vim file.py              " Open file
# :CocStatus inside      " Check LSP
```

---

## 🎯 Tips

1. **Custom keybindings**: Edit `~/.vimrc`
2. **Language config**: Edit `~/.vim/coc-settings.json`
3. **Add plugins**: Thêm `Plug '...'` và `:PlugInstall`
4. **Disable linters**: Comment trong `.vimrc`
5. **Format code**: `Leader+f` hoặc `:CocCommand editor.action.formatDocument`

---

## ✨ Example Workflows

### Python Development
```bash
./vim.sh → 5 → 1  # Python only
vim main.py
:CocStatus         # Verify pyright
# Viết code → auto-format on save
```

### Web Development
```bash
./vim.sh → 5 → 2,3  # JS/TS + HTML/CSS
vim index.html
# ESLint + Prettier + HTML validation
```

### System Programming
```bash
./vim.sh → 5 → 5,6,7  # Rust + Go + C/C++
vim main.rs
# rust-analyzer + clippy + rustfmt
```

---

## 📖 Learn More

- **Full Guide**: VIM_MULTILANG_GUIDE.md (chi tiết từng ngôn ngữ)
- **Quick Ref**: VIM_QUICK_REFERENCE.md (lệnh & keybindings)
- **Coc Docs**: https://github.com/neoclide/coc.nvim
- **ALE Docs**: https://github.com/dense-analysis/ale

---

## 🚀 First Run

```bash
# 1. Make executable
chmod +x vim.sh

# 2. Run setup
./vim.sh

# 3. Choose option 1 (Full setup) or 5 (Select languages)

# 4. Wait for installation (5-15 min)

# 5. Open Vim
vim

# 6. Verify
:CocStatus          # Check LSP
:PlugStatus         # Check plugins
:ALEToggle          # Toggle ALE if needed
```

---

**Version**: 2.0  
**Languages**: 12 supported  
**Last Updated**: 2026-09-11  

Happy coding! 🎉
