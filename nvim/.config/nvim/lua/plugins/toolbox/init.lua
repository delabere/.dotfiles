local Snacks = require("snacks")

local M = {}
local path_join = function(...)
  local args = { ... }
  return table.concat(args, "/")
end
local function get_items(find_cmd_table)
  if not find_cmd_table or type(find_cmd_table) ~= "table" then
    print("Error: find_cmd_table is nil or not a table")
    return {}
  end
  print("Executing command: " .. table.concat(find_cmd_table, " "))
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

local function previewer(item)
  local readme_path = M.path_join(item.full_path, "README.md")
  if vim.fn.filereadable(readme_path) == 1 then
    local contents = vim.fn.readfile(readme_path)
    return table.concat(contents, "\n")
  end
  return "No README.md found in " .. item.full_path
end

local function jump_to_component(prompt_title, find_cmd, change_directory)
  local items = get_items(find_cmd)
  Snacks.picker({
    title = prompt_title,
    source = "jump_to_component",
    items = items,
    format = function(item, picker)
      return { { item.text, "Normal" } }
    end,
    previewer = previewer,
    confirm = function(picker, item)
      picker:close()
      local full_path = items[item.idx].full_path
      print("Opening (default): " .. full_path)
      vim.cmd("e " .. vim.fn.fnameescape(full_path))
      if change_directory then
        vim.cmd("lcd " .. vim.fn.fnameescape(full_path))
      end
    end,
  })
end

local home = os.getenv("HOME")
M.path_join = path_join
M.wearedev_base = path_join(home, "src", "github.com", "monzo", "wearedev")

M.jump_to_component_no_cd = function()
  jump_to_component("Jump to Component", {
    "find",
    "-E",
    M.wearedev_base,
    "-type",
    "d",
    "-regex",
    ".*(service|cron|web)\\.[^/]*",
    "-maxdepth",
    "1",
  }, false)
end

return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>fs",
      M.jump_to_component_no_cd,
      desc = "Jump to Component",
    },
  },
}
