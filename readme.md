# PAKAGES Installer (Private Edition)

### Overview

This guide details a destructive, guided **Arch Linux install** for personal use. After the first login, it restores your private **PAKAGES** environment.

**Destructive Action:** This process will wipe the selected disk.

### Requirements

  * Arch Linux Live ISO with internet access.
  * **A separate, working computer/device** (for SSH key management and key upload).
  * GitHub SSH access (your personal SSH key registered with GitHub).

**Private Repositories:**

  * `git@github.com:btlarkin/arch_installer.git`
  * `git@github.com:btlarkin/PAKAGES-private.git`

-----

## 🔑 Prerequisite: SSH Key Setup (On a Separate Computer)

These steps must be completed **before** booting the Arch Live ISO.

1.  **Generate Key Pair:** If you don't have one, generate a new key on your separate machine. Use your GitHub-associated email for the comment:

    ```bash
    ssh-keygen -t ed25519 -C "your_github_email@example.com"
    ```

    This creates the private key (`id_ed25519`) and the public key (`id_ed25519.pub`).

2.  **Upload Public Key to GitHub:**

      * Copy the *contents* of the **public key** file (`cat ~/.ssh/id_ed25519.pub`).
      * Go to GitHub's **Settings \> SSH and GPG keys** in your browser.
      * Click **New SSH key**, give it a clear title, and paste the key contents.

3.  **Prepare Private Key for Transfer:**

      * Copy the **private key** file (`~/.ssh/id_ed25519`) to a reliable, portable medium like a **USB drive**. **Do not** copy the public key (`.pub`).

-----

## 💾 Quick Start (On the Arch Live ISO)

### 0\. Establish Internet Connection 🌐

The Live ISO environment uses the `iwctl` utility. Run these commands as **root**:

1.  **Enter the `iwctl` interactive shell:**

    ```bash
    iwctl
    ```

2.  **List your Wi-Fi devices** (look for names starting with `wlan` or `wlp`):

    ```bash
    [iwd]# device list
    ```

    *(Note the device name, e.g., `wlan0`.)*

3.  **Scan and Connect:**

    ```bash
    [iwd]# station <device_name> scan
    [iwd]# station <device_name> get-networks
    [iwd]# station <device_name> connect <SSID>
    ```

    *(You will be prompted for the password.)*

4.  **Exit and Verify:**

    ```bash
    [iwd]# exit
    ping -c 3 google.com
    ```

### 1\. Load SSH Key and Verify GitHub Access

1.  **Mount USB Drive and Transfer Key:**

      * Insert your USB drive and mount it (e.g., if the device is `/dev/sdb1`):
        ```bash
        mkdir /mnt/usb
        mount /dev/sdb1 /mnt/usb
        ```
      * Copy your private key and set the **strict permissions** required by SSH:
        ```bash
        mkdir -m700 -p /root/.ssh
        cp /mnt/usb/id_ed25519 /root/.ssh/id_ed25519
        chmod 600 /root/.ssh/id_ed25519
        ```

2.  **Load Key and Verify Connection:**

      * Start the SSH agent and load the key (enter your passphrase when prompted):
        ```bash
        eval "$(ssh-agent -s)"
        ssh-add /root/.ssh/id_ed25519
        ```
      * Add GitHub to your known hosts and test the connection:
        ```bash
        ssh-keyscan github.com >> /root/.ssh/known_hosts
        ssh -T git@github.com
        ```
      * *(Expected successful message: "Hi \[username]\! You've successfully authenticated...")*

### 2\. Run the Installer

1.  **Install Git and Clone Installer Repository:**

    ```bash
    pacman -Sy --noconfirm git
    git clone git@github.com:btlarkin/arch_installer.git
    ```

2.  **Execute Installation Script:**

    ```bash
    cd arch_installer
    ./install_sys.sh
    ```

3.  **Reboot and Log In:** **Reboot** the system and log in as the user you created during the installation.

-----

## 🖥️ Private Environment Restoration

### 1\. Private Overlay

Restore your customized environment in your new home directory:

```bash
git clone git@github.com:btlarkin/PAKAGES-private.git ~/PSAK || true
bash ~/PSAK/scripts/ages_bootstrap.sh
```

### 2\. Secrets

Populate any required sensitive information into `.env` files within your private tree, and then set permissions to restrict access:

```bash
chmod 600 path/to/.env
```

### 3\. Verification

Run the verification checks to ensure your private environment is correctly initialized:

```bash
cd ~/PSAK
make doctor
make tree
```
