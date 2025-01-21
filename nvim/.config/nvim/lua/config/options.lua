-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- set the filepath at the top of the buffer
vim.opt.winbar = "%=%m %f"

-- disable swapfiles, they are super annoying
vim.opt.swapfile = false

-- creates an undo “breakpoint” before doing any formatting, so that undoing will revert only the edits made by the autoformatter
vim.opt.undolevels = vim.opt.undolevels

-- sets the base_branch for use by the changed_files telescope picker
vim.g.telescope_changed_files_base_branch = "master"

-- -- options
vim.opt.tabstop = 4 -- show existing tab with 4 spaces width
vim.opt.shiftwidth = 4 -- when indenting with '>', use 4 spaces width
vim.opt.expandtab = true -- On pressing tab, insert 4 spaces
-- vim.opt.encoding = 'UTF-8'
-- vim.opt.hidden = true -- preserve background buffers
-- vim.opt.hlsearch = true -- highlights search terms
-- vim.opt.number = true -- linenumbers
-- vim.opt.relativenumber = true -- sets relative numbers
-- vim.opt.laststatus = 2
-- vim.opt.vb = true
-- vim.opt.ruler = true
-- vim.opt.spelllang = 'en_us'
-- vim.opt.autoindent = true
-- vim.opt.colorcolumn = '120'
-- vim.opt.mouse = 'a'
-- vim.opt.clipboard = 'unnamed'
-- --vim.opt.noscrollbind = true
-- vim.opt.wildmenu = true
-- vim.opt.autochdir = true
-- vim.api.nvim_command("set noswapfile")
-- vim.opt.scrolloff = 16 -- starts page scrolling when n lines from top/bottom
vim.api.nvim_command("set nofoldenable") -- no folds please
-- vim.opt.signcolumn = 'yes' --creates a dedicated column for git status so line numbers still show up
-- vim.opt.ignorecase = true --ignore case in searching
-- vim.opt.splitbelow = true --force new splits to go to the right of current window--
-- vim.opt.splitright = true --force new splits to go to below the of current window
-- vim.opt.termguicolors = true
vim.opt.report = 999

vim.g.lazygit_config = false

vim.g.lazyvim_picker = "telescope"

