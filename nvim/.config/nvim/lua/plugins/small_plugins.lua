return {
  {
    -- github PR reviews in nvim
    -- "pwntester/octo.nvim",
    -- TODO: go back to pwntester if my pr gets merged in
    -- https://github.com/pwntester/octo.nvim/pull/538
    "delabere/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    event = { { event = "BufReadCmd", pattern = "octo://*" } },
    opts = {
      enable_builtin = true,
      use_local_fs = true,
      suppress_missing_scope = {
        projects_v2 = true,
      },
    },
    keys = {
      { "<leader>gi", "<cmd>Octo issue list<CR>", desc = "List Issues (Octo)" },
      { "<leader>gI", "<cmd>Octo issue search<CR>", desc = "Search Issues (Octo)" },
      { "<leader>gp", "<cmd>Octo pr list<CR>", desc = "List PRs (Octo)" },
      { "<leader>gP", "<cmd>Octo pr search<CR>", desc = "Search PRs (Octo)" },
      { "<leader>gr", "<cmd>Octo repo list<CR>", desc = "List Repos (Octo)" },
      { "<leader>gS", "<cmd>Octo search<CR>", desc = "Search (Octo)" },

      { "<leader>a", "", desc = "+assignee (Octo)", ft = "octo" },
      { "<leader>c", "", desc = "+comment/code (Octo)", ft = "octo" },
      { "<leader>l", "", desc = "+label (Octo)", ft = "octo" },
      { "<leader>i", "", desc = "+issue (Octo)", ft = "octo" },
      { "<leader>r", "", desc = "+react (Octo)", ft = "octo" },
      { "<leader>p", "", desc = "+pr (Octo)", ft = "octo" },
      { "<leader>v", "", desc = "+review (Octo)", ft = "octo" },
      { "@", "@<C-x><C-o>", mode = "i", ft = "octo", silent = true },
      { "#", "#<C-x><C-o>", mode = "i", ft = "octo", silent = true },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
        python = { "ruff_format", "isort" },
        -- python = { "isort", "black" },
        go = { "gopls" },
        nix = { "nixpkgs_fmt" },
        rust = { "rustfmt" },
        templ = { "templ" },
        -- svelte = { "prettierd", "prettier", "svelte", lsp_format = "fallback" },
      },
    },
  },

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

  -- { "tpope/vim-surround" },

  -- debugger configuration for go
  { "ruanyl/vim-gh-line" },
  {
    "ruifm/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },

    config = function()
      local hosts = require("gitlinker.hosts")
      local actions = require("gitlinker.actions")

      -- Store the original github callback
      local original_github_callback = hosts.get_github_type_url

      -- Create a wrapper that prompts for branch choice
      local function github_with_branch_prompt(url_data)
        -- Store original rev
        local original_rev = url_data.rev

        -- Show prompt
        vim.ui.select(
          { "Current branch/commit", "master" },
          {
            prompt = "Generate permalink for:",
          },
          function(choice)
            if not choice then
              return
            end

            -- Modify rev if master is chosen
            if choice == "master" then
              url_data.rev = "master"
            end

            -- Generate URL with the original callback
            local url = original_github_callback(url_data)

            -- Copy to clipboard and notify
            vim.fn.setreg("+", url)
            vim.notify("Copied: " .. url)

            -- Restore original rev for any subsequent calls
            url_data.rev = original_rev
          end
        )

        -- Return empty string to prevent default action_callback from running
        return ""
      end

      require("gitlinker").setup({
        callbacks = {
          ["github.com"] = github_with_branch_prompt,
        },
        action_callback = function(url)
          -- Don't do anything if url is empty (handled by our callback)
          if url ~= "" then
            actions.copy_to_clipboard(url)
          end
        end,
        print_url = false,
      })
    end,
  },

  { "folke/zen-mode.nvim" },

  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        -- the default blue for todo's is a little garish
        TODO = { icon = " ", color = "hint" },
      },
    },
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-go" },
    config = function()
      -- get neotest namespace (api call creates or returns namespace)
      local neotest_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
      }, neotest_ns)

      local go_adapter = require("neotest-go")({
        experimental = {
          test_table = true,
        },
        args = { "-count=1", "-timeout=60s" },
      })

      go_adapter.root = function()
        local this_file_directory = vim.fn.fnamemodify(vim.fn.expand("%"), ":p:h")
        print("setting go adapter root", this_file_directory)
        return this_file_directory
      end

      require("neotest").setup({
        discovery = {
          filter_dir = function(name, rel_path, root)
            print("name: ", name, "rel_path", rel_path, "root", root)
            if root == "/Users/jackrickards/src/github.com/monzo/wearedev" then
              return false
            end
            return true
          end,
        },
        adapters = {
          go_adapter,
        },
      })
    end,

  -- stylua: ignore
    keys = {
      { "<leader>t", "", desc = "+test" },
      { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File", },
      -- { "<leader>tT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files" },
      { "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest", },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last", },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary", },
      { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output", },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel", },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop", },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch", },
      { "<leader>tT", function() require("neotest").run.run(vim.fn.fnamemodify(vim.fn.expand("%"), ":p:h")) end, desc = "Run All Test Files", },
    },
  },

  {
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>hh", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", desc = "toggle_quick_menu" },
      { "<leader>ha", "<cmd>lua require('harpoon.mark').add_file()<cr>", desc = "add_file" },
      { "<leader>ht", "<cmd>Telescope harpoon marks<cr>", desc = "telescope_marks" },
    },
  },
  "Hoffs/omnisharp-extended-lsp.nvim",
  {
    "nvim-mini/mini.surround",
    version = "*",
    opts = {
      search_method = "cover_or_next",
      mappings = {
        add = "sa", -- Add surrounding in Normal and Visual modes
        delete = "sd", -- Delete surrounding
        find = "sf", -- Find surrounding (to the right)
        find_left = "sF", -- Find surrounding (to the left)
        highlight = "sh", -- Highlight surrounding
        replace = "sr", -- Replace surrounding
        update_n_lines = "sn", -- Update `n_lines`

        suffix_last = "l", -- Suffix to search with "prev" method
        suffix_next = "n", -- Suffix to search with "next" method
      },
    },
  },
}
