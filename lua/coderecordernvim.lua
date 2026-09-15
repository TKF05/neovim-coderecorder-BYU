local version = require("version")
local M = {}

M.recording = false
M.filename = ""
M.cwd = ""

function M.status()
	if M.recording then
		return "● RECORDING"
	else
		return "○ NOT RECORDING"
	end
end

function statusEvent(status)
	local data = {
		type = "focusStatus",
		editor = "neovim",
		recorderVersion = version,
		timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		document = M.cwd,
		focused = status,
	}
	file:write(vim.json.encode(data), "\n")
end

function editEvent()
	local bufnr = vim.api.nvim_get_current_buf()
	local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

	vim.api.nvim_buf_attach(bufnr, false, {
		on_bytes = function(
			_,
			bufnr,
			changedtick,
			start_row,
			start_col,
			start_byte,
			old_end_row,
			old_end_col,
			old_end_byte,
			new_end_row,
			new_end_col,
			new_end_byte
		)
			------------------------------------------------------------------------
			-- Calculate Offset of the edit
			------------------------------------------------------------------------
			local lines = vim.api.nvim_buf_get_lines(bufnr, 0, start_row, true)
			local offset = 0
			for _, line in ipairs(lines) do
				offset = offset + vim.fn.strchars(line) + 1
			end
			offset = offset + start_col

			------------------------------------------------------------------------
			-- Find the new Fragment
			------------------------------------------------------------------------
			local new_end_row_abs = start_row + new_end_row
			local new_end_col_abs = start_col + new_end_col

			local line_count = vim.api.nvim_buf_line_count(bufnr)

			new_end_row_abs = math.min(new_end_row_abs, line_count - 1)

			local new_fragment =
				vim.api.nvim_buf_get_text(bufnr, start_row, start_col, new_end_row_abs, new_end_col_abs, {})

			new_fragment = table.concat(new_fragment, "\n")

			------------------------------------------------------------------------
			-- Calculate absolute old end
			------------------------------------------------------------------------

			local old_end_row_abs = start_row + old_end_row

			local old_end_col_abs
			if old_end_row == 0 then
				old_end_col_abs = start_col + old_end_col
			else
				old_end_col_abs = old_end_col
			end

			------------------------------------------------------------------------
			-- Get old fragment from our previous buffer snapshot
			------------------------------------------------------------------------

			local old_fragment

			if old_end_row == 0 then
				-- Change happened entirely on one line
				local line = old_lines[start_row + 1] or ""

				old_fragment = line:sub(start_col + 1, old_end_col_abs)
			else
				-- First line
				old_fragment = {}

				local first_line = old_lines[start_row + 1] or ""

				table.insert(old_fragment, first_line:sub(start_col + 1))

				-- Middle lines
				for row = start_row + 1, old_end_row_abs - 1 do
					table.insert(old_fragment, old_lines[row + 1] or "")
				end

				-- Last line
				local last_line = old_lines[old_end_row_abs + 1] or ""

				table.insert(old_fragment, last_line:sub(1, old_end_col))

				old_fragment = table.concat(old_fragment, "\n")
			end

			------------------------------------------------------------------------
			-- write to the file
			------------------------------------------------------------------------

			local data = {
				type = "edit",
				editor = "neovim",
				recorderVersion = version,
				timestamp = os.date("%Y-%m-%d %H:%M:%S"),
				document = M.cwd,
				offset = offset,
				oldFragment = old_fragment,
				newFragment = new_fragment,
			}

			file:write(vim.json.encode(data), "\n")

			file:flush()

			old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
		end,
	})
end

function snapShot(file)
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

	fragments = table.concat(lines, "\n")
	local data = {
		type = "edit",
		editor = "neovim",
		recorderVersion = version,
		timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		document = M.cwd,
		offset = 0,
		oldFragment = fragments,
		newFragment = fragments,
	}
	file:write(vim.json.encode(data), "\n")

	file:flush()
end

function M.start_recording()
	M.recording = true
	M.filename = vim.fn.expand("%:t")
	M.cwd = (vim.fn.getcwd() .. "/" .. M.filename)
	vim.notify(M.cwd)

	vim.cmd("redrawstatus")
	vim.notify("● RECORDING", vim.log.levels.INFO)
	--For builtin statusline:: for lualine implementation see the lualine.lua in nvim config
	vim.o.statusline = "%f %{v:lua.MyPluginStatus()}"

	outputFileName = (M.filename:gsub("%.[^%.]+$", "") .. ".recording.jsonl")
	file = assert(io.open(outputFileName, "w"))

	snapShot(file)

	------------------------------------------------------------------------
	-- Focus Events Fucntionality
	------------------------------------------------------------------------

	vim.api.nvim_create_autocmd({ "FocusLost" }, {
		callback = function()
			statusEvent(false)
		end,
	})

	vim.api.nvim_create_autocmd({ "FocusGained" }, {
		callback = function()
			statusEvent(true)
		end,
	})

	------------------------------------------------------------------------------
	-- Edit Events functionality
	------------------------------------------------------------------------------
	editEvent()
end

function M.stop_recording()
	M.recording = false
	vim.cmd("redrawstatus")
	vim.notify("○ NOT RECORDING", vim.log.levels.INFO)
	vim.o.statusline = "%f %{v:lua.MyPluginStatus()}"
end

function M.setup(opts)
	opts = opts or {}
	vim.api.nvim_create_user_command("Rn", M.start_recording, {})
	vim.api.nvim_create_user_command("StartRecording", M.start_recording, {})
	vim.api.nvim_create_user_command("StopRecording", M.stop_recording, {})
	_G.MyPluginStatus = M.status
end

return M
