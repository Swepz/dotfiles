export PATH="$HOME/.local/bin:$PATH"
export GPG_TTY=$(tty)

# opencode
fish_add_path /home/swepz/.opencode/bin

set -gx PNPM_HOME "/home/swepz/.local/share/pnpm"
if not string match -q -- "$PNPM_HOME/bin" $PATH
  set -gx PATH "$PNPM_HOME/bin" $PATH
end

set -q XDG_RUNTIME_DIR; or set -gx XDG_RUNTIME_DIR /run/user/(id -u)
