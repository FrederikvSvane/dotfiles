-- Render images (png, jpg, ...) inline. Needs a kitty-graphics terminal (kitty, ghostty, wezterm).
--
-- snacks caches each image by path for the whole session, so a regenerated file keeps
-- showing the old picture, and switching between image buffers can leave a blank window.
-- So: re-attach an image whenever its buffer is entered, and drop the cache first if the
-- file changed on disk.
local mtimes = {} ---@type table<string, string>

---@param buf number
---@param force boolean re-attach even if the file did not change
local function reload(buf, force)
  local file = vim.api.nvim_buf_get_name(buf)
  local stat = vim.uv.fs_stat(file)
  if not (stat and Snacks.image.supports_file(file)) then
    return
  end
  local mtime = stat.mtime.sec .. "." .. stat.mtime.nsec
  local changed = mtimes[file] ~= nil and mtimes[file] ~= mtime
  mtimes[file] = mtime
  if changed then
    local base = vim.fn.fnamemodify(file, ":t:r"):gsub("[^%w%.]+", "-")
    for _, cached in ipairs(vim.fn.glob(Snacks.image.config.cache .. "/*-" .. base .. ".*", false, true)) do
      os.remove(cached)
    end
    Snacks.image.image.clear()
  end
  if changed or force then
    Snacks.image.buf.attach(buf)
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = { image = { enabled = true } },
    init = function()
      local group = vim.api.nvim_create_augroup("image_reload", { clear = true })
      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function(ev)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) and ev.buf == vim.api.nvim_get_current_buf() then
              reload(ev.buf, true)
            end
          end)
        end,
      })
      vim.api.nvim_create_autocmd("FocusGained", {
        group = group,
        callback = function()
          reload(vim.api.nvim_get_current_buf(), false)
        end,
      })
    end,
  },
}
