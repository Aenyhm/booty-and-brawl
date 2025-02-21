local Color = require "toolbox.Color"
local Math = require "toolbox.Math"
local Renderer = require "toolbox.Renderer"
local Services = require "toolbox.Services"
local Vector2 = require "toolbox.Vector2"

local Components = require "gameplay.Components"
local Player = require "gameplay.Player"

local Colors = require "Colors"

local EndGame = {}

local FONT = Services.Get("FONT").Get("END", 32)

local VictoryDisplay = {
  SPRITE = Components.Sprite(love.graphics.newImage("assets/images/Coffre.png")),
  TEXT = "V i c t o i r e",
  TEXT_COLOR = Colors.END_VICTORY_TEXT
}
local DefeatDisplay = {
  SPRITE = Components.Sprite(love.graphics.newImage("assets/images/Crane2.png")),
  TEXT = "P e r d u",
  TEXT_COLOR = Colors.END_DEFEAT_TEXT
}

-- en secondes
local BG_FADE_DURATION = 4.0
local FG_FADE_DURATION = 1.5
local WAIT_DURATION = 0.7

EndGame.States = {
  FADING_BG = "fading_bg",
  FADING_FG = "fading_fg",
  WAIT      = "wait",
  FINISHED  = "finished"
}
EndGame.state = nil

local camera
local bgFadeElapsed
local fgFadeElapsed
local waitElapsed

function EndGame.Init()
  camera = Services.Get("CAMERA").Get("UI")
  bgFadeElapsed = 0
  fgFadeElapsed = 0
  waitElapsed = 0
  EndGame.state = EndGame.States.FADING_BG
end

function EndGame.Update(dt)
  if EndGame.state == EndGame.States.FADING_BG then
    bgFadeElapsed = bgFadeElapsed + dt
    if bgFadeElapsed >= BG_FADE_DURATION then
      bgFadeElapsed = BG_FADE_DURATION
      EndGame.state = EndGame.States.FADING_FG
    end
  elseif EndGame.state == EndGame.States.FADING_FG then
    fgFadeElapsed = fgFadeElapsed + dt
    if fgFadeElapsed >= FG_FADE_DURATION then
      fgFadeElapsed = FG_FADE_DURATION
      EndGame.state = EndGame.States.WAIT
    end
  elseif EndGame.state == EndGame.States.WAIT then
    waitElapsed = waitElapsed + dt
    if waitElapsed >= WAIT_DURATION then
      EndGame.state = EndGame.States.FINISHED
    end
  end
end

function EndGame.Draw()
  local bgAlpha = math.max(0, bgFadeElapsed/BG_FADE_DURATION)
  local bgColor = Color.Copy(Colors.MENU_BG)
  bgColor[4] = bgAlpha
  Renderer.DrawRectangle(Vector2.Zero(), camera.size, bgColor)

  local fgAlpha = 1 - math.min(fgFadeElapsed/FG_FADE_DURATION, 1)
  local imageColor = Color.new(1, 1, 1, fgAlpha)

  -- Défaite > Victoire en cas de match nul
  local victory = not Player.GetEntity().dead

  local display = victory and VictoryDisplay or DefeatDisplay

  Renderer.DrawTexture(
    display.SPRITE.image,
    nil,
    camera.size/2,
    display.SPRITE.size/2,
    0,
    imageColor,
    1 + Math.EaseOutQuart(bgAlpha)*1.5
  )

  local textSize = Vector2.new(FONT:getWidth(display.TEXT), FONT:getHeight())
  local textColor = Color.Copy(display.TEXT_COLOR)
  textColor[4] = fgAlpha
  local origin = (camera.size - textSize)/2
  origin.y = origin.y + display.SPRITE.size.y*2
  Renderer.DrawText(FONT, display.TEXT, origin, textColor)
end

return EndGame
