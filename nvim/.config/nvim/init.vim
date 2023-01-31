 " these are all the linked files, for easy access use 'gf' on any of themdao
" │ │ │  plugin/coc.vim
" │ │ │  plugin/go.vim
" │ │ │  lua/autosave-plug.lua
" │ │ │  lua/mapsandsets-plug.lua
" │ │ │  lua/monzo-plug.lua
" │ │ │  lua/nvimtree-plug.lua
" │ │ │  lua/lsp-config.lua
" │ │ │  lua/auto-cmp.lua
" │ │ │  lua/diagnostics.lua
" │ │ │  lua/dap-debug.lua
" │ │ │  lua/plugin-dev.lua
" │ │ │  lua/octo.lua
" │ │ └  lua/telescope-plug.lua

nmap <leader>t <Plug>PlenaryTestFile

filetype plugin indent on

syntax on

hi Search cterm=NONE ctermfg=black ctermbg=red

set nocompatible

" plug 
call plug#begin()

Plug 'sheerun/vim-polyglot'

Plug 'christoomey/vim-tmux-navigator'

" post install (yarn install | npm install) then load plugin only for editing supported files
" Plug 'prettier/vim-prettier', { 'do': 'yarn install --frozen-lockfile --production' }

" Plug 'delabere/protodef'
Plug '/Users/jackrickards/jacksrc/protodef'

" surround vim
Plug 'tpope/vim-surround'

" for opening markdown files in a new browser window
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }

" Plug 'vim-airline/vim-airline' " https://github.com/vim-airline/vim-airline
" Plug 'ctrlpvim/ctrlp.vim'      " https://github.com/ctrlpvim/ctrlp.vim
Plug 'ryanoasis/vim-devicons'  " https://github.com/ryanoasis/vim-devicons + https://github.com/ryanoasis/nerd-fonts/
Plug 'tpope/vim-commentary'    " https://github.com/tpope/vim-commentary
Plug 'airblade/vim-gitgutter'  " https://github.com/airblade/vim-gitgutter
" Plug 'mkitt/tabline.vim'       " https://github.com/mkitt/tabline.vim

" Go
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' } " https://github.com/fatih/vim-go
" Plug 'neoclide/coc.nvim', {'branch': 'master', 'do': 'yarn install --frozen-lockfile'}

" telescope fuzzy finder
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

" nvim-tree
Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'kyazdani42/nvim-tree.lua'

" Plug 'williamboman/nvim-lsp-installer'
Plug '~/src/github.com/monzo/wearedev/tools/editors/nvim/nvim-monzo'

Plug 'jiangmiao/auto-pairs' " automatically insert/delete bracket pairs

" Themes
Plug 'NLKNguyen/papercolor-theme' " https://github.com/NLKNguyen/papercolor-theme
Plug 'morhetz/gruvbox' 							" a different theme
Plug 'sainnhe/gruvbox-material'

" helps when you want to search all of wearedev not just the current dir
Plug 'airblade/vim-rooter' " used to find current project dir

Plug '907th/vim-auto-save' " auto save all open buffers on any file change
Plug 'djoshea/vim-autoread' " auto read any changes to open buffers without prompt

" cql syntax highlighting
Plug 'elubow/cql-vim'

" git links from a file
Plug 'ruanyl/vim-gh-line'

" debugging
Plug 'mfussenegger/nvim-dap'
Plug 'leoluz/nvim-dap-go'
Plug 'rcarriga/nvim-dap-ui'
Plug 'theHamsta/nvim-dap-virtual-text'
Plug 'nvim-telescope/telescope-dap.nvim'

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" auto completion
Plug 'neovim/nvim-lspconfig'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-calc'
Plug 'f3fora/cmp-spell'
Plug 'tamago324/cmp-zsh'
Plug 'quangnguyen30192/cmp-nvim-ultisnips'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'

" open lazygit in a floating window
Plug 'kdheepak/lazygit.nvim'

" official
" Plug 'pwntester/octo.nvim'
" fork of octo that defaults to checking out local file system
Plug 'NWVi/octo.nvim'

" plugins for x-ray - go stuff
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'neovim/nvim-lspconfig'
Plug 'ray-x/go.nvim'
Plug 'ray-x/guihua.lua'

" plugins for navigator - lsp on steroids
Plug 'neovim/nvim-lspconfig'
Plug 'ray-x/guihua.lua', {'do': 'cd lua/fzy && make' }
Plug 'ray-x/navigator.lua'

" Plug 'Pocco81/auto-save.nvim'
call plug#end()

lua require('octo')
lua require('plugin-dev')
lua require('mapsandsets-plug')
lua require('nvimtree-plug')
lua require('autosave-plug')
lua require('monzo-plug')
lua require('auto-cmp')
lua require('diagnostics')
lua require('lsp-config')
lua require('dap-debug')
lua require('go').setup()
lua require('navigator').setup({lsp={ disable_lsp = {'gopls'}, disply_diagnostic_qf = false }, treesitter_analysis = false})
lua require('telescope-plug')

" allows you to select multiple lines in visual mode
" and perform a macro on all of them at the same time
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction

" mapping for protodef plugin
nmap <silent> <leader>gp :lua require'protodef'.protodef()<CR>

" setup mapping to call :LazyGit
nnoremap <silent> <leader>gg :LazyGit<CR>

" [count]<C-w>C is a shortcut for :[count]tabclose.
nnoremap <silent> <C-w>C :<C-u>exe (v:count ? v:count : '') . 'tabclose'<cr>
" [count]<C-w>O is a shortcut for :[count]tabonly.
nnoremap <silent> <C-w>O :<C-u>exe (v:count ? v:count : '') . 'tabonly'<cr>

" go to handler from proto message type
nnoremap gh :let pp=getpos('.')<CR>:let res=split(system('handlertool '.shellescape(expand('%:p').':'.line('.').':'.col('.'))), ':')<CR>:e <C-R>=res[0]<CR><CR>:call setpos('.',[pp[0],res[1],res[2],0])<CR>

"👇 you can put lua code inside blocks like this 
lua << EOF
EOF

