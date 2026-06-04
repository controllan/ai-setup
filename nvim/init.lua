local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.keymap.set("n", "<Esc>", vim.cmd.nohlsearch, { desc = "clear highlights" })
vim.keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "open netrw" })
vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "save file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>", { desc = "quit" })
vim.keymap.set("n", "<leader>qq", "<cmd>qa<CR>", { desc = "quit all" })

require("lazy").setup({
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "go", "html", "javascript", "java", "python", "lua", "tsx", "typescript", "css", "json", "yaml", "markdown" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = { "gopls", "html", "ts_ls", "jdtls", "pyright" },
      automatic_installation = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()
      for _, c in pairs({ capabilities, cmp_capabilities }) do
        c.textDocument = c.textDocument or {}
        c.textDocument.completion = c.textDocument.completion or {}
        c.textDocument.completion.dynamicRegistration = true
        c.textDocument.completion.completionItem = c.textDocument.completion.completionItem or {}
        c.textDocument.completion.completionItem.snippetSupport = true
      end

      local on_attach = function(_, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "gd", vim.lsp.buf.definition, "goto definition")
        map("n", "K", vim.lsp.buf.hover, "hover docs")
        map("n", "gi", vim.lsp.buf.implementation, "goto implementation")
        map("n", "gr", vim.lsp.buf.references, "goto references")
        map("n", "<leader>rn", vim.lsp.buf.rename, "rename")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "code action")
        map("n", "<leader>d", vim.diagnostic.open_float, "line diagnostics")
        map("n", "[d", vim.diagnostic.goto_prev, "prev diagnostic")
        map("n", "]d", vim.diagnostic.goto_next, "next diagnostic")
      end

      local servers = { "gopls", "html", "ts_ls", "jdtls", "pyright" }
      for _, server in ipairs(servers) do
        lspconfig[server].setup({
          on_attach = on_attach,
          capabilities = cmp_capabilities,
        })
      end
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },
  {
    "folke/which-key.nvim",
    config = function()
      require("which-key").setup()
    end,
  },
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "find files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "live grep" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "find buffers" },
      { "<leader>fh", "<cmd>FzfLua help_tags<CR>", desc = "help tags" },
    },
    config = function()
      require("fzf-lua").setup({
        -- builtin fuzzy finder — no external deps needed after neovim 0.10
      })
    end,
  },
}, {
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})

vim.cmd.colorscheme("habamax")
