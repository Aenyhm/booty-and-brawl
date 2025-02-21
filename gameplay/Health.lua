local Health = {}

function Health.GetRatio(health)
  return health.value/health.max
end

function Health.Hurt(e, damagePoints)
  if e.health then
    e.health.value = math.max(0, e.health.value - e.damagePoints)
  end
end

return Health
