return {
  {
    "stevearc/oil.nvim",
    -- stylua: ignore
    keys = {
        {"<leader>o", "<CMD>Oil<CR>", desc = "Oil"},
    },
    opts = {
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
      },

      -- See :help oil-actions for a list of all available actions
      keymaps = {
        ["?"] = "actions.show_help",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-x>"] = "actions.select_split",
        ["<BS>"] = "actions.parent",
        ["<C-h>"] = false,
        ["<C-l>"] = false,
      },
    },
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
}
