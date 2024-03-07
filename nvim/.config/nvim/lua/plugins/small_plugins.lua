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
    "stevearc/conform.nvim",
    opts = function()
      ---@class ConformOpts
      local opts = {
        -- LazyVim will use these options when formatting with the conform.nvim formatter
        format = {
          timeout_ms = 3000,
          async = false, -- not recommended to change
          quiet = false, -- not recommended to change
        },
        ---@type table<string, conform.FormatterUnit[]>
        formatters_by_ft = {
          lua = { "stylua" },
          fish = { "fish_indent" },
          sh = { "shfmt" },
          python = { "ruff_format", "isort" },
          -- python = { "isort", "black" },
          go = { "gopls" },
          nix = { "alejandra" },
        },
        -- The options you set here will be merged with the builtin formatters.
        -- You can also define any custom formatters here.
        ---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
        formatters = {
          injected = { options = { ignore_errors = true } },
          -- # Example of using dprint only when a dprint.json file is present
          -- dprint = {
          --   condition = function(ctx)
          --     return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
          --   end,
          -- },
          --
          -- # Example of using shfmt with extra args
          -- shfmt = {
          --   prepend_args = { "-i", "2", "-ci" },
          -- },
        },
      }
      return opts
    end,
  },

  { "delabere/protodef" },
  { "folke/zen-mode.nvim" },
  {
    "fatih/vim-go",
    make = ":GoInstallBinaries",
    config = function()
      vim.g.go_gopls_enabled = false -- or false to disable
      vim.g.go_def_mapping_enabled = false -- stops vim-go taking over <C-t> for tagstack jumps
      vim.keymap.set("n", "<leader>ge", "<cmd>GoIfErr<CR>", { desc = "Go if error" })
      vim.keymap.set("n", "<leader>tf", "<cmd>GoAlternate<CR>", { desc = "Go to tests for file" })
      vim.keymap.set("n", "<leader>tc", "<cmd>GoCoverageToggle<CR>", { desc = "Test coverage toggle" })
    end,
  },

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

  -- { "tpope/vim-surround" },

  -- debugger configuration for go
  { "leoluz/nvim-dap-go" },
  { "ruanyl/vim-gh-line" },
  { "folke/zen-mode.nvim" },

  -- install without yarn or npm
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },

    init = function()
      -- set to 1, nvim will open the preview window after entering the Markdown buffer
      -- default: 0
      vim.g.mkdp_auto_start = 0

      -- combine preview window
      -- default: 0
      -- if enable it will reuse previous opened preview window when you preview markdown file.
      -- ensure to set let g:mkdp_auto_close = 0 if you have enable this option
      vim.g.mkdp_combine_preview = 1

      -- auto refetch combine preview contents when change markdown buffer
      -- only when g:mkdp_combine_preview is 1
      vim.g.mkdp_combine_preview_auto_refresh = 1
    end,

    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },

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
    "nvim-neotest/neotest-go",
  },
  {
    "nvim-neotest/neotest",
    opts = { adapters = { "neotest-go" }, discovery = { enabled = false } },
  },

  {
    "stevearc/oil.nvim",

    keys = {
      { "<leader>o", "<CMD>Oil<CR>", desc = "Oil" },
    },
    opts = {
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
      },

      -- See :help oil-actions for a list of all available actions
      keymaps = {
        ["?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-x>"] = "actions.select_split",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-l>"] = "actions.refresh",
        ["<BS>"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
      },
    },
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
}
