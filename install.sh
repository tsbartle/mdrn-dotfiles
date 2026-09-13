#!/usr/bin/env bash
# Symlink this repo's packages into place. This is THE installer -- there is no
# stow path any more and the .stowrc that used to sit beside this file is gone.
#
# Why not stow: stow links each FILE individually into an existing directory,
# while this links each PACKAGE DIRECTORY as a single symlink. The two layouts
# are not interchangeable, and once ~/.config/nvim is itself a symlink into this
# repo, `stow nvim` resolves its relative link paths back INTO the working tree.
# stow also cannot place lazygit correctly on macOS (see below). Run this script.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {  # link <source> <destination>
  local src="$1" dst="$2" name="$3"
  if [ -L "$dst" ]; then
    local current; current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then echo "ok      $name (already linked)"; return; fi
    echo "relink  $name (was -> $current)"
    rm "$dst"
  elif [ -e "$dst" ]; then
    if [ -s "$dst" ]; then
      local backup="$dst.pre-install.$(date +%Y%m%d-%H%M%S)"
      echo "backup  $name -> $(basename "$backup")"
      mv "$dst" "$backup"
    else
      echo "replace $name (existing file was empty)"
      rm "$dst"
    fi
  else
    echo "link    $name"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
}

if [ "${1:-}" = "--check" ]; then
  # jump straight to the dependency report without touching any symlinks
  :
else
# --- XDG packages -> ~/.config/<pkg> ------------------------------------------
for pkg in tmux ghostty nvim opencode; do
  link "$REPO/$pkg" "$HOME/.config/$pkg" "$pkg"
done

# --- lazygit ------------------------------------------------------------------
# lazygit does NOT use ~/.config on macOS; it uses
# ~/Library/Application Support/lazygit. Only config.yml is linked -- state.yml
# in that directory is lazygit's own runtime state and must stay local.
case "$(uname -s)" in
  Darwin) LG_DIR="$HOME/Library/Application Support/lazygit" ;;
  *)      LG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit" ;;
esac
link "$REPO/lazygit/config.yml" "$LG_DIR/config.yml" "lazygit/config.yml"
fi


# --- dependency check ---------------------------------------------------------
check_deps() {
  local missing=0
  have() { command -v "$1" >/dev/null 2>&1; }
  report() { # report <label> <ok|warn> <detail>
    case "$2" in
      ok)   printf '  \033[32m ok \033[0m %-22s %s\n' "$1" "$3" ;;
      warn) printf '  \033[33mwarn\033[0m %-22s %s\n' "$1" "$3"; missing=1 ;;
    esac
  }

  echo
  echo "dependencies:"

  for c in tmux nvim git lazygit; do
    have "$c" && report "$c" ok "$(command -v "$c")" \
               || report "$c" warn "not on PATH"
  done

  # nvim must be 0.11+ for the native vim.lsp.config API in after/plugin/lsp.lua
  if have nvim; then
    local v; v="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+')"
    if [ "$(printf '%s\n0.11\n' "$v" | sort -V | head -1)" = "0.11" ]; then
      report "nvim version" ok "$v (>= 0.11)"
    else
      report "nvim version" warn "$v -- lsp.lua needs 0.11+"
    fi
  fi

  # telescope: rg is required for grep pickers, fd is an optional speedup
  have rg && report "ripgrep (rg)" ok "$(command -v rg)" \
          || report "ripgrep (rg)" warn "telescope <leader>ps / live_grep need it"
  have fd || have fdfind && report "fd" ok "$(command -v fd || command -v fdfind)" \
          || report "fd" warn "optional -- speeds up telescope find_files"

  # treesitter compiles parsers from source
  have cc || have gcc && report "C compiler" ok "$(command -v cc || command -v gcc)" \
                      || report "C compiler" warn "needed for :TSUpdate"

  # clipboard: pbcopy on macOS, one of three on Linux
  case "$(uname -s)" in
    Darwin)
      have pbcopy && report "clipboard" ok "pbcopy" || report "clipboard" warn "pbcopy missing?!"
      ;;
    *)
      if have wl-copy;   then report "clipboard" ok "wl-copy (wayland)"
      elif have xclip;   then report "clipboard" ok "xclip (x11)"
      elif have xsel;    then report "clipboard" ok "xsel (x11)"
      else report "clipboard" warn "install wl-clipboard, xclip or xsel -- tmux-yank and nvim \"+y need one"
      fi
      ;;
  esac

  # tpm is fetched per-machine; tmux/plugins is gitignored
  if [ -d "$HOME/.config/tmux/plugins/tpm" ]; then
    report "tpm" ok "installed"
  else
    report "tpm" warn "git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm"
  fi

  if [ -d "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim" ]; then
    report "packer.nvim" ok "installed"
  else
    report "packer.nvim" warn "see README -> Running this on Linux -> nvim notes"
  fi

  [ "$missing" -eq 0 ] && echo "  all good." || echo "  ^ see README for install commands."
}

if [ "${1:-}" = "--check" ]; then check_deps; exit 0; fi
check_deps
echo
echo "done."
