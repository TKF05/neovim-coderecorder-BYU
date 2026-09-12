-- Source for Nvim Lua documentation::
-- https://neovim.io/doc/user/lua/
local M = {}

M.recording = false

local log_file = vim.fn.getcwd() .. "/recording.jsonl"
local buffer
local buffer_state = {}

--Used for lualine integration
function M.status()
	if M.recording then
		return "● RECORDING"
	else
		return "○ NOT RECORDING"
	end
end

local function get_buffer_lines(bufnr)
	return vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
end

function M.start_recording()
	M.recording = true
	vim.cmd("redrawstatus")
	--vim.notify() posts a notification on screen temporarily
	vim.notify("● RECORDING", vim.log.levels.INFO)
	--For builtin statusline:: for lualine implementation see the lualine.lua in nvim config
	vim.o.statusline = "%f %{v:lua.MyPluginStatus()}"

	-- ALL ABOVE IS UI
	-- ALL BELOW IS FUNCTIONALITY
	buffer = assert(io.open(log_file, "a"))

	--FRAGMENT LOGGING
	local bufnr = vim.api.nvim_get_current_buf()
	buffer_state[bufnr] = get_buffer_lines(bufnr)

	vim.api.nvim_buf_attach(bufnr, false, {
		on_lines = function(_, buf, _, first_line, last_line, last_line_old)
			local old_lines = buffer_state[buf]

			local new_lines = get_buffer_lines(buf)

			-- These are the lines that existed before the edit.
			local old_fragment = vim.list_slice(old_lines, first_line + 1, last_line_old)

			-- These are the lines that exist after the edit.
			local new_fragment = vim.list_slice(new_lines, first_line + 1, last_line)

			-- Do whatever you want with these.
			--print("OLD:", vim.inspect(old_fragment))
			--print("NEW:", vim.inspect(new_fragment))
			--vim.notify(new_fragment, vim.log.levels.INFO)
			buffer:write(vim.json.encode({ newFragment = new_fragment, old_fragment = old_fragment }), "\n")

			-- The current buffer becomes the snapshot for
			-- the next edit.
			buffer_state[buf] = new_lines
		end,

		on_detach = function(_, buf)
			buffer_state[buf] = nil
		end,
	})

	--See the nvim documentation for .on_key() definition
	-- win (boolean) = vim.api.nvim_get_current_win()

	--{ "WinEnter", "WinLeave" }
	vim.api.nvim_create_autocmd({ "FocusLost" }, {
		callback = function()
			vim.notify("Window Unfocused!")
			--buffer:write(vim.json.encode({ type = "Focus Change", focused = false }), "\n")
		end,
	})

	--{ "WinEnter", "WinLeave" }
	vim.api.nvim_create_autocmd({ "FocusGained" }, {
		callback = function()
			vim.notify("Window Focused!")
			--buffer:write(vim.json.encode({ type = "Focus Change", focused = true }), "\n")
		end,
	})

	vim.on_key(function(key, typed)
		if not buffer then
			return
		end

		--only record keypresses in insert mode
		if vim.api.nvim_get_mode().mode ~= "i" then
			return
		end

		--buffer:write(vim.json.encode({ timestamp = vim.uv.hrtime(), key = key, typed = typed }), "\n")
		--buffer:write(vim.json.encode({ timestamp = os.date("%Y-%m-%d %H:%M:%S"), key = key, typed = typed }), "\n")

		--buffer:flush()
	end)
end

function M.stop_recording()
	M.recording = false
	vim.cmd("redrawstatus")
	vim.notify("○ NOT RECORDING", vim.log.levels.INFO)
	-- vim.o initiates vimscript:: vim.o.statusline == :statusline
	-- %f  is the vimscript for current file name
	vim.o.statusline = "%f %{v:lua.MyPluginStatus()}"

	--ALL BELOLW IS FUNCTIONALITY
	if buffer then
		buffer:close()
		buffer = nil
	end
end

function M.setup(opts)
	opts = opts or {}

	vim.api.nvim_create_user_command("StartRecording", M.start_recording, {})

	vim.api.nvim_create_user_command("StopRecording", M.stop_recording, {})

	_G.MyPluginStatus = M.status
end

return M
