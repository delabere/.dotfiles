return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "super-tab",
      },
      sources = {
        compat = { "avante_commands", "avante_mentions", "avante_files" },
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },
}
