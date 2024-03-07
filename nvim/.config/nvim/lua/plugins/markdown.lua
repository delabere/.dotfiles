return {
  -- install without yarn or npm
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },

    init = function()
      -- set to 1, nvim will open the preview window after entering the Markdown buffer
      -- default: 0
      vim.g.mkdp_auto_start = 0

      -- combine preview window
      -- default: 0
      -- if enable it will reuse previous opened preview window when you preview markdown file.
      -- ensure to set let g:mkdp_auto_close = 0 if you have enable this option
      vim.g.mkdp_combine_preview = 1

      -- auto refetch combine preview contents when change markdown buffer
      -- only when g:mkdp_combine_preview is 1
      vim.g.mkdp_combine_preview_auto_refresh = 1
    end,

    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
}
