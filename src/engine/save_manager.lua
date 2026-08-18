-- src/engine/save_manager.lua
local SteamManager = require("src.engine.steam_manager")
local SaveManager = {}

SaveManager.activeProfileIndex = 1
local RUN_FILENAME = "save_run.dat"

local function getProfileFilename(idx)
    return "profile_" .. (idx or SaveManager.activeProfileIndex) .. ".dat"
end

SaveManager.data = {
    profileName = "Profile 1",
    highScoreYards = 0,
    totalTouchdowns = 0,
    superBowlRings = 0,
    careerCapCash = 0,
    unlockedCards = {},
    unlockedBlinds = {},
    masteredCards = {},
    settings = {
        enableCRT = false,
        screenshake = 1.0,
        sfxVolume = 0.8,
        musicVolume = 0.5,
        fullscreen = false,
        vsync = true,
        muteOnFocus = false,
        showFPS = false
    }
}

function SaveManager.init()
    SaveManager.load(1)
    SteamManager.init()
end

function SaveManager.switchProfile(idx)
    idx = math.clamp(idx, 1, 5)
    SaveManager.activeProfileIndex = idx
    SaveManager.load(idx)
end

function SaveManager.load(idx)
    idx = idx or SaveManager.activeProfileIndex
    local filename = getProfileFilename(idx)
    
    SaveManager.data = {
        profileName = "Profile " .. idx,
        highScoreYards = 0,
        totalTouchdowns = 0,
        superBowlRings = 0,
        careerCapCash = 0,
        unlockedCards = {},
        unlockedBlinds = {},
        masteredCards = {},
        settings = {
            enableCRT = false,
            screenshake = 1.0,
            sfxVolume = 0.8,
            musicVolume = 0.5,
            fullscreen = false,
            vsync = true,
            muteOnFocus = false,
            showFPS = false
        }
    }
    
    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(filename) then
        local content, size = love.filesystem.read(filename)
        if content then
            local loaded = nil
            local func = loadstring or load
            if func then
                local ok, res = pcall(func(content))
                if ok and type(res) == "table" then
                    loaded = res
                end
            end
            if loaded then
                for k, v in pairs(loaded) do
                    SaveManager.data[k] = v
                end
            end
        end
    end
    
    _G.CONFIG_ENABLE_CRT = SaveManager.data.settings.enableCRT or false
    _G.CONFIG_SFX_VOLUME = SaveManager.data.settings.sfxVolume or 0.8
    _G.CONFIG_MUSIC_VOLUME = SaveManager.data.settings.musicVolume or 0.5
    _G.CONFIG_SCREENSHAKE = SaveManager.data.settings.screenshake or 1.0
    _G.CONFIG_FULLSCREEN = SaveManager.data.settings.fullscreen or false
    _G.CONFIG_VSYNC = SaveManager.data.settings.vsync ~= false
    _G.CONFIG_MUTE_ON_FOCUS_LOST = SaveManager.data.settings.muteOnFocus or false
    _G.CONFIG_SHOW_FPS = SaveManager.data.settings.showFPS or false
    
    local SettingsData = require("src.data.settings_data")
    SettingsData.sfxVolume = _G.CONFIG_SFX_VOLUME
    SettingsData.musicVolume = _G.CONFIG_MUSIC_VOLUME
    if SaveManager.data.settings.masterVolume ~= nil then SettingsData.masterVolume = SaveManager.data.settings.masterVolume end
    if SaveManager.data.settings.stadiumPulseEnabled ~= nil then SettingsData.stadiumPulseEnabled = SaveManager.data.settings.stadiumPulseEnabled end
    if SaveManager.data.settings.gameSpeed ~= nil then SettingsData.gameSpeed = SaveManager.data.settings.gameSpeed end
    if SaveManager.data.settings.impactFx ~= nil then SettingsData.impactFx = SaveManager.data.settings.impactFx end
    if SaveManager.data.settings.weatherStains ~= nil then SettingsData.weatherStains = SaveManager.data.settings.weatherStains end
    if SaveManager.data.settings.reducedFlashing ~= nil then SettingsData.reducedFlashing = SaveManager.data.settings.reducedFlashing end
    if SaveManager.data.settings.streamerMode ~= nil then SettingsData.streamerMode = SaveManager.data.settings.streamerMode end
    if SaveManager.data.settings.profanityFilter ~= nil then SettingsData.profanityFilter = SaveManager.data.settings.profanityFilter end
    
    if love.window then
        pcall(love.window.setFullscreen, _G.CONFIG_FULLSCREEN)
        pcall(love.window.setVSync, _G.CONFIG_VSYNC and 1 or 0)
    end
end

function SaveManager.save()
    if not love.filesystem then return end
    local filename = getProfileFilename(SaveManager.activeProfileIndex)
    
    local function serialize(val)
        local t = type(val)
        if t == "number" or t == "boolean" then
            return tostring(val)
        elseif t == "string" then
            return string.format("%q", val)
        elseif t == "table" then
            local str = "{"
            for k, v in pairs(val) do
                local keyStr = (type(k) == "number") and ("[" .. k .. "]") or ("[" .. string.format("%q", k) .. "]")
                str = str .. keyStr .. "=" .. serialize(v) .. ","
            end
            return str .. "}"
        end
        return "nil"
    end
    
    local content = "return " .. serialize(SaveManager.data)
    love.filesystem.write(filename, content)
    SteamManager.syncCloudSave(filename, content)
end

function SaveManager.hasActiveRun()
    if love.filesystem and love.filesystem.getInfo then
        return love.filesystem.getInfo(RUN_FILENAME) ~= nil
    end
    return false
end

function SaveManager.saveActiveRun(gameState)
    if not love.filesystem or not gameState then return end
    
    local rosterData = {}
    if gameState.rosterSlots then
        for pos, posData in pairs(gameState.rosterSlots) do
            rosterData[pos] = { max = posData.max, cards = {} }
            for _, card in ipairs(posData.cards) do
                local badges = {}
                for _, b in ipairs(card.equippedBadges or {}) do
                    table.insert(badges, b.id)
                end
                table.insert(rosterData[pos].cards, {
                    name = card.name,
                    position = card.position,
                    rarity = card.rarity,
                    overall = card.overall,
                    edition = card.edition or "Standard",
                    isMyPlayer = card.isMyPlayer,
                    baseMult = card.baseMult,
                    baseChips = card.baseChips,
                    equippedBadges = badges,
                    passesThrown = card.passesThrown,
                    runsCalled = card.runsCalled,
                    deepPasses = card.deepPasses,
                    deepTotal = card.deepTotal,
                    firstDowns = card.firstDowns
                })
            end
        end
    end
    
    local playbookData = {}
    local DeckManager = require("src.engine.deck_manager")
    if DeckManager.playbook then
        for _, card in ipairs(DeckManager.playbook) do
            table.insert(playbookData, {
                type = card.type,
                name = card.name,
                baseChips = card.baseChips,
                baseMult = card.baseMult,
                enhancement = card.enhancement,
                seal = card.seal
            })
        end
    end
    
    local consumablesData = {}
    for _, cons in ipairs(gameState.consumables or {}) do
        table.insert(consumablesData, cons.id)
    end
    
    local shopItemsData = {}
    if gameState.inShop then
        local StateShop = require("src.states.state_shop")
        if StateShop.shopItems then
            for _, item in ipairs(StateShop.shopItems) do
                table.insert(shopItemsData, {
                    slot = item.slot,
                    title = item.title,
                    desc = item.desc,
                    cost = item.cost,
                    packType = item.packType,
                    purchased = item.purchased or false,
                    consumableId = item.consumable and item.consumable.id,
                    voucherId = item.voucher and item.voucher.id
                })
            end
        end
    end
    
    local runData = {
        profileIndex = SaveManager.activeProfileIndex,
        capCash = gameState.capCash,
        ante = gameState.ante,
        gameWeek = gameState.gameWeek,
        currentPoints = gameState.currentPoints,
        targetPoints = gameState.targetPoints,
        drivesRemaining = gameState.drivesRemaining,
        yardLine = gameState.yardLine,
        stakeTier = gameState.stakeTier or "white",
        gameMode = _G.GAME_MODE or "arcade",
        
        teamId = gameState.config and gameState.config.team and gameState.config.team.id,
        archetypeId = gameState.config and gameState.config.archetype and gameState.config.archetype.id,
        
        bonusDriveCash = gameState.bonusDriveCash,
        touchdownBonusCash = gameState.touchdownBonusCash,
        bonusAudibles = gameState.bonusAudibles,
        passBonus = gameState.passBonus,
        teamMultBonus = gameState.teamMultBonus,
        playActionBonus = gameState.playActionBonus,
        globalRosterChips = gameState.globalRosterChips,
        ignoreRedZonePenalty = gameState.ignoreRedZonePenalty,
        freeVoucher = gameState.freeVoucher,
        
        roster = rosterData,
        playbook = playbookData,
        consumables = consumablesData,
        inShop = gameState.inShop or false,
        shopItems = shopItemsData
    }
    
    local function serialize(val)
        local t = type(val)
        if t == "number" or t == "boolean" then return tostring(val)
        elseif t == "string" then return string.format("%q", val)
        elseif t == "table" then
            local str = "{"
            for k, v in pairs(val) do
                local keyStr = (type(k) == "number") and ("[" .. k .. "]") or ("[" .. string.format("%q", k) .. "]")
                str = str .. keyStr .. "=" .. serialize(v) .. ","
            end
            return str .. "}"
        end
        return "nil"
    end
    
    local content = "return " .. serialize(runData)
    love.filesystem.write(RUN_FILENAME, content)
    SteamManager.syncCloudSave(RUN_FILENAME, content)
end

function SaveManager.loadActiveRun()
    if not SaveManager.hasActiveRun() then return nil end
    local content = love.filesystem.read(RUN_FILENAME)
    if content then
        local func = loadstring or load
        if func then
            local ok, res = pcall(func(content))
            if ok and type(res) == "table" then return res end
        end
    end
    return nil
end

function SaveManager.loadActiveRunIntoState(gameState)
    local runData = SaveManager.loadActiveRun()
    if not runData then return false end
    
    _G.GAME_MODE = runData.gameMode or "arcade"
    _G.STAKE_TIER = runData.stakeTier or "white"
    
    local teamObj = nil
    if runData.teamId then
        local FranchiseTeams = require("src.data.franchise_teams")
        for _, t in ipairs(FranchiseTeams) do
            if t.id == runData.teamId then teamObj = t; break end
        end
    end
    
    local archObj = nil
    if runData.archetypeId then
        local archetypes = {
            { id = "air_raid", name = "Air Raid Scheme" },
            { id = "ground_pound", name = "Ground & Pound" },
            { id = "west_coast", name = "West Coast Scheme" }
        }
        for _, a in ipairs(archetypes) do
            if a.id == runData.archetypeId then archObj = a; break end
        end
    end
    
    gameState.init({
        team = teamObj,
        archetype = archObj,
        stakeTier = _G.STAKE_TIER
    })
    
    gameState.capCash = runData.capCash
    gameState.ante = runData.ante
    gameState.gameWeek = runData.gameWeek
    gameState.currentPoints = runData.currentPoints
    gameState.targetPoints = runData.targetPoints
    gameState.drivesRemaining = runData.drivesRemaining
    gameState.yardLine = runData.yardLine
    
    gameState.bonusDriveCash = runData.bonusDriveCash or 0
    gameState.touchdownBonusCash = runData.touchdownBonusCash or 0
    gameState.bonusAudibles = runData.bonusAudibles or 0
    gameState.passBonus = runData.passBonus
    gameState.teamMultBonus = runData.teamMultBonus
    gameState.playActionBonus = runData.playActionBonus
    gameState.globalRosterChips = runData.globalRosterChips
    gameState.ignoreRedZonePenalty = runData.ignoreRedZonePenalty
    gameState.freeVoucher = runData.freeVoucher
    
    if runData.roster then
        local RosterPlayersExpanded = require("src.data.roster_players_expanded")
        local PlayerCard = require("src.entities.player_card")
        local BadgesData = require("src.data.badges")
        
        gameState.rosterSlots = {}
        for pos, posData in pairs(runData.roster) do
            gameState.rosterSlots[pos] = { max = posData.max, cards = {} }
            for _, cardData in ipairs(posData.cards) do
                local playerCard = nil
                if cardData.isMyPlayer then
                    playerCard = PlayerCard.new(cardData.name, cardData.position, cardData.rarity, cardData.baseMult, cardData.baseChips, cardData.edition)
                    playerCard.isMyPlayer = true
                else
                    playerCard = RosterPlayersExpanded.getPlayerByName(cardData.name)
                    if not playerCard then
                        playerCard = PlayerCard.new(cardData.name, cardData.position, cardData.rarity, nil, nil, cardData.edition)
                    end
                end
                
                playerCard.overall = cardData.overall
                playerCard.edition = cardData.edition
                playerCard.passesThrown = cardData.passesThrown
                playerCard.runsCalled = cardData.runsCalled
                playerCard.deepPasses = cardData.deepPasses
                playerCard.deepTotal = cardData.deepTotal
                playerCard.firstDowns = cardData.firstDowns
                
                playerCard.equippedBadges = {}
                for _, badgeId in ipairs(cardData.equippedBadges or {}) do
                    for _, b in ipairs(BadgesData) do
                        if b.id == badgeId then
                            table.insert(playerCard.equippedBadges, b)
                        end
                    end
                end
                
                table.insert(gameState.rosterSlots[pos].cards, playerCard)
            end
        end
    end
    
    if runData.playbook then
        local DeckManager = require("src.engine.deck_manager")
        local PlayCard = require("src.entities.play_card")
        DeckManager.playbook = {}
        for _, cardData in ipairs(runData.playbook) do
            local card = PlayCard.new(cardData.name, cardData.type)
            card.baseChips = cardData.baseChips
            card.baseMult = cardData.baseMult
            card.enhancement = cardData.enhancement
            card.seal = cardData.seal
            table.insert(DeckManager.playbook, card)
        end
        DeckManager.shuffle()
    end
    
    if runData.consumables then
        local ConsumablesData = require("src.data.consumables")
        gameState.consumables = {}
        for _, cId in ipairs(runData.consumables) do
            for _, cons in ipairs(ConsumablesData) do
                if cons.id == cId then
                    table.insert(gameState.consumables, cons)
                    break
                end
            end
        end
    end
    
    gameState.inShop = runData.inShop or false
    if runData.shopItems and #runData.shopItems > 0 then
        local StateShop = require("src.states.state_shop")
        StateShop.shopItems = {}
        local ConsumablesData = require("src.data.consumables")
        local VouchersData = require("src.data.vouchers")
        
        for _, itemData in ipairs(runData.shopItems) do
            local item = {
                slot = itemData.slot,
                title = itemData.title,
                desc = itemData.desc,
                cost = itemData.cost,
                packType = itemData.packType,
                purchased = itemData.purchased or false
            }
            if itemData.consumableId then
                for _, cons in ipairs(ConsumablesData) do
                    if cons.id == itemData.consumableId then
                        item.consumable = cons
                        break
                    end
                end
            end
            if itemData.voucherId then
                for _, vouch in ipairs(VouchersData) do
                    if vouch.id == itemData.voucherId then
                        item.voucher = vouch
                        break
                    end
                end
            end
            table.insert(StateShop.shopItems, item)
        end
    else
        local StateShop = require("src.states.state_shop")
        StateShop.shopItems = nil
    end
    
    return true
end

function SaveManager.clearActiveRun()
    if love.filesystem and love.filesystem.remove then
        love.filesystem.remove(RUN_FILENAME)
    end
end

function SaveManager.writeTelemetryLog(filename, data)
    local function serializeJSON(val)
        local t = type(val)
        if t == "number" or t == "boolean" then
            return tostring(val)
        elseif t == "string" then
            return string.format("%q", val)
        elseif t == "table" then
            local isArray = (#val > 0)
            local str = isArray and "[" or "{"
            local first = true
            for k, v in pairs(val) do
                if not first then str = str .. ", " end
                first = false
                if isArray then
                    str = str .. serializeJSON(v)
                else
                    str = str .. string.format("%q", tostring(k)) .. ": " .. serializeJSON(v)
                end
            end
            return str .. (isArray and "]" or "}")
        end
        return "null"
    end
    
    local jsonStr = serializeJSON(data)
    if love.filesystem then
        love.filesystem.write(filename, jsonStr)
    end
    
    local f = io.open("f:/Projects/BalatroFB/" .. filename, "w")
    if f then
        f:write(jsonStr)
        f:close()
    end
end

function SaveManager.updateHighScore(yards)
    if yards > SaveManager.data.highScoreYards then
        SaveManager.data.highScoreYards = yards
        SaveManager.save()
    end
end

function SaveManager.recordTouchdown()
    SaveManager.data.totalTouchdowns = SaveManager.data.totalTouchdowns + 1
    SaveManager.save()
    SteamManager.unlockAchievement("ACH_FIRST_TD")
end

function SaveManager.markCardMastered(cardName)
    if not SaveManager.data.masteredCards then SaveManager.data.masteredCards = {} end
    if not SaveManager.data.masteredCards[cardName] then
        SaveManager.data.masteredCards[cardName] = true
        SaveManager.save()
    end
end

function SaveManager.isCardMastered(cardName)
    if not SaveManager.data or not SaveManager.data.masteredCards then return false end
    return SaveManager.data.masteredCards[cardName] == true
end

function math.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

return SaveManager
