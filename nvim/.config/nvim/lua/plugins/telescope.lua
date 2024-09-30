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
      local action_state = require("telescope.actions.state")
      local finders = require("telescope.finders")

      -- Custom action to filter out _test.go files
      local function filter_out_test_files(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local manager = picker.manager

        -- Collect the current results (full entries)
        local original_results = {}
        for entry in manager:iter() do
          table.insert(original_results, entry)
        end

        -- Filter out entries ending with _test.go
        local filtered_results = {}
        for _, entry in ipairs(original_results) do
          if not string.match(entry.value, "_test%.go") then
            table.insert(filtered_results, entry)
          end
        end

        -- Refresh the picker with the filtered results
        picker:refresh(
          finders.new_table({
            results = filtered_results,
            entry_maker = function(entry)
              return entry -- Return the full entry object
            end,
          }),
          {
            reset_prompt = false, -- Keep the current prompt text
          }
        )
      end

      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              -- smart_send_to_qflist struggles with large search results,
              -- and when it fails will send all results to the qfixlist
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              -- Map <C-f> to filter out _test.go files
              ["<C-f>"] = filter_out_test_files,
            },
            n = {
              -- smart_send_to_qflist struggles with large search results,
              -- and when it fails will send all results to the qfixlist
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<C-f>"] = filter_out_test_files,
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
