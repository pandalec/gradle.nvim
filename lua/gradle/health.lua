-- lua/gradle/health.lua
local state = require("gradle.state")
local health = vim.health or require("health") -- For Neovim >= 0.9 compatibility
local bit = require("bit") -- LuaJIT bitwise operations

local M = {}

local function executable_in_path(exec) return vim.fn.executable(exec) == 1 end

local function file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "file"
end

local function file_is_executable(path)
  local stat = vim.loop.fs_stat(path)
  if not stat then return false end
  -- Check if any execute bit (user/group/other) is set
  local mode = stat.mode
  return (bit.band(mode, 0x40) ~= 0) or (bit.band(mode, 0x08) ~= 0) or (bit.band(mode, 0x01) ~= 0)
end

function M.check()
  health.start("Gradle Environment Check")

  -- Check if we are in a Gradle project
  if not state.is_gradle_project() then
    vim.health.warn(
      "No build.gradle or build.gradle.kts found in current working directory. gradle.nvim will be inactive."
    )
    return
  else
    vim.health.ok("Gradle project detected (build.gradle or build.gradle.kts present)")
  end

  local gradlew_path = vim.loop.cwd() .. "/gradlew"
  if file_exists(gradlew_path) then
    if file_is_executable(gradlew_path) then
      health.ok("Found executable './gradlew' in current working directory (preferred)")
    else
      health.warn("'./gradlew' exists but is not executable. Run: chmod +x gradlew")
    end
  end

  if executable_in_path("gradle") then
    health.ok("Found 'gradle' in PATH (no './gradlew' in current directory)")
  else
    health.error("No Gradle installation found. Include executable './gradlew' in project root or install Gradle.")
  end
end

return M
