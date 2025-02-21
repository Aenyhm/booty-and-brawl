local Services = require "toolbox.Services"
local Vector2 = require "toolbox.Vector2"

local Cannonball = require "gameplay.Cannonball"
local Components = require "gameplay.Components"
local EntityManager = require "gameplay.EntityManager"

local Cannon = {}

local IMAGE_ORIENTATION = math.pi -- vers la gauche
local SPRITE = Components.Sprite(
  love.graphics.newImage("assets/images/cannon.png"), nil, nil, IMAGE_ORIENTATION
)
local COOLDOWN_TIMER = 1.2 -- Durée avant de pouvoir tirer à nouveau (en secondes)

-- Décalage des canons par rapport au centre du bateau
local BoatOffsets = {
  SLOOPY = Vector2.new(0, 0.4),
  BRIGANTO = Vector2.new(0, 0.5),
  GALILEON = Vector2.new(0, 0.6),
}

function Cannon.Create(boat, side)  -- side: -1 = gauche, 1 = droite
  local transform = Components.Transform()
  local e = EntityManager.Create(SPRITE, transform)

  e.type = EntityManager.Type.CANNON
  e.parent = boat
  e.side = side
  e.cooldown = 0

  Cannon.Update(e)

  return e
end

function Cannon.TryShoot(e)
  if e.cooldown == 0 then
    Cannonball.Create(e)
    e.cooldown = COOLDOWN_TIMER

    Services.Get("AUDIO").GetSound("CANNON_SHOOT"):play()
  end
end

function Cannon.Update(e, dt)
  if e.cooldown > 0 then
    e.cooldown = math.max(e.cooldown - dt, 0)
  end

  local boatOffset = BoatOffsets[e.parent.boatType]
  local deltaPos = e.side*boatOffset:Rotate(e.parent.transform.angle)
  e.transform.position = e.parent.transform.position + deltaPos

  e.transform.angle = e.parent.transform.angle + e.side*math.pi/2 -- perpendiculaire au bateau
end

return Cannon
