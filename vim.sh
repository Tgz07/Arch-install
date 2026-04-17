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
    sudo pacman -S vim git curl nodejs npm --noconfirm
}

install_plug() {
    echo ">>> Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

setup_vimrc() {
    echo ">>> Writing .vimrc..."

    cat > "$VIMRC" << 'EOF'
" =========================
" BASIC
" =========================
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent
syntax on
set mouse=a
set clipboard=unnamedplus
set encoding=UTF-8

" =========================
" PLUGINS
" =========================
call plug#begin('~/.vim/plugged')

" UI
Plug 'joshdick/onedark.vim'
Plug 'itchyny/lightline.vim'

" File explorer
Plug 'preservim/nerdtree'

" Icons
Plug 'ryanoasis/vim-devicons'

" Git
Plug 'tpope/vim-fugitive'

" Auto complete
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Syntax
Plug 'sheerun/vim-polyglot'

call plug#end()

" =========================
" THEME
" =========================
colorscheme onedark

" =========================
" KEYMAP
" =========================
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-s> :w<CR>
nnoremap <C-q> :q<CR>

" =========================
" LIGHTLINE
" =========================
set laststatus=2

" =========================
" COC CONFIG
" =========================
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <CR> pumvisible() ? coc#_select_confirm() : "\<CR>"

EOF
}

install_plugins() {
    echo ">>> Installing plugins..."
    vim +PlugInstall +qall
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
    install_plugins

    echo ">>> DONE! Restart Vim to use."
}

reinstall_only() {
    remove_vim
    install_vim
    install_plug
    setup_vimrc
    install_plugins
}

plugins_only() {
    install_plug
    install_plugins
}

# =========================
# MENU
# =========================
while true; do
    clear
    echo "=========================="
    echo "   VIM ARCH SETUP TOOL"
    echo "=========================="
    echo "1. Full setup (ALL)"
    echo "2. Update system"
    echo "3. Reinstall Vim"
    echo "4. Install plugins only"
    echo "5. Exit"
    echo "=========================="

    read -p "Choose: " choice

    case $choice in
        1) full_install ;;
        2) update_system ;;
        3) reinstall_only ;;
        4) plugins_only ;;
        5) exit ;;
        *) echo "Invalid!" ;;
    esac

    read -p "Press Enter to continue..."
done
