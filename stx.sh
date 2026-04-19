#!/usr/bin/env bash

# ===== 1. Detect hardware =====
CPU=$(lscpu | grep "Model name" | sed 's/Model name:\s*//')
RAM=$(free -h | awk '/Mem:/ {print $2}')
GPU=$(lspci | grep -E "VGA|3D")

clear
echo "===== SYSTEM INFO ====="
echo "CPU: $CPU"
echo "RAM: $RAM"
if [ -z "$GPU" ]; then
  echo "GPU: None detected"
else
  echo "GPU: $GPU"
fi
echo "========================"

# ===== 2. Ask user needs =====
echo ""
echo "Chon nhu cau su dung:"
echo "1. Gaming"
echo "2. Lap trinh"
echo "3. Su dung hang ngay (web, video)"
echo "4. Toi uu pin (laptop)"
read -rp "Nhap lua chon (1-4): " CHOICE

# ===== 3. Optimization =====
echo ""
echo "Dang toi uu..."

# Common optimizations
sudo pacman -S --noconfirm cpupower tlp thermald

sudo systemctl enable --now thermald 2>/dev/null
sudo systemctl enable --now tlp

# Apply based on usage
case $CHOICE in
  1)
    echo "Profile: Gaming"
    sudo cpupower frequency-set -g performance
    ;;
  2)
    echo "Profile: Programming"
    sudo cpupower frequency-set -g schedutil
    ;;
  3)
    echo "Profile: Daily use"
    sudo cpupower frequency-set -g ondemand
    ;;
  4)
    echo "Profile: Battery saving"
    sudo cpupower frequency-set -g powersave
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

# Swappiness optimization (RAM)
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf

# Enable zram
sudo pacman -S --noconfirm zram-generator
echo -e "[zram0]\nzram-size = ram / 2" | sudo tee /etc/systemd/zram-generator.conf >/dev/null

# GPU tweak (if exists)
if echo "$GPU" | grep -iq "nvidia"; then
  echo "NVIDIA GPU detected -> enabling modeset"
  echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
fi

echo ""
echo "Toi uu hoan tat. Reboot de ap dung day du."
