local M = {}


local defaults = {
	file_patterns = { "*.yaml", "*.yml", "*.tf", "*.cfg", "*.config", "*.conf" },
	extractor = {
		cron_from_line = require("cronex.cron_from_line").cron_from_line,
		extract = require("cronex.extract").extract,
	},
	explainer = {
		cmd = "cronstrue",
		args = {},
		timeout = 10000, --TODO : acceptance test?
	},
	format = function(s) --TODO: acceptance test?
		return s
	end
}

M.parse_opts = function(opts)
	opts = vim.tbl_deep_extend("force", defaults, opts)

	local extract = function()
		return opts.extractor.extract(opts.extractor.cron_from_line)
	end

	local explain = function(cron, lnum, bufnr, explanations, ns)
		local cmd = vim.iter({ opts.explainer.cmd, opts.explainer.args }):flatten():totable()
		require("cronex.explain").explain(cmd, opts.explainer.timeout, cron, opts.format, bufnr, lnum, ns, explanations)
	end

	return {
		file_patterns = opts.file_patterns,
		extract = extract,
		explain = explain,
	}
end


return M
