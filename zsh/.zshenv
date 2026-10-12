typeset -U path PATH
export PNPM_HOME="$HOME/.local/share/pnpm"
path=("$HOME/.local/bin" "$HOME/.cargo/bin" /usr/lib/ccache/bin "$PNPM_HOME/bin" $path)
export EDITOR=nvim
export IDADIR="$HOME/.local/opt/ida-9.4"
export IDAPYTHON_VENV_EXECUTABLE="$HOME/.local/opt/ida-venv/bin/python"
set -a
for env_file in "$HOME"/.config/environment.d/*.conf; do
  source "$env_file"
done
unset env_file
set +a
