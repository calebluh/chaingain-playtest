-- src/engine/scoring_evaluator.lua
local SoundManager = require("src.engine.sound_manager")
local FxManager = require("src.engine.fx_manager")
local DefenseManager = require("src.engine.defense_manager")
local SaveManager = require("src.engine.save_manager")
local Loc = require("src.engine.loc_manager")

local ScoringEvaluator = {}

ScoringEvaluator.active = false
ScoringEvaluator.phase = 0
ScoringEvaluator.timer = 0
ScoringEvaluator.playCard = nil
ScoringEvaluator.gameState = nil
ScoringEvaluator.rosterQueue = {}
ScoringEvaluator.currentRosterIdx = 0
ScoringEvaluator.currentChips = 0
ScoringEvaluator.currentMult = 0
ScoringEvaluator.displayedChips = 0
ScoringEvaluator.displayedMult = 0

function ScoringEvaluator.start(playCard, gameState, isTurnover, turnoverType)
    ScoringEvaluator.active = true
    ScoringEvaluator.phase = 1
    ScoringEvaluator.timer = 0.35
    ScoringEvaluator.playCard = playCard
    ScoringEvaluator.gameState = gameState
    ScoringEvaluator.isTurnover = isTurnover
    ScoringEvaluator.turnoverType = turnoverType
    
    local chips = playCard.baseChips
    local mult = playCard.baseMult
    
    if playCard.enhancement == "Glass" then
        mult = mult * 2.0
        FxManager.addFloatingText("GLASS! x2.0 MTM", 480, 180, 0.8, 1, 1, 1.5)
    elseif playCard.enhancement == "Stone" then
        chips = chips + 8
        mult = 0.0
        FxManager.addFloatingText("STONE! +8 YDS", 480, 180, 0.6, 0.6, 0.6, 1.5)
    end
    
    if gameState then
        if gameState.passBonus and (playCard.type == "Run" or playCard.type == "Short Pass") then
            chips = chips + gameState.passBonus
            FxManager.addFloatingText("SPEED DEMONS! +" .. gameState.passBonus .. " YDS", 480, 140, 0, 0.75, 0.75, 1.2)
        end
        if gameState.playActionBonus and playCard.type == "Play Action" then
            chips = chips + gameState.playActionBonus
            FxManager.addFloatingText("GOLDEN PLAY ACTION! +" .. gameState.playActionBonus .. " YDS", 480, 140, 0.9, 0.75, 0.2, 1.2)
        end
        if gameState.teamMultBonus then
            mult = mult + gameState.teamMultBonus
            FxManager.addFloatingText("BLIZZARD BOOST! +" .. string.format("%.1f", gameState.teamMultBonus) .. " MTM", 480, 140, 0, 0.35, 0.85, 1.2)
        end
    end
    
    if gameState and gameState.stakeTier == "purple" then
        chips = math.floor(chips * 0.90) -- Purple Stake: -10% Base Yards
    end
    
    if playCard.seal == "Red" then
        chips = chips + playCard.baseChips
        mult = mult + playCard.baseMult
        FxManager.addFloatingText("RED DECAL! RETRIGGER!", 480, 120, 1.0, 0.2, 0.2, 1.5)
    end
    
    if playCard.seal == "Gold" then
        if gameState then
            gameState.capCash = (gameState.capCash or 0) + 3
            FxManager.addFloatingText("GOLD DECAL! +$3", 480, 120, 1.0, 0.84, 0.0, 1.5)
            SoundManager.playSFX("coin")
        end
    end
    
    local DeckManager = require("src.engine.deck_manager")
    if DeckManager.hand then
        for _, card in ipairs(DeckManager.hand) do
            if card.enhancement == "Steel" and card ~= playCard then
                mult = mult + 1.5
                FxManager.addFloatingText("STEEL PASSIVE! +1.5 MTM", 480, 150, 0.7, 0.7, 0.8, 1.3)
                SoundManager.playSFX("coin")
            end
        end
    end
    
    ScoringEvaluator.currentChips = chips
    ScoringEvaluator.currentMult = mult
    ScoringEvaluator.displayedChips = chips
    ScoringEvaluator.displayedMult = mult
    
    ScoringEvaluator.rosterQueue = {}
    local drawOrder = {"QB", "RB", "WR1", "WR2", "FLEX"}
    if gameState.rosterSlots then
        for _, pos in ipairs(drawOrder) do
            local posData = gameState.rosterSlots[pos]
            if posData then
                for _, player in ipairs(posData.cards) do
                    table.insert(ScoringEvaluator.rosterQueue, { player = player, pos = pos })
                end
            end
        end
    end
    
    ScoringEvaluator.currentRosterIdx = 0
    SoundManager.playSFX("whistle")
end

function ScoringEvaluator.update(dt)
    if not ScoringEvaluator.active then return end
    
    local PhysicsUtils = require("src.engine.physics_utils")
    ScoringEvaluator.displayedChips = PhysicsUtils.lerp(ScoringEvaluator.displayedChips, ScoringEvaluator.currentChips, dt * 8)
    ScoringEvaluator.displayedMult = PhysicsUtils.lerp(ScoringEvaluator.displayedMult, ScoringEvaluator.currentMult, dt * 8)
    
    if ScoringEvaluator.phase == 4.5 then
        local FieldAnimator = require("src.ui.field_animator")
        FieldAnimator.update(dt)
        if FieldAnimator.completed then
            ScoringEvaluator.phase = 5
            ScoringEvaluator.timer = 0.2
            ScoringEvaluator.finalizeDriveSlam()
        end
        return
    end
    
    ScoringEvaluator.timer = ScoringEvaluator.timer - dt
    if ScoringEvaluator.timer <= 0 then
        if ScoringEvaluator.phase == 1 then
            ScoringEvaluator.phase = 2
            ScoringEvaluator.timer = 0.3
            SoundManager.playSFX("click")
            FxManager.addFloatingText("BASE: " .. ScoringEvaluator.currentChips .. " YDS x " .. string.format("%.1f", ScoringEvaluator.currentMult) .. " MTM", 480, 240, 0.2, 0.8, 1, 1.6)
            
        elseif ScoringEvaluator.phase == 2 then
            ScoringEvaluator.phase = 3
            ScoringEvaluator.currentRosterIdx = 1
            ScoringEvaluator.timer = 0.20
            ScoringEvaluator.evaluateCurrentRosterPlayer()
            
        elseif ScoringEvaluator.phase == 3 then
            ScoringEvaluator.currentRosterIdx = ScoringEvaluator.currentRosterIdx + 1
            if ScoringEvaluator.currentRosterIdx <= #ScoringEvaluator.rosterQueue then
                ScoringEvaluator.timer = 0.20
                ScoringEvaluator.evaluateCurrentRosterPlayer()
            else
                ScoringEvaluator.phase = 4
                ScoringEvaluator.timer = 0.35
                ScoringEvaluator.evaluateDefenseCounter()
            end
            
        elseif ScoringEvaluator.phase == 4 then
            ScoringEvaluator.phase = 4.5
            
            -- Predict yards gained for the animation
            local gs = ScoringEvaluator.gameState
            local totalMult = math.max(0.1, ScoringEvaluator.currentMult + (gs.tempMultBoost or 0))
            local zoneScale = 1.0
            if gs.yardLine >= 80 then
                if not gs.ignoreRedZonePenalty then
                    zoneScale = (gs.stakeTier == "gold") and 0.45 or 0.55
                end
            elseif gs.yardLine >= 50 then
                zoneScale = 0.85
            end
            
            local rawYards = ScoringEvaluator.currentChips * totalMult * zoneScale
            local predictedYards = 0
            if ScoringEvaluator.playCard.type == "Run" then
                predictedYards = math.floor(math.min(25, 3 + rawYards * 0.4))
            else
                predictedYards = math.floor(math.min(80, 5 + rawYards * 0.35))
            end
            local DefenseManager = require("src.engine.defense_manager")
            if DefenseManager.activeBlind and DefenseManager.activeBlind.id == "blitz_heavy" and ScoringEvaluator.playCard.type == "Play Action" then
                predictedYards = predictedYards - 3
            end
            
            if gs.weather == "snow" and not ScoringEvaluator.playCard.type:match("Pass") then
                predictedYards = math.floor(predictedYards * 0.9)
            end
            
            if gs.weather == "rain" and ScoringEvaluator.playCard.type:match("Pass") and math.random() < 0.15 then
                predictedYards = -5
            end
            
            local isIntercepted = ScoringEvaluator.isTurnover and (ScoringEvaluator.turnoverType == "INT")
            local isFumbled = ScoringEvaluator.isTurnover and (ScoringEvaluator.turnoverType == "FUMBLE")
            local FieldAnimator = require("src.ui.field_animator")
            FieldAnimator.startPlay(ScoringEvaluator.playCard.type, predictedYards, gs.yardLine, gs.distance, isIntercepted, isFumbled)
        end
    end
end

function ScoringEvaluator.evaluateCurrentRosterPlayer()
    local item = ScoringEvaluator.rosterQueue[ScoringEvaluator.currentRosterIdx]
    if not item then return end
    
    local player = item.player
    player.jumpY = -14
    
    local isDebuffed = false
    if DefenseManager.activeBlind and DefenseManager.activeBlind.id == "no_fly_zone" then
        if item.pos:match("WR") or item.pos:match("TE") or player.position:match("WR") or player.position:match("TE") then
            isDebuffed = true
        end
    end
    
    local chipBonus, multBonus = 0, 0
    if isDebuffed then
        FxManager.addFloatingText("NO-FLY ZONE: DEBUFFED!", 480, 200, 1, 0.2, 0.2, 1.2)
        SoundManager.playSFX("tackle")
    else
        chipBonus, multBonus = player:evaluatePlay(ScoringEvaluator.playCard, ScoringEvaluator.gameState)
    end
    
    if DefenseManager.activeBlind and DefenseManager.activeBlind.id == "ironclad_front" and ScoringEvaluator.gameState and (ScoringEvaluator.gameState.down == 3 or ScoringEvaluator.gameState.down == 4) then
        chipBonus = 0
        FxManager.addFloatingText("IRONCLAD FRONT: YARDS NEGATED!", 480, 220, 1, 0.2, 0.2, 1.2)
    end
    
    if player.edition == "Foil" then chipBonus = chipBonus + 5
    elseif player.edition == "Holographic" then multBonus = multBonus + 1.0 end
    
    if ScoringEvaluator.gameState and ScoringEvaluator.gameState.globalRosterChips then
        chipBonus = chipBonus + ScoringEvaluator.gameState.globalRosterChips
    end

    if _G.GAME_MODE == "roguelite" and ScoringEvaluator.currentRosterIdx == 2 then
        local MyPlayerProfile = require("src.data.myplayer_profile")
        if MyPlayerProfile.hasNode("cmd_4") then
            chipBonus = chipBonus * 2
            multBonus = multBonus * 2
        end
    end

    if player.equippedBadges then
        for _, b in ipairs(player.equippedBadges) do
            if b.id == "captains_badge" then
                local prevItem = ScoringEvaluator.rosterQueue[ScoringEvaluator.currentRosterIdx - 1]
                local nextItem = ScoringEvaluator.rosterQueue[ScoringEvaluator.currentRosterIdx + 1]
                if prevItem then chipBonus = chipBonus + 2 end
                if nextItem then chipBonus = chipBonus + 2 end
            end
        end
    end

    ScoringEvaluator.currentChips = ScoringEvaluator.currentChips + chipBonus
    ScoringEvaluator.currentMult = ScoringEvaluator.currentMult + multBonus
    
    if player.edition == "Polychrome" then
        ScoringEvaluator.currentMult = ScoringEvaluator.currentMult * 1.5
    end
    
    local pitchStep = 1.0 + (ScoringEvaluator.currentRosterIdx * 0.08)
    SoundManager.playSFX("coin", pitchStep)
    
    if chipBonus > 0 or multBonus > 0 or player.edition == "Polychrome" then
        local msg = player.name .. ": +" .. chipBonus .. "Y +" .. string.format("%.1f", multBonus) .. "M"
        if player.edition and player.edition ~= "Standard" then
            msg = msg .. " [" .. player.edition:upper() .. "]"
        end
        FxManager.addFloatingText(msg, 480, 200, 1, 0.84, 0, 1.4)
    end
end

function ScoringEvaluator.evaluateDefenseCounter()
    local cChips, cMult = DefenseManager.evaluatePlay(ScoringEvaluator.playCard.type, ScoringEvaluator.currentChips, ScoringEvaluator.currentMult)
    
    if cChips < ScoringEvaluator.currentChips or cMult < ScoringEvaluator.currentMult then
        SoundManager.playSFX("tackle")
        FxManager.addFloatingText("DEFENSIVE COUNTER!", 480, 220, 1, 0.2, 0.2, 1.8)
        if _G.triggerScreenShake then _G.triggerScreenShake(12, 0.4) end
    end
    
    ScoringEvaluator.currentChips = cChips
    ScoringEvaluator.currentMult = cMult
end

function ScoringEvaluator.finalizeDriveSlam()
    local gs = ScoringEvaluator.gameState
    
    if ScoringEvaluator.isTurnover then
        ScoringEvaluator.active = false
        local FieldAnimator = require("src.ui.field_animator")
        FieldAnimator.active = false
        
        for _, item in ipairs(ScoringEvaluator.rosterQueue) do
            item.player.jumpY = 0
        end
        
        local StateDefense = require("src.states.state_defense")
        StateDefense.previousYardLine = gs.yardLine
        StateDefense.previousDown = gs.down
        StateDefense.previousDistance = gs.distance
        StateDefense.turnoverType = ScoringEvaluator.turnoverType
        
        local StateManager = require("src.states.state_manager")
        StateManager.switch(StateDefense)
        return
    end

    ScoringEvaluator.active = false
    local FieldAnimator = require("src.ui.field_animator")
    FieldAnimator.active = false
    
    for _, item in ipairs(ScoringEvaluator.rosterQueue) do
        item.player.jumpY = 0
    end
    
    local gs = ScoringEvaluator.gameState
    local totalMult = math.max(0.1, ScoringEvaluator.currentMult + (gs.tempMultBoost or 0))
    gs.tempMultBoost = 0
    
    -- -------------------------------------------------------------
    -- DYNAMIC FIELD RESISTANCE SCALING (STAKE AWARE)
    -- Gold Stake: Red Zone yard scaling set to 45%!
    -- -------------------------------------------------------------
    local zoneScale = 1.0
    if gs.yardLine >= 80 then
        if not gs.ignoreRedZonePenalty then
            zoneScale = (gs.stakeTier == "gold") and 0.45 or 0.55
        end
    elseif gs.yardLine >= 50 then
        zoneScale = 0.85
    end
    
    local rawYards = ScoringEvaluator.currentChips * totalMult * zoneScale
    local yardsGained = 0
    if ScoringEvaluator.playCard.type == "Run" then
        yardsGained = math.floor(math.min(25, 3 + rawYards * 0.4))
    else
        yardsGained = math.floor(math.min(80, 5 + rawYards * 0.35))
    end
    
    if DefenseManager.activeBlind and DefenseManager.activeBlind.id == "blitz_heavy" and ScoringEvaluator.playCard.type == "Play Action" then
        yardsGained = yardsGained - 3
    end
    
    if gs.weather == "snow" and not ScoringEvaluator.playCard.type:match("Pass") then
        yardsGained = math.floor(yardsGained * 0.9)
    end
    
    local fumbled = false
    if gs.weather == "rain" and ScoringEvaluator.playCard.type:match("Pass") then
        if math.random() < 0.15 then fumbled = true end
    end
    
    if fumbled then
        yardsGained = -5
        FxManager.addFloatingText("RAIN SLIP! FUMBLED PASS!", 480, 250, 1.0, 0.2, 0.2, 2.0)
    end
    
    gs.totalYardsGained = gs.totalYardsGained + yardsGained
    gs.yardLine = math.max(1, gs.yardLine + yardsGained)
    
    if ScoringEvaluator.playCard.enhancement == "Glass" then
        if math.random() < 0.25 then
            local DeckManager = require("src.engine.deck_manager")
            DeckManager.destroyCard(ScoringEvaluator.playCard)
            FxManager.addFloatingText("GLASS SHATTERED!", 480, 200, 1.0, 0.2, 0.2, 2.0)
            SoundManager.playSFX("tackle")
        end
    end
    
    local previousDistance = gs.distance
    
    local shakeAmt = math.min(30, math.abs(yardsGained) * 0.35)
    if totalMult >= 3.0 then
        shakeAmt = shakeAmt * 1.5
        FxManager.addBurstParticles(480, 270, 60, 1.0, 0.84, 0.0)
        FxManager.addBurstParticles(480, 270, 40, 0.0, 0.76, 1.0)
        if _G.triggerHitStop then _G.triggerHitStop(0.15) end
    elseif totalMult >= 1.5 then
        if _G.triggerHitStop then _G.triggerHitStop(0.08) end
    end
    
    if _G.triggerScreenShake then _G.triggerScreenShake(shakeAmt, 0.4) end
    SoundManager.playSFX("slam", 1.0 - math.min(0.3, shakeAmt * 0.01))
    
    if yardsGained < 0 then
        if _G.GAME_MODE == "roguelite" then
            local MyPlayerProfile = require("src.data.myplayer_profile")
            if MyPlayerProfile.hasNode("rush_2") and math.random() <= 0.4 then
                yardsGained = 0
                local negateText = (ScoringEvaluator.playCard and ScoringEvaluator.playCard.type == "Run") and "ELUSIVE HIPS! LOSS NEGATED!" or "ELUSIVE HIPS! SACK NEGATED!"
                FxManager.addFloatingText(negateText, 480, 260, 0.0, 0.76, 1.0, 2.0)
                SoundManager.playSFX("coin")
            end
        end
    end

    if yardsGained < 0 then
        SoundManager.playSFX("tackle")
        gs.distance = gs.distance - yardsGained
        gs.down = gs.down + 1
        
        if ScoringEvaluator.playCard and ScoringEvaluator.playCard.type == "Run" then
            gs.lastPlayResult = string.format("TACKLED FOR LOSS! %d YDS!", yardsGained)
            FxManager.addFloatingText("TFL! " .. yardsGained .. " YDS!", 480, 240, 1, 0.2, 0.2, 2.4)
        else
            gs.lastPlayResult = string.format("SACKED! %d YDS!", yardsGained)
            FxManager.addFloatingText("SACK! " .. yardsGained .. " YDS!", 480, 240, 1, 0.2, 0.2, 2.4)
        end
        
        if gs.down > 4 then
            gs.capCash = math.max(0, (gs.capCash or 0) - 3)
            gs.clockPenaltyNextDrive = 3
            gs.drivesRemaining = gs.drivesRemaining - 1
            
            local DeckManager = require("src.engine.deck_manager")
            for _, card in ipairs(DeckManager.hand or {}) do
                if card.enhancement == "Gold" then
                    gs.capCash = gs.capCash + 3
                    FxManager.addFloatingText("GOLD CARD HELD! +$3", 480, 150, 1.0, 0.84, 0.0, 1.5)
                end
                if card.seal == "Blue" then
                    local ConsumablesData = require("src.data.consumables")
                    if #gs.consumables < gs.maxConsumables then
                        local c = ConsumablesData[math.random(#ConsumablesData)]
                        gs.addConsumable(c)
                        FxManager.addFloatingText("BLUE DECAL! GENERATED " .. c.name:upper(), 480, 120, 0.0, 0.58, 1.0, 1.5)
                    end
                end
            end
            
            if gs.drivesRemaining <= 0 and gs.currentPoints < gs.targetPoints then
                gs.status = "TURNOVER"
            else
                gs.status = "TOUCHDOWN"
            end
            gs.lastPlayResult = gs.lastPlayResult .. " TURNOVER ON DOWNS (-$3 CASH)!"
        end
    elseif gs.yardLine >= 100 then
        gs.currentPoints = gs.currentPoints + 7
        gs.drivesRemaining = gs.drivesRemaining - 1
        
        local payout = 5 + (gs.bonusDriveCash or 0) + (gs.touchdownBonusCash or 0)
        
        local DeckManager = require("src.engine.deck_manager")
        for _, card in ipairs(DeckManager.hand or {}) do
            if card.enhancement == "Gold" then
                payout = payout + 3
                FxManager.addFloatingText("GOLD CARD HELD! +$3", 480, 150, 1.0, 0.84, 0.0, 1.5)
            end
            if card.seal == "Blue" then
                local ConsumablesData = require("src.data.consumables")
                if #gs.consumables < gs.maxConsumables then
                    local c = ConsumablesData[math.random(#ConsumablesData)]
                    gs.addConsumable(c)
                    FxManager.addFloatingText("BLUE DECAL! GENERATED " .. c.name:upper(), 480, 120, 0.0, 0.58, 1.0, 1.5)
                end
            end
        end
        
        gs.capCash = gs.capCash + payout
        
        SoundManager.playSFX("touchdown")
        if _G.triggerScreenShake then _G.triggerScreenShake(20, 0.6) end
        if _G.triggerHitStop then _G.triggerHitStop(0.2) end
        SaveManager.recordTouchdown()
        SaveManager.updateHighScore(gs.totalYardsGained)
        
        FxManager.addFloatingText("TOUCHDOWN! +7 PTS! +$" .. payout, 480, 200, 1, 0.84, 0, 3.0)
        FxManager.addBurstParticles(100, 220, 30, 1, 0.84, 0)
        FxManager.addBurstParticles(480, 220, 40, 1, 0.84, 0)
        FxManager.addBurstParticles(860, 220, 30, 1, 0.84, 0)
        
        if gs.currentPoints >= gs.targetPoints then
            gs.status = "GAME_WON"
            gs.gameWeek = gs.gameWeek + 1
            if gs.gameWeek > 4 then
                gs.gameWeek = 1
                gs.ante = gs.ante + 1
            end
        elseif gs.drivesRemaining <= 0 then
            gs.status = "TURNOVER"
        else
            gs.status = "TOUCHDOWN"
        end
    else
        if yardsGained >= previousDistance then
            local prevDown = gs.down
            gs.down = 1
            gs.distance = 10
            gs.lastPlayResult = string.format("FIRST DOWN! +%d YDS", yardsGained)
            
            if prevDown == 4 and ScoringEvaluator.playCard.type == "Run" and _G.GAME_MODE == "roguelite" then
                local MyPlayerProfile = require("src.data.myplayer_profile")
                if MyPlayerProfile.hasNode("rush_4") then
                    MyPlayerProfile.baseMult = MyPlayerProfile.baseMult + 0.5
                    MyPlayerProfile.save()
                    FxManager.addFloatingText("UNSTOPPABLE! +0.5 MTM PERMANENT", 480, 260, 1.0, 0.84, 0.0, 2.5)
                end
            end
        else
            gs.distance = previousDistance - yardsGained
            gs.down = gs.down + 1
            gs.lastPlayResult = string.format("+%d YDS", yardsGained)
            
            if gs.down > 4 then
                gs.capCash = math.max(0, (gs.capCash or 0) - 3)
                gs.clockPenaltyNextDrive = 3
                gs.drivesRemaining = gs.drivesRemaining - 1
                
                local DeckManager = require("src.engine.deck_manager")
                for _, card in ipairs(DeckManager.hand or {}) do
                    if card.enhancement == "Gold" then
                        gs.capCash = gs.capCash + 3
                        FxManager.addFloatingText("GOLD CARD HELD! +$3", 480, 150, 1.0, 0.84, 0.0, 1.5)
                    end
                    if card.seal == "Blue" then
                        local ConsumablesData = require("src.data.consumables")
                        if #gs.consumables < gs.maxConsumables then
                            local c = ConsumablesData[math.random(#ConsumablesData)]
                            gs.addConsumable(c)
                            FxManager.addFloatingText("BLUE DECAL! GENERATED " .. c.name:upper(), 480, 120, 0.0, 0.58, 1.0, 1.5)
                        end
                    end
                end
                
                if gs.drivesRemaining <= 0 and gs.currentPoints < gs.targetPoints then
                    gs.status = "TURNOVER"
                else
                    gs.status = "TOUCHDOWN"
                end
                gs.lastPlayResult = gs.lastPlayResult .. " TURNOVER ON DOWNS (-$3 CASH)!"
            end
        end
        
        SoundManager.playSFX("tackle")
        FxManager.addFloatingText("+" .. yardsGained .. " YDS!", 480, 240, 0.2, 0.8, 1, 2.0)
    end
    
    gs.resetPlayClock()
    DefenseManager.callDefensivePlay()
end

function ScoringEvaluator.draw()
    -- Disabled: animated yards and momentum are integrated directly into the top scoreboard
    do return end
    
    local t = love.timer.getTime()
    
    -- Main Box
    local boxX, boxY = 60, 200
    local boxW, boxH = 220, 110
    
    love.graphics.push()
    
    -- Screen shake for high mults
    if ScoringEvaluator.currentMult >= 3.0 then
        local shakeX = math.random(-3, 3)
        local shakeY = math.random(-3, 3)
        love.graphics.translate(shakeX, shakeY)
    end
    
    -- Flame Effects (if mult >= 2.0)
    if ScoringEvaluator.currentMult >= 2.0 then
        love.graphics.setBlendMode("add")
        for i = 1, 10 do
            local ox = math.sin(t * 10 + i) * 10
            local oy = (t * -50 + i * 15) % boxH
            love.graphics.setColor(1.0, 0.4, 0.0, 0.4 - (oy/boxH)*0.4)
            love.graphics.circle("fill", boxX + (boxW * (i/10)) + ox, boxY + boxH - oy, math.random(5, 15))
            
            -- High heat blue flames
            if ScoringEvaluator.currentMult >= 4.0 then
                love.graphics.setColor(0.0, 0.6, 1.0, 0.5 - (oy/boxH)*0.5)
                love.graphics.circle("fill", boxX + (boxW * (i/10)) + ox * 0.5, boxY + boxH - oy * 1.5, math.random(3, 10))
            end
        end
        love.graphics.setBlendMode("alpha")
    end
    
    -- Box Background
    love.graphics.setColor(0.08, 0.1, 0.14, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 8, 8)
    
    local multIntensity = math.min(1.0, (ScoringEvaluator.currentMult - 1.0) / 3.0)
    love.graphics.setColor(1.0 * multIntensity, 0.76 - 0.76 * multIntensity, 1.0 - multIntensity)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- Play Type Title
    local title = ScoringEvaluator.playCard and ScoringEvaluator.playCard.type or "PLAY"
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(title:upper(), boxX, boxY + 10, boxW, "center")
    
    -- Chips (Yards) Box
    love.graphics.setColor(0.0, 0.58, 1.0)
    love.graphics.rectangle("fill", boxX + 15, boxY + 40, 80, 45, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("%d", math.floor(ScoringEvaluator.displayedChips)), boxX + 15, boxY + 52, 80 / 1.5, "center", 0, 1.5, 1.5)
    
    -- 'X' symbol
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.print("X", boxX + 104, boxY + 52, 0, 1.3, 1.3)
    
    -- Mult (MTM) Box
    love.graphics.setColor(1.0, 0.3, 0.3)
    love.graphics.rectangle("fill", boxX + 125, boxY + 40, 80, 45, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("%.1f", ScoringEvaluator.displayedMult), boxX + 125, boxY + 52, 80 / 1.5, "center", 0, 1.5, 1.5)
    
    love.graphics.pop()
end

function ScoringEvaluator.calculateTurnoverRisk(playCard, gameState)
    if not playCard then return 0, "None" end
    
    local DefenseManager = require("src.engine.defense_manager")
    local isPass = playCard.type:match("Pass") or playCard.type == "Play Action"
    
    if isPass then
        -- Interception Risk
        local baseRisk = 0
        if playCard.type == "Deep Pass" or playCard.name:match("Deep") then
            baseRisk = 8
        elseif playCard.type == "Hail Mary" or playCard.name == "Hail Mary" then
            baseRisk = 15
        elseif playCard.type == "Play Action" then
            baseRisk = 4
        elseif playCard.type == "Short Pass" or playCard.type == "Medium Pass" then
            baseRisk = 1
        end
        
        -- QB Awareness reduces INT risk
        local qbCard = nil
        if gameState.rosterSlots and gameState.rosterSlots.QB and gameState.rosterSlots.QB.cards[1] then
            qbCard = gameState.rosterSlots.QB.cards[1]
        end
        local qbAwr = qbCard and qbCard.awr or 70
        local risk = baseRisk - (qbAwr - 70) * 0.25
        
        -- Blinds increase INT risk
        if DefenseManager.activeBlind and (DefenseManager.activeBlind.id == "no_fly_zone" or DefenseManager.activeBlind.id == "cover_0_blitz") then
            risk = risk + 10
        end
        
        return math.max(0, math.floor(risk + 0.5)), "INT"
    else
        -- Fumble Risk (Run plays)
        if playCard.type == "Run" then
            local baseRisk = 5
            
            -- RB / TE overall/awr reduces fumble risk
            local carrierCard = nil
            if gameState.rosterSlots and gameState.rosterSlots.RB and gameState.rosterSlots.RB.cards[1] then
                carrierCard = gameState.rosterSlots.RB.cards[1]
            end
            local carrierAwr = carrierCard and carrierCard.awr or 70
            local risk = baseRisk - (carrierAwr - 70) * 0.15
            
            -- Weather increases fumble risk
            if gameState.weather == "rain" then
                risk = risk + 8
            elseif gameState.weather == "snow" then
                risk = risk + 5
            end
            
            -- Blinds increase fumble risk
            if DefenseManager.activeBlind and DefenseManager.activeBlind.id == "ironclad_front" then
                risk = risk + 5
            end
            
            return math.max(0, math.floor(risk + 0.5)), "FUMBLE"
        end
    end
    
    return 0, "None"
end

return ScoringEvaluator
