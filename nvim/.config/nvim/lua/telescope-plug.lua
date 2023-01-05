vim.keymap.set('n', '<Leader>ff', '<cmd>Telescope find_files<cr>')
vim.keymap.set('n', '<Leader>fg', '<cmd>Telescope live_grep<cr>')
vim.keymap.set('n', '<Leader>fb', '<cmd>Telescope buffers<cr>')
vim.keymap.set('n', '<Leader>fh', '<cmd>Telescope help_tags<cr>')
vim.keymap.set('n', '<Leader>fo', '<cmd>Telescope oldfiles<cr>')

vim.my_fd = function(opts)
    opts = opts or {}
    opts.cwd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    require 'telescope.builtin'.find_files(opts)
end

-- allows telescope to search from the git repo not just the current dir
vim.g.rooter_patterns = { '.git', '.svn', 'package.json', '!node_modules' }



