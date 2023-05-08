local colors = require("ansicolors")
-- colors = require("colors")
-- colors.red("hi")

local M = {}

local function red(text: string): string
  print(colors("%{red}" .. text))
end
M.red = red

local function yellow(text: string): string
  print(colors("%{yellow}" .. text))
end
M.yellow = yellow

local function green(text: string): string
  print(colors("%{green}" .. text))
end
M.green = green

local function blue(text: string): string
  print(colors("%{blue}" .. text))
end
M.blue = blue

return M