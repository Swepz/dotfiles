typeset -U path PATH
export PNPM_HOME="$HOME/.local/share/pnpm"
path=("$HOME/.local/bin" "$HOME/.cargo/bin" /usr/lib/ccache/bin "$PNPM_HOME/bin" $path)
export EDITOR=nvim
export IDADIR="$HOME/.local/opt/ida-9.4"
export IDAPYTHON_VENV_EXECUTABLE="$HOME/.local/opt/ida-venv/bin/python"
set -a
source "$HOME/.config/environment.d/50-api-keys.conf"
set +a
