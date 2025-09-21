-- lua/gradle/util.lua
local M = {}

function M.notify(msg, level) vim.notify("[jiratui.nvim] " .. tostring(msg), level or vim.log.levels.INFO) end

function M.config_path()
  local p = os.getenv("JIRA_TUI_CONFIG_FILE")
  if p and p ~= "" then return p end
  local x = os.getenv("XDG_CONFIG_HOME")
  if x and x ~= "" then return x .. "/jiratui/config.yaml" end
  local h = os.getenv("HOME") or ""
  return h .. "/.config/jiratui/config.yaml"
end

function M.file_exists(path)
  local handle = io.open(path, "r")
  if handle then
    handle:close()
    return true
  end
  return false
end

function M.config_file_exists()
  local path = M.config_path()
  if type(path) ~= "string" or path == "" then return false end
  return M.file_exists(path) == true
end

return M
