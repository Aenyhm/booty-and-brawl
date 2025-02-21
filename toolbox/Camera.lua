--[[
Module inspiré par Raylib : https://github.com/raysan5/raylib/blob/master/src/rcore.c#L1551

Une caméra permet de :
- transformer dynamiquement l’affichage de la scène (déplacement, zoom)
- suivre une entité
- centrer la vue sur une région spécifique

Différences avec love.graphics.Canvas :

Un Canvas est utilisé pour un rendu offscreen, ce qui permet de :
- faire du post-traitement (peut être passé à un shader pour appliquer
  des effets comme du flou, des filtres de couleur ou des distorsions)
- gérer plusieurs layers (ex: background, foreground, interface utilisateur).

/!\ Un Canvas consomme plus de mémoire GPU. À utiliser quand on peut regrouper des images fixes.

Exemple d'utilisation :

  -- Centrer l'origine de la caméra (par défaut en haut à gauche)
  gameCamera.offset = Vector2.new(windowWidth, windowHeight)/2

  -- Zoomer (1 par défaut, dézoomer avec une valeur entre 0 et 1)
  uiCamera.zoom = 2.5

  -- Suivre le personnage
  gameCamera.target = character.position

  -- Dessiner la scène
  function love.draw()
    gameCamera:Begin()
      drawGame()
    gameCamera:End()

    uiCamera:Begin()
      drawUi()
    uiCamera:End()
  end
--]]
local Vector2 = require "toolbox.Vector2"

local Camera = {}
local mt = { __index = Camera }

function Camera.new(target, offset, zoom)
  local obj = {}
  obj.target = target or Vector2.Zero()
  obj.offset = offset or Vector2.Zero()
  obj.zoom = zoom or 1.0

  return setmetatable(obj, mt)
end

function Camera:Begin()
  love.graphics.push()

  -- On se place sur l'offset choisi
  love.graphics.translate(self.offset.x, self.offset.y)

  -- On applique le zoom
  love.graphics.scale(self.zoom)

  -- On se recale sur la position cible
  love.graphics.translate(-self.target.x, -self.target.y)
end

function Camera:End()
  love.graphics.pop()
end

return Camera
