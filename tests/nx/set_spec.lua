local set = require("nx.set")

describe("NxSet", function()
	it("can set variables", function()
		set({
			dracula_italic = 1,
			dracula_bold = 1,
			dracula_full_special_attrs_support = 1,
			dracula_colorterm = 0,
		})
		assert.equal(1, vim.g.dracula_italic)
		assert.equal(1, vim.g.dracula_bold)
		assert.equal(1, vim.g.dracula_full_special_attrs_support)
		assert.equal(0, vim.g.dracula_colorterm)
	end)

	it("can set options", function()
		set({
			clipboard = "unnamedplus",
			mouse = "a",
			showmode = false,
			termguicolors = true,
			timeoutlen = 350,
		}, vim.opt)

		assert.equal("unnamedplus", vim.o.clipboard)
		assert.equal("a", vim.o.mouse)
		assert.falsy(vim.o.showmode)
		assert.truthy(vim.o.termguicolors)
		assert.equal(350, vim.o.timeoutlen)
	end)

	it("can append to options", function()
		vim.o.fillchars = "eob: "
		set({
			fillchars__append = "vert:▏",
		}, vim.opt)

		assert.equal("eob: ,vert:▏", vim.o.fillchars)
	end)
end)
