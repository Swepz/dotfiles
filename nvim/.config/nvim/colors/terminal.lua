local ghostty_dir = vim.fn.expand("~/.config/ghostty")

local function theme_path()
	for line in io.lines(ghostty_dir .. "/config.ghostty") do
		local name = line:match("^%s*theme%s*=%s*(.-)%s*$")
		if name then
			for _, dir in ipairs({ ghostty_dir .. "/themes", "/usr/share/ghostty/themes" }) do
				local path = dir .. "/" .. name
				if vim.uv.fs_stat(path) then
					return path
				end
			end
			error("terminal colorscheme: Ghostty theme '" .. name .. "' not found in " .. ghostty_dir .. "/themes or /usr/share/ghostty/themes")
		end
	end
	error("terminal colorscheme: no theme set in " .. ghostty_dir .. "/config.ghostty")
end

local function read_colors(path)
	local colors = {}
	for line in io.lines(path) do
		local index, hex = line:match("^%s*palette%s*=%s*(%d+)%s*=%s*(#%x%x%x%x%x%x)")
		if index then
			colors[tonumber(index)] = hex:lower()
		else
			local key, value = line:match("^%s*([%w-]+)%s*=%s*(#%x%x%x%x%x%x)")
			if key then
				colors[key] = value:lower()
			end
		end
	end
	local missing = {}
	for _, key in ipairs({ "background", "foreground", "selection-background", 1, 2, 3, 4, 6, 7, 9, 13, 14, 15 }) do
		if not colors[key] then
			table.insert(missing, tostring(key))
		end
	end
	if #missing > 0 then
		error("terminal colorscheme: " .. path .. " is missing " .. table.concat(missing, ", "))
	end
	return colors
end

local function blend(from, to, amount)
	local result = "#"
	for i = 2, 6, 2 do
		local a = tonumber(from:sub(i, i + 1), 16)
		local b = tonumber(to:sub(i, i + 1), 16)
		result = result .. string.format("%02x", math.floor(a + (b - a) * amount + 0.5))
	end
	return result
end

local c = read_colors(theme_path())
local bg, fg = c.background, c.foreground

vim.o.termguicolors = true
require("mini.base16").setup({
	palette = {
		base00 = bg,
		base01 = blend(bg, fg, 0.08),
		base02 = c["selection-background"],
		base03 = blend(bg, fg, 0.45),
		base04 = blend(bg, fg, 0.65),
		base05 = fg,
		base06 = c[7],
		base07 = c[15],
		base08 = c[1],
		base09 = c[9],
		base0A = c[3],
		base0B = c[2],
		base0C = c[6],
		base0D = c[4],
		base0E = c[13],
		base0F = c[14],
	},
	use_cterm = true,
})
vim.g.colors_name = "terminal"
