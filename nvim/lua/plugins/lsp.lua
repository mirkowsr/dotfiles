return {
  -- pyright; mason installs it automatically
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {},
        -- preserve prior typescript-tools import behavior
        vtsls = {
          settings = {
            typescript = {
              preferences = {
                importModuleSpecifierPreference = "non-relative",
                includePackageJsonAutoImports = "on",
                useAliasesForRenames = false,
              },
            },
          },
        },
      },
    },
  },
}
