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
        adapters = {
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              name = "ollama",
              env = {
                url = "http://localhost:11434",
                api_key = "OLLAMA_API_KEY",
              },
              headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer ${api_key}",
              },
              parameters = {
                sync = true,
              },
              schema = {
                model = {
                  default = "qwen2.5-coder:7b",
                },
                num_ctx = {
                  default = 16384,
                },
                num_predict = {
                  default = -1,
                },
              },
            })
          end,
        },

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
            adapter = "ollama",
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
      })
    end,
  },
}
