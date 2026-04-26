# -----------------------------------------------------
# CUSTOMIZATION
# -----------------------------------------------------

# -----------------------------------------------------
# Prompt
# -----------------------------------------------------
# Previous oh-my-posh config (replaced with Starship):
# eval "$($HOME/.local/bin/oh-my-posh init fish --config $HOME/.config/ohmyposh/zen.toml)"
# eval "$($HOME/.local/bin/oh-my-posh init fish --config $HOME/.config/ohmyposh/EDM115-newline.omp.json)"

# -----------------------------------------------------
# Colored man pages
# -----------------------------------------------------
set -x MANPAGER "less -R --use-color -Dd+r -Du+b"
set -x MANROFFOPT "-P -c"

export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1
export IS_DEMO=1
export CLAUDE_CODE_HIDE_ACCOUNT_INFO=1
