-- lazygit.nvim -- opens the lazygit TUI in a floating window inside nvim, so
-- you can stage/commit/push without leaving the editor. lazygit itself is
-- already installed (homebrew, /opt/homebrew/bin/lazygit).
--
-- Buffer changes are written before opening so lazygit sees current state.

if vim.fn.executable("lazygit") == 0 then
  vim.notify("lazygit not found on PATH", vim.log.levels.WARN)
  return
end

-- Float sizing (read by lazygit.nvim at open time)
vim.g.lazygit_floating_window_scaling_factor = 0.9
vim.g.lazygit_floating_window_border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
vim.g.lazygit_floating_window_use_plenary = 0
vim.g.lazygit_use_neovim_remote = 0

local function lazygit(cmd)
  return function()
    vim.cmd("silent! wall")  -- flush unsaved buffers so lazygit sees them
    vim.cmd(cmd)
  end
end

-- <leader>gs is already vim-fugitive (after/plugin/fugitive.lua), so lazygit
-- takes <leader>gg.
vim.keymap.set("n", "<leader>gg", lazygit("LazyGit"),
  { desc = "LazyGit (repo root)" })
vim.keymap.set("n", "<leader>gf", lazygit("LazyGitFilter"),
  { desc = "LazyGit: commits touching this file" })
vim.keymap.set("n", "<leader>gc", lazygit("LazyGitFilterCurrentFile"),
  { desc = "LazyGit: current file history" })
