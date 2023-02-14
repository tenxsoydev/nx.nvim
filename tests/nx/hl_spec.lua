local hl = require("nx.hl")

---@parm hl_name string
local function get_hl(hl_name) return vim.api.nvim_get_hl_by_name(hl_name, true) end

---We'll use this one as the values for `fg` and `bg` returned in get_hl are decimal values
---@parm hex_val string
local function hex_to_dec(hex_val) return tonumber(hex_val:gsub("#", ""), 16) end

---local tint funciton copied from ../../lua/nx/hl.lua
---@param col number|string
---@param amt number @amount to lighten/darken the source color "+15"|"-15"
local function tint(col, amt)
	col = tonumber(col:gsub("#", ""), 16)

	local function clamp(val) return math.min(math.max(val, 0), 16777215) end

	local r = math.floor(col / 65536) + amt
	local g = (math.floor(col / 256) % 256) + amt
	local b = (col % 256) + amt

	return clamp(r) * 65536 + clamp(g) * 256 + clamp(b)
end

-- an example palette of hex colors (reference: dracula)
local palette = {
	fg = "#F8F8F2",
	bg = "#282A36",
	bgdark = "#21222C",
	comment = "#6272A4",
	-- ...
}

describe("NxHl", function()
	it("can set a highlight", function()
		hl({ "DraculaComment", fg = palette.comment, italic = true })
		local dracula_comment_hl = get_hl("DraculaComment")
		assert.equals(hex_to_dec(palette.comment), dracula_comment_hl["foreground"])
		assert.truthy(dracula_comment_hl, dracula_comment_hl["italic"])
	end)

	it("can set multiple highlights", function()
		hl({
			{ "DraculaBg", bg = palette.bg },
			{ "DraculaPurple", fg = "MediumPurple" },
			{ { "Directory", "MarkSign" }, link = "DraculaPurple" },
		})
		local hls = {
			bg = get_hl("DraculaBg"),
			purple = get_hl("DraculaPurple"),
			directory = get_hl("Directory"),
			mark_sign = get_hl("MarkSign"),
		}
		local medium_purple = hex_to_dec("#9370DB") -- (reference: hex of html color name `MediumPurple`)
		assert.equals(hex_to_dec(palette.bg), hls.bg["background"])
		assert.equals(medium_purple, hls.purple["foreground"])
		assert.equals(medium_purple, hls.mark_sign["foreground"])
		assert.equals(medium_purple, hls.directory["foreground"])
	end)

	it("can add `:fg`|`:bg` modifiers to set a highlight parameters based on other highlights", function()
		hl({
			{ "LineNr", fg = "DraculaComment:fg" },
			{ "Normal", bg = "DraculaBg:bg" },
		})

		assert.equals(get_hl("DraculaComment")["foreground"], get_hl("LineNr")["foreground"])
		assert.equals(get_hl("DraculaBg")["background"], get_hl("Normal")["background"])
	end)

	it("can add a `:#b` modifier to set a highlight with transformed brightness", function()
		hl({
			{ "WinbarPath", fg = "DraculaComment:fg:#b+10" }, -- using hl created in test above
			{ "DraculaBgDarker", bg = palette.bgdark .. ":#b-5" },
		})
		local lightened_comment = tint(palette.comment, 10)
		local darkened_bg = tint(palette.bgdark, -5)
		assert.truthy(lightened_comment > tonumber(palette.comment:gsub("#", ""), 16))
		assert.equals(lightened_comment, get_hl("WinbarPath")["foreground"])
		assert.truthy(darkened_bg < tonumber(palette.bg:gsub("#", ""), 16))
		assert.equals(darkened_bg, get_hl("DraculaBgDarker")["background"])
	end)

	it("can add values via wrapper opts", function()
		hl({ "TabLine", bg = palette.bgdark })
		local tabline_bg = get_hl("TabLine")["background"]
		assert.equals(hex_to_dec(palette.bgdark), tabline_bg)

		hl({
			{ "NeoTreeTabActive", bg = palette.bg },
			{ "NeoTreeTabInactive", fg = "WinbarPath:fg" },
			{ "NeoTreeTabSeparatorInactive", fg = "TabLine:bg" },
		}, { bg = "TabLine:bg" })

		assert.equals(tabline_bg, get_hl("NeoTreeTabInactive")["background"])
		assert.equals(tabline_bg, get_hl("NeoTreeTabSeparatorInactive")["background"])
		assert.equals(hex_to_dec(palette.bg), get_hl("NeoTreeTabActive")["background"])
	end)
end)
