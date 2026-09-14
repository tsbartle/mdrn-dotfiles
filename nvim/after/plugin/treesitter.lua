-- nvim-treesitter `main`. This is a full rewrite of the plugin, not a version
-- bump: `require('nvim-treesitter.configs').setup{}` is gone, and with it
-- `ensure_installed`, `sync_install`, `auto_install` and the `highlight`
-- module. Parsers are installed imperatively, and treesitter features are
-- turned on per-buffer by us. See lua/itsborkedagain/packer.lua for why we
-- left `master`.
local ok, ts = pcall(require, 'nvim-treesitter')
if not ok then
  vim.notify('nvim-treesitter not installed -- run :PackerSync', vim.log.levels.WARN)
  return
end

-- Deliberately not just `if not ok`. On `master` the require SUCCEEDS -- its
-- lua/nvim-treesitter.lua exports only define_modules and statusline -- so a
-- clone that hasn't been re-synced since we flipped the branch would sail past
-- the check above and then die on `ts.install` being nil. Changing `branch` in
-- the packer spec does not re-checkout an existing clone; you have to delete it.
if type(ts.install) ~= 'function' then
  vim.notify(
    'nvim-treesitter is still on `master` (no install()). Fix:\n'
      .. '  rm -rf ~/.local/share/nvim/site/pack/packer/start/nvim-treesitter\n'
      .. '  rm -f  ~/.config/nvim/plugin/packer_compiled.lua\n'
      .. '  nvim +PackerSync',
    vim.log.levels.WARN
  )
  return
end

-- No setup() call: install_dir defaults to stdpath('data')/site, which is
-- already on runtimepath and is the same tree packer installs into. Parsers
-- land in .../site/parser/, queries in .../site/queries/.

-- Replaces `ensure_installed`. Runs async and is a no-op once the parsers are
-- present, so the cost is only paid on a fresh machine. `markdown` is listed
-- explicitly -- it used to arrive via `auto_install`, which no longer exists.
ts.install {
  'python',
  'html',
  'dockerfile',
  'htmldjango',
  'c',
  'lua',
  'vim',
  'vimdoc',
  'query',
  'ruby',
  'yaml',
  'markdown',
}

-- Replaces `highlight = { enable = true }` plus `auto_install = true`.
-- Wildcard so any installed parser highlights without editing this file; the
-- pcall is what makes that safe, since filetypes with no parser just fall back
-- to regex syntax instead of erroring.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('itsborkedagain_treesitter', { clear = true }),
  pattern = '*',
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
