-- lua/gradle/telescope.lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local terminal = require("gradle.terminal")
local tasks_module = require("gradle.tasks")

local M = {}

local function format_entry(entry)
	return string.format("%-25s [%s]", entry.task, entry.group)
end

local function make_finder(tasks)
	local results = {}
	for _, t in ipairs(tasks) do
		table.insert(results, {
			value = t,
			display = format_entry(t),
			ordinal = t.task .. " " .. t.group,
		})
	end

	return finders.new_table({
		results = results,
		entry_maker = function(entry)
			return {
				value = entry.value,
				display = entry.display,
				ordinal = entry.ordinal,
			}
		end,
	})
end

local function previewer_task()
	return previewers.new_buffer_previewer({
		define_preview = function(self, entry)
			local lines = {}
			if entry.value and entry.value.desc then
				lines = vim.split(entry.value.desc, "\n")
			else
				lines = { "No description available." }
			end

			vim.api.nvim_buf_set_option(self.state.bufnr, "modifiable", true)
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
			vim.api.nvim_buf_set_option(self.state.bufnr, "modifiable", false)

			vim.wo[self.state.winid].wrap = true
		end,
	})
end

local function run_task_action(prompt_bufnr)
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local selection = action_state.get_selected_entry()
	actions.close(prompt_bufnr)
	if selection and selection.value then
		terminal.run_task(selection.value.task)
	end
end

local function pick_tasks_filtered_by_group(tasks, group)
	local actions = require("telescope.actions")
	local filtered = {}
	for _, t in ipairs(tasks) do
		if t.group == group then
			table.insert(filtered, t)
		end
	end
	if #filtered == 0 then
		vim.notify("[gradle.nvim] No tasks found for group: " .. group, vim.log.levels.WARN)
		return
	end

	pickers
	    .new({}, {
		    prompt_title = "Gradle Tasks: " .. group,
		    finder = make_finder(filtered),
		    sorter = conf.generic_sorter({}),
		    previewer = previewer_task(),
		    attach_mappings = function(prompt_bufnr, map)
			    map("i", "<CR>", run_task_action)
			    map("n", "<CR>", run_task_action)

			    local jump_back = function()
				    actions.close(prompt_bufnr)
				    M.pick_tasks()
			    end
			    map("i", "<C-S-g>", jump_back)
			    map("n", "<C-S-g>", jump_back)

			    return true
		    end,
	    })
	    :find()
end

function M.pick_tasks()
	local tasks = tasks_module.load_tasks()
	if not tasks or #tasks == 0 then
		vim.notify("[gradle.nvim] No Gradle tasks available yet. Refreshing in background...",
			vim.log.levels.INFO)
		tasks_module.refresh_tasks_async(function(new_tasks)
			if new_tasks and #new_tasks > 0 then
				-- re-open picker when ready (optional, simple approach: notify only)
				vim.notify(
					"[gradle.nvim] Tasks loaded. Run :lua require('gradle').telescope.pick_tasks() to open.",
					vim.log.levels.INFO
				)
			end
		end)
		return
	end

	pickers
	    .new({}, {
		    prompt_title = "Gradle Tasks",
		    finder = make_finder(tasks),
		    sorter = conf.generic_sorter({}),
		    previewer = previewer_task(),
		    attach_mappings = function(prompt_bufnr, map)
			    local actions = require("telescope.actions")
			    local action_state = require("telescope.actions.state")

			    map("i", "<CR>", run_task_action)
			    map("n", "<CR>", run_task_action)

			    local filter_group = function()
				    local selection = action_state.get_selected_entry()
				    if selection and selection.value and selection.value.group then
					    actions.close(prompt_bufnr)
					    pick_tasks_filtered_by_group(tasks, selection.value.group)
				    end
			    end
			    map("i", "<C-g>", filter_group)
			    map("n", "<C-g>", filter_group)

			    return true
		    end,
	    })
	    :find()
end

function M.pick_groups()
	local tasks = tasks_module.load_tasks()
	if not tasks or #tasks == 0 then
		vim.notify("[gradle.nvim] No Gradle tasks available", vim.log.levels.WARN)
		return
	end

	local groups = {}
	local group_set = {}
	for _, t in ipairs(tasks) do
		if not group_set[t.group] then
			group_set[t.group] = true
			table.insert(groups, t.group)
		end
	end
	table.sort(groups)

	pickers
	    .new({}, {
		    prompt_title = "Gradle Task Groups",
		    finder = finders.new_table(groups),
		    sorter = conf.generic_sorter({}),
		    attach_mappings = function(prompt_bufnr, map)
			    local actions = require("telescope.actions")
			    local action_state = require("telescope.actions.state")
			    local choose_group = function()
				    local selection = action_state.get_selected_entry()[1]
				    actions.close(prompt_bufnr)
				    pick_tasks_filtered_by_group(tasks, selection)
			    end
			    map("i", "<CR>", choose_group)
			    map("n", "<CR>", choose_group)
			    return true
		    end,
	    })
	    :find()
end

return M
