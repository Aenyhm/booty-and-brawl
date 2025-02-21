local Vector2 = require "toolbox.Vector2"

local Math = {}

Math.TAU = math.pi*2
Math.EPSILON = 0.01 -- Valeur en dessous de laquelle on considère que c'est comme 0.

function Math.Sign(n)
  local result = 0
  if n > 0 then
    result = 1
  elseif n < 0 then
    result = -1
  end

  return result
end

function Math.Clamp(n, min, max)
  local result = n

  if n < min then
    result = min
  elseif n > max then
    result = max
  end

  return result
end

function Math.NormalizeValue(value, min, max)
  return (value - min)/(max - min)
end

-- Retourne la distance entre 2 vecteurs.
function Math.Dist(v1, v2)
  return ((v2.x - v1.x)^2 + (v2.y - v1.y)^2)^0.5
end


-- [Angles] --

-- Retourne un vecteur unitaire à partir d'un angle.
function Math.AngleFromVector(v)
  return math.atan2(v.y, v.x)
end

function Math.VectorFromAngle(angle)
  return Vector2.new(math.cos(angle), math.sin(angle))
end

-- Retourne un angle entre −𝜋 et +𝜋.
-- Utile pour savoir de quel côté tourner.
function Math.NormalizeAngle(angle)
  return (
    (angle + math.pi) -- décale l'intervalle de [−𝜋,𝜋] vers [0,τ]
    % (Math.TAU)      -- remet l'angle dans cet intervalle
    - math.pi         -- le ramène à [−𝜋,𝜋]
  )
end

function Math.AngleDiff(position1, angle1, position2)
  local angle2 = Math.AngleFromVector(position2 - position1)
  local angleDiff = angle2 - angle1

  return Math.NormalizeAngle(angleDiff)
end


-- [Collisions] --

-- Vérifie la collision entre 2 cercles.
function Math.CircleIntersect(center1, radius1, center2, radius2)
  local distance = Math.Dist(center1, center2)

  return math.abs(radius1 - radius2) <= distance and distance <= radius1 + radius2
end

-- Vérifie la collision entre 2 rectangles (récupéré de Raylib).
function Math.CheckCollisionRecs(rec1, rec2)
  return (
    (rec1.position.x < (rec2.position.x + rec2.size.x) and
    (rec1.position.x + rec1.size.x) > rec2.position.x) and
    (rec1.position.y < (rec2.position.y + rec2.size.y) and
    (rec1.position.y + rec1.size.y) > rec2.position.y)
  )
end

-- Vérifie la collision entre 1 cercle et 1 rectangle (récupéré de Raylib).
function Math.CheckCollisionCircleRec(center, radius, rec)
  local recCenter = rec.position + rec.size/2

  local dx = math.abs(center.x - recCenter.x)
  local dy = math.abs(center.y - recCenter.y)

  if dx > (rec.size.x/2 + radius) then return false end
  if dy > (rec.size.y/2 + radius) then return false end

  if dx <= (rec.size.x/2) then return true end
  if dy <= (rec.size.y/2) then return true end

  local cornerDistanceSq = (dx - rec.size.x/2)^2 + (dy - rec.size.y/2)^2

  return cornerDistanceSq <= radius^2
end


-- [Easings] --
-- cf. https://easings.net/

function Math.EaseOutQuart(n)
  return 1 - (1 - n)^4;
end

return Math
