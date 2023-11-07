return {
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                "black",
                "debugpy",
                "go-debug-adapter",
                "gopls",
                "pyright",
                "rnix-lsp",
                "shfmt",
                "stylua",
                -- "flake8",
            },
        },
    },
}
