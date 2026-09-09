return {
  {
    dir = "~/src/github.com/delabere/gander.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    cmd = { "Gander", "GanderClose", "GanderStatus" },
    opts = {
      exclude_globs = {
        "**/proto/*.{pb,router,typhon,validator}.go", -- generated proto code
      },
    },
    config = function(_, opts)
      require("gander").setup(opts)
    end,
  },
}
