-- lua/gradle/terminal.lua
local state = require("gradle.state")

local M = {}

local term = { buf = nil, win = nil, chan = nil }

local function win_open()
  return term.win ~= nil and vim.api.nvim_win_is_valid(term.win)
end

local function job_alive()
  return term.chan ~= nil and vim.api.nvim_get_chan_info(term.chan).id ~= nil
end

local function open_float()
  local config = require("gradle").get_config()
  local opts = (config and config.floating_terminal_opts) or {}
  local width = opts.width or math.floor(vim.o.columns * 0.9)
  local height = opts.height or math.floor(vim.o.lines * 0.8)

  if not (term.buf and vim.api.nvim_buf_is_valid(term.buf)) then
    term.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[term.buf].swapfile = false
  end

  term.win = vim.api.nvim_open_win(term.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = opts.border or "rounded",
  })
  vim.wo[term.win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"

  if not job_alive() then
    local save = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(term.win)
    term.chan = vim.fn.jobstart(vim.o.shell, { term = true })
    vim.api.nvim_set_current_win(save)
  end

  vim.schedule(function() vim.cmd("startinsert") end)
end

function M.toggle()
  if win_open() then
    vim.api.nvim_win_close(term.win, true)
    term.win = nil
  elseif term.buf then
    open_float()
  else
    vim.notify("[gradle.nvim] No Gradle task has been run yet.", vim.log.levels.INFO)
  end
end

function M.run_task(task)
  if not task or task == "" then
    vim.notify("[gradle.nvim] No Gradle task specified", vim.log.levels.ERROR)
    return
  end

  local cmd = state.get_cmd()
  if not cmd then
    vim.notify("[gradle.nvim] Neither ./gradlew nor gradle executable found", vim.log.levels.ERROR)
    return
  end

  if not win_open() then open_float() end
  vim.api.nvim_chan_send(term.chan, cmd .. " " .. task .. "\n")
end

return M
