local Color = {}

function Color.new(r, g, b, a)
  a = a or 1

  return { r, g, b, a }
end

-- Copie une couleur pour faire des traitements dessus
-- (comme changer l'alpha) sans affecter la couleur d'origine.
function Color.Copy(color)
  return Color.new(color[1], color[2], color[3], color[4])
end

-- Crée une couleur depuis un format RGBA (ex: 255, 120, 14).
function Color.FromBytes(rb, gb, bb, ab)
  return Color.new(love.math.colorFromBytes(rb, gb, bb, ab))
end

-- Crée une couleur depuis un format héxadécimal (ex: "#336699cc").
function Color.FromString(s)
  local rb = tonumber(string.sub(s, 2, 3), 16)
	local gb = tonumber(string.sub(s, 4, 5), 16)
	local bb = tonumber(string.sub(s, 6, 7), 16)
	local ab = tonumber(string.sub(s, 8, 9), 16) or nil

  return Color.FromBytes(rb, gb, bb, ab)
end

return Color
