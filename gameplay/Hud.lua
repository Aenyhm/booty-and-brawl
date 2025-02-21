local Color = require "toolbox.Color"
local Math = require "toolbox.Math"
local Renderer = require "toolbox.Renderer"
local Services = require "toolbox.Services"
local Vector2 = require "toolbox.Vector2"

local Components = require "gameplay.Components"
local EnemyManager = require "gameplay.EnemyManager"
local EntityManager = require "gameplay.EntityManager"
local Player = require "gameplay.Player"
local Health = require "gameplay.Health"

local Colors = require "Colors"

local Hud = {}

local PLAYER_HEALTH_SPRITE = Components.Sprite(
  love.graphics.newImage("assets/images/hud/HealthBarSaber_fg.png")
)
local ENEMY_ALIVE_SPRITE = Components.Sprite(
  love.graphics.newImage("assets/images/hud/Killing_sloopy.png")
)
local CROSSBONE_SPRITE = Components.Sprite(
  love.graphics.newImage("assets/images/Crane2.png")
)
CROSSBONE_SPRITE.scale = 0.5

local FONT = Services.Get("FONT").Get("MAIN", 18)
local PADDING = 5

local HEARTBEAT_THRESHOLD = 0.2
local HEARTBEAT_DURATION = 4
local HEARTBEAT_SIZE = 30

local camera
local heartbeatElapsed
local showHeartbeat
local totalEnemyCount
local remaingEnemyCount
local playerHealthRatio

local function onEnemyCreated()
  totalEnemyCount = totalEnemyCount + 1
  remaingEnemyCount = remaingEnemyCount + 1
end

local function onEnemyDied()
  remaingEnemyCount = remaingEnemyCount - 1
end

EnemyManager.OnEnemyCreated:Add(onEnemyCreated)
EnemyManager.OnEnemyDied:Add(onEnemyDied)

function Hud.Init()
  camera = Services.Get("CAMERA").Get("HUD")
  heartbeatElapsed = 0
  showHeartbeat = false
  totalEnemyCount = 0
  remaingEnemyCount = 0
end

function Hud.Update(dt)
  playerHealthRatio = Health.GetRatio(Player.GetEntity().health)
  if playerHealthRatio > 0 and playerHealthRatio <= HEARTBEAT_THRESHOLD then
    showHeartbeat = true
    heartbeatElapsed = heartbeatElapsed + dt
    if heartbeatElapsed > HEARTBEAT_DURATION then
      heartbeatElapsed = 0
    end
  else 
    showHeartbeat = false
  end
end

local function drawPlayerHealth(playerHealthRatio)
  local size = PLAYER_HEALTH_SPRITE.size

  local healthBgPosition = Vector2.new(size.x/2, size.y/2) + PADDING
  Renderer.DrawTexture(PLAYER_HEALTH_SPRITE.image, nil, healthBgPosition, size/2)

  local healthFgWidth = playerHealthRatio*size.x

  -- On remplit la jauge de dégâts de droite à gauche
  local healthFgPosition = Vector2.new(healthBgPosition.x + healthFgWidth, healthBgPosition.y)
  local width = size.x - healthFgWidth

  local healthFgQuad = love.graphics.newQuad(
    healthFgWidth, 0, width, size.y, PLAYER_HEALTH_SPRITE.image
  )
  Renderer.DrawTexture(
    PLAYER_HEALTH_SPRITE.image, healthFgQuad, healthFgPosition, size/2, 0, Colors.RED
  )
end

local function drawRemainingEnemies()
  for i = 0, totalEnemyCount - 1 do
    local marginX = i*(ENEMY_ALIVE_SPRITE.size.x + PADDING)

    local outerSize = ENEMY_ALIVE_SPRITE.size/2
    local outerPosition = Vector2.new(
      camera.size.x - outerSize.x - PADDING - marginX,
      outerSize.y + PADDING
    )

    local isDead = i >= remaingEnemyCount
    local outerColor = isDead and Colors.RED or Colors.WHITE

    Renderer.DrawTexture(ENEMY_ALIVE_SPRITE.image, nil, outerPosition, outerSize, 0, outerColor)

    if isDead then
      local innerSize = CROSSBONE_SPRITE.size*CROSSBONE_SPRITE.scale/2
      local innerPosition = outerPosition - innerSize/2
      Renderer.DrawTexture(
        CROSSBONE_SPRITE.image,
        nil,
        innerPosition,
        innerSize,
        0,
        Colors.WHITE,
        CROSSBONE_SPRITE.scale
      )
    end
  end
end

-- On dessine des rectangles rouges en fondu de chaque côté de la fenêtre.
-- Un coup vertical, un coup horizontal.
local function drawHeartbeat()
  local heartbeatRatio
  if heartbeatElapsed < HEARTBEAT_DURATION/2 then
    heartbeatRatio = Math.NormalizeValue(heartbeatElapsed/HEARTBEAT_DURATION, 0, 0.5)
  else
    heartbeatRatio = Math.NormalizeValue(heartbeatElapsed/HEARTBEAT_DURATION, 0.5, 1)
  end

  if heartbeatRatio > 0.5 then
    heartbeatRatio = 1 - heartbeatRatio
  end

  local color = Color.Copy(Colors.RED)
  color[4] = heartbeatRatio

  if heartbeatElapsed < HEARTBEAT_DURATION/2 then
    Renderer.DrawRectangle(
      Vector2.new(0, 0),
      Vector2.new(camera.size.x, HEARTBEAT_SIZE),
      color
    )
    Renderer.DrawRectangle(
      Vector2.new(0, camera.size.y - HEARTBEAT_SIZE),
      Vector2.new(camera.size.x, HEARTBEAT_SIZE),
      color
    )
  else
    Renderer.DrawRectangle(
      Vector2.new(0, 0),
      Vector2.new(HEARTBEAT_SIZE, camera.size.y),
      color
    )
    Renderer.DrawRectangle(
      Vector2.new(camera.size.x - HEARTBEAT_SIZE, 0),
      Vector2.new(HEARTBEAT_SIZE, camera.size.y),
      color
    )
  end
end

function Hud.Draw()
  camera:Begin()
    if showHeartbeat then
      drawHeartbeat()
    end

    drawPlayerHealth(playerHealthRatio)
    drawRemainingEnemies()
  camera:End()
end

return Hud
