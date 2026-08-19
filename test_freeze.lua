local GameStateData = require("src.engine.game_state_init")()
_G.GameStateData = GameStateData
_G.GAME_MODE = "franchise"
_G.STAKE_TIER = "white"

local FranchiseTeams = require("src.data.franchise_teams")
local PlaybookExpanded = require("src.data.playbook_expanded")

GameStateData.init({
    team = FranchiseTeams[1],
    archetype = PlaybookExpanded.generateFullPlaybook(),
    stakeTier = "white"
})

local DeckManager = require("src.engine.deck_manager")
DeckManager.init("shanahan_wide_zone")
DeckManager.drawHand()

local StateGame = require("src.states.state_game")
print("calling enter")
StateGame:enter()
print("enter complete")
