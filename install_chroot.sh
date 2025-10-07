#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "[ERR] chroot stage failed at line $LINENO"; exit 1' ERR

# Preconditions
[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }
. /etc/os-release; [ "${ID:-}" = "arch" ] || { echo "Arch chroot required"; exit 1; }

# Inputs from stage-1
uefi="$(cat /var_uefi)"; hd="$(cat /var_hd)"
cat /comp > /etc/hostname && rm -f /comp
HN="$(cat /etc/hostname)"

# Base tools needed for prompts + bootloader + network + sudo
pacman -S --noconfirm dialog grub sudo networkmanager systemd-timesyncd

# Bootloader
if [ "$uefi" = "1" ]; then
  pacman -S --noconfirm --needed efibootmgr
  grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
else
  grub-install "$hd"
fi
grub-mkconfig -o /boot/grub/grub.cfg

# Time, locale, hosts
timedatectl set-ntp true
TZ="${TZ:-America/Chicago}"
ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
hwclock --systohc

# Enable locale cleanly
sed -i 's/^#\s*en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf

# Hosts
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HN}.localdomain ${HN}
EOF

# User setup
config_user() {
  local target="$1"
  local name pass1 pass2
  if [ "$target" = "root" ]; then
    dialog --title "root password" --msgbox "Set root password" 7 40
    while :; do
      pass1=$(dialog --no-cancel --passwordbox "Enter root password." 9 60 3>&1 1>&2 2>&3)
      pass2=$(dialog --no-cancel --passwordbox "Confirm root password." 9 60 3>&1 1>&2 2>&3)
      [ "$pass1" = "$pass2" ] && break
      dialog --msgbox "Passwords do not match. Try again." 7 40
    done
    echo "root:${pass1}" | chpasswd
  else
    name="$(dialog --no-cancel --inputbox "Enter new username." 8 50 3>&1 1>&2 2>&3)"
    while :; do
      pass1=$(dialog --no-cancel --passwordbox "Enter password for ${name}." 9 60 3>&1 1>&2 2>&3)
      pass2=$(dialog --no-cancel --passwordbox "Confirm password for ${name}." 9 60 3>&1 1>&2 2>&3)
      [ "$pass1" = "$pass2" ] && break
      dialog --msgbox "Passwords do not match. Try again." 7 40
    done
    id -u "$name" >/dev/null 2>&1 || useradd -m -G wheel -s /bin/bash "$name"
    echo "${name}:${pass1}" | chpasswd
    echo "$name" > /tmp/user_name
  fi
}
config_user root
dialog --title "Add User" --msgbox "Create a non-root user." 7 40
config_user user

# Sudo for wheel via drop-in
install -Dm440 /dev/stdin /etc/sudoers.d/10-wheel <<'EOF'
%wheel ALL=(ALL:ALL) ALL
EOF

# Enable services
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

# Optional apps/dotfiles step (private: execute local file if staged by stage-1)
if dialog --yesno "Install apps/dotfiles now?" 7 50; then
  if [ -x /install_apps.sh ]; then
    bash /install_apps.sh
  elif [ -x /root/install_apps.sh ]; then
    bash /root/install_apps.sh
  else
    dialog --msgbox "install_apps.sh not found. Skipping." 7 50
  fi
fi

# Cleanup vars
rm -f /var_uefi /var_hd

clear
echo "== PAKAGES Installer — Private Edition complete =="
echo "Reboot, login as your user, then continue your private bootstrap."
