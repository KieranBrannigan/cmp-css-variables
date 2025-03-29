local M = {}
local cmp = require("cmp")

function M.split_path(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end

	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

function M.join_paths(absolute, relative)
	local path = absolute
	for _, dir in ipairs(M.split_path(relative, "/")) do
		if dir == ".." then
			path = absolute:gsub("(.*)/.*", "%1")
		end
	end
	return path .. "/" .. relative:gsub("^(%./|%.%./)", "")
end

function M.get_css_variables(files)
	local variables = {}
	local used = {}

	vim.print(type(files))

	for _, file in ipairs(files) do
		local content = vim.fn.readfile(M.join_paths(vim.fn.getcwd(), file))
		if not content then
			goto continue
		end

		-- Join lines that end with backslash
		local processed_lines = {}
		local current_line = ""

		for _, line in ipairs(content) do
			line = line:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
			if line:match("\\%s*$") then
				current_line = current_line .. line:gsub("\\%s*$", "")
			else
				current_line = current_line .. line
				if current_line ~= "" then
					table.insert(processed_lines, current_line)
				end
				current_line = ""
			end
		end

		-- Process each logical line
		for index, line in ipairs(processed_lines) do
			-- Look for comments in different formats
			local comment
			if index > 1 then
				local lineBefore = processed_lines[index - 1]
				comment = lineBefore:match("%s*/%*%s*(.-)%s*%*/") -- Multi-line comment
					or lineBefore:match("%s*//(.-)%s*$") -- Single-line comment
			end

			-- Split line by semicolons, but respect strings
			local pos = 1
			local len = #line
			local in_string = false
			local string_char = nil
			local block_start = 1

			while pos <= len do
				local char = line:sub(pos, pos)

				if char == '"' or char == "'" then
					if not in_string then
						in_string = true
						string_char = char
					elseif string_char == char and line:sub(pos - 1, pos - 1) ~= "\\" then
						in_string = false
					end
				elseif char == ";" and not in_string then
					local block = line:sub(block_start, pos - 1)
					local name, value = block:match("%s*%-%-([%w%-_]+)%s*:%s*([^;]+)")

					if name and not used[name] then
						-- Trim whitespace from value
						value = value:match("^%s*(.-)%s*$")

						local var_info = {
							label = "--" .. name,
							insertText = "var(--" .. name .. ")",
							kind = cmp.lsp.CompletionItemKind.Variable,
							documentation = comment and value .. "\n\n" .. comment or value,
						}

						table.insert(variables, var_info)
						used[name] = true
					end

					block_start = pos + 1
				end
				pos = pos + 1
			end
		end

		::continue::
	end

	return variables
end

-- function M.find_files(path)
-- 	local Job, exists = pcall(require, "plenary.job")
-- 	if not exists then
-- 		vim.notify(
-- 			"[cmp-css-variables]: Plenary is required as a dependency.",
-- 			vim.log.levels.ERROR,
-- 			{ title = "cmp-css-variables" }
-- 		)
-- 		return
-- 	end
-- 	local stdout = Job:new({
-- 		command = "find",
-- 		args = { ".", "-type", "d", "-name", "node_modules", "-prune", "-o", "-name", path, "-print" },
-- 	}):sync()
-- 	return stdout
-- end

return M
