-- LSP + completion, on Neovim 0.11's native API.
--
-- This replaced lsp-zero v2.x. lsp-zero was pinned to a Jan-2024 release that
-- drove LSP through `require('lspconfig')`, the old "framework" API. On 0.11
-- that printed a deprecation traceback on every buffer open, and
-- nvim-lspconfig v3.0.0 removes it outright.
--
-- The pieces now:
--   mason.nvim            installs server binaries
--   mason-lspconfig (v2)  bridges mason <-> lspconfig names, and calls
--                         vim.lsp.enable() for anything installed
--   nvim-lspconfig        ships the per-server config files (lsp/*.lua) that
--                         vim.lsp.config reads -- it is data now, not a framework
--   nvim-cmp              completion, wired to LSP via cmp_nvim_lsp capabilities

require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = {
    "ansiblels",
    "html",
    "lua_ls",
  },
  -- v2 default: every installed server is vim.lsp.enable()d automatically,
  -- which is why there is no setup_handlers/per-server .setup() call here.
  automatic_enable = true,
})

-- ---------------------------------------------------------------------------
-- Capabilities: advertise nvim-cmp's completion support to every server.
-- '*' is a wildcard config that 0.11 merges into each server.
-- ---------------------------------------------------------------------------
vim.lsp.config("*", {
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

-- Fix "Undefined global 'vim'" -- the old lsp.nvim_workspace() equivalent.
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

-- ---------------------------------------------------------------------------
-- Buffer-local keymaps, on LspAttach (replaces lsp-zero's on_attach).
-- ---------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("itsborkedagain_lsp_attach", { clear = true }),
  callback = function(event)
    local opts = { buffer = event.buf, remap = false }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
    vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
    vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)

    -- "]" forward, "[" backward. vim.diagnostic.jump replaces the deprecated
    -- goto_next/goto_prev.
    vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
  end,
})

-- ---------------------------------------------------------------------------
-- Diagnostics (sign icons moved here from lsp.set_preferences)
-- ---------------------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN]  = "W",
      [vim.diagnostic.severity.HINT]  = "H",
      [vim.diagnostic.severity.INFO]  = "I",
    },
  },
})

-- ---------------------------------------------------------------------------
-- Completion. Keymaps preserved from the old lsp-zero cmp_mappings, including
-- <Tab>/<S-Tab> deliberately left unmapped.
-- ---------------------------------------------------------------------------
local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
  snippet = {
    expand = function(args) require("luasnip").lsp_expand(args.body) end,
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
  }),
  mapping = cmp.mapping.preset.insert({
    ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
    ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<Tab>"] = vim.NIL,
    ["<S-Tab>"] = vim.NIL,
  }),
})
