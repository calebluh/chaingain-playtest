-- src/engine/bot_runner.lua
local GameStateData = require("src.engine.game_state")
local DeckManager = require("src.engine.deck_manager")
local DefenseManager = require("src.engine.defense_manager")
local PlayerCard = require("src.entities.player_card")
local SaveManager = require("src.engine.save_manager")
local SoundManager = require("src.engine.sound_manager")

local BotRunner = {}

BotRunner.active = false
BotRunner.visualAutoPlay = false
BotRunner.autoPlayTimer = 0
BotRunner.logs = {
    totalRuns = 0,
    wins = 0,
    losses = 0,
    crashes = {},
    avgYardsPerPlay = 0,
    totalPlaysCalled = 0,
    totalYardsGenerated = 0
}

function BotRunner.runHeadlessSimulation(runsToSimulate)
    runsToSimulate = runsToSimulate or 1000
    
    BotRunner.logs = {
        totalRuns = runsToSimulate,
        wins = 0,
        losses = 0,
        fieldGoals = 0,
        fumbles = 0,
        interceptions = 0,
        trueTurnovers = 0,
        crashes = {},
        avgYardsPerPlay = 0,
        totalPlaysCalled = 0,
        totalYardsGenerated = 0
    }
    
    local ScoringEvaluator = require("src.engine.scoring_evaluator")
    
    for run = 1, runsToSimulate do
        local ok, err = pcall(function()
            if BotRunner.testConfig then
                GameStateData.init(BotRunner.testConfig)
            else
                GameStateData.init({ stake = "starter" })
            end
            DeckManager.init()
            DeckManager.drawHand()
            
            local maxSteps = 200
            local step = 0
            
            while GameStateData.status == "PLAYING" and step < maxSteps do
                step = step + 1
                
                if GameStateData.down == 4 and GameStateData.yardLine >= 65 then
                    GameStateData.kickFieldGoal()
                    BotRunner.logs.fieldGoals = BotRunner.logs.fieldGoals + 1
                elseif #DeckManager.hand > 0 then
                    local bestPlayIdx = 1
                    local bestScore = -999
                    for i, p in ipairs(DeckManager.hand) do
                        local score = 0
                        if GameStateData.distance > 5 and p.type:match("Pass") then score = score + 10 end
                        if GameStateData.distance <= 5 and p.type == "Run" then score = score + 10 end
                        if score > bestScore then
                            bestScore = score
                            bestPlayIdx = i
                        end
                    end
                    
                    local play = DeckManager.hand[bestPlayIdx]
                    table.remove(DeckManager.hand, bestPlayIdx)
                    
                    local baseChips = play.baseChips
                    local baseMult = play.baseMult
                    local rosterChips, rosterMult = 0, 0
                    
                    if GameStateData.rosterSlots then
                        for posName, posData in pairs(GameStateData.rosterSlots) do
                            for _, player in ipairs(posData.cards) do
                                local c, m = player:evaluatePlay(play, GameStateData)
                                rosterChips = rosterChips + c
                                rosterMult = rosterMult + m
                            end
                        end
                    end
                    
                    local tChips = baseChips + rosterChips
                    local tMult = baseMult + rosterMult
                    
                    DefenseManager.callDefensivePlay()
                    tChips, tMult = DefenseManager.evaluatePlay(play.type, tChips, tMult)
                    tMult = math.max(0.1, tMult)
                    
                    local riskPct, tType = ScoringEvaluator.calculateTurnoverRisk(play, GameStateData)
                    local isTurnover = (math.random(100) <= riskPct)
                    
                    if isTurnover then
                        if tType == "INT" then BotRunner.logs.interceptions = BotRunner.logs.interceptions + 1
                        else BotRunner.logs.fumbles = BotRunner.logs.fumbles + 1 end
                        
                        -- Recovery Minigame Simulation (1 in 3 chance to guess correctly)
                        if math.random(1, 3) == 1 then
                            -- Got it back! Restore down and distance (reset downs for bot simplicity)
                            GameStateData.down = 1
                            GameStateData.distance = 10
                        else
                            -- True Turnover!
                            BotRunner.logs.trueTurnovers = BotRunner.logs.trueTurnovers + 1
                            GameStateData.status = "TURNOVER"
                        end
                    else
                        local zoneScale = 1.0
                        if GameStateData.yardLine >= 80 then zoneScale = 0.55
                        elseif GameStateData.yardLine >= 50 then zoneScale = 0.85 end
                        
                        local yards = math.floor(tChips * tMult * zoneScale)
                        BotRunner.logs.totalPlaysCalled = BotRunner.logs.totalPlaysCalled + 1
                        BotRunner.logs.totalYardsGenerated = BotRunner.logs.totalYardsGenerated + yards
                        
                        GameStateData.totalYardsGained = GameStateData.totalYardsGained + yards
                        GameStateData.yardLine = GameStateData.yardLine + yards
                        
                        if GameStateData.totalYardsGained >= GameStateData.distance then
                            GameStateData.down = 1
                            GameStateData.distance = 10
                            GameStateData.totalYardsGained = 0
                        else
                            GameStateData.down = GameStateData.down + 1
                            GameStateData.distance = GameStateData.distance - yards
                        end
                        
                        if GameStateData.yardLine >= 100 then
                            GameStateData.status = "TOUCHDOWN"
                        elseif GameStateData.down > 4 then
                            GameStateData.status = "TURNOVER"
                        end
                    end
                    
                    DeckManager.fillHand()
                end
            end
            
            if GameStateData.status == "TOUCHDOWN" then
                BotRunner.logs.wins = BotRunner.logs.wins + 1
            elseif GameStateData.status == "TURNOVER" then
                BotRunner.logs.losses = BotRunner.logs.losses + 1
            end
        end)
        
        if not ok then
            table.insert(BotRunner.logs.crashes, { run = run, error = tostring(err) })
        end
    end
    
    if BotRunner.logs.totalPlaysCalled > 0 then
        BotRunner.logs.avgYardsPerPlay = math.floor(BotRunner.logs.totalYardsGenerated / BotRunner.logs.totalPlaysCalled)
    end
    
    return BotRunner.logs
end

function BotRunner.updateVisualAutoPlay(dt)
    if not BotRunner.visualAutoPlay then return end
    
    BotRunner.autoPlayTimer = BotRunner.autoPlayTimer - dt
    if BotRunner.autoPlayTimer <= 0 then
        BotRunner.autoPlayTimer = 0.08
        
        local StateManager = require("src.states.state_manager")
        local activeState = StateManager.activeState
        
        if activeState == require("src.states.state_game") then
            if GameStateData.status == "PLAYING" then
                if GameStateData.down == 4 and GameStateData.yardLine >= 65 then
                    GameStateData.kickFieldGoal()
                elseif #DeckManager.hand > 0 then
                    local bestPlayIdx = 1
                    local bestScore = -999
                    for i, p in ipairs(DeckManager.hand) do
                        local score = 0
                        if GameStateData.distance > 5 and p.type:match("Pass") then score = score + 10 end
                        if GameStateData.distance <= 5 and p.type == "Run" then score = score + 10 end
                        if score > bestScore then
                            bestScore = score
                            bestPlayIdx = i
                        end
                    end
                    activeState.selectedPlayIndex = bestPlayIdx
                    activeState:callPlay()
                end
            elseif GameStateData.status == "TOUCHDOWN" or GameStateData.status == "GAME_WON" then
                local StateShop = require("src.states.state_shop")
                StateManager.switch(StateShop)
            elseif GameStateData.status == "TURNOVER" then
                GameStateData.init(GameStateData.config)
                DeckManager.drawHand()
            end
        elseif activeState == require("src.states.state_shop") then
            if GameStateData.capCash >= 5 then
                activeState:buyItem(1)
            elseif GameStateData.capCash >= 4 then
                activeState:buyItem(2)
            else
                local StateGame = require("src.states.state_game")
                GameStateData.nextRound("standard")
                DeckManager.drawHand()
                StateManager.switch(StateGame)
            end
        elseif activeState == require("src.states.state_menu") then
            local StateGame = require("src.states.state_game")
            GameStateData.init()
            DeckManager.drawHand()
            StateManager.switch(StateGame)
        end
    end
end

return BotRunner
