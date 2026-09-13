local builtin = require('telescope.builtin')

-- file search for all files
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})

-- search through git files. Why? Sometimes you have huge directories
-- that contain many files but aren't tracked, and probably aren't as
-- relevant to what you're looking for
-- NOTE: this was 'C-p' -- without the angle brackets vim maps the literal
-- sequence C, -, p, not Ctrl-p. So git_files was effectively unreachable.
vim.keymap.set('n', '<C-p>', builtin.git_files, {})

-- search that greps within files
vim.keymap.set('n', '<leader>ps', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)
