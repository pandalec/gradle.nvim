-- lua/gradle/terminal.lua
local Terminal = require("toggleterm.terminal").Terminal
local state = require("gradle.state")

local M = {}

local float_term = nil

function M.toggle()
  if float_term then
    if float_term:is_open() then
      float_term:close()
    else
      float_term:open()
    end
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

  local gradle_cmd = cmd .. " " .. task

  if not float_term then
    local shell = vim.o.shell
    local config = require("gradle").get_config()

    float_term = Terminal:new({
      cmd = shell,
      direction = "float",
      close_on_exit = false,
      float_opts = config.floating_terminal_opts,

      -- Workaround for entering insert mode
      on_open = function(term)
        local bufnr = term.bufnr or vim.api.nvim_get_current_buf()
        vim.schedule(function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == bufnr then
              vim.api.nvim_set_current_win(win)
              pcall(vim.cmd, "startinsert")
              return
            end
          end
          pcall(vim.cmd, "startinsert")
        end)
      end,
    })

    float_term:toggle()
  else
    float_term:open()
  end

  -- Send gradle command
  float_term:send(gradle_cmd)
end

return M
