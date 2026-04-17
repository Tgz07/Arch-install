#!/bin/bash

# =====================================================
# Script cài đặt VIM cho Arch Linux
# Tính năng:
# - Cập nhật hệ thống
# - Xoá cấu hình VIM cũ (nếu có) và cài lại mới
# - Thêm plugins, mappings, theme
# - Tối ưu cho lập trình và soạn thảo văn bản
# =====================================================

set -e  # Dừng script nếu có lỗi

# Màu sắc cho terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_msg() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_title() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 1. Cập nhật hệ thống
print_title "Bước 1: Cập nhật hệ thống"
print_msg "Đang cập nhật hệ thống Arch Linux..."
sudo pacman -Syu --noconfirm

# 2. Cài đặt VIM và các gói cần thiết
print_title "Bước 2: Cài đặt VIM và các gói bổ trợ"
print_msg "Cài đặt VIM, GVIM và các công cụ hỗ trợ..."
sudo pacman -S --noconfirm vim gvim vim-runtime vim-colorsamplerpack \
    ctags cscope the_silver_searcher fzf ripgrep fd nodejs npm \
    python python-pip python-pynvim clang lldb

# Cài đặt các công cụ bổ sung từ AUR (nếu có yay hoặc paru)
if command -v yay &> /dev/null; then
    print_msg "Phát hiện yay, cài thêm các gói từ AUR..."
    yay -S --noconfirm vim-plug vim-youcompleteme-git
elif command -v paru &> /dev/null; then
    print_msg "Phát hiện paru, cài thêm các gói từ AUR..."
    paru -S --noconfirm vim-plug vim-youcompleteme-git
fi

# 3. Xoá cấu hình VIM cũ nếu tồn tại
print_title "Bước 3: Xoá cấu hình VIM cũ"
if [ -d ~/.vim ] || [ -f ~/.vimrc ] || [ -f ~/.viminfo ]; then
    print_warn "Phát hiện cấu hình VIM cũ. Đang xoá..."
    # Backup cấu hình cũ (phòng trường hợp)
    if [ -d ~/.vim ] || [ -f ~/.vimrc ]; then
        BACKUP_DIR="$HOME/.vim_backup_$(date +%Y%m%d_%H%M%S)"
        print_msg "Tạo backup tại: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        [ -d ~/.vim ] && mv ~/.vim "$BACKUP_DIR/"
        [ -f ~/.vimrc ] && mv ~/.vimrc "$BACKUP_DIR/"
        [ -f ~/.viminfo ] && mv ~/.viminfo "$BACKUP_DIR/"
    fi
    print_msg "Đã xoá và backup cấu hình cũ."
fi

# 4. Tạo cấu trúc thư mục cho VIM
print_title "Bước 4: Tạo cấu trúc thư mục VIM"
mkdir -p ~/.vim/{autoload,backup,colors,plugged,swap,undo,ftplugin,syntax,doc,plugin}

# 5. Cài đặt Vim-Plug (plugin manager)
print_msg "Cài đặt Vim-Plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# 6. Tạo .vimrc với cấu hình đầy đủ
print_title "Bước 5: Cấu hình .vimrc"
cat > ~/.vimrc << 'EOF'
" =====================================================
" .vimrc - Cấu hình VIM cho Arch Linux
" Tối ưu cho lập trình và soạn thảo
" =====================================================

" ========== CÀI ĐẶT CƠ BẢN ==========
set nocompatible              " Tắt chế độ tương thích với vi
filetype on                   " Bật nhận diện kiểu file
filetype plugin on            " Bật plugin cho từng loại file
filetype indent on            " Bật indent cho từng loại file
syntax on                     " Bật tô màu cú pháp
set mouse=a                   " Hỗ trợ chuột trong mọi chế độ

" ========== GIAO DIỆN ==========
set number                    " Hiển thị số dòng
set relativenumber            " Hiển thị số dòng tương đối
set showmatch                 " Highlight cặp ngoặc tương ứng
set matchtime=2               " Thời gian highlight (0.2 giây)
set cursorline                " Highlight dòng hiện tại
set colorcolumn=80,120        " Cột giới hạn dòng
set showcmd                   " Hiển thị lệnh đang gõ
set showmode                  " Hiển thị chế độ hiện tại
set laststatus=2              " Luôn hiển thị status line
set ruler                     " Hiển thị vị trí con trỏ
set scrolloff=5               " Giữ khoảng cách khi cuộn
set sidescrolloff=5           " Giữ khoảng cách cuộn ngang
set title                     " Hiển thị tiêu đề file

" ========== TÌM KIẾM ==========
set hlsearch                  " Highlight kết quả tìm kiếm
set incsearch                 " Tìm kiếm khi đang gõ
set ignorecase                " Không phân biệt hoa thường
set smartcase                 " Phân biệt nếu có chữ hoa
set wrapscan                  " Quét lại từ đầu khi tìm đến cuối

" ========== INDENT & TAB ==========
set autoindent                " Tự động indent
set smartindent               " Indent thông minh
set expandtab                 " Dùng space thay cho tab
set tabstop=4                 " Tab = 4 spaces
set softtabstop=4             " Tab trong insert mode = 4 spaces
set shiftwidth=4              " Indent = 4 spaces
set smarttab                  " Tab thông minh
set wrap                      " Wrap dòng dài
set linebreak                 " Wrap tại từ hoàn chỉnh

" ========== MÃ HOÁ ==========
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,ucs-bom,cp1258,cp1250

" ========== BACKUP & UNDO ==========
set backup                    " Tạo backup file
set backupdir=~/.vim/backup   " Thư mục backup
set directory=~/.vim/swap     " Thư mục swap file
set undofile                  " Bật undo vĩnh viễn
set undodir=~/.vim/undo       " Thư mục undo file
set writebackup               " Tạo backup trước khi ghi

" ========== LỊCH SỬ ==========
set history=1000              " Lịch sử lệnh
set undolevels=1000           " Số lần undo
set undoreload=10000          " Số dòng lưu khi reload

" ========== FOLDING ==========
set foldmethod=indent         " Fold theo indent
set foldnestmax=10            " Số cấp fold tối đa
set foldlevelstart=99         " Mở fold mặc định
set nofoldenable              " Tắt fold mặc định (có thể bật bằng za)

" ========== CẤU HÌNH PLUGINS (Vim-Plug) ==========
" Tự động cài đặt Vim-Plug nếu chưa có
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" ========== CÁC PLUGIN CẦN THIẾT ==========

" Giao diện & Theme
Plug 'morhetz/gruvbox'                 " Theme gruvbox
Plug 'cocopon/iceberg.vim'             " Theme iceberg
Plug 'vim-airline/vim-airline'         " Status line đẹp
Plug 'vim-airline/vim-airline-themes'  " Themes cho airline

" Tìm kiếm & điều hướng
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'                " Fuzzy finder
Plug 'easymotion/vim-easymotion'       " Di chuyển nhanh
Plug 'scrooloose/nerdtree'             " File explorer
Plug 'preservim/nerdcommenter'         " Comment code nhanh

" Lập trình & Syntax
Plug 'jiangmiao/auto-pairs'            " Tự động đóng ngoặc
Plug 'tpope/vim-surround'              " Xử lý surround (()[]{}"')
Plug 'tpope/vim-fugitive'              " Git integration
Plug 'airblade/vim-gitgutter'          " Hiển thị git diff
Plug 'Yggdroot/indentLine'             " Hiển thị indent line
Plug 'neoclide/coc.nvim', {'branch': 'release'}  " Auto-completion
Plug 'preservim/tagbar'                " Hiển thị cấu trúc code
Plug 'vim-syntastic/syntastic'         " Syntax checking

" Hỗ trợ ngôn ngữ cụ thể
Plug 'pangloss/vim-javascript'         " JavaScript
Plug 'leafgarland/typescript-vim'      " TypeScript
Plug 'rust-lang/rust.vim'              " Rust
Plug 'fatih/vim-go'                    " Golang
Plug 'derekwyatt/vim-scala'            " Scala
Plug 'vim-python/python-syntax'        " Python cải tiến
Plug 'lervag/vimtex'                   " LaTeX

call plug#end()

" ========== CẤU HÌNH THEME ==========
colorscheme gruvbox
set background=dark
let g:gruvbox_contrast_dark = 'hard'

" ========== CẤU HÌNH AIRLINE ==========
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline_powerline_fonts = 1
let g:airline_theme = 'gruvbox'

" ========== CẤU HÌNH NERDTREE ==========
map <C-n> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.pyc$', '\.swp$', '\.o$', '\.obj$']

" ========== CẤU HÌNH FZF ==========
let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.8 } }
let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
nnoremap <C-p> :Files<CR>
nnoremap <C-g> :Rg<CR>

" ========== CẤU HÌNH COC (Auto-completion) ==========
" Sử dụng tab để điều hướng completion
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" ========== CẤU HÌNH EASYMOTION ==========
map <Leader> <Plug>(easymotion-prefix)
map <Leader>f <Plug>(easymotion-overwin-f)
map <Leader>w <Plug>(easymotion-overwin-w)

" ========== CÁC MAPPING TIỆN ÍCH ==========
" Leader key
let mapleader = " "

" Lưu file với sudo
cmap w!! w !sudo tee > /dev/null %

" Di chuyển giữa các window
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Reload .vimrc
nnoremap <leader>sv :source $MYVIMRC<CR>

" Quick save
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>wq :wq<CR>

" Xoá highlight tìm kiếm
nnoremap <leader>h :noh<CR>

" Mở file explorer
nnoremap <leader>e :Explore<CR>

" Chuyển đổi paste mode
set pastetoggle=<F2>

" Mở terminal trong VIM
nnoremap <leader>t :term<CR>

" ========== CÁC AUTOCMD ==========
" Tự động cài đặt plugins khi mới cài đặt
augroup vimrc_autocmd
    autocmd!
    " Tự động cài plugin khi mở VIM lần đầu
    autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
        \ | PlugInstall --sync | source $MYVIMRC
    \ | endif
augroup END

" ========== CẤU HÌNH CHO TỪNG NGÔN NGỮ ==========
" Python
autocmd FileType python setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType python setlocal colorcolumn=79

" JavaScript/TypeScript
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2

" C/C++
autocmd FileType c setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType cpp setlocal shiftwidth=4 tabstop=4 softtabstop=4

" HTML/CSS
autocmd FileType html setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType css setlocal shiftwidth=2 tabstop=2 softtabstop=2

" Go
autocmd FileType go setlocal shiftwidth=4 tabstop=4 softtabstop=4 noexpandtab

" Rust
autocmd FileType rust setlocal shiftwidth=4 tabstop=4 softtabstop=4

" ========== HIỂN THỊ KÝ TỰ ĐẶC BIỆT ==========
set list
set listchars=tab:→\ ,trail:·,extends:>,precedes:<,nbsp:␣

EOF

# 7. Cài đặt các plugin tự động
print_title "Bước 6: Cài đặt VIM plugins"
print_msg "Đang cài đặt các plugins (lần đầu tiên chạy sẽ mất vài phút)..."
vim +PlugInstall +qall

# 8. Cài đặt CocExtensions (auto-completion)
print_title "Bước 7: Cài đặt Coc extensions"
print_msg "Cài đặt các extension cho auto-completion..."
vim -c 'CocInstall -sync coc-json coc-tsserver coc-python coc-html coc-css coc-go coc-rust-analyzer coc-sh coc-markdownlint coc-yaml | qall' 2>/dev/null || true

# 9. Tạo alias trong .bashrc/.zshrc
print_title "Bước 8: Thêm alias cho VIM"
SHELL_CONFIG="$HOME/.zshrc"
if [ ! -f "$SHELL_CONFIG" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

cat >> "$SHELL_CONFIG" << 'EOF'

# VIM aliases
alias v='vim'
alias vi='vim'
alias vimrc='vim ~/.vimrc'
alias vimplug='vim +PlugInstall +qall'
alias vimupdate='vim +PlugUpdate +qall'
alias vimclean='vim +PlugClean +qall'
EOF

print_msg "Đã thêm alias VIM vào $SHELL_CONFIG"

# 10. Tạo script kiểm tra cài đặt
print_title "Bước 9: Tạo script kiểm tra"
cat > ~/check_vim.sh << 'EOF'
#!/bin/bash
echo "=== Kiểm tra cài đặt VIM ==="
echo "VIM version: $(vim --version | head -1)"
echo ""
echo "Các plugin đã cài:"
ls ~/.vim/plugged/ 2>/dev/null || echo "Chưa có plugin nào"
echo ""
echo "Cấu hình VIM:"
vim -c 'PlugStatus' +qall 2>/dev/null
echo ""
echo "Theme hiện tại:"
grep "colorscheme" ~/.vimrc | head -1
EOF

chmod +x ~/check_vim.sh

# 11. Hoàn tất
print_title "CÀI ĐẶT VIM HOÀN TẤT!"
cat << EOF

${GREEN}✓ Đã cài đặt VIM với đầy đủ tính năng${NC}

${YELLOW}CÁC LỆNH CẦN NHỚ:${NC}
  • vim          - Khởi động VIM
  • vimrc        - Mở file cấu hình
  • vimplug      - Cài đặt plugins
  • vimupdate    - Cập nhật plugins
  • check_vim    - Kiểm tra cài đặt

${YELLOW}PHÍM TẮT QUAN TRỌNG:${NC}
  • <Space>sv    - Reload .vimrc
  • <Space>w     - Lưu file
  • <Space>q     - Thoát
  • <Ctrl+n>     - Mở NERDTree
  • <Ctrl+p>     - Tìm kiếm file (FZF)
  • <Space>f     - Di chuyển nhanh (EasyMotion)
  • gd           - Go to definition (Coc)
  • <F2>         - Bật/tắt paste mode

${YELLOW}HƯỚNG DẪN SỬ DỤNG:${NC}
  1. Chạy 'vim' để mở editor
  2. Lần đầu sẽ tự động cài plugins (chờ 2-3 phút)
  3. Gõ ':help' để xem trợ giúp
  4. Gõ ':PlugStatus' để kiểm tra plugins

${BLUE}Để kiểm tra cài đặt, chạy: ~/check_vim.sh${NC}

EOF

# 12. Mở VIM để kiểm tra (tùy chọn)
read -p "Bạn có muốn mở VIM để kiểm tra ngay không? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    vim
fi
