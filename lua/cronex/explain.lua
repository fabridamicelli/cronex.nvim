M = {}


M._cache = {}

--TODO:set only changed diagnostics
--TODO: set_explanations func

M.explain = function(cmd, cron_expression, bufnr, lnum, ns, explanations)
	local cached = M._cache[cron_expression]
	if cached then
		table.insert(explanations, {
			bufnr = bufnr,
			lnum = lnum,
			col = 0,
			message = cached,
			severity = vim.diagnostic.severity.HINT,
		})
		vim.schedule(function()
			vim.diagnostic.set(ns, bufnr, explanations, {})
		end)
	else
		local on_exit = function(obj)
			if obj.code ~= 0 then
				print('ERROR: ', obj.stderr) --TODO: notify?, err?
			end
			local data = obj.stdout
			if data ~= "" then ---TODO: check this works
				-- Update cache
				M._cache[cron_expression] = data
				table.insert(explanations, {
					bufnr = bufnr,
					lnum = lnum,
					col = 0,
					message = data,
					severity = vim.diagnostic.severity.HINT,
				})
				vim.schedule(function()
					vim.diagnostic.set(ns, bufnr, explanations, {})
				end)
			end
		end

		vim.system(
			vim.iter({ cmd, cron_expression }):flatten():totable(),
			{ text = true },
			on_exit
		)
	end
end

return M
