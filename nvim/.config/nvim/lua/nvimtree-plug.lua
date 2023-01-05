-- open up the tree
vim.keymap.set('n', '<Leader>e', ':NvimTreeToggle<CR>')
vim.keymap.set('n', '<Leader>f', ':NvimTreeFocus<CR>')


require 'nvim-tree'.setup {
    update_focused_file = {
        enable = true,
        update_root = false,
        update_cwd = false,
    },
    git = {
        enable = true,
    },
    renderer = {
        highlight_opened_files = "all",
    },
}
