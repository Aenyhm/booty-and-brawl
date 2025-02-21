local Color = require "toolbox.Color"
local Event = require "toolbox.Event"
local Math = require "toolbox.Math"
local Services = require "toolbox.Services"
local Vector2 = require "toolbox.Vector2"

local Cannon = require "gameplay.Cannon"
local CollisionManager = require "gameplay.CollisionManager"
local Components = require "gameplay.Components"
local EntityManager = require "gameplay.EntityManager"
local Health = require "gameplay.Health"

local Boat = {}

-- Il y a 3 types de bateaux qui ont des caractéristiques différentes :
-- taille, vitesse, points de vie, etc.

-- Pour chaque type de bateau, on a 3 couleurs de voiles.
local Images = {
  SLOOPY = {
    BLUE   = love.graphics.newImage("assets/images/boats/Sloopy_b.png"),
    RED    = love.graphics.newImage("assets/images/boats/Sloopy_r.png"),
    YELLOW = love.graphics.newImage("assets/images/boats/Sloopy_y.png"),
  },
  BRIGANTO = {
    BLUE   = love.graphics.newImage("assets/images/boats/Briganto_b.png"),
    RED    = love.graphics.newImage("assets/images/boats/Briganto_r.png"),
    YELLOW = love.graphics.newImage("assets/images/boats/Briganto_y.png"),
  },
  GALILEON = {
    BLUE   = love.graphics.newImage("assets/images/boats/Galileon_b.png"),
    RED    = love.graphics.newImage("assets/images/boats/Galileon_r.png"),
    YELLOW = love.graphics.newImage("assets/images/boats/Galileon_y.png"),
  }
}

-- Pour chaque type de bateau, on a 3 images à afficher successivement quand on coule.
local SinkImages = {
  SLOOPY = {
    love.graphics.newImage("assets/images/boats/Sloopy_kaput1.png"),
    love.graphics.newImage("assets/images/boats/Sloopy_kaput2.png"),
    love.graphics.newImage("assets/images/boats/Sloopy_kaput3.png"),
  },
  BRIGANTO = {
    love.graphics.newImage("assets/images/boats/Briganto_kaput1.png"),
    love.graphics.newImage("assets/images/boats/Briganto_kaput2.png"),
    love.graphics.newImage("assets/images/boats/Briganto_kaput3.png"),
  },
  GALILEON = {
    love.graphics.newImage("assets/images/boats/Galileon_kaput1.png"),
    love.graphics.newImage("assets/images/boats/Galileon_kaput2.png"),
    love.graphics.newImage("assets/images/boats/Galileon_kaput3.png"),
  },
}

local IMAGE_ORIENTATION = -math.pi/2 -- vers le haut

local AccelerationSpeeds = { SLOOPY = 3.0, BRIGANTO = 3.2, GALILEON = 3.5 }
local AngleSpeeds        = { SLOOPY = math.pi/3, BRIGANTO = math.pi/4, GALILEON = math.pi/5 }
local MaxHealthes        = { SLOOPY = 8,   BRIGANTO = 12,  GALILEON = 15  }

-- Pour chaque type de bateau, on spécifie plusieurs hitboxes circulaires.
-- C'est plus simple d'utiliser des cercles lorsqu'on a une entité qui change d'angle.
local ImageHalfWidthes = {
  SLOOPY   = Images.SLOOPY.BLUE:getWidth()/2,
  BRIGANTO = Images.BRIGANTO.BLUE:getWidth()/2,
  GALILEON = Images.GALILEON.BLUE:getWidth()/2,
}
local HitboxAreas = {
  SLOOPY = {
    { offset = Vector2.new(-20, 0), radius = ImageHalfWidthes.SLOOPY -  4 },
    { offset = Vector2.new(-12, 0), radius = ImageHalfWidthes.SLOOPY -  3 },
    { offset = Vector2.new( -5, 0), radius = ImageHalfWidthes.SLOOPY -  3 },
    { offset = Vector2.new(  5, 0), radius = ImageHalfWidthes.SLOOPY -  3 },
    { offset = Vector2.new( 15, 0), radius = ImageHalfWidthes.SLOOPY -  7 },
    { offset = Vector2.new( 23, 0), radius = ImageHalfWidthes.SLOOPY - 12 },
  },
  BRIGANTO = {
    { offset = Vector2.new(-26, 0), radius = ImageHalfWidthes.BRIGANTO -  7 },
    { offset = Vector2.new(-18, 0), radius = ImageHalfWidthes.BRIGANTO -  5 },
    { offset = Vector2.new(-11, 0), radius = ImageHalfWidthes.BRIGANTO -  5 },
    { offset = Vector2.new(  0, 0), radius = ImageHalfWidthes.BRIGANTO -  5 },
    { offset = Vector2.new( 10, 0), radius = ImageHalfWidthes.BRIGANTO -  7 },
    { offset = Vector2.new( 21, 0), radius = ImageHalfWidthes.BRIGANTO - 12 },
    { offset = Vector2.new( 30, 0), radius = ImageHalfWidthes.BRIGANTO - 17 },
  },
  GALILEON = {
    { offset = Vector2.new(-30, 0), radius = ImageHalfWidthes.GALILEON -  7 },
    { offset = Vector2.new(-18, 0), radius = ImageHalfWidthes.GALILEON -  6 },
    { offset = Vector2.new( -5, 0), radius = ImageHalfWidthes.GALILEON -  6 },
    { offset = Vector2.new(  8, 0), radius = ImageHalfWidthes.GALILEON -  6 },
    { offset = Vector2.new( 20, 0), radius = ImageHalfWidthes.GALILEON - 12 },
    { offset = Vector2.new( 33, 0), radius = ImageHalfWidthes.GALILEON - 20 },
  },
}

local SIGHT_RANGE = 7 -- en nombre de cases autour
local CANNONBALL_MAX_DISTANCE = 4 -- en nombre de cases autour

local FRICTION_FACTOR = 0.9
local BRAKING_FACTOR = 3.0
local MIN_DAMAGE_VELOCITY_LENGTH = 1.2
local SINK_DURATION = 4.0 -- en secondes
local DAMAGE_POINTS = 1

local BoatStates = {
  ALIVE = "alive",
  SINK = "sink"
}

Boat.OnDied = Event.new("Boat Died")

function Boat.Create(boatType, color, position, angle)
  local sprite = Components.Sprite(Images[boatType][color], nil, nil, IMAGE_ORIENTATION)
  local transform = Components.Transform(position, angle)
  local e = EntityManager.Create(sprite, transform)

  e.boatType = boatType
  e.type = EntityManager.Type.BOAT
  e.velocity = Vector2.Zero()
  e.accelerationSpeed = AccelerationSpeeds[boatType]
  e.deltaMove = 0     -- -1 = freine, 1 = accélère
  e.rotationSpeed = AngleSpeeds[boatType]
  e.deltaRotation = 0 -- -1 = gauche, 1 = droite
  e.health = Components.Health(MaxHealthes[boatType])
  e.damagePoints = DAMAGE_POINTS
  e.sightRange = SIGHT_RANGE
  e.cannonballMaxDistance = CANNONBALL_MAX_DISTANCE
  e.sinkTime = 0
  e.state = BoatStates.ALIVE
  e.hitboxAreas = HitboxAreas[boatType]
  e.cannons = {
    left = Cannon.Create(e, -1),
    right = Cannon.Create(e, 1)
  }

  -- Permet de vérifier si on est déjà en collision pour
  -- éviter de se prendre des dégâts à chaque frame.
  e.colliding = false

  return e
end

local function checkCollisions(e, deltaAngle)
  local collidedEntity = CollisionManager.GetCollidedEntity(e, e.transform.position)
  if collidedEntity then
    -- Effet de recul si collision avec une autre entité massive
    if collidedEntity.type ~= EntityManager.Type.CANNONBALL then
      local angleDiff = Math.AngleDiff(
        e.transform.position, e.transform.angle, collidedEntity.transform.position
      )
      e.velocity = -1*e.velocity:Rotate(angleDiff)
      e.transform.angle = e.transform.angle - deltaAngle
    end

    -- Dégâts si on va assez vite et qu'on n'est pas déjà en collision
    if not e.colliding and e.velocity:Length() > MIN_DAMAGE_VELOCITY_LENGTH then
      Services.Get("AUDIO").GetSound("BOAT_HIT"):play()
      Health.Hurt(e, 1)
      Health.Hurt(collidedEntity, e.damagePoints)
    end

    e.colliding = true
  else
    e.colliding = false
  end
end

local function move(e, dt)
  -- [Rotation] --
  local deltaAngle = 0
  if e.deltaRotation ~= 0 then
    deltaAngle = e.deltaRotation*e.rotationSpeed*dt
    e.velocity = e.velocity:Rotate(deltaAngle)
    e.transform.angle = e.transform.angle + deltaAngle
  end

  -- [Déplacement] --

  -- On applique une friction de l'eau constante pour ralentir doucement.
  local frictionForce = e.velocity*(-FRICTION_FACTOR)

  if e.deltaMove == 1 then
    -- Accélération
    local direction = Math.VectorFromAngle(e.transform.angle)
    local acceleration = e.accelerationSpeed*direction*dt

    e.velocity = e.velocity + acceleration
  elseif e.deltaMove == -1 then
    -- Freinage
    frictionForce = frictionForce*BRAKING_FACTOR
  end

  e.velocity = e.velocity + frictionForce*dt

  -- Pour éviter des calculs de collisions inutiles :
  -- quand la vitesse est insignifiante, on la réduit à 0.
  if e.velocity:Length() < Math.EPSILON then
    e.velocity = Vector2.Zero()
  end

  if e.velocity:Length() ~= 0 then
    checkCollisions(e, deltaAngle)
  end

  e.deltaRotation = 0
  e.deltaMove = 0
end

local function sink(e, dt)
  if e.sinkTime >= SINK_DURATION then
    e.sunk = true
    e.destroy = true
  else
    local sinkRatio = e.sinkTime/SINK_DURATION
    if sinkRatio >= 0.66 then
      e.sprite.image = SinkImages[e.boatType][3]
      local newColor = Color.Copy(e.color)
      newColor[4] = Math.NormalizeValue(0.66/sinkRatio, 0.66, 1)
      e.color = newColor

      -- Quand on est "sous l'eau", on retire les hitboxes.
      e.hitboxAreas = nil
    elseif sinkRatio >= 0.33 then
      e.sprite.image = SinkImages[e.boatType][2]
    elseif sinkRatio >= 0 then
      e.sprite.image = SinkImages[e.boatType][1]
    end

    e.sinkTime = e.sinkTime + dt
  end
end

function Boat.Update(e, dt)
  if e.state == BoatStates.ALIVE then
    if e.health.value > 0 then
      move(e, dt)
    else
      e.dead = true
      Boat.OnDied(e)

      e.velocity = Vector2.Zero()
      for _, cannon in pairs(e.cannons) do
        cannon.destroy = true
      end

      e.state = BoatStates.SINK
    end
  elseif e.state == BoatStates.SINK then
    sink(e, dt)
  end
end

return Boat
