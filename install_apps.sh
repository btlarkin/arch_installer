#!/usr/bin/env bash
set -Eeuo pipefail

# --- config (edit once) ---
NAME="$(cat /tmp/user_name 2>/dev/null || true)"; : "${NAME:?missing /tmp/user_name}"
APPS_URL="${APPS_URL:-https://raw.githubusercontent.com/btlarkin/arch_installer/main/apps.csv}"
INSTALL_USER_URL="${INSTALL_USER_URL:-https://raw.githubusercontent.com/btlarkin/arch_installer/main/install_user.sh}"

# Private PAKAGES source (SSH deploy key or agent must be ready)
PAKAGES_REPO_SSH="${PAKAGES_REPO_SSH:-git@github.com:btlarkin/PAKAGES-private.git}"
PAKAGES_DIR="${PAKAGES_DIR:-/home/${NAME}/PSAK}"
PAKAGES_BOOTSTRAP="${PAKAGES_BOOTSTRAP:-scripts/ages_bootstrap.sh}"

APPS_PATH="/tmp/apps.csv"
curl -fsSLo "$APPS_PATH" --retry 3 "$APPS_URL"

command -v dialog >/dev/null 2>&1 || pacman -Sy --noconfirm --needed dialog
dialog --title "Apps & Dotfiles" --msgbox "Private Edition" 6 40

# dynamic groups
mapfile -t GROUPS < <(awk -F, 'NF>=2{print $1}' "$APPS_PATH" | sort -u)
is_on(){ case "$1" in essential|network|tools|git|zsh|neovim|tmux|i3) echo on;;*) echo off;; esac; }
opts=(); for g in "${GROUPS[@]}"; do opts+=("$g" "Group: $g" "$(is_on "$g")"); done
dialog --checklist "Select groups (SPACE to toggle, ENTER to confirm)" 0 0 0 "${opts[@]}" 2> /tmp/app_choices
read -r SELECTION <<<"$(cat /tmp/app_choices 2>/dev/null || true)"; rm -f /tmp/app_choices
[ -z "$SELECTION" ] && { dialog --msgbox "No groups selected. Exiting." 6 40; exit 0; }

read -r -a SEL_ARR <<<"$SELECTION"; SEL_REGEX="$(printf '^%s,|' "${SEL_ARR[@]}")"; SEL_REGEX="${SEL_REGEX%|}"

# split repo vs AUR using [AUR] token
mapfile -t REPO_PKGS < <(awk -F, -v p="$SEL_REGEX" 'BEGIN{IGNORECASE=1} $0~p && $3!~/\[AUR\]/ {print $2}' "$APPS_PATH" | sed '/^\s*$/d' | sort -u)
mapfile -t AUR_PKGS  < <(awk -F, -v p="$SEL_REGEX" 'BEGIN{IGNORECASE=1} $0~p && $3~/\[AUR\]/  {print $2}' "$APPS_PATH" | sed '/^\s*$/d' | sort -u)

pacman -Syu --noconfirm
((${#REPO_PKGS[@]})) && pacman -Sy --noconfirm --needed "${REPO_PKGS[@]}" |& tee /tmp/arch_install_repo.log

# any repo misses → AUR
MISSING=(); for p in "${REPO_PKGS[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 || MISSING+=("$p"); done
: > /tmp/aur_queue
((${#AUR_PKGS[@]})) && printf '%s\n' "${AUR_PKGS[@]}" >> /tmp/aur_queue
((${#MISSING[@]}))  && printf '%s\n' "${MISSING[@]}"  >> /tmp/aur_queue

# dotfiles + AUR as user
curl -fsSLo /tmp/install_user.sh --retry 3 "$INSTALL_USER_URL"; chmod +x /tmp/install_user.sh
dialog --msgbox "Switching to user for AUR & dotfiles…" 6 50
sudo -u "$NAME" /tmp/install_user.sh

# --- PRIVATE HANDOFF: restore PAKAGES with AGES ---
dialog --infobox "Restoring PAKAGES (private)…" 5 50
sudo -u "$NAME" bash -lc "
  set -e
  if [ -d '${PAKAGES_DIR}/.git' ]; then
    git -C '${PAKAGES_DIR}' fetch --all && git -C '${PAKAGES_DIR}' pull --ff-only
  else
    git clone '${PAKAGES_REPO_SSH}' '${PAKAGES_DIR}'
  fi
  cd '${PAKAGES_DIR}'
  if [ -x '${PAKAGES_BOOTSTRAP}' ]; then
    bash '${PAKAGES_BOOTSTRAP}'
  else
    echo 'Bootstrap missing: ${PAKAGES_BOOTSTRAP}' >&2; exit 1
  fi
"

dialog --msgbox "Private Edition complete. Reboot when ready." 6 45
