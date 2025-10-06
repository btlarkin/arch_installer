# PAKAGES Installer (Private Edition)

Overview

Guided Arch Linux install for personal use. After first login, restore your private PAKAGES environment.

Destructive action: this wipes the selected disk.

Requirements

Arch Linux Live ISO with internet access.

GitHub SSH access (deploy key or your key loaded into the Live ISO).

Private repos:

`git@github.com:btlarkin/arch_installer.git`

`git@github.com:btlarkin/PAKAGES-private.git`

Quick start

Load SSH key and verify GitHub:

```
mkdir -m700 -p /root/.ssh
# copy your private key to /root/.ssh/id_ed25519 and chmod 600 it
ssh-keyscan github.com >> /root/.ssh/known_hosts
ssh -T git@github.com
```

Run the installer:

```
pacman -Sy --noconfirm git
git clone git@github.com:btlarkin/arch_installer.git
cd arch_installer
./install_sys.sh
```

Reboot and log in as your user.

Private overlay

Restore your environment:
```
git clone git@github.com:btlarkin/PAKAGES-private.git ~/PSAK || true
bash ~/PSAK/scripts/ages_bootstrap.sh
```
Secrets

Populate any required `.env` files in your private tree and set permissions:

`chmod 600 path/to/.env`

Verify

```
cd ~/PSAK
make doctor
make tree
```
