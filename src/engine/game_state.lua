-- src/engine/game_state.lua
local DefenseManager = require("src.engine.defense_manager")
local MyPlayerProfile = require("src.data.myplayer_profile")
local PlayerCard = require("src.entities.player_card")
local SoundManager = require("src.engine.sound_manager")
local FxManager = require("src.engine.fx_manager")
local RosterPlayersExpanded = require("src.data.roster_players_expanded")
local SaveManager = require("src.engine.save_manager")
local SteamManager = require("src.engine.steam_manager")

local GameState = {}

GameState.capCash = 5
GameState.ante = 1
GameState.gameWeek = 1
GameState.round = 1
GameState.consumables = {}
GameState.maxConsumables = 2
GameState.consecutiveDrivesWithoutRest = 0
GameState.tempMultBoost = 0

GameState.stakeTier = "white" -- white, red, purple, gold
GameState.currentPoints = 0
GameState.targetPoints = 6
GameState.drivesRemaining = 3
GameState.maxDrives = 3
GameState.yardLine = 25

GameState.playClock = 25
GameState.maxPlayClock = 25
GameState.clockActive = true
GameState.clockPenaltyNextDrive = 0

function GameState.init(config)
    GameState.config = config or {}
    GameState.capCash = 5
    GameState.ante = 1
    GameState.gameWeek = 1
    GameState.maxDrives = 3
    GameState.bonusAudibles = 0
    GameState.bonusDriveCash = 0
    GameState.fieldGoalValue = 3
    
    GameState.maxConsumables = 2
    GameState.consumables = {}
    GameState.clockPenaltyNextDrive = 0
    GameState.stakeTier = (config and config.stakeTier) or _G.STAKE_TIER or "white"
    
    GameState.currentPoints = 0
    GameState.targetPoints = 6
    GameState.drivesRemaining = 3
    GameState.maxDrives = 3
    GameState.yardLine = 25
    
    GameState.rosterSlots = {
        QB = { max = 1, cards = {} },
        RB = { max = 1, cards = {} },
        WR1 = { max = 1, cards = {} },
        WR2 = { max = 1, cards = {} },
        FLEX = { max = 1, cards = {} }
    }
    
    if GameState.config and GameState.config.team then
        local t = GameState.config.team
        if t.bonusCash then GameState.capCash = GameState.capCash + t.bonusCash end
        if t.extraTESlot then GameState.rosterSlots.WR2.max = 2 end
        if t.bonusAudibles then GameState.bonusAudibles = (GameState.bonusAudibles or 0) + t.bonusAudibles end
        if t.passBonus then GameState.passBonus = t.passBonus end
        if t.multBonus then GameState.teamMultBonus = t.multBonus end
        if t.playActionBonus then GameState.playActionBonus = t.playActionBonus end
        if t.touchdownBonusCash then GameState.touchdownBonusCash = (GameState.touchdownBonusCash or 0) + t.touchdownBonusCash end
    end

    -- 1. If roguelite mode, add MyPlayer first so their position slot is occupied
    if _G.GAME_MODE == "roguelite" then
        local myPlayerCard = PlayerCard.new(MyPlayerProfile.name, MyPlayerProfile.position .. "1", "Starter", MyPlayerProfile.baseMult, MyPlayerProfile.baseChips)
        myPlayerCard.isMyPlayer = true
        if MyPlayerProfile.hasNode("cmd_1") then GameState.touchdownBonusCash = (GameState.touchdownBonusCash or 0) + 2 end
        if MyPlayerProfile.hasNode("pass_3") then GameState.bonusAudibles = (GameState.bonusAudibles or 0) + 2 end
        if MyPlayerProfile.hasNode("cmd_2") then GameState.hasAnalyticsDept = true end
        GameState.addRosterPlayer(myPlayerCard, MyPlayerProfile.position)
    end

    -- 2. Apply archetype rosters (adding starting players where slots aren't full)
    if GameState.config and GameState.config.archetype then
        local archId = GameState.config.archetype.id
        if archId == "air_raid" then
            GameState.rosterSlots.WR2.max = 2
            GameState.addRosterPlayer(RosterPlayersExpanded.getRandomPlayer("QB"), "QB")
            GameState.addRosterPlayer(RosterPlayersExpanded.getRandomPlayer("WR"), "WR1")
        elseif archId == "ground_pound" then
            GameState.rosterSlots.RB.max = 2
            GameState.addRosterPlayer(RosterPlayersExpanded.getRandomPlayer("RB"), "RB")
            GameState.addRosterPlayer(RosterPlayersExpanded.getRandomPlayer("TE"), "WR2")
        elseif archId == "west_coast" then
            GameState.rosterSlots.FLEX.max = 2
            GameState.addRosterPlayer(RosterPlayersExpanded.getRandomPlayer("QB"), "QB")
            GameState.addRosterPlayer(RosterPlayersExpanded.getRandomPlayer("RB"), "RB")
        end
    end
    
    -- 3. If standard mode, check if a QB is slot-occupied; if not, add one
    if _G.GAME_MODE ~= "roguelite" then
        if #GameState.rosterSlots.QB.cards == 0 then
            local pillar = RosterPlayersExpanded.getRandomPlayer("QB")
            if GameState.config and GameState.config.team and GameState.config.team.superstarQB then
                pillar.overall = 99
                pillar.name = "Montana Brady"
            end
            GameState.addRosterPlayer(pillar, "QB")
        end
    end
    
    DefenseManager.init()
    GameState.nextRound("standard")
end

function GameState.resetPlayClock()
    local baseClock = 25
    if GameState.stakeTier == "red" then baseClock = 20
    elseif GameState.stakeTier == "purple" then baseClock = 15
    elseif GameState.stakeTier == "gold" then baseClock = 10 end
    
    if DefenseManager.activeBlind and (DefenseManager.activeBlind.id == "blitz_heavy" or DefenseManager.activeBlind.id == "no_fly_zone" or DefenseManager.activeBlind.id == "cover_0_blitz") then
        if _G.GAME_MODE ~= "roguelite" or not MyPlayerProfile.hasNode("pass_4") then
            local limit = (DefenseManager.activeBlind.id == "cover_0_blitz") and 8 or 10
            baseClock = math.min(baseClock, limit)
        end
    end
    
    if GameState.clockPenaltyNextDrive and GameState.clockPenaltyNextDrive > 0 then
        baseClock = math.max(6, baseClock - GameState.clockPenaltyNextDrive)
        GameState.clockPenaltyNextDrive = 0
    end
    
    GameState.maxPlayClock = baseClock
    GameState.playClock = GameState.maxPlayClock
    GameState.clockActive = true
end

function GameState.updatePlayClock(dt)
    if GameState.status ~= "PLAYING" or not GameState.clockActive then return end
    
    local ScoringEvaluator = require("src.engine.scoring_evaluator")
    local FieldAnimator = require("src.ui.field_animator")
    if ScoringEvaluator.active or FieldAnimator.active then return end
    
    GameState.playClock = GameState.playClock - dt
    if GameState.playClock <= 0 then
        SoundManager.playSFX("whistle")
        GameState.yardLine = math.max(1, GameState.yardLine - 5)
        GameState.distance = GameState.distance + 5
        GameState.down = GameState.down + 1
        
        FxManager.addFloatingText("DELAY OF GAME! -5 YDS", 480, 240, 1, 0.2, 0.2, 2.2)
        if _G.triggerScreenShake then _G.triggerScreenShake(12, 0.4) end
        
        if GameState.down > 4 then
            GameState.capCash = math.max(0, (GameState.capCash or 0) - 3)
            GameState.status = "DRIVE_LOST"
            GameState.drivesRemaining = GameState.drivesRemaining - 1
            GameState.lastPlayResult = "DELAY OF GAME! TURNOVER ON DOWNS."
        else
            GameState.lastPlayResult = "DELAY OF GAME PENALTY! Loss of 5 Yards."
        end
        
        GameState.resetPlayClock()
    end
end

function GameState.startDrive()
    GameState.down = 1
    GameState.distance = 10
    GameState.yardLine = 25
    GameState.totalYardsGained = 0
    GameState.status = "PLAYING"
    
    GameState.resetPlayClock()
    SaveManager.saveActiveRun(GameState)
end

function GameState.nextRound(defenseType)
    GameState.down = 1
    GameState.distance = 10
    GameState.yardLine = 25
    GameState.tempMultBoost = 0
    GameState.consecutiveDrivesWithoutRest = (GameState.consecutiveDrivesWithoutRest or 0) + 1
    
    local r = math.random()
    if r < 0.15 then GameState.weather = "snow"
    elseif r < 0.35 then GameState.weather = "rain"
    else GameState.weather = "clear" end
    
    if GameState.config and GameState.config.team and GameState.config.team.weather then
        GameState.weather = GameState.config.team.weather
    end
    
    -- Stake Tier Target Point Multipliers
    local stakeMult = 1.0
    if GameState.stakeTier == "red" then stakeMult = 1.15
    elseif GameState.stakeTier == "purple" then stakeMult = 1.30
    elseif GameState.stakeTier == "gold" then stakeMult = 1.50 end
    
    local anteMultiplier = 1 + math.max(0, (GameState.ante - 1) * 0.25)
    
    if GameState.gameWeek == 1 then
        GameState.targetPoints = math.floor(6 * anteMultiplier * stakeMult)
        GameState.maxDrives = 3
    elseif GameState.gameWeek == 2 then
        GameState.targetPoints = math.floor(10 * anteMultiplier * stakeMult)
        GameState.maxDrives = 3
    elseif GameState.gameWeek == 3 then
        GameState.targetPoints = math.floor(14 * anteMultiplier * stakeMult)
        GameState.maxDrives = 3
    else
        GameState.targetPoints = math.floor(20 * anteMultiplier * stakeMult)
        GameState.maxDrives = 4
    end
    
    if not GameState.drivesRemaining or GameState.drivesRemaining <= 0 then
        GameState.drivesRemaining = GameState.maxDrives
        GameState.currentPoints = 0
    end
    
    GameState.totalYardsGained = 0
    GameState.status = "PLAYING"
    GameState.lastPlayResult = ""
    
    GameState.audiblesRemaining = 3 + (GameState.bonusAudibles or 0)
    
    DefenseManager.setNextBlind(defenseType)
    DefenseManager.callDefensivePlay()
    GameState.resetPlayClock()
    
    SaveManager.saveActiveRun(GameState)
end

function GameState.kickFieldGoal()
    if GameState.yardLine < 65 then return false end
    
    local fgPts = GameState.fieldGoalValue or 3
    GameState.currentPoints = GameState.currentPoints + fgPts
    GameState.drivesRemaining = GameState.drivesRemaining - 1
    
    local payout = 2 + (GameState.bonusDriveCash or 0)
    GameState.capCash = GameState.capCash + payout
    
    SoundManager.playSFX("coin")
    FxManager.addFloatingText("FIELD GOAL GOOD! +" .. fgPts .. " PTS!", 480, 220, 1, 0.84, 0, 2.5)

    if GameState.down == 4 and _G.GAME_MODE == "roguelite" then
        local MyPlayerProfile = require("src.data.myplayer_profile")
        if MyPlayerProfile.hasNode("cmd_3") then
            GameState.audiblesRemaining = GameState.audiblesRemaining + 1
            FxManager.addFloatingText("+1 AUDIBLE REFUNDED!", 480, 250, 0.0, 0.76, 1.0, 2.0)
        end
    end
    
    if GameState.currentPoints >= GameState.targetPoints then
        GameState.status = "GAME_WON"
        GameState.gameWeek = GameState.gameWeek + 1
        if GameState.gameWeek > 4 then
            GameState.gameWeek = 1
            GameState.ante = GameState.ante + 1
            if GameState.ante > 8 then
                SteamManager.unlockAchievement("ACH_SUPER_BOWL")
                if _G.GAME_MODE == "roguelite" then
                    MyPlayerProfile.superBowlRings = MyPlayerProfile.superBowlRings + 1
                    MyPlayerProfile.seasonsPlayed = MyPlayerProfile.seasonsPlayed + 1
                    if MyPlayerProfile.seasonsPlayed >= MyPlayerProfile.maxSeasons then
                        MyPlayerProfile.retire()
                        GameState.lastPlayResult = "CAREER OVER. PLAYER RETIRED."
                    else
                        MyPlayerProfile.save()
                    end
                end
            end
        end
    elseif GameState.drivesRemaining <= 0 then
        GameState.status = "TURNOVER"
    else
        GameState.status = "TOUCHDOWN"
    end
    
    return true
end

function GameState.puntBall()
    local yardsGainedInDrive = math.max(0, GameState.yardLine - 25)
    local puntPayout = math.floor(yardsGainedInDrive / 10) + 1 + (GameState.bonusDriveCash or 0)
    
    GameState.drivesRemaining = GameState.drivesRemaining - 1
    GameState.capCash = GameState.capCash + puntPayout
    
    SoundManager.playSFX("whistle")
    FxManager.addFloatingText("PUNTED! SAVED DRIVE +$" .. puntPayout, 480, 220, 0.2, 0.8, 1, 2.0)
    
    if GameState.drivesRemaining <= 0 and GameState.currentPoints < GameState.targetPoints then
        GameState.status = "TURNOVER"
    else
        GameState.status = "TOUCHDOWN"
    end
    
    return true
end

function GameState.addConsumable(item)
    if #GameState.consumables < GameState.maxConsumables then
        table.insert(GameState.consumables, item)
        return true
    end
    return false
end

function GameState.useConsumable(index)
    if GameState.consumables[index] then
        local c = table.remove(GameState.consumables, index)
        if c.id == "rest" then
            GameState.consecutiveDrivesWithoutRest = 0
        end
        if c.use then
            return c.use(GameState)
        end
        return c.useMessage or "Used Consumable"
    end
    return "Nothing happened."
end

function GameState.addRosterPlayer(playerCard, posOverride)
    local pos = posOverride
    if pos == "TE" or pos == "WR" then pos = nil end

    if not pos then
        if playerCard.position:match("QB") then
            pos = "QB"
        elseif playerCard.position:match("RB") then
            if #GameState.rosterSlots.RB.cards < GameState.rosterSlots.RB.max then
                pos = "RB"
            elseif #GameState.rosterSlots.FLEX.cards < GameState.rosterSlots.FLEX.max then
                pos = "FLEX"
            else
                pos = "RB"
            end
        elseif playerCard.position:match("WR") then
            if #GameState.rosterSlots.WR1.cards < GameState.rosterSlots.WR1.max then
                pos = "WR1"
            elseif #GameState.rosterSlots.WR2.cards < GameState.rosterSlots.WR2.max then
                pos = "WR2"
            elseif #GameState.rosterSlots.FLEX.cards < GameState.rosterSlots.FLEX.max then
                pos = "FLEX"
            else
                pos = "WR1"
            end
        elseif playerCard.position:match("TE") then
            if #GameState.rosterSlots.WR2.cards < GameState.rosterSlots.WR2.max then
                pos = "WR2"
            elseif #GameState.rosterSlots.FLEX.cards < GameState.rosterSlots.FLEX.max then
                pos = "FLEX"
            else
                pos = "WR2"
            end
        end
    end
    
    if playerCard.edition == "Franchise" and pos and GameState.rosterSlots[pos] then
        GameState.rosterSlots[pos].max = GameState.rosterSlots[pos].max + 1
    end
    
    if pos and GameState.rosterSlots[pos] then
        local slotData = GameState.rosterSlots[pos]
        if #slotData.cards < slotData.max then
            table.insert(slotData.cards, playerCard)
            return true
        else
            -- Slot is full: swap out lowest OVR non-MyPlayer card
            local replaceIdx = nil
            local minOvr = 999
            for i, c in ipairs(slotData.cards) do
                if not c.isMyPlayer and c.overall < minOvr then
                    minOvr = c.overall
                    replaceIdx = i
                end
            end
            if replaceIdx then
                slotData.cards[replaceIdx] = playerCard
                return true
            end
        end
    end
    return false
end

function GameState.hasSpaceForPosition(posName)
    if posName == "QB" then
        return #GameState.rosterSlots.QB.cards < GameState.rosterSlots.QB.max
    elseif posName == "RB" then
        return (#GameState.rosterSlots.RB.cards < GameState.rosterSlots.RB.max) or (#GameState.rosterSlots.FLEX.cards < GameState.rosterSlots.FLEX.max)
    elseif posName == "WR" then
        return (#GameState.rosterSlots.WR1.cards < GameState.rosterSlots.WR1.max) or (#GameState.rosterSlots.WR2.cards < GameState.rosterSlots.WR2.max) or (#GameState.rosterSlots.FLEX.cards < GameState.rosterSlots.FLEX.max)
    elseif posName == "TE" then
        return (#GameState.rosterSlots.WR2.cards < GameState.rosterSlots.WR2.max) or (#GameState.rosterSlots.FLEX.cards < GameState.rosterSlots.FLEX.max)
    end
    return false
end

function GameState.executePlay(playCard, isTurnover, turnoverType)
    local ScoringEvaluator = require("src.engine.scoring_evaluator")
    ScoringEvaluator.start(playCard, GameState, isTurnover, turnoverType)
end

function GameState.addConsumable(consumableObj)
    if #GameState.consumables < GameState.maxConsumables then
        table.insert(GameState.consumables, consumableObj)
        return true
    end
    return false
end

function GameState.useConsumable(index)
    if not GameState.consumables[index] then return "Slot Empty" end
    local cons = GameState.consumables[index]
    local msg = cons.use(GameState)
    table.remove(GameState.consumables, index)
    return msg
end

return GameState
