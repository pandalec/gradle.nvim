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
			start_in_insert = true,
			float_opts = config.floating_terminal_opts,
		})

		float_term:toggle()
	else
		float_term:open()
	end

	-- -- Clear screen before new command (Ctrl+l)
	-- float_term:send("\x0c")
	-- Send gradle command
	float_term:send(gradle_cmd)
end

return M
