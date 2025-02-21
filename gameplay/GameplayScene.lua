local Renderer = require "toolbox.Renderer"
local Services = require "toolbox.Services"
local Vector2 = require "toolbox.Vector2"

local Boat = require "gameplay.Boat"
local Cannonball = require "gameplay.Cannonball"
local Cannon = require "gameplay.Cannon"
local Debug = require "gameplay.Debug"
local EndGame = require "gameplay.EndGame"
local EnemyManager = require "gameplay.EnemyManager"
local EntityManager = require "gameplay.EntityManager"
local Hud = require "gameplay.Hud"
local Map = require "gameplay.Map"
local Player = require "gameplay.Player"

local Colors = require "Colors"
local Controls = require "Controls"
local GameState = require "GameState"
local Window = require "Window"

local GameplayScene = {}

local States = {
  PLAY = "play",
  END_GAME = "end_game"
}

local debugMode = false
local gameCamera
local uiCamera
local state

local enemyCount = 0

local function onEnemyCreated()
  enemyCount = enemyCount + 1
end

local function onEnemyDestroyed()
  enemyCount = enemyCount - 1
end

EnemyManager.OnEnemyCreated:Add(onEnemyCreated)
EnemyManager.OnEnemyDestroyed:Add(onEnemyDestroyed)

function GameplayScene.Init()
  gameCamera = Services.Get("CAMERA").Get("GAME")
  uiCamera = Services.Get("CAMERA").Get("UI")
end

function GameplayScene.Enter()
  if GameState.isPlaying then return end

  EntityManager.Reset()

  GameState.isPlaying = true
  state = States.PLAY

  Map.Init()
  EndGame.Init()
  Player.Init()
  Hud.Init()
  EnemyManager.Init()
end

local function goToMenu()
  if state == States.END_GAME then
    GameState.isPlaying = false
  end

  Services.Get("SCENE").GoTo("MENU")
end

function GameplayScene.Update(dt)
  if state == States.PLAY then
    if Player.GetEntity().sunk or enemyCount == 0 then
      state = States.END_GAME
    else
      Player.Update()
    end
  elseif state == States.END_GAME then
    EndGame.Update(dt)
    if EndGame.state == EndGame.States.FINISHED then
      goToMenu()
    end
  end

  for _, e in ipairs(EntityManager.GetAll()) do
    if e.type == EntityManager.Type.BOAT then
      if e.enemyState then
        EnemyManager.Update(e)
      end
      Boat.Update(e, dt)
    elseif e.type == EntityManager.Type.CANNON then
      Cannon.Update(e, dt)
    elseif e.type == EntityManager.Type.CANNONBALL then
      Cannonball.Update(e, dt)
    end

    if e.velocity then
      e.transform.position = e.transform.position + e.velocity*dt
    end
  end

  EntityManager.DestroySystem()

  Hud.Update(dt)
end

function GameplayScene.Draw()
  gameCamera:Begin()
    -- On ne dessine que les entités visibles autour du joueur.
    local borderMinRec = gameCamera.target - gameCamera.size/2
    local borderMaxRec = gameCamera.target + gameCamera.size/2

    local borderMinCenter = borderMinRec - Window.TILE_CENTER
    local borderMaxCenter = borderMaxRec + Window.TILE_CENTER

    Renderer.DrawRectangle(borderMinRec, gameCamera.size, Colors.GAME_DEEP_WATER)

    for _, e in ipairs(EntityManager.GetAll()) do
      local renderPosition = e.transform.position*Window.TILE_SIDE

      if (
        renderPosition.x > borderMinCenter.x and renderPosition.x < borderMaxCenter.x and
        renderPosition.y > borderMinCenter.y and renderPosition.y < borderMaxCenter.y
      ) then
        e:Draw()

        if e.enemyState and not e.dead then
          EnemyManager.DrawHealthBar(e)
        end
      end
    end

    -- Pour cacher une partie des entités à cheval sur les bordures,
    -- on dessine un masque autour de la zone de la caméra (4 rectangles).
    Renderer.DrawRectangle(
      Vector2.new(-Window.TILE_SIDE/2, borderMinRec.y),
      Vector2.new(borderMinRec.x + Window.TILE_SIDE/2, gameCamera.size.y),
      Colors.BLACK
    )
    Renderer.DrawRectangle(
      Vector2.new(borderMinRec.x, -Window.TILE_SIDE/2),
      Vector2.new(gameCamera.size.x, borderMinRec.y + Window.TILE_SIDE/2),
      Colors.BLACK
    )
    Renderer.DrawRectangle(
      Vector2.new(borderMaxRec.x, borderMinRec.y), gameCamera.size, Colors.BLACK
    )
    Renderer.DrawRectangle(
      Vector2.new(borderMinRec.x, borderMaxRec.y), gameCamera.size, Colors.BLACK
    )

    if debugMode then Debug.DrawGizmos() end
  gameCamera:End()

  Hud.Draw()

  uiCamera:Begin()
    if debugMode then Debug.DrawInfo() end
    if state == States.END_GAME then EndGame.Draw() end
  uiCamera:End()
end

function GameplayScene.OnKeyPressed(key)
  if Controls.IsPressed(key, Controls.Keys.BACK) then
    goToMenu()
  elseif Controls.IsPressed(key, Controls.Keys.DEBUG) then
    debugMode = not debugMode
  end
end

function GameplayScene.OnMouseWheel(delta)
  if debugMode then
    Debug.Zoom(delta)
  end
end

function GameplayScene.OnFocusChange(focus)
  if not focus then
    goToMenu()
  end
end

return GameplayScene
