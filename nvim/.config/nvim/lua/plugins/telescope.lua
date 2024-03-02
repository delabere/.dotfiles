return {
  {
    "axkirillov/telescope-changed-files",
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        dir = "~/src/github.com/monzo/wearedev/tools/editors/nvim/nvim-monzo",
      },
      { "axkirillov/telescope-changed-files" },
      { "nvim-telescope/telescope-file-browser.nvim" },
    },
    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup({
        defaults = {
          -- Default configuration for telescope goes here:
          -- config_key = value,
          mappings = {
            i = {
              ["<C-h>"] = "which_key",
              -- smart_send_to_qflist struggles with large search results,
              -- and when it fails will send all results to the qfixlist
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            },
          },
        },
        extensions = {
          file_browser = {
            theme = "ivy",
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
          },
        },
      })
      require("telescope").load_extension("file_browser")

      require("telescope").load_extension("changed_files")
    end,
    keys = {
      { "<leader>fs", ":Monzo jump_to_component_no_cd<CR>", desc = "Monzo jump to component" },
      { "<leader>fd", ":Monzo jump_to_downstream<CR>", desc = "Monzo jump to downstream" },
      { "<leader>E", ":Telescope file_browser<CR>", desc = "File browser at CWD" },
      { "<leader>e", ":Telescope file_browser path=%:p:h<CR>", desc = "File browser at buffer path" },
    },
  },
}
