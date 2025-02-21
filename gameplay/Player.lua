local Color = require "toolbox.Color"
local Renderer = require "toolbox.Renderer"
local Services = require "toolbox.Services"
local Vector2 = require "toolbox.Vector2"

local Boat = require "gameplay.Boat"
local Cannon = require "gameplay.Cannon"
local Components = require "gameplay.Components"
local Health = require "gameplay.Health"
local Map = require "gameplay.Map"

local Controls = require "Controls"
local GameState = require "GameState"
local Window = require "Window"

local Player = {}

Player.SpawnableLocation = { position = 4*Map.SIZE/9, size = Map.SIZE/9 }

local entity

local BoatTypeByDifficulty = {
  [GameState.Difficulties.EASY] = "GALILEON",
  [GameState.Difficulties.MEDIUM] = "BRIGANTO",
  [GameState.Difficulties.HARD] = "SLOOPY",
}

function Player.Init()
  local boatType = BoatTypeByDifficulty[GameState.difficulty]

  local boatColorRandom = math.random(2)
  local boatColor = boatColorRandom == 1 and "BLUE" or "YELLOW"

  -- On place le joueur au centre de la carte
  local spawnableLocations = Map.FindSpawnableLocations(Player.SpawnableLocation)
  local locationIndex = love.math.random(#spawnableLocations)

  local playerPosition = spawnableLocations[locationIndex]
  local playerAngle = -math.pi/2 -- vers le haut

  entity = Boat.Create(boatType, boatColor, playerPosition, playerAngle)

  -- Avantages pour le joueur
  entity.accelerationSpeed = entity.accelerationSpeed*1.2
end

function Player.GetEntity()
  return entity
end

local function processInput()
  if Controls.IsDown(Controls.Keys.LEFT)  then entity.deltaRotation = -1 end
  if Controls.IsDown(Controls.Keys.RIGHT) then entity.deltaRotation =  1 end

  if Controls.IsDown(Controls.Keys.UP)   then entity.deltaMove =  1 end
  if Controls.IsDown(Controls.Keys.DOWN) then entity.deltaMove = -1 end

  if Controls.IsDown(Controls.Keys.ATTACK_LEFT) then
    Cannon.TryShoot(entity.cannons.left)
  end
  if Controls.IsDown(Controls.Keys.ATTACK_RIGHT) then
    Cannon.TryShoot(entity.cannons.right)
  end
end

-- Centre la caméra sur le joueur.
-- Si on arrive aux bords de la map, on bloque l'affichage.
-- NOTE: Ne tient pas compte du zoom en mode Debug.
local function updateGameCamera()
  local gameCamera = Services.Get("CAMERA").Get("GAME")

  -- Cas nominal
  local playerRenderPos = entity.transform.position*Window.TILE_SIDE
  gameCamera.target = playerRenderPos

  -- Arrivé sur un ou plusieurs bords
  local mapRenderSize = Map.SIZE*Window.TILE_SIDE
  local cameraCenter = gameCamera.size/2
  local borderMin = cameraCenter - Window.TILE_CENTER
  local borderMax = mapRenderSize - cameraCenter - Window.TILE_CENTER

  if playerRenderPos.x < borderMin.x then
    gameCamera.target.x = borderMin.x
  elseif playerRenderPos.x >= borderMax.x then
    gameCamera.target.x = borderMax.x
  end

  if playerRenderPos.y < borderMin.y then
    gameCamera.target.y = borderMin.y
  elseif playerRenderPos.y >= borderMax.y then
    gameCamera.target.y = borderMax.y
  end
end

function Player.Update()
  if not entity.dead then
    processInput()
    updateGameCamera()
  end
end

return Player
