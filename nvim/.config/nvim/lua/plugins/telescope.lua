return {
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
              -- smart_send_to_qflist struggles with large search results,
              -- and when it fails will send all results to the qfixlist
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            },
            n = {
              -- smart_send_to_qflist struggles with large search results,
              -- and when it fails will send all results to the qfixlist
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            },
          },
        },
        extensions = {
          file_browser = {
            initial_mode = "normal",
            theme = "ivy",
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
          },
        },
      })
      require("telescope").load_extension("file_browser")

      require("telescope").load_extension("changed_files")
      require("telescope").load_extension("harpoon")
    end,
    keys = {
      { "<leader>fs", ":Monzo jump_to_component_no_cd<CR>", desc = "Monzo jump to component" },
      { "<leader>fd", ":Monzo jump_to_downstream<CR>", desc = "Monzo jump to downstream" },
      { "<leader>fc", "<cmd>Telescope changed_files<CR>", desc = "Find files changed on this branch" },
      { "<leader>E", ":Telescope file_browser<CR>", desc = "File browser at CWD" },
      { "<leader>e", ":Telescope file_browser path=%:p:h<CR>", desc = "File browser at buffer path" },
    },
  },
}
