--[[
NOTE:
Here's the logic extract cron expression from each line using regex + simple parsing.
]]

local M = {}

--Define s to match cronexp in a line. One of three possible lengths (7,6,5)
local first = "['\"]%s?[%d%-%/%*,]+%s" -- Should we allow letters here too?
local part = "[%a%d%-%/%*,%?#]+%s"
local last = "[%a%d%-%/%*,%?#]+%s?['\"]"
local nparts2pat = {
    [7] = first .. part .. part .. part .. part .. part .. last,
    [6] = first .. part .. part .. part .. part .. last,
    [5] = first .. part .. part .. part .. last,
}

local get_cron_for_pat = function(line, pat)
    -- Only allow 1 expression per line
    local n_quotes = 0
    for _ in string.gmatch(line, "['\"]") do
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
        if c ~= "'" and c ~= '"' then
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

-- Helper function to convert a string to a case-insensitive pattern
local function ci(str)
    local result = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        result = result .. "[" .. c:upper() .. c:lower() .. "]"
    end
    return result
end

local function make_patterns(names)
    local patterns = {}
    for _, name in pairs(names) do
        table.insert(patterns, "^" .. ci(name) .. "$")
    end
    return patterns
end

-- Patterns for field validation
local month_names_patterns = make_patterns({
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
})

local weekday_names_patterns = make_patterns({
    "SUN",
    "MON",
    "TUE",
    "WED",
    "THU",
    "FRI",
    "SAT",
})

-- Special time strings like @daily, @hourly, etc.
local special_pattern = "^%s*(@%w+)%s"

-- Parse and extract cron expressions from standard crontab format
-- According to crontab(5) spec:
-- - Supports standard 5-part and 6-part (with seconds) cron expressions
-- - Handles three-letter month and day names (case-insensitive)
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

    -- Check for special time strings
    local special = line:match(special_pattern)
    if special then
        return special
    end

    -- Split line by whitespace to get parts
    local parts = {}
    for part in line:gmatch("%S+") do
        table.insert(parts, part)
    end

    -- Need at least 5 parts for a valid cron expression
    if #parts < 5 then
        return nil
    end

    -- Pattern for standard cron fields (numeric, *, -, /, ,)
    local is_standard_part = function(part)
        return part:match("^[%d%*%-%/,]+$") ~= nil
    end

    -- Check if a part matches a name in the provided list of patterns
    local is_valid_name = function(part, patterns)
        -- As per crontab(5): "Ranges or lists of names are not allowed"
        if part:match("[-,]") then
            return false
        end

        for _, pattern in ipairs(patterns) do
            if part:match(pattern) then
                return true
            end
        end
        return false
    end

    -- Function to check if a part matches the expected format for its position
    local is_valid_part = function(part, pos)
        -- Minutes, hours, day of month - must be numeric format
        if pos <= 3 then
            return is_standard_part(part)
        -- Month - can be numeric or month name
        elseif pos == 4 then
            return is_standard_part(part) or is_valid_name(part, month_names_patterns)
        -- Day of week - can be numeric or weekday name
        elseif pos == 5 then
            return is_standard_part(part) or is_valid_name(part, weekday_names_patterns)
        end
        return false
    end

    -- Format for returning matched parts
    local format_parts = function(offset, count)
        local result = parts[offset]
        for i = 1, count - 1 do
            result = result .. " " .. parts[offset + i]
        end
        return result
    end

    -- Check for 6-part cron format (with seconds)
    if #parts >= 6 then
        local valid = true
        valid = valid and is_standard_part(parts[1]) -- seconds

        -- Validate remaining 5 standard parts
        for i = 1, 5 do
            valid = valid and is_valid_part(parts[i + 1], i)
        end

        if valid then
            -- Return standard 5-part format, skipping seconds
            return format_parts(2, 5)
        end
    end

    -- Check for 5-part cron format
    local valid = true
    for i = 1, 5 do
        valid = valid and is_valid_part(parts[i], i)
    end

    if valid then
        return format_parts(1, 5)
    end

    return nil
end

return M
