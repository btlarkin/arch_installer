#!/bin/bash

# Block device and boot mode
uefi=$(cat /var_uefi); hd=$(cat /var_hd);

# Naming the system
cat /comp > /etc/hostname && rm /comp

# The Bootloader GRUB
pacman --noconfirm -S dialog
pacman -S --noconfirm grub

if [ "$uefi" = 1 ]; then
    pacman -S --confirm efibootmgr
    grub-install --target=x86_64-efi \
        --bootloader-id=GRUB \
        --efi-directory=/boot/efi
else
    grub-install "$hd"
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Set hardware clock from system clock
hwclock --systohc
# Set timezone
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime


