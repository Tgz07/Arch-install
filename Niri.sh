#!/usr/bin/env bash
# =============================================================================
#  niri.sh — Cài đặt Niri Wayland Compositor trên Arch Linux
#  Bao gồm: Niri, Waybar, Zsh + plugins, Vim + plugins, Fcitx5
#  Hỗ trợ: NVIDIA / AMD / Intel (tự detect)
# =============================================================================

set -euo pipefail

# ─── Màu sắc ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Helper ───────────────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
banner()  { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${BLUE}  $*${RESET}"; \
            echo -e "${BOLD}${BLUE}══════════════════════════════════════════${RESET}\n"; }

confirm() {
    local msg="$1"
    local default="${2:-n}"
    local prompt
    [[ "$default" == "y" ]] && prompt="[Y/n]" || prompt="[y/N]"
    echo -en "${YELLOW}${msg} ${prompt}: ${RESET}"
    read -r answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy]$ ]]
}

die() { error "$*"; exit 1; }

# ─── Kiểm tra môi trường ──────────────────────────────────────────────────────
check_root() {
    [[ "$EUID" -eq 0 ]] && die "Không chạy script này bằng root. Chạy với user thường (có sudo)."
}

check_arch() {
    [[ -f /etc/arch-release ]] || die "Script chỉ hỗ trợ Arch Linux."
}

check_internet() {
    info "Kiểm tra kết nối mạng..."
    ping -c 1 -W 3 archlinux.org &>/dev/null || die "Không có kết nối internet."
    success "Kết nối internet OK"
}

# ─── Detect GPU ───────────────────────────────────────────────────────────────
detect_gpu() {
    GPU_TYPE="unknown"
    if lspci 2>/dev/null | grep -qi nvidia; then
        GPU_TYPE="nvidia"
    elif lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        GPU_TYPE="amd"
    elif lspci 2>/dev/null | grep -qi "intel"; then
        GPU_TYPE="intel"
    fi
    info "Detected GPU: ${BOLD}${GPU_TYPE^^}${RESET}"
}

# ─── AUR Helper ───────────────────────────────────────────────────────────────
install_aur_helper() {
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
        success "AUR helper đã có: yay"
        return
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
        success "AUR helper đã có: paru"
        return
    fi

    banner "Cài đặt yay (AUR Helper)"
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    pushd "$tmp/yay" > /dev/null
    makepkg -si --noconfirm
    popd > /dev/null
    rm -rf "$tmp"
    AUR_HELPER="yay"
    success "Đã cài yay"
}

# ─── Gỡ cài đặt (nếu tồn tại) ────────────────────────────────────────────────
uninstall_existing() {
    banner "Dọn dẹp cài đặt cũ"

    local packages_to_remove=(
        niri xwayland-satellite
        waybar swaylock swayidle swaybg
        mako dunst
        wofi rofi-wayland fuzzel
        foot alacritty kitty
        fcitx5 fcitx5-gtk fcitx5-qt fcitx5-chinese-addons fcitx5-bamboo
        fcitx5-configtool fcitx5-lua
        polkit-kde-agent polkit-gnome
        xdg-desktop-portal-gtk xdg-desktop-portal-gnome xdg-desktop-portal-wlr
        wl-clipboard cliphist
        brightnessctl playerctl pamixer
        grim slurp swappy
        network-manager-applet blueman
    )

    local installed=()
    for pkg in "${packages_to_remove[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            installed+=("$pkg")
        fi
    done

    if [[ ${#installed[@]} -eq 0 ]]; then
        info "Không tìm thấy package niri cũ nào cần xoá."
        return
    fi

    warn "Các package sau sẽ bị xoá và cài lại:"
    for p in "${installed[@]}"; do echo "  - $p"; done

    if confirm "Xác nhận xoá toàn bộ?" "y"; then
        sudo pacman -Rns --noconfirm "${installed[@]}" 2>/dev/null || true
        success "Đã xoá các package cũ"
    else
        info "Bỏ qua bước dọn dẹp"
    fi

    # Xoá config cũ nếu muốn
    if [[ -d "$HOME/.config/niri" ]]; then
        if confirm "Xoá config Niri cũ (~/.config/niri)?" "n"; then
            rm -rf "$HOME/.config/niri"
            info "Đã xoá config cũ"
        else
            cp -r "$HOME/.config/niri" "$HOME/.config/niri.bak.$(date +%s)"
            info "Đã backup config cũ → ~/.config/niri.bak.*"
        fi
    fi
}

# ─── Cập nhật hệ thống ────────────────────────────────────────────────────────
update_system() {
    banner "Cập nhật hệ thống"
    sudo pacman -Syu --noconfirm
    success "Hệ thống đã cập nhật"
}

# ─── Cài package nhóm ─────────────────────────────────────────────────────────
pacman_install() {
    sudo pacman -S --noconfirm --needed "$@"
}

aur_install() {
    "$AUR_HELPER" -S --noconfirm --needed "$@"
}

# ─── Cài Niri + dependencies ──────────────────────────────────────────────────
install_niri() {
    banner "Cài đặt Niri & Wayland stack"

    # Core
    pacman_install \
        niri \
        xwayland-satellite \
        xorg-xwayland

    # Status bar
    pacman_install waybar

    # Launcher
    pacman_install fuzzel rofi-wayland

    # Terminal
    pacman_install foot alacritty

    # Notification
    pacman_install mako libnotify

    # Wallpaper
    pacman_install swaybg

    # Lock screen & idle
    pacman_install swaylock swayidle

    # Clipboard
    pacman_install wl-clipboard cliphist

    # Screenshot
    pacman_install grim slurp swappy

    # Audio control
    pacman_install pamixer playerctl

    # Backlight
    pacman_install brightnessctl

    # Portal (screenshare, file picker)
    pacman_install \
        xdg-desktop-portal \
        xdg-desktop-portal-gtk \
        xdg-desktop-portal-wlr

    # Polkit
    pacman_install polkit polkit-kde-agent

    # Font & icons
    pacman_install \
        noto-fonts noto-fonts-cjk noto-fonts-emoji \
        ttf-jetbrains-mono-nerd \
        papirus-icon-theme

    # Network & Bluetooth tray
    pacman_install network-manager-applet blueman

    # Pipewire
    pacman_install \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack \
        wireplumber

    success "Đã cài Niri và Wayland stack"
}

# ─── Cài GPU drivers ──────────────────────────────────────────────────────────
install_gpu_drivers() {
    banner "Cài đặt GPU Drivers (${GPU_TYPE^^})"

    case "$GPU_TYPE" in
        nvidia)
            pacman_install \
                nvidia nvidia-utils nvidia-settings \
                lib32-nvidia-utils egl-wayland
            # NVIDIA env vars cho niri
            mkdir -p "$HOME/.config/niri"
            info "Thêm NVIDIA env vars vào niri config..."
            ;;
        amd)
            pacman_install \
                mesa lib32-mesa \
                vulkan-radeon lib32-vulkan-radeon \
                libva-mesa-driver
            ;;
        intel)
            pacman_install \
                mesa lib32-mesa \
                vulkan-intel lib32-vulkan-intel \
                intel-media-driver
            ;;
        *)
            warn "Không xác định được GPU, bỏ qua bước cài driver."
            ;;
    esac

    success "Đã cài GPU drivers"
}

# ─── Cài Zsh + plugins ────────────────────────────────────────────────────────
install_zsh() {
    banner "Cài đặt Zsh + Plugins"

    pacman_install zsh zsh-completions

    # Zinit
    if [[ ! -d "$HOME/.local/share/zinit/zinit.git" ]]; then
        info "Cài Zinit..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)" || \
            git clone https://github.com/zdharma-continuum/zinit.git \
                "$HOME/.local/share/zinit/zinit.git"
    else
        info "Zinit đã tồn tại"
    fi

    # Modern CLI tools
    pacman_install \
        eza bat fzf ripgrep fd \
        zoxide starship \
        htop btop \
        fastfetch

    # Thay đổi shell mặc định
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        if confirm "Đặt Zsh làm shell mặc định?" "y"; then
            chsh -s "$(which zsh)"
            success "Đã đổi shell mặc định sang Zsh"
        fi
    fi

    # Ghi ~/.zshrc
    write_zshrc
    success "Đã cài Zsh và plugins"
}

write_zshrc() {
    local zshrc="$HOME/.zshrc"

    if [[ -f "$zshrc" ]]; then
        cp "$zshrc" "${zshrc}.bak.$(date +%s)"
        info "Backup .zshrc cũ"
    fi

    cat > "$zshrc" << 'ZSHRC_EOF'
# ── Zinit ─────────────────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[[ ! -d $ZINIT_HOME ]] && \
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# ── Plugins ───────────────────────────────────────────────────────────────────
# Syntax highlighting (phải load trước completions)
zinit light zdharma-continuum/fast-syntax-highlighting

# Autosuggestions
zinit light zsh-users/zsh-autosuggestions

# Completions nâng cao
zinit light zsh-users/zsh-completions

# History substring search
zinit light zsh-users/zsh-history-substring-search

# fzf-tab (thay thế tab completion bằng fzf)
zinit light Aloxaf/fzf-tab

# Git helper
zinit snippet OMZ::plugins/git/git.plugin.zsh

# Extract archives (x <archive>)
zinit snippet OMZ::plugins/extract/extract.plugin.zsh

# Sudo bằng double ESC
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

# ── Prompt: Starship ──────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Zoxide (cd thông minh) ────────────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── FZF ───────────────────────────────────────────────────────────────────────
source /usr/share/fzf/key-bindings.zsh 2>/dev/null || true
source /usr/share/fzf/completion.zsh   2>/dev/null || true
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ── Aliases ───────────────────────────────────────────────────────────────────
alias ls='eza --icons'
alias ll='eza -lh --icons --git'
alias la='eza -lah --icons --git'
alias lt='eza --tree --icons'
alias cat='bat --style=auto'
alias grep='grep --color=auto'
alias cd='z'   # zoxide
alias ..='cd ..'
alias ...='cd ../..'

# pacman shortcuts
alias pacs='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacu='sudo pacman -Syu'
alias pacss='pacman -Ss'
alias pacq='pacman -Qi'

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# ── Completions ───────────────────────────────────────────────────────────────
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always $realpath'

# ── Keybindings ───────────────────────────────────────────────────────────────
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# ── Fcitx5 (Wayland) ─────────────────────────────────────────────────────────
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx

# ── Wayland env ───────────────────────────────────────────────────────────────
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland,x11
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
ZSHRC_EOF

    success "Đã ghi ~/.zshrc"
}

# ─── Cài Vim + plugins ────────────────────────────────────────────────────────
install_vim() {
    banner "Cài đặt Vim + Plugins"

    pacman_install vim

    # vim-plug
    local plug_path="$HOME/.vim/autoload/plug.vim"
    if [[ ! -f "$plug_path" ]]; then
        info "Cài vim-plug..."
        curl -fLo "$plug_path" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    else
        info "vim-plug đã tồn tại"
    fi

    write_vimrc
    install_vim_plugins
    success "Đã cài Vim và plugins"
}

write_vimrc() {
    local vimrc="$HOME/.vimrc"

    if [[ -f "$vimrc" ]]; then
        cp "$vimrc" "${vimrc}.bak.$(date +%s)"
        info "Backup .vimrc cũ"
    fi

    cat > "$vimrc" << 'VIMRC_EOF'
" ── vim-plug ──────────────────────────────────────────────────────────────────
call plug#begin('~/.vim/plugged')

" ── Giao diện ─────────────────────────────────────────────────────────────────
Plug 'joshdick/onedark.vim'             " OneDark theme
Plug 'vim-airline/vim-airline'          " Status bar
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/nerdtree'               " File explorer
Plug 'ryanoasis/vim-devicons'           " Icons
Plug 'Yggdroot/indentLine'              " Indent guides

" ── Editor UX ─────────────────────────────────────────────────────────────────
Plug 'tpope/vim-surround'               " Surround text objects
Plug 'tpope/vim-commentary'             " gc để comment
Plug 'jiangmiao/auto-pairs'             " Auto brackets
Plug 'easymotion/vim-easymotion'        " Quick navigation
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'                 " fzf integration
Plug 'airblade/vim-gitgutter'           " Git diff in gutter
Plug 'tpope/vim-fugitive'               " Git commands
Plug 'preservim/tagbar'                 " Code outline (F8)
Plug 'vim-syntastic/syntastic'          " Syntax checking

" ── LSP / Autocomplete ────────────────────────────────────────────────────────
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" ── Languages ─────────────────────────────────────────────────────────────────
" Python
Plug 'vim-python/python-syntax'
Plug 'Vimjas/vim-python-pep8-indent'

" JavaScript / TypeScript
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'

" HTML / CSS
Plug 'mattn/emmet-vim'
Plug 'hail2u/vim-css3-syntax'
Plug 'othree/html5.vim'

" Rust
Plug 'rust-lang/rust.vim'

" Go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" Lua
Plug 'tbastos/vim-lua'

" Bash / Shell
Plug 'arzg/vim-sh'

" Markdown
Plug 'preservim/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npx --yes yarn install' }

" JSON / YAML
Plug 'elzr/vim-json'
Plug 'stephpy/vim-yaml'

" TOML / KDL (Niri config)
Plug 'cespare/vim-toml'

call plug#end()

" ── Cài đặt chung ─────────────────────────────────────────────────────────────
set nocompatible
filetype plugin indent on
syntax on

set number relativenumber
set cursorline
set tabstop=4 shiftwidth=4 expandtab smartindent
set wrap linebreak
set incsearch hlsearch ignorecase smartcase
set scrolloff=8 sidescrolloff=8
set splitbelow splitright
set hidden
set updatetime=300
set signcolumn=yes
set encoding=utf-8 fileencoding=utf-8
set termguicolors
set clipboard=unnamedplus
set mouse=a
set lazyredraw
set showmatch
set wildmenu wildmode=longest:full,full
set backspace=indent,eol,start

" ── Theme ─────────────────────────────────────────────────────────────────────
colorscheme onedark
let g:airline_theme='onedark'
let g:airline_powerline_fonts=1

" ── NERDTree ──────────────────────────────────────────────────────────────────
nnoremap <C-n> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.git$', '__pycache__', '\.pyc$', 'node_modules']
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 &&
    \ exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" ── Tagbar ────────────────────────────────────────────────────────────────────
nnoremap <F8> :TagbarToggle<CR>

" ── FZF ───────────────────────────────────────────────────────────────────────
nnoremap <C-p> :Files<CR>
nnoremap <C-f> :Rg<CR>
nnoremap <leader>b :Buffers<CR>

" ── CoC ───────────────────────────────────────────────────────────────────────
let g:coc_global_extensions = [
    \ 'coc-pyright',
    \ 'coc-tsserver',
    \ 'coc-eslint',
    \ 'coc-html',
    \ 'coc-css',
    \ 'coc-json',
    \ 'coc-yaml',
    \ 'coc-rust-analyzer',
    \ 'coc-go',
    \ 'coc-lua',
    \ 'coc-sh',
    \ 'coc-pairs',
    \ 'coc-snippets',
    \ ]

inoremap <silent><expr> <TAB>
    \ coc#pum#visible() ? coc#pum#next(1) :
    \ CheckBackspace() ? "\<Tab>" :
    \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"

function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1] =~# '\s'
endfunction

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <leader>rn <Plug>(coc-rename)
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
    if CocAction('hasProvider', 'hover')
        call CocActionAsync('doHover')
    else
        call feedkeys('K', 'in')
    endif
endfunction

" ── Syntastic ─────────────────────────────────────────────────────────────────
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" ── Python ────────────────────────────────────────────────────────────────────
let g:python_highlight_all = 1
autocmd FileType python setlocal ts=4 sw=4 et

" ── JavaScript/TypeScript ─────────────────────────────────────────────────────
autocmd FileType javascript,typescript,jsx,tsx setlocal ts=2 sw=2 et
let g:jsx_ext_required = 0

" ── Rust ──────────────────────────────────────────────────────────────────────
let g:rustfmt_autosave = 1

" ── Go ────────────────────────────────────────────────────────────────────────
let g:go_fmt_command = "goimports"
let g:go_highlight_functions = 1
let g:go_highlight_types = 1

" ── Emmet ─────────────────────────────────────────────────────────────────────
let g:user_emmet_leader_key=','
let g:user_emmet_install_global = 0
autocmd FileType html,css EmmetInstall

" ── Keymaps ───────────────────────────────────────────────────────────────────
let mapleader = " "
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>/ :nohlsearch<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" ── indentLine ────────────────────────────────────────────────────────────────
let g:indentLine_char = '▏'

" ── Markdown preview ──────────────────────────────────────────────────────────
let g:mkdp_auto_close = 1
nmap <leader>md <Plug>MarkdownPreviewToggle
VIMRC_EOF

    success "Đã ghi ~/.vimrc"
}

install_vim_plugins() {
    info "Cài vim-plug plugins... (có thể mất vài phút)"
    vim +PlugInstall +qall 2>/dev/null || true
    success "Đã cài Vim plugins"
}

# ─── Cài Fcitx5 ───────────────────────────────────────────────────────────────
install_fcitx5() {
    banner "Cài đặt Fcitx5 (Input Method)"

    pacman_install \
        fcitx5 \
        fcitx5-gtk \
        fcitx5-qt \
        fcitx5-configtool \
        fcitx5-lua

    echo ""
    echo -e "${CYAN}Chọn IME (Input Method Engine):${RESET}"
    echo "  1) fcitx5-bamboo     (Tiếng Việt — Bamboo)"
    echo "  2) fcitx5-unikey     (Tiếng Việt — Unikey, từ AUR)"
    echo "  3) fcitx5-chinese-addons (Tiếng Trung — Pinyin/Cangjie)"
    echo "  4) fcitx5-mozc       (Tiếng Nhật)"
    echo "  5) fcitx5-hangul     (Tiếng Hàn)"
    echo "  6) Bỏ qua"
    echo ""
    echo -en "${YELLOW}Lựa chọn [1-6, nhập nhiều cách nhau dấu cách]: ${RESET}"
    read -r ime_choices

    for choice in $ime_choices; do
        case "$choice" in
            1)
                pacman_install fcitx5-bamboo 2>/dev/null || \
                    aur_install fcitx5-bamboo
                ;;
            2)
                aur_install fcitx5-unikey
                ;;
            3)
                pacman_install fcitx5-chinese-addons
                ;;
            4)
                pacman_install fcitx5-mozc
                ;;
            5)
                pacman_install fcitx5-hangul
                ;;
            6)
                info "Bỏ qua cài IME"
                ;;
            *)
                warn "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done

    # Environment variables cho Fcitx5 Wayland
    local profile_conf="$HOME/.config/environment.d/fcitx5.conf"
    mkdir -p "$(dirname "$profile_conf")"
    cat > "$profile_conf" << 'FCITX_EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
FCITX_EOF

    success "Đã ghi fcitx5 env → ${profile_conf}"

    # Autostart
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    if [[ ! -f "$autostart_dir/fcitx5.desktop" ]]; then
        cat > "$autostart_dir/fcitx5.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Name=Fcitx 5
GenericName=Input Method
Comment=Start Input Method
Exec=fcitx5
Icon=fcitx
Terminal=false
Type=Application
Categories=System;Utility;
X-GNOME-Autostart-Phase=Applications
X-GNOME-AutoRestart=false
X-KDE-autostart-after=panel
DESKTOP_EOF
        success "Đã tạo autostart fcitx5"
    fi

    success "Đã cài Fcitx5"
}

# ─── Tạo Niri config ──────────────────────────────────────────────────────────
create_niri_config() {
    banner "Tạo Niri config (~/.config/niri/config.kdl)"

    local cfg_dir="$HOME/.config/niri"
    mkdir -p "$cfg_dir"
    local cfg="$cfg_dir/config.kdl"

    if [[ -f "$cfg" ]]; then
        info "Config đã tồn tại, bỏ qua (dùng backup nếu cần)"
        return
    fi

    # NVIDIA specific env
    local nvidia_env=""
    if [[ "$GPU_TYPE" == "nvidia" ]]; then
        nvidia_env='environment {
    // NVIDIA Wayland
    GBM_BACKEND "nvidia-drm"
    __GLX_VENDOR_LIBRARY_NAME "nvidia"
    LIBVA_DRIVER_NAME "nvidia"
    NVD_BACKEND "direct"
}'
    fi

    cat > "$cfg" << NIRI_CFG_EOF
// ── Niri config.kdl ──────────────────────────────────────────────────────────
// Sinh bởi niri.sh | Chỉnh sửa tùy ý

// Không dùng client-side decorations
prefer-no-csd

// Screenshot path
screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

// ── Environment ──────────────────────────────────────────────────────────────
environment {
    QT_QPA_PLATFORM "wayland"
    MOZ_ENABLE_WAYLAND "1"
    GTK_IM_MODULE "fcitx"
    QT_IM_MODULE "fcitx"
    XMODIFIERS "@im=fcitx"
    XCURSOR_THEME "Adwaita"
    XCURSOR_SIZE "24"
}
${nvidia_env}

// ── Input ─────────────────────────────────────────────────────────────────────
input {
    keyboard {
        xkb {
            // layout "us,vn"
            // options "grp:alt_shift_toggle"
        }
        repeat-delay 250
        repeat-rate 35
    }
    touchpad {
        tap
        natural-scroll
        dwt  // disable while typing
    }
    mouse {
        accel-speed 0.0
    }
}

// ── Outputs ───────────────────────────────────────────────────────────────────
// Bỏ comment và chỉnh sửa theo monitor thực tế (niri msg outputs)
// output "HDMI-A-1" {
//     mode "1920x1080@60.000"
//     scale 1.0
//     position x=0 y=0
// }

// ── Layout ───────────────────────────────────────────────────────────────────
layout {
    gaps 8
    center-focused-column "never"
    default-column-width { proportion 0.5; }

    focus-ring {
        width 2
        active-color "#89b4fa"    // Catppuccin Blue
        inactive-color "#313244"
    }

    border {
        off
    }

    struts {
        left 0
        right 0
        top 0
        bottom 0
    }
}

// ── Animations ────────────────────────────────────────────────────────────────
animations {
    slowdown 1.0

    workspace-switch {
        spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
    }

    window-open {
        duration-ms 150
        curve "ease-out-expo"
    }

    window-close {
        duration-ms 150
        curve "ease-out-quad"
    }
}

// ── Spawn apps khi start ──────────────────────────────────────────────────────
spawn-at-startup "swaybg" "-m" "fill" "-c" "#1e1e2e"
spawn-at-startup "mako"
spawn-at-startup "waybar"
spawn-at-startup "fcitx5" "-d"
spawn-at-startup "xwayland-satellite"

// ── Window rules ──────────────────────────────────────────────────────────────
window-rule {
    match app-id="org.gnome.Calculator"
    match app-id="org.gnome.Nautilus"
    open-floating true
    default-floating-size { width 800; height 600; }
}

window-rule {
    match app-id="firefox"
    default-column-width { proportion 0.65; }
}

// ── Keybindings ───────────────────────────────────────────────────────────────
// Mod = Super key
binds {
    // ── App launchers ─────────────────────────────────────────────────────────
    Mod+T { spawn "foot"; }
    Mod+Return { spawn "foot"; }
    Mod+D { spawn "fuzzel"; }
    Mod+E { spawn "nemo"; }
    Mod+B { spawn "firefox"; }

    // ── Session ───────────────────────────────────────────────────────────────
    Mod+Shift+Q { close-window; }
    Mod+Shift+E { quit; }
    Ctrl+Alt+Delete { quit; }

    // ── Reload config ─────────────────────────────────────────────────────────
    Mod+Shift+R { reload-config; }

    // ── Focus windows ─────────────────────────────────────────────────────────
    Mod+H     { focus-column-left; }
    Mod+J     { focus-window-down; }
    Mod+K     { focus-window-up; }
    Mod+L     { focus-column-right; }
    Mod+Left  { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+Up    { focus-window-up; }
    Mod+Down  { focus-window-down; }

    // ── Move windows ──────────────────────────────────────────────────────────
    Mod+Shift+H     { move-column-left; }
    Mod+Shift+J     { move-window-down; }
    Mod+Shift+K     { move-window-up; }
    Mod+Shift+L     { move-column-right; }
    Mod+Shift+Left  { move-column-left; }
    Mod+Shift+Right { move-column-right; }

    // ── Resize columns ────────────────────────────────────────────────────────
    Mod+Minus  { set-column-width "-10%"; }
    Mod+Equal  { set-column-width "+10%"; }
    Mod+Ctrl+H { set-column-width "-10%"; }
    Mod+Ctrl+L { set-column-width "+10%"; }
    Mod+Ctrl+J { set-window-height "-10%"; }
    Mod+Ctrl+K { set-window-height "+10%"; }

    // ── Fullscreen / maximize ─────────────────────────────────────────────────
    Mod+F       { maximize-column; }
    Mod+Shift+F { fullscreen-window; }
    Mod+C       { center-column; }

    // ── Workspaces ────────────────────────────────────────────────────────────
    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }

    Mod+Shift+1 { move-column-to-workspace 1; }
    Mod+Shift+2 { move-column-to-workspace 2; }
    Mod+Shift+3 { move-column-to-workspace 3; }
    Mod+Shift+4 { move-column-to-workspace 4; }
    Mod+Shift+5 { move-column-to-workspace 5; }
    Mod+Shift+6 { move-column-to-workspace 6; }
    Mod+Shift+7 { move-column-to-workspace 7; }
    Mod+Shift+8 { move-column-to-workspace 8; }
    Mod+Shift+9 { move-column-to-workspace 9; }

    Mod+Tab         { focus-workspace-down; }
    Mod+Shift+Tab   { focus-workspace-up; }
    Mod+Page_Down   { focus-workspace-down; }
    Mod+Page_Up     { focus-workspace-up; }

    // ── Screenshots ───────────────────────────────────────────────────────────
    Mod+S                  { screenshot; }
    Ctrl+Print             { screenshot-screen; }
    Alt+Print              { screenshot-window; }

    // ── Media keys ────────────────────────────────────────────────────────────
    XF86AudioRaiseVolume  allow-when-locked=true { spawn "pamixer" "-i" "5"; }
    XF86AudioLowerVolume  allow-when-locked=true { spawn "pamixer" "-d" "5"; }
    XF86AudioMute         allow-when-locked=true { spawn "pamixer" "-t"; }
    XF86AudioMicMute      allow-when-locked=true { spawn "pamixer" "--default-source" "-t"; }
    XF86MonBrightnessUp                          { spawn "brightnessctl" "s" "+10%"; }
    XF86MonBrightnessDown                        { spawn "brightnessctl" "s" "10%-"; }
    XF86AudioPlay  allow-when-locked=true { spawn "playerctl" "play-pause"; }
    XF86AudioNext  allow-when-locked=true { spawn "playerctl" "next"; }
    XF86AudioPrev  allow-when-locked=true { spawn "playerctl" "previous"; }

    // ── Lock screen ───────────────────────────────────────────────────────────
    Mod+Shift+L { spawn "swaylock" "-f" "-c" "1e1e2e"; }

    // ── Clipboard ─────────────────────────────────────────────────────────────
    Mod+V { spawn "sh" "-c" "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"; }

    // ── Overview ──────────────────────────────────────────────────────────────
    Mod+O { toggle-overview; }

    // ── Help ──────────────────────────────────────────────────────────────────
    Mod+Shift+Slash { show-hotkey-overlay; }
}
NIRI_CFG_EOF

    success "Đã tạo ~/.config/niri/config.kdl"

    # Waybar config cơ bản
    create_waybar_config
}

create_waybar_config() {
    local wbar_dir="$HOME/.config/waybar"
    mkdir -p "$wbar_dir"

    if [[ -f "$wbar_dir/config.jsonc" ]]; then
        info "Waybar config đã tồn tại, bỏ qua"
        return
    fi

    cat > "$wbar_dir/config.jsonc" << 'WAYBAR_EOF'
{
    "layer": "top",
    "position": "top",
    "height": 32,
    "spacing": 4,
    "modules-left":   ["niri/workspaces", "niri/window"],
    "modules-center": ["clock"],
    "modules-right":  ["pulseaudio", "network", "cpu", "memory", "battery", "tray"],

    "niri/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "active":  "",
            "default": ""
        }
    },
    "niri/window": { "max-length": 50 },
    "clock": {
        "format":      "{:%H:%M}",
        "format-alt":  "{:%Y-%m-%d %H:%M:%S}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    "cpu":    { "format": " {usage}%", "interval": 2 },
    "memory": { "format": " {used:.1f}G", "interval": 5 },
    "battery": {
        "states": { "warning": 30, "critical": 15 },
        "format": "{icon} {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },
    "network": {
        "format-wifi":       " {signalStrength}%",
        "format-ethernet":   " {ifname}",
        "format-disconnected":"⚠ Offline"
    },
    "pulseaudio": {
        "format":        "{icon} {volume}%",
        "format-muted":  " muted",
        "format-icons":  { "default": ["", "", ""] },
        "on-click":      "pavucontrol"
    },
    "tray": { "spacing": 8 }
}
WAYBAR_EOF

    # Waybar style cơ bản (Catppuccin Mocha)
    cat > "$wbar_dir/style.css" << 'STYLE_EOF'
* {
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 13px;
    border: none;
    border-radius: 0;
    min-height: 0;
}

window#waybar {
    background: rgba(30,30,46,0.95);
    color: #cdd6f4;
    border-bottom: 2px solid #313244;
}

#workspaces button {
    padding: 0 6px;
    color: #6c7086;
    background: transparent;
}
#workspaces button.active {
    color: #89b4fa;
    border-bottom: 2px solid #89b4fa;
}
#workspaces button:hover {
    background: #313244;
    color: #cdd6f4;
}

#clock      { color: #89dceb; padding: 0 12px; }
#cpu        { color: #a6e3a1; padding: 0 8px; }
#memory     { color: #fab387; padding: 0 8px; }
#battery    { color: #a6e3a1; padding: 0 8px; }
#battery.warning  { color: #f9e2af; }
#battery.critical { color: #f38ba8; }
#network    { color: #89b4fa; padding: 0 8px; }
#pulseaudio { color: #cba6f7; padding: 0 8px; }
#tray       { padding: 0 8px; }
STYLE_EOF

    success "Đã tạo Waybar config"
}

# ─── Enable services ──────────────────────────────────────────────────────────
enable_services() {
    banner "Enable Systemd services"

    # PipeWire
    systemctl --user enable --now pipewire.service       2>/dev/null || true
    systemctl --user enable --now pipewire-pulse.service 2>/dev/null || true
    systemctl --user enable --now wireplumber.service    2>/dev/null || true

    success "Đã enable PipeWire services"
}

# ─── Summary ──────────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║     Cài đặt Niri hoàn tất! 🎉           ║${RESET}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${CYAN}Bước tiếp theo:${RESET}"
    echo "  1. Khởi động lại máy: sudo reboot"
    echo "  2. Chọn 'Niri' ở màn hình login (nếu dùng display manager)"
    echo "     Hoặc chạy: niri-session (từ TTY)"
    echo ""
    echo -e "${CYAN}Keybinds quan trọng:${RESET}"
    echo "  Super+T          → Mở terminal (foot)"
    echo "  Super+D          → Launcher (fuzzel)"
    echo "  Super+O          → Overview tất cả workspaces"
    echo "  Super+Shift+/    → Xem tất cả keybinds"
    echo "  Super+Shift+E    → Thoát Niri"
    echo ""
    echo -e "${CYAN}Files đã tạo:${RESET}"
    echo "  ~/.config/niri/config.kdl    → Niri config"
    echo "  ~/.config/waybar/            → Waybar config + style"
    echo "  ~/.zshrc                     → Zsh + Zinit plugins"
    echo "  ~/.vimrc                     → Vim + plugins"
    echo ""
    echo -e "${YELLOW}Sau khi vào Niri:${RESET}"
    echo "  • Cấu hình Fcitx5: chạy fcitx5-configtool"
    echo "  • Cài Vim plugins: vim +PlugInstall"
    echo "  • Chỉnh monitor: niri msg outputs → sửa config.kdl"
    echo ""
}

# ─── Menu chọn components ─────────────────────────────────────────────────────
show_menu() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║     Niri Installer — Arch Linux          ║${RESET}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${CYAN}Chọn chế độ cài đặt:${RESET}"
    echo "  1) Cài đặt đầy đủ (recommended)"
    echo "  2) Chỉ Niri + Wayland stack"
    echo "  3) Chỉ Zsh + Vim"
    echo "  4) Chỉ Fcitx5"
    echo "  5) Tất cả (bao gồm dọn dẹp cài lại)"
    echo "  q) Thoát"
    echo ""
    echo -en "${YELLOW}Lựa chọn [1-5/q]: ${RESET}"
    read -r choice

    case "$choice" in
        1)
            DO_NIRI=true DO_ZSH=true DO_VIM=true DO_FCITX=true
            DO_CLEAN=false
            ;;
        2)
            DO_NIRI=true DO_ZSH=false DO_VIM=false DO_FCITX=false
            DO_CLEAN=false
            ;;
        3)
            DO_NIRI=false DO_ZSH=true DO_VIM=true DO_FCITX=false
            DO_CLEAN=false
            ;;
        4)
            DO_NIRI=false DO_ZSH=false DO_VIM=false DO_FCITX=true
            DO_CLEAN=false
            ;;
        5)
            DO_NIRI=true DO_ZSH=true DO_VIM=true DO_FCITX=true
            DO_CLEAN=true
            ;;
        q|Q)
            echo "Thoát."
            exit 0
            ;;
        *)
            die "Lựa chọn không hợp lệ: $choice"
            ;;
    esac
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    check_root
    check_arch
    check_internet
    detect_gpu

    show_menu

    update_system
    install_aur_helper

    ${DO_CLEAN} && uninstall_existing

    ${DO_NIRI}  && { install_gpu_drivers; install_niri; create_niri_config; }
    ${DO_ZSH}   && install_zsh
    ${DO_VIM}   && install_vim
    ${DO_FCITX} && install_fcitx5

    enable_services
    print_summary
}

main "$@"
