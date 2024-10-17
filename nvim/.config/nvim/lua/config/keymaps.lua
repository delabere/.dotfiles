-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- lets you use 'kj' instead of <Esc>
vim.keymap.set("i", "kj", "<Esc>")

-- resume the last open telescope picker
vim.keymap.set(
  "n",
  "<leader>sx",
  require("telescope.builtin").resume,
  { noremap = true, silent = true, desc = "Resume" }
)

-- mapping for protodef plugin
vim.keymap.set(
  "n",
  "<leader>gp",
  require("protodef").protodef,
  { noremap = true, silent = true, desc = "ProtoDefinition" }
)

-- No more Arrow Keys, deal with it
vim.keymap.set("n", "<Up>", "<NOP>")
vim.keymap.set("n", "<Down>", "<NOP>")
vim.keymap.set("n", "<Left>", "<NOP>")
vim.keymap.set("n", "<Right>", "<NOP>")

-- save current buffer
vim.keymap.set("n", "zz", ":update<CR>", { silent = true })

-- arrow keys to resize windows
vim.keymap.set("n", "<Up>", ":resize -2<CR>", { silent = true })
vim.keymap.set("n", "<Down>", ":resize +2<CR>", { silent = true })
vim.keymap.set("n", "<Left>", ":vertical resize -2<CR>", { silent = true })
vim.keymap.set("n", "<Right>", ":vertical resize +2<CR>", { silent = true })

-- easy way to get into this config file from nvim
vim.keymap.set("n", "<Leader>v", ":e $MYVIMRC<CR>")

-- source the configuration file on the fly
vim.keymap.set("n", "<Leader><CR>", ":so ~/.config/nvim/init.vim<CR>")

-- move blocks of text in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- navigate through items in the quickfixlist
vim.keymap.set("n", "<Leader>j", ":cprev<CR>")
vim.keymap.set("n", "<Leader>k", ":cnext<CR>")

-- stops p in visual mode yanking the replaced text
vim.keymap.set("x", "p", "pgvy")

--This enables us to undo files even if you exit Vim.
-- if vim.fn.has('persistent_undo') == 1 then
--     vim.opt.undofile = true
--     vim.opt.undodir = '~/.config/vim/tmp/undo//'
-- end

vim.api.nvim_command(
  'command! Mockit lua local pos = vim.fn.getpos("."); vim.fn.system("goprotomocker -file " .. vim.fn.expand("%:p") .. " -line " .. vim.fn.line(".") .. " -write"); vim.cmd("edit!"); vim.fn.setpos(".", pos); vim.lsp.buf.format()'
)
vim.api.nvim_set_keymap("n", "gh", "", {
  noremap = true,
  silent = true,
  callback = function()
    -- Call handlertool.
    local file_src_path_abs = vim.fn.expand("%:p")
    local file_src_line = vim.fn.line(".")
    local file_src_col = vim.fn.col(".")
    local handlertool_out = vim.fn.system(
      "handlertool " .. vim.fn.shellescape(file_src_path_abs .. ":" .. file_src_line .. ":" .. file_src_col)
    )

    -- Parse handlertool output.
    local file_dst_path_abs, file_dst_line, file_dst_col = string.match(handlertool_out, "([^:]+):(%d+):(%d+)")

    -- Jump to the destination.
    vim.cmd("e " .. file_dst_path_abs)
    vim.fn.setpos(".", { vim.api.nvim_get_current_buf(), tonumber(file_dst_line), tonumber(file_dst_col), 0 })
    vim.cmd("normal! zz")
  end,
})

-- diagnostic seeks
vim.keymap.set("n", ")", "<cmd>lua vim.diagnostic.goto_next()<CR>", { silent = true })
vim.keymap.set("n", "(", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { silent = true })
