M = {}


M._cache = {}

M.explain = function(cmd, cron_expression)
	local cached = M._cache[cron_expression]
	if cached then
		return cached
	end
	local full_cmd = vim.tbl_flatten({ cmd, cron_expression })
	local output = ""
	local job_id = vim.fn.jobstart(
		full_cmd,
		{
			stdout_buffered = true,
			stderr_buffered = true,
			on_stdout = function(_, data, _)
				output = output .. table.concat(data)
				M._cache[cron_expression] = output
			end,
			on_stderr = function(_, data, _)
				vim.notify(string.format("Error: %s", vim.inspect(data)))
			end,
			pty = true, -- IMPORTANT, otherwise it hangs up!
		})
	vim.fn.jobwait({ job_id }, 2000)

	return output
end

return M
