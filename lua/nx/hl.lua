-- Annotations ================================================================

---@class NxHl : NxHlOpts
---@field [1] string|string[] @highlight_name
---@field [2]? number|number[] @can be passed as index `[2]` or `ns_id` key - defaults to `0`

---@class NxHlOpts : VimHlOpts
---@field brightness? number
---@field ns_id? number|number[]

---@class VimHlOpts @reference `:h nvim_set_hl()`
---@field fg? Color
---@field bg? Color
---@field sp? Color
---@field blend? number
---@field bold? boolean
---@field standout? boolean
---@field underline? boolean
---@field undercurl? boolean
---@field underdouble? boolean
---@field underdotted? boolean
---@field underdashed? boolean
---@field strikethrough? boolean
---@field italic? boolean
---@field reverse? boolean
---@field nocombine? boolean
---@field link? string @name of another highlight group to link to
---@field defaul? boolean @don't override existing definition
---@field ctermfg? string @sets foreground of cterm color
---@field ctermbg? string @sets background of cterm color
---@field cterm? table @cterm attribute map

-- Possible values: hex `"#6495ed"` | highlight `"Constant:fg"` | decimal `6591981` | colorname `"CornFlowerBlue"`
-- Modifiers: `:#b` is a tint modifier to change the brightness of values
--   Examples: `fg = "Normal:fg:#b-15"` | `bg = a_hex_var_from_a_color_palette .. ":#b+10"`
---@alias Color string|number

-- Options ====================================================================

---@param opts VimHlOpts
---@param t NxHl|NxHlOpts
---@return VimHlOpts
local function add_opts(opts, t)
	for k, v in pairs(t) do
		if type(k) ~= "number" and k ~= "brightness" and opts[k] == nil then opts[k] = v end
	end

	return opts
end

---Remove custom opts and retain opts passed to `nvim_set_hl()`
---@param hl NxHl
---@param wrapper_opts? NxHlOpts
---@return VimHlOpts
local function get_vim_opts(hl, wrapper_opts)
	local opts = {}

	add_opts(opts, hl)
	if wrapper_opts then add_opts(opts, wrapper_opts) end

	return opts
end

-- Transfrom Colors ===========================================================

---Check if a string contains a hex value
---@parm val string
local function is_hex(val)
	if (val:match("^#?%x%x%x$") or val:match("^#?%x%x%x%x%x%x$")) ~= nil then return true end
	return false
end

---@param col number|string
---@param amt number @amount to lighten/darken the source color "+15"|"-15"
---@return number
local function tint(col, amt)
	if type(col) == "string" and is_hex(col) then col = tonumber(col:gsub("#", ""), 16) end

	local function clamp(val) return math.min(math.max(val, 0), 16777215) end

	local r = math.floor(col / 65536) + amt
	local g = (math.floor(col / 256) % 256) + amt
	local b = (col % 256) + amt

	return clamp(r) * 65536 + clamp(g) * 256 + clamp(b)
end

-- Evaluate Input =============================================================

---Returns color source without `:` modifiers
---@param val string @foreground|background
local function get_source(val)
	local source = val:gsub("(.*)%:.*$", "%1")
	if source:match(":") then source = get_source(source) end

	return source
end

---@param val string @foreground|background
---@return "fg"|"bg"?
local function get_prop(val)
	local prop = val:match(":fg") or val:match(":bg")
	if not prop then return end

	return prop:sub(2, 3)
end

---@param val string @foreground|background
---@return number?
local function get_tint_amount(val)
	local tint_amount = val:gsub(".*:#b", ""):sub(1, 3)

	return tonumber(tint_amount)
end

---@param source string
---@param prop "fg"|"bg"
---@param tint_amount? number
local function get_color_from_hl(source, prop, tint_amount)
	local hl = {}

	if type(source) == "number" then
		hl = vim.api.nvim_get_hl_by_id(source, true)
	else
		hl = vim.api.nvim_get_hl_by_name(source, true)
	end

	local color
	if prop == "fg" then
		color = hl["foreground"]
	elseif prop == "bg" then
		color = hl["background"]
	end

	if type(color) ~= "number" then return color end

	if tint_amount then color = tint(color, tint_amount) end

	return math.floor(color)
end

---Gets the setter color from an input that may contain `:` modifiers
---@param input string|number @foreground|background input that'll be evaluated as setter color
---@param wrapper_tint_amount? number
local function get_setter_color(input, wrapper_tint_amount)
	-- plain values like string color names, decimal and hexadecimal color values without modifiers
	if type(input) == "number" or (not input:match(":") and not wrapper_tint_amount) then return input end

	local source = get_source(input)
	local prop = get_prop(input)
	local tint_amount = get_tint_amount(input)
	if not tint_amount then tint_amount = wrapper_tint_amount end

	-- colors derived from another hl_group
	if prop then return get_color_from_hl(source, prop, tint_amount) end

	-- hex colors e.g., passed from a color pallets value
	if is_hex(source) and tint_amount then return tint(source, tint_amount) end

	-- decimal color values formatted as string
	if tonumber(source) and tint_amount then return tint(source, tint_amount) end

	-- color names that had added the brightness modifier
	if pcall(vim.api.nvim_set_hl, 0, "NxTintColorName", { fg = source }) and tint_amount then
		return get_color_from_hl("NxTintColorName", "fg", tint_amount)
	end

	vim.api.nvim_set_hl(0, "NxTintColorName", {})

	return source
end

-- Create Highlights ==========================================================

---@param hl NxHl
---@param wrapper_opts NxHlOpts
local function set_hl(ns_id, hl, wrapper_opts)
	local name = hl[1]

	hl.fg, hl.bg = hl.fg or wrapper_opts.fg, hl.bg or wrapper_opts.bg
	if hl.fg then hl.fg = get_setter_color(hl.fg, wrapper_opts.brightness) end
	if hl.bg then hl.bg = get_setter_color(hl.bg, wrapper_opts.brightness) end

	local vim_opts = get_vim_opts(hl, wrapper_opts)

	if type(name) == "table" then
		for _, v in ipairs(name) do
			vim.api.nvim_set_hl(ns_id, v, vim_opts)
		end
	else
		vim.api.nvim_set_hl(ns_id, name, vim_opts)
	end
end

local hl_opts = {
	"fg",
	"bg",
	"sp",
	"blend",
	"bold",
	"standout",
	"underline",
	"undercurl",
	"underdouble",
	"underdotted",
	"underdashed",
	"strikethrough",
	"italic",
	"reverse",
	"nocombine",
	"link",
	"defaul",
	"ctermfg",
	"ctermbg",
	"cterm",
}

---Set highlights
--
---NxHl:
-- `[1]`: string|string[] @highlight_name,
-- `[2]?`: number|number[] @ns_id be passed as index `[2]` or `ns_id` key - defaults to `0`
-- `fg?`: Color,
-- `bg?`: Color,
--   Color:
--     Possible values: hex `"#6495ed"` | highlight `"Constant:fg"` | decimal `6591981` | colorname `"CornFlowerBlue"`
--     Modifiers: `:#b` is a tint modifier you can add to change the brightness of values
-- `<…>` any other key-value pair for `nvim_set_hl()` values is passed inline as well
--
---`wrapper_opts?`: add values to all highlights in a `nx.hl()` call
-- (options passed to single keys are prioritized)
--
---Examples:
-- ---
-- ```lua
--  nx.hl({ "GitSignsCurrentLineBlame", fg = "Debug:fg", bg = "CursorLine:bg", italic = true })
--  ---@ ╰── set a single highlight
--  ---@ ╭── or lists of highlights
--  nx.hl({
--     { "Hex", fg = "#9370DB" },            --   ╮
--     { "ColorName", fg = "MediumPurple" }, ---@ ├  kinds of values already possible without nx.nvim
--     { "Decimal", fg = 9662683 },          --   ╯
--     --
--     { "Winbar", fg = "DraculaComment:fg" },
--     ---@                       ╭────╯  use single values from other highlight groups
--     { "Normal", bg = "DraculaBg:bg" },
--     ---@ use a color with transformed brightness  ──╮ ╭─ darken
--     { "BufferLineSeparatorShadow", fg = "TabLine:bg:#b-10", bg = "Normal:bg" } }
--     ---@ e.g., with hex var ──╮         ╭─ brighten
--     { "BgLight", bg = palette.bg .. ":#b+15" },
--     ---@           ╭── multiple highlight names
--     { { "Directory", "MarkSign" }, link = "DraculaPurple" },
--  }, { bold = true, italic = true })
--  ---@    ╰── wrapper opts apply values to all entries
--  ```
---@param hls NxHl|NxHl[]
---@param wrapper_opts? NxHlOpts
return function(hls, wrapper_opts)
	wrapper_opts = wrapper_opts or {}

	-- handle single hls
	for _, v in ipairs(hl_opts) do
		if hls[v] ~= nil then
			local ns_id = hls[2] or hls.ns_id or wrapper_opts.ns_id or 0
			if type(ns_id) == "table" then
				for _, id in ipairs(ns_id) do
					set_hl(id, hls, wrapper_opts)
				end
			else
				set_hl(ns_id, hls, wrapper_opts)
			end

			return
		end
	end

	-- handle lists of hls
	for _, hl in pairs(hls) do
		local ns_id = hl[2] or hl.ns_id or wrapper_opts.ns_id or 0

		if type(ns_id) == "table" then
			for _, id in ipairs(ns_id) do
				set_hl(id, hl, wrapper_opts)
			end
		else
			set_hl(ns_id, hl, wrapper_opts)
		end
	end
end
