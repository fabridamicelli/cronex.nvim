local api = vim.api

local M = {}
local augroup_name = "plugin-cronex.nvim"
local ns = api.nvim_create_namespace(augroup_name)
local augroup = api.nvim_create_augroup(augroup_name, { clear = true })

local make_set_explanations = function(config)
	local set_explanations = function()
		--local bufnr = 0 --api.nvim_get_current_buf()
		--TODO Check
		local bufnr = api.nvim_get_current_buf()
		vim.diagnostic.reset(ns, bufnr)
		local crons = config.extract()

		local cmd = { "bash", "/home/fdamicel/projects/cronex-async/test.sh" } --TODO: remove
		local explanations = {}
		local cmd_handles = {}
		for lnum, cron in pairs(crons) do
			require("cronex.explain").explain(
				cmd, cron, bufnr, lnum, ns, explanations, cmd_handles
			--cmd, cron, bufnr, lnum, ns, explanations, M._cmd_handles
			)
		end
	end
	return set_explanations
end


M.enable = function()
	local set_explanations = make_set_explanations(M.config)
	api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
		group = augroup,
		buffer = 0,
		callback = set_explanations,
		desc = "Set explanations when leaving insert mode or changing the text"
	})

	api.nvim_create_autocmd({ "InsertEnter" }, {
		group = augroup,
		buffer = 0,
		callback = function() vim.diagnostic.reset(ns, 0) end,
		desc = "Hide explanations when entering insert mode"
	})
	set_explanations()
end


M.disable = function()
	local ns = api.nvim_create_namespace(augroup_name)
	vim.diagnostic.reset(ns, 0)
	-- pcall: let error (because group no longer exists) go silent
	-- on successive calls to CronExplainedDisable
	pcall(function()
		api.nvim_del_augroup_by_id(augroup)
	end)
end


M.setup = function(opts)
	M.config = require("cronex.config").parse_opts(opts)

	api.nvim_create_user_command("CronExplainedEnable",
		require("cronex").enable,
		{ desc = "Enable explanations of cron expressions" })

	api.nvim_create_user_command("CronExplainedDisable",
		require("cronex").disable,
		{ desc = "Disable explanations of cron expressions" })

	api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		pattern = M.config.file_patterns,
		callback = M.enable,
	})
end

return M
