#!/usr/bin/env bash
# =============================================================================
#  zsh.sh — Auto-install & configure Zsh on Arch Linux
#  Stack : Zinit · Powerlevel10k · plugins · Catppuccin Mocha
#  Author: Truong
#  Tested: Arch Linux (bare / proot-distro on Termux)
# =============================================================================

set -euo pipefail

# ─── Color palette ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()     { echo -e "${CYAN}${BOLD}[*]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[✔]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[✘]${RESET} $*" >&2; exit 1; }
step()    { echo -e "\n${BLUE}${BOLD}══════════════════════════════════════${RESET}"; \
            echo -e "${BLUE}${BOLD}  $*${RESET}"; \
            echo -e "${BLUE}${BOLD}══════════════════════════════════════${RESET}"; }

# ─── Detect target user (chạy sudo vẫn config đúng home) ──────────────────────
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
[[ -z "$TARGET_HOME" || "$TARGET_HOME" == "~" ]] && TARGET_HOME="$HOME"

run_as_user() { sudo -u "$TARGET_USER" bash -c "$*"; }

log "Target user : ${BOLD}$TARGET_USER${RESET}"
log "Home dir    : ${BOLD}$TARGET_HOME${RESET}"

# =============================================================================
# 1. UPDATE SYSTEM
# =============================================================================
step "1 · Update system"

if command -v pacman &>/dev/null; then
    log "Đồng bộ database & nâng cấp toàn bộ gói..."
    pacman -Syu --noconfirm
    success "System đã được cập nhật."
else
    warn "pacman không tìm thấy — bỏ qua bước update (có thể đang trong container)."
fi

# =============================================================================
# 2. CHECK UPDATE
# =============================================================================
step "2 · Check update"

log "Kernel version : $(uname -r)"

if command -v pacman &>/dev/null; then
    OUTDATED=$(pacman -Qu 2>/dev/null | wc -l)
    if [[ "$OUTDATED" -gt 0 ]]; then
        warn "$OUTDATED gói chưa cập nhật:"
        pacman -Qu 2>/dev/null
    else
        success "Tất cả gói đều up-to-date."
    fi
fi

log "Kiểm tra shell hiện tại của $TARGET_USER..."
CURRENT_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7 2>/dev/null || echo "$SHELL")
log "Current shell: ${BOLD}$CURRENT_SHELL${RESET}"

log "Kiểm tra Zsh đã cài chưa..."
if command -v zsh &>/dev/null; then
    success "Zsh đã có: $(zsh --version)"
else
    warn "Zsh chưa được cài — sẽ cài ở bước tiếp theo."
fi

# =============================================================================
# 3. INSTALL PACKAGES
# =============================================================================
step "3 · Install packages"

PKGS=(
    # ── Shell chính ──────────────────────────────────────────────────────────
    zsh

    # ── Build tools (Zinit compile plugins) ──────────────────────────────────
    git
    curl
    wget
    unzip
    make
    gcc

    # ── CLI tools tích hợp vào shell ─────────────────────────────────────────
    fzf              # fuzzy finder — Ctrl+R history, Ctrl+T files
    eza              # ls thay thế (màu sắc + icons)
    bat              # cat thay thế (syntax highlight)
    fd               # find thay thế (nhanh hơn)
    ripgrep          # grep thay thế (rg)
    zoxide           # cd thông minh (z / zi)
    delta            # git diff đẹp hơn
    starship         # prompt backup (nếu p10k lỗi)
    thefuck          # sửa lệnh sai tự động
    jq               # JSON processor
    tree             # hiển thị cây thư mục
    tldr             # man page ngắn gọn

    # ── Fonts (Powerlevel10k cần Nerd Font) ───────────────────────────────────
    ttf-jetbrains-mono-nerd
    ttf-font-awesome
)

if command -v pacman &>/dev/null; then
    log "Cài đặt ${#PKGS[@]} packages..."
    pacman -S --needed --noconfirm "${PKGS[@]}" \
        || warn "Một số gói không cài được — kiểm tra lại tên gói."
    success "Packages đã được cài đặt."
else
    warn "Không có pacman — bỏ qua cài packages. Đảm bảo zsh & git đã có."
    command -v zsh &>/dev/null || error "zsh không tìm thấy. Cài thủ công rồi chạy lại."
    command -v git &>/dev/null || error "git không tìm thấy. Cài thủ công rồi chạy lại."
fi

# =============================================================================
# 4. ZSH MẶC ĐỊNH — đổi default shell
# =============================================================================
step "4 · Đặt Zsh làm default shell"

ZSH_BIN=$(command -v zsh)
log "Zsh path: $ZSH_BIN"

# Thêm vào /etc/shells nếu chưa có
if ! grep -qxF "$ZSH_BIN" /etc/shells 2>/dev/null; then
    echo "$ZSH_BIN" >> /etc/shells
    log "Đã thêm $ZSH_BIN vào /etc/shells."
fi

# Đổi shell
if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
    if chsh -s "$ZSH_BIN" "$TARGET_USER" 2>/dev/null; then
        success "Default shell đã đổi sang Zsh."
    else
        warn "chsh thất bại (thường do chạy trong proot/container)."
        warn "Thêm dòng sau vào cuối ~/.bashrc để tự động vào Zsh:"
        warn '  [ -x "$(command -v zsh)" ] && exec zsh -l'
    fi
else
    success "Zsh đã là default shell."
fi

# =============================================================================
# 5. CUSTOM ZSH — Zinit + Powerlevel10k + plugins
# =============================================================================
step "5 · Custom Zsh (Zinit · P10k · Catppuccin Mocha)"

ZDOTDIR="$TARGET_HOME"
ZINIT_HOME="$TARGET_HOME/.local/share/zinit/zinit.git"

# ── 5a. Cài Zinit ─────────────────────────────────────────────────────────────
log "Cài đặt Zinit plugin manager..."

if [[ -d "$ZINIT_HOME" ]]; then
    warn "Zinit đã tồn tại — cập nhật..."
    run_as_user "git -C '$ZINIT_HOME' pull --quiet"
else
    run_as_user "mkdir -p '$(dirname "$ZINIT_HOME")'"
    run_as_user "git clone --depth=1 https://github.com/zdharma-continuum/zinit.git '$ZINIT_HOME'"
fi
success "Zinit sẵn sàng tại $ZINIT_HOME"

# ── 5b. Tải Powerlevel10k font config (offline fallback) ─────────────────────
log "Chuẩn bị thư mục config..."
run_as_user "mkdir -p '$TARGET_HOME/.config/zsh'"

# ── 5c. Tạo .zshrc ────────────────────────────────────────────────────────────
log "Tạo ~/.zshrc..."

ZSHRC="$ZDOTDIR/.zshrc"
[[ -f "$ZSHRC" ]] && cp "$ZSHRC" "${ZSHRC}.bak.$(date +%s)" && warn "Đã backup .zshrc cũ."

cat > "$ZSHRC" <<'ZSHRC_EOF'
# =============================================================================
#  ~/.zshrc — Zsh config
#  Stack: Zinit · Powerlevel10k · fzf · zoxide · eza · bat
#  Theme: Catppuccin Mocha
# =============================================================================

# ─── Powerlevel10k instant prompt (PHẢI ở đầu file) ──────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# ZINIT
# =============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[[ -d "$ZINIT_HOME" ]] || {
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
}
source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# =============================================================================
# PLUGINS
# =============================================================================

# ── Powerlevel10k — prompt ────────────────────────────────────────────────────
zinit ice depth=1; zinit light romkatv/powerlevel10k

# ── Syntax highlighting (phải load trước suggestions) ────────────────────────
zinit ice wait lucid atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting

# ── Autosuggestions ───────────────────────────────────────────────────────────
zinit ice wait lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# ── Completions ───────────────────────────────────────────────────────────────
zinit ice wait lucid blockf atpull"zinit creinstall -q ."
zinit light zsh-users/zsh-completions

# ── fzf-tab (replace zsh completion menu với fzf) ────────────────────────────
zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# ── History substring search ──────────────────────────────────────────────────
zinit ice wait lucid
zinit light zsh-users/zsh-history-substring-search

# ── Sudo (Esc Esc để thêm sudo) ───────────────────────────────────────────────
zinit ice wait lucid
zinit snippet OMZP::sudo

# ── Git aliases ───────────────────────────────────────────────────────────────
zinit ice wait lucid
zinit snippet OMZP::git

# ── Colored man pages ─────────────────────────────────────────────────────────
zinit ice wait lucid
zinit snippet OMZP::colored-man-pages

# ── Extract — giải nén mọi loại file bằng `x file.tar.gz` ────────────────────
zinit ice wait lucid
zinit snippet OMZP::extract

# ── Clipboard — copy/paste cross-platform ─────────────────────────────────────
zinit ice wait lucid
zinit snippet OMZP::copypath

# ── thefuck (cần cài `thefuck` package) ──────────────────────────────────────
zinit ice wait lucid has"thefuck"
zinit snippet OMZP::thefuck

# =============================================================================
# COMPLETION SYSTEM
# =============================================================================
autoload -Uz compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons --color=always --tree --level=1 $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --icons --color=always --tree --level=1 $realpath'
compinit -C

# =============================================================================
# HISTORY
# =============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS   # bỏ duplicate
setopt HIST_IGNORE_SPACE      # lệnh bắt đầu bằng space không lưu
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY          # chia sẻ history giữa các session
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# =============================================================================
# ZSH OPTIONS
# =============================================================================
setopt AUTO_CD              # gõ tên thư mục = cd vào
setopt AUTO_PUSHD           # cd tự push vào stack
setopt PUSHD_IGNORE_DUPS
setopt CORRECT              # gợi ý sửa lệnh sai
setopt INTERACTIVE_COMMENTS # cho phép # comment trong interactive shell
setopt NO_BEEP
setopt GLOB_DOTS            # glob match dotfiles

# =============================================================================
# KEYBINDINGS
# =============================================================================
bindkey -e  # Emacs mode (Ctrl+A, Ctrl+E, Ctrl+R, ...)

# History substring search
bindkey '^[[A' history-substring-search-up    # Up arrow
bindkey '^[[B' history-substring-search-down  # Down arrow
bindkey '^P'   history-substring-search-up
bindkey '^N'   history-substring-search-down

# Autosuggestions
bindkey '^ '  autosuggest-accept   # Ctrl+Space chấp nhận gợi ý
bindkey '^]'  autosuggest-accept   # Alt+→

# Word navigation
bindkey '^[[1;5C' forward-word    # Ctrl+Right
bindkey '^[[1;5D' backward-word   # Ctrl+Left

# Delete word
bindkey '^H' backward-kill-word   # Ctrl+Backspace
bindkey '^[[3;5~' kill-word       # Ctrl+Delete

# =============================================================================
# ENVIRONMENT
# =============================================================================
export EDITOR='vim'
export VISUAL='vim'
export PAGER='bat --style=plain'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_THEME='Catppuccin Mocha'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
    --color=selected-bg:#45475a
    --border=rounded --padding=1
    --height=50% --layout=reverse
    --bind='ctrl-/:toggle-preview'
    --preview-window=right:55%:border-rounded
"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons --color=always --tree --level=2 {}'"
export LESS='-R --use-color -Dd+r$Du+b'
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# =============================================================================
# ALIASES
# =============================================================================

# ── ls → eza ─────────────────────────────────────────────────────────────────
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first --color=always'
    alias ll='eza --icons --group-directories-first --color=always -lh'
    alias la='eza --icons --group-directories-first --color=always -lha'
    alias lt='eza --icons --color=always --tree --level=2'
    alias lta='eza --icons --color=always --tree --level=2 -a'
    alias l='eza --icons --color=always -1'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh --color=auto'
    alias la='ls -lha --color=auto'
fi

# ── cat → bat ─────────────────────────────────────────────────────────────────
command -v bat &>/dev/null && alias cat='bat --style=auto'

# ── grep ──────────────────────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias rg='rg --color=always'

# ── git ───────────────────────────────────────────────────────────────────────
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# ── pacman ────────────────────────────────────────────────────────────────────
alias pac='sudo pacman'
alias pacs='sudo pacman -S'
alias pacss='pacman -Ss'
alias pacu='sudo pacman -Syu'
alias pacr='sudo pacman -Rns'
alias pacq='pacman -Qi'
alias pacl='pacman -Ql'
alias paclogs='cat /var/log/pacman.log | tail -50'

# ── system ────────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias c='clear'
alias q='exit'
alias h='history'
alias j='jobs'
alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias top='htop'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias ln='ln -iv'
alias ff='find . -type f -name'

# ── network ───────────────────────────────────────────────────────────────────
alias ip='ip --color=auto'
alias myip='curl -s ifconfig.me && echo'
alias ping='ping -c 5'

# ── editor ────────────────────────────────────────────────────────────────────
alias v='vim'
alias vi='vim'

# ── misc ──────────────────────────────────────────────────────────────────────
alias reload='source ~/.zshrc && echo "✔ .zshrc reloaded"'
alias zshconfig='$EDITOR ~/.zshrc'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias today='date +"%d/%m/%Y"'
alias weather='curl -s wttr.in/?format=3'

# =============================================================================
# FUNCTIONS
# =============================================================================

# ── mkcd: mkdir + cd ──────────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }

# ── backup: sao lưu file nhanh ────────────────────────────────────────────────
backup() { cp "$1" "${1}.bak.$(date +%Y%m%d_%H%M%S)"; }

# ── extract: giải nén mọi định dạng ──────────────────────────────────────────
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)  tar xjf "$1"    ;;
            *.tar.gz)   tar xzf "$1"    ;;
            *.tar.xz)   tar xJf "$1"    ;;
            *.tar.zst)  tar --zstd -xf "$1" ;;
            *.bz2)      bunzip2 "$1"    ;;
            *.gz)       gunzip "$1"     ;;
            *.tar)      tar xf "$1"     ;;
            *.tbz2)     tar xjf "$1"    ;;
            *.tgz)      tar xzf "$1"    ;;
            *.zip)      unzip "$1"      ;;
            *.Z)        uncompress "$1" ;;
            *.7z)       7z x "$1"       ;;
            *.xz)       unxz "$1"       ;;
            *.zst)      zstd -d "$1"    ;;
            *.rar)      unrar x "$1"    ;;
            *)          echo "Không biết cách giải nén '$1'" ;;
        esac
    else
        echo "'$1' không phải file hợp lệ."
    fi
}

# ── fcd: fzf cd vào thư mục con ───────────────────────────────────────────────
fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null \
        | fzf --preview 'eza --icons --color=always --tree --level=2 {}') \
        && cd "$dir"
}

# ── fkill: fzf kill process ───────────────────────────────────────────────────
fkill() {
    local pid
    pid=$(ps aux | fzf --header '[Kill process]' | awk '{print $2}')
    [[ -n "$pid" ]] && kill -${1:-9} "$pid" && echo "Đã kill PID $pid"
}

# ── fhist: fzf search history và chạy lại ────────────────────────────────────
fhist() {
    local cmd
    cmd=$(history | fzf --tac --no-sort | awk '{$1=""; print $0}' | sed 's/^ //')
    [[ -n "$cmd" ]] && eval "$cmd"
}

# ── gclone: clone repo rồi cd vào ────────────────────────────────────────────
gclone() {
    git clone "$1" && cd "$(basename "$1" .git)"
}

# ── sizeof: kích thước file/thư mục ──────────────────────────────────────────
sizeof() { du -sh "${1:-.}" | cut -f1; }

# ── ports: xem port đang dùng ────────────────────────────────────────────────
ports() { ss -tulanp; }

# ── up: update toàn bộ system + AUR ──────────────────────────────────────────
up() {
    echo "🔄 Updating system..."
    sudo pacman -Syu --noconfirm
    if command -v yay &>/dev/null; then
        echo "🔄 Updating AUR (yay)..."
        yay -Sua --noconfirm
    elif command -v paru &>/dev/null; then
        echo "🔄 Updating AUR (paru)..."
        paru -Sua --noconfirm
    fi
    echo "✔ Done!"
}

# =============================================================================
# INTEGRATIONS
# =============================================================================

# ── fzf key bindings & completion ────────────────────────────────────────────
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
fi
if [[ -f /usr/share/fzf/completion.zsh ]]; then
    source /usr/share/fzf/completion.zsh
fi

# ── zoxide (z / zi thay cd) ───────────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh --cmd z)"
fi

# ── thefuck ───────────────────────────────────────────────────────────────────
if command -v thefuck &>/dev/null; then
    eval "$(thefuck --alias f)"
fi

# ── Bat Catppuccin theme (nếu chưa có sẽ dùng built-in) ─────────────────────
export BAT_THEME='Catppuccin Mocha'

# ── dircolors ────────────────────────────────────────────────────────────────
[[ -f ~/.dircolors ]] && eval "$(dircolors ~/.dircolors)"

# =============================================================================
# POWERLEVEL10K
# =============================================================================
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

ZSHRC_EOF

chown "$TARGET_USER:$TARGET_USER" "$ZSHRC" 2>/dev/null || true
success "~/.zshrc đã tạo."

# ── 5d. Tạo .p10k.z
