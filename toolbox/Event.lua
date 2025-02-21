--[[
Système d'évènement inspiré de C#.

NOTE: Je l'ai créé pour éviter un couplage fort entre mes modules.
--]]

local Event = {}
local mt = { __index = Event }

function Event.new(label)
  local obj = {}
  obj.label = label
  obj.listeners = {}

  return setmetatable(obj, mt)
end

function Event:Add(listener)
  table.insert(self.listeners, listener)
end

function Event:Remove(listener)
  for i = 1, #self.listeners do
    if self.listeners[i] == listener then
      table.remove(self.listeners, i)
      break
    end
  end
end

function mt.__call(evt, args)
  if evt.label then
    print(string.format("[Event] %s:", evt.label), args)
  end
  for _, listener in ipairs(evt.listeners) do
    listener(args)
  end
end

return Event
