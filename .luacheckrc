---@diagnostic disable: lowercase-global
std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	"**/Libs",
}
not_globals = {
	"arg", -- arg is a standard global, so without this it won't error when we typo "args" in a module
}
