-- lua/gradle/tasks.lua
local M = {}

local parser = require("gradle.parser")
local state = require("gradle.state")

-- cached results (read by telescope)
M.cached_tasks = nil
M.cached_status = nil
M._loading = false

-- Internal: sort helper
local function sort_tasks(tasks)
	table.sort(tasks, function(a, b)
		if a.group == b.group then
			return a.task < b.task
		end
		return a.group < b.group
	end)
end

-- Public, non-blocking: kicks off a background refresh and notifies on completion
function M.refresh_tasks_async(cb)
	vim.notify("[gradle.nvim] Refreshing Gradle tasks in background...", vim.log.levels.INFO)
	return M.load_tasks_async(true, cb)
end

-- Back-compat sync-ish accessor:
-- If we have a cache, return it immediately. If not, trigger an async load and
-- return an empty list right now (UI stays responsive).
function M.load_tasks(refresh)
	if not refresh and M.cached_tasks then
		return M.cached_tasks, M.cached_status
	end
	-- trigger an async load in the background, but don't block
	M.load_tasks_async(true)
	return M.cached_tasks or {}, M.cached_status
end

-- Real async loader. Never blocks the UI.
-- cb(tasks, status) will be called on completion (main loop).
function M.load_tasks_async(force_refresh, cb)
	if M._loading then
		return
	end
	if not force_refresh and M.cached_tasks then
		if cb then
			cb(M.cached_tasks, M.cached_status)
		end
		return
	end

	local cmd = state.get_cmd() or "./gradlew"
	local argv = { cmd, "tasks", "--all" }

	-- prefer vim.system when available (Neovim 0.10+), otherwise fall back to jobstart
	local has_vim_system = type(vim.system) == "function"

	M._loading = true
	local function handle_result(code, stdout, stderr)
		-- concatenate and parse
		local output = (stdout or "") .. (stderr or "")
		local tasks, status = parser.parse_tasks(output)

		if status == "BUILD FAILED" then
			vim.schedule(function()
				vim.notify("[gradle.nvim] Gradle build failed while listing tasks", vim.log.levels.ERROR)
			end)
			M.cached_tasks = {}
			M.cached_status = status
		else
			sort_tasks(tasks)
			M.cached_tasks = tasks
			M.cached_status = status
			vim.schedule(function()
				local msg = string.format("[gradle.nvim] Gradle tasks list refreshed (%d tasks)", #tasks)
				if status then
					msg = msg .. " - " .. status
				end
				if code ~= 0 then
					msg = msg .. " (exit " .. tostring(code) .. ")"
				end
				vim.notify(msg)
			end)
		end

		M._loading = false
		if cb then
			vim.schedule(function()
				cb(M.cached_tasks, M.cached_status)
			end)
		end
	end

	if has_vim_system then
		-- Neovim 0.10+: fully async, simple API
		vim.system(argv, { text = true }, function(obj)
			handle_result(obj.code or 0, obj.stdout or "", obj.stderr or "")
		end)
	else
		-- Neovim <=0.9: jobstart
		local stdout_chunks, stderr_chunks = {}, {}
		local job_id = vim.fn.jobstart(argv, {
			stdout_buffered = true,
			stderr_buffered = true,
			on_stdout = function(_, data)
				if data and #data > 0 then
					table.insert(stdout_chunks, table.concat(data, "\n"))
				end
			end,
			on_stderr = function(_, data)
				if data and #data > 0 then
					table.insert(stderr_chunks, table.concat(data, "\n"))
				end
			end,
			on_exit = function(_, code)
				handle_result(code or 0, table.concat(stdout_chunks, "\n"), table.concat(stderr_chunks, "\n"))
			end,
		})
		if job_id <= 0 then
			M._loading = false
			vim.notify("[gradle.nvim] Failed to start Gradle process", vim.log.levels.ERROR)
		end
	end
end

return M
