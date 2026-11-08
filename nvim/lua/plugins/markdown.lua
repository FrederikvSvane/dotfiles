-- Cleaner markdown: render-markdown with heading icons, no markdownlint noise.
return {
  -- LazyVim's markdown extra enables markdownlint-cli2 (MD013 line-length etc.). Turn it off.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = { linters_by_ft = { markdown = {} } },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        -- LazyVim sets icons = {} (leaves raw "#"); restore distinct per-level icons
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        width = "block", -- background only behind the heading text, not the full line
        left_pad = 1,
        right_pad = 2,
        border = true, -- thin line above/below headings so they stand out
      },
    },
  },
}
