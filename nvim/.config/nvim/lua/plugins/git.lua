return {
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    opts = {
      enabled = true,
      message_template = "<author> • <date> • <summary> • <<sha>>",
      delay = 3000,
      virtual_text_column = 121,
    },
    keys = {
      { "<leader>gB", "<cmd>GitBlameToggle<cr>", desc = "Toggle blame information" },
      -- { "<leader>bB", "<cmd>GitBlameOpenFileURL<cr>", desc = "Open blame in browser" },
    },
  },
}
