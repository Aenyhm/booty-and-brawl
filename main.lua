local Services = require "toolbox.Services"

local Window = require "Window"

-- Afficher les prints dans la sortie console.
io.stdout:setvbuf("no")

-- Debugger VSCode
if pcall(require, "lldebugger") then
  require("lldebugger").start()
end

-- Pour avoir un scaling pixel-perfect
love.graphics.setDefaultFilter("nearest")

-- Enregistrement des services
Services.Register("AUDIO",  require "AudioManager")
Services.Register("CAMERA", require "CameraManager")
Services.Register("FONT",   require "FontManager")
Services.Register("SCENE",  require "SceneManager")

local AudioManager  = Services.Get("AUDIO")
local CameraManager = Services.Get("CAMERA")
local SceneManager  = Services.Get("SCENE")

function love.load()
  love.mouse.setVisible(false)

  -- /!\ L'ordre compte : il faut avoir défini la taille de fenêtre avant de pouvoir l'utiliser.
  Window.Init()
  CameraManager.Init()

  SceneManager.Init()
  SceneManager.GoTo("MENU")

  AudioManager.SetGlobalVolume(0.5)
end

function love.update(dt)
  SceneManager.Update(dt)
end

function love.draw()
  SceneManager.Draw()
end

function love.keypressed(key)
  SceneManager.OnKeyPressed(key)
end

function love.wheelmoved(x, y)
  SceneManager.OnMouseWheel(y)
end

function love.focus(focus)
  SceneManager.OnFocusChange(focus)
end

function love.resize(w, h)
  Window.size.x = w
  Window.size.y = h
  CameraManager.OnWindowResize()
end
