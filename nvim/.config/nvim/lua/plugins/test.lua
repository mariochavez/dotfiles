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
    opts = { adapters = { "neotest-plenary", "neotest-rspec", "neotest-minitest" } },
  },
}
