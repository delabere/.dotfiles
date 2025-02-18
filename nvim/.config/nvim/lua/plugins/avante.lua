return {
  {
    "yetone/avante.nvim",
    lazy = true,
    event = "VeryLazy",
    build = "make",

    opts = {
      provider = "copilot",
      auto_suggestions_provider = "copilot",
      -- copilot = { model = "claude-3.5-sonnet" },
      hints = { enabled = false },
      file_selector = {
        provider = "fzf",
        provider_opts = {},
      },
      behaviour = {
        enable_token_counting = false,
      },
    },

    dependencies = {
      {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = function(_, ft)
          vim.list_extend(ft, { "Avante" })
        end,
      },
      { "ibhagwan/fzf-lua" },
      {
        "folke/which-key.nvim",
        opts = {
          spec = {
            { "<leader>a", group = "ai" },
          },
        },
      },
    },
  },

  {
    "stevearc/dressing.nvim",
    lazy = true,
    opts = {
      input = { enabled = false },
      select = { enabled = false },
    },
  },

  {
    "saghen/blink.compat",
    lazy = true,
    opts = {},
    config = function()
      -- monkeypatch cmp.ConfirmBehavior for Avante
      require("cmp").ConfirmBehavior = {
        Insert = "insert",
        Replace = "replace",
      }
    end,
  },
}
