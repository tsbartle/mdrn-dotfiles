-- Statusline: mode, git branch, file, diagnostics, position.
--
-- Same reasoning as colors.lua -- this lives in after/plugin so it runs once
-- lualine is actually on the runtimepath, not while packer is still declaring
-- the plugin list.
--
-- The theme ships with catppuccin/nvim itself, so it tracks the flavour set in
-- colors.lua instead of hardcoding hex values. The name is "catppuccin-nvim",
-- NOT "catppuccin" -- the plain name was the old spelling and now resolves to
-- nothing, which lualine reports via :LualineNotices (not :messages) while
-- silently falling back to "auto". "catppuccin-nvim" follows whatever flavour
-- is active; "catppuccin-mocha" would pin it and ignore the light/dark swap.

local ok, lualine = pcall(require, "lualine")
if not ok then
  vim.notify("lualine not installed -- run :PackerSync", vim.log.levels.WARN)
  return
end

-- lualine renders the mode, so vim's own "-- INSERT --" is just a duplicate
-- on the line below.
vim.opt.showmode = false

lualine.setup({
  options = {
    theme = "catppuccin-nvim",
    icons_enabled = true,
    -- Powerline glyphs; safe given the Nerd Font. Swap to "" for plain.
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
    -- One bar for the whole window instead of one per split. Needs
    -- laststatus=3, which lualine sets for us.
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    -- path = 1 -> relative to cwd. 0 = name only, 3 = absolute.
    lualine_c = {
      { "filename", path = 1, symbols = { modified = " ●", readonly = " " } },
    },
    lualine_x = { "diagnostics", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  -- Dimmed copy of the above for splits that aren't focused.
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  extensions = { "fugitive", "lazy" },
})
