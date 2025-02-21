local Math = require "toolbox.Math"
local Renderer = require "toolbox.Renderer"
local Services = require "toolbox.Services"
local Vector2 = require "toolbox.Vector2"

local CollisionManager = require "gameplay.CollisionManager"
local EnemyManager = require "gameplay.EnemyManager"
local EntityManager = require "gameplay.EntityManager"
local Map = require "gameplay.Map"
local Player = require "gameplay.Player"

local Colors = require "Colors"
local Window = require "Window"

local Debug = {}

local MIN_ZOOM = 0.15
local FONT = Services.Get("FONT").Get("MAIN", 10)

local SHOW_IDS = false

function Debug.Zoom(delta)
  local gameCamera = Services.Get("CAMERA").Get("GAME")
  gameCamera.zoom = math.max(MIN_ZOOM, gameCamera.zoom + delta/10)
end

function Debug.DrawGizmos()
  -- [Grille de la carte] --
  local positionOffset = -Window.TILE_SIDE/2

  -- Lignes
  for i = 1, Map.SIZE.y do
    local position = Vector2.new(positionOffset, i*Window.TILE_SIDE + positionOffset)
    local size = Vector2.new(
      Map.SIZE.x*Window.TILE_SIDE + positionOffset,
      i*Window.TILE_SIDE + positionOffset
    )
    Renderer.DrawLine(position, size, Colors.DEBUG_GRID)
  end
  -- Colonnes
  for i = 1, Map.SIZE.x do
    local position = Vector2.new(i*Window.TILE_SIDE + positionOffset, positionOffset)
    local size = Vector2.new(
      i*Window.TILE_SIDE + positionOffset,
      Map.SIZE.y*Window.TILE_SIDE + positionOffset
    )
    Renderer.DrawLine(position, size, Colors.DEBUG_GRID)
  end

  -- [Zones spawnables] --
  for _, loc in ipairs(EnemyManager.SpawnableLocations) do
    Renderer.DrawRectangle(
      loc.position*Window.TILE_SIDE, loc.size*Window.TILE_SIDE, Colors.DEBUG_SPAWN, "line"
    )
  end
  local playerLoc = Player.SpawnableLocation
  Renderer.DrawRectangle(
    playerLoc.position*Window.TILE_SIDE, playerLoc.size*Window.TILE_SIDE, Colors.DEBUG_SPAWN, "line"
  )

  for _, e in ipairs(EntityManager.GetAll()) do
    local renderPosition = e.transform.position*Window.TILE_SIDE

    -- [Trajectoires des canons] --
    if e.type == EntityManager.Type.CANNON then
      local direction = Math.VectorFromAngle(e.transform.angle)
      local gizmoEnd = (
        e.parent.transform.position*Window.TILE_SIDE +
        direction*e.parent.cannonballMaxDistance*Window.TILE_SIDE
      )
      Renderer.DrawLine(renderPosition, gizmoEnd, Colors.DEBUG_CANNON)
    end

    -- [Hitboxes] --
    if e.hitboxRectangle then
      local rec = CollisionManager.GetComputedHitboxRectangle(e, e.transform.position)
      Renderer.DrawRectangle(rec.position, rec.size, Colors.DEBUG_HITBOX, "line")
    elseif e.hitboxAreas then
      for _, hitbox in ipairs(CollisionManager.GetComputedHitboxCircles(e, e.transform.position)) do
        Renderer.DrawCircle(hitbox.center, hitbox.radius, Colors.DEBUG_HITBOX, "line")
      end
    end

    -- [Ranges] --
    if e.type == EntityManager.Type.BOAT then
      Renderer.DrawCircle(
        renderPosition, e.sightRange*Window.TILE_SIDE, Colors.DEBUG_SIGHT_RANGE, "line"
      )
      Renderer.DrawCircle(
        renderPosition, e.cannonballMaxDistance*Window.TILE_SIDE, Colors.DEBUG_CANNONBALL_RANGE, "line"
      )
    end

    -- [IDs] --
    if SHOW_IDS then
      local idText = e.id
      local idTextWidth = FONT:getWidth(idText)
      local position = Vector2.new(renderPosition.x - idTextWidth/2, renderPosition.y)
      Renderer.DrawText(FONT, idText, position)
    end

    -- [États des ennemis] --
    if e.enemyState then
      local stateText = e.enemyState
      local stateTextWidth = FONT:getWidth(stateText)
      local position = Vector2.new(renderPosition.x - stateTextWidth/2, renderPosition.y - 20)
      Renderer.DrawText(FONT, stateText, position, Colors.DEBUG_STATE)
    end
  end
end

function Debug.DrawInfo()
  Renderer.DrawText(FONT, EntityManager.Count().." entities", Vector2.new(2, 2), Colors.WHITE)
end

return Debug
