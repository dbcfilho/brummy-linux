# Brummy fish
if status is-interactive
  starship init fish | source
  alias ll="ls -lh"
  alias v="nvim"
  # Terminal: nvim. Gráfico: vscodium (se instalado). Helium é o browser default (ver install.sh).
  set -gx EDITOR nvim
  if command -v codium >/dev/null 2>&1
    set -gx VISUAL codium
    alias code="codium"
  else
    set -gx VISUAL nvim
  end
  set -gx BROWSER helium-browser
  fish_add_path ~/.local/bin
end
