return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "giuxtaposition/blink-cmp-copilot",
    },
    opts = {
      sources = {
        -- adding any nvim-cmp sources here will enable them
        -- with blink.compat
        compat = {
          -- "copilot",
          --   "monzo_component",
          --   "monzo_system",
        },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            score_offset = 100,
            async = true,
          },
        },
        default = { "lsp", "path", "snippets", "buffer", "copilot" },

        cmdline = {},
      },

      keymap = {
        preset = "super-tab",
        ["<Tab>"] = { "select_and_accept" },
        ["Enter"] = { "accept" },
      },
      completion = {
        list = {
          selection = "auto_insert",
        },
      },
    },
  },
}
