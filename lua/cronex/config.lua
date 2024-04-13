local M = {}


local defaults = {
	file_patterns = { "*.yaml", "*.yml", "*.tf", "*.cfg", "*.config", "*.conf" },
	extractor = {
		cron_from_line = require("cronex.cron_from_line").cron_from_line,
		extract = require("cronex.extract").extract,
	},
	explainer = {
		cmd = "cronstrue",
		args = {}
	},
	format = function(s)
		return s
	end
}

M.parse_opts = function(opts)
	local user = vim.F.if_nil(opts, {})

	-- Set first level keys, otherwise user.* will fail
	for k, v in pairs(defaults) do
		user[k] = vim.F.if_nil(user[k], v)
	end

	local extract = function()
		local extract = user.extractor.extract or defaults.extractor.extract
		local cron_from_line = user.extractor.cron_from_line or defaults.extractor.cron_from_line
		return extract(cron_from_line)
	end

	local explain = function(cron)
		local cmd = user.explainer.cmd or defaults.explainer.cmd
		local args = user.explainer.args or defaults.explainer.args
		local full_cmd = vim.tbl_flatten({ cmd, args })
		return require("cronex.explain").explain(full_cmd, cron)
	end

	return {
		file_patterns = user.file_patterns or defaults.file_patterns,
		extract = extract,
		explain = explain,
		format = user.format or defaults.format,
	}
end


return M
