return {
  {
    "nvim-neotest/neotest-plenary",
  },
  {
    "olimorris/neotest-rspec",
  },
  {
    "zidhuss/neotest-minitest",
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/nvim-nio", "nvim-lua/plenary.nvim" },
    opts = { adapters = { "neotest-plenary", "neotest-rspec", "neotest-minitest" } },
  },
}
