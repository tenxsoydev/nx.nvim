# nx.nvim

_Utility library to n^x your work with the nvim api._

<br>

**Features**

- [Keymaps](#nxmap-%EF%B8%8F)
- [Highlights](https://www.github.com)
- [Autocommands](#nxau-%EF%B8%8F)
- [Commands](https://www.github.com)

**Installation**

- [Getting Started](https://www.github.com)

<br>

## Features

All features maintain familiarity with their underlying base functions and should feel intuitive to use. Below is an overview of their differences and extended functionalities.

<br>

## nx.map 🗺️

**Based on `vim.keymap.set()`**

**Differences**

- Map single or multiple keymaps
- The only required values are index `[1]`: _lhs_ and `[2]`: _rhs_
- `mode`: defaults to `"n"` and instead of being passed as index `[1]` it is optional as `[3]` or `mode` key
- `opts`: are passed inline instead of in a separate table
  - additional options:
    - `wk_label`: to create which-key labels that should differ from the key's description
    - `ft`: to create filetype specific mappings
  - `{<wrapper_opts>}`: to add options to all keymaps within a `nx.map()`

#### `map` Examples

```lua
nx.map({
   { ";w", "<Cmd>w<CR>" },
   { ";q", "<Cmd>confirm quit<CR>", desc = "Close Current Window" }, {
   { "<leader>ts", "<Cmd>set spell!<CR>", desc = "Toggle Spellcheck", wk_label = "Spellcheck"} },
   { "<leader>tp", "<Cmd>MarkdownPreviewToggle<CR>", ft = "markdown", desc = "Toggle Markdown Preview" }
})
-- ...
nx.map({
   -- Line Navigation
   { { "j", "<Up>" }, "&wrap ? 'gj' : 'j'", "" },
   { { "k", "<Down>" }, "&wrap ? 'gk' : 'k'", "" },
   { "$", "&wrap ? 'g$' : '$'", "" },
   { "^", "&wrap ? 'g^' : '^'", mode = "" },
   -- Indentation
   { "i", function() return smart_indent "i" end },
   { "a", function() return smart_indent "a" end },
   { "A", function() return smart_indent "A" end },
   }, { expr = true, silent = true })
})
```

<br>

<details open>
<summary><b>Detailed Examples</b> <sub><sup>click to close...</sup></sub></summary><br>

- ##### Feature overview

  ```lua
  nx.map({ ";q", "<Cmd>confirm quit<CR>", desc = "Close Current Window" })
  ---@ ╰── set a single keymap
  ---@ ╭── or lists of keymaps
  nx.map({
     -- Line Navigation
     ---@    ╭── multiple lhs
     { { "j", "<Up>" }, "&wrap ? 'gj' : 'j'", "" },
     { { "k", "<Down>" }, "&wrap ? 'gk' : 'k'", "" },
     { "$", "&wrap ? 'g$' : '$'", "" },
     { "^", "&wrap ? 'g^' : '^'", "" },
     -- Indentation
     { "i", function() return smart_indent "i" end },
     { "a", function() return smart_indent "a" end },
     { "A", function() return smart_indent "A" end },
     }, { expr = true, silent = true })
  ---@      ╰── wrapper opts apply options to all entries

  nx.map({
     { "<Esc>", "<Esc>", "i" },
     { "<C-c>", "<Cmd>close<CR>", { "i", "x" } },
     { "q", "<Cmd>close<CR>", "x" },
     ---@ set filetype keymaps ──╮ (in {wrapper_opts} or for single keymaps)
  }, { buffer = 0, ft = "DressingInput" })
  ```

  <br>

- ##### Mode

  Specify a `mode|mode[]` other than `"n"` as index `[3]` or `mode` key (inline or in `wrapper_opts`).

  ```lua
  nx.map({
  { "<kEnter>", "<CR>", { "", "!" }, desc = "Enter" }
  ---@ ^=                      ╰── or  ──╮
  { "<kEnter>", "<CR>", desc = "Enter", mode = { "", "!" } }
  }, { mode = { "", "!" }) -- or in wrapper_opts (here it has to be the `mode` key)
  ```

  <br>

- ##### Wrapper options

  Add options to all entries in a list of keymaps _- inline keymap options are treated with higher priority and won't be overwritten by wrapper options_. As an example let's use nx.map for <a target="_blank" href="https://github.com/neovim/nvim-lspconfig#suggested-configuration">nvim-lspconfig#suggested-configuration</a>

  ```lua
  ---@ common

  local opts = { noremap=true, silent=true }
  vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

  local on_attach = function(client, bufnr)
     local bufopts = { noremap=true, silent=true, buffer=bufnr }
     vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
     vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
     vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
     vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
     vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
     vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
     vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
     vim.keymap.set('n', '<space>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
     end, bufopts)
     vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
     vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
     vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
     vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
     vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
  end
  ```

  ```lua
  ---@ nx.map

  nx.map({
     { "<space>e", vim.diagnostic.open_float },
     { "[d", vim.diagnostic.goto_prev },
     { "]d", vim.diagnostic.goto_next },
     { "<space>q", vim.diagnostic.setloclist },
  }, { noremap = true, silent = true })

  local on_attach = function(client, bufnr)
     nx.map({
        { "gD", vim.lsp.buf.declaration },
        { "gd", vim.lsp.buf.definition },
        { "K", vim.lsp.buf.hover },
        { "gi", vim.lsp.buf.implementation },
        { "<C-k>", vim.lsp.buf.signature_help },
        { "<space>wa", vim.lsp.buf.add_workspace_folder },
        { "<space>wr", vim.lsp.buf.remove_workspace_folder },
        { "<space>wl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end },
        { "<space>D", vim.lsp.buf.type_definition },
        { "<space>rn", vim.lsp.buf.rename },
        { "<space>ca", vim.lsp.buf.code_action },
        { "gr", vim.lsp.buf.references },
        { "<space>f", function() vim.lsp.buf.format { async = true } end },
     }, { noremap = true, silent = true, buffer = bufnr })
  end
  ```

  <br>

- ##### Custom which-key labels

  Register which-key labels that should differ from the mappings description.
  They can be a `string` literal, `"ignore"`(^=`"which_key_ignore"`), or `{ sub_desc = "<pattern>" }` to exclude a pattern of the mappings `desc` key.

  <!-- panvimdoc-ignore-start -->

  <table>
    <tr align="center">
      <td width="400">
        <a href="https://user-images.githubusercontent.com/34311583/219030703-2592465d-6d3e-4283-ab0d-7e00c343e651.png">
          <img src="https://user-images.githubusercontent.com/34311583/219030703-2592465d-6d3e-4283-ab0d-7e00c343e651.png" />
        </a>
        <sup>
          <em>E.g., <code>Search</code> group</em>
        </sup>
        <br />
        <sup><em>🟣 desc labels | 🔵 custom labels</em></sup>
      </td>
      <td width="400">
        <a href="https://user-images.githubusercontent.com/34311583/219030828-1531aa9a-3fe1-4da1-96d9-0c558046df75.png">
          <img src="https://user-images.githubusercontent.com/34311583/219030828-1531aa9a-3fe1-4da1-96d9-0c558046df75.png" />
        </a>
        <sup>
          <em>E.g., <code>Toggle</code> group</em>
        </sup>
        <br />
        <sup><em>🟣 desc labels | 🔵 custom labels</em></sup>
      </td>
      <td width="400">
        <a href="https://user-images.githubusercontent.com/34311583/219030985-6c54cfca-b088-435b-b8b4-f596fa242056.png">
          <img src="https://user-images.githubusercontent.com/34311583/219030985-6c54cfca-b088-435b-b8b4-f596fa242056.png" />
        </a>
        <sup>
          <em>Preserve searchable description<br /></em>
        </sup>
        <sup>
          <em>e.g.: <code>:Telescope keymaps</code></em>
        </sup>
      </td>
    </tr>
  </table>

  <!-- panvimdoc-ignore-end -->

  The example below uses `wk_label` for a "`SnipRun`-keymap-family". It excludes the string `"SnipRun"` from being added to every entry on their which-key page.

  ```lua
  ---@ method 1: custom a `wk_label` per key
  nx.map {
     { "<leader>Rc", "<Cmd>SnipClose<CR>", desc = "Close SnipRun", wk_label = "Close" },
     { "<leader>Rf", "<Cmd>%SnipRun<CR>", desc = "Run File" },
     { "<leader>Ri", "<Cmd>SnipInfo<CR>", desc = "SnipRun Info", wk_label = "Info" },
     { "<leader>Rm", "<Cmd>SnipReplMemoryClean<CR>", desc = "SnipRun Clean Memory", wk_label = "Clean Memory" },
     { "<leader>Rr", "<Cmd>SnipReset<CR>", desc = "Reset SnipRun", wk_label = "Reset" },
     { "<leader>Rx", "<Cmd>SnipTerminate<CR>", desc = "Terminate SnipRun", wk_label = "Terminate" },
     { "<leader>R", "<Esc><Cmd>'<,'>SnipRun<CR>", "v", desc = "SnipRun Range", wk_label = "Run Range" },
  }

  ---@ method 2: use `sub_desc` in `wrapper_opts` to remove `SnipRun` from all entries
  nx.map({
     { "<leader>Rc", "<Cmd>SnipClose<CR>", desc = "Close SnipRun" },
     { "<leader>Rf", "<Cmd>%SnipRun<CR>", desc = "Run File" },
     { "<leader>Ri", "<Cmd>SnipInfo<CR>", desc = "SnipRun Info" },
     { "<leader>Rm", "<Cmd>SnipReplMemoryClean<CR>", desc = "SnipRun Clean Memory" },
     { "<leader>Rr", "<Cmd>SnipReset<CR>", desc = "Reset SnipRun" },
     { "<leader>Rx", "<Cmd>SnipTerminate<CR>", desc = "Terminate SnipRun" },
     { "<leader>RR", "<Esc><Cmd>'<,'>SnipRun<CR>", "v", desc = "SnipRun Range" },
  }, { wk_label = { sub_desc = "SnipRun" } })
  ```

  <br>

- ##### Type Annotations

  Allow your language server to assist you with hovers, completions, and diagnostics.

  <!-- panvimdoc-ignore-start -->

  <table>
    <tr align="center">
      <td>
        <a href="https://user-images.githubusercontent.com/34311583/219031105-f29cf684-dc64-4f63-8a05-e310e434b4ba.png">
          <img src="https://user-images.githubusercontent.com/34311583/219031105-f29cf684-dc64-4f63-8a05-e310e434b4ba.png" />
        </a>
        <sup><em>function hover</em></sup>
      </td>
      <td>
        <a href="https://user-images.githubusercontent.com/34311583/219031245-23176c70-bdb7-424d-a209-6af79fc757e8.png">
          <img src="https://user-images.githubusercontent.com/34311583/219031245-23176c70-bdb7-424d-a209-6af79fc757e8.png" />
        </a>
        <sup><em>field hover</em></sup>
      </td>
    </tr>
    <tr></tr>
    <tr align="center">
      <td>
        <a href="https://user-images.githubusercontent.com/34311583/219031260-c321d48d-f7ae-4e3f-b2ec-8cb7265a4905.png">
          <img src="https://user-images.githubusercontent.com/34311583/219031260-c321d48d-f7ae-4e3f-b2ec-8cb7265a4905.png" />
        </a>
        <sup><em>cmp</em></sup>
      </td>
      <td>
        <a href="https://user-images.githubusercontent.com/34311583/219030703-2592465d-6d3e-4283-ab0d-7e00c343e651.png">
          <img src="https://user-images.githubusercontent.com/34311583/219031166-52da4130-7f98-41bd-a783-07915ea74859.png" />
        </a>
        <sup><em>diagnostic</em></sup>
      </td>
    </tr>
  </table>

  <!-- panvimdoc-ignore-end -->

  This requires your runtime environment to be configured to include your plugin directories. An easy way is to have this automated using https://github.com/folke/neodev.nvim.

</details>

<br>

## nx.hl 🎨

**Based on `nvim_set_hl()`**

**Differences**

- Set single or multiple highlights
- The only required values are index `[1]`: _hl_name_ and `bg|fg|link|…`: _value_
- `ns_id`: defaults to `0` and instead of being passed as index `[1]` it is optional as `[3]` or `ns_id` key
- `values`: are passed inline instead of in a separate table
- modifiers for values:
  - `:bg|:fg`: to use single values of other highlights as color source instead of linking the whole group.
  - `:#b`: to transform the brightness of a color
- `{<wrapper_opts>}` to add values to all highlights within a `nx.hl()`

#### `hl` Examples

```lua
nx.hl({
 { "LineNr", fg = "DraculaComment:fg" },
 { "Normal", bg = "DraculaBg:bg" },
 { "BgDarker", bg = palette.bg .. ":#b-15" },
 { "BufferLineSeparatorShadow", fg = "TabLine:bg:#b-10", bg = "Normal:bg" } }
 { { "Directory", "MarkSign" }, link = "DraculaPurple" },
})
```

<br>

<details>
<summary><b>Detailed Examples</b> <sub><sup>click to expand...</sup></sub></summary><br>

- ##### Feature overview

  ```lua
  nx.hl({ "GitSignsCurrentLineBlame", fg = "Debug:fg", bg = "CursorLine:bg", italic = true })
  ---@ ╰── set a single highlight
  ---@ ╭── or lists of highlights
  nx.hl({
     { "Hex", fg = "#9370DB" },            --   ╮
     { "ColorName", fg = "MediumPurple" }, ---@ ├  kinds of values already possible without nx.nvim
     { "Decimal", fg = 9662683 },          --   ╯
     --
     { "Winbar", fg = "DraculaComment:fg" },
     ---@                       ╭────╯  use single values from other highlight groups
     { "Normal", bg = "DraculaBg:bg" },
     ---@ use a color with transformed brightness  ──╮ ╭─ darken
     { "BufferLineSeparatorShadow", fg = "TabLine:bg:#b-10", bg = "Normal:bg" } }
     ---@ e.g., with hex var ──╮         ╭─ brighten
     { "BgLight", bg = palette.bg .. ":#b+15" },
     ---@           ╭── multiple highlight names
     { { "Directory", "MarkSign" }, link = "DraculaPurple" },
  }, { bold = true, italic = true })
  ---@    ╰── wrapper opts apply values to all entries
  ```

  <br>

- ##### Wrapper options

  Add values to all entries in a list of highlights _- inline values are treated with higher priority and won't be overwritten by wrapper options_.

  ```lua
  nx.hl({
     { "NeoTreeTabActive", bg = "NeoTreeNormal:bg" },
     { "NeoTreeTabInactive", fg = "NeoTreeDimText:fg" },   -- ╮
     { "NeoTreeTabSeparatorInactive", fg = "TabLine:bg" }, -- ┤
  }, { bg = "TabLine:bg" }) ---@    applies `bg` these     -- ╯
  ```

</details>

<br>

## nx.au 🤖

**Based on `nvim_create_autocmd()`**

**Differences**

- Create single or multiple auto commands
- `opts`: are passed inline instead of in a separate table
  - additional options:
    - `create_group`: to create a group and add the `autocmd|autocmd[]` to that group
  - `{<wrapper_opts>}` to add values to all autocmds within a `nx.au()`

#### `au` Examples

```lua
nx.au({
   { "BufWritePost", pattern = "options.lua", command = "source <afile>", desc = "Execute files on save" },
   { "BufWritePre", command = "call mkdir(expand('<afile>:p:h'), 'p')", desc = "Create non-existent parents" },
})
nx.au({
   { "BufWinLeave", pattern = "*.*", command = "mkview" },
   { "BufWinEnter", pattern = "*.*", command = "silent! loadview" },
}, { create_group = "RememberFolds" })
```

<br>

<details>
<summary><b>Detailed Examples</b> <sub><sup>click to expand...</sup></sub></summary><br>

- ##### Feature Description

  ```lua
  nx.au({ "FocusGained", pattern = "*.*", command = "checktime", desc = "Check if buffer changed outside of vim" })
  ---@ ╰── create a single autocommand
  ---@ ╭── or lists of autocommands
  nx.au({
     { "BufWinLeave", pattern = "*.*", command = "mkview" },
     { "BufWinEnter", pattern = "*.*", command = "silent! loadview" },
  }, { pattern = "*.*" })
  ---@     ╰── wrapper opts apply values to all entries without them
  ```

  <br>

- ##### Autocommand groups

  Besides the usual adding to existing autocommand groups using the `group` key, it is possible to create autocommand groups on the fly with the `create_group` key.

  ```lua
  nx.au({
     "BufWritePre",
     -- group = "FormatOnSave", ---@ use `group` as usual to add the autocmd to an already existing group
     create_group = "FormatOnSave", ---@ or create a new group while creating the autocmd
     callback = function()
        if next(vim.lsp.get_active_clients({ bufnr = 0 })) == nil then return end
        vim.lsp.buf.format({ async = false })
     end,
  })
  nx.au({
     { "BufWinLeave", pattern = "*.*", command = "mkview" },
     { "BufWinEnter", pattern = "*.*", command = "silent! loadview" },
     ---@   ╭── create an autocommand group in `wrapper_opts` and add all autocommands within this "nx.au()" call
  }, { create_group = "RememberFolds" })
  ```

</details>

<br>

## nx.cmd ⚙️

**Based on `nvim_create_user_command()`**

**Differences**

- Create single or multiple commands
- The only required values are index `[1]`: _name_ and `[2]`: _command_
- `opts`: are passed inline instead of in a separate table
- `{<wrapper_opts>}` to add values to all commands within a `nx.cmd()`

#### `cmd` Examples

```lua
nx.cmd({
  "LspFormat",
  function() vim.lsp.buf.format({ async = true }) end,
  bang = true,
  desc = "Fromat the Current Buffer",
})
```

<br>

<details>
<summary><b>Detailed Examples</b> <sub><sup>click to expand...</sup></sub></summary><br>

- ##### Feature Description

  ```lua
  ---@ ╭── create a single command
  nx.cmd({ "ResetTerminal", function() vim.cmd("set scrollback=1 | sleep 10m | set scrollback=10000") end })
  ---@ ╭── or lists of commands
  nx.cmd({
     { "LspFormat", function() vim.lsp.buf.format({ async = true }) end },
     { "LspToggleAutoFormat", function(opt) toggle_format_on_save(opt.args) end, nargs = "?" },
     { "ToggleBufferDiagnostics", function() toggle_buffer_diags(vim.fn.bufnr()) end },
  }, { bang = true })
  ---@   ╰── wrapper opts apply options to all entries without them
  ```

</details>

<br>

## nx.set 🛠️

There is also `nx.set` to assign multiple variables or options.

Next to an array of variables/settings, add the scope (`vim.g|vim.opt|vim.bo|...`) as a second parameter. If no scope is specified `vim.g` is used.

(This features function currently consists of just over 10 lines of code. It's not as extensive or well annotated, but feel free to use it if you like).

#### `set` Examples

<details>

<summary><b>Details</b> <sub><sup>click to expand...</sup></sub></summary><br>

- Variables

  ```lua
  nx_set({
     dracula_italic = 1,
     dracula_bold = 1,
     dracula_full_special_attrs_support = 1,
     dracula_colorterm = 0,
  })
  -- common way:
  vim.g.dracula_italic = 1
  vim.g.dracula_bold = 1
  vim.g.dracula_full_special_attrs_support = 1
  vim.g.dracula_colorterm = 0
  ```

- Options

  ```lua
  nx.set({
     -- General
     clipboard = "unnamedplus", -- use system clipboard
     mouse = "a", -- allow mouse in all modes
     showmode = false, -- print vim mode on enter
     termguicolors = true, -- set term gui colors
     timeoutlen = 350, -- time to wait for a mapped sequence to complete
     fillchars__append = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:›, vert:▏]],
     listchars__append = [[space:⋅, trail:⋅, eol:↴]],
     -- Auxiliary files
     undofile = true, -- enable persistent undo
     backup = false, -- create a backup file
     swapfile = false, -- create a swap file
     -- Command line
     cmdheight = 0,
     -- Completion menu
     pumheight = 14, -- completion popup menu height
     shortmess__append = "c", -- don't give completion-menu messages
     -- Gutter
     number = true, -- show line numbers
     numberwidth = 3, -- number column width - default "4"
     relativenumber = true, -- set relative line numbers
     signcolumn = "yes:2", -- use fixed width signcolumn - prevents text shift when adding signs
     -- Search
     hlsearch = true, -- highlight matches in previous search pattern
     ignorecase = true, -- ignore case in search patterns
     smartcase = true, -- use smart case
     -- ...
  }, vim.opt)
  ```

</details>

<br>

## Getting Started 🚀

Install `"tenxsoydev/nx.nvim"` via your favorite plugin manager.

The only thing left to do then is to import the `nx` functions you want to use.<br>

#### Examples

- Set it once as global variable so it can be called anywhere in a configuration

  ```lua
  -- if using a global variable, make sure it's set where it will be loaded before it's used in another place
  _G.nx = require("nx")
  -- use anywhere
  nx.map({})
  nx.au({})
  nx.hl({})
  ```

  ```lua
  -- E.g., when using a plugin manger like lazy, add a high priority
  require("lazy").setup({
    -- ...
    { "tenxsoydev/nx.nvim", priority = 100, config = function() _G.nx = require "nx" end },
    -- ...
  })
  ```

  ```lua
  -- or if you prefer not to have the `nx` branding, use another vairable name
  _G.v = require("nx")
  -- use anywhere
  v.map({})
  v.au({})
  v.hl({})
  ```

- It's also possible to import single modules on demand

  ```lua
  local map = require("nx.map")
  local hl = require("nx.hl")
  local au = require("nx.au")
  ```

<br>

### Reusability

To be easily composable, the utilities are written as single modules that can stand on their own. So if they can be helpful within the project you are working - and adding dependencies is too heavy - they are light copy pasta 🍝. In such cases, keeping a small reference of attribution warms the heart of your fellow developer.

<br>

## Contribution 🤝

There is always room for enhancement. Reach out if you experience any issues, would like to request a feature, or submit improvements. If you would like to tackle open issues - they are usually "help wanted" by nature. Leaving an emoji to show support for an idea that has already been requested also helps to prioritize community needs.

<br>

---

### Credits

- [nxvim](https://github.com/tenxsoydev/nxvim/)

[1]: ./preview/lsp-hover.png
