#!/usr/bin/env bash
# =============================================================================
# install_desktop.sh - Cài môi trường desktop sau khi boot vào Arch mới
# =============================================================================
# Tác giả: Arch Linux Setup Project
# Mô tả : Cài i3 (X11) + Niri (Wayland) + greetd display manager
#          Niri setup theo phong cách CachyOS
# Yêu cầu: Arch Linux đã cài base, boot vào hệ thống, có internet
# Chạy  : Với tư cách USER thường (không phải root)
#          Script sẽ tự dùng sudo khi cần
# =============================================================================

set -euo pipefail

# ─── Màu sắc log ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Hàm log ─────────────────────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
log_step()    { echo -e "\n${CYAN}${BOLD}==> $*${RESET}"; }
log_skip()    { echo -e "${MAGENTA}[SKIP]${RESET}  $*"; }
log_divider() { echo -e "${BLUE}────────────────────────────────────────────────────${RESET}"; }

# ─── Biến toàn cục ───────────────────────────────────────────────────────────
SCRIPT_USER="${SUDO_USER:-$USER}"
HOME_DIR=$(eval echo "~$SCRIPT_USER")
CONFIG_DIR="$HOME_DIR/.config"
FAILED_PKGS=()   # Lưu danh sách package cài thất bại để báo cáo cuối

# ─── Kiểm tra quyền: KHÔNG chạy trực tiếp với root ───────────────────────────
check_user() {
    if [[ $EUID -eq 0 ]] && [[ -z "${SUDO_USER:-}" ]]; then
        log_error "Đừng chạy script này trực tiếp với root!"
        log_warn "Hãy chạy với user thường: ./install_desktop.sh"
        log_warn "Script sẽ tự dùng sudo khi cần thiết"
        exit 1
    fi

    log_ok "Chạy với user: $SCRIPT_USER (home: $HOME_DIR)"

    # Kiểm tra sudo có sẵn
    if ! command -v sudo &>/dev/null; then
        log_error "Lệnh 'sudo' không tìm thấy. Hãy cài sudo và thêm user vào group wheel"
        exit 1
    fi
}

# ─── Kiểm tra internet ───────────────────────────────────────────────────────
check_internet() {
    log_step "Kiểm tra kết nối internet"
    if ! ping -c 1 -W 5 archlinux.org &>/dev/null; then
        log_error "Không có kết nối internet!"
        log_warn "Hãy kết nối mạng trước khi chạy script này"
        log_info "Gợi ý: sudo systemctl start NetworkManager && nmtui"
        exit 1
    fi
    log_ok "Kết nối internet OK"
}

# ─── Cập nhật hệ thống ───────────────────────────────────────────────────────
update_system() {
    log_step "Cập nhật hệ thống"
    sudo pacman -Syu --noconfirm
    log_ok "Hệ thống đã được cập nhật"
}

# ─── Hàm cài package an toàn (bỏ qua nếu không có trong repo) ────────────────
safe_install() {
    local pkgs=("$@")
    local available=()
    local unavailable=()

    for pkg in "${pkgs[@]}"; do
        if pacman -Si "$pkg" &>/dev/null; then
            available+=("$pkg")
        else
            unavailable+=("$pkg")
            FAILED_PKGS+=("$pkg")
        fi
    done

    if [[ ${#unavailable[@]} -gt 0 ]]; then
        log_skip "Không tìm thấy trong repo chính: ${unavailable[*]}"
    fi

    if [[ ${#available[@]} -gt 0 ]]; then
        sudo pacman -S --needed --noconfirm "${available[@]}"
    fi
}

# ─── Cài các package hệ thống cơ bản ─────────────────────────────────────────
install_base_packages() {
    log_step "Cài packages cơ bản"

    safe_install \
        base-devel \
        git \
        curl \
        wget \
        networkmanager \
        network-manager-applet \
        bluez \
        bluez-utils \
        pipewire \
        pipewire-alsa \
        pipewire-pulse \
        pipewire-jack \
        wireplumber \
        xdg-utils \
        xdg-user-dirs \
        polkit \
        polkit-gnome \
        glib2 \
        dbus \
        udiskie \
        udisks2 \
        ntfs-3g \
        zip unzip \
        htop \
        man-db

    # Enable NetworkManager
    sudo systemctl enable --now NetworkManager
    log_ok "NetworkManager enabled"
}

# ─── Cài X11 dependencies cho i3 ─────────────────────────────────────────────
install_x11() {
    log_step "Cài X11 / Xorg cho i3"

    safe_install \
        xorg-server \
        xorg-xinit \
        xorg-xrandr \
        xorg-xset \
        xorg-xprop \
        xorg-xinput \
        xf86-video-vesa \
        mesa
        # Driver GPU: Thêm xf86-video-intel / xf86-video-amdgpu / nvidia tùy phần cứng

    log_ok "X11 packages đã cài"
}

# ─── Cài i3 Window Manager ────────────────────────────────────────────────────
install_i3() {
    log_step "Cài i3 Window Manager (X11)"

    safe_install \
        i3-wm \
        i3status \
        i3lock \
        dmenu \
        rofi \
        dunst \
        picom \
        feh \
        xss-lock \
        xclip \
        xdotool \
        lxappearance \
        arandr

    log_ok "i3 packages đã cài"
}

# ─── Cài Niri Wayland Compositor ─────────────────────────────────────────────
install_niri() {
    log_step "Cài Niri Wayland Compositor"

    # Niri có trong Arch extra repo từ 2024
    safe_install \
        niri

    # Wayland utilities
    safe_install \
        wayland \
        wayland-protocols \
        xwayland \
        wl-clipboard \
        wlr-randr

    log_ok "Niri đã cài"
}

# ─── Cài Wayland ecosystem (phong cách CachyOS) ───────────────────────────────
install_wayland_stack() {
    log_step "Cài Wayland stack (CachyOS style)"

    # Waybar - status bar cho Wayland
    safe_install waybar

    # Rofi Wayland fork hoặc wofi
    # rofi-wayland không có trong extra, dùng wofi thay thế
    safe_install wofi

    # Mako - notification daemon cho Wayland
    safe_install mako

    # Swaybg - wallpaper cho Wayland
    safe_install swaybg

    # Swaylock - screen locker Wayland
    safe_install swaylock

    # Swayidle - idle management
    safe_install swayidle

    # XDG Desktop Portal cho Wayland
    safe_install \
        xdg-desktop-portal \
        xdg-desktop-portal-gnome
        # NOTE: xdg-desktop-portal-wlr phù hợp hơn nhưng check repo

    # Clipboard Wayland
    safe_install wl-clipboard

    log_ok "Wayland stack đã cài"
}

# ─── Cài terminal và file manager ────────────────────────────────────────────
install_apps() {
    log_step "Cài terminal emulator và ứng dụng cơ bản"

    # Terminal (theo thứ tự ưu tiên)
    safe_install alacritty    # Terminal chính (niri/i3)
    safe_install kitty        # Backup terminal Wayland native

    # File manager
    safe_install thunar
    safe_install thunar-volman
    safe_install gvfs          # Virtual filesystem support

    # Text editor
    safe_install neovim
    safe_install gedit         # GUI fallback (có thể không có trong base)

    # Trình duyệt nhẹ
    safe_install firefox

    # Screenshot
    safe_install grim          # Wayland screenshot
    safe_install slurp         # Wayland region select
    safe_install flameshot     # X11 screenshot

    # Image viewer
    safe_install imv           # Wayland image viewer
    safe_install feh           # X11 image viewer

    # Ứng dụng khác
    safe_install pavucontrol   # PulseAudio volume control GUI
    safe_install brightnessctl # Brightness control

    log_ok "Ứng dụng đã cài"
}

# ─── Cài fonts ───────────────────────────────────────────────────────────────
install_fonts() {
    log_step "Cài fonts"

    safe_install \
        noto-fonts \
        noto-fonts-emoji \
        noto-fonts-cjk \
        ttf-fira-code \
        ttf-font-awesome \
        ttf-dejavu \
        ttf-liberation \
        otf-font-awesome

    # Refresh font cache
    sudo fc-cache -f
    log_ok "Fonts đã cài và cache đã refresh"
}

# ─── Cài greetd + tuigreet display manager ───────────────────────────────────
install_greetd() {
    log_step "Cài greetd + tuigreet (display manager)"

    safe_install greetd
    safe_install greetd-tuigreet

    log_ok "greetd và tuigreet đã cài"
}

# ─── Tạo cấu hình greetd ─────────────────────────────────────────────────────
configure_greetd() {
    log_step "Cấu hình greetd"

    # Tạo thư mục config nếu chưa có
    sudo mkdir -p /etc/greetd

    # Tạo danh sách session từ các .desktop files
    # greetd sẽ đọc từ /usr/share/wayland-sessions và /usr/share/xsessions

    sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
# greetd configuration
# Xem thêm: https://sr.ht/~kennylevinsen/greetd/

[terminal]
# VT số 1 dùng cho greetd
vt = 1

[default_session]
# Dùng tuigreet để hiển thị màn hình đăng nhập TUI
command = "tuigreet --time --remember --remember-session --sessions /usr/share/wayland-sessions:/usr/share/xsessions --greeting 'Chào mừng đến Arch Linux'"
user = "greeter"
EOF

    log_ok "Đã tạo /etc/greetd/config.toml"

    # Enable greetd service
    sudo systemctl enable greetd
    log_ok "greetd service đã được enable"

    # Tạo file session cho Niri nếu chưa có
    sudo mkdir -p /usr/share/wayland-sessions
    if [[ ! -f /usr/share/wayland-sessions/niri.desktop ]]; then
        sudo tee /usr/share/wayland-sessions/niri.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
EOF
        log_ok "Tạo niri.desktop session"
    fi

    # Tạo file session cho i3 nếu chưa có
    sudo mkdir -p /usr/share/xsessions
    if [[ ! -f /usr/share/xsessions/i3.desktop ]]; then
        sudo tee /usr/share/xsessions/i3.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=i3
Comment=Improved tiling window manager
Exec=i3
TryExec=i3
Type=Application
X-LightDM-DesktopName=i3
DesktopNames=i3
EOF
        log_ok "Tạo i3.desktop session"
    fi
}

# ─── Tạo cấu hình Niri ───────────────────────────────────────────────────────
create_niri_config() {
    log_step "Tạo cấu hình Niri (~/.config/niri/config.kdl)"

    local niri_dir="$CONFIG_DIR/niri"
    mkdir -p "$niri_dir"

    cat > "$niri_dir/config.kdl" << 'EOF'
// ============================================================
// Niri Configuration - CachyOS inspired
// Docs: https://github.com/YaLTeR/niri/wiki/Configuration
// ============================================================

// ── Inputs ──────────────────────────────────────────────────
input {
    keyboard {
        xkb {
            // Thay đổi layout phù hợp (us, vn, ...)
            layout "us"
        }
    }

    touchpad {
        tap                     // Tap để click
        natural-scroll          // Cuộn tự nhiên
        accel-speed 0.2
    }

    mouse {
        accel-speed 0.0
    }
}

// ── Outputs / Màn hình ───────────────────────────────────────
// Bỏ comment và chỉnh sửa theo tên output của bạn
// Dùng `niri msg outputs` để xem tên output
// output "eDP-1" {
//     scale 1.0
//     mode "1920x1080@60.000"
//     position x=0 y=0
// }

// ── Layout ──────────────────────────────────────────────────
layout {
    // Khoảng cách giữa các cửa sổ
    gaps 8

    // Border cửa sổ
    border {
        width 2
        active-color "#89b4fa"      // Catppuccin Mocha Blue
        inactive-color "#313244"    // Catppuccin Mocha Surface1
    }

    // Focus ring (highlight cửa sổ đang active)
    focus-ring {
        off
    }

    // Shadow
    shadow {
        on
    }

    // Preset column widths
    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
        proportion 1.0
    }

    // Kích thước cửa sổ mặc định
    default-column-width { proportion 0.5; }

    // Khu vực struts (giữ không gian cho bar)
    struts {
        top 0
        bottom 0
        left 0
        right 0
    }
}

// ── Appearance ───────────────────────────────────────────────
// Blur và hiệu ứng (nếu GPU hỗ trợ)
// prefer-no-csd  // Uncomment nếu muốn tắt client-side decorations

// ── Keybindings ──────────────────────────────────────────────
binds {
    // ── App launchers ──
    Mod+Return    { spawn "alacritty"; }
    Mod+D         { spawn "wofi" "--show" "run"; }
    Mod+E         { spawn "thunar"; }
    Mod+B         { spawn "firefox"; }

    // ── Screenshot ──
    Print         { screenshot; }
    Mod+Print     { screenshot-screen; }
    Mod+Shift+S   { screenshot-window; }

    // ── Điều khiển cửa sổ ──
    Mod+Q         { close-window; }
    Mod+F         { fullscreen-window; }
    Mod+Shift+F   { toggle-window-floating; }
    Mod+C         { center-window; }

    // ── Di chuyển focus ──
    Mod+H         { focus-column-left; }
    Mod+L         { focus-column-right; }
    Mod+J         { focus-window-down; }
    Mod+K         { focus-window-up; }
    Mod+Left      { focus-column-left; }
    Mod+Right     { focus-column-right; }
    Mod+Down      { focus-window-down; }
    Mod+Up        { focus-window-up; }

    // ── Di chuyển cửa sổ ──
    Mod+Shift+H   { move-column-left; }
    Mod+Shift+L   { move-column-right; }
    Mod+Shift+J   { move-window-down; }
    Mod+Shift+K   { move-window-up; }
    Mod+Shift+Left  { move-column-left; }
    Mod+Shift+Right { move-column-right; }
    Mod+Shift+Down  { move-window-down; }
    Mod+Shift+Up    { move-window-up; }

    // ── Workspaces ──
    Mod+1         { focus-workspace 1; }
    Mod+2         { focus-workspace 2; }
    Mod+3         { focus-workspace 3; }
    Mod+4         { focus-workspace 4; }
    Mod+5         { focus-workspace 5; }
    Mod+Shift+1   { move-window-to-workspace 1; }
    Mod+Shift+2   { move-window-to-workspace 2; }
    Mod+Shift+3   { move-window-to-workspace 3; }
    Mod+Shift+4   { move-window-to-workspace 4; }
    Mod+Shift+5   { move-window-to-workspace 5; }

    // ── Resize ──
    Mod+Minus     { set-column-width "-10%"; }
    Mod+Equal     { set-column-width "+10%"; }
    Mod+Shift+Minus { set-window-height "-10%"; }
    Mod+Shift+Equal { set-window-height "+10%"; }

    // ── Reload / Quit ──
    Mod+Shift+R   { reload-config; }
    Mod+Shift+Q   { quit; }

    // ── Volume ──
    XF86AudioRaiseVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
    XF86AudioLowerVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
    XF86AudioMute         allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }

    // ── Brightness ──
    XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "set" "10%+"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "10%-"; }
}

// ── Startup ──────────────────────────────────────────────────
spawn-at-startup "waybar"
spawn-at-startup "mako"
spawn-at-startup "swaybg" "-m" "fill" "-c" "#1e1e2e"  // Catppuccin Mocha base
// spawn-at-startup "swaybg" "-i" "/path/to/wallpaper.jpg"

// ── Window rules ─────────────────────────────────────────────
window-rule {
    match app-id="firefox"
    default-column-width { proportion 0.7; }
}

window-rule {
    match app-id="org.gnome.Nautilus"
    default-column-width { proportion 0.4; }
}

window-rule {
    match app-id="thunar"
    default-column-width { proportion 0.4; }
}

// Float một số ứng dụng
window-rule {
    match app-id="pavucontrol"
    open-floating true
    default-floating-position x=960 y=30
}

window-rule {
    match app-id="nm-connection-editor"
    open-floating true
}

// ── Environment variables cho Wayland ────────────────────────
environment {
    DISPLAY ":0"
    QT_QPA_PLATFORM "wayland"
    GDK_BACKEND "wayland,x11"
    CLUTTER_BACKEND "wayland"
    SDL_VIDEODRIVER "wayland"
    MOZ_ENABLE_WAYLAND "1"
    _JAVA_AWT_WM_NONREPARENTING "1"
    XDG_CURRENT_DESKTOP "niri"
    XDG_SESSION_TYPE "wayland"
    XDG_SESSION_DESKTOP "niri"
}
EOF

    # Đổi ownership về user
    chown -R "$SCRIPT_USER":"$SCRIPT_USER" "$niri_dir" 2>/dev/null || true
    log_ok "Đã tạo $niri_dir/config.kdl"
}

# ─── Tạo cấu hình i3 ─────────────────────────────────────────────────────────
create_i3_config() {
    log_step "Tạo cấu hình i3 (~/.config/i3/config)"

    local i3_dir="$CONFIG_DIR/i3"
    mkdir -p "$i3_dir"

    cat > "$i3_dir/config" << 'EOF'
# ============================================================
# i3 Configuration - Arch Linux Setup
# Tham khảo: https://i3wm.org/docs/userguide.html
# ============================================================

# ── Modifier key ──
# Mod4 = Super (Windows key)
# Mod1 = Alt
set $mod Mod4

# ── Font ──
font pango:FiraCode Nerd Font 10

# ── Terminal mặc định ──
set $term alacritty

# ── Launcher ──
set $menu rofi -show run

# ── Màu Catppuccin Mocha ──────────────────────────────────────
set $base     #1e1e2e
set $mantle   #181825
set $surface0 #313244
set $surface1 #45475a
set $text     #cdd6f4
set $blue     #89b4fa
set $lavender #b4befe
set $green    #a6e3a1
set $red      #f38ba8
set $yellow   #f9e2af
set $peach    #fab387

# ── Màu cửa sổ ──────────────────────────────────────────────
# class                 border    background  text      indicator child_border
client.focused          $blue     $base       $text     $blue     $blue
client.focused_inactive $surface1 $base       $text     $surface1 $surface1
client.unfocused        $surface0 $base       $text     $surface0 $surface0
client.urgent           $red      $base       $red      $red      $red

# ── Border ──
default_border pixel 2
default_floating_border pixel 2
hide_edge_borders smart

# ── Gaps (cần i3-gaps hoặc i3 >= 4.22) ──
gaps inner 8
gaps outer 4

# ── Font Awesome icons cho workspaces ──
set $ws1  "1: "
set $ws2  "2: "
set $ws3  "3: "
set $ws4  "4: "
set $ws5  "5: "
set $ws6  "6"
set $ws7  "7"
set $ws8  "8"
set $ws9  "9"
set $ws10 "10"

# ── Workspaces ──
bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9
bindsym $mod+0 workspace $ws10

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9
bindsym $mod+Shift+0 move container to workspace $ws10

# ── App launchers ──
bindsym $mod+Return exec $term
bindsym $mod+d exec $menu
bindsym $mod+e exec thunar
bindsym $mod+b exec firefox

# ── Điều khiển cửa sổ ──
bindsym $mod+q kill
bindsym $mod+f fullscreen toggle
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle

# ── Di chuyển focus ──
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right
bindsym $mod+Left  focus left
bindsym $mod+Down  focus down
bindsym $mod+Up    focus up
bindsym $mod+Right focus right

# ── Di chuyển cửa sổ ──
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right
bindsym $mod+Shift+Left  move left
bindsym $mod+Shift+Down  move down
bindsym $mod+Shift+Up    move up
bindsym $mod+Shift+Right move right

# ── Layout ──
bindsym $mod+ctrl+h split h
bindsym $mod+ctrl+v split v
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+t layout toggle split

# ── Resize mode ──
mode "resize" {
    bindsym h resize shrink width  5 px or 5 ppt
    bindsym l resize grow   width  5 px or 5 ppt
    bindsym k resize shrink height 5 px or 5 ppt
    bindsym j resize grow   height 5 px or 5 ppt
    bindsym Left  resize shrink width  5 px or 5 ppt
    bindsym Right resize grow   width  5 px or 5 ppt
    bindsym Up    resize shrink height 5 px or 5 ppt
    bindsym Down  resize grow   height 5 px or 5 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}
bindsym $mod+r mode "resize"

# ── Volume ──
bindsym XF86AudioRaiseVolume exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute        exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# ── Brightness ──
bindsym XF86MonBrightnessUp   exec --no-startup-id brightnessctl set 10%+
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 10%-

# ── Screenshot ──
bindsym Print       exec --no-startup-id flameshot full
bindsym Mod1+Print  exec --no-startup-id flameshot gui

# ── Lock screen ──
bindsym $mod+Shift+x exec --no-startup-id i3lock -c 1e1e2e

# ── i3 management ──
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+q exec "i3-nagbar -t warning -m 'Thoát i3?' -B 'Đồng ý' 'i3-msg exit'"

# ── Floating rules ──
for_window [class="Pavucontrol"] floating enable, resize set 600 400
for_window [class="Nm-connection-editor"] floating enable
for_window [class="Lxappearance"] floating enable
for_window [class="Arandr"] floating enable
for_window [window_role="dialog"] floating enable
for_window [window_role="pop-up"] floating enable

# ── Autostart ──
exec_always --no-startup-id dunst
exec_always --no-startup-id picom --config ~/.config/picom/picom.conf
exec --no-startup-id feh --bg-fill ~/.config/wallpaper.jpg 2>/dev/null || feh --bg-solid "#1e1e2e"
exec --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec --no-startup-id udiskie --tray

# ── Bar (i3status) ──
bar {
    status_command i3status --config ~/.config/i3/i3status.conf
    position top

    colors {
        background $base
        statusline $text
        separator  $surface1

        focused_workspace  $blue     $blue     $base
        active_workspace   $surface1 $surface1 $text
        inactive_workspace $base     $base     $text
        urgent_workspace   $red      $red      $base
    }
}
EOF

    # Tạo i3status config
    cat > "$i3_dir/i3status.conf" << 'EOF'
# i3status configuration
general {
    colors = true
    interval = 5
    color_good     = "#a6e3a1"
    color_degraded = "#f9e2af"
    color_bad      = "#f38ba8"
}

order += "wireless _first_"
order += "ethernet _first_"
order += "battery all"
order += "disk /"
order += "memory"
order += "cpu_usage"
order += "volume master"
order += "tztime local"

wireless _first_ {
    format_up   = " %essid %quality"
    format_down = " Mất kết nối"
}

ethernet _first_ {
    format_up   = " %ip"
    format_down = " Không có LAN"
}

battery all {
    format          = "%status %percentage %remaining"
    format_down     = "Không có pin"
    status_chr      = ""
    status_bat      = ""
    status_unk      = "?"
    status_full     = ""
    low_threshold   = 20
    threshold_type  = percentage
}

disk "/" {
    format = " %avail"
}

memory {
    format = " %used / %total"
    threshold_degraded = "1G"
    threshold_critical = "200M"
}

cpu_usage {
    format = " %usage"
    max_threshold = 75
    degraded_threshold = 25
}

volume master {
    format       = " %volume"
    format_muted = " Tắt"
    device       = "default"
    mixer        = "Master"
}

tztime local {
    format = " %d/%m/%Y %H:%M"
}
EOF

    chown -R "$SCRIPT_USER":"$SCRIPT_USER" "$i3_dir" 2>/dev/null || true
    log_ok "Đã tạo $i3_dir/config và i3status.conf"
}

# ─── Tạo cấu hình Waybar ─────────────────────────────────────────────────────
create_waybar_config() {
    log_step "Tạo cấu hình Waybar"

    local waybar_dir="$CONFIG_DIR/waybar"
    mkdir -p "$waybar_dir"

    # Config chính
    cat > "$waybar_dir/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 32,
    "spacing": 4,

    "modules-left": ["niri/workspaces", "niri/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "cpu", "memory", "tray"],

    "niri/workspaces": {
        "format": "{name}",
        "format-icons": {
            "active": "",
            "default": ""
        }
    },

    "niri/window": {
        "max-length": 50
    },

    "clock": {
        "timezone": "Asia/Ho_Chi_Minh",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format": " {:%d/%m/%Y  %H:%M}"
    },

    "cpu": {
        "format": " {usage}%",
        "tooltip": false
    },

    "memory": {
        "format": " {}%"
    },

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },

    "network": {
        "format-wifi": " {signalStrength}%",
        "format-ethernet": " {ipaddr}",
        "tooltip-format": "{ifname} via {gwaddr}",
        "format-linked": "{ifname} (No IP)",
        "format-disconnected": "⚠ Ngắt kết nối",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " Tắt",
        "on-click": "pavucontrol",
        "format-icons": {
            "headphone": "",
            "default": ["", "", ""]
        }
    },

    "tray": {
        "spacing": 10
    }
}
EOF

    # CSS style - Catppuccin Mocha
    cat > "$waybar_dir/style.css" << 'EOF'
/* Waybar - Catppuccin Mocha theme */

* {
    font-family: "FiraCode Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    border: none;
    border-radius: 0;
    min-height: 0;
}

window#waybar {
    background-color: rgba(30, 30, 46, 0.95);   /* Mocha base */
    color: #cdd6f4;                               /* Mocha text */
    border-bottom: 2px solid #89b4fa;             /* Mocha blue */
}

#workspaces button {
    padding: 0 8px;
    background: transparent;
    color: #6c7086;   /* Mocha overlay0 */
    border-bottom: 2px solid transparent;
}

#workspaces button.active {
    color: #89b4fa;   /* Mocha blue */
    border-bottom: 2px solid #89b4fa;
}

#workspaces button:hover {
    background: rgba(137, 180, 250, 0.1);
    color: #cdd6f4;
}

#clock {
    color: #a6e3a1;   /* Mocha green */
    padding: 0 12px;
}

#battery {
    color: #a6e3a1;
    padding: 0 8px;
}

#battery.charging {
    color: #f9e2af;   /* Mocha yellow */
}

#battery.warning:not(.charging) {
    color: #fab387;   /* Mocha peach */
}

#battery.critical:not(.charging) {
    color: #f38ba8;   /* Mocha red */
    animation: blink 0.5s linear infinite alternate;
}

@keyframes blink {
    to { color: #f38ba8; background: rgba(243, 139, 168, 0.2); }
}

#cpu {
    color: #89b4fa;   /* Mocha blue */
    padding: 0 8px;
}

#memory {
    color: #b4befe;   /* Mocha lavender */
    padding: 0 8px;
}

#network {
    color: #74c7ec;   /* Mocha sapphire */
    padding: 0 8px;
}

#network.disconnected {
    color: #f38ba8;
}

#pulseaudio {
    color: #cba6f7;   /* Mocha mauve */
    padding: 0 8px;
}

#pulseaudio.muted {
    color: #6c7086;
}

#tray {
    padding: 0 8px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#window {
    color: #cdd6f4;
    padding: 0 8px;
}
EOF

    chown -R "$SCRIPT_USER":"$SCRIPT_USER" "$waybar_dir" 2>/dev/null || true
    log_ok "Đã tạo Waybar config và CSS"
}

# ─── Tạo cấu hình Mako ───────────────────────────────────────────────────────
create_mako_config() {
    log_step "Tạo cấu hình Mako (notification daemon)"

    local mako_dir="$CONFIG_DIR/mako"
    mkdir -p "$mako_dir"

    cat > "$mako_dir/config" << 'EOF'
# Mako notification daemon - Catppuccin Mocha

[config]
sort=-time
layer=overlay
background-color=#1e1e2e
width=340
height=110
border-size=2
border-color=#89b4fa
border-radius=8
icons=1
max-icon-size=48
default-timeout=5000
ignore-timeout=0
font=FiraCode Nerd Font 11
text-color=#cdd6f4
padding=8

[urgency=low]
border-color=#313244
default-timeout=3000

[urgency=normal]
border-color=#89b4fa

[urgency=high]
border-color=#f38ba8
text-color=#f38ba8
default-timeout=0
EOF

    chown -R "$SCRIPT_USER":"$SCRIPT_USER" "$mako_dir" 2>/dev/null || true
    log_ok "Đã tạo Mako config"
}

# ─── Enable các service cần thiết ────────────────────────────────────────────
enable_services() {
    log_step "Enable systemd services"

    # Pipewire / Audio
    # Pipewire chạy như user service, enable thông qua systemctl --user
    log_info "Enable Pipewire services (user level)..."
    sudo -u "$SCRIPT_USER" systemctl --user enable pipewire pipewire-pulse wireplumber 2>/dev/null || \
        log_warn "Không thể enable Pipewire user services (sẽ tự động khi login)"

    # Bluetooth
    if pacman -Q bluez &>/dev/null 2>&1; then
        sudo systemctl enable bluetooth
        log_ok "Bluetooth service enabled"
    fi

    # NetworkManager (đã enable ở trên nhưng đảm bảo lại)
    sudo systemctl enable NetworkManager
    log_ok "NetworkManager enabled"

    # Greetd (đã enable trong configure_greetd)
    log_ok "Services đã được enable"
}

# ─── Tạo .xinitrc cho i3 ─────────────────────────────────────────────────────
create_xinitrc() {
    log_step "Tạo ~/.xinitrc cho i3 (X11 fallback)"

    cat > "$HOME_DIR/.xinitrc" << 'EOF'
#!/bin/sh
# ~/.xinitrc - Khởi động X11 session
# Dùng khi chạy: startx

# Load Xresources nếu có
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

# Set keyboard repeat rate
xset r rate 300 50

# Khởi động i3
exec i3
EOF

    chmod +x "$HOME_DIR/.xinitrc"
    chown "$SCRIPT_USER":"$SCRIPT_USER" "$HOME_DIR/.xinitrc" 2>/dev/null || true
    log_ok "Đã tạo ~/.xinitrc"
}

# ─── Tạo thư mục XDG chuẩn ───────────────────────────────────────────────────
setup_xdg_dirs() {
    log_step "Tạo thư mục XDG chuẩn"
    sudo -u "$SCRIPT_USER" xdg-user-dirs-update 2>/dev/null || true
    log_ok "XDG directories đã cập nhật"
}

# ─── Tóm tắt kết quả ─────────────────────────────────────────────────────────
show_summary() {
    echo ""
    log_divider
    echo -e "${GREEN}${BOLD}  ✅ CÀI ĐẶT DESKTOP HOÀN TẤT!${RESET}"
    log_divider

    if [[ ${#FAILED_PKGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}  ⚠  Packages không tìm thấy trong repo (đã bỏ qua):${RESET}"
        for pkg in "${FAILED_PKGS[@]}"; do
            echo -e "     ${YELLOW}• $pkg${RESET}"
        done
        echo ""
    fi

    echo -e "${BOLD}  Đã cài:${RESET}"
    echo -e "  ${GREEN}✓${RESET} i3 Window Manager (X11)"
    echo -e "  ${GREEN}✓${RESET} Niri Wayland Compositor"
    echo -e "  ${GREEN}✓${RESET} greetd + tuigreet Display Manager"
    echo -e "  ${GREEN}✓${RESET} Waybar, Mako, Wofi, Swaybg"
    echo -e "  ${GREEN}✓${RESET} Alacritty, Thunar, Firefox"
    echo -e "  ${GREEN}✓${RESET} PipeWire audio stack"
    echo ""
    echo -e "${BOLD}  Config files đã tạo:${RESET}"
    echo -e "  ${CYAN}~/.config/niri/config.kdl${RESET}"
    echo -e "  ${CYAN}~/.config/i3/config${RESET}"
    echo -e "  ${CYAN}~/.config/waybar/config${RESET} + ${CYAN}style.css${RESET}"
    echo -e "  ${CYAN}~/.config/mako/config${RESET}"
    echo -e "  ${CYAN}~/.xinitrc${RESET}"
    echo ""
    echo -e "${BOLD}  Bước tiếp theo:${RESET}"
    echo -e "  1. Reboot: ${CYAN}sudo reboot${RESET}"
    echo -e "  2. greetd sẽ hiện màn hình đăng nhập TUI"
    echo -e "  3. Chọn session: ${CYAN}niri${RESET} (Wayland) hoặc ${CYAN}i3${RESET} (X11)"
    echo ""
    echo -e "${YELLOW}  Lưu ý AUR packages (cần yay/paru để cài thêm):${RESET}"
    echo -e "  • rofi-wayland   - Rofi native Wayland"
    echo -e "  • nwg-look       - GTK theme setter cho Wayland"
    echo -e "  • xdg-desktop-portal-wlr - Portal cho wlroots compositors"
    log_divider
    echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║     ARCH LINUX DESKTOP INSTALLER             ║"
    echo "  ║     i3 (X11) + Niri (Wayland) + greetd       ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"

    check_user
    check_internet
    update_system
    install_base_packages
    install_x11
    install_i3
    install_niri
    install_wayland_stack
    install_apps
    install_fonts
    install_greetd
    configure_greetd
    create_niri_config
    create_i3_config
    create_waybar_config
    create_mako_config
    create_xinitrc
    enable_services
    setup_xdg_dirs
    show_summary
}

main "$@"
