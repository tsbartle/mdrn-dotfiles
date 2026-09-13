-- remap our leader key to <space>
vim.g.mapleader = " "

-- remap explorer to <leader>pv
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move highlighted lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor in the same place when appening a line
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor in the middle when page jumping
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Keep search terms in the middle of the window
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- When replacing text with paste, keep buffer
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Yank to system clipboard
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Delete to the void
vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])

-- Crtl+C to get out of vertical edit mode
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Remove Q so we don't break things
vim.keymap.set("n", "Q", "<nop>")


-- NOTE: requires a `tmux-sessionizer` script on PATH; there isn't one on this
-- machine, so this currently opens an empty tmux window. Kept because you have
-- tmux-sessionx bound to prefix+o, which covers the same need.
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- Quickfix nav. These used to be <C-k>/<C-j>, which collided with harpoon's
-- nav_file maps in after/plugin/harpoon.lua. after/plugin loads *after* this
-- file, so harpoon won and quickfix navigation was silently dead.
vim.keymap.set("n", "<leader>qn", "<cmd>cnext<CR>zz", { desc = "Quickfix next" })
vim.keymap.set("n", "<leader>qp", "<cmd>cprev<CR>zz", { desc = "Quickfix prev" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Toggles to start replacing current word
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Make this file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Jump to the plugin list. The old path pointed at
-- ~/.dotfiles/nvim/.config/nvim/lua/theprimeagen/packer.lua, which has never
-- existed on this machine (wrong dotfiles dir *and* wrong namespace).
vim.keymap.set("n", "<leader>vpp", "<cmd>e ~/.config/nvim/lua/itsborkedagain/packer.lua<CR>",
  { desc = "Edit plugin list" })

-- Removed: <leader>mr -> CellularAutomaton. That plugin is not installed, so
-- the mapping only ever produced "E492: Not an editor command".

-- Quick way to re-source a file
vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)

