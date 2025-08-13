-- lua/gradle/state.lua
local M = {}

local function has_executable(cmd)
	return vim.fn.executable(cmd) == 1
end

function M.get_cmd()
	-- Prefer ./gradlew if executable in cwd
	if vim.fn.filereadable("./gradlew") == 1 and vim.fn.executable("./gradlew") == 1 then
		return "./gradlew"
	elseif has_executable("gradle") then
		return "gradle"
	else
		return nil
	end
end

-- Detect if current working directory contains a Gradle build file
function M.is_gradle_project()
	return (vim.fn.filereadable("build.gradle") == 1 or vim.fn.filereadable("build.gradle.kts") == 1)
end

return M
