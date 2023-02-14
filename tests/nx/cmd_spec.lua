local cmd = require("nx.cmd")
local filter = vim.tbl_filter

describe("NxCmd", function()
	it("can create a command", function()
		cmd({
			"LspFormat",
			function() vim.lsp.buf.format({ async = true }) end,
			bang = true,
			desc = "Fromat the Current Buffer",
		})

		local format_command =
			filter(function(k) return k.name == "LspFormat" end, vim.api.nvim_get_commands({ builtin = false }))[1]
		assert.truthy(format_command.bang)
		assert.equals("Fromat the Current Buffer", format_command.definition)
	end)

	it("can create multiple commands", function()
		cmd({
			{ "ResetTerminal", function() vim.cmd("set scrollback=1 | sleep 10m | set scrollback=10000") end },
			{
				"WipeRegisters",
				function()
					for i = 34, 122 do
						pcall(vim.fn.setreg, vim.fn.nr2char(i), "")
					end
					vim.cmd("wshada!")
				end,
				desc = "Clear All Registers",
			},
			{
				"PrintXHellos",
				function(x)
					for i = 1, type(x) == "string" and tonumber(x) or 1 do
						print("Hello")
					end
				end,
				nargs = "?",
			},
		})

		local user_cmds = vim.api.nvim_get_commands({ builtin = false })

		local wipe_regs_cmd = filter(function(k) return k.name == "WipeRegisters" end, user_cmds)[1]
		local reset_terminal_cmd = filter(function(k) return k.name == "ResetTerminal" end, user_cmds)[1]
		local print_x_hellos_cmd = filter(function(k) return k.name == "PrintXHellos" end, user_cmds)[1]
		assert.equals("Clear All Registers", wipe_regs_cmd.definition)
		assert.equals("", reset_terminal_cmd.definition)
		assert.falsy(reset_terminal_cmd.bang)
		assert.equals("?", print_x_hellos_cmd.nargs)
	end)

	it("can add wrapper opts", function()
		cmd({
			{ "LspToggleAutoFormat", function(opt) _toggle_format_on_save(opt.args) end, nargs = "?" },
			{ "ToggleBufferDiagnostics", function() _toggle_buffer_diags(vim.fn.bufnr()) end },
		}, { bang = true })

		local wrapped_commands = {
			toggle_format = filter(
				function(k) return k.name == "LspToggleAutoFormat" end,
				vim.api.nvim_get_commands({ builtin = false })
			)[1],
			toggle_diags = filter(
				function(k) return k.name == "ToggleBufferDiagnostics" end,
				vim.api.nvim_get_commands({ builtin = false })
			)[1],
		}
		assert.truthy(wrapped_commands.toggle_format.bang)
		assert.falsy(not wrapped_commands.toggle_diags.bang)
	end)
end)
