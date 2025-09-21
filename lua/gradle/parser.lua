-- lua/gradle/parser.lua
local M = {}

-- Parses raw gradle tasks output into grouped, sorted table
function M.parse_tasks(raw_output)
  local tasks = {}
  local current_group = nil

  local build_status = nil
  if raw_output:find("BUILD SUCCESSFUL") then
    build_status = "BUILD SUCCESSFUL"
  elseif raw_output:find("BUILD FAILED") then
    build_status = "BUILD FAILED"
  end

  for line in raw_output:gmatch("[^\r\n]+") do
    if line:match("^%-%-+%s*$") then
      -- skip separator lines
    elseif line:match("^[%w%s]+ tasks$") then
      current_group = line:gsub("%s+tasks$", ""):gsub("^%s*(.-)%s*$", "%1")
    elseif line:match("^%s*%w") and current_group then
      local task, desc = line:match("^%s*(%S+)%s+%-%s+(.*)$")
      if task then table.insert(tasks, { task = task, group = current_group, desc = desc }) end
    end
  end

  return tasks, build_status
end

return M
