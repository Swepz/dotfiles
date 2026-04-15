# dotfiles

Arch Linux + Hyprland dotfiles managed with GNU Stow and provisioned with Ansible.

## Fresh Install

```bash
sudo pacman -S git
git clone git@github.com:Swepz/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

## After Setup

```bash
cd ~/.dotfiles/ansible
make all       # run full playbook
make check     # dry run
make dotfiles  # re-stow only
```
