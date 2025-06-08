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



