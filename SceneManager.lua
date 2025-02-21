local SceneManager = {}

local Scenes = {
  MENU = require "MenuScene",
  GAME = require "gameplay.GameplayScene",
}

local currentScene

function SceneManager.GoTo(newSceneName)
  local newScene = Scenes[newSceneName]

  if newScene == nil then
    print(string.format("[ERROR] [SceneManager] Trying to go to unknown scene `%s`.", newSceneName))
    return
  elseif newScene == currentScene then
    print("[WARNING] [SceneManager] Trying to replace the current scene with the same one.")
    return
  end

  if currentScene then
    currentScene.nextScene = nil
    if currentScene.Exit then
      currentScene.Exit()
    end
  end

  currentScene = newScene

  if currentScene.Enter then
    currentScene.Enter()
  end
end

function SceneManager.Init()
  for _, scene in pairs(Scenes) do
    if scene.Init then
      scene.Init()
    end
  end
end

function SceneManager.Update(dt)
  if currentScene.Update then
    currentScene.Update(dt)
  end
end

function SceneManager.Draw()
  if currentScene.Draw then
    currentScene.Draw()
  end
end

function SceneManager.OnKeyPressed(key)
  if currentScene.OnKeyPressed then
    currentScene.OnKeyPressed(key)
  end
end

function SceneManager.OnMouseWheel(delta)
  if currentScene.OnMouseWheel then
    currentScene.OnMouseWheel(delta)
  end
end

function SceneManager.OnFocusChange(focus)
  if currentScene.OnFocusChange then
    currentScene.OnFocusChange(focus)
  end
end

return SceneManager
