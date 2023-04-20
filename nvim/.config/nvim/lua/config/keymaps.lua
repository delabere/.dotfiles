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

-- No more Arrow Keys, deal with it
vim.keymap.set("n", "<Up>", "<NOP>")
vim.keymap.set("n", "<Down>", "<NOP>")
vim.keymap.set("n", "<Left>", "<NOP>")
vim.keymap.set("n", "<Right>", "<NOP>")

-- save current buffer
vim.keymap.set("n", "zz", ":update<CR>")

-- arrow keys to resize windows
vim.keymap.set("n", "<Up>", ":resize -2<CR>")
vim.keymap.set("n", "<Down>", ":resize +2<CR>")
vim.keymap.set("n", "<Left>", ":vertical resize -2<CR>")
vim.keymap.set("n", "<Right>", ":vertical resize +2<CR>")

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

-- -- options
-- vim.opt.tabstop = 4 -- show existing tab with 4 spaces width
-- vim.opt.shiftwidth = 4 -- when indenting with '>', use 4 spaces width
-- vim.opt.expandtab = true -- On pressing tab, insert 4 spaces
-- vim.opt.encoding = 'UTF-8'
-- vim.opt.hidden = true -- preserve background buffers
-- vim.opt.hlsearch = true -- highlights search terms
-- vim.opt.number = true -- linenumbers
-- vim.opt.relativenumber = true -- sets relative numbers
-- vim.opt.laststatus = 2
-- vim.opt.vb = true
-- vim.opt.ruler = true
-- vim.opt.spelllang = 'en_us'
-- vim.opt.autoindent = true
-- vim.opt.colorcolumn = '120'
-- vim.opt.mouse = 'a'
-- vim.opt.clipboard = 'unnamed'
-- --vim.opt.noscrollbind = true
-- vim.opt.wildmenu = true
-- vim.opt.autochdir = true
-- vim.api.nvim_command("set noswapfile")
-- vim.opt.scrolloff = 16 -- starts page scrolling when n lines from top/bottom
vim.api.nvim_command("set nofoldenable") -- no folds please
-- vim.opt.signcolumn = 'yes' --creates a dedicated column for git status so line numbers still show up
-- vim.opt.ignorecase = true --ignore case in searching
-- vim.opt.splitbelow = true --force new splits to go to the right of current window--
-- vim.opt.splitright = true --force new splits to go to below the of current window
-- vim.opt.termguicolors = true

-- this bit of code allows you to highlight a visual range
-- and run a macro on each line
vim.cmd("xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>")

--This enables us to undo files even if you exit Vim.
-- if vim.fn.has('persistent_undo') == 1 then
--     vim.opt.undofile = true
--     vim.opt.undodir = '~/.config/vim/tmp/undo//'
-- end
