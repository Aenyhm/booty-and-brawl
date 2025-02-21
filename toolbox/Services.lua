--[[
Service Locator
--]]

local Services = {}

local items = {}

function Services.Register(type, module)
  items[type] = module
end

function Services.Get(type)
  return items[type]
end

return Services
