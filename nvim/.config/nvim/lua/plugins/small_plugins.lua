-- my own prododef plugin
return {
  { "delabere/protodef" },

  -- navigate between other tmux panes
  {
    "christoomey/vim-tmux-navigator",

    keys = {

      { "<C-h>", "<C-U>TmuxNavigateRight<cr>", desc = "Tmux Navigate Right" },
      { "<C-k>", "<C-U>TmuxNavigateUp<cr>", desc = "Tmux Navigate Up" },
      { "<C-j>", "<C-U>TmuxNavigateDown<cr>", desc = "Tmux Navigate Down" },
      { "<C-l>", "<C-U>TmuxNavigateLeft<cr>", desc = "Tmux Navigate Left" },
    },
  },

  { "tpope/vim-surround" },

  -- auto save all open buffers on any file change
  {
    "907th/vim-auto-save",

    config = function()
      vim.g.auto_save = 1
      vim.g.auto_save_in_insert_mode = 0
      vim.g.auto_save_silent = 1
    end,
  },

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "go",
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },

  -- it is not clear that any of these are needed 👇
  {
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-calc",
    "f3fora/cmp-spell",
    "tamago324/cmp-zsh",
    "quangnguyen30192/cmp-nvim-ultisnips",
    "hrsh7th/cmp-nvim-lsp-signature-help",
  },

  -- debugger configuration for go
  { "leoluz/nvim-dap-go" },

  {
    "mfussenegger/nvim-dap",

    dependencies = {

      -- fancy UI for the debugger
      {
        "rcarriga/nvim-dap-ui",
      -- stylua: ignore
        opts = {},
        config = function(_, opts)
          require("dap-go").setup()

          local dap = require("dap")
          local dapui = require("dapui")
          dapui.setup(opts)
          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open({})
          end
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close({})
          end
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close({})
          end
        end,
      },
    },

  -- stylua: ignore
  keys = {
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
    { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<leader>dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>dj", function() require("dap").down() end, desc = "Down" },
    { "<leader>dk", function() require("dap").up() end, desc = "Up" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
    { "<leader>dr", function() require("dap").repl.open() end, desc = "Repl" },
    { "<leader>ds", function() require("dap").session() end, desc = "Session" },
    { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
  },

    config = function()
      local Config = require("lazyvim.config")
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      for name, sign in pairs(Config.icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end
    end,
  },
}
