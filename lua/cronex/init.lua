local api = vim.api
--TODO: make it cronex.nvim-plugin
local ns = api.nvim_create_namespace("cronex")

local M = {}

local make_set_explanations = function(config)
	local set_explanations = function()
		local bufnr = 0
		vim.diagnostic.reset(ns, bufnr) -- Start fresh
		--local explanations = {}
		local crons = config.extract()
		local cmd = '/home/fdamicel/cronstrue/.npm/bin/cronstrue'

		local explanations = {}
		for lnum, cron in pairs(crons) do
			--local raw_explanation =
			require("cronex.explain").explain(cmd, cron, bufnr, lnum, ns, explanations)

			-- 	local explanation = config.format(raw_explanation)
			-- 	table.insert(explanations, {
			-- 		bufnr = bufnr,
			-- 		lnum = lnum,
			-- 		col = 0,
			-- 		message = explanation,
			-- 		severity = vim.diagnostic.severity.HINT,
			-- 	})
			-- end
			-- vim.diagnostic.set(ns, bufnr, explanations, {})
		end
	end
	return set_explanations
end


M.hide_explanations = function()
	vim.diagnostic.reset(ns, 0)
end


M.enable = function()
	M.augroup = api.nvim_create_augroup("cronex", { clear = true })
	api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
		group = M.augroup,
		buffer = 0,
		callback = require("cronex").set_explanations,
		desc = "Set explanations when leaving insert mode or changing the text"
	})

	api.nvim_create_autocmd({ "InsertEnter" }, {
		group = M.augroup,
		buffer = 0,
		callback = require("cronex").hide_explanations,
		desc = "Hide explanations when entering insert mode"
	})
	require("cronex").set_explanations()
end


M.disable = function()
	vim.diagnostic.reset(ns, 0)
	-- pcall: let error (because groud no longer exists) go silent
	-- on successive calls to CronExplainedDisable
	pcall(function()
		api.nvim_del_augroup_by_id(M.augroup)
	end)
end


M.setup = function(opts)
	M.config = require("cronex.config").parse_opts(opts)

	M.set_explanations = make_set_explanations(M.config)

	api.nvim_create_user_command("CronExplainedEnable",
		require("cronex").enable,
		{ desc = "Enable explanations of cron expressions" })

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
