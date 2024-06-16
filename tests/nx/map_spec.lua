local map = require("nx.map")
local filter = vim.tbl_filter
local get_map = vim.api.nvim_get_keymap
local get_bmap = vim.api.nvim_buf_get_keymap
local wk = require("which-key")

describe("NxMap", function()
	it("can set a keymap", function()
		map({ ";w", "<Cmd>write<CR>" })

		local nmap = filter(function(k) return k.lhsraw == ";w" end, get_map("n"))[1]
		assert.equals(nmap.lhsraw, ";w")
		assert.equals(nmap.rhs, "<Cmd>write<CR>")
	end)

	it("can set multiple keymaps", function()
		map({
			{ "<leader>p", function() print("Test") end, desc = "Test", "v" },
			{ { "jk", "kj" }, "<Esc>", "i" },
		})

		local vmap = filter(function(k) return k.lhsraw == "\\p" end, get_map("v"))[1]
		assert.equals(vmap.desc, "Test")
		assert.equals(type(vmap.callback), "function")

		local multi_lhs = {
			filter(function(k) return k.lhsraw == "jk" end, get_map("i"))[1],
			filter(function(k) return k.lhsraw == "kj" end, get_map("i"))[1],
		}
		assert.equals(multi_lhs[1].lhsraw, "jk")
		assert.equals(multi_lhs[1].rhs, "<Esc>")
		assert.equals(multi_lhs[2].lhsraw, "kj")
		assert.equals(multi_lhs[2].rhs, "<Esc>")
	end)

	it("can add wrapper opts", function()
		map({
			{ { "j", "<Down>" }, "&wrap ? 'gj' : 'j'" },
			{ "^", "&wrap ? 'g^' : '^'" },
			{ ";c", "<Cmd>Bdelete<CR>", "", expr = false },
		}, { mode = "", silent = true, expr = true })

		local j = filter(function(k) return k.lhsraw == "j" end, get_map(""))
		local ast = filter(function(k) return k.lhsraw == "^" end, get_map(""))
		local close = filter(function(k) return k.lhsraw == ";c" end, get_map(""))

		assert.equals("&wrap ? 'gj' : 'j'", j[1].rhs)
		assert.equals(1, j[1].expr)
		assert.equals(1, ast[1].silent)
		assert.equals(0, close[1].expr)
	end)

	it("can set keymaps for filetypes", function()
		local md_aus_pre = vim.api.nvim_get_autocmds({ pattern = { "markdown" } })

		map({ "j", "gj", desc = "md keymap", ft = "markdown" })
		-- test using wrapper_opts
		map({ { "k", "gk" } }, { ft = "markdown" })

		-- check if autocommands for setting buffer keymaps were created
		assert.equals(0, #md_aus_pre)
		assert.equals(2, #vim.api.nvim_get_autocmds({ pattern = { "markdown" } }))

		-- keymaps should be not set yet
		assert.equals(0, #filter(function(k) return k.desc == "md keymap" end, get_map("n")))
		assert.equals(0, #filter(function(k) return k.desc == "md keymap" end, get_bmap(0, "n")))

		-- change the buffers filetype and assert the keymaps were set
		vim.bo.ft = "markdown"
		local md_maps = {
			j = filter(function(k) return k.lhsraw == "j" end, get_bmap(0, "n")),
			k = filter(function(k) return k.lhsraw == "k" end, get_bmap(0, "n")),
		}
		assert.equals(1, #md_maps.j)
		assert.equals("j", md_maps.j[1].lhsraw)
		assert.equals("gj", md_maps.j[1].rhs)
		assert.equals(1, #md_maps.j)
		assert.equals("k", md_maps.k[1].lhsraw)
		assert.equals("gk", md_maps.k[1].rhs)
	end)

	it("can add custom which-key labels", function()
		-- add a custom string literal label
		local desc = "Some long description"
		local label = "Short label"
		map({ { "j", "k", desc = desc, wk_label = label } })

		wk.setup()
		vim.wait(1, wk.load)

		local wk_key = require("which-key.keys").mappings.n.tree.root.children.j.mapping
		assert.equals(wk_key.desc, desc)
		assert.equals(wk_key.opts.desc, label)

		-- use a substring of the mappings description as label
		map({
			{ "tw", "<Cmd>set list!<CR>", desc = "Toggle Whitespace Characters", wk_label = { sub_desc = "Toggle" } },
		})

		wk.setup()
		vim.wait(1, wk.load)

		local toggle_mapping = filter(
			function(k) return k.mapping.desc == "Toggle Whitespace Characters" end,
			require("which-key.keys").mappings.n.tree.root.children.t.children
		)[1].mapping

		assert.equals(toggle_mapping.desc, "Toggle Whitespace Characters")
		assert.equals(toggle_mapping.opts.desc, "Whitespace Characters")

		-- test deriving a substring with wrapper opts
		map({
			{ "sf", "<Cmd>SomeFileSearchCommmand<CR>", desc = "Search Files" },
			{ "sr", "<Cmd>SomeRegisterSearchCommand<CR>", desc = "Search Registers" },
		}, { wk_label = { sub_desc = "Search" } })

		wk.setup()
		vim.wait(1, wk.load)

		local wk_keys = require("which-key.keys").mappings.n.tree.root.children.s.children
		local search_mappings = {
			files = filter(function(k) return k.mapping.keys.keys == "sf" end, wk_keys)[1].mapping,
			registers = filter(function(k) return k.mapping.keys.keys == "sr" end, wk_keys)[1].mapping,
		}

		assert.equals(search_mappings.files.desc, "Search Files")
		assert.equals(search_mappings.files.opts.desc, "Files")
		assert.equals(search_mappings.registers.desc, "Search Registers")
		assert.equals(search_mappings.registers.opts.desc, "Registers")
	end)
end)
