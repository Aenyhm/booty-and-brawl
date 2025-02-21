local FontManager = {}

local fontFiles = {
  MAIN = "MPLUSCodeLatin.ttf",
  END = "Pricedown.otf",
}

local fonts = {
  MAIN = {},
  END = {}
}

function FontManager.Get(type, size)
  local font = fonts[type][size]
  if font == nil then
    print(string.format("[FontManager] Create font: %s %u", fontFiles[type], size))
    local filePath = string.format("assets/fonts/%s", fontFiles[type])
    font = love.graphics.newFont(filePath, size, "none", 4)
    fonts[type][size] = font
  end

  return font
end

return FontManager
