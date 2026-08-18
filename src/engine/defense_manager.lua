-- src/engine/defense_manager.lua
local DefensiveSchemes = require("src.data.defensive_schemes")

local DefenseManager = {}

DefenseManager.plays = {
    { id = "Blitz", hint = "The defense is crowding the box, showing pressure...", counter = "Deep Pass", strongAgainst = "Run" },
    { id = "Cover 2", hint = "The safeties are splitting high and wide...", counter = "Run", strongAgainst = "Deep Pass" },
    { id = "Prevent", hint = "The defense is dropping everyone deep...", counter = "Short Pass", strongAgainst = "Deep Pass" },
    { id = "Run Stuff", hint = "The defensive line is shifting aggressively...", counter = "Play Action", strongAgainst = "Run" }
}

function DefenseManager.init()
    DefenseManager.proDefenses = {}
    DefenseManager.legendaryDefenses = {}
    
    for _, scheme in ipairs(DefensiveSchemes) do
        if scheme.type == "standard" then
            table.insert(DefenseManager.proDefenses, scheme)
        elseif scheme.type == "boss" then
            table.insert(DefenseManager.legendaryDefenses, scheme)
        end
    end
    
    DefenseManager.activeBlind = nil -- kept as activeBlind internally for compatibility
    DefenseManager.currentPlay = nil
end

function DefenseManager.setNextBlind(defenseType, gameState)
    if defenseType == "standard" then
        local idx = math.random(#DefenseManager.proDefenses)
        DefenseManager.activeBlind = DefenseManager.proDefenses[idx]
    elseif defenseType == "boss" then
        local idx = math.random(#DefenseManager.legendaryDefenses)
        DefenseManager.activeBlind = DefenseManager.legendaryDefenses[idx]
    end
    -- Fire onActivate if the blind has a special startup effect
    if DefenseManager.activeBlind and DefenseManager.activeBlind.onActivate then
        local gs = gameState or (pcall(function() return require("src.engine.game_state") end) and require("src.engine.game_state") or nil)
        pcall(DefenseManager.activeBlind.onActivate, gs)
    end
end

function DefenseManager.callDefensivePlay()
    local idx = math.random(#DefenseManager.plays)
    DefenseManager.currentPlay = DefenseManager.plays[idx]
end

function DefenseManager.evaluatePlay(playType, chips, mult)
    local variance = math.random() * 0.4 + 0.8 -- 0.8x to 1.2x
    local rpsModifier = 1.0
    local chipsPenalty = 0
    
    if DefenseManager.currentPlay then
        if playType == DefenseManager.currentPlay.counter then
            rpsModifier = 1.5 -- 50% bonus
        elseif playType == DefenseManager.currentPlay.strongAgainst then
            rpsModifier = 0.3 -- Heavy multiplier penalty
            chipsPenalty = 22 -- Yards loss base penalty
        end
    end
    
    local modifiedChips = (chips - chipsPenalty) * variance
    local modifiedMult = mult * rpsModifier
    
    if DefenseManager.activeBlind then
        modifiedChips, modifiedMult = DefenseManager.activeBlind.evaluate(playType, modifiedChips, modifiedMult)
    end
    
    return math.floor(modifiedChips), modifiedMult
end

return DefenseManager
