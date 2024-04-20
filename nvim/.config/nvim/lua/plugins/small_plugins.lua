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
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
        python = { "ruff_format", "isort" },
        -- python = { "isort", "black" },
        go = { "gopls" },
        nix = { "nixpkgs-fmt" },
        rust = { "rustfmt" },
      },
    },
  },

  { "folke/zen-mode.nvim" },
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
  { "ruanyl/vim-gh-line" },
  { "folke/zen-mode.nvim" },

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
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-go" },
    opts = { adapters = { "neotest-go" }, discovery = { enabled = false } },
  },

  {
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>hh", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", desc = "toggle_quick_menu" },
      { "<leader>ha", "<cmd>lua require('harpoon.mark').add_file()<cr>", desc = "add_file" },
      { "<leader>ht", "<cmd>Telescope harpoon marks<cr>", desc = "telescope_marks" },
    },
  },
  -- { "github/copilot.vim" },
}
