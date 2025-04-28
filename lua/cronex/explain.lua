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


M.explain = function(cmd, cron_expression, format, bufnr, lnum, ns, explanations)
	local cached = M._cache[cron_expression]
	if cached then
		append_explanation(explanations, format(cached), bufnr, lnum)
		schedule_explanations(explanations, ns, bufnr)
	else
		local on_exit = function(obj)
			if obj.signal == 15 and obj.code == 124 then --TODO: acceptance test?
				vim.schedule(function()
					vim.notify(string.format(
						"CronExplained Timeout with cmd %s and args %s", vim.inspect(cmd), cron_expression
					))
				end)
			end

			local data = obj.stdout
			if data ~= "" then ---TODO: add acceptance test?
				-- Update cache
				M._cache[cron_expression] = data
				append_explanation(explanations, format(data), bufnr, lnum)
				schedule_explanations(explanations, ns, bufnr)
			end
		end

		vim.system(
			vim.iter({ cmd, cron_expression }):flatten():totable(),
			{
				timeout = 10000, --TODO : add to config
				text = true,
				stderr = function(_, data)
					if data then
						vim.schedule(function()
							vim.notify(string.format(
								"Error calling cmd %s with args %s.\nStderr: \n %s", vim.inspect(cmd),
								cron_expression,
								data
							))
						end)
					end
				end
			},
			on_exit
		)
	end
end

return M
