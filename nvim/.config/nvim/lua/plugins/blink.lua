return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<Tab>"] = {
          require("blink.cmp.keymap.presets").get("super-tab")["<Tab>"][1],
          LazyVim.cmp.map({ "snippet_forward", "ai_accept" }),
          "fallback",
        },
        -- https://github.com/LazyVim/LazyVim/issues/6185
        -- preset = "super-tab",
      },
      -- sources = {
      -- compat = { "avante_commands", "avante_mentions", "avante_files" },
      -- default = { "lsp", "path", "snippets", "buffer" },
      -- },
    },
  },
}
