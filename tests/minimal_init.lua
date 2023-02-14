local dependencies = {
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/folke/which-key.nvim",
}

for _, source in ipairs(dependencies) do
	local plugin_dir = "/tmp/" .. source:gsub(".*/", "")

	if vim.fn.isdirectory(plugin_dir) == 0 then vim.fn.system({ "git", "clone", source, plugin_dir }) end

	vim.opt.rtp:append(plugin_dir)
end

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")

vim.opt.rtp:append("../")
