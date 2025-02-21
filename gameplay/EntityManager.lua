--[[
Module qui gère la création, le stockage et la suppression de toutes les entités.
--]]
local Event = require "toolbox.Event"

local Entity = require "gameplay.Entity"

local EntityManager = {}

local entities = {}

EntityManager.Type = {
  BOAT = "boat",
  CANNON = "cannon",
  CANNONBALL = "cannonball",
}

local currentEntityId = 0

EntityManager.OnEntityAdded = Event.new()
EntityManager.OnEntityRemoved = Event.new()

function EntityManager.GetAll()
  return entities
end

function EntityManager.Count()
  return #entities
end

function EntityManager.Create(sprite, transform)
  currentEntityId = currentEntityId + 1

  local e = Entity.new(currentEntityId, sprite, transform)
  table.insert(entities, e)

  EntityManager.OnEntityAdded(e)

  return e
end

function EntityManager.Reset()
  entities = {}
  currentEntityId = 0
end

function EntityManager.DestroySystem()
  for i = #entities, 1, -1 do
    local e = entities[i]
    if e.destroy then
      EntityManager.OnEntityRemoved(e)
      table.remove(entities, i)
    end
  end
end

return EntityManager
