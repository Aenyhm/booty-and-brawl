--[[
Les composants sont des structures dont les données sont liées pour le traitement
que l'on veut faire dessus. Par exemple, le composant `Health` contient une valeur
pour la santé max et une pour la santé actuelle.

On pourrait utiliser des tableaux, mais ça permet d'avoir des paramètres par défaut.
Par exemple, le composant `Transform` permet d'avoir pour toutes les entités un
angle à 0 par défaut et donc éviter de vérifier à chaque fois si elles en ont un.
--]]
local Vector2 = require "toolbox.Vector2"

local Components = {}

-- Pour chaque sprite, on crée un quad. Ce n'est nécessaire que pour
-- ceux qui ont une `startPos` ou une `size` différente de l'image
-- complète mais ça simplifie le traitement pour les dessiner et ça
-- évite de s'embêter à créer manuellement des Quad.
-- /!\ Ne pas créer de sprite dans love.update ou love.draw car la
-- création de Quads est une opération coûteuse.
--
-- L'`orientation` de l'image est utile lorsqu'on a besoin de la
-- tourner et de la déplacer, dans ce cas on spécifie un angle en
-- radian partant de 0 vers la droite (dans le sens horaire).
function Components.Sprite(image, startPos, size, orientation)
  startPos = startPos or Vector2.Zero()
  size = size or Vector2.new(image:getWidth(), image:getHeight())
  orientation = orientation or 0

  local sprite = {}
  sprite.image = image
  sprite.size = size
  sprite.quad = love.graphics.newQuad(startPos.x, startPos.y, size.x, size.y, image)
  sprite.orientation = orientation

  return sprite
end

function Components.Transform(position, angle)
  position = position or Vector2.Zero()
  angle = angle or 0

  return { position = position, angle = angle }
end

function Components.Health(maxValue, value)
  value = value or maxValue

  return { max = maxValue, value = value }
end

return Components
