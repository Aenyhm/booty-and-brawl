local Vector2 = require "toolbox.Vector2"

local Window = {}
Window.ASPECT_RATIO = 4/3

Window.TILE_SIDE = 32
Window.TILE_SIZE = Window.TILE_SIDE*Vector2.One()
Window.TILE_CENTER = Window.TILE_SIZE/2

local HEIGHT_RATIO = 0.8 -- Remplissage de l'écran en hauteur

-- Calcule les dimensions et la position de la fenêtre de jeu par rapport à l'écran.
--
-- Au lieu de mettre un taille de fenêtre en dur, je préfère passer par un pourcentage d'écran
-- utilisé pour dimensionner la fenêtre de jeu par défaut : car autant une fenêtre de 800x600
-- sur un écran HD est correcte, autant sur un écran 4K elle est peu visible. LÖVE a bien une
-- fonction pour connaitre le DPI, mais elle retourne tout le temps 1.
function Window.Init()
  local width, height, flags = love.window.getMode()

  Window.size = Vector2.new(width, height)

  local monitorWidth, monitorHeight = love.window.getDesktopDimensions(flags.display)
  local monitorSize = Vector2.new(monitorWidth, monitorHeight)

  Window.size.y = HEIGHT_RATIO*monitorSize.y
  Window.size.x = Window.size.y*Window.ASPECT_RATIO

  local windowPosition = (monitorSize - Window.size)/2

  love.window.setMode(Window.size.x, Window.size.y, flags)
  love.window.setPosition(windowPosition.x, windowPosition.y, flags.display)
end

return Window
