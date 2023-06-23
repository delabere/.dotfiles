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
