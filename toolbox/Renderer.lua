--[[
Ce module a pour intérêt de simplifier les dessins à l'écran.

- On lui passe des vecteurs au lieu de x, y, width et height.
- On ne s'embête pas à savoir quelle couleur on a mis en
  dernier car on la précise à chaque fois (sinon c'est blanc).
- On peut passer les couleurs sous forme de tableau ou d'entier.
  Par exemple: { 0.02, 0.66, 0.85, 0.61 } ou 0x05a8da9b
  L'alpha est optionnel (1 par défaut)
--]]
local Color = require "toolbox.Color"

local Renderer = {}

local COLOR_WHITE = Color.new(1, 1, 1, 1)

local function setColor(color)
  color = color or COLOR_WHITE
  color[4] = color[4] or 1

  love.graphics.setColor(color[1], color[2], color[3], color[4])
end

function Renderer.DrawRectangle(position, size, color, mode)
  setColor(color)
  love.graphics.rectangle(mode or "fill", position.x, position.y, size.x, size.y)
end

function Renderer.DrawCircle(center, radius, color, mode)
  setColor(color)
  love.graphics.circle(mode or "fill", center.x, center.y, radius)
end

function Renderer.DrawLine(position, size, color)
  setColor(color)
  love.graphics.line(position.x, position.y, size.x, size.y)
end

function Renderer.DrawText(font, text, position, color)
  setColor(color)
  love.graphics.setFont(font)
  love.graphics.print(text, position.x, position.y)
end

function Renderer.DrawTexture(image, quad, position, origin, angle, color, scale)
  angle = angle or 0
  setColor(color)
  scale = scale or 1

  local transform = love.math.newTransform(
    position.x,
    position.y,
    angle,
    scale,
    scale,
    origin.x,
    origin.y
  )

  if quad then
    love.graphics.draw(image, quad, transform)
  else
    love.graphics.draw(image, transform)
  end
end

return Renderer
