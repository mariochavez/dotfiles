-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
vim.fn.serverstart("/tmp/nvim-" .. project_name .. ".sock")
