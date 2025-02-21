local Renderer = require "toolbox.Renderer"

local Window = require "Window"

local Entity = {}
local mt = { __index = Entity }

function Entity.new(id, sprite, transform)
  local obj = {}
  obj.id = id
  obj.sprite = sprite
  obj.transform = transform
  obj.color = { 1, 1, 1, 1 }

  return setmetatable(obj, mt)
end

function mt.__tostring(e)
  return string.format("Entity #%u", e.id)
end

function Entity:Draw()
  local renderPosition = self.transform.position*Window.TILE_SIDE
  local origin = self.sprite.size/2
  local rotation = self.transform.angle - self.sprite.orientation

  Renderer.DrawTexture(
    self.sprite.image,
    self.sprite.quad,
    renderPosition,
    origin,
    rotation,
    self.color
  )
end

return Entity
