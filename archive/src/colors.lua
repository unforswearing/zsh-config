local colors = require("libcolors.lua")

local selected_color = arg[1]
local text = arg[2]

print(colors[selected_color](text))
