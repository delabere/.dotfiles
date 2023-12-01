-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- autosave
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "InsertLeave" }, {
  command = "silent! wa",
})

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "InsertLeave" }, {
  pattern = "*",
  callback = function(args)
    require("conform").format({ bufnr = args.buf })
  end,
})
