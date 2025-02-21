local Camera = require "toolbox.Camera"
local Vector2 = require "toolbox.Vector2"

local Window = require "Window"

local CameraManager = {}

-- Pour définir la taille du monde, on décide d'un nombre de cases en largeur.
local TILES_IN_WIDTH = 32
local UI_HEIGHT = 800

local WORLD_SIZE = Vector2.new(TILES_IN_WIDTH, TILES_IN_WIDTH/Window.ASPECT_RATIO)*Window.TILE_SIDE
local UI_SIZE = Vector2.new(UI_HEIGHT*Window.ASPECT_RATIO, UI_HEIGHT)

local cameras = {}

local function adaptToWindow(camera)
  -- On place l'origine de la caméra au centre de la fenêtre.
  -- Utile lorsqu'on a une target (pour suivre le joueur par exemple).
  camera.offset = Window.size/2

  -- On zoome sur le monde en fonction de la taille de la fenêtre.
  local zoom = Window.size/camera.size

  -- Pour ne pas que le monde déborde de la fenêtre, on prend le plus petit ratio.
  camera.zoom = math.min(zoom.x, zoom.y)
end

local function createCamera(cameraSize)
  local camera = Camera.new(cameraSize/2)
  camera.size = cameraSize

  adaptToWindow(camera)

  return camera
end

function CameraManager.Init()
  cameras.UI   = createCamera(UI_SIZE)
  cameras.GAME = createCamera(WORLD_SIZE)
  cameras.HUD  = createCamera(UI_SIZE)
end

function CameraManager.Get(type)
  return cameras[type]
end

-- Met à jour le centrage et le zoom des caméras
-- en fonction de la taille de la fenêter
function CameraManager.OnWindowResize()
  for _, camera in pairs(cameras) do
    adaptToWindow(camera)
  end
end

return CameraManager
