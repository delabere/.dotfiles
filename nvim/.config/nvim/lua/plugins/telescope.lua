return {

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { dir = "~/src/github.com/monzo/wearedev/tools/editors/nvim/nvim-monzo", "axkirillov/telescope-changed-files" },
    },
    config = function()
      require("telescope").load_extension("changed_files")
    end,
    keys = {
      { "<leader>fs", ":Monzo jump_to_component_no_cd<CR>", desc = "Monzo jump to component" },
      { "<leader>fd", ":Monzo jump_to_downstream<CR>", desc = "Monzo jump to downstream" },
    },
  },
}
