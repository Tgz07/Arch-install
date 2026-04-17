#!/bin/bash
# ============================================================
#  i3 Setup Script for Arch Linux
#  Inspired by VuNguyenCoder
#  Author  : Custom Build
#  Version : 1.0.0
# ============================================================

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "${CYAN}${BOLD}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}${BOLD}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERR]${RESET}   $*"; }
step()    { echo -e "\n${MAGENTA}${BOLD}══════════════════════════════════════${RESET}"; \
            echo -e "${MAGENTA}${BOLD}  $*${RESET}"; \
            echo -e "${MAGENTA}${BOLD}══════════════════════════════════════${RESET}"; }

confirm() {
    echo -e "${YELLOW}${BOLD}[?]${RESET}    $* ${YELLOW}(y/N)${RESET}: \c"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# ── Paths ────────────────────────────────────────────────────
CONFIG_DIR="$HOME/.config"
I3_DIR="$CONFIG_DIR/i3"
POLYBAR_DIR="$CONFIG_DIR/polybar"
PICOM_DIR="$CONFIG_DIR/picom"
ROFI_DIR="$CONFIG_DIR/rofi"
DUNST_DIR="$CONFIG_DIR/dunst"
ALACRITTY_DIR="$CONFIG_DIR/alacritty"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
FONTS_DIR="$HOME/.local/share/fonts"

# ── Catppuccin Mocha Palette ─────────────────────────────────
COLOR_BASE="#1e1e2e"
COLOR_MANTLE="#181825"
COLOR_CRUST="#11111b"
COLOR_TEXT="#cdd6f4"
COLOR_SUBTEXT="#bac2de"
COLOR_SURFACE="#313244"
COLOR_OVERLAY="#45475a"
COLOR_BLUE="#89b4fa"
COLOR_MAUVE="#cba6f7"
COLOR_RED="#f38ba8"
COLOR_GREEN="#a6e3a1"
COLOR_YELLOW="#f9e2af"
COLOR_PEACH="#fab387"
COLOR_TEAL="#94e2d5"
COLOR_SKY="#89dceb"
COLOR_PINK="#f5c2e7"

# ════════════════════════════════════════════════════════════
#  BANNER
# ════════════════════════════════════════════════════════════
show_banner() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "  ██╗██████╗     ███████╗███████╗████████╗██╗   ██╗██████╗ "
    echo "  ██║╚════██╗    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗"
    echo "  ██║ █████╔╝    ███████╗█████╗     ██║   ██║   ██║██████╔╝"
    echo "  ██║ ╚═══██╗    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ "
    echo "  ██║██████╔╝    ███████║███████╗   ██║   ╚██████╔╝██║     "
    echo "  ╚═╝╚═════╝     ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     "
    echo -e "${RESET}"
    echo -e "${CYAN}  Arch Linux • i3 Window Manager • Catppuccin Mocha${RESET}"
    echo -e "${CYAN}  Inspired by VuNguyenCoder${RESET}"
    echo ""
}

# ════════════════════════════════════════════════════════════
#  CHECKS
# ════════════════════════════════════════════════════════════
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Đừng chạy script này với quyền root!"
        exit 1
    fi
}

check_arch() {
    if ! command -v pacman &>/dev/null; then
        error "Script này chỉ chạy trên Arch Linux!"
        exit 1
    fi
    success "Arch Linux detected"
}

check_aur_helper() {
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        AUR_HELPER=""
        warn "Không tìm thấy AUR helper (yay/paru). Sẽ cài yay."
    fi
}

# ════════════════════════════════════════════════════════════
#  INSTALL AUR HELPER
# ════════════════════════════════════════════════════════════
install_aur_helper() {
    if [[ -n "$AUR_HELPER" ]]; then
        success "AUR helper: $AUR_HELPER"
        return
    fi

    step "Cài đặt yay (AUR Helper)"
    sudo pacman -S --needed --noconfirm git base-devel
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    AUR_HELPER="yay"
    success "yay đã được cài đặt"
}

# ════════════════════════════════════════════════════════════
#  DETECT EXISTING INSTALLATION
# ════════════════════════════════════════════════════════════
detect_existing() {
    EXISTING=()
    [[ -d "$I3_DIR" ]]        && EXISTING+=("i3 config (~/.config/i3)")
    [[ -d "$POLYBAR_DIR" ]]   && EXISTING+=("polybar config (~/.config/polybar)")
    [[ -d "$PICOM_DIR" ]]     && EXISTING+=("picom config (~/.config/picom)")
    [[ -d "$ROFI_DIR" ]]      && EXISTING+=("rofi config (~/.config/rofi)")
    [[ -d "$DUNST_DIR" ]]     && EXISTING+=("dunst config (~/.config/dunst)")
    [[ -d "$ALACRITTY_DIR" ]] && EXISTING+=("alacritty config (~/.config/alacritty)")

    if [[ ${#EXISTING[@]} -gt 0 ]]; then
        warn "Phát hiện cài đặt cũ:"
        for item in "${EXISTING[@]}"; do
            echo -e "   ${RED}▸${RESET} $item"
        done
        echo ""
        if confirm "Xoá toàn bộ config cũ và cài lại từ đầu?"; then
            remove_existing
        else
            warn "Giữ nguyên config cũ. Các file sẽ bị ghi đè."
        fi
    fi
}

remove_existing() {
    step "Xoá config cũ"
    local dirs=("$I3_DIR" "$POLYBAR_DIR" "$PICOM_DIR" "$ROFI_DIR" "$DUNST_DIR" "$ALACRITTY_DIR")
    for d in "${dirs[@]}"; do
        if [[ -d "$d" ]]; then
            rm -rf "$d"
            success "Đã xoá: $d"
        fi
    done

    # Xoá các packages i3 cũ nếu có
    if confirm "Gỡ toàn bộ packages i3 cũ trước khi cài lại?"; then
        local old_pkgs=(i3-wm i3blocks i3status i3lock i3gaps)
        for pkg in "${old_pkgs[@]}"; do
            if pacman -Q "$pkg" &>/dev/null; then
                sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null && warn "Đã gỡ: $pkg"
            fi
        done
    fi
}

# ════════════════════════════════════════════════════════════
#  SYSTEM UPDATE
# ════════════════════════════════════════════════════════════
system_update() {
    step "Cập nhật hệ thống"
    if confirm "Cập nhật toàn bộ hệ thống trước khi cài?"; then
        sudo pacman -Syu --noconfirm
        success "Hệ thống đã được cập nhật"
    else
        info "Bỏ qua cập nhật hệ thống"
    fi
}

# ════════════════════════════════════════════════════════════
#  PACKAGE LISTS
# ════════════════════════════════════════════════════════════
PACMAN_PKGS=(
    # i3 core
    i3-wm
    i3lock
    i3status

    # Display
    xorg-server
    xorg-xinit
    xorg-xrandr
    xorg-xsetroot
    xorg-xbacklight
    arandr

    # Compositor
    picom

    # Bar
    polybar

    # Launcher
    rofi

    # Terminal
    alacritty

    # Notification
    dunst
    libnotify

    # File manager
    thunar
    thunar-archive-plugin
    gvfs

    # Fonts
    ttf-jetbrains-mono-nerd
    ttf-font-awesome
    noto-fonts
    noto-fonts-emoji

    # Media / Volume
    pulseaudio
    pulseaudio-alsa
    pamixer
    pavucontrol
    playerctl

    # Brightness
    brightnessctl

    # Screenshot
    scrot
    xclip

    # Network
    networkmanager
    network-manager-applet

    # Wallpaper
    nitrogen
    feh

    # Utils
    lxappearance
    qt5ct
    xdotool
    xss-lock
    numlockx
    unzip
    zip
    wget
    curl
    git
    base-devel
    neofetch
    htop
    btop
    ranger
    zip
    unzip
    p7zip
    xarchiver
)

AUR_PKGS=(
    # i3 with gaps (nếu dùng i3-gaps thay i3-wm)
    # i3-gaps   # bỏ comment nếu muốn dùng gaps

    # Themes & Icons
    catppuccin-gtk-theme-mocha
    papirus-icon-theme

    # Cursor
    bibata-cursor-theme

    # Extra
    i3lock-color
    betterlockscreen
    picom-git
    rofi-calc
    networkmanager-dmenu-git
)

# ════════════════════════════════════════════════════════════
#  INSTALL PACKAGES
# ════════════════════════════════════════════════════════════
install_packages() {
    step "Cài đặt packages chính (pacman)"
    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" 2>&1 | \
        grep -E "^(installing|error|warning)" | \
        sed "s/^installing/$(echo -e "${GREEN}[+]${RESET}") installing/" | \
        sed "s/^error/$(echo -e "${RED}[!]${RESET}") error/"
    success "Packages pacman đã được cài đặt"

    step "Cài đặt packages AUR"
    if confirm "Cài các packages từ AUR? (themes, extras)"; then
        $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}" 2>/dev/null || \
            warn "Một số AUR packages có thể không cài được — kiểm tra thủ công"
        success "AUR packages hoàn tất"
    fi
}

# ════════════════════════════════════════════════════════════
#  CREATE DIRECTORIES
# ════════════════════════════════════════════════════════════
create_dirs() {
    step "Tạo thư mục cấu hình"
    local dirs=(
        "$I3_DIR"
        "$I3_DIR/scripts"
        "$POLYBAR_DIR"
        "$POLYBAR_DIR/scripts"
        "$PICOM_DIR"
        "$ROFI_DIR"
        "$DUNST_DIR"
        "$ALACRITTY_DIR"
        "$WALLPAPER_DIR"
        "$FONTS_DIR"
        "$HOME/.local/bin"
    )
    for d in "${dirs[@]}"; do
        mkdir -p "$d" && success "Created: $d"
    done
}

# ════════════════════════════════════════════════════════════
#  WRITE CONFIGS
# ════════════════════════════════════════════════════════════

# ── i3 config ────────────────────────────────────────────────
write_i3_config() {
    step "Viết i3 config"
    cat > "$I3_DIR/config" << 'ENDOFCONFIG'
# ================================================================
#  i3 Config — Catppuccin Mocha
#  Inspired by VuNguyenCoder
# ================================================================

set $mod Mod4
set $left  h
set $down  j
set $up    k
set $right l

# ── Font ────────────────────────────────────────────────────────
font pango:JetBrainsMono Nerd Font 10

# ── Catppuccin Colors ───────────────────────────────────────────
set $base     #1e1e2e
set $mantle   #181825
set $crust    #11111b
set $text     #cdd6f4
set $subtext  #bac2de
set $surface  #313244
set $overlay  #45475a
set $blue     #89b4fa
set $mauve    #cba6f7
set $red      #f38ba8
set $green    #a6e3a1
set $yellow   #f9e2af
set $peach    #fab387
set $teal     #94e2d5
set $pink     #f5c2e7

# ── Window colors ───────────────────────────────────────────────
#                       border   bg       text     indicator child_border
client.focused          $blue    $base    $text    $teal     $blue
client.focused_inactive $surface $base    $subtext $overlay  $surface
client.unfocused        $surface $base    $subtext $overlay  $surface
client.urgent           $red     $base    $text    $red      $red

# ── Borders & Gaps ──────────────────────────────────────────────
default_border pixel 2
default_floating_border pixel 2
hide_edge_borders smart
gaps inner 8
gaps outer 4
smart_gaps on

# ── Autostart ───────────────────────────────────────────────────
exec --no-startup-id dex --autostart --environment i3
exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork
exec --no-startup-id nm-applet
exec --no-startup-id picom --config ~/.config/picom/picom.conf -b
exec --no-startup-id dunst
exec --no-startup-id numlockx on
exec --no-startup-id ~/.config/polybar/launch.sh
exec_always --no-startup-id nitrogen --restore
exec_always --no-startup-id feh --bg-scale ~/Pictures/Wallpapers/wallpaper.jpg 2>/dev/null || true

# ── Applications ────────────────────────────────────────────────
set $terminal   alacritty
set $filemanager thunar
set $browser    firefox
set $launcher   rofi -show drun -theme ~/.config/rofi/launcher.rasi

bindsym $mod+Return       exec $terminal
bindsym $mod+e            exec $filemanager
bindsym $mod+b            exec $browser
bindsym $mod+d            exec $launcher
bindsym $mod+Shift+d      exec rofi -show run

# ── Screenshot ──────────────────────────────────────────────────
bindsym Print             exec scrot '%Y-%m-%d_%H-%M-%S.png' -e 'mv $f ~/Pictures/' && notify-send "Screenshot" "Saved to ~/Pictures"
bindsym $mod+Print        exec scrot -s '%Y-%m-%d_%H-%M-%S.png' -e 'mv $f ~/Pictures/' && notify-send "Screenshot" "Region saved"
bindsym $mod+Shift+Print  exec scrot -u '%Y-%m-%d_%H-%M-%S.png' -e 'mv $f ~/Pictures/' && notify-send "Screenshot" "Window saved"

# ── Media Keys ──────────────────────────────────────────────────
bindsym XF86AudioRaiseVolume  exec --no-startup-id pamixer -i 5 && notify-send -h int:value:"$(pamixer --get-volume)" "Volume"
bindsym XF86AudioLowerVolume  exec --no-startup-id pamixer -d 5 && notify-send -h int:value:"$(pamixer --get-volume)" "Volume"
bindsym XF86AudioMute         exec --no-startup-id pamixer -t && notify-send "Volume" "Toggled mute"
bindsym XF86AudioPlay         exec --no-startup-id playerctl play-pause
bindsym XF86AudioNext         exec --no-startup-id playerctl next
bindsym XF86AudioPrev         exec --no-startup-id playerctl previous

# ── Brightness ──────────────────────────────────────────────────
bindsym XF86MonBrightnessUp   exec --no-startup-id brightnessctl set +5% && notify-send -h int:value:"$(brightnessctl get)" "Brightness"
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 5%- && notify-send -h int:value:"$(brightnessctl get)" "Brightness"

# ── Window Management ───────────────────────────────────────────
bindsym $mod+q        kill
bindsym $mod+f        fullscreen toggle
bindsym $mod+Shift+f  floating toggle
bindsym $mod+space    focus mode_toggle

# Focus
bindsym $mod+$left  focus left
bindsym $mod+$down  focus down
bindsym $mod+$up    focus up
bindsym $mod+$right focus right
bindsym $mod+Left   focus left
bindsym $mod+Down   focus down
bindsym $mod+Up     focus up
bindsym $mod+Right  focus right

# Move
bindsym $mod+Shift+$left  move left
bindsym $mod+Shift+$down  move down
bindsym $mod+Shift+$up    move up
bindsym $mod+Shift+$right move right
bindsym $mod+Shift+Left   move left
bindsym $mod+Shift+Down   move down
bindsym $mod+Shift+Up     move up
bindsym $mod+Shift+Right  move right

# Split
bindsym $mod+backslash  split h
bindsym $mod+minus      split v

# Layout
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+t layout toggle split

# Floating resize/move
floating_modifier $mod

# ── Workspaces ──────────────────────────────────────────────────
set $ws1  "1 "
set $ws2  "2 "
set $ws3  "3 "
set $ws4  "4 "
set $ws5  "5 "
set $ws6  "6 "
set $ws7  "7 "
set $ws8  "8 "
set $ws9  "9 "
set $ws10 "10 "

bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10

bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

# Auto-assign apps to workspaces
assign [class="firefox"]          $ws2
assign [class="Thunar"]           $ws3
assign [class="Code"]             $ws4
assign [class="Spotify"]          $ws9
assign [class="discord"]          $ws10
assign [class="TelegramDesktop"]  $ws10

# Floating rules
for_window [class="Pavucontrol"]   floating enable, resize set 700 450
for_window [class="Arandr"]        floating enable
for_window [class="lxappearance"]  floating enable
for_window [class="qt5ct"]         floating enable
for_window [class="Nm-connection-editor"] floating enable
for_window [window_role="pop-up"]  floating enable
for_window [window_role="bubble"]  floating enable

# ── i3 System ───────────────────────────────────────────────────
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart

# ── Scratchpad ──────────────────────────────────────────────────
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+grave       scratchpad show

# ── Resize Mode ─────────────────────────────────────────────────
mode "resize" {
    bindsym h resize shrink width  10 px or 10 ppt
    bindsym j resize grow   height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow   width  10 px or 10 ppt
    bindsym Left  resize shrink width  10 px or 10 ppt
    bindsym Down  resize grow   height 10 px or 10 ppt
    bindsym Up    resize shrink height 10 px or 10 ppt
    bindsym Right resize grow   width  10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}
bindsym $mod+r mode "resize"

# ── Power Menu Mode ─────────────────────────────────────────────
set $mode_system (l)ock  (e)xit  (r)eboot  (s)hutdown  (h)ibernate
mode "$mode_system" {
    bindsym l exec --no-startup-id betterlockscreen -l, mode "default"
    bindsym e exec --no-startup-id i3-msg exit,       mode "default"
    bindsym r exec --no-startup-id systemctl reboot,  mode "default"
    bindsym s exec --no-startup-id systemctl poweroff, mode "default"
    bindsym h exec --no-startup-id systemctl hibernate, mode "default"
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+Escape mode "$mode_system"

# ── Gaps Mode ───────────────────────────────────────────────────
set $mode_gaps Gaps: (i)nner (o)uter  +/- to adjust
mode "$mode_gaps" {
    bindsym i mode "$mode_gaps_inner"
    bindsym o mode "$mode_gaps_outer"
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
set $mode_gaps_inner Inner: +/- (local)  shift+/- (global)
mode "$mode_gaps_inner" {
    bindsym plus  gaps inner current plus  4
    bindsym minus gaps inner current minus 4
    bindsym Shift+plus  gaps inner all plus  4
    bindsym Shift+minus gaps inner all minus 4
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
set $mode_gaps_outer Outer: +/- (local)  shift+/- (global)
mode "$mode_gaps_outer" {
    bindsym plus  gaps outer current plus  4
    bindsym minus gaps outer current minus 4
    bindsym Shift+plus  gaps outer all plus  4
    bindsym Shift+minus gaps outer all minus 4
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+g mode "$mode_gaps"

# ── Bar (polybar) ────────────────────────────────────────────────
# polybar được khởi động qua exec ở trên
# Ẩn thanh i3bar mặc định
# bar { ... }
ENDOFCONFIG
    success "i3 config đã được tạo"
}

# ── Picom config ─────────────────────────────────────────────
write_picom_config() {
    step "Viết Picom config"
    cat > "$PICOM_DIR/picom.conf" << 'EOF'
# ================================================================
#  Picom Config — Catppuccin Mocha
# ================================================================

backend = "glx";
vsync = true;
glx-no-stencil = true;
glx-copy-from-front = false;
use-damage = true;

# ── Shadows ──────────────────────────────────────────────────────
shadow = true;
shadow-radius = 12;
shadow-opacity = 0.75;
shadow-offset-x = -12;
shadow-offset-y = -12;
shadow-color = "#000000";
shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Conky'",
    "class_g ?= 'Notify-osd'",
    "_GTK_FRAME_EXTENTS@:c",
    "class_g = 'i3-frame'"
];

# ── Fading ───────────────────────────────────────────────────────
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-delta = 5;
no-fading-openclose = false;

# ── Transparency ─────────────────────────────────────────────────
inactive-opacity = 0.92;
active-opacity = 1.0;
frame-opacity = 1.0;
inactive-opacity-override = false;
opacity-rule = [
    "100:class_g = 'firefox'",
    "100:class_g = 'mpv'",
    "100:fullscreen",
    "90:class_g = 'Alacritty' && !focused",
    "100:class_g = 'Alacritty' && focused"
];

# ── Blur ──────────────────────────────────────────────────────────
blur-method = "dual_kawase";
blur-strength = 5;
blur-background = true;
blur-background-frame = false;
blur-background-fixed = false;
blur-background-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'",
    "_GTK_FRAME_EXTENTS@:c"
];

# ── Corners ───────────────────────────────────────────────────────
corner-radius = 8;
rounded-corners-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'"
];

# ── Window type ───────────────────────────────────────────────────
wintypes:
{
    tooltip      = { fade = true; shadow = true; opacity = 0.9; focus = true; full-shadow = false; };
    dock         = { shadow = false; clip-shadow-above = true; };
    dnd          = { shadow = false; };
    popup_menu   = { opacity = 0.95; };
    dropdown_menu = { opacity = 0.95; };
};
EOF
    success "Picom config đã được tạo"
}

# ── Polybar config ───────────────────────────────────────────
write_polybar_config() {
    step "Viết Polybar config"

    cat > "$POLYBAR_DIR/launch.sh" << 'EOF'
#!/bin/bash
# Kill existing polybar
killall -q polybar
while pgrep -u $UID -x polybar > /dev/null; do sleep 0.5; done

# Launch on all monitors
if type "xrandr" > /dev/null; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar --reload main &
    done
else
    polybar --reload main &
fi
EOF
    chmod +x "$POLYBAR_DIR/launch.sh"

    cat > "$POLYBAR_DIR/config.ini" << 'EOF'
; ================================================================
;  Polybar Config — Catppuccin Mocha
;  Inspired by VuNguyenCoder
; ================================================================

[color]
base     = #1e1e2e
mantle   = #181825
crust    = #11111b
text     = #cdd6f4
subtext  = #bac2de
surface  = #313244
overlay  = #45475a
blue     = #89b4fa
mauve    = #cba6f7
red      = #f38ba8
green    = #a6e3a1
yellow   = #f9e2af
peach    = #fab387
teal     = #94e2d5
sky      = #89dceb
pink     = #f5c2e7
transparent = #00000000

; ─────────────────────────────────────────
[bar/main]
monitor             = ${env:MONITOR:}
width               = 100%
height              = 32
offset-x            = 0
offset-y            = 0
radius              = 0
fixed-center        = true

background          = ${color.base}
foreground          = ${color.text}

line-size           = 2
line-color          = ${color.blue}

border-bottom-size  = 2
border-bottom-color = ${color.surface}

padding-left        = 2
padding-right       = 2
module-margin-left  = 1
module-margin-right = 1

font-0              = JetBrainsMono Nerd Font:style=Bold:size=10;3
font-1              = Font Awesome 6 Free:style=Solid:size=10;3
font-2              = Noto Color Emoji:style=Regular:size=10;3

modules-left   = i3 xwindow
modules-center = date
modules-right  = pulseaudio network cpu memory battery

tray-position  = right
tray-padding   = 4
tray-background = ${color.base}

cursor-click   = pointer
cursor-scroll  = ns-resize
enable-ipc     = true

; ─────────────────────────────────────────
[module/i3]
type             = internal/i3
format           = <label-state> <label-mode>
index-sort       = true
wrapping-scroll  = false
strip-wsnumbers  = true
pin-workspaces   = true

label-mode-padding    = 2
label-mode-foreground = ${color.text}
label-mode-background = ${color.mauve}

label-focused            = %icon%
label-focused-foreground = ${color.blue}
label-focused-background = ${color.surface}
label-focused-underline  = ${color.blue}
label-focused-padding    = 2

label-unfocused            = %icon%
label-unfocused-foreground = ${color.subtext}
label-unfocused-padding    = 2

label-visible            = %icon%
label-visible-foreground = ${color.teal}
label-visible-underline  = ${color.teal}
label-visible-padding    = 2

label-urgent            = %icon%
label-urgent-foreground = ${color.red}
label-urgent-background = ${color.crust}
label-urgent-underline  = ${color.red}
label-urgent-padding    = 2

ws-icon-0  = 1;
ws-icon-1  = 2;
ws-icon-2  = 3;
ws-icon-3  = 4;
ws-icon-4  = 5;
ws-icon-5  = 6;
ws-icon-6  = 7;
ws-icon-7  = 8;
ws-icon-8  = 9;
ws-icon-9  = 10;

; ─────────────────────────────────────────
[module/xwindow]
type             = internal/xwindow
label            = %title:0:60:...%
label-foreground = ${color.subtext}

; ─────────────────────────────────────────
[module/date]
type             = internal/date
interval         = 1
date             =
time             = %H:%M:%S
date-alt         = %A, %d %b %Y
time-alt         = %H:%M:%S
label            =  %date%  %time%
label-foreground = ${color.blue}

; ─────────────────────────────────────────
[module/pulseaudio]
type             = internal/pulseaudio
format-volume    = <ramp-volume> <label-volume>
label-volume     = %percentage%%
label-muted      =  muted
label-muted-foreground = ${color.overlay}
ramp-volume-0    = 
ramp-volume-1    = 
ramp-volume-2    = 
ramp-volume-foreground = ${color.green}

click-right = pavucontrol &

; ─────────────────────────────────────────
[module/network]
type              = internal/network
interface-type    = wireless
interval          = 3
format-connected  = <ramp-signal>  <label-connected>
label-connected   = %essid% %downspeed:8%
label-disconnected      = 睊 disconnected
label-disconnected-foreground = ${color.red}
ramp-signal-0    = 
ramp-signal-1    = 
ramp-signal-2    = 
ramp-signal-3    = 
ramp-signal-4    = 
ramp-signal-foreground = ${color.teal}

; ─────────────────────────────────────────
[module/cpu]
type             = internal/cpu
interval         = 2
format-prefix    = " "
format-prefix-foreground = ${color.peach}
label            = %percentage:2%%

; ─────────────────────────────────────────
[module/memory]
type             = internal/memory
interval         = 2
format-prefix    = " "
format-prefix-foreground = ${color.mauve}
label            = %percentage_used:2%%

; ─────────────────────────────────────────
[module/battery]
type             = internal/battery
battery          = BAT0
adapter          = AC
full-at          = 98
low-at           = 15
format-charging  = <animation-charging> <label-charging>
format-discharging = <ramp-capacity> <label-discharging>
format-full      =  Full
label-charging   = %percentage%%
label-discharging = %percentage%%

ramp-capacity-0  = 
ramp-capacity-1  = 
ramp-capacity-2  = 
ramp-capacity-3  = 
ramp-capacity-4  = 
ramp-capacity-foreground = ${color.yellow}

animation-charging-0 = 
animation-charging-1 = 
animation-charging-2 = 
animation-charging-3 = 
animation-charging-4 = 
animation-charging-foreground = ${color.green}
animation-charging-framerate = 750

; ─────────────────────────────────────────
[global/wm]
margin-top    = 0
margin-bottom = 0
EOF
    success "Polybar config đã được tạo"
}

# ── Rofi config ──────────────────────────────────────────────
write_rofi_config() {
    step "Viết Rofi config"
    cat > "$ROFI_DIR/launcher.rasi" << 'EOF'
/* ================================================================
   Rofi Launcher — Catppuccin Mocha
   Inspired by VuNguyenCoder
================================================================ */

* {
    base:         #1e1e2e;
    mantle:       #181825;
    crust:        #11111b;
    text:         #cdd6f4;
    subtext:      #bac2de;
    surface:      #313244;
    overlay:      #45475a;
    blue:         #89b4fa;
    mauve:        #cba6f7;
    red:          #f38ba8;
    green:        #a6e3a1;
    yellow:       #f9e2af;
    peach:        #fab387;

    background-color:  transparent;
    text-color:        @text;
    font:              "JetBrainsMono Nerd Font Bold 12";
    border:            0;
    margin:            0;
    padding:           0;
    spacing:           0;
}

window {
    width:            500px;
    background-color: @base;
    border:           2px;
    border-color:     @blue;
    border-radius:    10px;
}

mainbox {
    background-color: transparent;
    children:         [ inputbar, message, listview ];
}

inputbar {
    background-color: @mantle;
    border-radius:    10px 10px 0 0;
    padding:          12px 16px;
    children:         [ prompt, entry ];
}

prompt {
    background-color: @blue;
    text-color:       @crust;
    padding:          4px 10px;
    border-radius:    6px;
    margin:           0 8px 0 0;
}

entry {
    background-color: transparent;
    text-color:       @text;
    placeholder:      "Search...";
    placeholder-color: @overlay;
    cursor:           text;
}

listview {
    background-color: transparent;
    padding:          8px;
    columns:          1;
    lines:            8;
    scrollbar:        false;
}

element {
    background-color: transparent;
    text-color:       @subtext;
    border-radius:    6px;
    padding:          8px 12px;
    spacing:          8px;
    children:         [ element-icon, element-text ];
}

element selected {
    background-color: @surface;
    text-color:       @text;
}

element-icon {
    size:             24px;
    vertical-align:   0.5;
}

element-text {
    vertical-align:   0.5;
    text-color:       inherit;
}

message {
    padding:          8px 16px;
}

textbox {
    background-color: transparent;
    text-color:       @yellow;
}
EOF
    success "Rofi config đã được tạo"
}

# ── Dunst config ─────────────────────────────────────────────
write_dunst_config() {
    step "Viết Dunst config"
    cat > "$DUNST_DIR/dunstrc" << 'EOF'
[global]
    monitor          = 0
    follow           = mouse
    width            = 320
    height           = 100
    origin           = top-right
    offset           = 12x48
    scale            = 0
    notification_limit = 5
    progress_bar     = true
    progress_bar_height = 6
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    indicate_hidden  = yes
    transparency     = 0
    separator_height = 2
    padding          = 12
    horizontal_padding = 12
    text_icon_padding = 0
    frame_width      = 2
    frame_color      = "#89b4fa"
    separator_color  = frame
    sort             = yes
    idle_threshold   = 120
    font             = JetBrainsMono Nerd Font 10
    line_height      = 0
    markup           = full
    format           = "<b>%s</b>\n%b"
    alignment        = left
    vertical_alignment = center
    show_age_threshold = 60
    word_wrap        = yes
    ellipsize        = middle
    ignore_newline   = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators  = yes
    icon_path        = /usr/share/icons/Papirus-Dark/16x16/status/:/usr/share/icons/Papirus-Dark/16x16/devices/
    icon_position    = left
    min_icon_size    = 0
    max_icon_size    = 32
    sticky_history   = yes
    history_length   = 20
    browser          = /usr/bin/xdg-open
    always_run_script = true
    title            = Dunst
    class            = Dunst
    corner_radius    = 8
    ignore_dbusclose = false
    force_xinerama   = false
    mouse_left_click  = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#313244"
    timeout    = 4
    icon       = dialog-information

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#89b4fa"
    timeout    = 6
    icon       = dialog-information

[urgency_critical]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#f38ba8"
    timeout    = 0
    icon       = dialog-error
EOF
    success "Dunst config đã được tạo"
}

# ── Alacritty config ─────────────────────────────────────────
write_alacritty_config() {
    step "Viết Alacritty config"
    cat > "$ALACRITTY_DIR/alacritty.toml" << 'EOF'
# ================================================================
#  Alacritty Config — Catppuccin Mocha
#  Inspired by VuNguyenCoder
# ================================================================

[window]
padding.x   = 12
padding.y   = 12
decorations = "none"
opacity     = 0.92
blur        = true
startup_mode = "Windowed"
title       = "Alacritty"
dynamic_title = true

[font]
normal   = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold     = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic   = { family = "JetBrainsMono Nerd Font", style = "Italic" }
size     = 12.0

[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"
dim_foreground    = "#7f849c"
bright_foreground = "#cdd6f4"

[colors.cursor]
text   = "#1e1e2e"
cursor = "#f5e0dc"

[colors.vi_mode_cursor]
text   = "#1e1e2e"
cursor = "#b4befe"

[colors.search.matches]
foreground = "#1e1e2e"
background = "#a6adc8"

[colors.search.focused_match]
foreground = "#1e1e2e"
background = "#a6e3a1"

[colors.footer_bar]
background = "#181825"
foreground = "#cdd6f4"

[colors.hints.start]
foreground = "#1e1e2e"
background = "#f9e2af"

[colors.hints.end]
foreground = "#1e1e2e"
background = "#a6adc8"

[colors.selection]
text       = "#1e1e2e"
background = "#f5e0dc"

[colors.normal]
black   = "#45475a"
red     = "#f38ba8"
green   = "#a6e3a1"
yellow  = "#f9e2af"
blue    = "#89b4fa"
magenta = "#f5c2e7"
cyan    = "#94e2d5"
white   = "#bac2de"

[colors.bright]
black   = "#585b70"
red     = "#f38ba8"
green   = "#a6e3a1"
yellow  = "#f9e2af"
blue    = "#89b4fa"
magenta = "#f5c2e7"
cyan    = "#94e2d5"
white   = "#a6adc8"

[colors.dim]
black   = "#45475a"
red     = "#f38ba8"
green   = "#a6e3a1"
yellow  = "#f9e2af"
blue    = "#89b4fa"
magenta = "#f5c2e7"
cyan    = "#94e2d5"
white   = "#bac2de"

[cursor]
style.shape   = "Block"
style.blinking = "On"
blink_interval = 750
unfocused_hollow = true
thickness   = 0.15

[scrolling]
history    = 10000
multiplier = 3

[selection]
save_to_clipboard = true

[terminal]
osc52 = "CopyPaste"

[[keyboard.bindings]]
key   = "V"
mods  = "Control|Shift"
action = "Paste"

[[keyboard.bindings]]
key   = "C"
mods  = "Control|Shift"
action = "Copy"

[[keyboard.bindings]]
key   = "Plus"
mods  = "Control"
action = "IncreaseFontSize"

[[keyboard.bindings]]
key   = "Minus"
mods  = "Control"
action = "DecreaseFontSize"

[[keyboard.bindings]]
key   = "Key0"
mods  = "Control"
action = "ResetFontSize"
EOF
    success "Alacritty config đã được tạo"
}

# ── .xinitrc ─────────────────────────────────────────────────
write_xinitrc() {
    step "Viết .xinitrc"
    cat > "$HOME/.xinitrc" << 'EOF'
#!/bin/bash
# .xinitrc — i3 startup

# Fix cursor
xsetroot -cursor_name left_ptr

# Set keyboard repeat
xset r rate 300 50

# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Load Xresources
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# Start i3
exec i3
EOF
    success ".xinitrc đã được tạo"
}

# ── GTK / Qt theme ───────────────────────────────────────────
write_gtk_config() {
    step "Cấu hình GTK & Qt theme"
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

    cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Blue-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=1
EOF

    cat > "$HOME/.config/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Blue-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=1
EOF

    # Qt5
    mkdir -p "$HOME/.config/qt5ct"
    cat > "$HOME/.config/qt5ct/qt5ct.conf" << 'EOF'
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/darker.conf
custom_palette=false
icon_theme=Papirus-Dark
standard_dialogs=default
style=Fusion

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x16\0J\0\x65\0t\0\x42\0r\0\x61\0i\0n\0s\0M\0o\0n\0o@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x12\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
EOF

    # Xresources
    cat > "$HOME/.Xresources" << 'EOF'
! Catppuccin Mocha
*.background:  #1e1e2e
*.foreground:  #cdd6f4
*.cursorColor: #f5e0dc
*.color0:  #45475a
*.color1:  #f38ba8
*.color2:  #a6e3a1
*.color3:  #f9e2af
*.color4:  #89b4fa
*.color5:  #f5c2e7
*.color6:  #94e2d5
*.color7:  #bac2de
*.color8:  #585b70
*.color9:  #f38ba8
*.color10: #a6e3a1
*.color11: #f9e2af
*.color12: #89b4fa
*.color13: #f5c2e7
*.color14: #94e2d5
*.color15: #a6adc8
Xcursor.theme: Bibata-Modern-Classic
Xcursor.size:  24
EOF
    success "GTK / Qt / Xresources config đã được tạo"
}

# ── i3 scripts ────────────────────────────────────────────────
write_scripts() {
    step "Viết helper scripts"

    # Lockscreen
    cat > "$I3_DIR/scripts/lock.sh" << 'EOF'
#!/bin/bash
betterlockscreen -l blur --text "  Nhập mật khẩu..." 2>/dev/null || \
    i3lock -c 1e1e2e --nofork
EOF
    chmod +x "$I3_DIR/scripts/lock.sh"

    # Power menu
    cat > "$I3_DIR/scripts/powermenu.sh" << 'EOF'
#!/bin/bash
options=" Lock\n Logout\n Reboot\n Shutdown\n Hibernate"
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power" \
    -theme ~/.config/rofi/launcher.rasi)
case "$chosen" in
    " Lock")      ~/.config/i3/scripts/lock.sh ;;
    " Logout")    i3-msg exit ;;
    " Reboot")    systemctl reboot ;;
    " Shutdown")  systemctl poweroff ;;
    " Hibernate") systemctl hibernate ;;
esac
EOF
    chmod +x "$I3_DIR/scripts/powermenu.sh"

    # Wallpaper changer
    cat > "$I3_DIR/scripts/wallpaper.sh" << 'EOF'
#!/bin/bash
WALL_DIR="$HOME/Pictures/Wallpapers"
if [[ ! -d "$WALL_DIR" ]] || [[ -z "$(ls -A $WALL_DIR 2>/dev/null)" ]]; then
    notify-send "Wallpaper" "Không tìm thấy ảnh trong $WALL_DIR"
    exit 1
fi
wall=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n1)
feh --bg-scale "$wall"
notify-send "Wallpaper" "$(basename "$wall")"
EOF
    chmod +x "$I3_DIR/scripts/wallpaper.sh"

    # Autorandr / multi-monitor
    cat > "$I3_DIR/scripts/display.sh" << 'EOF'
#!/bin/bash
# Auto detect và cấu hình màn hình
if command -v autorandr &>/dev/null; then
    autorandr --change
else
    arandr &
fi
EOF
    chmod +x "$I3_DIR/scripts/display.sh"

    success "Scripts đã được tạo"
}

# ════════════════════════════════════════════════════════════
#  SERVICES
# ════════════════════════════════════════════════════════════
enable_services() {
    step "Kích hoạt dịch vụ hệ thống"
    local services=(NetworkManager pulseaudio)
    for svc in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "$svc"; then
            sudo systemctl enable --now "$svc" 2>/dev/null && success "Enabled: $svc" || warn "Không enable được: $svc"
        fi
    done
}

# ════════════════════════════════════════════════════════════
#  POST INSTALL
# ════════════════════════════════════════════════════════════
post_install() {
    step "Hoàn thiện cài đặt"

    # Refresh font cache
    fc-cache -fv &>/dev/null && success "Font cache đã được làm mới"

    # Update Xresources
    [[ -f "$HOME/.Xresources" ]] && xrdb -merge "$HOME/.Xresources" 2>/dev/null

    # Betterlockscreen cache
    if command -v betterlockscreen &>/dev/null; then
        if ls "$WALLPAPER_DIR"/*.{jpg,png,jpeg} &>/dev/null 2>&1; then
            betterlockscreen -u "$WALLPAPER_DIR" --blur 0.5 &
            info "Betterlockscreen đang cache wallpaper..."
        fi
    fi
}

# ════════════════════════════════════════════════════════════
#  SUMMARY
# ════════════════════════════════════════════════════════════
show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║      Cài đặt hoàn tất! What's next?         ║"
    echo "  ╠══════════════════════════════════════════════╣"
    echo "  ║                                              ║"
    echo "  ║  1. Thêm wallpaper vào ~/Pictures/Wallpapers ║"
    echo "  ║  2. Chạy: startx (từ TTY)                   ║"
    echo "  ║     hoặc đăng nhập qua Display Manager       ║"
    echo "  ║                                              ║"
    echo "  ║  Phím tắt quan trọng:                        ║"
    echo "  ║  Super+Enter   → Alacritty                   ║"
    echo "  ║  Super+d       → Rofi launcher               ║"
    echo "  ║  Super+Shift+q → Thoát i3                    ║"
    echo "  ║  Super+Escape  → Power menu                  ║"
    echo "  ║  Super+r       → Resize mode                 ║"
    echo "  ║  Super+g       → Gaps mode                   ║"
    echo "  ║                                              ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════
main() {
    show_banner
    check_root
    check_arch
    check_aur_helper

    echo -e "${BOLD}Bắt đầu cài đặt i3 cho Arch Linux${RESET}"
    echo -e "${CYAN}Sử dụng theme: Catppuccin Mocha${RESET}\n"

    # Bước 1: Update
    system_update

    # Bước 2: Kiểm tra cài đặt cũ
    detect_existing

    # Bước 3: AUR helper
    install_aur_helper

    # Bước 4: Packages
    install_packages

    # Bước 5: Tạo thư mục
    create_dirs

    # Bước 6: Viết configs
    write_i3_config
    write_picom_config
    write_polybar_config
    write_rofi_config
    write_dunst_config
    write_alacritty_config
    write_xinitrc
    write_gtk_config
    write_scripts

    # Bước 7: Services
    enable_services

    # Bước 8: Post install
    post_install

    # Xong
    show_summary
}

main "$@"
