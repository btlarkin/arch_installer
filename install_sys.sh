#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "[ERR] line $LINENO"; exit 1' ERR
[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }
. /etc/os-release; [ "${ID:-}" = arch ] || { echo "Arch ISO required"; exit 1; }

VERSION="PAKAGES Installer — Private Edition v1.0"
echo "== ${VERSION} =="

# dialog for prompts
pacman -Sy --noconfirm dialog

timedatectl set-ntp true

dialog --defaultno --title "Are you sure?" --yesno \
"This will DESTROY EVERYTHING on the target disk.\n\nContinue?" 12 60 || exit 0

dialog --no-cancel --inputbox "Enter a hostname:" 8 50 2> comp
comp=$(cat comp); rm -f comp

# Detect UEFI
uefi=0; [ -d /sys/firmware/efi/efivars ] && uefi=1

# Pick disk
devices_list=($(lsblk -d | awk '{print "/dev/" $1 " " $4 " on"}' \
    | grep -E 'sd|hd|vd|nvme|mmcblk'))
dialog --title "Choose your hard drive" --no-cancel --radiolist \
"Select with SPACE, confirm with ENTER.\nWARNING: Disk will be wiped." \
15 60 6 "${devices_list[@]}" 2> hd
hd=$(cat hd); rm -f hd

# Swap size
default_size="8"
dialog --no-cancel --inputbox \
"Partitions:\n- Boot: 512M\n- Swap: your size\n- Root: rest\n\nEnter Swap size in GB (default ${default_size}):" \
14 60 2> swap_size
size=$(cat swap_size); rm -f swap_size
[[ $size =~ ^[0-9]+$ ]] || size=$default_size

# Wipe choice
dialog --no-cancel --menu "Wipe method for $hd" 12 50 3 \
1 "dd (overwrite with zeros)" \
2 "shred (secure, slower)" \
3 "Skip (disk already empty)" 2> eraser
hderaser=$(cat eraser); rm -f eraser

eraseDisk() {
  case "$1" in
    1) dd if=/dev/zero of="$hd" status=progress 2>&1 | dialog --title "Wiping $hd with dd..." --progressbox --stdout 20 60;;
    2) shred -v "$hd"            2>&1 | dialog --title "Wiping $hd with shred..." --progressbox --stdout 20 60;;
    3) :;;
  esac
}
eraseDisk "$hderaser"

# Partitioning with fdisk (GPT)
partprobe "$hd"
boot_type=1; [ "$uefi" -eq 0 ] && boot_type=4
fdisk "$hd" << EOF
g
n


+512M
t
$boot_type
n


+${size}G
n



w
EOF
partprobe "$hd"

# NVMe suffix
echo "$hd" | grep -q nvme && hd="${hd}p"

# Filesystems
mkswap "${hd}2"
swapon "${hd}2"
mkfs.ext4 -F "${hd}3"
mount "${hd}3" /mnt

if [ "$uefi" -eq 1 ]; then
  mkfs.fat -F32 "${hd}1"
  mkdir -p /mnt/boot/efi
  mount "${hd}1" /mnt/boot/efi
fi

# Base system
pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# Pass vars to chroot stage
echo "$uefi" > /mnt/var_uefi
echo "$hd"   > /mnt/var_hd
echo "$comp" > /mnt/comp

# Prefer local chroot script (private repo); fallback disabled for privacy
if [ -f "./install_chroot.sh" ]; then
  install -m 0755 ./install_chroot.sh /mnt/install_chroot.sh
else
  echo "[FATAL] install_chroot.sh missing in repo"; exit 1
fi

arch-chroot /mnt bash /install_chroot.sh

# Cleanup
rm -f /mnt/var_uefi /mnt/var_hd /mnt/install_chroot.sh /mnt/comp

# Reboot prompt with private handoff (print only; no files/MOTD)
NEXT_PRIV='git clone git@github.com:btlarkin/PAKAGES-private.git ~/PSAK && bash ~/PSAK/scripts/ages_bootstrap.sh'
dialog --yesno "Install complete.\n\nReboot now?" 10 40
resp=$?
clear
echo "== ${VERSION} =="
echo "After first login as your user, run:"
echo "${NEXT_PRIV}"
[ "$resp" -eq 0 ] && reboot || true
