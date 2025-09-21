-- lua/gradle/init.lua
local M = {}

M.state = require("gradle.state")
M.tasks = require("gradle.tasks")
M.telescope = require("gradle.telescope")
M.terminal = require("gradle.terminal")

-- keep a tiny config store (optional use by other modules later)
M.config = {
  keymaps = true,
  load_on_startup = false,
  disable_startup_notification = false,
  floating_terminal_opts = {
    border = "curved",
  },
}

function M.setup(opts)
  opts = opts or {}
  M.config.keymaps = opts.keymaps ~= false
  M.config.load_on_startup = opts.load_on_startup == true
  M.config.disable_startup_notification = opts.disable_startup_notification == true
  M.config.floating_terminal_opts =
    vim.tbl_deep_extend("force", M.config.floating_terminal_opts, opts.floating_terminal_opts or {})

  -- Early exit if not a Gradle project
  if not M.state.is_gradle_project() then
    -- Only print startup notification if enabled
    if not M.config.disable_startup_notification then
      vim.notify("[gradle.nvim] No build.gradle found in current project — plugin disabled", vim.log.levels.INFO)
    end
    return
  end

  -- Configure keymaps
  if M.config.keymaps then
    vim.api.nvim_set_keymap(
      "n",
      "<leader>gr",
      [[<Cmd>lua require('gradle').tasks.refresh_tasks_async()<CR>]],
      { noremap = true, silent = true, desc = "Refresh gradle tasks (async)" }
    )
    vim.api.nvim_set_keymap(
      "n",
      "<leader>gw",
      [[<Cmd>lua require('gradle').terminal.toggle()<CR>]],
      { noremap = true, silent = true, desc = "Toggle gradle terminal" }
    )
    vim.api.nvim_set_keymap(
      "n",
      "<leader>gt",
      [[<Cmd>lua require('gradle').telescope.pick_tasks()<CR>]],
      { noremap = true, silent = true, desc = "Select gradle task via telescope" }
    )
  end

  -- User commands
  vim.api.nvim_create_user_command(
    "GradleRefreshTasks",
    function() require("gradle").tasks.refresh_tasks_async() end,
    { desc = "Refresh gradle tasks (async)" }
  )

  vim.api.nvim_create_user_command(
    "GradleToggleTerminal",
    function() require("gradle").terminal.toggle() end,
    { desc = "Toggle gradle terminal" }
  )

  vim.api.nvim_create_user_command(
    "GradlePickTasks",
    function() require("gradle").telescope.pick_tasks() end,
    { desc = "Select gradle task via telescope" }
  )

  -- optional: pre-load tasks without blocking UI
  if M.config.load_on_startup then
    -- after UI is up, kick off a background refresh
    -- using VimEnter avoids running in headless/plugin-load phases
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        -- defer one tick to let things settle
        vim.defer_fn(function() require("gradle.tasks").refresh_tasks_async() end, 0)
      end,
    })
  end
end

function M.get_config() return M.config end

function M.check_health() require("gradle.health").check() end

return M
