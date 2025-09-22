-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Start the server if it's not running
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
vim.fn.serverstart("/tmp/nvim-" .. project_name .. ".sock")

-- Enable HERB language server
vim.lsp.enable("herb_ls")
