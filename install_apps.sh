#!/bin/bash

name=$(cat /tmp/user_name)
apps_path="/tmp/apps.csv"

curl https://raw.githubusercontent.com/btlarkin\
    /arch_installer/master/apps.csv > $apps_path

dialog --title "Welcome!" \
    --msgbox "Welcome to the install script for your apps and dotfiles!" \
        10 60

# Allow the user to select the group of packages he (or she) wants to install.
apps=("essential" "Essentials" on
      "network" "Network" on
      "tools" "Nice tools to have (highly recommended)" on
      "tmux" "Tmux" on
      "notifier" "Notification tools" on
      "git" "Git & git tools" on
      "i3" "i3 wm" on
      "zsh" "The Z-Shell (zsh)" on
      "neovim" "Neovim" on
      "urxvt" "URxvt" on
      "js" "JavaScript tooling" on
      "music""terminal music player(kew)" on
      "google" "Google (Browser)" on
      "firefox" "Firefox (browser)" off
      "qutebrowser" "Qutebrowser (browser)" off
      "lynx" "Lynx (browser)" off)

dialog --checklist \
"You can now choose what group of application you want to install. \n\n\
You can select an option with SPACE and valid your choices with ENTER." \
0 0 0 \
"${apps[@]}" 2> app_choices
choices=$(cat app_choices) && rm app_choices

# Create a regex to only select the packages we want
selection="^$(echo $choices | sed -e 's/ /,|^/g'),"
lines=$(grep -E "$selection" "$apps_path")
count=$(echo "$lines" | wc -l)
packages=$(echo "$lines" | awk -F, {'print $2'})

echo "$selection" "$lines" "$count" >> "/tmp/packages"

# Updating system
pacman -Syu --noconfirm



