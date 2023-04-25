return {

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { dir = "~/src/github.com/monzo/wearedev/tools/editors/nvim/nvim-monzo" },
    },
    keys = {
      { "<leader>fs", ":Monzo jump_to_component<CR>", desc = "Monzo jump to component" },
      { "<leader>fd", ":Monzo jump_to_downstream<CR>", desc = "Monzo jump to downstream" },
    },
  },
}
