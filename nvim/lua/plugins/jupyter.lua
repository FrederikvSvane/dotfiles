-- Jupyter notebooks in the terminal: open .ipynb as plain text (jupytext),
-- run cells with molten, show plots inline with image.nvim (kitty graphics
-- protocol). Python side lives in a dedicated venv created by setup.sh.
local host = vim.fn.stdpath("data") .. "/python-host"

-- jupyter_client does not create its runtime dir, and a fresh host has none.
local function init_kernel()
  local jupyter = host .. "/bin/jupyter"
  if vim.fn.executable(jupyter) == 1 then
    vim.fn.mkdir(vim.trim(vim.fn.system({ jupyter, "--runtime-dir" })), "p")
  end
  vim.cmd("MoltenInit")
end

-- Play an animation/video file: nvim's own terminal cannot show images, so run
-- the viewer in a tmux split, or suspend nvim with :! when outside tmux.
-- gif/webp/png use kitty's icat (works over ssh); video needs mpv --vo=kitty
-- (local only, and not inside tmux).
local function play(path)
  path = vim.fn.fnamemodify(path, ":p")
  if vim.fn.filereadable(path) == 0 then
    return vim.notify("not a file: " .. path, vim.log.levels.WARN)
  end
  local image = path:match("%.gif$") or path:match("%.webp$") or path:match("%.png$")
  local cmd = image and { "kitten", "icat", "--loop=-1", "--hold", path }
    or { "mpv", "--vo=kitty", "--vo-kitty-use-shm=yes", "--loop", path }
  if vim.fn.executable(cmd[1]) == 0 then
    return vim.notify(cmd[1] .. " is not installed", vim.log.levels.WARN)
  end
  local line = table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " ")
  if vim.env.TMUX then
    vim.fn.system({ "tmux", "split-window", "-v", "-c", vim.fn.getcwd(), line })
  else
    vim.cmd("!" .. line)
  end
end

-- Run the fenced ```python block under the cursor (notebooks open as markdown).
local function run_cell()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local first, last
  for i = row, 1, -1 do
    if lines[i]:match("^```") then first = i; break end
  end
  if not first or not lines[first]:match("^```%s*{?%.?%w") then
    return vim.notify("cursor is not inside a code block", vim.log.levels.WARN)
  end
  for i = first + 1, #lines do
    if lines[i]:match("^```%s*$") then last = i; break end
  end
  if not last or last < first + 2 then return end
  vim.fn.MoltenEvaluateRange(first + 1, last - 1)
end

return {
  -- LazyVim's snacks.image would also draw images; keep image.nvim as the only one.
  { "folke/snacks.nvim", opts = { image = { enabled = false } } },

  {
    "3rd/image.nvim",
    build = false, -- skip the luarocks/hererocks build; magick_cli needs no rock
    -- magick_cli shells out to ImageMagick, so no luarocks needed
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = { markdown = { enabled = false } },
      max_width_window_percentage = 100,
      max_height_window_percentage = 50,
      window_overlap_clear_enabled = true,
      tmux_show_only_in_active_window = true,
    },
  },

  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
      if vim.fn.isdirectory(host) == 1 then
        vim.g.python3_host_prog = host .. "/bin/python"
      end
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_auto_open_output = false
      vim.g.molten_virt_text_output = true
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_lines_off_by_1 = true
    end,
    keys = {
      { "<localleader>mi", init_kernel, desc = "Molten: init kernel" },
      { "<localleader>rl", "<cmd>MoltenEvaluateLine<cr>", desc = "Molten: run line" },
      { "<localleader>rc", run_cell, desc = "Molten: run code block" },
      { "<localleader>rr", "<cmd>MoltenReevaluateCell<cr>", desc = "Molten: re-run cell" },
      { "<localleader>r", ":<C-u>MoltenEvaluateVisual<cr>gv", mode = "v", desc = "Molten: run selection" },
      { "<localleader>ro", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Molten: open output" },
      { "<localleader>mh", "<cmd>MoltenHideOutput<cr>", desc = "Molten: hide output" },
      { "<localleader>md", "<cmd>MoltenDelete<cr>", desc = "Molten: delete cell" },
      { "<localleader>mx", "<cmd>MoltenInterrupt<cr>", desc = "Molten: interrupt" },
      { "<localleader>mp", function() play(vim.fn.expand("<cfile>")) end, desc = "Play gif/video under cursor" },
    },
  },

  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      jupytext = host .. "/bin/jupytext",
      style = "markdown",
      output_extension = "md",
      force_ft = "markdown",
    },
  },
}
