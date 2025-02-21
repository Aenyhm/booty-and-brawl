local Math = require "toolbox.Math"
local Vector2 = require "toolbox.Vector2"

local Components = require "gameplay.Components"
local EntityManager = require "gameplay.EntityManager"

local Window = require "Window"

local Map = {}

local grid = {}

-- /!\ Trop de cases font ralentir le programme (400x400).
Map.SIZE = Vector2.new(60, 50)

local WATER_TILESET = love.graphics.newImage("assets/images/tiles/WaterTileset.png")
local SAND_TILESET = love.graphics.newImage("assets/images/tiles/SandOverWaterTileset.png")
local GRASS_TILESET = love.graphics.newImage("assets/images/tiles/GrassOverSandTileset.png")
local MOUNTAIN_IMAGE = love.graphics.newImage("assets/images/tiles/rock.png")
local PIKE_TILESET = love.graphics.newImage("assets/images/tiles/PikeTileset.png")

local NOISE_SCALE = 30
local TERRAIN_SEED = 510 -- love.math.random(10000)

local NoiseThresholds = {
  SHALLOW_WATER = 0.81,
  SAND = 0.9,
  GRASS = 0.97,
  MOUNTAIN = 1,
  PIKE = 1.1 -- Pour la bordure
}

local TileTypes = {
  DEEP_WATER = 0,
  SHALLOW_WATER = 1,
  SAND = 2,
  GRASS = 3,
  MOUNTAIN = 4,
  PIKE = 5
}

local TILE_HITBOX_RECTANGLE = {
  position = Vector2.Zero(),
  size = Window.TILE_SIZE
}

local function getCellValueAt(row, col)
  local result = TileTypes.PIKE -- Bordures au-delà de la grille

  if row > 0 and row <= Map.SIZE.y and col > 0 and col <= Map.SIZE.x then
    result = grid[row][col]
  end

  return result
end

local function generateTerrain()
  --TERRAIN_SEED = love.math.random(10000)
  --print(TERRAIN_SEED)
  local noises = {}

  local min = nil
  local max = nil
  for row = 1, Map.SIZE.y do
    noises[row] = {}
    for col = 1, Map.SIZE.x do
      local noiseVec = (Vector2.new(col, row) + TERRAIN_SEED)/NOISE_SCALE
      local noise = love.math.noise(noiseVec.x, noiseVec.y)
      noises[row][col] = noise
      if min == nil or min > noise then min = noise end
      if max == nil or max < noise then max = noise end
    end
  end

  for row = 1, Map.SIZE.y do
    grid[row] = {}
    for col = 1, Map.SIZE.x do
      -- On s'assure que les bords soient bloqués
      local tileType
      if (
        col == 1 or col == Map.SIZE.x or
        row == 1 or row == Map.SIZE.y
      ) then
        tileType = TileTypes.PIKE
      else
        local value = Math.NormalizeValue(noises[row][col], min, max)

        if value < NoiseThresholds.SHALLOW_WATER then
          tileType = TileTypes.DEEP_WATER
        elseif value < NoiseThresholds.SAND then
          tileType = TileTypes.SHALLOW_WATER
        elseif value < NoiseThresholds.GRASS then
          tileType = TileTypes.SAND
        elseif value < NoiseThresholds.MOUNTAIN then
          tileType = TileTypes.GRASS
        else
          tileType = TileTypes.MOUNTAIN
        end
      end

      grid[row][col] = tileType
    end
  end
end

local function cellIndexToCoords(index, gridWidth)
  local x = index % gridWidth
  local y = math.floor(index/gridWidth)

  return Vector2.new(x, y)
end

function Map.Init()
  generateTerrain()

  for row = 1, Map.SIZE.y do
    for col = 1, Map.SIZE.x do
      local cellValue = grid[row][col]

      if cellValue == TileTypes.DEEP_WATER then
        -- Pour la majorité des cases, on dessine juste un grand rectangle
        -- plutôt que de dessiner plein d'images.
        goto continue
      end

      -- Les tableaux Lua commencent à l'indice 1, mais les coordonnées commencent à 0.
      local transform = Components.Transform(Vector2.new(col - 1, row - 1))

      local sprite

      if cellValue == TileTypes.MOUNTAIN then
        sprite = Components.Sprite(MOUNTAIN_IMAGE)
      else
        local tileset
        if cellValue == TileTypes.SHALLOW_WATER then
          tileset = WATER_TILESET
        elseif cellValue == TileTypes.SAND then
          tileset = SAND_TILESET
        elseif cellValue == TileTypes.GRASS then
          tileset = GRASS_TILESET
        elseif cellValue == TileTypes.PIKE then
          tileset = PIKE_TILESET
        end

        local spriteIndex = 0
        if getCellValueAt(row - 1, col) >= cellValue then spriteIndex = spriteIndex + 1 end
        if getCellValueAt(row, col + 1) >= cellValue then spriteIndex = spriteIndex + 2 end
        if getCellValueAt(row + 1, col) >= cellValue then spriteIndex = spriteIndex + 4 end
        if getCellValueAt(row, col - 1) >= cellValue then spriteIndex = spriteIndex + 8 end

        local spriteCoords = cellIndexToCoords(spriteIndex, 4)

        sprite = Components.Sprite(tileset, spriteCoords*Window.TILE_SIDE, Window.TILE_SIZE)
      end

      local e = EntityManager.Create(sprite, transform)

      if cellValue >= TileTypes.SAND then
        e.hitboxRectangle = TILE_HITBOX_RECTANGLE
      end

      ::continue::
    end
  end
end

function Map.FindSpawnableLocations(areaRec)
  local result = {}

  -- On tronque les positions pour correspondre à une cellule de la grille.
  areaRec.position.x = math.floor(areaRec.position.x)
  areaRec.position.y = math.floor(areaRec.position.y)
  areaRec.size.x = math.ceil(areaRec.size.x)
  areaRec.size.y = math.ceil(areaRec.size.y)

  for row = areaRec.position.y + 1, areaRec.position.y + areaRec.size.y do
    for col = areaRec.position.x + 1, areaRec.position.x + areaRec.size.x do
      -- On ne spawn que dans l'eau profonde pour être assez loin des îles.
      if grid[row][col] == TileTypes.DEEP_WATER then
        local location = Vector2.new(col - 1, row - 1)
        table.insert(result, location)
      end
    end
  end

  return result
end

return Map
