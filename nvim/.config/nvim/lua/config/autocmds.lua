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

-- vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
--   desc = "conform autoformat",
--   callback = function(args)
--     if is_readonly() then
--       return
--     end
--
--     require("conform").format({ bufnr = args.buf })
--   end,
-- })

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.proto",
  group = vim.api.nvim_create_augroup("protobufGeneration", { clear = true }),
  callback = function()
    local cwd = vim.fn.getcwd()
    local service = vim.fn.expand("%:p"):match("wearedev/(.+)/proto")
    local cmd = string.format("%s/bin/generate_protobufs %s/%s", cwd, cwd, service)

    local output = {}
    local function handle_output(_, data)
      if data then
        vim.list_extend(
          output,
          vim.tbl_filter(function(line)
            return line ~= ""
          end, data)
        )
      end
    end

    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = handle_output,
      on_stderr = handle_output,
      on_exit = function(_, exit_code)
        table.insert(output, exit_code == 0 and "Command finished successfully" or "Command finished with errors")
        vim.notify(table.concat(output, "\n"), exit_code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
      end,
    })
  end,
})
