-- Shared helper functions used across multiple plugins
local M = {}

-- Find the service/project root directory using root markers
-- Works with lspconfig's root_pattern utility
M.find_service_root = function(start_path)
  local lspconfig = require("lspconfig")
  local root_markers = { "main.go", "README.md", "go.mod", "LICENSE" }
  local root_directory = lspconfig.util.root_pattern(root_markers)(start_path)
  return root_directory
end

-- Wrapper for LSP config that takes bufnr and callback (for backwards compatibility)
M.service_root_dir_lsp = function(bufnr, cb)
  local buffer_filepath = vim.api.nvim_buf_get_name(bufnr)
  local root_directory = M.find_service_root(buffer_filepath)
  cb(root_directory)
end

return M
