local GameState = {}

-- Si le joueur est dans une partie (commencée et non perdue).
GameState.isPlaying = false

GameState.Difficulties = {
  EASY = "easy",
  MEDIUM = "medium",
  HARD = "hard"
}
GameState.difficulty = GameState.Difficulties.HARD

return GameState
