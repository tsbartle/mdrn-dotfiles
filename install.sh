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

# --- tpm ----------------------------------------------------------------------
# tpm lives INSIDE the tmux package (tmux/plugins/tpm, gitignored), so it has to
# be cloned per machine. It is cloned HERE, after the symlink above, on purpose:
# if you clone it into ~/.config/tmux while that is still a real directory, the
# link step moves the whole directory -- tpm included -- to
# ~/.config/tmux.pre-install.<timestamp>, and tmux.conf's `run` line then points
# at nothing. The symptom is silent: prefix + I does nothing at all, because the
# I binding is created by tpm itself and tpm never loaded. Cloning it here makes
# that ordering impossible to get wrong.
TPM_DIR="$REPO/tmux/plugins/tpm"
if [ -e "$TPM_DIR/tpm" ]; then
  echo "ok      tpm (already cloned)"
elif command -v git >/dev/null 2>&1; then
  echo "clone   tpm -> tmux/plugins/tpm"
  git clone --depth 1 -q https://github.com/tmux-plugins/tpm "$TPM_DIR" \
    || echo "warn    tpm clone failed -- check network, then re-run"
else
  echo "warn    tpm not cloned (git not on PATH)"
fi
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

  # nvim must be 0.12+ for nvim-treesitter `main`, which hard-errors below it.
  # (0.11 would still satisfy the native vim.lsp.config API in after/plugin/lsp.lua.)
  if have nvim; then
    local v; v="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+')"
    if [ "$(printf '%s\n0.12\n' "$v" | sort -V | head -1)" = "0.12" ]; then
      report "nvim version" ok "$v (>= 0.12)"
    else
      report "nvim version" warn "$v -- treesitter 'main' needs 0.12+, lsp.lua needs 0.11+"
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

  # nvim-treesitter `main` compiles EVERY parser via `tree-sitter build`, so a
  # missing CLI means no highlighting at all -- not a degraded experience.
  # NOTE: the homebrew/distro `tree-sitter` package is the library neovim links
  # against and ships no binary; the CLI is a separate `tree-sitter-cli`.
  if have tree-sitter; then
    local tsv; tsv="$(tree-sitter --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    if [ "$(printf '%s\n0.26.1\n' "$tsv" | sort -V | head -1)" = "0.26.1" ]; then
      report "tree-sitter CLI" ok "$tsv ($(command -v tree-sitter))"
    else
      report "tree-sitter CLI" warn "$tsv -- below upstream's 0.26.1; usually still builds, check :TSLog"
    fi
  else
    report "tree-sitter CLI" warn "missing -- parsers cannot build; see README (NOT npm)"
  fi

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
    report "tpm" warn "re-run ./install.sh (it clones tpm), then: prefix + I"
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
