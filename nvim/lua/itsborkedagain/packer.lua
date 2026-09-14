-- Plugin declarations. Loaded via `require("itsborkedagain.packer")`.
--
-- After editing this file run :PackerSync
--
-- NOTE: packer.nvim has been unmaintained since Aug 2023. It still works on
-- nvim 0.11, but lazy.nvim is the maintained successor if you ever migrate.

vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- telescope fuzzy search
  -- telescope. Was pinned to tag 0.1.1 (Jan 2023), which called
  -- nvim_exec_autocmds("User TelescopeFindPre", {}) -- event and pattern in one
  -- string. Neovim tightened that validation, so every picker died with
  -- "Invalid 'event'". Fixed upstream in 0.1.8; v0.2.2 is the current release
  -- and needs nvim > 0.10.4.
  use {
    'nvim-telescope/telescope.nvim', tag = 'v0.2.2',
    requires = { { 'nvim-lua/plenary.nvim' } }
  }

  -- Colorscheme. The actual `colorscheme` call lives in
  -- after/plugin/colors.lua -- setting it here would run while the plugin
  -- spec is still being *declared*, before the plugin is on the runtimepath.
  use { 'catppuccin/nvim', as = 'catppuccin' }

  -- Statusline. catppuccin/nvim ships a first-party lualine theme, so the
  -- bar matches the colorscheme (and ghostty/tmux) without a hand-rolled
  -- palette. devicons supplies the filetype glyphs -- needs a Nerd Font,
  -- which JetBrainsMono Nerd Font Mono already is.
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons' },
  }

  -- syntax highlighting with treesitter.
  --
  -- Pinned to `main` (the v1.0 rewrite). We were on `master`, which upstream
  -- froze for nvim 0.11 -- and it is broken on 0.12. Its markdown, ruby and
  -- bash injection queries resolve the injected language through the custom
  -- `#set-lang-from-info-string!` directive, which query_predicates.lua
  -- registers with `all = false` -- an option 0.12 removed. Captures are now
  -- always TSNode LISTS, so the directive hands a plain table to
  -- get_node_text() and every parse of a fenced code block throws
  -- "attempt to call method 'range' (a nil value)" out of the highlighter.
  -- Opening any .md file with a ```lang fence hit it, including in telescope's
  -- grep preview.
  --
  -- `main` drops the directive for a plain @injection.language capture, so the
  -- failure mode cannot occur. It requires nvim 0.12+ and the tree-sitter CLI
  -- (>= 0.26.1) on PATH -- see install.sh --check. It also deleted the
  -- `nvim-treesitter.configs` module, which is why after/plugin/treesitter.lua
  -- is built around require('nvim-treesitter').install() plus a FileType
  -- autocmd calling vim.treesitter.start().
  --
  -- The run hook must live INSIDE the spec table. It used to be passed as a
  -- second argument -- `use('...', { run = ':TSUpdate' })` -- which packer
  -- silently discards, so packer_compiled.lua never registered the hook and
  -- parsers were never built.
  --
  -- It is also a FUNCTION, not the string ':TSUpdate'. packer runs the hook in
  -- the same session that just cloned the plugin, but `start/` packages only
  -- join runtimepath at STARTUP -- so plugin/nvim-treesitter.lua has not been
  -- sourced, the user command does not exist yet, and PackerSync dies with
  -- "E492: Not an editor command: TSUpdate". Putting the clone on rtp
  -- ourselves and calling the module skips the command layer entirely.
  --
  -- update() only bumps parsers whose pinned revision moved, so this is a
  -- no-op on a fresh clone -- the first install comes from the install{} call
  -- in after/plugin/treesitter.lua. It matters on every LATER sync, because
  -- parser revisions are pinned per plugin commit and must move in lockstep.
  use {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    run = function()
      vim.opt.runtimepath:append(
        vim.fn.stdpath('data') .. '/site/pack/packer/start/nvim-treesitter'
      )
      local ok, ts = pcall(require, 'nvim-treesitter')
      if not ok then
        return
      end
      ts.update():wait(300000) -- 5 min; compiling from source is not fast
    end,
  }

  -- nvim-treesitter/playground was removed here: it is archived upstream and
  -- its define_modules() call is nil against any current nvim-treesitter.
  -- nvim 0.12 ships :InspectTree and :EditQuery built in, which replace it.

  -- Harpoon plugin for navigating files
  use('theprimeagen/harpoon')

  -- undo tree
  use('mbbill/undotree')

  -- git: fugitive for blame/diff inside nvim, lazygit for committing
  use('tpope/vim-fugitive')
  use {
    'kdheepak/lazygit.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
  }

  -- LSP + completion.
  --
  -- lsp-zero was removed here: it was pinned to v2.x (Jan 2024) and drove LSP
  -- through the deprecated require('lspconfig') framework. after/plugin/lsp.lua
  -- now uses nvim 0.11's native vim.lsp.config / vim.lsp.enable instead.
  use { 'neovim/nvim-lspconfig' }
  use {
    'williamboman/mason.nvim',
    run = function() pcall(vim.cmd, 'MasonUpdate') end,
  }
  use { 'williamboman/mason-lspconfig.nvim' }

  -- Autocompletion
  use { 'hrsh7th/nvim-cmp' }
  use { 'hrsh7th/cmp-nvim-lsp' }
  use { 'hrsh7th/cmp-buffer' }
  use { 'L3MON4D3/LuaSnip' }
  use { 'saadparwaiz1/cmp_luasnip' }

end)
