-- Render images (png, jpg, ...) inline. Needs a kitty-graphics terminal (kitty, ghostty, wezterm).
--
-- snacks caches each image by path for the whole session, so a regenerated file keeps
-- showing the old picture. Reload an image buffer when its file changed on disk.
local mtimes = {} ---@type table<string, string>

local function refresh(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  local stat = vim.uv.fs_stat(file)
  if not (stat and Snacks.image.supports_file(file)) then
    return
  end
  local mtime = stat.mtime.sec .. "." .. stat.mtime.nsec
  local seen = mtimes[file]
  mtimes[file] = mtime
  if seen == nil or seen == mtime then
    return
  end
  local base = vim.fn.fnamemodify(file, ":t:r"):gsub("[^%w%.]+", "-")
  for _, cached in ipairs(vim.fn.glob(Snacks.image.config.cache .. "/*-" .. base .. ".*", false, true)) do
    os.remove(cached)
  end
  Snacks.image.image.clear()
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("edit!")
  end)
end

return {
  {
    "folke/snacks.nvim",
    opts = { image = { enabled = true } },
    init = function()
      vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
        group = vim.api.nvim_create_augroup("image_reload", { clear = true }),
        callback = function(ev)
          local buf = ev.event == "FocusGained" and vim.api.nvim_get_current_buf() or ev.buf
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
              refresh(buf)
            end
          end)
        end,
      })
    end,
  },
}
