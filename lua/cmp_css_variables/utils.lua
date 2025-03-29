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

		for index, line in ipairs(content or {}) do
			-- More flexible pattern matching for CSS variables
			-- Matches various formats:
			-- --variable: value;
			-- --variable : value;
			-- --variable:value;
			-- --variable-name: value;
			-- Also handles spaces and tabs
			local name, value = line:match("^%s*%-%-([%w%-_]+)%s*:%s*([^;]+);")

			if name and not used[name] then
				-- Look for comments in different formats
				local comment
				if index > 1 then
					local lineBefore = content[index - 1]
					-- Match both single-line and multi-line comment formats
					comment = lineBefore:match("%s*/%*%s*(.-)%s*%*/") -- Multi-line comment
						or lineBefore:match("%s*//(.-)%s*$") -- Single-line comment
				end

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
