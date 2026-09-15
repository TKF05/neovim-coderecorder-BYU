local M = {}

function M.read_gz(path)
	local result = vim.system({ "gzip", "-cd", "--", path }, { text = false }):wait()

	if result.code ~= 0 then
		error("Failed to decompress " .. path .. ": " .. (result.stderr or ""))
	end

	return result.stdout
end

function M.read_gz_file(file)
	-- Read the compressed bytes from the already-open file.
	local compressed = file:read("*a")

	-- Decompress them through gzip.
	local result = vim.system({ "gzip", "-cd" }, {
		stdin = compressed,
		text = false,
	}):wait()

	if result.code ~= 0 then
		error("Failed to decompress gzip data: " .. (result.stderr or ""))
	end

	return result.stdout
end

function M.write_gz(path, data)
	local result = vim.system({ "gzip", "-c" }, {
		stdin = data,
		text = false,
	}):wait()

	if result.code ~= 0 then
		error("Failed to compress data: " .. (result.stderr or ""))
	end

	local file = assert(io.open(path, "wb"))
	file:write(result.stdout)
	file:close()
end

return M
