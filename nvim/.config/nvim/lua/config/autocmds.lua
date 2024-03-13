-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function is_readonly()
  local current_buf = vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_option(current_buf, "readonly")
end

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "InsertLeave" }, {
  desc = "autosave modifiable buffers only",
  callback = function()
    if is_readonly() then
      return
    end

    vim.cmd("silent! wa")
  end,
})

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  desc = "conform autoformat",
  callback = function(args)
    if is_readonly() then
      return
    end

    require("conform").format({ bufnr = args.buf })
  end,
})
