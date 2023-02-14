-- Annotations ================================================================

---@class NxAu : NxAuOpts
---@field [1] string|string[] @event

---@class NxAuOpts : VimAuOpts
---@field create_group? string|NxAuGroup

---@class NxAuGroup
---@field [1] string @group name
---@field clear boolean @clear existing commands if the group already exists. Defaults to true

---@class VimAuOpts @references: `h: nvim_create_autocmd()`
---@field group? string|number
---@field pattern? string|string[]
---@field buffer? number|boolean
---@field desc? string
---@field callback? string|function
---@field command? string
---@field once? boolean
---@field nested? boolean

-- Options ====================================================================

---@param opts VimAuOpts
---@param t NxAu|VimAuOpts
---@return VimAuOpts
local function add_opts(opts, t)
	for k, v in pairs(t) do
		if type(k) ~= "number" and k ~= "create_group" and opts[k] == nil then opts[k] = v end
	end

	return opts
end

---Remove custom opts and retain opts passed to `nvim_create_autocmd()`
---@param au NxAu
---@param wrapper_opts? NxAuOpts
---@return VimAuOpts
local function get_vim_opts(au, wrapper_opts)
	local opts = {}

	add_opts(opts, au)
	if wrapper_opts then add_opts(opts, wrapper_opts) end

	return opts
end

-- Create AuGroups ============================================================

---@parm group string|NxAuGroup
local function create_group(group)
	local group_name

	if type(group) == "string" then
		vim.api.nvim_create_augroup(group, {})
		group_name = group
	else
		vim.api.nvim_create_augroup(group[1], { clear = group.clear })
		group_name = group[1]
	end

	return group_name
end

-- Create Autocmds ============================================================

---Create autocommands
--
---NxAu:
-- `[1]`: string|string[] @command_name,
-- `[2]`: string|function @command_action
-- `<…>` any other key-value pair for `nvim_create_user_command()` options is passed inline as well
--
---`wrapper_opts?`: apply options to all autocmds in a `nx.au()` call
-- (options passed to single autocmds are prioritized)
--
---Examples:
-- ---
-- ```lua
-- nx.au({ "FocusGained", pattern = "*.*", command = "checktime", desc = "Check if buffer changed outside of vim" })
-- ---@ ╰── create a single autocommand
-- ---@ ╭── or lists of autocommands
-- nx.au({
--    { "BufWinLeave", pattern = "*.*", command = "mkview" },
--    { "BufWinEnter", pattern = "*.*", command = "silent! loadview" },
-- }, { pattern = "*.*" })
-- ---@     ╰── wrapper opts apply values to all entries without them
--
-- -- auto command groups
-- nx.au({
--    "BufWritePre",
--    -- group = "FormatOnSave", ---@ use `group` as usual to add the autocmd to an already existing group
--    create_group = "FormatOnSave", ---@ or create a new group while creating an autocmd
--    callback = function()
--       if next(vim.lsp.get_active_clients({ bufnr = 0 })) == nil then return end
--       vim.lsp.buf.format({ async = false })
--    end,
-- })
-- nx.au({
--    { "BufWinLeave", pattern = "*.*", command = "mkview" },
--    { "BufWinEnter", pattern = "*.*", command = "silent! loadview" },
--    ---@   ╭── create an autocommand group in `wrapper_opts` and add all autocommands within a "nx.au()" call
-- }, { create_group = "RememberFolds" })
-- ```
-- ```
---@param aus NxAu|NxAu[]
---@param wrapper_opts? NxAuOpts
return function(aus, wrapper_opts)
	wrapper_opts = wrapper_opts or {}

	if wrapper_opts.create_group then
		local created_group = create_group(wrapper_opts.create_group)
		wrapper_opts.group = wrapper_opts.group or created_group
	end

	-- handle single au
	if aus.command or aus.callback then
		if aus.create_group then
			local created_group = create_group(aus.create_group)
			aus.group = aus.group or created_group or wrapper_opts.group
		end

		local vim_opts = get_vim_opts(aus, wrapper_opts)
		vim.api.nvim_create_autocmd(aus[1], vim_opts)
		return
	end

	-- handle list of aus
	for _, au in pairs(aus) do
		if au.create_group then
			local created_group = create_group(au.create_group)
			au.group = au.group or created_group or wrapper_opts.group
		end

		local vim_opts = get_vim_opts(au, wrapper_opts)

		vim.api.nvim_create_autocmd(au[1], vim_opts)
	end
end
