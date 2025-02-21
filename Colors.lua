local Color =  require "toolbox.Color"

local Colors = {}

Colors.BLACK  = Color.new(0, 0, 0)
Colors.WHITE  = Color.new(1, 1, 1)
Colors.RED    = Color.new(1, 0, 0)
Colors.YELLOW = Color.new(1, 1, 0)

Colors.MENU_BG     = Color.FromString("#111111")
Colors.MENU_TITLE  = Color.FromString("#ddbb00")
Colors.MENU_TEXT   = Color.FromString("#999999")
Colors.MENU_BUTTON = Color.FromString("#ffffff")
Colors.MENU_ACTIVE = Color.FromString("#11ccff")

Colors.GAME_DEEP_WATER = Color.FromString("#024f66")

Colors.ENEMY_TINT = Color.new(.3, .3, .3)
Colors.ENEMY_HEALTH_BG = Color.new(.7, .7, .7)
Colors.ENEMY_HEALTH_FG = Color.new(.7, .2, .2)

Colors.END_VICTORY_TEXT = Colors.MENU_TITLE
Colors.END_DEFEAT_TEXT  = Color.FromString("#6d1b1b")

Colors.DEBUG_GRID             = Color.FromString("#ffffff22")
Colors.DEBUG_SPAWN            = Color.FromString("#50ed9eaa")
Colors.DEBUG_CANNON           = Color.FromString("#0502d166")
Colors.DEBUG_HITBOX           = Color.FromString("#d1080288")
Colors.DEBUG_SIGHT_RANGE      = Color.FromString("#00ffffff")
Colors.DEBUG_CANNONBALL_RANGE = Color.FromString("#ff00ffff")
Colors.DEBUG_STATE            = Color.FromString("#dddd33ff")

return Colors
