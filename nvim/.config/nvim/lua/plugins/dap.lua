return {
  "mfussenegger/nvim-dap",
  -- stylua: ignore
  keys = {
    {
      "<F5>",
      function() require("dap").continue() end,
      desc =
      "Continue"
    },
    {
      "<F6>",
      function() require("dap").step_over() end,
      desc =
      "Step Over"
    },
    {
      "<F7>",
      function() require("dap").step_into() end,
      desc =
      "Step Into"
    },
    {
      "<F8>",
      function() require("dap").step_out() end,
      desc =
      "Step Out"
    },
    {
      "<F9>",
      function() require("dap").toggle_breakpoint() end,
      desc =
      "Toggle Breakpoint"
    },
    {
      "<leader>dB",
      function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end,
      desc =
      "Breakpoint Condition"
    },
    {
      "<leader>dC",
      function() require("dap").run_to_cursor() end,
      desc =
      "Run to Cursor"
    },
    {
      "<leader>dg",
      function() require("dap").goto_() end,
      desc =
      "Go to line (no execute)"
    },
    { "<leader>dj", function() require("dap").down() end, desc = "Down" },
    { "<leader>dk", function() require("dap").up() end,   desc = "Up" },
    {
      "<leader>dl",
      function() require("dap").run_last() end,
      desc =
      "Run Last"
    },
    { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
    {
      "<leader>dr",
      function() require("dap").repl.toggle() end,
      desc =
      "Toggle REPL"
    },
    {
      "<leader>ds",
      function() require("dap").session() end,
      desc =
      "Session"
    },
    {
      "<leader>dt",
      function() require("dap").terminate() end,
      desc =
      "Terminate"
    },
    {
      "<leader>dw",
      function() require("dap.ui.widgets").hover() end,
      desc =
      "Widgets"
    },
  },

  config = function()
    require("nvim-dap-virtual-text").setup({})
    require("dap-go").setup()
    require("dapui").setup({
      icons = { expanded = "▾", collapsed = "▸" },
      mappings = {
        -- Use a table to apply multiple mappings
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
      },
      -- Expand lines larger than the window
      -- Requires >= 0.7
      expand_lines = vim.fn.has("nvim-0.7"),
      -- Layouts define sections of the screen to place windows.
      -- The position can be "left", "right", "top" or "bottom".
      -- The size specifies the height/width depending on position.
      -- Elements are the elements shown in the layout (in order).
      -- Layouts are opened in order so that earlier layouts take priority in window sizing.
      layouts = {
        {
          elements = {
            -- Elements can be strings or table with id and size keys.
            { id = "scopes", size = 0.25 },
            "breakpoints",
            "stacks",
            "watches",
          },
          size = 40,
          position = "left",
        },
        {
          elements = {
            "repl",
            "console",
          },
          size = 10,
          position = "bottom",
        },
      },
      floating = {
        max_height = nil, -- These can be integers or a float between 0 and 1.
        max_width = nil, -- Floats will be treated as percentage of your screen.
        border = "single", -- Border style. Can be "single", "double" or "rounded"
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      windows = { indent = 1 },
      render = {
        max_type_length = nil, -- Can be integer or nil.
      },
    })

    local dap, dapui = require("dap"), require("dapui")
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end

    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end

    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end,
}
