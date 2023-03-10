local on_attach = function(client, bufnr)
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ls', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'U', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gt', '<cmd> lua vim.lsp.buf.type_definition()<CR>', opts)

    -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'U', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lwa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lwr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lwl',
        '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)

    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)

    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)

    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>lf', '<cmd>lua vim.lsp.buf.format()<CR>', opts)

    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>li', '<cmd>LspInfo<CR>', opts)

    vim.keymap.set('n', '<Leader>b', '<cmd>GoBuild<cr>')
    vim.keymap.set('n', '<Leader>t', '<cmd>GoTest<cr>')
    vim.keymap.set('n', '<Leader>x', '<cmd>GoCodeAction<cr>')
    vim.keymap.set('v', '<Leader>x', '<cmd>GoCodeAction<cr>')
    local path = client.workspace_folders[1].name

    -- for better imports sorting in wearedev
    if string.find(path, "monzo/wearedev") then
        client.config.settings.gopls['local'] = 'github.com/monzo/wearedev'
    end
    client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })

    -- this line ???? tells lspconfig to ignore all the above mappings and instead use those
    -- provided by the navigator plugin
    require('navigator.lspclient.mapping').setup({ bufnr = bufnr, client = client })

end

local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())


-- get the work directory as a plenary path
local path = require("plenary.path")
local p = path.new(os.getenv("HOME") .. "/src/github.com/monzo/wearedev")

-- Check if the directory exists
local work_profile = path.exists(p)

-- for work, we have a specific setup for our language server
if work_profile == true then
    local lspconfig = require 'lspconfig'
    local monzo_lsp = require 'monzo.lsp'
    lspconfig.gopls.setup(
        monzo_lsp.go_config({
            on_attach = on_attach,
            capabilities = capabilities,
        })
    )
else -- otherwise we are happy with defaults
    require('lspconfig')['gopls'].setup {
        on_attach = on_attach,
        capabilities = capabilities,
    }
end

local servers = { 'pyright', }
for _, lsp in ipairs(servers) do
    require('lspconfig')[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
    }
end

local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
require 'lspconfig'.lua_ls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT',
                -- Setup your lua path
                path = runtime_path,
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                -- Now, you don't get error/warning "Undefined global `vim`".
                globals = { 'vim' },
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
}
