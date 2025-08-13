# gradle.nvim

Simple Gradle integration for Neovim - list, filter, preview, and run Gradle tasks directly inside Neovim, with Telescope integration for task selection and ToggleTerm for running tasks in a floating terminal.

> **Note**
>
> - Tested only with **Neovim 0.12 nightly** and the built-in `vim.pack` package manager.
> - I do **not** use LazyVim or packer.nvim - installation with other managers is untested.
> - This plugin is only activated when a `build.gradle` or `build.gradle.kts` file is present in the current working directory.

---

## About This Plugin

This is my first attempt at writing a Neovim plugin in Lua - I'm still pretty new to both Neovim (coming from [helix](https://github.com/helix-editor/helix)) and Lua scripting. I also had help from an AI assistant to figure out some of the structure and Lua quirks along the way, and especially how to handle asynchronous operations.

The code is likely not perfect, but it works for my needs and might be useful for others as well. Feedback, improvements, and pull requests are very welcome!

---

## Features

- ✅ Automatic Gradle project detection (`build.gradle` / `build.gradle.kts`)
- ✅ Prefers `./gradlew` over `gradle` if available
- ✅ List and group all Gradle tasks (via [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim))
- ✅ Filter tasks by group
- ✅ Preview task descriptions with word wrap
- ✅ Run tasks in a reusable floating terminal (via [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim))
- ✅ Asynchronous task loading to keep the UI responsive
- ✅ Optional load tasks on startup
- ✅ `:checkhealth gradle` integration

---

## Installation

### Built-in `vim.pack` (Neovim 0.12+)

```lua
vim.pack.add({
	{ src = "https://github.com/pandalec/gradle.nvim" },
})
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "pandalec/gradle.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "akinsho/toggleterm.nvim",
  },
  config = function()
    require("gradle").setup({
      load_on_startup = true, -- optional
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "pandalec/gradle.nvim",
  requires = {
    "nvim-telescope/telescope.nvim",
    "akinsho/toggleterm.nvim",
  },
  config = function()
    require("gradle").setup({
      load_on_startup = true, -- optional
    })
  end,
})
```

---

## Usage

Default keymaps (can be disabled with `keymaps = false`):

| Mapping      | Description                              |
| ------------ | ---------------------------------------- |
| `<leader>gr` | Refresh Gradle tasks asynchronously      |
| `<leader>gt` | Pick and run a Gradle task via Telescope |
| `<leader>gw` | Toggle the Gradle floating terminal      |

Inside Telescope:

- `<CR>` → Run selected task
- `<C-g>` → Filter by selected task's group
- `<C-b>` → Jump back to full task list

---

## Health Check

Run:

```
:checkhealth gradle
```

to verify that:

- You're inside a valid Gradle project
- A Gradle executable is available

---

## Requirements

- **Neovim 0.12 nightly** (tested only on nightly)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
- Gradle installed or `./gradlew` in project root

---

## License

[MIT](LICENSE)
