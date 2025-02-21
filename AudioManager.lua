local Math = require "toolbox.Math"

local AudioManager = {}

local musics = {
  MENU = love.audio.newSource("assets/music/pirates.mp3", "stream"),
}

-- On duplique les sons pour pouvoir en jouer plusieurs en même temps.
local sounds = {
  CANNON_SHOOT = function()
    local sound = love.audio.newSource("assets/sounds/CannonShoot.mp3", "static")
    sound:setVolume(0.4)
    return sound
  end,
  BOAT_HIT = function()
    local sound = love.audio.newSource("assets/sounds/BoatHit.mp3", "static")
    sound:setVolume(0.25)
    return sound
  end,
  CANNONBALL_SINK = function()
    local sound = love.audio.newSource("assets/sounds/CannonballSink.mp3", "static")
    sound:setVolume(0.5)
    return sound
  end,
}

function AudioManager.GetGlobalVolume()
  local rawVolume = love.audio.getVolume()

  -- Sûrement à cause des problèmes de précision avec les nombres à virgules,
  -- LÖVE nous renvoie des fois des valeurs comme 0.60000002384186 au lieu de 0.6.

  -- Arrondit au multiple de 0.1
  local cleanVolume = math.floor(rawVolume*10 + 0.5)/10

  return cleanVolume
end

function AudioManager.SetGlobalVolume(volume)
  local cleanVolume = Math.Clamp(volume, 0, 1)
  love.audio.setVolume(cleanVolume)
end

function AudioManager.GetMusic(type)
  return musics[type]
end

function AudioManager.GetSound(type)
  return sounds[type]()
end

return AudioManager
