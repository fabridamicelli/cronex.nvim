local M = {}


M.all_after_colon = function(explanation)
	-- Return everything after colon like so:
	-- "* * * * *": Every minute --> Every minute
	local colon = string.find(explanation, ":")
	if colon then
		return string.sub(explanation, colon + 2)
	end
	return explanation
end

return M
