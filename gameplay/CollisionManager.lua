local Math = require "toolbox.Math"

local EntityManager = require "gameplay.EntityManager"

local Window = require "Window"

local CollisionManager = {}

-- /!\ Doit être >= EnemyManager.OBSTACLE_DIST_FACTOR pour ne pas louper des collisions à vérifier.
local MAX_DIST_COLLISION = 3

function CollisionManager.GetComputedHitboxCircles(e, center)
  local result = {}
  local renderCenter = center*Window.TILE_SIDE

  for _, hitbox in ipairs(e.hitboxAreas) do
    local computedHitbox = {
      center = renderCenter + hitbox.offset:Rotate(e.transform.angle),
      radius = hitbox.radius
    }
    table.insert(result, computedHitbox)
  end

  return result
end

function CollisionManager.GetComputedHitboxRectangle(e, center)
  local renderPosition = center*Window.TILE_SIDE - e.sprite.size/2

  return {
    position = renderPosition + e.hitboxRectangle.position,
    size = e.hitboxRectangle.size
  }
end

function CollisionManager.GetCollidedEntity(e, center)
  for _, other in ipairs(EntityManager.GetAll()) do
    if Math.Dist(e.transform.position, other.transform.position) > MAX_DIST_COLLISION then
      goto continue
    end

    if (other.hitboxRectangle or other.hitboxAreas) and e.id ~= other.id then
      if e.hitboxRectangle and other.hitboxRectangle then
        local computedHitboxRec1 = CollisionManager.GetComputedHitboxRectangle(e, center)
        local computedHitboxRec2 = CollisionManager.GetComputedHitboxRectangle(other, other.transform.position)

        if Math.CheckCollisionRecs(computedHitboxRec1, computedHitboxRec2) then
          return other
        end
      elseif e.hitboxRectangle and other.hitboxAreas then
        local computedHitboxRec1 = CollisionManager.GetComputedHitboxRectangle(e, center)
        local computedHitboxCircles2 = CollisionManager.GetComputedHitboxCircles(other, other.transform.position)

        for _, hitboxCircle2 in ipairs(computedHitboxCircles2) do
          if Math.CheckCollisionCircleRec(hitboxCircle2.center, hitboxCircle2.radius, computedHitboxRec1) then
            return other
          end
        end
      elseif e.hitboxAreas and other.hitboxRectangle then
        local computedHitboxCircles1 = CollisionManager.GetComputedHitboxCircles(e, center)
        local computedHitboxRec2 = CollisionManager.GetComputedHitboxRectangle(other, other.transform.position)

        for _, hitboxCircle1 in ipairs(computedHitboxCircles1) do
          if Math.CheckCollisionCircleRec(hitboxCircle1.center, hitboxCircle1.radius, computedHitboxRec2) then
            return other
          end
        end
      else
        local computedHitboxCircles1 = CollisionManager.GetComputedHitboxCircles(e, center)
        local computedHitboxCircles2 = CollisionManager.GetComputedHitboxCircles(other, other.transform.position)

        for _, hitboxCircle1 in ipairs(computedHitboxCircles1) do
          for _, hitboxCircle2 in ipairs(computedHitboxCircles2) do
            if Math.CircleIntersect(
              hitboxCircle1.center, hitboxCircle1.radius,
              hitboxCircle2.center, hitboxCircle2.radius
            ) then
              return other
            end
          end
        end
      end
    end

    ::continue::
  end

  return nil
end

return CollisionManager
