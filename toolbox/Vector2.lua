--[[
Un vecteur (ici dans un ensemble à 2 dimensions) permet de regrouper des
coordonnées x et y et de leur appliquer en même temps une transformation.

Par exemple on peut additionner des vecteurs : (5, 3) + (2, -1) = (3, 2),
ou encore les multiplier par un facteur commun : 3*(5.2, 3.3) = (15.6, 9.9).
--]]
local Vector2 = {}
local mt = { __index = Vector2 }

function Vector2.new(x, y)
  local obj = {}
  obj.x = x or 0
  obj.y = y or 0

  return setmetatable(obj, mt)
end

function Vector2.Zero()
  return Vector2.new(0, 0)
end

function Vector2.One()
  return Vector2.new(1, 1)
end

function mt.__add(v1, v2)
  if type(v2) == "number" then
    return Vector2.new(v1.x + v2, v1.y + v2)
  elseif type(v1) == "number" then
    return Vector2.new(v1 + v2.x, v1 + v2.y)
  else
    return Vector2.new(v1.x + v2.x, v1.y + v2.y)
  end
end

function mt.__sub(v1, v2)
  if type(v2) == "number" then
    return Vector2.new(v1.x - v2, v1.y - v2)
  elseif type(v1) == "number" then
    return Vector2.new(v1 - v2.x, v1 - v2.y)
  else
    return Vector2.new(v1.x - v2.x, v1.y - v2.y)
  end
end

function mt.__mul(v1, v2)
  if type(v2) == "number" then
    return Vector2.new(v1.x*v2, v1.y*v2)
  elseif type(v1) == "number" then
    return Vector2.new(v1*v2.x, v1*v2.y)
  else
    return Vector2.new(v1.x*v2.x, v1.y*v2.y)
  end
end

function mt.__div(v1, v2)
  if type(v2) == "number" then
    return Vector2.new(v1.x/v2, v1.y/v2)
  else
    return Vector2.new(v1.x/v2.x, v1.y/v2.y)
  end
end

-- Normalise un vecteur : fait en sorte que sa norme soit égale à 1.
function Vector2:Normalize()
  local length = self:Length()
  if length == 0 then return Vector2.Zero() end

  return self/length
end

-- Norme d'un vecteur : distance entre les deux extrémités de celui-ci (Pythagore).
function Vector2:Length()
  return (self.x^2 + self.y^2)^0.5
end

-- Tourne un vecteur grâce à la matrice de rotation
function Vector2:Rotate(angle)
  return Vector2.new(
    self.x*math.cos(angle) - self.y*math.sin(angle),
    self.x*math.sin(angle) + self.y*math.cos(angle)
  )
end

function mt.__tostring(v)
  return string.format("Vector2(%.3f,%.3f)", v.x, v.y)
end

return Vector2
