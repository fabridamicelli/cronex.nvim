local api = vim.api
local ns = api.nvim_create_namespace("cronex")

local M = {
  enabled = false
}

local make_set_explanations = function(config)
	-- local ns = vim.api.nvim_create_namespace("cronex_explanations")

	local set_explanations = function()
		local bufnr = 0
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

		local crons = config.extract()
		for lnum, cron in pairs(crons) do
			local raw_explanation = config.explain(cron)
			local explanation = config.format(raw_explanation):gsub("\r", "") -- Remove ^M
			vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
				virt_text = {{explanation, config.highlight}},
				virt_text_pos = "eol",
				hl_mode = "combine",
			})
		end
	end

	return set_explanations
end



M.hide_explanations = function()
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
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
  M.enabled = true
end


M.disable = function()
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	-- pcall: let error (because groud no longer exists) go silent
	-- on successive calls to CronExplainedDisable
	pcall(function()
		api.nvim_del_augroup_by_id(M.augroup)
	end)
  M.enabled = false
end

M.toggle = function()
	if M.enabled then
		M.disable()
	else
		M.enable()
	end
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

	api.nvim_create_user_command("CronExplainedToggle",
		require("cronex").toggle,
		{ desc = "Toggle explanations of cron expressions" })

	api.nvim_create_autocmd("BufEnter", {
		group = M.augroup,
		pattern = M.config.file_patterns,
		callback = function()
			if M.enabled then
        M.enable()
			end
    end,
	})
end

return M
