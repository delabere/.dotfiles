local function get_opts(keymap_setup, capabilities)
  -- get the work directory as a plenary path
  local path = require("plenary.path")
  local p = path:new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev")
  -- Check if the directory exists
  local work_profile = p:exists()
  -- for work, we have a specific setup for our language server
  if work_profile == true then
    -- we need to import our local monzo config plugin
    local monzo_lsp = require("monzo.lsp")
    -- use the monzo lsp config for gopls
    return monzo_lsp.go_config({
      on_attach = keymap_setup,
      capabilities = capabilities,
      -- this is a bit of a hack, we use a custom shell file to launch
      -- gopls with gomodules set to off
      cmd = { "/Users/" .. os.getenv("USER") .. "/bin/gopls.sh", "-remote=auto" },
    })
  else
    return {
      on_attach = keymap_setup,
      capabilities = capabilities,
    }
  end
end

return { get_opts = get_opts }
