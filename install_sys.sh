#!/bin/bash

# Never run pacman -Sy on your system!
pacman -Sy dialog

timedatectl set-ntp true

# Welcome message  of type yesno
dialog --defaultno --title "Are you sure?" --yesno \
    "This is my personal arch linux install. \n\n\
    It will DESTROY EVERYTHING on one of your hard disk. \n\n\
    Don't say YEs if you are not sure what you're doing! \n\n\
    Do you want to continue?" 15 60 || exit

dialog --no-cancel --inputbox "Enter a name for your computer." \
    10 60 2> comp

# Verify boot (UEFI or BIOS)
uefi=0
ls /sys/firmware/efi/efivars 2> /dev/null && uefi=1

# Choosing the hard drive
devices_list=($(lblk -d | awk '{print "/dev/" $1 " " $4 " on"}' \
        | grep -E 'sd|hd|vd|nvme|mmcblk'))

dialog --title "Choose your hard drive" --no-cancel --radiolist \
    "Where do you want to install your new system? \n\n\
    Select with SPACE, valid with ENTER. \n\n\
    WARNING: Everything will be DESTROYED on the hard disk!" \
    15 60 4 "${devices_list[@]}" 2> hd

hd=$(cat hd) && rm hd

# Ask for the size of the swap partition
default_size="8"
dialog --no-cancel --inputbox \
    "You need four partitions: Boot, Root and Swap \n\
    The boot partition will be 512M \n\
    The root partition will be the remaining of the hard disk \n\n\
    Enter below the partition size (in GB) for the Swap. \n\n\
    If you don't enter anything, it will default to ${default_size}G. \n" \
    20 60 2> swap_size

size=$(cat swap_size) && rm swap_size

[[ $size =~ ^[0-9]+$ ]] || size=$default_size

