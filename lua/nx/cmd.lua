-- Annotations ================================================================

---@class NxCmd : VimCmdOpts
---@field [1] string @command name
---@field [2] string|function @command action

-- NOTE: incomplete
---@class VimCmdOpts @references: `h: command-<param>`
---@field desc? string
---@field bang? boolean
---@field nargs? "0"| "1"| "*"| "?"| "+"|
---@field force? boolean
---@field complete? string|function

-- Options ====================================================================

---@param opts VimCmdOpts
---@param t NxCmd|VimCmdOpts
---@return VimCmdOpts
local function add_opts(opts, t)
	for k, v in pairs(t) do
		if type(k) ~= "number" and opts[k] == nil then opts[k] = v end
	end

	return opts
end

---@param cmd NxCmd
---@param wrapper_opts? VimCmdOpts
---@return VimCmdOpts
local function get_vim_opts(cmd, wrapper_opts)
	local opts = {}

	add_opts(opts, cmd)
	if wrapper_opts then add_opts(opts, wrapper_opts) end

	return opts
end

-- Create Commands ============================================================

---Create commands
--
---NxCmd:
-- `[1]`: string|string[] @command_name,
-- `[2]`: string|function @command_action
-- `<…>` any other key-value pair for `nvim_create_user_command()` options is passed inline as well
--
---`wrapper_opts?`: apply options to all commands in a `nx.cmd()` call
-- (options passed to single commands are prioritized)
--
---Examples:
-- ---
-- ```lua
-- ---@ ╭── create a single command
-- nx.cmd({ "ResetTerminal", function() vim.cmd("set scrollback=1 | sleep 10m | set scrollback=10000") end })
-- ---@ ╭── or lists of commands
-- nx.cmd({
--    { "LspFormat", function() vim.lsp.buf.format({ async = true }) end },
--    { "LspToggleAutoFormat", function(opt) toggle_format_on_save(opt.args) end, nargs = "?" },
--    { "ToggleBufferDiagnostics", function() toggle_buffer_diags(vim.fn.bufnr()) end },
-- }, { bang = true })
-- ---@   ╰── wrapper opts apply options to all entries without them
-- ```
---@param cmds NxCmd|NxCmd[]
---@param wrapper_opts? VimCmdOpts
return function(cmds, wrapper_opts)
	wrapper_opts = wrapper_opts or {}

	-- handle single cmd
	if type(cmds[1]) == "string" and (type(cmds[2]) == "string" or type(cmds[2]) == "function") then
		local vim_opts = get_vim_opts(cmds, wrapper_opts)
		---@diagnostic disable-next-line: param-type-mismatch
		vim.api.nvim_create_user_command(cmds[1], cmds[2], vim_opts)
		return
	end

	-- handle list of cmds
	for _, cmd in pairs(cmds) do
		local vim_opts = get_vim_opts(cmd, wrapper_opts)
		vim.api.nvim_create_user_command(cmd[1], cmd[2], vim_opts)
	end
end
