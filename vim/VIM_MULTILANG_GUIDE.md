# Vim IDE Setup - Hỗ trợ 12 Ngôn ngữ Lập trình

**Version**: 2.0 | **Total supported languages**: 12

---

## 📚 Ngôn ngữ được hỗ trợ

### Frontend & Web
1. **JavaScript** - ESLint, Prettier, TypeScript
2. **TypeScript** - TypeScript Language Server, ESLint
3. **HTML** - HTML Language Server, Prettier
4. **CSS** - StyleLint, Prettier
5. **YAML/JSON** - JSON/YAML Language Server, Prettier

### Backend & System
6. **Python** - Pyright, PyLint, Flake8, Black
7. **PHP** - PHP Language Server, PHP CS Fixer
8. **Shell/Bash** - Bash Language Server, ShellCheck, Shfmt
9. **Lua** - Lua Language Server, Stylua, Luacheck

### Systems Programming
10. **Rust** - Rust-Analyzer, Clippy, Rustfmt
11. **Go** - GoPLS, Golangci-lint, GoFmt
12. **C/C++** - Clang, Clang-Tidy, LLDB

### Enterprise
13. **Java** - JDK, Maven, Gradle, EclipseJDTLS
14. **Docker** - Dockerfile Language Server, Hadolint

---

## 🚀 Cách cài đặt

### Option 1: Cài tất cả (Recommended)

```bash
bash vim.sh
# Chọn: 1 (Full setup)
```

✓ Cài đặt:
- Vim + tất cả dependencies
- vim-plug + all plugins
- Coc.nvim + extensions
- **Tất cả 12 language servers**

⏱️ Thời gian: ~10-15 phút (tùy tốc độ internet)

### Option 2: Chọn ngôn ngữ cụ thể

```bash
bash vim.sh
# Chọn: 5 (Select & install languages)
```

Menu tương tác:
```
1.  Python
2.  JavaScript/TypeScript
3.  HTML/CSS
4.  Lua
5.  Rust
6.  Go
7.  C/C++
8.  Java
9.  PHP
10. Shell/Bash
11. YAML/JSON
12. Docker
13. Install ALL languages
14. Back to menu
```

**Ví dụ**: Chỉ cần Python + JavaScript + Go?
```
Nhập: 1,2,6
```

### Option 3: Cài language servers sau

```bash
bash vim.sh
# Chọn: 4 (Install plugins only)
# ... lúc khác ...
# Chọn: 5 (Select & install languages)
```

---

## 🛠️ Mô tả từng Language Server

### Python
```bash
# Cài đặt:
pip install --user pylint flake8 black python-lsp-server autopep8
npm install -g pyright

# Tính năng:
- Real-time linting (pylint, flake8)
- Auto-format (black, autopep8)
- Type checking (pyright)
- Go to definition, rename, refactor
```

### JavaScript/TypeScript
```bash
# Cài đặt:
npm install -g typescript typescript-language-server eslint prettier

# Tính năng:
- Full TypeScript support
- ESLint auto-fix
- Prettier formatting
- Auto-import, rename symbol
- Dead code detection
```

### HTML/CSS
```bash
# Cài đặt:
npm install -g vscode-langservers-extracted stylelint prettier

# Tính năng:
- HTML validation
- CSS selector checking
- Prettier formatting
- Auto-close tags
- Emmet abbreviation support
```

### Rust
```bash
# Cài đặt:
rustup component add rust-analyzer
cargo install clippy

# Tính năng:
- Rust-Analyzer LSP
- Clippy linting (safety checks)
- Rustfmt auto-format
- Macro expansion
- Inlay hints
```

### Go
```bash
# Cài đặt:
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install golang.org/x/tools/cmd/goimports@latest

# Tính năng:
- GoPLS language server
- Golangci-lint (multi-linter)
- Gofmt auto-format
- Imports organization
```

### C/C++
```bash
# Cài đặt:
sudo pacman -S clang lldb cmake

# Tính năng:
- Clang-format auto-format
- Clang-tidy linting
- LLDB debugging
- Code navigation
```

### Lua
```bash
# Cài đặt:
sudo pacman -S lua-language-server stylua luacheck

# Tính năng:
- Lua Language Server
- Stylua auto-format
- Luacheck linting
- Type hints
```

### Shell/Bash
```bash
# Cài đặt:
sudo pacman -S shellcheck shfmt bash-language-server

# Tính năng:
- ShellCheck linting
- Shfmt auto-format
- Bash Language Server
- Syntax validation
```

### Java
```bash
# Cài đặt:
sudo pacman -S jdk-openjdk maven gradle

# Tính năng:
- EclipseJDTLS language server
- Maven/Gradle build integration
- Checkstyle linting
- Java format
```

### PHP
```bash
# Cài đặt:
sudo pacman -S php php-pear
composer global require felixbecker/language-server

# Tính năng:
- PHP Language Server
- PHP-CS-Fixer
- PHPStan type checking
```

---

## ⌨️ Keybindings

| Phím | Hành động |
|------|----------|
| `Ctrl+N` | Toggle NERDTree (file explorer) |
| `Ctrl+P` | Fuzzy file search (FZF) |
| `Ctrl+F` | Ripgrep (text search) |
| `Ctrl+S` | Save file |
| `Ctrl+Q` | Quit |
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gi` | Go to implementation |
| `gr` | Find all references |
| `K` | Show documentation hover |
| `Leader+rn` | Rename symbol |
| `Leader+f` | Format document |
| `Leader+gs` | Git status |
| `Leader+gd` | Git diff |
| `Tab` / `Shift+Tab` | Navigate autocomplete |
| `Enter` | Select autocomplete item |

---

## 📋 Plugins cài đặt

### LSP & Completion
- `coc.nvim` - Language Server Protocol
- CoC extensions cho 12 ngôn ngữ

### Navigation
- `fzf.vim` - Fuzzy file finder
- `nerdtree` + `nerdtree-git-plugin`
- `vim-fugitive` + `vim-gitgutter`

### Editing
- `vim-surround` - Manage quotes/brackets
- `vim-commentary` - Quick comment
- `auto-pairs` - Auto close brackets
- `vim-polyglot` - Syntax highlighting (20+ languages)

### UI
- `onedark.vim` - Dark theme
- `lightline.vim` - Status bar
- `vim-devicons` - File icons
- `indentLine` - Indent guides

### Linting & Formatting
- `ale` - Async linting (tất cả 12 ngôn ngữ)

---

## ⚙️ Cấu hình Files

### 1. `~/.vimrc` - Main config
- Basic settings
- Plugins configuration
- Keybindings
- ALE linters/fixers
- CoC settings

### 2. `~/.vim/coc-settings.json` - Language server config
```json
{
  "coc.preferences.formatOnSave": true,
  "python.formatting.provider": "black",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "eslint.autoFixOnSave": true,
  // ... language-specific configs
}
```

---

## 🔧 Sử dụng

### Kiểm tra LSP status
```vim
:CocStatus
:checkhealth
```

### Xem installed CoC extensions
```vim
:CocList extensions
```

### Cài thêm CoC extension
```vim
:CocInstall coc-rust-analyzer
:CocInstall coc-go
```

### Format file hiện tại
```vim
:CocCommand editor.action.formatDocument
" Hoặc dùng: Leader+f
```

### Find & Replace
```vim
:CocCommand editor.action.refactor
```

### Refactor
```vim
:CocCommand workspace.showOutput
```

---

## 💾 Lưu & Quản lý Config

### Sao lưu config
```bash
tar -czf vim-backup.tar.gz ~/.vim ~/.vimrc
```

### Restore
```bash
tar -xzf vim-backup.tar.gz -C ~/
```

### Đồng bộ giữa máy
```bash
# Copy vimrc và coc-settings
scp ~/.vimrc ~/.vim/coc-settings.json user@remote:~/
```

---

## 🐛 Troubleshooting

### Plugins không cài?
```bash
vim +PlugInstall +qall
```

### CoC không hoạt động?
```vim
:CocStatus
:checkhealth coc
:CocCommand workspace.showOutput
```

### Language server không phản hồi?
```bash
# Reinstall specific language
bash vim.sh
# Chọn: 5 → chọn ngôn ngữ
```

### Memory/Performance quá cao?
```vim
" Tắt indentLine
let g:indentLine_enabled = 0

" Tắt auto-format
let g:ale_fix_on_save = 0
```

### Vim chậm khi typing?
```bash
# Disable linters không cần
# Sửa trong ~/.vimrc, comment linters
```

---

## 📝 Ví dụ Project Setup

### Python Project
```bash
# Full Python dev environment
bash vim.sh → 5 → 1  # Install Python server

# File structure
project/
├── main.py
├── requirements.txt
├── venv/
└── tests/
```

### Web Project (JS + HTML + CSS)
```bash
bash vim.sh → 5 → 2,3  # Install JS, HTML/CSS

# File structure
project/
├── index.html
├── styles.css
├── app.js
├── package.json
└── dist/
```

### Rust Project
```bash
bash vim.sh → 5 → 5  # Install Rust

# File structure
project/
├── src/
│   ├── main.rs
│   └── lib.rs
├── Cargo.toml
└── target/
```

---

## ✨ Tips & Tricks

### Tạo snippet cho language yêu thích
```vim
" Thêm vào ~/.vimrc
:CocCommand snippets.editSnippets
```

### Auto-import on save
```json
{
  "typescript.updateImportsOnFileMove.enabled": "always",
  "coc.preferences.formatOnSave": true
}
```

### Custom linter settings
```vim
" Ví dụ: Python pylint
let g:ale_python_pylint_options = '--disable=C0111'
```

### Keyboard mapping custom
```vim
" Thêm vào ~/.vimrc
nnoremap <Leader>d :CocCommand references<CR>
nnoremap <Leader>qf :CocCommand quickfix<CR>
```

---

## 📊 Performance Comparison

| Ngôn ngữ | Startup | Typing Latency | Memory |
|---------|---------|----------------|--------|
| Python | ✓✓✓ | ✓✓ | ✓✓ |
| JavaScript | ✓✓ | ✓ | ✓ |
| Rust | ✓✓ | ✓✓✓ | ✓ |
| Go | ✓✓✓ | ✓✓✓ | ✓✓ |

**Legend**: ✓ = Tốt, ✓✓ = Bình thường, ✓✓✓ = Chậm

---

## 🔗 Resources

- [Coc.nvim Docs](https://github.com/neoclide/coc.nvim)
- [ALE Documentation](https://github.com/dense-analysis/ale)
- [FZF.vim Guide](https://github.com/junegunn/fzf.vim)
- [Vim-Fugitive Docs](https://github.com/tpope/vim-fugitive)

---

**Happy coding!** 🎉

Các câu hỏi? Check lại `:CocStatus` hoặc `:checkhealth`
