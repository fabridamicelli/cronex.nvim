local api = vim.api

local M = {}
M._augroup_name = "plugin-cronex.nvim"
M.ns = api.nvim_create_namespace(M._augroup_name)
M._cmd_handles = {}

local make_set_explanations = function(config)
	local set_explanations = function()
		local bufnr = api.nvim_get_current_buf()
		vim.diagnostic.reset(M.ns, bufnr) -- Start fresh
		local crons = config.extract()
		local cmd = { "bash", "/home/fdamicel/projects/cronex-async/test.sh" }

		local explanations = {}
		for lnum, cron in pairs(crons) do
			require("cronex.explain").explain(
				cmd, cron, bufnr, lnum, M.ns, explanations, M._cmd_handles
			)
		end
	end
	return set_explanations
end

M.cancel_explanations = function()
	for _, handle in ipairs(M._cmd_handles) do
		vim.uv.kill(handle.pid, "sigterm")
		-- NOTE: this seems redundant (we could do it only once at the end of the loop)
		-- but for some reason works better (doing it only once does not fully clean the UI)
		vim.diagnostic.reset(M.ns, api.nvim_get_current_buf())
	end
	M._cmd_handles = {}
	--NOTE: same redundancy here to refresh UI
	vim.diagnostic.reset(M.ns, api.nvim_get_current_buf())
end

M.hide_explanations = function()
	vim.diagnostic.reset(M.ns, 0)
end


M.enable = function()
	local augroup = api.nvim_create_augroup(M._augroup_name, { clear = true })
	api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
		group = augroup,
		buffer = api.nvim_get_current_buf(), -- 0,
		callback = require("cronex").set_explanations,
		desc = "Set explanations when leaving insert mode or changing the text"
	})

	api.nvim_create_autocmd({ "InsertEnter" }, {
		group = augroup,
		buffer = api.nvim_get_current_buf(), -- 0,
		callback = require("cronex").hide_explanations,
		desc = "Hide explanations when entering insert mode"
	})
	require("cronex").set_explanations()
end


M.disable = function()
	vim.diagnostic.reset(M.ns, api.nvim_get_current_buf())
	-- pcall: let error (because group no longer exists) go silent
	-- on successive calls to CronExplainedDisable
	pcall(function()
		local augroup = api.nvim_create_augroup(M._augroup_name, { clear = true })
		api.nvim_del_augroup_by_id(augroup)
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

	--TODO: Remove after debugging
	api.nvim_create_user_command("CronExplainedCancel",
		require("cronex").cancel_explanations,
		{ desc = "Disable explanations of cron expressions" })

	local augroup = api.nvim_create_augroup(M._augroup_name, { clear = true })
	api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		pattern = M.config.file_patterns,
		callback = function()
			M.disable()
			M.enable()
		end,
	})
end

return M
