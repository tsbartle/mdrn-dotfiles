# mdrn-dotfiles

Personal config for tmux, Neovim, Ghostty, lazygit and opencode. Everything is
Catppuccin Mocha. Split out from the borrowed `omerxx/dotfiles` clone in
`~/dotfiles`.

This README is written as a walkthrough: start at the top of *Setting up a new
machine* and work down. If something looks wrong afterwards, skip to
[When it goes wrong](#when-it-goes-wrong).

---

# Setting up a new machine

## 1. Install the dependencies

None of this repo installs software — `install.sh` only makes symlinks and then
tells you what's missing. So get the tools on the box first.

### macOS (Homebrew)

```bash
brew install tmux neovim git lazygit ripgrep fd node
brew install --cask ghostty font-jetbrains-mono-nerd-font
brew install anomalyco/tap/opencode

# treesitter compiles parsers from source and needs a C compiler
xcode-select --install
```

That's the whole list. The font cask matters more than it looks — see step 3.

### RHEL (dnf)

RHEL needs repo setup first, because most of these aren't in the base channels:

```bash
sudo dnf install dnf-plugins-core            # provides config-manager and copr
sudo dnf install epel-release
sudo dnf config-manager --set-enabled crb    # RHEL 9 CodeReady Builder
sudo dnf copr enable atim/lazygit            # lazygit isn't in EPEL
```

`dnf-plugins-core` goes first — without it the next two commands fail with
"No such command: config-manager", which is a confusing way to find out.

then the packages themselves:

```bash
sudo dnf install tmux git neovim ripgrep fd-find nodejs npm gcc make lazygit
sudo dnf install wl-clipboard                # Wayland — use xclip on X11
```

**If COPR is blocked** — common on locked-down or centrally-managed RHEL, where
third-party repos are disabled by policy — skip the `copr enable` line, drop
`lazygit` from the install list, and use the upstream binary instead:

```bash
LG_VER=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
         | grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo /tmp/lazygit.tar.gz \
  "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_x86_64.tar.gz"
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
install -Dm755 /tmp/lazygit ~/.local/bin/lazygit   # no sudo needed
```

`~/.local/bin` needs to be on your PATH. Everything in this repo finds lazygit
via PATH — `nvim/after/plugin/lazygit.lua` guards with `vim.fn.executable()` and
tmux's `prefix + g` popup does the same — so a user-local install works fine and
needs no root.

Three things to know before you trust that list:

- **Check `nvim --version` — this config hard-requires 0.11+.**
  `after/plugin/lsp.lua` uses `vim.lsp.config` / `vim.lsp.enable`, which simply
  don't exist earlier. EPEL's neovim has historically lagged. If it's below
  0.11, grab the upstream AppImage instead. `./install.sh --check` runs exactly
  this test for you, so you don't have to eyeball it.
- **Ghostty has no official RHEL package.** It's a macOS `.app` here. On RHEL
  you'd need a COPR or a source build — and if you're running a different
  terminal, the `ghostty/` package in this repo is just unused. Nothing else
  breaks.
- **The Nerd Font is a manual install on Linux.** No cask equivalent; see the
  Linux note in step 3.

Package names drift. If one 404s, check the current name rather than assuming
this file is right.

### Other distros

| Need | Debian/Ubuntu | Fedora | Arch |
|---|---|---|---|
| tmux, git, nvim | `tmux git neovim` | `tmux git neovim` | `tmux git neovim` |
| lazygit | release binary ▼ | `lazygit` | `lazygit` |
| C compiler (treesitter) | `build-essential` | `gcc make` | `base-devel` |
| Clipboard — X11 | `xclip` *or* `xsel` | `xclip` | `xclip` |
| Clipboard — Wayland | `wl-clipboard` | `wl-clipboard` | `wl-clipboard` |
| **ripgrep** (telescope grep) | `ripgrep` | `ripgrep` | `ripgrep` |
| fd (optional, faster find) | `fd-find` | `fd-find` | `fd` |
| Node (html + ansible LSP) | `nodejs npm` | `nodejs npm` | `nodejs npm` |
| Font | Nerd Font ▼ | same | `ttf-jetbrains-mono-nerd` |

Debian/Ubuntu ship an older Neovim — use the official appimage or the unstable
PPA. lazygit isn't in their default repos either; grab the release binary from
<https://github.com/jesseduffield/lazygit/releases>.

**ripgrep is not optional** if you use `<leader>ps`. Telescope's
`vimgrep_arguments` defaults to `rg`; without it the picker opens, finds
nothing, and closes with no error at all. `:checkhealth telescope` reports it as
a hard ERROR. On Debian/Ubuntu the `fd-find` package installs its binary as
`fdfind`, which telescope doesn't look for — symlink it to `fd` on your PATH.

## 2. Link the configs

```bash
./install.sh          # symlink everything
./install.sh --check  # just report what's missing, touch nothing
```

`install.sh` is idempotent and it backs up any real file it would clobber to
`<name>.pre-install.<timestamp>`, so re-running it is safe.

Run `./install.sh --check` again now. You want all green before moving on.

<details>
<summary>What it links, and why not stow</summary>

| Package | Lands at |
|---|---|
| `tmux` | `~/.config/tmux` |
| `ghostty` | `~/.config/ghostty` |
| `nvim` | `~/.config/nvim` |
| `opencode` | `~/.config/opencode` |
| `lazygit` | macOS: `~/Library/Application Support/lazygit/config.yml`<br>Linux: `~/.config/lazygit/config.yml` |

This repo used to carry a `.stowrc`. It's gone, and you should not run `stow`
here. Two reasons:

1. stow links each **file** individually into an existing directory;
   `install.sh` links each **package directory** as one symlink. The layouts
   aren't interchangeable, and once `~/.config/nvim` is itself a symlink into
   this repo, `stow nvim` resolves its relative link paths back *into* the
   working tree. A dry run reports zero conflicts, which makes this worse, not
   better.
2. stow can't place lazygit correctly on macOS. `.stowrc` forced
   `--target=~/.config`, but macOS lazygit reads
   `~/Library/Application Support/lazygit/`. `install.sh` has a `uname -s`
   branch for this.

Only lazygit's `config.yml` is linked, deliberately — `state.yml` in that
directory is lazygit's own runtime state and stays machine-local.
</details>

## 3. Install the font (don't skip this)

**Symptom of skipping it: tofu boxes — ▯▯▯ — everywhere icons should be.** The
tmux status bar separators, nvim's devicons, and lazygit's file tree all render
as empty rectangles, and Ghostty silently falls back to a default face because
`font-family` points at something that isn't installed.

On macOS the cask in step 1 handles it. On Linux, download JetBrainsMono from
<https://github.com/ryanoasis/nerd-fonts/releases>, unzip into
`~/.local/share/fonts/`, then `fc-cache -fv`.

Unzip the **whole** archive, not just the `*NerdFontMono-*.ttf` files.
`ghostty/config` sets `font-family` to the *Mono* face for text, but maps the
icon codepoints to the plain `JetBrainsMono Nerd Font` face — the Mono variant
squashes every icon to exactly one cell with zero side bearing, which looks
cramped. Both faces must be present or the icons fall back to Mono and render
squashed. The long comment in `ghostty/config` has the measurements.

Check it worked:

```bash
ghostty +list-fonts | grep -i jetbrains   # expect Mono and non-Mono
fc-list | grep -i jetbrains               # Linux
```

Then reload Ghostty's config with <kbd>cmd</kbd>+<kbd>shift</kbd>+<kbd>,</kbd>,
or just restart it.

## 4. Bring up tmux

`tmux/plugins/` is gitignored, so plugins are fetched per-machine. `install.sh`
already cloned tpm for you in step 2 — you just need to let it pull the rest:

```bash
tmux
```

Now press <kbd>C-a</kbd> then <kbd>I</kbd> (capital i). tpm fetches the ten
declared plugins — sensible, yank, resurrect, continuum, thumbs, fzf, fzf-url,
catppuccin, sessionx, floax. You'll know it worked when the status bar grows its
rounded Catppuccin pills.

Prefix is <kbd>C-a</kbd>, not <kbd>C-b</kbd>.

**If <kbd>C-a</kbd> <kbd>I</kbd> appears to do nothing at all** — no popup, no
error — tpm didn't load. That binding is created *by tpm*, so its absence means
`run '~/.config/tmux/plugins/tpm/tpm'` (tmux.conf line 199) found nothing:

```bash
ls -la ~/.config/tmux/plugins/tpm/tpm   # should exist
tmux list-keys | grep -w I              # should show a binding
./install.sh                            # re-clones tpm if it's missing
tmux kill-server && tmux
```

Don't clone tpm into `~/.config/tmux/` by hand *before* running `install.sh` —
while that path is still a real directory, the link step moves the whole thing to
`~/.config/tmux.pre-install.<timestamp>`, tpm included. `install.sh` clones it
after linking for exactly this reason.

## 5. Bring up Neovim

Bootstrap packer, then sync:

```bash
# 1. bootstrap the plugin manager
git clone --depth 1 https://github.com/wbthomason/packer.nvim \
  ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# 2. fetch every plugin in lua/itsborkedagain/packer.lua
nvim +PackerSync

# 3. compile the treesitter parsers (needs the C compiler from the deps step)
nvim +TSUpdateSync
```

The first launch warns about missing plugins — that's expected. `+PackerSync`
opens a progress window; let it finish and `:q` out. `+TSUpdateSync` is the
synchronous variant of `:TSUpdate`, so it blocks until every parser is built
rather than returning immediately — that's what you want in a setup script.

Then open nvim and run `:Mason` to confirm `ansiblels`, `html` and `lua_ls`
installed.

Finally, the real test:

```bash
nvim --headless "+qa"      # expect NO output whatsoever
```

Any output here is a config error, not a warning. See below.

## 6. One thing that lives outside this repo

`~/.zshrc` needs to export `EDITOR='nvim'`. opencode's `/editor` command
(`<leader>e`, leader = <kbd>ctrl+o</kbd>) opens the current prompt in `$EDITOR`;
without the export it falls back to plain `vi`. That export is the only piece of
this setup not tracked here.

---

# When it goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| Tofu boxes ▯ instead of icons | Nerd Font not installed, or only the Mono face | Step 3 — install **both** faces |
| `module 'nvim-treesitter.configs' not found` | treesitter on the wrong branch | See below |
| `attempt to call field 'define_modules'` | archived `playground` plugin | Remove it; nvim 0.12 has `:InspectTree` |
| Telescope grep finds nothing, no error | `rg` missing | Install ripgrep |
| `<leader>y` doesn't reach the system clipboard | no clipboard provider on Linux | See below |
| nvim LSP errors about `vim.lsp.config` | Neovim older than 0.11 | Upgrade; `./install.sh --check` tests this |
| cmd+s / cmd+b do nothing in Ghostty | those keybinds were never in this config | Add them to `ghostty/config` if you want them |
| tmux ignores `~/.config/tmux/tmux.conf` | tmux not searching the XDG path | See below |
| `prefix + I` does nothing, no error | tpm not loaded | Step 4 — check the `run` line's path |

## The treesitter branch trap

This is the one that will bite you on a fresh machine, and it bit this repo
already.

nvim-treesitter flipped its **default branch** from `master` to `main` — the
v1.0 rewrite, which deleted the entire `nvim-treesitter.configs` module that
`after/plugin/treesitter.lua` is built around. An unpinned clone on a new
machine therefore installs `main` and throws on every single startup, while your
old machine keeps working because its clone predates the flip.

`lua/itsborkedagain/packer.lua` now pins `branch = 'master'` explicitly. If you
ever see those errors again, check what you actually have:

```bash
git -C ~/.local/share/nvim/site/pack/packer/start/nvim-treesitter \
    rev-parse --abbrev-ref HEAD        # must print: master
```

Changing `branch` in the spec does **not** re-checkout an existing clone. You
have to delete it and re-sync:

```bash
rm -rf ~/.local/share/nvim/site/pack/packer/start/nvim-treesitter
rm -f  ~/.config/nvim/plugin/packer_compiled.lua   # gitignored, regenerates
nvim +PackerSync
nvim +TSUpdateSync
```

Moving to `main` some day means rewriting `treesitter.lua` around
`require('nvim-treesitter').install()` plus a `FileType` autocmd calling
`vim.treesitter.start()`. It is not a drop-in swap.

## tmux can't find the config on RHEL

Seen on RHEL 9 with tmux 3.3a: the config sits at `~/.config/tmux/tmux.conf` and
tmux ignores it completely, starting with stock defaults instead. Ask tmux what
it actually loaded:

```bash
tmux display -p '#{config_files}'
```

If that prints `~/.tmux.conf` — especially when no such file exists — tmux never
had the XDG path in its search list. XDG support arrived upstream in tmux 3.1,
but whether a given build looks there can also depend on `XDG_CONFIG_HOME` being
set, and it is unset by default on RHEL. Test which case you're in:

```bash
XDG_CONFIG_HOME=$HOME/.config tmux kill-server
XDG_CONFIG_HOME=$HOME/.config tmux
```

The version-proof fix is a one-line shim at the old path, which works regardless
of the cause and regardless of tmux version:

```bash
printf 'source-file ~/.config/tmux/tmux.conf\n' > ~/.tmux.conf
tmux kill-server && tmux
```

Prefer that over exporting `XDG_CONFIG_HOME` in your shell profile — the env var
fixes tmux but changes lookup behaviour for every other XDG-aware tool on the
box, which is a much wider blast radius for one config file.

`tmux kill-server` matters: tmux reads its config once at server start, so
`source-file` on a running server layers new settings over the old ones instead
of resetting them.

## Clipboard on Linux

The one portability problem that actually bites. On macOS both tmux and nvim
reach the clipboard through `pbcopy`, which is always there. Linux has no
equivalent and **nothing is installed by default**:

- **tmux** — `tmux-yank` looks for `xclip`, `xsel`, or `wl-copy`. With none of
  them, `prefix + y` and copy-mode `y` copy to the tmux buffer only, silently.
- **nvim** — `<leader>y` / `<leader>Y` map to the `+` register, which needs the
  same programs. `:checkhealth provider` reports what it found.

Install `wl-clipboard` on Wayland, `xclip` or `xsel` on X11, both on a mixed
setup. `set -g set-clipboard on` in `tmux.conf` also gives you OSC 52
passthrough, which works over SSH in Ghostty regardless.

## Ghostty options that do nothing on Linux

Ghostty ignores options it can't honour rather than erroring, so the shared
config file works as-is. Two lines are inert:

| Line | On Linux |
|---|---|
| `macos-option-as-alt = true` | No effect, macOS-only by definition. |
| `background-blur-radius = 20` | KDE/KWin **only**, and needs KWin's Blur desktop effect enabled in System Settings. Ignored on GNOME and everything else. |

`background-blur-radius` is also the **legacy spelling** — current Ghostty calls
it `background-blur` and accepts the old name as an alias (`ghostty
+show-config` prints it back as `background-blur = 20`). Kept as-is for older
builds; rename it if the alias ever drops.

`window-padding-x/y`, `window-decoration`, the theme and the font all behave the
same on both platforms.

---

# Reference

## Layout

| Package | Holds |
|---|---|
| `tmux` | `tmux.conf`, `tmux.reset.conf` |
| `ghostty` | `config`, `shaders/` |
| `nvim` | packer-based config under `lua/itsborkedagain/` |
| `opencode` | `opencode.json`, `tui.json`, `agent/`, `command/`, `skills/` |
| `lazygit` | `config.yml` — Catppuccin Mocha theme |

`ghostty/shaders/space.glsl` is present but **dormant** — there's no
`custom-shader =` line in the config. Add one if you want it.

## Theme

Everything is Catppuccin **Mocha**, so the palette is shared across the stack:

- ghostty — `theme = Catppuccin Mocha`
- tmux — `catppuccin/tmux` plugin
- nvim — `catppuccin/nvim`, flavour mocha (`after/plugin/colors.lua`)
- opencode — `"theme": "catppuccin"` in `opencode/tui.json`
- lazygit — hex values in `lazygit/config.yml`

## nvim

Packer-based — run `:PackerSync` after editing
`lua/itsborkedagain/packer.lua`. Plugins live in
`~/.local/share/nvim/site/pack/packer/`, never in this repo.

### LSP

Uses Neovim 0.11's **native** LSP API — `vim.lsp.config` / `vim.lsp.enable` —
with `mason-lspconfig` v2 auto-enabling anything mason has installed.
`nvim-lspconfig` is present purely as the *data* source for per-server configs
(`lsp/*.lua`), not as a framework.

`lsp-zero` was removed. It was pinned to v2.x (Jan 2024), drove everything
through the deprecated `require('lspconfig')` framework, and printed a
deprecation traceback on every buffer open. `nvim-lspconfig` v3.0.0 removes that
API entirely.

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

### editing prompts in nvim

`/editor` (bound to `<leader>e`, leader = <kbd>ctrl+o</kbd>) opens the current
prompt in `$EDITOR`, so you can compose and submit from a real buffer. Needs the
`~/.zshrc` export from step 6.

### lazygit

opencode cannot do it. Its `tui.json` keybind schema defines 184 actions and
none of them run a shell command or launch an external TUI — it's an open
upstream request (anomalyco/opencode#7337). The `!cmd` prompt prefix only pipes
output into the conversation as a tool result; it can't host an interactive
program.

So the binding lives in tmux instead: **`prefix + g`** opens lazygit in a
floating popup rooted at the pane's cwd. tmux intercepts the prefix before
opencode sees it, so it works from inside an opencode session and everywhere
else. `terminal_suspend` is also bound to <kbd>ctrl+z</kbd> if you'd rather
suspend and `fg`.

nvim has its own lazygit bindings (`<leader>gg` et al, above) — separate
integration, unaffected.

## tmux

- Theme and plugin set from the borrowed config; keybindings and behaviour from
  the old `~/tmux.conf.old`. `tmux.reset.conf` owns the prefix and every
  binding, and deliberately leaves stock tmux defaults intact.
- The blank row under the status bar is `status 2` + empty `status-format[1]`.
  The gap *below* the prompt is not tmux — it's `window-padding-y = 12,28` in
  the ghostty config.
- `@sessionx-custom-paths` / `@sessionx-x-path` hardcode `$HOME/mdrn-dotfiles`.
  sessionx word-splits that value straight into `find` with no shell expansion,
  so it needs an absolute path — **if you clone this repo anywhere else, update
  those two lines.**
