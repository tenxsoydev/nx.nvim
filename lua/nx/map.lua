-- Annotations ================================================================

---@class NxMap : NxMapOpts
---@field [1] string|string[] @lhs
---@field [2] string|function @rhs
---@field [3]? mode

---@class NxMapOpts : VimMapOpts
-- `mode|mode[]:` defaults to `"n"` can be passed as index `[3]` or `mode` key
-- ┌──────┬──────┬─────┬─────┬─────┬─────┬─────┬──────┬──────┐
-- │ Mode │ Norm │ Ins │ Cmd │ Vis │ Sel │ Opr │ Term │ Lang │
-- ├──────┼──────┼─────┼─────┼─────┼─────┼─────┼──────┼──────┤
-- │ ""   │  ✓   │  -  │  -  │  ✓  │  ✓  │  ✓  │  -   │  -   │
-- │ "n"  │  ✓   │  -  │  -  │  -  │  -  │  -  │  -   │  -   │
-- │ "!"  │  -   │  ✓  │  ✓  │  -  │  -  │  -  │  -   │  -   │
-- │ "i"  │  -   │  ✓  │  -  │  -  │  -  │  -  │  -   │  -   │
-- │ "c"  │  -   │  -  │  ✓  │  -  │  -  │  -  │  -   │  -   │
-- │ "v"  │  -   │  -  │  -  │  ✓  │  ✓  │  -  │  -   │  -   │
-- │ "x"  │  -   │  -  │  -  │  ✓  │  -  │  -  │  -   │  -   │
-- │ "s"  │  -   │  -  │  -  │  -  │  ✓  │  -  │  -   │  -   │
-- │ "o"  │  -   │  -  │  -  │  -  │  -  │  ✓  │  -   │  -   │
-- │ "t"  │  -   │  -  │  -  │  -  │  -  │  -  │  ✓   │  -   │
-- │ "l"  │  -   │  ✓  │  ✓  │  -  │  -  │  -  │  -   │  ✓   │
-- └──────┴──────┴─────┴─────┴─────┴─────┴─────┴──────┴──────┘
---@field mode? mode
---@field wk_label? wk_label
---@field ft? string|string[]

---@class VimMapOpts @references: `h: vim.keymap.set()`, `h: nvim_set_keymap()`, `:h :map-arguments`
---@field buffer? number|boolean
---@field remap? boolean
---@field nowait? boolean
---@field silent? boolean
---@field script? boolean
---@field expr? boolean
---@field replace_keycodes? boolean
---@field unique? boolean
---@field desc? string

---Which-key label
-- `|` string @the label will be displayed in wichkey instead of the keys description. `"ignore"` and `"which_key_ignore"` are equivalent
-- `|` {sub_desc: string} @removes a pattern from the description and uses it as label
---@alias wk_label string|{sub_desc: string}

---@alias mode ""|"n"|"!"|"i"|"c"|"v"|"x"|"s"|"o"|"t"|"l"|{[number]: mode}

-- Which-key labels ===========================================================

local wk_ok, wk = pcall(require, "which-key")

---@param desc string
---@param sub_pattern string
---@return string
local function sub_desc_to_label(desc, sub_pattern)
	-- in addition to pattern removal, truncate spaces
	local label = desc:gsub(sub_pattern .. "[%s+]?", "")
	return label
end

---@param map NxMap
---@param wrapper_label? wk_label
local function get_wk_label(map, wrapper_label)
	local label = map.wk_label or map.desc or nil

	-- handle ignore
	if label == "ignore" then label = "which_key_ignore" end

	if map.wk_label and map.wk_label.sub_desc and map.desc then
		label = sub_desc_to_label(map.desc, map.wk_label.sub_desc)
	end

	---@cast label string
	if not wrapper_label then return label end

	-- handle wrapper label
	if type(wrapper_label) == "string" and not map.wk_label then
		-- use wrapper label if no local label is present
		label = wrapper_label
	elseif wrapper_label.sub_desc and map.desc and not map.wk_label then
		-- generate label from subbed local desc if a desc is present
		label = sub_desc_to_label(map.desc, wrapper_label.sub_desc)
	end

	---@cast label string
	return label
end

-- Options ====================================================================

local custom_opts = { "mode", "wk_label", "ft" }
for _, key in ipairs(custom_opts) do
	custom_opts[key] = true
end

---@param opts VimMapOpts
---@param t NxMap|NxMapOpts
---@return VimMapOpts
local function add_opts(opts, t)
	for k, v in pairs(t) do
		if type(k) ~= "number" and not custom_opts[k] and opts[k] == nil then opts[k] = v end
	end

	return opts
end

---Remove custom opts and retain opts passed to `vim.keymap.set()`
---@param map NxMap
---@param wrapper_opts? NxMapOpts
---@return VimMapOpts
local function get_vim_opts(map, wrapper_opts)
	local opts = {}

	add_opts(opts, map)
	if wrapper_opts then add_opts(opts, wrapper_opts) end

	return opts
end

-- Create Keymaps  ============================================================

---@param map NxMap
---@param wrapper_opts NxMapOpts
---@param wk_labels string[]
local function set_map(map, wrapper_opts, wk_labels)
	local lhs, rhs = map[1], map[2]
	local mode = map[3] or map.mode or wrapper_opts.mode or "n"
	local vim_opts = get_vim_opts(map, wrapper_opts)

	if type(lhs) == "table" then
		for _, v in ipairs(lhs) do
			vim.keymap.set(mode, v, rhs, vim_opts)
		end
	else
		vim.keymap.set(mode, lhs, rhs, vim_opts)
	end

	if wk_ok and not vim_opts.buffer then wk_labels[lhs] = get_wk_label(map, wrapper_opts.wk_label) end
end

---@param ft_maps {[string]: NxMap} @dictionary of filetype keymaps
---@param wrapper_opts NxMapOpts
local function set_ft_maps(ft_maps, wrapper_opts)
	for ft, maps in pairs(ft_maps) do
		vim.api.nvim_create_autocmd("FileType", {
			pattern = ft,
			callback = function()
				for _, map in pairs(maps) do
					map.buffer = map.buffer or wrapper_opts.buffer or 0
					set_map(map, wrapper_opts, {})
				end
			end,
		})
	end
end

---Set keymaps
--
---NxMap:
-- `[1]`: string|string[] @lhs,
-- `[2]`: string|function @rhs,
-- `[3]?`: mode|mode[] @mode defaults to `"n"` can be passed as index `[3]` or `mode` key.
-- `ft?`: string @pattern the keymap should be set for
-- `wk_label?`: string|{sub_desc: string}, @which-key label that should be different from it's description
-- `desc?`: string,
-- `buffer?`: number|boolean,
-- `expr?`: boolean,
-- `<…>` any other key-value pair for `vim.keymap.set()` options is passed inline as well
--
---`wrapper_opts?`: apply options to all keys in a `nx.map()` call
-- (options passed to single keys are prioritized)
--
---Examples:
-- ---
-- ```lua
-- nx.map({ ";q", "<Cmd>confirm quit<CR>", desc = "Close Current Window" })
-- ---@ ╰── set a single keymap
-- ---@ ╭── or lists of keymaps
-- nx.map({
--    -- Line Navigation
--    ---@    ╭── multiple lhs
--    { { "j", "<Up>" }, "&wrap ? 'gj' : 'j'", "" },
--    { { "k", "<Down>" }, "&wrap ? 'gk' : 'k'", "" },
--    { "$", "&wrap ? 'g$' : '$'", "" },
--    { "^", "&wrap ? 'g^' : '^'", "" },
--    -- Indentation
--    { "i", function() return smart_indent "i" end },
--    { "a", function() return smart_indent "a" end },
--    { "A", function() return smart_indent "A" end },
--    }, { expr = true, silent = true })
-- ---@      ╰── wrapper opts apply options to all entries
--
-- nx.map({
--    { "<Esc>", "<Esc>", "i" },
--    { "<C-c>", "<Cmd>close<CR>", { "i", "x" } },
--    { "q", "<Cmd>close<CR>", "x" },
--    ---@ set filetype keymaps ──╮ (in {wrapper_opts} or for single keymaps)
-- }, { buffer = 0, ft = "DressingInput" })
--
-- -- `mode`: defaults to `"n"` and can be passed as index `[3]` or `mode` key
-- nx.map({
--    { "<kEnter>", "<CR>", { "", "!" }, desc = "Enter" }
--    ---@ ^=                      ╰── or  ──╮
--    { "<kEnter>", "<CR>", desc = "Enter", mode = { "", "!" } }
-- }, { mode = { "", "!" }) -- or in wrapper_opts (here it has to be the `mode` key)
-- ```
---@param nx_map NxMap|NxMap[]
---@param wrapper_opts? NxMapOpts
return function(nx_map, wrapper_opts)
	wrapper_opts = wrapper_opts or {}

	---@type string[]
	local wk_labels = {}
	---@type {[string]: NxMap}
	local ft_maps = {}

	-- handle single keymap
	if
		(type(nx_map[1]) == "string" or type(nx_map[1]) == "table")
		and (type(nx_map[2]) == "string" or type(nx_map[2]) == "function")
	then
		if nx_map.ft or wrapper_opts.ft then
			ft_maps[nx_map.ft] = ft_maps[nx_map.ft] or {}
			ft_maps[nx_map.ft][1] = nx_map
			set_ft_maps(ft_maps, wrapper_opts)
		else
			set_map(nx_map, wrapper_opts, wk_labels)
		end
		if wk_ok then vim.schedule(function() wk.register(wk_labels) end) end
		return
	end

	-- handle lists of keymaps
	for _, map in pairs(nx_map) do
		if map.ft or wrapper_opts.ft then
			map.ft = map.ft or wrapper_opts.ft
			ft_maps[map.ft] = ft_maps[map.ft] or {}
			table.insert(ft_maps[map.ft], map)
		else
			set_map(map, wrapper_opts, wk_labels)
		end
	end

	if wk_ok then vim.schedule(function() wk.register(wk_labels) end) end
	set_ft_maps(ft_maps, wrapper_opts)
end
