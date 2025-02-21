local Color = require "toolbox.Color"
local Math = require "toolbox.Math"
local Renderer = require "toolbox.Renderer"
local Services = require "toolbox.Services"
local Vector2 = require "toolbox.Vector2"

local Colors = require "Colors"
local Controls = require "Controls"
local GameState = require "GameState"

local MenuScene = {}

local MenuStates = {
  HOME = "home",
  RESTART = "restart",
  NEW_GAME = "new_game",
  SETTINGS = "settings",
  COMMANDS = "commands",
  CREDITS = "credits",
  QUIT = "quit",
}
local state

local MAIN_TITLE_FONT = Services.Get("FONT").Get("MAIN", 64)
local TEXT_FONT = Services.Get("FONT").Get("MAIN", 32)
local SMALL_TEXT_FONT = Services.Get("FONT").Get("MAIN", 18)

local SECTION_TITLE_BORDER_PADDING = 4
local SECTION_TITLE_BORDER_ALPHA = 0.5

local music
local camera
local layoutY
local currentButtonIndex
local widgets = {}

local function hasWidgetAction(widget)
  return widget.action or widget.actionLeft or widget.actionRight
end

local function addWidget(widget)
  table.insert(widgets, widget)
  if hasWidgetAction(widget) and currentButtonIndex == 0 then
    currentButtonIndex = #widgets
  end
end

local function changeVolume(delta)
  local newVolume = Services.Get("AUDIO").GetGlobalVolume() + delta/10
  Services.Get("AUDIO").SetGlobalVolume(newVolume)
end

local function goToGame()
  Services.Get("SCENE").GoTo("GAME")
end

local function startNewGame(difficulty)
  GameState.difficulty = difficulty
  GameState.isPlaying = false
  goToGame()
end

local function setState(newState)
  state = newState
  currentButtonIndex = 0
end

function MenuScene.Init()
  camera = Services.Get("CAMERA").Get("UI")
  music = Services.Get("AUDIO").GetMusic("MENU")
end

function MenuScene.Enter()
  music:play()
  setState(MenuStates.HOME)
end

function MenuScene.Exit()
  music:stop()
end

function MenuScene.Update(dt)
  widgets = {}

  if state == MenuStates.HOME then
    if not GameState.isPlaying then
      addWidget({ label = "Nouvelle Partie", action = function () setState(MenuStates.NEW_GAME) end })
    else
      addWidget({ label = "Reprendre", action = goToGame })
      addWidget({ label = "Recommencer", action = function () setState(MenuStates.RESTART) end })
    end
    addWidget({ label = "Paramètres", action = function () setState(MenuStates.SETTINGS) end })
    addWidget({ label = "Commandes", action = function () setState(MenuStates.COMMANDS) end })
    addWidget({ label = "Crédits", action = function () setState(MenuStates.CREDITS) end })
    addWidget({ label = "Quitter", action = function () setState(MenuStates.QUIT) end })
  elseif state == MenuStates.RESTART then
    addWidget({ label = "Êtes-vous sûr de vouloir recommencer ?" })
    addWidget({ label = "Oui", action = function () setState(MenuStates.NEW_GAME) end })
    addWidget({ label = "Non", action = function () setState(MenuStates.HOME) end })
  elseif state == MenuStates.NEW_GAME then
    addWidget({ label = "Nouvelle Partie", title = true })
    addWidget({ label = "Facile", action = function () startNewGame(GameState.Difficulties.EASY) end })
    addWidget({ label = "Intermédiaire", action = function () startNewGame(GameState.Difficulties.MEDIUM) end })
    addWidget({ label = "Difficile", action = function () startNewGame(GameState.Difficulties.HARD) end })
    addWidget({ label = "" })
    addWidget({ label = "Retour", action = function () setState(MenuStates.HOME) end })
  elseif state == MenuStates.SETTINGS then
    addWidget({ label = "Paramètres", title = true })
    addWidget({
      alignLeft = true,
      label = string.format("Volume\t\t\t\t%u %%", Services.Get("AUDIO").GetGlobalVolume()*100),
      actionLeft = function () changeVolume(-1) end,
      actionRight = function () changeVolume(1) end,
    })
    addWidget({ label = "" })
    addWidget({ label = "Retour", action = function () setState(MenuStates.HOME) end })
  elseif state == MenuStates.COMMANDS then
    addWidget({ label = "Commandes", title = true })
    addWidget({ alignLeft = true, label = string.format("Avancer\t\t\t%s\t%s", string.upper(Controls.Keys.UP[1]), string.upper(Controls.Keys.UP[2])) })
    addWidget({ alignLeft = true, label = string.format("Freiner\t\t\t%s\t%s", string.upper(Controls.Keys.DOWN[1]), string.upper(Controls.Keys.DOWN[2])) })
    addWidget({ alignLeft = true, label = string.format("Gauche\t\t\t %s\t%s", string.upper(Controls.Keys.LEFT[1]), string.upper(Controls.Keys.LEFT[2])) })
    addWidget({ alignLeft = true, label = string.format("Droite\t\t\t %s\t%s", string.upper(Controls.Keys.RIGHT[1]), string.upper(Controls.Keys.RIGHT[2])) })
    addWidget({ alignLeft = true, label = string.format("Attaque gauche\t %s", string.upper(Controls.Keys.ATTACK_LEFT[1])) })
    addWidget({ alignLeft = true, label = string.format("Attaque droite\t %s", string.upper(Controls.Keys.ATTACK_RIGHT[1])) })
    addWidget({ label = "" })
    addWidget({ label = "Retour", action = function () setState(MenuStates.HOME) end })
  elseif state == MenuStates.CREDITS then
    addWidget({ label = "Crédits", title = true })
    addWidget({ label = "Graphismes : Fabien Siccard" })
    addWidget({ label = "Le reste : Fabien Nouaillat" })
    addWidget({ label = "Merci à Antoine Peillon pour ses idées sur le Game Design", small = true })
    addWidget({ label = "" })
    addWidget({ label = "Retour", action = function () setState(MenuStates.HOME) end })
  elseif state == MenuStates.QUIT then
    addWidget({ label = "Êtes-vous sûr de vouloir quitter ?" })
    addWidget({ label = "Oui", action = function () love.event.push("quit") end })
    addWidget({ label = "Non", action = function () setState(MenuStates.HOME) end })
  end
end

local function drawWidget(widget, current)
  local font = widget.small and SMALL_TEXT_FONT or TEXT_FONT
  local textWidth = widget.alignLeft and 450 or font:getWidth(widget.label)
  local position = Vector2.new((camera.size.x - textWidth)/2, layoutY)

  local color
  if current then
    color = Colors.MENU_ACTIVE
  elseif hasWidgetAction(widget) then
    color = Colors.MENU_BUTTON
  else
    color = Colors.MENU_TEXT
  end

  Renderer.DrawText(font, widget.label, position, color)

  if widget.title then
    local tileBorderColor = Color.Copy(color)
    tileBorderColor[4] = SECTION_TITLE_BORDER_ALPHA

    local positionTop = Vector2.new(
      position.x + textWidth,
      position.y - SECTION_TITLE_BORDER_PADDING
    )
    local sizeTop = Vector2.new(positionTop.x - textWidth, positionTop.y)
    Renderer.DrawLine(positionTop, sizeTop, tileBorderColor)

    local positionBottom = Vector2.new(
      position.x + textWidth,
      position.y + font:getHeight() + SECTION_TITLE_BORDER_PADDING
    )
    local sizeBottom = Vector2.new(positionBottom.x - textWidth, positionBottom.y)
    Renderer.DrawLine(positionBottom, sizeBottom, tileBorderColor)
  end

  if state == MenuStates.COMMANDS then
    layoutY = layoutY + font:getHeight()*1.2
  else
    layoutY = layoutY + font:getHeight()*2
  end
end

function MenuScene.Draw()
  camera:Begin()
    Renderer.DrawRectangle(Vector2.Zero(), camera.size, Colors.MENU_BG)

    local titleText = "Butin & Baston"
    local titleTextWidth = MAIN_TITLE_FONT:getWidth(titleText)
    local position = Vector2.new((camera.size.x - titleTextWidth)/2, 64)
    Renderer.DrawText(MAIN_TITLE_FONT, titleText, position, Colors.MENU_TITLE)

    layoutY = state == MenuStates.COMMANDS and camera.size.y/3.5 or camera.size.y/3

    for i, widget in ipairs(widgets) do
      drawWidget(widget, i == currentButtonIndex)
    end
  camera:End()
end

local function setNextButtonIndex(deltaIndex)
  for i = 1, #widgets do
    local index = currentButtonIndex + i*deltaIndex
    if index <= 0 then
      index = index + #widgets
    elseif index > #widgets then
      index = index - #widgets
    end
    local widget = widgets[index]
    if hasWidgetAction(widget) then
      currentButtonIndex = index
      return
    end
  end
end

function MenuScene.OnKeyPressed(key)
  if #widgets == 0 then return end -- Éviter de taper trop vite.

  if Controls.IsPressed(key, Controls.Keys.BACK) then
    if state ~= MenuStates.HOME then
      setState(MenuStates.HOME)
    else
      setState(MenuStates.QUIT)
    end
  elseif Controls.IsPressed(key, Controls.Keys.UP) then
    setNextButtonIndex(-1)
  elseif Controls.IsPressed(key, Controls.Keys.DOWN) then
    setNextButtonIndex(1)
  elseif Controls.IsPressed(key, Controls.Keys.VALIDATE) then
    widgets[currentButtonIndex].action()
  elseif Controls.IsPressed(key, Controls.Keys.LEFT) then
    if widgets[currentButtonIndex].actionLeft then
      widgets[currentButtonIndex].actionLeft()
    end
  elseif Controls.IsPressed(key, Controls.Keys.RIGHT) then
    if widgets[currentButtonIndex].actionRight then
      widgets[currentButtonIndex].actionRight()
    end
  end
end

return MenuScene
