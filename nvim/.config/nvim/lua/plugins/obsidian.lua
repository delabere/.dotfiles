return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = false,
  ft = "markdown",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-telescope/telescope.nvim" },
    { "hrsh7th/nvim-cmp" },
    { "nvim-treesitter/nvim-treesitter" },
  },
  opts = {
    templates = {
      folder = "templates",
      date_format = "%Y-%m-%d-%a",
      time_format = "%H:%M",
    },
    workspaces = {
      {
        name = "notes",
        path = "~/notes",
      },
    },

    -- Optional, configure key mappings. These are the defaults. If you don't want to set any keymappings this
    -- way then set 'mappings = {}'.
    -- stylua: ignore
    mappings = {
      ["gd"] = { action = function() return require("obsidian").util.gf_passthrough() end, opts = { noremap = false, expr = true, buffer = true, desc = "Go to note" } },
      ["gr"] = { action = function() return "<cmd>ObsidianBacklinks<CR>" end, opts = { noremap = false, expr = true, buffer = true, desc = "Obsidian Backlinks" } },
      ["<leader>nn"] = { action = function() return "<cmd>ObsidianNew<CR>" end, opts = { noremap = false, expr = true, buffer = true, desc = "New note" } },
      ["<leader>os"] = { action = function() return "<cmd>ObsidianSearch<CR>" end, opts = { noremap = false, expr = true, buffer = true, desc = "Obsidian search" } },
      ["<leader>op"] = { action = function() return "<cmd>ObsidianPasteImg<CR>" end, opts = { noremap = false, expr = true, buffer = true, desc = "Paste image" } },
      ["<leader>ch"] = { action = function() return require("obsidian").util.toggle_checkbox() end, opts = { buffer = true } },
    },

    -- Optional, customize how note IDs are generated given an optional title.
    ---@param title string|?
    ---@return string
    note_id_func = function(title)
      -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
      -- In this case a note with the title 'My new note' will be given an ID that looks
      -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
      local suffix = ""
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. "-" .. suffix
    end,

    follow_url_func = function(url)
      -- Open the URL in the default web browser.
      vim.fn.jobstart({ "open", url }) -- Mac OS
      -- vim.fn.jobstart({"xdg-open", url})  -- linux
    end,
  },
}
