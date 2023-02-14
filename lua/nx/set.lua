---Set editor options or variables
--
-- `[1]`: @set_table table of variables or options
-- `[2]?:` @scope `vim.g.|vim.opt|vim.bo` - defaults to `vim.g` when nil
--
---Examples:
-- ---
-- ```lua
-- nx_set({
--    dracula_italic = 1,
--    dracula_bold = 1,
--    dracula_full_special_attrs_support = 1,
--    dracula_colorterm = 0,
-- })
-- -- common way:
-- vim.g.dracula_italic = 1,
-- vim.g.dracula_bold = 1,
-- vim.g.dracula_full_special_attrs_support = 1,
-- vim.g.dracula_colorterm = 0,
-- ```
-- ```lua
-- -- Options
-- nx_set({
--    -- General
--    clipboard = "unnamedplus", -- use system clipboard
--    mouse = "a", -- allow mouse in all modes
--    showmode = false, -- print vim mode on enter
--    termguicolors = true, -- set term gui colors
--    timeoutlen = 350, -- time to wait for a mapped sequence to complete
--    -- Auxiliary files
--    undofile = true, -- enable persistent undo
--    backup = false, -- create a backup file
--    swapfile = false, -- create a swap file
--    -- Command line
--    cmdheight = 0,
--    -- Completion menu
--    pumheight = 14, -- completion popup menu height
--    shortmess__append = "c", -- don't give completion-menu messages
--    -- Characters
--    fillchars__append = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:›, vert:▏]],
--    listchars__append = [[space:⋅, trail:⋅, eol:↴]],
--    -- Gutter
--    number = true, -- show line numbers
--    numberwidth = 3, -- number column width - default "4"
--    relativenumber = true, -- set relative line numbers
--    signcolumn = "yes:2", -- use fixed width signcolumn - prevents text shift when adding signs
--    -- Search
--    hlsearch = true, -- highlight matches in previous search pattern
--    ignorecase = true, -- ignore case in search patterns
--    smartcase = true, -- use smart case
--    -- ...
-- }, vim.opt)
--  ```
---@param set_table table
---@param scope table?
return function(set_table, scope)
	scope = scope or vim.g

	for k, v in pairs(set_table) do
		if scope == vim.opt and string.find(k, "__append") then
			k = k:gsub("__append", "")
			scope[k]:append(v)
		else
			scope[k] = v
		end
	end
end
