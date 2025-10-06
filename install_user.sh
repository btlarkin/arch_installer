#!/usr/bin/env bash
set -Eeuo pipefail

# --- basics ---
mkdir -p "$HOME/Documents" "$HOME/Downloads"

# --- helpers ---
aur_install() {
  local pkg="$1"
  local tmp
  tmp="$(mktemp -d)"
  (
    cd "$tmp"
    curl -fsSLO "https://aur.archlinux.org/cgit/aur.git/snapshot/${pkg}.tar.gz"
    tar -xzf "${pkg}.tar.gz"
    cd "$pkg"
    makepkg --noconfirm -si
  )
  rm -rf "$tmp"
}

aur_check() {
  local installed
  installed="$(pacman -Qm 2>/dev/null | awk '{print $1}')"
  for pkg in "$@"; do
    if ! grep -qx "$pkg" <<<"$installed"; then
      if command -v yay >/dev/null 2>&1; then
        yay --noconfirm -S "$pkg" &>> /tmp/aur_install || aur_install "$pkg" &>> /tmp/aur_install
      else
        aur_install "$pkg" &>> /tmp/aur_install
      fi
    fi
  done
}

msg() { command -v dialog >/dev/null && dialog --infobox "$1" 7 60 || echo "$1"; }

# --- ensure yay present ---
msg 'Installing "yay" AUR helper (if needed)…'
aur_check yay

# --- process /tmp/aur_queue if present ---
QUEUE="/tmp/aur_queue"
if [[ -s "$QUEUE" ]]; then
  mapfile -t pkgs < <(grep -Ev '^\s*(#|$)' "$QUEUE")
  total="${#pkgs[@]}"
  i=0
  for p in "${pkgs[@]}"; do
    i=$((i+1))
    msg "AUR install ($i/$total): $p"
    aur_check "$p"
  done
else
  msg "No /tmp/aur_queue found or it is empty. Skipping AUR bulk install."
fi

# --- dotfiles ---
DOTFILES="$HOME/dotfiles"
if [[ ! -d "$DOTFILES" ]]; then
  msg "Cloning dotfiles…"
  git clone https://github.com/btlarkin/dotfiles.git "$DOTFILES" >/dev/null
else
  msg "Updating dotfiles…"
  git -C "$DOTFILES" pull --ff-only || true
fi

# shell env then install
if [[ -f "$DOTFILES/zsh/.zshenv" ]]; then
  # shellcheck disable=SC1090
  source "$DOTFILES/zsh/.zshenv"
fi
bash "$DOTFILES/install.sh"

# --- done ---
msg "User setup complete."
