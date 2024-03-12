local lspconfig = require("lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

local on_attach = function(_, bufnr)
  local opts = { noremap = true, silent = true }
  local keymap = vim.keymap -- for conciseness
  opts.buffer = bufnr

  opts.desc = "Show LSP definitions"
  keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

  opts.desc = "Show LSP references"
  keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)

  opts.desc = "Show documentation for what is under cursor"
  keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)

  opts.desc = "Show LSP implementations"
  keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

  opts.desc = "Show LSP type definitions"
  keymap.set("n", "gt", "<cmd> lua vim.lsp.buf.type_definition()<CR>", opts)

  opts.desc = "Smart rename"
  keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)

  opts.desc = "See available code actions"
  keymap.set("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)

  opts.desc = "LSP format"
  keymap.set("n", "<leader>lf", "<cmd>lua vim.lsp.buf.format()<CR>", opts)

  opts.desc = "LSP info"
  keymap.set("n", "<leader>li", "<cmd>LspInfo<CR>", opts)

  opts.desc = "Show buffer diagnostics"
  keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

  opts.desc = "Go to previous diagnostic"
  keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

  opts.desc = "Go to next diagnostic"
  keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

  -- these aren't LSP specific, but it makes sense to only add them on attach to gopls
  opts.desc = "See available code actions"
  vim.keymap.set("n", "<Leader>b", "<cmd>GoBuild<cr>")

  opts.desc = "See available code actions"
  vim.keymap.set("n", "<Leader>t", "<cmd>GoTest<cr>")

  opts.desc = "See available code actions"
  vim.keymap.set("n", "<Leader>x", "<cmd>GoCodeAction<cr>")

  opts.desc = "See available code actions"
  vim.keymap.set("v", "<Leader>x", "<cmd>GoCodeAction<cr>")

  opts.desc = "Restart LSP"
  keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
  --
  -- Workaround for the lack of a DAP strategy in neotest-go: https://github.com/nvim-neotest/neotest-go/issues/12
  opts.desc = "Debug nearest test (Go)"
  keymap.set("", "<leader>td", "<cmd>lua require('dap-go').debug_test()<CR>", opts)
  -- this line 👇 tells lspconfig to ignore all the above mappings and instead use those
  -- provided by the navigator plugin
  -- require("navigator.lspclient.mapping").setup({ bufnr = bufnr, client = client })
end

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      -- only required for work configuration
      { dir = "~/src/github.com/monzo/wearedev/tools/editors/nvim/nvim-monzo" },
    },

    config = function()
      -- used to enable autocompletion (assign to every lsp server config)
      local capabilities = cmp_nvim_lsp.default_capabilities()
      --
      -- Change the Diagnostic symbols in the sign column (gutter)
      -- (not in youtube nvim video)
      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

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
        lspconfig.gopls.setup(monzo_lsp.go_config({
          on_attach = on_attach,
          capabilities = capabilities,
          -- this is a bit of a hack, we use a custom shell file to launch
          -- gopls with gomodules set to off
          cmd = { "/Users/" .. os.getenv("USER") .. "/bin/gopls.sh", "-remote=auto" },
        }))
      else -- otherwise we are happy with defaults
        require("lspconfig")["gopls"].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end

      -- configure all our other servers
      local servers = { "pyright", "tsserver", "marksman" }
      for _, lsp in ipairs(servers) do
        require("lspconfig")[lsp].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end

      -- lua has some extra special config so it can work with runtime files
      local runtime_path = vim.split(package.path, ";")
      table.insert(runtime_path, "lua/?.lua")
      table.insert(runtime_path, "lua/?/init.lua")
      require("lspconfig").lua_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = {
              -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
              version = "LuaJIT",
              -- Setup your lua path
              path = runtime_path,
            },
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              -- Now, you don't get error/warning "Undefined global `vim`".
              globals = { "vim" },
            },
            workspace = {
              -- Make the server aware of Neovim runtime files
              library = vim.api.nvim_get_runtime_file("", true),
            },
            -- By default, lua-language-server sends anonymized data to its developers. Stop it using the following.
            telemetry = {
              enable = false,
            },
          },
        },
      })
    end,
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^3",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
      {
        "lvimuser/lsp-inlayhints.nvim",
        opts = {},
      },
    },
    ft = { "rust" },
    config = function()
      vim.g.rustaceanvim = {
        inlay_hints = {
          highlight = "NonText",
        },
        tools = {
          hover_actions = {
            auto_focus = true,
          },
        },
        server = {
          on_attach = function(client, bufnr)
            require("lsp-inlayhints").on_attach(client, bufnr)
            on_attach(client, bufnr)
          end,
        },
      }
    end,
  },
}
