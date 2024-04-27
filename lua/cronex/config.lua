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
	opts = vim.tbl_deep_extend("force", defaults, opts)

	local extract = function()
		return opts.extractor.extract(opts.extractor.cron_from_line)
	end

	local explain = function(cron)
		local cmd = opts.explainer.cmd
		local args = opts.explainer.args
		local full_cmd = vim.tbl_flatten({ cmd, args })
		return require("cronex.explain").explain(full_cmd, cron)
	end

	return {
		file_patterns = opts.file_patterns,
		extract = extract,
		explain = explain,
		format = opts.format,
	}
end


return M
