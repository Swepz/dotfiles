#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="git@github.com:Swepz/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

read -rsp "Enter sudo password: " SUDO_PASS
echo

PASS_FILE="$(mktemp)"
chmod 600 "$PASS_FILE"
printf '%s' "$SUDO_PASS" > "$PASS_FILE"
trap 'rm -f "$PASS_FILE"' EXIT

echo "==> Installing base dependencies..."
printf '%s\n' "$SUDO_PASS" | sudo -S pacman -Sy --noconfirm --needed git ansible stow base-devel 2>&1

echo "==> Installing ansible community.general collection..."
ansible-galaxy collection install community.general

if [ -d "$DOTFILES_DIR" ]; then
    echo "==> Dotfiles already cloned at $DOTFILES_DIR"
    cd "$DOTFILES_DIR"
    git pull --rebase || true
else
    echo "==> Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

echo "==> Running Ansible playbook..."
cd "$DOTFILES_DIR/ansible"
ansible-playbook site.yml --become-password-file="$PASS_FILE"

echo "==> Done! Log out and back in for all changes to take effect."
