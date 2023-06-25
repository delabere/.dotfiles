return {
  {
    -- github PR reviews in nvim
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("octo").setup({
        use_local_fs = true,
      })
    end,
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason.nvim", "ThePrimeagen/refactoring.nvim" },
    opts = function()
      local nls = require("null-ls")
      return {
        root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git", ".py"),
        sources = {
          nls.builtins.formatting.fish_indent,
          nls.builtins.diagnostics.fish,
          nls.builtins.formatting.stylua,
          nls.builtins.formatting.shfmt,
          nls.builtins.formatting.isort,
          nls.builtins.formatting.black,
          -- nls.builtins.code_actions.refactoring,
          -- nls.builtins.diagnostics.flake8,
        },
      }
    end,
  },

  { "delabere/protodef" },
  { "folke/zen-mode.nvim" },
  {
    "fatih/vim-go",
    make = ":GoInstallBinaries",
    config = function()
      vim.g.go_gopls_enabled = false -- or false to disable
    end,
  },

  -- -- Use <tab> for completion and snippets (supertab)
  -- -- first: disable default <tab> and <s-tab> behavior in LuaSnip
  -- {
  --   "L3MON4D3/LuaSnip",
  --   keys = function()
  --     return {}
  --   end,
  -- },
  -- -- then: setup supertab in cmp
  -- {
  --   "hrsh7th/nvim-cmp",
  --   dependencies = {
  --     "hrsh7th/cmp-emoji",
  --   },
  --   ---@param opts cmp.ConfigSchema
  --   opts = function(_, opts)
  --     local has_words_before = function()
  --       unpack = unpack or table.unpack
  --       local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  --       return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
  --     end
  --
  --     local luasnip = require("luasnip")
  --     local cmp = require("cmp")
  --
  --     opts.mapping = vim.tbl_extend("force", opts.mapping, {
  --       ["<Tab>"] = cmp.mapping(function(fallback)
  --         if cmp.visible() then
  --           cmp.select_next_item()
  --           -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
  --           -- they way you will only jump inside the snippet region
  --         elseif luasnip.expand_or_jumpable() then
  --           luasnip.expand_or_jump()
  --         elseif has_words_before() then
  --           cmp.complete()
  --         else
  --           fallback()
  --         end
  --       end, { "i", "s" }),
  --       ["<S-Tab>"] = cmp.mapping(function(fallback)
  --         if cmp.visible() then
  --           cmp.select_prev_item()
  --         elseif luasnip.jumpable(-1) then
  --           luasnip.jump(-1)
  --         else
  --           fallback()
  --         end
  --       end, { "i", "s" }),
  --     })
  --   end,
  -- },

  -- navigate between other tmux panes
  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<C-h>", "<C-U>TmuxNavigateRight<cr>", desc = "Tmux Navigate Right" },
      { "<C-k>", "<C-U>TmuxNavigateUp<cr>", desc = "Tmux Navigate Up" },
      { "<C-j>", "<C-U>TmuxNavigateDown<cr>", desc = "Tmux Navigate Down" },
      { "<C-l>", "<C-U>TmuxNavigateLeft<cr>", desc = "Tmux Navigate Left" },
    },
  },

  { "tpope/vim-surround" },

  -- { "907th/vim-auto-save" },
  -- {
  --   "Pocco81/auto-save.nvim",
  --   opts = {
  --     enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
  --     execution_message = {
  --       message = function() -- message to print on save
  --         return ""
  --       end,
  --       dim = 0.18, -- dim the color of `message`
  --       cleaning_interval = 1250, -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
  --     },
  --     events = { "InsertLeave" }, -- vim events that trigger auto-save. See :h events
  --     -- function that determines whether to save the current buffer or not
  --     -- return true: if buffer is ok to be saved
  --     -- return false: if it's not ok to be saved
  --     condition = function(buf)
  --       local fn = vim.fn
  --       local utils = require("auto-save.utils.data")
  --
  --       if fn.getbufvar(buf, "&modifiable") == 1 and utils.not_in(fn.getbufvar(buf, "&filetype"), {}) then
  --         return true -- met condition(s), can save
  --       end
  --       return false -- can't save
  --     end,
  --     write_all_buffers = false, -- write all buffers when the current one meets `condition`
  --     debounce_delay = 135, -- saves the file at most every `debounce_delay` milliseconds
  --     callbacks = { -- functions to be executed at different intervals
  --       enabling = nil, -- ran when enabling auto-save
  --       disabling = nil, -- ran when disabling auto-save
  --       before_asserting_save = nil, -- ran before checking `condition`
  --       before_saving = nil, -- ran before doing the actual save
  --       after_saving = nil, -- ran after doing the actual save
  --     },
  --   },
  -- },

  -- auto save all open buffers on any file change
  -- {
  --   "907th/vim-auto-save",
  --
  --   config = function()
  --     vim.g.auto_save = 1
  --     vim.g.auto_save_events = { "InsertLeave" }
  --   end,
  --
  --   -- ExitPre,
  --   -- FocusLost,
  --   -- InsertEnter,
  --   -- QuitPre,
  --   -- BufLeave,
  -- },
  --
  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "go",
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "nix",
      },
    },
  },

  -- it is not clear that any of these are needed 👇
  -- {
  --   "hrsh7th/cmp-cmdline",
  --   "hrsh7th/cmp-calc",
  --   "f3fora/cmp-spell",
  --   "tamago324/cmp-zsh",
  --   "quangnguyen30192/cmp-nvim-ultisnips",
  --   "hrsh7th/cmp-nvim-lsp-signature-help",
  -- },

  -- debugger configuration for go
  { "leoluz/nvim-dap-go" },
  { "ruanyl/vim-gh-line" },
  { "folke/zen-mode.nvim" },
  { "iamcco/markdown-preview.nvim" },
  {
    -- the default blue for todo's is a little garish
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        TODO = { icon = " ", color = "hint" },
      },
    },
  },

  {
    "axkirillov/telescope-changed-files",
  },
}
