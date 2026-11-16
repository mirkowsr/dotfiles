return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    picker = {
      exclude = {
        -- add folder names here to exclude
        ".git",
        "node_modules",
      },
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
        files = {
          hidden = true,
          ignored = true,
        },
      },
    },
    terminal = {
      win = {
        position = "right",
      },
    },
  },
}
