#!/bin/bash

VIM_DIR="$HOME/.vim"
VIMRC="$HOME/.vimrc"

update_system() {
    echo ">>> Updating system..."
    sudo pacman -Syu --noconfirm
}

remove_vim() {
    echo ">>> Removing Vim and configs..."
    sudo pacman -Rns vim --noconfirm 2>/dev/null
    rm -rf "$VIM_DIR" "$VIMRC"
}

install_vim() {
    echo ">>> Installing Vim + dependencies..."
    sudo pacman -S vim git curl nodejs npm python python-pip ripgrep fd lua --noconfirm
    echo ">>> Installing Python language servers..."
    pip install --user python-lsp-server python-lsp-black pylint --quiet
}

install_plug() {
    echo ">>> Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

install_plugins() {
    echo ">>> Installing plugins..."
    vim +PlugInstall +qall
}

install_coc_extensions() {
    echo ">>> Installing CoC extensions..."
    sleep 2
    vim -c "CocInstall -sync coc-json coc-html coc-css coc-python coc-tsserver coc-eslint coc-yaml coc-prettier coc-rust-analyzer coc-go coc-java coc-lua coc-lists coc-git | q" 2>/dev/null || true
    echo "✓ CoC extensions setup"
}

setup_coc_config() {
    echo ">>> Setting up CoC configuration..."
    mkdir -p ~/.config/nvim
    
    cat > ~/.vim/coc-settings.json << 'EOFCOC'
{
  "coc.preferences.formatOnSave": true,
  "coc.preferences.jumpCommand": "edit",
  "suggest.noselect": false,
  "suggest.enablePreview": true,
  "suggest.timeout": 5000,
  "suggest.minTriggerInputLength": 1,
  
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.linting.flake8Enabled": true,
  "python.formatting.provider": "black",
  "pyright.pythonPath": "/usr/bin/python",
  
  "javascript.autoClosingTags": true,
  "javascript.format.insertSpaceBeforeFunctionParenthesis": true,
  
  "typescript.autoClosingTags": true,
  "typescript.updateImportsOnFileMove.enabled": "always",
  
  "eslint.autoFixOnSave": true,
  "eslint.packageManager": "npm",
  
  "html.filetypes": ["html", "handlebars", "htmldjango", "blade"],
  "html.autoClosingTag": true,
  "html.format.enable": true,
  
  "css.autoFixOnSave": true,
  "css.validate": true,
  
  "json.format.enable": true,
  "json.schemas": [],
  
  "yaml.format.enable": true,
  "yaml.schemas": {
    "kubernetes": "*.k8s.yaml"
  },
  
  "lua.enable": true,
  "lua.runtime.version": "Lua 5.1",
  
  "rust-analyzer.checkOnSave.command": "clippy",
  "rust-analyzer.checkOnSave.allTargets": true,
  
  "go.useLanguageServer": true,
  "go.lintOnSave": "package",
  "go.lintTool": "golangci-lint",
  
  "java.enabled": true,
  "java.checkstyle.enable": true,
  
  "php.validate.executablePath": "/usr/bin/php",
  "php.validate.run": "onSave",
  
  "cpp.clangFormat.style": "LLVM",
  
  "prettier.eslintIntegration": true,
  "prettier.trailingComma": "es5",
  "prettier.tabWidth": 4,
  "prettier.semi": true,
  "prettier.singleQuote": true
}
EOFCOC
}

setup_vimrc() {
    echo ">>> Writing .vimrc..."

    cat > "$VIMRC" << 'EOF'
" =========================
" BASIC
" =========================
set nocompatible
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smartindent
set autoindent
set cindent
syntax on
set mouse=a
set clipboard=unnamedplus
set encoding=UTF-8

" Behavior
set hidden
set backspace=indent,eol,start
set ignorecase
set smartcase
set incsearch
set hlsearch
set ruler
set showcmd
set showmatch
set matchtime=2
set t_Co=256
set background=dark

" Performance
set lazyredraw
set synmaxcol=300

" File settings
set noswapfile
set nobackup
set undofile
set undodir=~/.vim/undo
autocmd BufWritePre /tmp/* setlocal noundofile

" =========================
" PLUGINS
" =========================
call plug#begin('~/.vim/plugged')

" UI & Theme
Plug 'joshdick/onedark.vim'
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-airline-themes'

" File explorer
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

" Icons
Plug 'ryanoasis/vim-devicons'

" LSP & Completion (CoC ecosystem)
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neoclide/coc-lists'
Plug 'neoclide/coc-prettier'

" Language-specific CoC extensions
Plug 'neoclide/coc-json'
Plug 'neoclide/coc-html'
Plug 'neoclide/coc-css'
Plug 'neoclide/coc-python'
Plug 'neoclide/coc-eslint'
Plug 'neoclide/coc-tsserver'
Plug 'neoclide/coc-yaml'

" Additional CoC extensions
Plug 'coc-extensions/coc-rust-analyzer'
Plug 'josa42/coc-go'
Plug 'coc-extensions/coc-java'
Plug 'bmewj/vim-coc-lua'

" Syntax & Language support
Plug 'sheerun/vim-polyglot'
Plug 'dense-analysis/ale'

" Git integration
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Surrounding & Motion
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Indent guides
Plug 'Yggdroot/indentLine'

" Auto pairs
Plug 'jiangmiao/auto-pairs'

" Formatting
Plug 'Chiel92/base16-vim'

" Multi-language specific
Plug 'vim-python/python-syntax'
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'rust-lang/rust.vim'
Plug 'fatih/vim-go'
Plug 'tpope/vim-rails'
Plug 'stephpy/vim-php-cs-fixer'

call plug#end()

" =========================
" THEME
" =========================
colorscheme onedark

" =========================
" KEYMAP
" =========================
" File navigation
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-p> :FZF<CR>
nnoremap <C-f> :Rg<CR>

" Editing
nnoremap <C-s> :w<CR>
nnoremap <C-q> :q<CR>
nnoremap <Leader>f :CocCommand editor.action.formatDocument<CR>

" Git
nnoremap <Leader>gs :G<CR>
nnoremap <Leader>gd :Gdiff<CR>

" CoC navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <Leader>rn <Plug>(coc-rename)

" =========================
" LIGHTLINE
" =========================
set laststatus=2
let g:lightline = { 'colorscheme': 'onedark' }

" =========================
" COC CONFIG
" =========================
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <silent><expr> <CR> pumvisible() ? coc#_select_confirm() : "\<CR>"

" Show documentation
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" =========================
" ALE CONFIG
" =========================
let g:ale_fixers = {
  \ 'python': ['black', 'autopep8', 'pylint'],
  \ 'javascript': ['prettier', 'eslint'],
  \ 'typescript': ['prettier', 'eslint', '@typescript-eslint/eslint-plugin'],
  \ 'json': ['prettier', 'jq'],
  \ 'html': ['prettier'],
  \ 'css': ['prettier', 'stylelint'],
  \ 'lua': ['stylua'],
  \ 'sh': ['shfmt'],
  \ 'rust': ['rustfmt'],
  \ 'go': ['gofmt', 'goimports'],
  \ 'cpp': ['clang-format'],
  \ 'c': ['clang-format'],
  \ 'java': ['google_java_format'],
  \ 'php': ['php-cs-fixer'],
  \ 'yaml': ['prettier'],
  \ 'dockerfile': ['hadolint'],
  \ }

let g:ale_linters = {
  \ 'python': ['pylint', 'flake8', 'pyright'],
  \ 'javascript': ['eslint'],
  \ 'typescript': ['eslint', 'tsserver'],
  \ 'json': ['jsonlint'],
  \ 'html': ['htmlhint'],
  \ 'css': ['stylelint'],
  \ 'lua': ['luacheck'],
  \ 'sh': ['shellcheck', 'bash-language-server'],
  \ 'rust': ['rust-analyzer', 'clippy'],
  \ 'go': ['golangci-lint', 'gopls'],
  \ 'cpp': ['clang-tidy', 'cppcheck'],
  \ 'c': ['clang-tidy', 'cppcheck'],
  \ 'java': ['checkstyle', 'javac'],
  \ 'php': ['phpcs', 'phpstan'],
  \ 'yaml': ['yamllint', 'spectral'],
  \ 'dockerfile': ['hadolint'],
  \ }

let g:ale_fix_on_save = 1
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '⚠'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'

EOF
}

install_python_servers() {
    echo ">>> Installing Python servers..."
    pip install --user pylint flake8 black python-lsp-server autopep8 --quiet
    npm install -g pyright --quiet 2>/dev/null
    echo "✓ Python (pylint, flake8, black, pyright)"
}

install_js_servers() {
    echo ">>> Installing JavaScript/TypeScript servers..."
    sudo npm install -g \
        typescript \
        typescript-language-server \
        eslint \
        prettier \
        @typescript-eslint/eslint-plugin \
        @typescript-eslint/parser --quiet 2>/dev/null
    echo "✓ JavaScript/TypeScript (ESLint, Prettier, TS)"
}

install_html_css_servers() {
    echo ">>> Installing HTML/CSS servers..."
    sudo npm install -g \
        vscode-langservers-extracted \
        stylelint \
        stylelint-config-standard --quiet 2>/dev/null
    echo "✓ HTML/CSS (Prettier, StyleLint)"
}

install_lua_servers() {
    echo ">>> Installing Lua servers..."
    sudo pacman -S lua-language-server stylua luacheck --noconfirm 2>/dev/null
    echo "✓ Lua (lua-language-server, stylua, luacheck)"
}

install_rust_servers() {
    echo ">>> Installing Rust servers..."
    sudo pacman -S rustup --noconfirm 2>/dev/null
    rustup component add rust-analyzer --quiet 2>/dev/null
    echo "✓ Rust (rust-analyzer)"
}

install_go_servers() {
    echo ">>> Installing Go servers..."
    sudo pacman -S go gopls golangci-lint --noconfirm 2>/dev/null
    echo "✓ Go (gopls, golangci-lint)"
}

install_c_cpp_servers() {
    echo ">>> Installing C/C++ servers..."
    sudo pacman -S clang lldb cmake --noconfirm 2>/dev/null
    echo "✓ C/C++ (clang, lldb, cmake)"
}

install_java_servers() {
    echo ">>> Installing Java servers..."
    sudo pacman -S jdk-openjdk maven gradle --noconfirm 2>/dev/null
    npm install -g eclipse-jdtls --quiet 2>/dev/null
    echo "✓ Java (JDK, maven, gradle)"
}

install_php_servers() {
    echo ">>> Installing PHP servers..."
    sudo pacman -S php php-pear --noconfirm 2>/dev/null
    composer global require felixbecker/language-server 2>/dev/null
    echo "✓ PHP (PHP Language Server)"
}

install_shell_servers() {
    echo ">>> Installing Shell/Bash servers..."
    sudo pacman -S shellcheck shfmt bash-language-server --noconfirm 2>/dev/null
    sudo npm install -g bash-language-server --quiet 2>/dev/null
    echo "✓ Shell (shellcheck, shfmt, bash-language-server)"
}

install_yaml_servers() {
    echo ">>> Installing YAML/JSON servers..."
    sudo npm install -g \
        yaml-language-server \
        jsonlint \
        @stoplight/spectral-cli --quiet 2>/dev/null
    echo "✓ YAML/JSON (yaml-language-server, jsonlint)"
}

install_docker_servers() {
    echo ">>> Installing Docker servers..."
    sudo npm install -g dockerfile-language-server-nodejs --quiet 2>/dev/null
    echo "✓ Docker (Dockerfile Language Server)"
}

install_lang_servers() {
    echo ">>> Installing language servers..."
    
    # System tools
    sudo pacman -S shellcheck shfmt ripgrep fd --noconfirm 2>/dev/null
    
    # Python
    pip install --user pylint flake8 black python-lsp-server autopep8 --quiet
    npm install -g pyright --quiet 2>/dev/null
    
    # Node.js servers
    sudo npm install -g \
        typescript \
        typescript-language-server \
        vscode-langservers-extracted \
        prettier \
        eslint --quiet 2>/dev/null
    
    echo "✓ All language servers installed"
}

interactive_lang_select() {
    clear
    echo "=================================="
    echo "   SELECT DEVELOPMENT LANGUAGES"
    echo "=================================="
    echo ""
    echo "Available languages:"
    echo "1.  Python"
    echo "2.  JavaScript/TypeScript"
    echo "3.  HTML/CSS"
    echo "4.  Lua"
    echo "5.  Rust"
    echo "6.  Go"
    echo "7.  C/C++"
    echo "8.  Java"
    echo "9.  PHP"
    echo "10. Shell/Bash"
    echo "11. YAML/JSON"
    echo "12. Docker"
    echo "13. Install ALL languages"
    echo "14. Back to menu"
    echo ""
    read -p "Choose language(s) (comma-separated, e.g. 1,2,3): " langs
    
    case $langs in
        1) install_python_servers ;;
        2) install_js_servers ;;
        3) install_html_css_servers ;;
        4) install_lua_servers ;;
        5) install_rust_servers ;;
        6) install_go_servers ;;
        7) install_c_cpp_servers ;;
        8) install_java_servers ;;
        9) install_php_servers ;;
        10) install_shell_servers ;;
        11) install_yaml_servers ;;
        12) install_docker_servers ;;
        13) 
            install_python_servers
            install_js_servers
            install_html_css_servers
            install_lua_servers
            install_rust_servers
            install_go_servers
            install_c_cpp_servers
            install_java_servers
            install_php_servers
            install_shell_servers
            install_yaml_servers
            install_docker_servers
            ;;
        14) return ;;
        *)
            # Handle comma-separated input
            IFS=',' read -ra LANGS <<< "$langs"
            for lang in "${LANGS[@]}"; do
                lang=$(echo $lang | xargs) # trim whitespace
                case $lang in
                    1) install_python_servers ;;
                    2) install_js_servers ;;
                    3) install_html_css_servers ;;
                    4) install_lua_servers ;;
                    5) install_rust_servers ;;
                    6) install_go_servers ;;
                    7) install_c_cpp_servers ;;
                    8) install_java_servers ;;
                    9) install_php_servers ;;
                    10) install_shell_servers ;;
                    11) install_yaml_servers ;;
                    12) install_docker_servers ;;
                esac
            done
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

full_install() {
    update_system

    if pacman -Qs "^vim$" > /dev/null; then
        echo ">>> Vim exists → reinstalling..."
        remove_vim
    fi

    install_vim
    install_plug
    setup_vimrc
    setup_coc_config
    install_plugins
    install_coc_extensions

    echo ""
    echo ">>> Installing ALL language servers..."
    echo "(This may take a few minutes)"
    echo ""
    
    install_python_servers
    sleep 1
    install_js_servers
    sleep 1
    install_html_css_servers
    sleep 1
    install_lua_servers
    sleep 1
    install_rust_servers
    sleep 1
    install_go_servers
    sleep 1
    install_c_cpp_servers
    sleep 1
    install_java_servers
    sleep 1
    install_php_servers
    sleep 1
    install_shell_servers
    sleep 1
    install_yaml_servers
    sleep 1
    install_docker_servers

    echo ""
    echo "======================================"
    echo "✓ DONE! Full Vim setup complete!"
    echo "======================================"
    echo "Supported languages:"
    echo "  • Python, JavaScript, TypeScript"
    echo "  • Rust, Go, C/C++, Java, PHP"
    echo "  • Lua, Shell/Bash, YAML, JSON"
    echo "  • HTML, CSS, Docker"
    echo ""
    echo "Restart Vim to use: vim"
    echo "======================================"
}

reinstall_only() {
    remove_vim
    install_vim
    install_plug
    setup_vimrc
    setup_coc_config
    install_plugins
    install_coc_extensions
}

plugins_only() {
    install_plug
    install_plugins
    install_coc_extensions
}

# =========================
# MENU
# =========================
while true; do
    clear
    echo "======================================"
    echo "      VIM ARCH SETUP TOOL v2.0"
    echo "======================================"
    echo "1. Full setup (ALL languages)"
    echo "2. Update system"
    echo "3. Reinstall Vim"
    echo "4. Install plugins only"
    echo "5. Select & install languages"
    echo "6. Install all language servers"
    echo "7. Exit"
    echo "======================================"

    read -p "Choose: " choice

    case $choice in
        1) full_install ;;
        2) update_system ;;
        3) reinstall_only ;;
        4) plugins_only ;;
        5) interactive_lang_select ;;
        6) install_lang_servers ;;
        7) exit ;;
        *) echo "Invalid!" ;;
    esac

    read -p "Press Enter to continue..."
done
