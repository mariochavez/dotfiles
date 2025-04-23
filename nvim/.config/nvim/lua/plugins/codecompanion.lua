-- Choose default model from a list of preferred models. Fall back to first
-- available.
local function preferred_model_picker(preferred)
  return function(self)
    if self == nil then
      -- Debug:render() calls Adapter.schema.model.default() but doesn't pass
      -- in `self`. Just return an empty string in this case.
      return ""
    end

    local choices = self.schema.model.choices(self)

    for _, best in ipairs(preferred) do
      for _, choice in ipairs(choices) do
        if choice:find(best, 1, true) then
          return choice
        end
      end
    end

    return choices[1]
  end
end

local ollama_fn = function()
  return require("codecompanion.adapters").extend("ollama", {
    schema = {
      model = {
        default = preferred_model_picker({
        -- default = "deepseek-r1:8b",
          "qwen2.5-coder:7b",
          "qwen2.5-coder:32b",
        }),
        -- default = "llama3.1:8b",
        -- default = "codellama:7b",
      },
      env = {
        url = "http://localhost:11434",
        api_key = "OLLAMA_API_KEY",
      },
      num_ctx = {
        default = 16384,
      },
      num_predict = {
        default = -1,
      },
    },
  })
end

local supported_adapters = {
  -- anthropic = anthropic_fn,
  -- openai = openai_fn,
  ollama = ollama_fn,
}

local function save_path()
  local Path = require("plenary.path")
  local p = Path:new(vim.fn.stdpath("data") .. "/codecompanion_chats")
  p:mkdir({ parents = true })
  return p
end

--- Load a saved codecompanion.nvim chat file into a new CodeCompanion chat buffer.
--- Usage: CodeCompanionLoad
vim.api.nvim_create_user_command("CodeCompanionLoad", function()
  local fzf = require("fzf-lua")

  local function select_adapter(filepath)
    local adapters = vim.tbl_keys(supported_adapters)

    fzf.fzf_exec(adapters, {
      prompt = "Select CodeCompanion Adapter> ",
      actions = {
        ["default"] = function(selected)
          local adapter = selected[1]
          -- Open new CodeCompanion chat with selected adapter
          vim.cmd("CodeCompanionChat " .. adapter)

          -- Read contents of saved chat file
          local lines = vim.fn.readfile(filepath)

          -- Get the current buffer (which should be the new CodeCompanion chat)
          local current_buf = vim.api.nvim_get_current_buf()

          -- Paste contents into the new chat buffer
          vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
        end,
      },
    })
  end

  local function start_picker()
    local files = vim.fn.glob(save_path() .. "/*", false, true)

    fzf.fzf_exec(files, {
      prompt = "Saved CodeCompanion Chats | <c-r>: remove >",
      previewer = "builtin",
      actions = {
        ["default"] = function(selected)
          if #selected > 0 then
            local filepath = selected[1]
            select_adapter(filepath)
          end
        end,
        ["ctrl-r"] = function(selected)
          if #selected > 0 then
            local filepath = selected[1]
            os.remove(filepath)
            -- Refresh the picker
            start_picker()
          end
        end,
      },
    })
  end

  start_picker()
end, {})

--- Save the current codecompanion.nvim chat buffer to a file in the save_folder.
--- Usage: CodeCompanionSave <filename>.md
---@param opts table
vim.api.nvim_create_user_command("CodeCompanionSave", function(opts)
  local codecompanion = require("codecompanion")
  local success, chat = pcall(function()
    return codecompanion.buf_get_chat(0)
  end)
  if not success or chat == nil then
    vim.notify("CodeCompanionSave should only be called from CodeCompanion chat buffers", vim.log.levels.ERROR)
    return
  end
  if #opts.fargs == 0 then
    vim.notify("CodeCompanionSave requires at least 1 arg to make a file name", vim.log.levels.ERROR)
  end
  local save_name = table.concat(opts.fargs, "-") .. ".md"
  local save_file = save_path():joinpath(save_name)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  save_file:write(table.concat(lines, "\n"), "w")
end, { nargs = "*" })

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- "nvim-telescope/telescope.nvim", -- Optional: For using slash commands
      -- { "MeanderingProgrammer/render-markdown.nvim", ft = { "markdown", "codecompanion" } }, -- Optional: For prettier markdown rendering
      { "stevearc/dressing.nvim", opts = {} }, -- Optional: Improves `vim.ui.select`
      {
        "saghen/blink.cmp",
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
          sources = {
            default = { "codecompanion" },
            providers = {
              codecompanion = {
                name = "CodeCompanion",
                module = "codecompanion.providers.completion.blink",
                enabled = true,
              },
            },
          },
        },
        opts_extend = {
          "sources.default",
        },
      },
    },
    config = function()
      require("codecompanion").setup({
        adapters = supported_adapters,

        strategies = {
          chat = {
            adapter = "ollama",
            slash_commands = {
              ["buffer"] = {
                opts = {
                  provider = "fzf_lua", -- default|telescope|mini_pick|fzf_lua
                },
              },

              ["file"] = {
                opts = {
                  provider = "fzf_lua", -- default|telescope|mini_pick|fzf_lua
                },
              },

              ["help"] = {
                opts = {
                  provider = "fzf_lua", -- telescope|mini_pick|fzf_lua
                },
              },

              ["symbols"] = {
                opts = {
                  provider = "fzf_lua", -- default|telescope|mini_pick|fzf_lua
                },
              },
            },
          },
          inline = {
            adapter = "ollama_q7",
          },
        },
        display = {
          chat = {
            show_settings = true,
          },
          action_palette = {
            provider = "default", -- default|telescope|mini_pick
          },
          diff = {
            provider = "default", -- default|mini_diff
          },
        },
        prompt_library = {
          ["Rails Dev (Solorails)"] = {
            strategy = "chat",
            description = "Rails Dev (Solorails)",
            prompts = {
              {
                role = "system",
                content = [[You are an expert Ruby on Rails developer with deep knowledge of modern Rails practices and patterns. Help me write professional, well-crafted code following these guidelines:

Code Style:
- Follow Ruby/Rails best practices and conventions
- Keep code DRY and modular
- Use meaningful variable/method names
- Add comments only for complex logic

Testing (when requested):
- Use RSpec with minimal setup
- For HTTP testing:
  - Use WebMock for request stubs
  - Create helper methods for dynamic headers/body/status
  - No need to mock/stub unless specified

Frontend:
- Use Hotwired (Turbo + Stimulus) by default
- Implement UI with Tailwind CSS
- Use Shadcn/ui-style components
- Extract complex components into helper files
- Follow View Component pattern for reusable elements

Documentation (when requested):
- Use RDoc format
- Document classes, modules, and methods
- Include usage examples when helpful
- Specify parameter types and return values
- Document exceptions/errors when relevant
- Follow standard RDoc tags and conventions

Communication:
- Don't explain code unless asked
- Acknowledge shared code with brief confirmation
- Only suggest improvements when requested
- Provide context only when needed]],
              },
              {
                role = "user",
                content = "Be helpful and concise, don't respond if you are not explicitly asked to give an asnwer or a solution.\n",
              },
            },
          },
        },
      })
    end,
    keys = {
      { "<leader>ao", ":CodeCompanionChat Toggle<CR>", desc = "Codecompanion Toggle" },
      {
        "<leader>as",
        function()
          local name = vim.fn.input("Save as: ")
          if name and name ~= "" then
            vim.cmd("CodeCompanionSave " .. name)
          end
        end,
        desc = "Codecompanion Save chat",
      },
      { "<leader>al", ":CodeCompanionLoad<CR>", desc = "Codecompanion Load chat" },
      { "<leader>ap", ":CodeCompanionActions<CR>", desc = "Codecompanion Prompts" },
    },
  },
}
