local Controls = {}

Controls.Keys = {
  BACK  = { "escape" },
  VALIDATE = { "return" },
  DEBUG = { "f3" },

  UP    = { "z", "up" },
  DOWN  = { "s", "down" },
  LEFT  = { "q", "left" },
  RIGHT = { "d", "right" },

  ATTACK_LEFT  = { "a" },
  ATTACK_RIGHT = { "e" },
}

function Controls.IsPressed(keyPressed, command)
  local result = false

  for _, key in ipairs(command) do
    if keyPressed == key then
      result = true
      break
    end
  end

  return result
end

function Controls.IsDown(command)
  local result = false

  for _, key in ipairs(command) do
    if love.keyboard.isDown(key) then
      result = true
      break
    end
  end

  return result
end

return Controls
