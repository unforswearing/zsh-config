local colors = require("ansicolors")


local M = {}

local function red(text)
   print(colors("%{red}" .. text))
end
M.red = red

local function yellow(text)
   print(colors("%{yellow}" .. text))
end
M.yellow = yellow

local function green(text)
   print(colors("%{green}" .. text))
end
M.green = green

local function blue(text)
   print(colors("%{blue}" .. text))
end
M.blue = blue

return M
