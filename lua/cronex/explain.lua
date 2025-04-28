M = {}


M._cache = {}


local append_explanation = function(explanations, explanation, bufnr, lnum)
	table.insert(explanations, {
		bufnr = bufnr,
		lnum = lnum,
		col = 0,
		message = explanation,
		severity = vim.diagnostic.severity.HINT,
	})
end


local schedule_explanations = function(explanations, ns, bufnr)
	vim.schedule(function()
		vim.diagnostic.set(ns, bufnr, explanations, {})
	end)
end


M.explain = function(cmd, cron_expression, bufnr, lnum, ns, explanations)
	local cached = M._cache[cron_expression]
	if cached then
		append_explanation(explanations, cached, bufnr, lnum)
		schedule_explanations(explanations, ns, bufnr)
	else
		local on_exit = function(obj)
			local data = obj.stdout
			if data ~= "" then ---TODO: add acceptance test?
				-- Update cache
				M._cache[cron_expression] = data
				append_explanation(explanations, data, bufnr, lnum)
				schedule_explanations(explanations, ns, bufnr)
			end
		end

		vim.system(
			vim.iter({ cmd, cron_expression }):flatten():totable(),
			{
				timeout = 2000, --TODO : add to config
				text = true,
				stderr = function(_, data)
					if data then
						vim.schedule(function()
							local msg = string.format(
								"Error calling cmd %s with args %s.\nStderr: \n %s", vim.inspect(cmd),
								cron_expression,
								data
							)
							vim.notify(msg)
						end)
					end
				end
			},
			on_exit
		)
	end
end

return M
