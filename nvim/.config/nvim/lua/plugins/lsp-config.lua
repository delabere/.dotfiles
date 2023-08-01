return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "folke/neoconf.nvim",
        cmd = "Neoconf",
        config = true,
      },
      {
        "folke/neodev.nvim",
        opts = {
          experimental = { pathStrict = true },
        },
      },
      { dir = "~/src/github.com/monzo/wearedev/tools/editors/nvim/nvim-monzo" },
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      {
        "hrsh7th/cmp-nvim-lsp",
        cond = function()
          return require("lazyvim.util").has("nvim-cmp")
        end,
      },
    },
    ---@class PluginLspOpts
    opts = {
      -- options for vim.diagnostic.config()
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
          -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
          -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
          -- prefix = "icons",
        },
        severity_sort = true,
      },
      -- add any global capabilities here
      capabilities = {},
      -- Automatically format on save
      autoformat = true,
      -- options for vim.lsp.buf.format
      -- `bufnr` and `filter` is handled by the LazyVim formatter,
      -- but can be also overridden when specified
      format = {
        formatting_options = nil,
        timeout_ms = nil,
      },
      -- LSP Server Settings
      ---@type lspconfig.options
      servers = {
        jsonls = {},
        lua_ls = {
          -- mason = false, -- set to false if you don't want this server to be installed with mason
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        },
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- example to setup with typescript.nvim
        -- tsserver = function(_, opts)
        --   require("typescript").setup({ server = opts })
        --   return true
        -- end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    },
    ---@param opts PluginLspOpts
    config = function(_, opts)
      local Util = require("lazyvim.util")
      -- setup autoformat
      require("lazyvim.plugins.lsp.format").autoformat = opts.autoformat
      -- setup formatting and keymaps
      Util.on_attach(function(client, buffer)
        require("lazyvim.plugins.lsp.format").on_attach(client, buffer)
        require("lazyvim.plugins.lsp.keymaps").on_attach(client, buffer)
      end)

      -- diagnostics
      for name, icon in pairs(require("lazyvim.config").icons.diagnostics) do
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
      end

      if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
        opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
          or function(diagnostic)
            local icons = require("lazyvim.config").icons.diagnostics
            for d, icon in pairs(icons) do
              if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
                return icon
              end
            end
          end
      end

      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      local servers = opts.servers
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities(),
        opts.capabilities or {}
        -- adds dynamic realoading when files have changed
        -- {
        --   workspace = {
        --     didChangeWatchedFiles = {
        --       dynamicRegistration = true,
        --     },
        --   },
        -- }
      )

      local function setup(server)
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})

        if opts.setup[server] then
          if opts.setup[server](server, server_opts) then
            return
          end
        elseif opts.setup["*"] then
          if opts.setup["*"](server, server_opts) then
            return
          end
        end
        require("lspconfig")[server].setup(server_opts)
      end

      -- get all the servers that are available thourgh mason-lspconfig
      local have_mason, mlsp = pcall(require, "mason-lspconfig")
      local all_mslp_servers = {}
      if have_mason then
        all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
      end

      local ensure_installed = {} ---@type string[]
      for server, server_opts in pairs(servers) do
        if server_opts then
          server_opts = server_opts == true and {} or server_opts
          -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
          if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
            setup(server)
          else
            ensure_installed[#ensure_installed + 1] = server
          end
        end
      end

      if have_mason then
        mlsp.setup({ ensure_installed = ensure_installed })
        mlsp.setup_handlers({ setup })
      end

      if Util.lsp_get_config("denols") and Util.lsp_get_config("tsserver") then
        local is_deno = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")
        Util.lsp_disable("tsserver", is_deno)
        Util.lsp_disable("denols", function(root_dir)
          return not is_deno(root_dir)
        end)
      end

      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true }
        vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ls", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", opts)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>lD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "U", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gt", "<cmd> lua vim.lsp.buf.type_definition()<CR>", opts)

        -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'U', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>lwa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<leader>lwr",
          "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",
          opts
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          "n",
          "<leader>lwl",
          "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
          opts
        )

        vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)

        vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)

        vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)

        vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>lf", "<cmd>lua vim.lsp.buf.format()<CR>", opts)

        vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>li", "<cmd>LspInfo<CR>", opts)

        vim.keymap.set("n", "<Leader>b", "<cmd>GoBuild<cr>")
        vim.keymap.set("n", "<Leader>t", "<cmd>GoTest<cr>")
        vim.keymap.set("n", "<Leader>x", "<cmd>GoCodeAction<cr>")
        vim.keymap.set("v", "<Leader>x", "<cmd>GoCodeAction<cr>")

        local path = client.workspace_folders[1].name

        -- for better imports sorting in wearedev
        if string.find(path, "monzo/wearedev") then
          client.config.settings.gopls["local"] = "github.com/monzo/wearedev"
        end
        client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })

        -- this line 👇 tells lspconfig to ignore all the above mappings and instead use those
        -- provided by the navigator plugin
        require("navigator.lspclient.mapping").setup({ bufnr = bufnr, client = client })
      end

      -- TODO: activate this if we use navigator again
      -- local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

      -- get the work directory as a plenary path
      local path = require("plenary.path")
      local p = path.new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev")

      -- Check if the directory exists
      local work_profile = path.exists(p)

      -- for work, we have a specific setup for our language server
      if work_profile == true then
        local lspconfig = require("lspconfig")
        local monzo_lsp = require("monzo.lsp")
        lspconfig.gopls.setup(monzo_lsp.go_config({
          on_attach = on_attach,
          capabilities = capabilities,
        }))
      else -- otherwise we are happy with defaults
        require("lspconfig")["gopls"].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end

      local servers = { "pyright", "tsserver" }
      for _, lsp in ipairs(servers) do
        require("lspconfig")[lsp].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end
    end,
  },
}
