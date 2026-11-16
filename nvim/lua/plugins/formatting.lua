return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        prettier = {
          prepend_args = {
            "--embedded-language-formatting",
            "off",
          },
        },
      },

      formatters_by_ft = {
        markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
      },
    },
  },
}
