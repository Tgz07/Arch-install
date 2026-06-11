#!/usr/bin/env bash
# =============================================================================
# format_disk.sh - Chuẩn bị ổ đĩa để cài Arch Linux
# =============================================================================
# Tác giả: Arch Linux Setup Project
# Mô tả : Format ổ đĩa GPT (EFI + ROOT), mount vào /mnt
# Yêu cầu: Chạy từ Arch Linux live USB với quyền root
# =============================================================================

set -euo pipefail

# ─── Màu sắc log ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Hàm log ─────────────────────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
log_step()    { echo -e "\n${CYAN}${BOLD}==> $*${RESET}"; }
log_divider() { echo -e "${BLUE}────────────────────────────────────────────────────${RESET}"; }

# ─── Kiểm tra quyền root ─────────────────────────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script này phải chạy với quyền root!"
        log_error "Hãy dùng: sudo $0 hoặc chạy với tư cách root"
        exit 1
    fi
    log_ok "Đang chạy với quyền root"
}

# ─── Kiểm tra các công cụ cần thiết ─────────────────────────────────────────
check_dependencies() {
    log_step "Kiểm tra dependencies"
    local missing=()
    local tools=(lsblk parted mkfs.fat mkfs.ext4 mount mkdir)

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Thiếu các công cụ sau: ${missing[*]}"
        log_error "Hãy đảm bảo bạn đang chạy từ Arch Linux live USB"
        exit 1
    fi
    log_ok "Tất cả dependencies đã có"
}

# ─── Hiển thị danh sách ổ đĩa ────────────────────────────────────────────────
show_disks() {
    log_step "Danh sách ổ đĩa hiện có"
    log_divider
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,MODEL
    log_divider
}

# ─── Nhập và validate ổ đĩa ──────────────────────────────────────────────────
select_disk() {
    while true; do
        echo -e "\n${BOLD}Nhập đường dẫn ổ đĩa cần format${RESET}"
        echo -e "${YELLOW}Ví dụ: /dev/sda hoặc /dev/nvme0n1${RESET}"
        read -rp "Disk: " DISK

        # Kiểm tra không rỗng
        if [[ -z "$DISK" ]]; then
            log_error "Không được để trống! Hãy nhập lại."
            continue
        fi

        # Kiểm tra tồn tại
        if [[ ! -b "$DISK" ]]; then
            log_error "Ổ đĩa '$DISK' không tồn tại hoặc không phải block device!"
            log_warn "Kiểm tra lại với lsblk ở trên"
            continue
        fi

        # Kiểm tra không phải partition (không được chọn /dev/sda1, v.v.)
        local disk_name
        disk_name=$(basename "$DISK")
        if lsblk -no TYPE "$DISK" 2>/dev/null | grep -q "part"; then
            log_error "'$DISK' là partition, không phải ổ đĩa!"
            log_warn "Hãy chọn ổ đĩa gốc (ví dụ /dev/sda, không phải /dev/sda1)"
            continue
        fi

        log_ok "Ổ đĩa hợp lệ: $DISK"
        break
    done
}

# ─── Xác định tên partition theo loại ổ đĩa ──────────────────────────────────
get_partition_names() {
    # NVMe: /dev/nvme0n1p1, /dev/nvme0n1p2
    # SATA/SCSI: /dev/sda1, /dev/sda2
    if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
        EFI_PART="${DISK}p1"
        ROOT_PART="${DISK}p2"
    else
        EFI_PART="${DISK}1"
        ROOT_PART="${DISK}2"
    fi
    log_info "Partition EFI  : $EFI_PART"
    log_info "Partition ROOT : $ROOT_PART"
}

# ─── Cảnh báo và xác nhận ────────────────────────────────────────────────────
confirm_format() {
    local disk_info
    disk_info=$(lsblk -o NAME,SIZE,MODEL "$DISK" 2>/dev/null | head -2)

    echo ""
    log_divider
    echo -e "${RED}${BOLD}  ⚠️  CẢNH BÁO NGUY HIỂM ⚠️${RESET}"
    log_divider
    echo -e "${RED}  Thao tác này sẽ XÓA TOÀN BỘ DỮ LIỆU trên:${RESET}"
    echo -e "${BOLD}  $DISK${RESET}"
    echo ""
    echo -e "${YELLOW}  Thông tin ổ đĩa:${RESET}"
    echo "$disk_info" | sed 's/^/  /'
    echo ""
    echo -e "${RED}  KHÔNG THỂ KHÔI PHỤC SAU KHI FORMAT!${RESET}"
    log_divider

    echo -e "\n${BOLD}Để xác nhận, hãy gõ chính xác:${RESET}"
    echo -e "${YELLOW}  FORMAT $DISK${RESET}"
    echo ""
    read -rp "Xác nhận: " CONFIRM

    if [[ "$CONFIRM" != "FORMAT $DISK" ]]; then
        log_warn "Xác nhận không khớp. Hủy thao tác."
        log_info "Script đã thoát an toàn, không có gì bị xóa."
        exit 0
    fi

    log_ok "Xác nhận thành công. Bắt đầu format..."
}

# ─── Unmount nếu đã mount ────────────────────────────────────────────────────
unmount_existing() {
    log_step "Kiểm tra và unmount các mount point cũ"

    # Unmount theo thứ tự ngược (con trước cha)
    local mounts
    mounts=$(mount | grep "$DISK" | awk '{print $3}' | sort -r || true)

    if [[ -n "$mounts" ]]; then
        log_warn "Phát hiện các mount point cũ, đang unmount..."
        while IFS= read -r mp; do
            log_info "Unmount: $mp"
            umount "$mp" 2>/dev/null || log_warn "Không thể unmount $mp (bỏ qua)"
        done <<< "$mounts"
    fi

    # Unmount /mnt nếu đang dùng
    if mountpoint -q /mnt 2>/dev/null; then
        log_info "Unmount /mnt..."
        umount -R /mnt 2>/dev/null || true
    fi

    log_ok "Hoàn tất kiểm tra mount"
}

# ─── Tạo bảng phân vùng GPT ──────────────────────────────────────────────────
create_partitions() {
    log_step "Tạo bảng phân vùng GPT trên $DISK"

    log_info "Xóa bảng phân vùng cũ..."
    wipefs -af "$DISK"
    sgdisk --zap-all "$DISK" 2>/dev/null || true
    sleep 1

    log_info "Tạo bảng phân vùng GPT mới..."
    parted -s "$DISK" mklabel gpt

    log_info "Tạo partition EFI (512M)..."
    parted -s "$DISK" mkpart "EFI" fat32 1MiB 513MiB
    parted -s "$DISK" set 1 esp on

    log_info "Tạo partition ROOT (phần còn lại)..."
    parted -s "$DISK" mkpart "ROOT" ext4 513MiB 100%

    # Đợi kernel cập nhật partition table
    log_info "Đợi kernel nhận diện partition mới..."
    partprobe "$DISK"
    sleep 2

    log_ok "Tạo partition thành công"
    log_info "Bảng phân vùng mới:"
    parted -s "$DISK" print
}

# ─── Format partition ─────────────────────────────────────────────────────────
format_partitions() {
    log_step "Format các partition"

    # Kiểm tra partition tồn tại
    if [[ ! -b "$EFI_PART" ]]; then
        log_error "Partition EFI '$EFI_PART' không tồn tại sau khi tạo!"
        log_error "Thử chạy: partprobe $DISK"
        exit 1
    fi

    if [[ ! -b "$ROOT_PART" ]]; then
        log_error "Partition ROOT '$ROOT_PART' không tồn tại sau khi tạo!"
        exit 1
    fi

    log_info "Format EFI partition ($EFI_PART) → FAT32..."
    mkfs.fat -F32 -n "EFI" "$EFI_PART"
    log_ok "EFI partition đã format FAT32"

    log_info "Format ROOT partition ($ROOT_PART) → ext4..."
    mkfs.ext4 -F -L "ROOT" "$ROOT_PART"
    log_ok "ROOT partition đã format ext4"
}

# ─── Mount partition ──────────────────────────────────────────────────────────
mount_partitions() {
    log_step "Mount các partition"

    log_info "Mount ROOT partition vào /mnt..."
    mount "$ROOT_PART" /mnt
    log_ok "ROOT mounted tại /mnt"

    log_info "Tạo thư mục /mnt/boot..."
    mkdir -p /mnt/boot

    log_info "Mount EFI partition vào /mnt/boot..."
    mount "$EFI_PART" /mnt/boot
    log_ok "EFI mounted tại /mnt/boot"

    # Xác nhận kết quả
    log_step "Kết quả mount"
    log_divider
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE "$DISK"
    log_divider
}

# ─── Tóm tắt kết quả ─────────────────────────────────────────────────────────
show_summary() {
    echo ""
    log_divider
    echo -e "${GREEN}${BOLD}  ✅ FORMAT VÀ MOUNT HOÀN TẤT!${RESET}"
    log_divider
    echo -e "${BOLD}  Cấu trúc:${RESET}"
    echo -e "  ${GREEN}$EFI_PART${RESET}  → /mnt/boot  (FAT32, 512M, EFI)"
    echo -e "  ${GREEN}$ROOT_PART${RESET}  → /mnt       (ext4, toàn bộ còn lại)"
    echo ""
    echo -e "${BOLD}  Bước tiếp theo:${RESET}"
    echo -e "  1. Cài Arch base system:"
    echo -e "     ${CYAN}pacstrap /mnt base base-devel linux linux-firmware networkmanager vim${RESET}"
    echo -e "  2. Tạo fstab:"
    echo -e "     ${CYAN}genfstab -U /mnt >> /mnt/etc/fstab${RESET}"
    echo -e "  3. Chroot vào hệ thống mới:"
    echo -e "     ${CYAN}arch-chroot /mnt${RESET}"
    echo -e "  4. Sau khi cài xong và reboot, chạy:"
    echo -e "     ${CYAN}./install_desktop.sh${RESET}"
    log_divider
    echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║     ARCH LINUX DISK FORMATTER                ║"
    echo "  ║     GPT + EFI + ROOT Setup                   ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"

    check_root
    check_dependencies
    show_disks
    select_disk
    get_partition_names
    confirm_format
    unmount_existing
    create_partitions
    format_partitions
    mount_partitions
    show_summary
}

main "$@"
