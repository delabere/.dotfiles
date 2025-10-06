local Snacks = require("snacks")
local oil = require("oil")

local M = {}

-- Helper function to get the directory from oil buffer or current file
M.get_current_directory = function()
  local oil_dir = oil.get_current_dir()
  if oil_dir then
    return oil_dir
  end
  return vim.fn.expand("%:p:h")
end

local path_join = function(...)
  local args = { ... }
  return table.concat(args, "/")
end

M.get_items = function(find_cmd_table)
  local result = vim.system(find_cmd_table, { text = true }):wait()
  local output = result.stdout
  local code = result.code

  if code ~= 0 or not output or output == "" then
    print("Command failed or no output: " .. (result.stderr or "No error message"))
    return {}
  end

  local items = {}
  for dir in output:gmatch("[^\n]+") do
    table.insert(items, dir)
  end

  local items_with_text = {}
  for _, full_path in ipairs(items) do
    local directory_name = full_path:match("([^/]+)$") or full_path
    table.insert(items_with_text, {
      text = directory_name,
      full_path = full_path,
      file = M.path_join(full_path, "README.md"),
    })
  end

  return items_with_text
end
---@param p snacks.Picker
M.filter_test_files_new = function(p)
  p._test_filter = not p._test_filter
  local pattern = p._test_filter and "!_test.go" or ""
  p.matcher:init(pattern)
  p.input.filter.pattern = pattern
  p.matcher:run(p)
  p:update_titles()
end

---@param item snacks.picker.Item
M.readme_previewer = function(item)
  local readme_path = M.path_join(item.full_path, "README.md")
  if vim.fn.filereadable(readme_path) == 1 then
    local contents = vim.fn.readfile(readme_path)
    return table.concat(contents, "\n")
  end
  return "No README.md found in " .. item.full_path
end

local home = os.getenv("HOME")
M.path_join = path_join
M.wearedev_base = path_join(home, "src", "github.com", "monzo", "wearedev")

M.picker_goto_service_no_cd = function()
  local services = M.get_items({
    "find",
    "-E",
    M.wearedev_base,
    "-type",
    "d",
    "-regex",
    ".*(service|cron|web)\\.[^/]*",
    "-maxdepth",
    "1",
  })

  Snacks.picker({
    title = "Jump to Service",
    source = "jump_to_service",
    items = services,

    format = function(item)
      return { { item.text, "Normal" } }
    end,

    previewer = M.readme_previewer,

    confirm = function(picker, item)
      picker:close()
      local full_path = services[item.idx].full_path
      -- Snacks.picker.files({ cwd = full_path })
      -- Snacks.explorer({ cwd = full_path })
      oil.open(full_path)
    end,
  })
end

return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      matcher = { frecency = true },
      actions = {
        toggle_test_filter = M.filter_test_files_new,
      },
      win = {
        input = {
          keys = {
            ["<c-f>"] = {
              "toggle_test_filter",
              mode = { "n", "i" },
            },
          },
        },
      },
    },
  },
    -- stylua: ignore
  keys = {
        -- Custom/work
    { "<leader>fs", M.picker_goto_service_no_cd, desc = "Jump to Component"},
        -- File/text search that respects oil directory
    { "<leader><space>", function() Snacks.picker.files({ cwd = M.get_current_directory() }) end, desc = "Find Files (Oil-aware)" },
    { "<leader>ff", function() Snacks.picker.files({ cwd = M.get_current_directory() }) end, desc = "Find Files (Oil-aware)" },
    { "<leader>gs", function() Snacks.picker.grep({ cwd = M.get_current_directory() }) end, desc = "Grep (Oil-aware)" },
        -- LSP
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gi", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gt", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
  },
}
