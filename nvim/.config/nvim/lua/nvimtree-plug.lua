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
    filesystem_watchers = {
        enable = true,
        debounce_delay = 50,
        -- filesystem_watchers in wearedev make changing services reeeeaally slow
        -- but this setting will mean changes in the filesystem are not going
        -- to be reflected until you open a new session
        ignore_dirs = { '/Users/jackrickards/src/github.com/monzo/wearedev' },
    },
    -- log = {
    --     enable = true,
    --     truncate = true,
    --     types = {
    --         diagnostics = true,
    --         git = true,
    --         profile = true,
    --         watcher = true,
    --     },
    -- },
}
