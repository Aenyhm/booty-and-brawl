local Color = require "toolbox.Color"
local Event = require "toolbox.Event"
local Math = require "toolbox.Math"
local Renderer = require "toolbox.Renderer"
local Vector2 = require "toolbox.Vector2"

local Colors = require "Colors"
local GameState = require "GameState"
local Window = require "Window"

local Boat = require "gameplay.Boat"
local Cannon = require "gameplay.Cannon"
local CollisionManager = require "gameplay.CollisionManager"
local EntityManager = require "gameplay.EntityManager"
local Player = require "gameplay.Player"
local Health = require "gameplay.Health"
local Map = require "gameplay.Map"

local EnemyManager = {}

local EnemyStates = {
  IDLE     = "idle",
  SAIL     = "sail",
  CHASE    = "chase",
  EVASION  = "evasion",
  MANEUVER = "maneuver",
  ATTACK   = "attack",
}

local IDLE_DISTANCE = 30
local EVASION_THRESHOLD = 0.25

-- Distance à laquelle on regarde s'il y a un obstacle.
-- /!\ Ça veut dire qu'on est bloqué si on est dans un couloir qui fait moins de 2 fois cette valeur.
local OBSTACLE_DIST_FACTOR = 2

-- Angle pour vérifier les obstacles à gauche et à droite.
-- On répète cet angle en fonction de `OBSTACLE_ANGLE_REPEAT` pour vérifier plusieurs cases.
-- Donc si on le fait 3 fois, les angles aux extremums vaudront cette valeur x3.
local OBSTACLE_ANGLE_FACTOR = math.pi/6
local OBSTACLE_ANGLE_REPEAT = 2

local enemies = {}

local DifficultySpawns = {
  [GameState.Difficulties.EASY] = {"SLOOPY", "SLOOPY", "SLOOPY", "SLOOPY"},
  [GameState.Difficulties.MEDIUM] = {"SLOOPY", "SLOOPY", "BRIGANTO", "BRIGANTO"},
  [GameState.Difficulties.HARD] = {"SLOOPY", "BRIGANTO", "GALILEON", "GALILEON"},
}

EnemyManager.OnEnemyCreated   = Event.new("Enemy Created")
EnemyManager.OnEnemyDied      = Event.new("Enemy Died")
EnemyManager.OnEnemyDestroyed = Event.new("Enemy Destroyed")

-- On crée un ennemi dans chaque coin de la map
EnemyManager.SpawnableLocations = {
  { position = 1*Map.SIZE/9, size = Map.SIZE/3 },
  { position = Vector2.new(5*Map.SIZE.x/9, 1*Map.SIZE.y/9), size = Map.SIZE/3 },
  { position = Vector2.new(1*Map.SIZE.x/9, 5*Map.SIZE.y/9), size = Map.SIZE/3 },
  { position = 5*Map.SIZE/9, size = Map.SIZE/3 },
}

local function createEnemy(type, areaRec, rotation)
  local locations = Map.FindSpawnableLocations(areaRec)
  local locationIndex = love.math.random(#locations)
  local angle = love.math.random(Math.TAU)

  local enemy = Boat.Create(type, "RED", locations[locationIndex], angle)
  enemy.enemyState = EnemyStates.IDLE
  enemy.color = Colors.ENEMY_TINT
  table.insert(enemies, enemy)

  EnemyManager.OnEnemyCreated(enemy)

  return enemy
end

local function onBoatDied(e)
  for _, enemy in ipairs(enemies) do
    if enemy.id == e.id then
      EnemyManager.OnEnemyDied(enemy)
      break
    end
  end
end

local function onEntityRemoved(e)
  for _, enemy in ipairs(enemies) do
    if enemy.id == e.id then
      EnemyManager.OnEnemyDestroyed(enemy)
      break
    end
  end
end

Boat.OnDied:Add(onBoatDied)
EntityManager.OnEntityRemoved:Add(onEntityRemoved)

function EnemyManager.Init()
  for i, loc in ipairs(EnemyManager.SpawnableLocations) do
    local boatType = DifficultySpawns[GameState.difficulty][i]
    createEnemy(boatType, loc)
  end
end

function EnemyManager.Count()
  return #enemies
end

function EnemyManager.GetSunkCount()
  local result = 0

  for _, e in ipairs(enemies) do
    if e.sunk then
      result = result + 1
    end
  end

  return result
end

local function checkCollisions(e)
  local collisionAngle = {}
  -- On vérifie si des positions autour de nous sont des obstacles.
  local positions = {}
  for i = -OBSTACLE_ANGLE_REPEAT, OBSTACLE_ANGLE_REPEAT do
    local angleOffset = i*OBSTACLE_ANGLE_FACTOR
    local positionOffset = Math.VectorFromAngle(e.transform.angle + angleOffset)*OBSTACLE_DIST_FACTOR
    local predictedPosition = e.transform.position + positionOffset
    local collidedEntity = CollisionManager.GetCollidedEntity(e, predictedPosition)
    if collidedEntity then
      table.insert(positions, collidedEntity.transform.position)
    end
  end

  if #positions > 0 then
    local closerPosition
    local minDist = nil
    for _, position in ipairs(positions) do
      local distance = Math.Dist(e.transform.position, position)
      -- On ne tient pas compte des distances trop similaires,
      -- sinon le bateau va boucler sur ses 2 distances à chaque rotation.
      -- TODO: Faire une vérification plus fine pour décider du meilleur sens dans lequel tourner.
      if minDist == nil or distance < minDist + math.pi/4 then
        minDist = distance
        closerPosition = position
      end
    end

    -- On ralentit et on tourne dans le sens opposé de la plus proche collision.
    local angleDiff = Math.AngleDiff(e.transform.position, e.transform.angle, closerPosition)
    e.deltaRotation = -Math.Sign(angleDiff)
    e.deltaMove = -1

    return true
  end

  return false
end

local function getHitboxAngleDiff(cannon, player, hitboxArea)
  -- On divise le radius par 2 pour ne pas taper pile au bord du bateau.
  local offset = (hitboxArea.offset - hitboxArea.radius/2)/Window.TILE_SIDE
  local position = player.transform.position + offset:Rotate(player.transform.angle)

  return Math.AngleDiff(cannon.transform.position, cannon.transform.angle, position)
end

local function updateState(e)
  local player = Player.GetEntity()

  -- [Joueur mort] --

  if player.dead then
    e.enemyState = EnemyStates.IDLE
    return
  end

  -- [Loin du joueur] --

  local dist = Math.Dist(e.transform.position, player.transform.position)

  if e.enemyState == EnemyStates.IDLE then
    -- Si on est pas trop loin du joueur, on bouge.
    if dist < IDLE_DISTANCE then
      e.enemyState = EnemyStates.SAIL
    end
    return
  end

  -- Si on est trop loin du joueur, on s'arrête.
  if dist >= IDLE_DISTANCE then
    e.enemyState = EnemyStates.IDLE
    return
  end

  -- [Proche du joueur] --

  if e.enemyState == EnemyStates.SAIL then
    -- Si le joueur est dans notre champ de vision, on le pourchasse.
    if dist <= e.sightRange then
      e.enemyState = EnemyStates.CHASE
    -- Sinon on avance.
    else
      e.deltaMove = 1
    end
    return
  end

  -- Si le joueur n'est plus dans notre champ de vision, on navigue tranquillement.
  if dist > e.sightRange then
    e.enemyState = EnemyStates.SAIL
    return
  end

  -- [Joueur dans le champ de vision] --

  local angleDiff = Math.AngleDiff(e.transform.position, e.transform.angle, player.transform.position)

  -- On cherche le canon le plus proche de la cible.
  local leftCannon = e.cannons.left
  local rightCannon = e.cannons.right
  local leftAngleDiff = Math.AngleDiff(leftCannon.transform.position, leftCannon.transform.angle, player.transform.position)
  local rightAngleDiff = Math.AngleDiff(rightCannon.transform.position, rightCannon.transform.angle, player.transform.position)
  local closerCannon
  local closerCannonAngleDiff
  if math.abs(leftAngleDiff) < math.abs(rightAngleDiff) then
    closerCannon = leftCannon
    closerCannonAngleDiff = leftAngleDiff
  else
    closerCannon = rightCannon
    closerCannonAngleDiff = rightAngleDiff
  end

  if Health.GetRatio(e.health) <= EVASION_THRESHOLD then
    -- Si on a peu de vie, on fuit.
    e.enemyState = EnemyStates.EVASION
  else
    -- Sinon on cherche à attaquer le joueur
    if dist > e.cannonballMaxDistance then
      e.enemyState = EnemyStates.CHASE
    else
      -- On récupère les angles des 2 extrémités du bateau
      -- (/!\ on suppose que les hitboxes ont été faites dans l'ordre).
      local targetSternAngleDiff = getHitboxAngleDiff(closerCannon, player, player.hitboxAreas[1])
      local targetProwAngleDiff = getHitboxAngleDiff(closerCannon, player, player.hitboxAreas[#player.hitboxAreas])

      -- Si la proue et la poupe ont des angles opposés, c'est qu'ils sont de part et d'autre de
      -- l'angle de notre canon.
      if Math.Sign(targetSternAngleDiff) ~= Math.Sign(targetProwAngleDiff) then
        e.enemyState = EnemyStates.ATTACK
      else
        e.enemyState = EnemyStates.MANEUVER
      end
    end
  end

  if e.enemyState == EnemyStates.EVASION then
    -- On tourne dans la direction opposée et on avance.
    e.deltaRotation = -Math.Sign(angleDiff)
    e.deltaMove = 1
    return
  end

  if e.enemyState == EnemyStates.CHASE then
    -- On avance et on se tourne dans la direction du joueur.
    e.deltaRotation = Math.Sign(angleDiff)
    e.deltaMove = 1
    return
  end

  -- [Joueur à distance de tir] --

  -- On ralentit.
  e.deltaMove = -1

  if e.enemyState == EnemyStates.MANEUVER then
    -- On oriente le canon le plus proche du joueur vers lui.
    e.deltaRotation = Math.Sign(closerCannonAngleDiff)
    return
  end

  if e.enemyState == EnemyStates.ATTACK then
    -- On attaque !
    Cannon.TryShoot(closerCannon)
    return
  end
end

function EnemyManager.Update(e)
  if e.dead then return end

  if not checkCollisions(e) then
    updateState(e)
  end
end

function EnemyManager.DrawHealthBar(e)
  local renderPosition = e.transform.position*Window.TILE_SIDE

  local healthBarPosition = Vector2.new(
    renderPosition.x - Window.TILE_SIDE/2 - 10,
    renderPosition.y - Window.TILE_SIDE
  )
  local healthBarSize = Vector2.new(Window.TILE_SIDE + 10, 7)

  Renderer.DrawRectangle(healthBarPosition, healthBarSize, Colors.ENEMY_HEALTH_BG)

  local healthRatio = Health.GetRatio(e.health)
  local healthPosition = Vector2.new(healthBarPosition.x + 1, healthBarPosition.y + 1)
  local healthSize = Vector2.new((healthBarSize.x - 2)*healthRatio, healthBarSize.y - 2)

  Renderer.DrawRectangle(healthPosition, healthSize, Colors.ENEMY_HEALTH_FG)
end

return EnemyManager
