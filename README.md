# tsbartle-dotfiles

Personal config, split out from the borrowed `omerxx/dotfiles` clone in `~/dotfiles`.

## Layout

| Package   | Links to                                           | Holds                                      |
|-----------|----------------------------------------------------|--------------------------------------------|
| `tmux`    | `~/.config/tmux`                                   | `tmux.conf`, `tmux.reset.conf`, `scripts/` |
| `ghostty` | `~/.config/ghostty`                                | `config`, `shaders/`                       |
| `nvim`    | `~/.config/nvim`                                   | packer-based config, `itsborkedagain/`     |
| `opencode`| `~/.config/opencode`                               | `opencode.json`, `tui.json`, `agent/`, `command/`, `skills/` |
| `lazygit` | macOS: `~/Library/Application Support/lazygit/config.yml`<br>Linux: `~/.config/lazygit/config.yml` | Catppuccin Mocha theme |

## Install

```bash
./install.sh          # symlink everything
./install.sh --check  # only report missing dependencies
```

`stow` is not installed here, so `install.sh` uses `ln -s`. `.stowrc` targets
`~/.config`, so `stow .` would cover tmux/ghostty/nvim — **but not lazygit**,
whose path differs per platform (see above). Only `config.yml` is linked there;
`state.yml` in that directory is lazygit's runtime state and stays local.

## Theme

Everything is Catppuccin **Mocha**, so the palette is shared across the stack:

- ghostty — `theme = Catppuccin Mocha`
- tmux — `catppuccin-tmux` plugin
- nvim — `catppuccin/nvim`, flavour `mocha` (`after/plugin/colors.lua`)
- opencode — `"theme": "catppuccin"` in `opencode/tui.json` (built-in theme)
- lazygit — hex values in `lazygit/config.yml`

---

# Running this on Linux

The configs themselves are portable — everything uses `~`/XDG paths and no
Homebrew prefixes are hardcoded. What differs is **where lazygit looks for its
config**, **how the clipboard works**, and **which Ghostty options do anything**.
`install.sh` handles the first automatically; the rest is below.

## 1. Packages to install

| Need | Debian/Ubuntu | Fedora | Arch |
|---|---|---|---|
| tmux, git, nvim | `tmux git neovim` | `tmux git neovim` | `tmux git neovim` |
| lazygit | see note ▼ | `lazygit` | `lazygit` |
| C compiler (treesitter) | `build-essential` | `gcc make` | `base-devel` |
| Clipboard — X11 | `xclip` *or* `xsel` | `xclip` | `xclip` |
| Clipboard — Wayland | `wl-clipboard` | `wl-clipboard` | `wl-clipboard` |
| **ripgrep** (telescope grep) | `ripgrep` | `ripgrep` | `ripgrep` |
| fd (optional, faster find) | `fd-find` | `fd-find` | `fd` |
| Node (html LSP, ansible LSP) | `nodejs npm` | `nodejs npm` | `nodejs npm` |
| Font | JetBrainsMono Nerd Font ▼ | same | `ttf-jetbrains-mono-nerd` |

**Neovim must be 0.11+.** `after/plugin/lsp.lua` uses `vim.lsp.config` /
`vim.lsp.enable`, which do not exist before 0.11. Debian/Ubuntu ship older
Neovim — use the official appimage or the unstable PPA.

**lazygit on Debian/Ubuntu** is not in the default repos; grab the release
binary from <https://github.com/jesseduffield/lazygit/releases>.

**Nerd Font**: download JetBrainsMono from
<https://github.com/ryanoasis/nerd-fonts/releases>, unzip into
`~/.local/share/fonts/`, then `fc-cache -fv`. Without it the tmux status bar
separators and lazygit icons render as boxes.

**ripgrep is not optional** if you use `<leader>ps`. Telescope's
`vimgrep_arguments` defaults to `rg`; without it the picker opens, finds
nothing, and closes without an error message. `:checkhealth telescope` reports
it as a hard ERROR. On Debian/Ubuntu the `fd-find` binary installs as `fdfind`,
which telescope does not look for — symlink it to `fd` on your PATH.

## 2. Clipboard — the one thing that will actually bite you

On macOS both tmux and nvim reach the clipboard through `pbcopy`, which is
always present. On Linux there is no equivalent, so **nothing is installed by
default**:

- **tmux** — `tmux-yank` looks for `xclip`, `xsel`, or `wl-copy`. With none of
  them, `prefix + y` and copy-mode `y` silently copy to the tmux buffer only.
- **nvim** — `<leader>y` / `<leader>Y` map to the `+` register, which needs the
  same programs. `:checkhealth provider` will tell you what it found.

Install `wl-clipboard` on Wayland, `xclip` (or `xsel`) on X11. On a mixed
setup install both. `set -g set-clipboard on` in `tmux.conf` also gives you
OSC 52 passthrough, which works over SSH in Ghostty regardless.

## 3. Ghostty options that are macOS-only

`ghostty/config` is shared, and Ghostty ignores options it can't honour rather
than erroring — so the file works as-is. But two lines do nothing on Linux:

| Line | On Linux |
|---|---|
| `macos-option-as-alt = true` | No effect (macOS-only by definition). |
| `background-blur-radius = 20` | Supported **only on KDE/KWin**, and it needs KWin's own Blur desktop effect enabled in System Settings. Ignored on GNOME and everything else. |

`background-blur-radius` is also the **legacy spelling** — current Ghostty
renamed it to `background-blur` and accepts the old name as an alias
(`ghostty +show-config` prints it back as `background-blur = 20`). Kept as-is
for compatibility with older Ghostty builds; rename it if the alias ever drops.

`window-padding-x/y`, `window-decoration`, the theme and the font all behave
the same on both platforms.

## 4. tmux notes for Linux

The config is portable, but on a fresh machine tpm isn't installed:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
tmux && tmux source ~/.config/tmux/tmux.conf   # then press: prefix + I
```

`tmux/plugins/` is gitignored, so plugins are always fetched per-machine.
`prefix` is `C-a`. Nothing in `tmux.conf` is macOS-specific — the
`status-position top` comment says "macOS / darwin style" but it is only a
preference and works anywhere.

## 5. nvim notes for Linux

First launch will warn about missing plugins. Bootstrap packer, then sync:

```bash
git clone --depth 1 https://github.com/wbthomason/packer.nvim \
  ~/.local/share/nvim/site/pack/packer/start/packer.nvim
nvim +PackerSync
```

Then, inside nvim, `:TSUpdateSync` to compile treesitter parsers (needs the C
compiler from the table above) and `:Mason` to confirm the three language
servers installed.

---

## nvim

Packer-based (`:PackerSync` after editing `lua/itsborkedagain/packer.lua`).
Plugins live in `~/.local/share/nvim/site/pack/packer/`, not in this repo.

### LSP

Uses Neovim 0.11's **native** LSP API — `vim.lsp.config` / `vim.lsp.enable` —
with `mason-lspconfig` v2 auto-enabling anything mason has installed.
`nvim-lspconfig` is present purely as the *data* source for per-server configs
(`lsp/*.lua`), not as a framework.

`lsp-zero` was removed. It was pinned to v2.x (Jan 2024), drove everything
through the deprecated `require('lspconfig')` framework, and printed a
deprecation traceback on every buffer open. `nvim-lspconfig` v3.0.0 removes
that API entirely.

Servers in `ensure_installed`: `ansiblels`, `html`, `lua_ls`.

### git workflow

| Key | Does |
|---|---|
| `<leader>gg` | lazygit, floating, at repo root |
| `<leader>gf` | lazygit filtered to commits touching the file |
| `<leader>gc` | lazygit current-file history |
| `<leader>gs` | vim-fugitive `:Git` status |

Buffers are written (`:wall`) before lazygit opens so it sees current state.

## opencode

`~/.config/opencode` is symlinked by `install.sh` like the other XDG packages.
opencode itself is **not installed on this machine** — `brew install anomalyco/tap/opencode`
or see <https://opencode.ai/docs/>.

### editing prompts in nvim

`/editor` (bound to `<leader>e`, leader = `ctrl+o`) opens the current prompt in
`$EDITOR` so you can compose and submit from a real buffer. `~/.zshrc` exports
`EDITOR='nvim'`; **without it opencode falls back to plain `vi`.** That export
is the one piece of this that lives outside the repo.

### lazygit

opencode cannot do it. Its `tui.json` keybind schema defines 184 actions and
none of them run a shell command or launch an external TUI — it's an open
upstream request (anomalyco/opencode#7337). The `!cmd` prompt prefix only pipes
output into the conversation as a tool result; it can't host an interactive
program.

So the binding lives in tmux instead: **`prefix + g`** opens lazygit in a
floating popup rooted at the pane's cwd. tmux intercepts the prefix before
opencode sees it, so it works from inside an opencode session (and everywhere
else). `terminal_suspend` is also bound to `ctrl+z` if you'd rather suspend and
`fg`.

Note nvim has its own lazygit bindings (`<leader>gg` et al, see above) — those
are a separate integration and unaffected.

## tmux

- Theme and plugin set from the borrowed config; keybindings and behaviour from
  the old `~/tmux.conf.old`. `tmux.reset.conf` owns the prefix and every
  binding, and deliberately leaves stock tmux defaults intact.
- The blank row under the status bar is `status 2` + empty `status-format[1]`.
  The gap *below* the prompt is not tmux — it's `window-padding-y = 12,28` in
  the ghostty config.
