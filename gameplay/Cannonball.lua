local Math = require "toolbox.Math"
local Services = require "toolbox.Services"
local Vector2 = require "toolbox.Vector2"

local CollisionManager = require "gameplay.CollisionManager"
local Components = require "gameplay.Components"
local EntityManager = require "gameplay.EntityManager"
local Health = require "gameplay.Health"

local Cannonball = {}

local IMAGE = love.graphics.newImage("assets/images/cannonball.png")
local SPEED = 4.2
local HITBOX_AREAS = {{ offset = Vector2.Zero(), radius = IMAGE:getWidth()/2 }}
local DAMAGE_POINTS = 1
local FRICTION_FACTOR = 0.9

-- Durée avant de tomber dans l'eau (en secondes)
-- FIXME: doublon avec Boat::CANNONBALL_MAX_DISTANCE
local MAX_DISTANCE = 3

function Cannonball.Create(fromCannon)
  local direction = Math.VectorFromAngle(fromCannon.transform.angle)
  local position = fromCannon.transform.position + direction*0.1 -- On part au bout du canon

  local sprite = Components.Sprite(IMAGE)
  local transform = Components.Transform(position)
  local e = EntityManager.Create(sprite, transform)

  e.type = EntityManager.Type.CANNONBALL
  e.fromCannon = fromCannon
  e.velocity = direction*SPEED
  e.distanceTraveled = 0.0
  e.damagePoints = DAMAGE_POINTS
  e.hitboxAreas = HITBOX_AREAS

  return e
end

local function checkCollisions(e)
  local collidedEntity = CollisionManager.GetCollidedEntity(e, e.transform.position)
  if collidedEntity and collidedEntity.id ~= e.fromCannon.parent.id then
    if collidedEntity.type == EntityManager.Type.BOAT then
      Services.Get("AUDIO").GetSound("BOAT_HIT"):play()
    end
    Health.Hurt(collidedEntity, e.damagePoints)
    e.destroy = true
  end
end

function Cannonball.Update(e, dt)
  if e.distanceTraveled >= MAX_DISTANCE then
    Services.Get("AUDIO").GetSound("CANNONBALL_SINK"):play()
    e.destroy = true
    return
  end

  -- On applique une friction pour ralentir doucement.
  local frictionForce = e.velocity*(-FRICTION_FACTOR)

  local acceleration = frictionForce*dt
  e.distanceTraveled = e.distanceTraveled + acceleration:Length()
  e.velocity = e.velocity + acceleration

  checkCollisions(e)
end

return Cannonball
