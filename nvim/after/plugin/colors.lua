-- Catppuccin Mocha, matching the Ghostty theme and the tmux status bar.
--
-- This lives in after/plugin (not packer.lua) because the colorscheme can only
-- be applied once the plugin is actually on the runtimepath. The old config
-- called vim.cmd('colorscheme rose-pine') from inside the packer startup
-- function, i.e. while the plugin list was still being declared.

local ok, catppuccin = pcall(require, "catppuccin")
if not ok then
  vim.notify("catppuccin not installed -- run :PackerSync", vim.log.levels.WARN)
  return
end

catppuccin.setup({
  flavour = "mocha",          -- matches `theme = Catppuccin Mocha` in ghostty
  background = { light = "latte", dark = "mocha" },
  transparent_background = false,
  term_colors = true,
  integrations = {
    treesitter = true,
    telescope = { enabled = true },
    harpoon = true,
    mason = true,
    native_lsp = { enabled = true },
    cmp = true,
    fidget = false,
    notify = false,
  },
})

-- pcall so a failed colorscheme never aborts the rest of startup
local applied = pcall(vim.cmd.colorscheme, "catppuccin-mocha")
if not applied then
  vim.notify("could not apply catppuccin-mocha", vim.log.levels.WARN)
end
