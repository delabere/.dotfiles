-- my own prododef plugin
return {
  { "delabere/protodef" },

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

  -- auto save all open buffers on any file change
  {
    "907th/vim-auto-save",

    config = function()
      vim.g.auto_save = 1
      vim.g.auto_save_in_insert_mode = 0
      vim.g.auto_save_silent = 1
    end,
  },

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
      },
    },
  },

  -- it is not clear that any of these are needed 👇
  {
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-calc",
    "f3fora/cmp-spell",
    "tamago324/cmp-zsh",
    "quangnguyen30192/cmp-nvim-ultisnips",
    "hrsh7th/cmp-nvim-lsp-signature-help",
  },

  -- debugger configuration for go
  { "leoluz/nvim-dap-go" },
}
