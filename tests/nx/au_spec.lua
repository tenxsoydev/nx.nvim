local au = require("nx.au")
local filter = vim.tbl_filter

describe("NxAu", function()
	it("can create an autocommand", function()
		au({
			"FocusGained",
			pattern = "*.*",
			command = "checktime",
			desc = "Check if buffers were modified outside of Vim",
		})
		assert.equals("checktime", vim.api.nvim_get_autocmds({ event = "FocusGained" })[1]["command"])
	end)

	it("can create multiple autocommands", function()
		au({
			{ "BufWritePost", pattern = "options.lua", command = "source <afile>", desc = "Execute files on save" },
			{ "BufWritePre", command = "call mkdir(expand('<afile>:p:h'), 'p')", desc = "Create non-existent parents" },
		})

		local aus = vim.api.nvim_get_autocmds({
			event = { "BufWritePre", "BufWritePost" },
		})
		assert.equals("source <afile>", filter(function(k) return k.pattern == "options.lua" end, aus)[1].command)
		assert.equals(1, #filter(function(k) return k.desc == "Create non-existent parents" end, aus))
		assert.equals(0, #filter(function(k) return k.desc == "non_existent_au" end, aus))
	end)

	it("can create autocommand groups", function()
		au({
			{ "BufWinLeave", pattern = "*.*", command = "mkview" },
			{ "BufWinEnter", pattern = "*.*", command = "silent! loadview" },
		}, { create_group = "RememberFolds" })

		local aus = vim.api.nvim_get_autocmds({
			group = "RememberFolds",
		})
		assert.equals("silent! loadview", filter(function(k) return k.event == "BufWinEnter" end, aus)[1].command)
		assert.equals("mkview", filter(function(k) return k.event == "BufWinLeave" end, aus)[1].command)
	end)
end)
