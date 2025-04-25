M = {}


M._cache = {}

-- M.explain = function(cmd, cron_expression)
-- 	local cached = M._cache[cron_expression]
-- 	if cached then
-- 		return cached
-- 	end
-- 	local full_cmd = vim.tbl_flatten({ cmd, cron_expression })
-- 	local output = ""
-- 	local job_id = vim.fn.jobstart(
-- 		full_cmd,
-- 		{
-- 			stdout_buffered = true,
-- 			stderr_buffered = true,
-- 			on_stdout = function(_, data, _)
-- 				output = output .. table.concat(data)
-- 				M._cache[cron_expression] = output
-- 			end,
-- 			on_stderr = function(_, data, _)
-- 				vim.notify(string.format("Error: %s", vim.inspect(data)))
-- 			end,
-- 			pty = true, -- IMPORTANT, otherwise it hangs up!
-- 		})
-- 	vim.fn.jobwait({ job_id }, 2000)
-- 	return output
-- end
-- return M


-- M.explain = function(cmd, cron_expression)
-- 	local cached = M._cache[cron_expression]
-- 	if cached then
-- 		return cached
-- 	end
-- 	local output = ""
-- 	vim.system(
-- 		{ "" .. table.concat(cmd), cron_expression },
-- 		{ text = true },
-- 		function(obj)
-- 			if obj.code ~= 0 then
-- 				vim.notify(string.format("Error: %s", vim.inspect(obj.stderr)))
-- 				--TODO:: Is this a better idea to report error in newer nvim versions?
-- 				--error("Error: " .. (obj.stderr or ""))
-- 			end
--
-- 			if obj.code == 0 then
-- 				output = output .. obj.stdout
-- 				M._cache[cron_expression] = output
-- 			end
-- 		end
-- 	):wait()
--
-- 	return output
-- end
-- return M



-- M.explain = function(cmd, cron_expression)
-- 	local cached = M._cache[cron_expression]
-- 	if cached then
-- 		return cached
-- 	end
-- 	local uv = vim.loop
-- 	local stdio_pipe = uv.new_pipe()
-- 	-- local stderr = uv.new_pipe(false)
-- 	--
-- 	local opts = {
-- 		args = { cron_expression },
-- 		stdio = { nil, stdio_pipe, nil }
-- 	}
--
-- 	local handle
-- 	local on_exit = function(status)
-- 		uv.read_stop(stdio_pipe)
-- 		uv.close(stdio_pipe)
-- 		uv.close(handle)
-- 	end
-- 	cmd = "" .. table.concat(cmd)
-- 	handle = uv.spawn(cmd, opts, on_exit)
-- 	local output = ""
-- 	uv.read_start(stdio_pipe, function(status, data)
-- 		if data then
-- 			output = output .. data
-- 			M._cache[cron_expression] = output
-- 		end
-- 	end)
-- 	return output
-- end
-- return M

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
-- local raw_explanation = config.explain(cron, bufnr, lnum, config.format)


-- M.explain = function(cmd, cron_expression, bufnr, lnum, ns)
-- 	--TODO:
-- 	-- 	local cached = M._cache[cron_expression]
-- 	-- 	if cached then
-- 	-- 		return cached
-- 	-- 	end
-- 	--
-- 	--local results = {}
-- 	local function on_read(err, data)
-- 		if err then
-- 			print('ERROR: ', err)
-- 		end
-- 		if data then
-- 			vim.schedule(function()
-- 				vim.diagnostic.set(ns, bufnr, { {
-- 					bufnr = bufnr,
-- 					lnum = lnum,
-- 					col = 0,
-- 					--message = formatter(data),
-- 					message = data,
-- 					severity = vim.diagnostic.severity.HINT,
-- 				} }, {})
-- 			end)
-- 		end
-- 	end
--
-- 	local stdout = vim.loop.new_pipe(false)
-- 	local stderr = vim.loop.new_pipe(false)
--
-- 	if type(cmd) == "table" then
-- 		cmd = "" .. table.concat(cmd)
-- 	end
-- 	handle = vim.loop.spawn(cmd, {
-- 			args = { cron_expression },
-- 			stdio = { nil, stdout, stderr }
-- 		},
-- 		vim.schedule_wrap(function()
-- 			stdout:read_stop()
-- 			stderr:read_stop()
-- 			if not stderr:is_closing() then stderr:close() end
-- 			if not stdout:is_closing() then stdout:close() end
-- 			if not handle:is_closing() then handle:close() end
-- 		end
-- 		)
-- 	)
-- 	vim.loop.read_start(stdout, on_read)
-- 	vim.loop.read_start(stderr, on_read)
-- end
--
-- return M

-- M.explain = function(cmd, cron_expression, bufnr, lnum, ns, explanations)
-- 	local function onread(err, data)
-- 		if err then
-- 			print('ERROR: ', err)
-- 		end
-- 		if data then
-- 			M._cache[cron_expression] = data
-- 			table.insert(explanations, {
-- 				bufnr = bufnr,
-- 				lnum = lnum,
-- 				col = 0,
-- 				message = data,
-- 				severity = vim.diagnostic.severity.HINT,
-- 			})
-- 			vim.schedule(function()
-- 				vim.diagnostic.set(ns, bufnr, explanations, {})
-- 			end)
-- 		end
-- 	end
--
-- 	local stdout = vim.loop.new_pipe(false)
-- 	local stderr = vim.loop.new_pipe(false)
--
-- 	if type(cmd) == "table" then
-- 		cmd = table.concat(cmd)
-- 	end
--
-- 	local cached = M._cache[cron_expression]
-- 	if cached then
-- 		table.insert(explanations, {
-- 			bufnr = bufnr,
-- 			lnum = lnum,
-- 			col = 0,
-- 			message = cached,
-- 			severity = vim.diagnostic.severity.HINT,
-- 		})
-- 		vim.schedule(function()
-- 			vim.diagnostic.set(ns, bufnr, explanations, {})
-- 		end)
-- 	else
-- 		--vim.uv.spawn()
-- 		handle = vim.loop.spawn(cmd, {
-- 				args = { cron_expression },
-- 				stdio = { nil, stdout, stderr }
-- 			},
-- 			vim.schedule_wrap(function()
-- 				stdout:read_stop()
-- 				stderr:read_stop()
-- 				if not stderr:is_closing() then stderr:close() end
-- 				if not stdout:is_closing() then stdout:close() end
-- 				--if not handle:is_closing() then handle:close() end
-- 			end))
--
-- 		vim.loop.read_start(stdout, onread)
-- 		vim.loop.read_start(stderr, onread)
-- 	end
-- end
--
-- return M
--[[
        local on_exit = function(obj)
          print(obj.code)
          print(obj.signal)
          print(obj.stdout)
          print(obj.stderr)
        end

        -- Runs asynchronously:
        vim.system({'echo', 'hello'}, { text = true }, on_exit)
]]

M.explain = function(cmd, cron_expression, bufnr, lnum, ns, explanations)
	local on_exit = function(obj)
		if obj.code ~= 0 then
			print('ERROR: ', obj.stderr)
		end
		local data = obj.stdout
		if data then
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

	if type(cmd) == "table" then
		cmd = table.concat(cmd)
	end

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
		vim.schedule(function()
			vim.system({ "bash", "/home/fdamicel/projects/cronex.nvim/test.sh", cron_expression }, { text = true }, on_exit)
		end
		)
	end
end

return M
