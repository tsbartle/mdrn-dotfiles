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
  -- Pinned to master. Upstream flipped the DEFAULT branch to `main` (the v1.0
  -- rewrite), which deleted the entire `nvim-treesitter.configs` module that
  -- after/plugin/treesitter.lua drives -- so an unpinned clone on a fresh
  -- machine installs main and every startup throws
  -- "module 'nvim-treesitter.configs' not found". master is maintenance-mode
  -- but stable on 0.12. If you ever move to main, treesitter.lua has to be
  -- rewritten around require('nvim-treesitter').install() plus a FileType
  -- autocmd calling vim.treesitter.start().
  --
  -- The run hook must live INSIDE the spec table. It used to be passed as a
  -- second argument -- `use('...', { run = ':TSUpdate' })` -- which packer
  -- silently discards, so packer_compiled.lua never registered the hook and
  -- parsers were never built.
  use {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    run = ':TSUpdate',
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
