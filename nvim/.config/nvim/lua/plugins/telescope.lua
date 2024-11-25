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

    -- this function doesn't work on some telescope picker results
    -- "string expected, not table"
    config = function()
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local finders = require("telescope.finders")

      -- Custom action to toggle filter of _test.go files
      local function toggle_test_file_filter(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)

        -- Initialize filter_active and store all_results if not already stored
        if picker.filter_active == nil then
          picker.filter_active = false
          -- Store the initial, unfiltered results
          picker.all_results = {}
          for entry in picker.manager:iter() do
            table.insert(picker.all_results, entry)
          end
        end

        -- Toggle filter_active
        picker.filter_active = not picker.filter_active

        local filtered_results = {}
        if picker.filter_active then
          -- Filter out entries containing _test.go
          for _, entry in ipairs(picker.all_results) do
            local filename = entry.value["filename"] ~= "" and entry.value["filename"] or entry.value
            if not string.match(filename, "_test%.go") then
              table.insert(filtered_results, entry)
            end
          end
        else
          -- No filtering, use all_results
          filtered_results = picker.all_results
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
              -- Map <C-f> to toggle filter of _test.go files
              ["<C-f>"] = toggle_test_file_filter,
            },
            n = {
              -- smart_send_to_qflist struggles with large search results,
              -- and when it fails will send all results to the qfixlist
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<C-f>"] = toggle_test_file_filter,
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
