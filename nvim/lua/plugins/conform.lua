local util = require("conform.util")

return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      opts.formatters.oxfmt = {
        command = "oxfmt",
        args = {
          "--stdin-filepath",
          "$FILENAME",
          "-",
        },
        stdin = true,
        condition = function(_, ctx)
          return vim.fn.executable("oxfmt") == 1
            and util.root_file({
                ".oxfmtrc",
                ".oxfmtrc.json",
                ".oxfmtrc.jsonc",
                "oxfmt.config.ts",
                "oxfmt.config.mts",
              })(nil, ctx)
              ~= nil
        end,
      }

      opts.formatters.prettier = {
        condition = function(_, ctx)
          return vim.fn.executable("prettier") == 1
            and util.root_file({
                ".prettierrc",
                ".prettierrc.json",
                ".prettierrc.js",
                ".prettierrc.cjs",
                "prettier.config.js",
                "prettier.config.cjs",
              })(nil, ctx)
              ~= nil
        end,
      }

      for _, filetype in ipairs({
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "jsonc",
      }) do
        opts.formatters_by_ft[filetype] = {
          "oxfmt",
          "prettier",
          stop_after_first = true,
        }
      end
    end,
  },
}
