# BYU CS Code-Recorder Plugin for Neovim

Records code changes as students work, without recording their screen. Every edit to source file is written to {basename}.recording.jsonl beside the file, in the schema shared with the VS Code and JetBrains recorders and read by recan.


# Installation

For usage with Lazyvim:
```lua
return {
	dir = "*path to plugin",
	config = function()
		require("coderecordernvim").setup({
			--opts
		})
	end,
}

```lua

For usage with LuaLine:
```lua

return {
	"nvim-lualine/lualine.nvim",

	opts = function(_, opts)
		table.insert(opts.sections.lualine_c, {
			require("coderecordernvim").status,

			color = function()
				if require("coderecordernvim").recording then
					return {
						fg = "#ffffff",
						bg = "#ff0000",
					}
				else
					return {
						fg = "#ffffff",
						bg = "#00aa00",
					}
				end
			end,
		})
	end,
}
```

