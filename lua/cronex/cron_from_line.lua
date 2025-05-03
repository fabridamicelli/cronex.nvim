--[[
NOTE:
Here's the logic extract cron expression from each line using regex + simple parsing.
]]

local M = {}


--Define s to match cronexp in a line. One of three possible lengths (7,6,5)
local first = '[\'"]%s?[%d%-%/%*,]+%s' -- Should we allow letters here too?
local part = '[%a%d%-%/%*,%?#]+%s'
local last = '[%a%d%-%/%*,%?#]+%s?[\'"]'
local nparts2pat = {
    [7] = first .. part .. part .. part .. part .. part .. last,
    [6] = first .. part .. part .. part .. part .. last,
    [5] = first .. part .. part .. part .. last,
}

local get_cron_for_pat = function(line, pat)
	-- Only allow 1 expression per line
	local n_quotes = 0
	for _ in string.gmatch(line, '[\'"]') do
		n_quotes = n_quotes + 1
	end
	if n_quotes > 2 then
		return nil
	end

	-- Build match and count as we go
	local match = ""
	local n_matches = 0
	for m in string.gmatch(line, pat) do
		n_matches = n_matches + 1
		match = match .. m
	end
	if match == "" or n_matches > 1 then
		return nil
	end

	-- Remove " and '
	local clean = ""
	for i = 1, #match do
		local c = string.sub(match, i, i)
		if c ~= "\'" and c ~= "\"" then
			clean = clean .. c
		end
	end

	-- Strip white space at beginning and end
	if string.sub(clean, 1, 1) == " " then
		clean = string.sub(clean, 2)
	end
	if string.sub(clean, -1, -1) == " " then
		clean = string.sub(clean, 0, -2)
	end

	return clean
end

M.cron_from_line = function(line)
	for n = 7, 5, -1 do
		local pat = nparts2pat[n]
		local match = get_cron_for_pat(line, pat)
		if match then
			return match
		end
	end
	return nil
end

-- Patterns for standard crontab format (no quotes)
local crontab_patterns = {
	-- Standard 5-part cron expression (minute hour day month weekday)
	"^%s*([%d%*%-%/,]+)%s+([%d%*%-%/,]+)%s+([%d%*%-%/,]+)%s+([%d%*%-%/,]+)%s+([%d%*%-%/,]+)%s",
	-- Special time strings like @daily, @hourly, etc.
	"^%s*(@%w+)%s",
}

-- Extract cron expression from crontab format without quotes
M.cron_from_line_crontab = function(line)
	-- Skip comments and empty lines
	if line:match("^%s*#") or line:match("^%s*$") then
		return nil
	end

	-- First try the standard method in case it has quotes
	local quoted_match = M.cron_from_line(line)
	if quoted_match then
		return quoted_match
	end

	-- Check for cron with 6 parts (some implementations add seconds)
	local six_part_pattern =
		"^%s*([%d%*%-%/,]+)%s+([%d%*%-%/,]+)%s+([%d%*%-%/,]+)%s+([%d%*%-%/,]+)%s+([%d%*%-%/,]+)%s+([%d%*%-%/,]+)%s"
	local sec, min_six, hour_six, day_six, month_six, weekday_six = line:match(six_part_pattern)
	if sec and min_six and hour_six and day_six and month_six and weekday_six then
		-- For 6-part cron, return only the standard 5 parts (ignore seconds)
		return min_six .. " " .. hour_six .. " " .. day_six .. " " .. month_six .. " " .. weekday_six
	end

	-- Check for standard 5-part cron expression
	local min, hour, day, month, weekday = line:match(crontab_patterns[1])
	if min and hour and day and month and weekday then
		return min .. " " .. hour .. " " .. day .. " " .. month .. " " .. weekday
	end

	-- Check for special time strings
	local special = line:match(crontab_patterns[2])
	if special then
		return special
	end

	return nil
end

return M
