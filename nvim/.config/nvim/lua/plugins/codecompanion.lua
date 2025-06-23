return {
  {
    -- CodeCompanion plugin for AI-assisted development
    "olimorris/codecompanion.nvim",
    -- Required dependencies
    dependencies = {
      "nvim-lua/plenary.nvim",      -- Lua utility functions
      "nvim-treesitter/nvim-treesitter", -- For syntax understanding
    },
    opts = {
      -- Configure AI adapters that will be used
      adapters = {
        -- Copilot adapter configuration
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = {
              model = {
                -- See https://codecompanion.olimorris.dev/usage/chat-buffer/agents.html#compatibility for supported models
                default = "claude-3.7-sonnet", -- Default AI model to use (note: may not support @editor command)
              },
            },
          })
        end,
      },
      -- Define strategies for different interaction modes
      strategies = {
        chat = {
          adapter = "copilot", -- Use Copilot for chat interactions
        },
        inline = {
          adapter = "copilot", -- Use Copilot for inline completions
        },
        agent = {
          adapter = "copilot", -- Use Copilot for agent-based operations
        },
      },
      -- Custom prompt templates library
      prompt_library = {
        ["Monzo"] = {
          strategy = "chat",           -- Use chat strategy for this prompt
          description = "Help me to write code", -- Description shown in UI
          opts = {
            index = 11,              -- Position in the prompt list
            is_slash_cmd = false,    -- Not accessible via slash command
            auto_submit = false,     -- Don't auto-submit prompt
            short_name = "monzo",    -- Short name for quick access
          },
          -- Include reference files for context
          references = {
            {
              type = "file",
              path = {
                -- Reference paths to organization coding guidelines
                -- Note: These are relative paths that only work within wearedev environment
                "./.cursor/rules/general.mdc",
                "./.cursor/rules/monzo-go.mdc",
                "./.cursor/rules/protobufs.mdc",
                "./.cursor/rules/unit-testing.mdc",
                "./.cursor/rules/wearedev",
                "./.cursor/rules/wearedev.mdc",
              },
            },
          },
          -- Initial prompt messages to set context
          prompts = {
            {
              role = "user",
              content = [[ I am writing code at my organisation, the files I have shared provide a good guide on how my organisation writes code. Please make sure to follow the guidelines when suggesting changes. We write code in golang.]],
            },
          },
        },
      },
    },
  },
}
