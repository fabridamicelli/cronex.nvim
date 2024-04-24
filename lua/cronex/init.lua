local api = vim.api
local ns = api.nvim_create_namespace("cronex")

local M = {}

local make_set_explanations = function(config)
	local set_explanations = function()
		local bufnr = 0
		vim.diagnostic.reset(ns, bufnr) -- Start fresh

		local explanations = {}
		local crons = config.extract()
		for lnum, cron in pairs(crons) do
			local raw_explanation = config.explain(cron)
			local explanation = config.format(raw_explanation)
			table.insert(explanations, {
				bufnr = bufnr,
				lnum = lnum,
				col = 0,
				message = explanation,
				severity = vim.diagnostic.severity.HINT,
			})
		end
		vim.diagnostic.set(ns, bufnr, explanations, {})
	end
	return set_explanations
end


M.hide_explanations = function()
	vim.diagnostic.reset(ns, 0)
end


M.enable = function()
	M.augroup = api.nvim_create_augroup("cronex", { clear = true })
	api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "TextChanged" }, {
		group = M.augroup,
		buffer = 0,
		callback = require("cronex").set_explanations,
	})

	api.nvim_create_autocmd({ "InsertEnter" }, {
		group = M.augroup,
		buffer = 0,
		callback = require("cronex").hide_explanations,
	})
	require("cronex").set_explanations()
end


M.disable = function()
	vim.diagnostic.reset(ns, 0)
	api.nvim_del_augroup_by_id(M.augroup)
end


M.setup = function(opts)
	M.config = require("cronex.config").parse_opts(opts)

	M.set_explanations = make_set_explanations(M.config)

	api.nvim_create_user_command("CronExplainedEnable",
		require("cronex").enable,
		{ desc = "Disable explanations of cron expressions" })

	api.nvim_create_user_command("CronExplainedDisable",
		require("cronex").disable,
		{ desc = "Disable explanations of cron expressions" })

	api.nvim_create_autocmd("BufEnter", {
		group = M.augroup,
		pattern = M.config.file_patterns,
		callback = M.enable,
	})
end

return M
