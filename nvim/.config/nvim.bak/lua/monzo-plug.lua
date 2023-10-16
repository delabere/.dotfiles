vim.keymap.set('n', '<Leader>fs', ':Monzo jump_to_component<CR>')
vim.keymap.set('n', '<Leader>fd', ':Monzo jump_to_downstream<CR>')

-- https://github.com/monzo/wearedev/blob/master/tools/go-mod/editors.md
--
-- local cmp = require'cmp'
-- local cmp_types = require('cmp.types')

-- require'monzo.cmp'

-- cmp.setup({
--     autocomplete = {
--         cmp_types.cmp.TriggerEvent.TextChanged,
--     },
--     completeopt = 'menu,menuone,noselect',
--     keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%(-\w*\)*\)]],
--     experimental = {
--         native_menu = false,
--         ghost_text = false,
--     },
--     mapping = cmp.mapping.preset.insert({
--         ['<C-x><C-o>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
--         ['<C-x><C-z>'] = cmp.mapping({
--             i = cmp.mapping.abort(),
--             c = cmp.mapping.close(),
--         }),
--         ['<tab>'] = cmp.mapping.confirm({ select = true }),
--     }),
--     sources = cmp.config.sources({
--         { name = 'nvim_lsp' },
--         { name = 'monzo_component', max_item_count = 20 },
--         { name = 'monzo_system', max_item_count = 20 },
--     }),
-- })
--
