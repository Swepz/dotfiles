.PHONY: all check dotfiles

all:
	ansible-playbook site.yml -K

check:
	ansible-playbook site.yml --check --diff -K

dotfiles:
	ansible-playbook site.yml --tags "dotfiles" -K
