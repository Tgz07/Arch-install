#!/usr/bin/env bash
# =============================================================================
#  install_zsh.sh — Auto-detect OS & install Zsh + plugins from scratch
#  Supports: Arch, Debian/Ubuntu, Fedora/RHEL, macOS, Alpine, Termux (Android)
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()   { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
die()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
sep()  { echo -e "${BOLD}────────────────────────────────────────────────────${RESET}"; }

# =============================================================================
# 1. DETECT OS & RUNTIME ENVIRONMENT
# =============================================================================
sep
log "Detecting system environment..."

OS=""
DISTRO=""
PKG_MGR=""
INSTALL_CMD=""

# Detect runtime (Docker / Termux / WSL / native)
RUNTIME="native"
if [ -f /.dockerenv ]; then
    RUNTIME="docker"
elif [[ "$(uname -r)" == *microsoft* ]] || [[ "$(uname -r)" == *WSL* ]]; then
    RUNTIME="wsl"
elif [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]]; then
    RUNTIME="termux"
fi

case "$(uname -s)" in
    Linux)
        OS="linux"
        if [[ "$RUNTIME" == "termux" ]]; then
            DISTRO="termux"
            PKG_MGR="pkg"
            INSTALL_CMD="pkg install -y"
        elif [ -f /etc/os-release ]; then
            # shellcheck disable=SC1091
            source /etc/os-release
            DISTRO="${ID:-unknown}"
            case "$DISTRO" in
                arch|manjaro|endeavouros|garuda)
                    PKG_MGR="pacman"; INSTALL_CMD="sudo pacman -S --noconfirm" ;;
                ubuntu|debian|linuxmint|pop|kali|raspbian)
                    PKG_MGR="apt";    INSTALL_CMD="sudo apt-get install -y" ;;
                fedora)
                    PKG_MGR="dnf";    INSTALL_CMD="sudo dnf install -y" ;;
                centos|rhel|rocky|almalinux)
                    PKG_MGR="dnf";    INSTALL_CMD="sudo dnf install -y" ;;
                opensuse*|sles)
                    PKG_MGR="zypper"; INSTALL_CMD="sudo zypper install -y" ;;
                alpine)
                    PKG_MGR="apk";    INSTALL_CMD="sudo apk add --no-cache" ;;
                void)
                    PKG_MGR="xbps";   INSTALL_CMD="sudo xbps-install -y" ;;
                nixos)
                    die "NixOS detected — use nix-env or home-manager to install zsh." ;;
                *)
                    if command -v apt-get &>/dev/null; then
                        PKG_MGR="apt"; INSTALL_CMD="sudo apt-get install -y"
                    elif command -v pacman &>/dev/null; then
                        PKG_MGR="pacman"; INSTALL_CMD="sudo pacman -S --noconfirm"
                    elif command -v dnf &>/dev/null; then
                        PKG_MGR="dnf"; INSTALL_CMD="sudo dnf install -y"
                    else
                        die "Unsupported Linux distro: $DISTRO. Install zsh manually."
                    fi
                    ;;
            esac
        fi
        ;;
    Darwin)
        OS="macos"
        DISTRO="macos"
        if command -v brew &>/dev/null; then
            PKG_MGR="brew"; INSTALL_CMD="brew install"
        else
            warn "Homebrew not found — installing it first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            PKG_MGR="brew"; INSTALL_CMD="brew install"
        fi
        ;;
    *)
        die "Unsupported OS: $(uname -s)"
        ;;
esac

ok "OS:      $OS"
ok "Distro:  $DISTRO"
ok "Runtime: $RUNTIME"
ok "Package manager: $PKG_MGR"
sep

# =============================================================================
# 2. UNINSTALL EXISTING ZSH SETUP (full clean)
# =============================================================================
sep
log "Removing existing Zsh installation and config..."

# Kill any lingering zsh processes (best-effort)
pkill zsh 2>/dev/null || true

# Remove config files
for f in \
    "$HOME/.zshrc" \
    "$HOME/.zshenv" \
    "$HOME/.zprofile" \
    "$HOME/.zlogin" \
    "$HOME/.zlogout" \
    "$HOME/.p10k.zsh" \
    "$HOME/.zsh_history" \
    "$HOME/.zcompdump"*
do
    [ -e "$f" ] && { rm -f "$f"; warn "Removed: $f"; }
done

# Remove plugin managers and their directories
for d in \
    "$HOME/.oh-my-zsh" \
    "$HOME/.local/share/zinit" \
    "$HOME/.zim" \
    "$HOME/.antidote" \
    "$HOME/.zplug" \
    "$HOME/.zsh" \
    "$HOME/.zsh_plugins" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
do
    [ -d "$d" ] && { rm -rf "$d"; warn "Removed: $d"; }
done

[ -f "$HOME/.zimrc"  ] && { rm -f "$HOME/.zimrc";  warn "Removed: ~/.zimrc"; }
[ -f "$HOME/.antigen" ] && { rm -f "$HOME/.antigen"; warn "Removed: ~/.antigen"; }

# Uninstall zsh package
log "Uninstalling zsh package..."
case "$PKG_MGR" in
    pacman)  sudo pacman -Rns --noconfirm zsh 2>/dev/null || true ;;
    apt)     sudo apt-get remove -y --purge zsh zsh-common 2>/dev/null || true ;;
    dnf)     sudo dnf remove -y zsh 2>/dev/null || true ;;
    zypper)  sudo zypper remove -y zsh 2>/dev/null || true ;;
    apk)     sudo apk del zsh 2>/dev/null || true ;;
    xbps)    sudo xbps-remove -y zsh 2>/dev/null || true ;;
    brew)    brew uninstall --force zsh 2>/dev/null || true ;;
    pkg)     pkg uninstall -y zsh 2>/dev/null || true ;;
esac

ok "Clean-up complete."
sep

# =============================================================================
# 3. INSTALL ZSH
# =============================================================================
sep
log "Installing Zsh..."

case "$PKG_MGR" in
    apt)
        sudo apt-get update -y
        $INSTALL_CMD zsh zsh-doc curl git
        ;;
    pacman)
        sudo pacman -Sy --noconfirm
        $INSTALL_CMD zsh curl git
        ;;
    dnf)
        $INSTALL_CMD zsh curl git
        ;;
    zypper)
        $INSTALL_CMD zsh curl git
        ;;
    apk)
        $INSTALL_CMD zsh curl git bash
        ;;
    xbps)
        $INSTALL_CMD zsh curl git
        ;;
    brew)
        $INSTALL_CMD zsh curl git
        ;;
    pkg)
        pkg update -y
        $INSTALL_CMD zsh curl git
        ;;
esac

ZSH_BIN="$(command -v zsh)"
ok "Zsh installed: $ZSH_BIN ($(zsh --version))"
sep

# =============================================================================
# 4. INSTALL ZINIT (plugin manager)
# =============================================================================
sep
log "Installing Zinit plugin manager..."

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
mkdir -p "$(dirname "$ZINIT_HOME")"
git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
ok "Zinit installed at: $ZINIT_HOME"
sep

# =============================================================================
# 5. INSTALL MESLO NERD FONT (for Powerlevel10k icons)
# =============================================================================
sep
log "Installing Meslo Nerd Font..."

if [[ "$OS" == "linux" && "$RUNTIME" != "termux" ]]; then
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
    for font in "MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" \
                "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"; do
        encoded="${font// /%20}"
        curl -fsSL "$BASE/$encoded" -o "$FONT_DIR/$font" && log "  Downloaded: $font"
    done
    fc-cache -fv "$FONT_DIR" &>/dev/null && ok "Font cache updated."
elif [[ "$OS" == "macos" ]]; then
    warn "macOS: Install font manually or via:"
    warn "  brew tap homebrew/cask-fonts && brew install --cask font-meslo-lg-nerd-font"
else
    warn "Termux: Install 'MesloLGS NF' font manually in your terminal app."
fi
sep

# =============================================================================
# 6. WRITE ~/.zshrc
# =============================================================================
sep
log "Writing ~/.zshrc..."

cat > "$HOME/.zshrc" << 'ZSHRC'
# =============================================================================
# ~/.zshrc — Zsh configuration with Zinit
# Generated by install_zsh.sh
# =============================================================================

# !! IMPORTANT: Instant prompt MUST be the very first thing — before any output,
# !! any `source`, any command that prints to stdout/stderr.
# !! Do NOT move this block down.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Skip global compinit (we call it manually below for speed)
skip_global_compinit=1

# ── Zinit bootstrap ──────────────────────────────────────────────────────────
# Redirect Zinit's own init messages so they don't pollute instant prompt
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
{
  source "${ZINIT_HOME}/zinit.zsh"
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit
} 2>/dev/null

# =============================================================================
# PLUGINS
# =============================================================================

# Theme: Powerlevel10k — loaded synchronously (no wait) so instant prompt works
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Extra completions for 300+ tools
zinit ice wait lucid
zinit light zsh-users/zsh-completions

# Fish-like inline suggestions (→ arrow to accept)
zinit ice wait lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# Real-time syntax highlighting
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

# History substring search with ↑↓ arrows
zinit ice wait lucid
zinit light zsh-users/zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P'   history-substring-search-up
bindkey '^N'   history-substring-search-down

# Replace tab-completion with fzf preview
zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# Jump to frecent directories (type `z foo`)
zinit ice wait lucid
zinit light agkozak/zsh-z

# Auto-close brackets & quotes
zinit ice wait lucid
zinit light hlissner/zsh-autopair

# Remind you of existing aliases
zinit ice wait lucid
zinit light MichaelAquilina/zsh-you-should-use

# Colored man pages
zinit ice wait lucid
zinit light ael-code/zsh-colored-man-pages

# Press ESC ESC to prepend sudo to last command
zinit ice wait lucid; zinit snippet OMZP::sudo

# Git aliases (ga, gc, gp, glog, etc.)
zinit ice wait lucid; zinit snippet OMZP::git

# Extract any archive with `x file.tar.gz`
zinit ice wait lucid; zinit snippet OMZP::extract

# Copy current path to clipboard
zinit ice wait lucid; zinit snippet OMZP::copypath

# Web search: `google query`, `github query`, etc.
zinit ice wait lucid; zinit snippet OMZP::web-search

# fzf binary
zinit ice wait lucid from"gh-r" as"program"
zinit light junegunn/fzf

# eza — modern ls replacement
zinit ice wait lucid from"gh-r" as"program" mv"eza* -> eza"
zinit light eza-community/eza

# bat — cat with syntax highlighting
zinit ice wait lucid from"gh-r" as"program" mv"bat*/bat -> bat"
zinit light sharkdp/bat

# fd — fast find alternative
zinit ice wait lucid from"gh-r" as"program" mv"fd*/fd -> fd"
zinit light sharkdp/fd

# ripgrep — fast grep
zinit ice wait lucid from"gh-r" as"program" mv"ripgrep*/rg -> rg"
zinit light BurntSushi/ripgrep

# =============================================================================
# COMPLETION SYSTEM
# =============================================================================
autoload -Uz compinit
# Only rebuild once per day for speed
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'

# =============================================================================
# HISTORY
# =============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY

# =============================================================================
# SHELL OPTIONS
# =============================================================================
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt GLOB_DOTS
setopt NO_BEEP

# =============================================================================
# ALIASES
# =============================================================================

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# ls → eza (fallback to system ls)
if command -v eza &>/dev/null; then
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -la --icons --git --group-directories-first"
    alias lt="eza --tree --icons --level=2"
    alias la="eza -a --icons --group-directories-first"
else
    alias ls="ls --color=auto"
    alias ll="ls -lah --color=auto"
    alias la="ls -A --color=auto"
fi

# cat → bat
command -v bat &>/dev/null && alias cat="bat --paging=never"

# grep
alias grep="grep --color=auto"

# Git shortcuts
alias g="git"
alias gs="git status -sb"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline --graph --decorate"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"

# Safety nets
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Utilities
alias zshrc="${EDITOR:-vim} ~/.zshrc"
alias reload="source ~/.zshrc"
alias path='echo -e ${PATH//:/\\n}'
alias ports="ss -tulnp"
alias myip="curl -s ifconfig.me"
alias weather="curl wttr.in"
alias sizeof="du -sh"
alias diff="diff --color=auto"

# =============================================================================
# ENVIRONMENT
# =============================================================================
export EDITOR="${EDITOR:-nvim}"
[ ! -x "$(command -v nvim)" ] && export EDITOR="vim"
export PAGER="less"
export LESS="-R"

# bat as man pager
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# fzf
export FZF_DEFAULT_OPTS="
    --height 40% --border rounded --info inline --layout reverse
    --preview-window right:50%
    --color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8
    --color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8
    --color=info:#cba6f7,prompt:#f38ba8,pointer:#f5e0dc
    --color=marker:#b5e8e0,spinner:#f5e0dc,header:#87afaf
"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Key bindings
bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# =============================================================================
# LOCAL MACHINE OVERRIDES
# =============================================================================
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# =============================================================================
# POWERLEVEL10K — run `p10k configure` to set up your prompt
# =============================================================================
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
ZSHRC

ok "~/.zshrc written."
sep

# =============================================================================
# 7. SET ZSH AS DEFAULT SHELL
# =============================================================================
sep
log "Setting Zsh as default shell..."

if [[ "$RUNTIME" == "termux" ]]; then
    warn "Termux: run 'zsh' to start Zsh. chsh is not supported here."
else
    if ! grep -qx "$ZSH_BIN" /etc/shells 2>/dev/null; then
        echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
        ok "Added $ZSH_BIN to /etc/shells"
    fi

    if [[ "$SHELL" != "$ZSH_BIN" ]]; then
        chsh -s "$ZSH_BIN" "$USER" && ok "Default shell changed to: $ZSH_BIN"
    else
        ok "Zsh is already the default shell."
    fi
fi
sep

# =============================================================================
# DONE
# =============================================================================
sep
echo -e "${GREEN}${BOLD}"
echo "   ███████╗███████╗██╗  ██╗"
echo "      ███╔╝██╔════╝██║  ██║"
echo "     ███╔╝ ███████╗███████║"
echo "    ███╔╝  ╚════██║██╔══██║"
echo "   ███████╗███████║██║  ██║"
echo "   ╚══════╝╚══════╝╚═╝  ╚═╝  installed!"
echo -e "${RESET}"
sep
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  1. ${CYAN}exec zsh${RESET}              — start Zsh now"
echo -e "  2. ${CYAN}p10k configure${RESET}        — interactive prompt wizard"
echo -e "  3. Set terminal font to  ${CYAN}MesloLGS NF${RESET}  for icons"
echo -e "  4. Edit ${CYAN}~/.zshrc${RESET}          to customize further"
echo ""
echo -e "  ${YELLOW}Tip:${RESET} Add machine-specific settings to ${CYAN}~/.zshrc.local${RESET}"
sep
echo ""
