local lspconfig = require("lspconfig")
local path = require("plenary.path")

local servers = {
  "pyright",
  "marksman",
  "kotlin_language_server",
  "templ",
  "html",
  "svelte",
  "gopls",
  -- "pbls", -- protobuf
  -- "buf_ls",
  -- "htmx",
  -- "tsserver",
}

-- vim.lsp.config("gopls", {
--   root_dir = lspconfig.util.root_pattern("main.go", "README.md", "LICENSE")(),
-- })
--

vim.lsp.config("gopls", {
  root_dir = function(bufnr, cb)
    local util = require("lspconfig.util")
    local root_markers = { "main.go", "README.md", "go.mod", "LICENSE" } -- Add more as needed
    local find_root_function = util.root_pattern(unpack(root_markers))
    local buffer_filepath = vim.api.nvim_buf_get_name(bufnr)
    vim.notify("buffer file path: " .. buffer_filepath)
    if buffer_filepath == "" then
      cb(nil)
      return
    end
    local root_directory = find_root_function(buffer_filepath, bufnr)
    vim.notify("root directory: " .. root_directory)
    cb(root_directory)
  end,

  cmd = { "env", "GO111MODULE=off", "gopls", "-remote=auto" },
})

for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end

require("lspconfig").protols.setup({})
return {
  -- {
  --   dir = "~",
  --   enabled = path:new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev"):exists(),
  --   config = function()
  --     vim.lsp.config("gopls", {
  --       root_dir = lspconfig.util.root_pattern("main.go", "README.md", "LICENSE")(),
  --     })
  --   end,
  -- },
}
