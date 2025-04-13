local path = require("plenary.path")
if path:new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev"):exists() then
  local monzo_lsp = require("monzo.lsp")
  vim.lsp.config["gopls"] = monzo_lsp.go_config({
    -- this is a bit of a hack, we use a custom shell file to launch
    -- gopls with gomodules set to off
    cmd = { "env", "GO111MODULE=off", "gopls", "-remote=auto" },
  })
end
vim.lsp.enable("gopls")
