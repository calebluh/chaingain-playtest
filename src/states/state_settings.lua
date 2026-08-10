-- src/states/state_settings.lua
local SettingsData = require("src.data.settings_data")
local StateManager = require("src.states.state_manager")
local SoundManager = require("src.engine.sound_manager")
local StateSettings = {}

StateSettings.activeTab = 1
StateSettings.tabs = { "GAMEPLAY", "VISUALS", "AUDIO", "STREAMER" }

function StateSettings.draw()
    -- Outer Modal Window
    love.graphics.setColor(0.10, 0.12, 0.16, 0.95)
    love.graphics.rectangle("fill", 80, 50, 800, 540, 8, 8)
    love.graphics.setColor(0.3, 0.35, 0.4, 1)
    love.graphics.rectangle("line", 80, 50, 800, 540, 8, 8)

    -- Header Tabs
    for i, name in ipairs(StateSettings.tabs) do
        local tx = 110 + (i - 1) * 180
        if StateSettings.activeTab == i then
            love.graphics.setColor(0.2, 0.5, 0.9, 1)
        else
            love.graphics.setColor(0.18, 0.2, 0.25, 1)
        end
        love.graphics.rectangle("fill", tx, 75, 160, 32, 4, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(name, tx + 35, 84)
    end

    -- Options List Display
    love.graphics.setColor(0.15, 0.18, 0.22, 1)
    love.graphics.rectangle("fill", 110, 120, 740, 410, 6, 6)

    StateSettings.drawCategoryOptions()

    -- Footer Navigation
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("[ESC] BACK    [ARROWS] NAVIGATE    [SPACE / ENTER] TOGGLE", 120, 550)
end

function StateSettings.drawCategoryOptions()
    love.graphics.setColor(1, 1, 1, 1)
    local y = 145

    if StateSettings.activeTab == 1 then
        StateSettings.drawRow("Stadium Pulse System", SettingsData.stadiumPulseEnabled and "ON" or "OFF", y)
        StateSettings.drawRow("Deafening Pulse Counter-Scaling", SettingsData.pulseCounterScaling and "ON" or "OFF", y + 40)
        StateSettings.drawRow("RPO Active Read Minigame", SettingsData.rpoMinigameEnabled and "ON" or "OFF", y + 80)
        StateSettings.drawRow("Game Execution Speed", tostring(SettingsData.gameSpeed) .. "x", y + 120)

    elseif StateSettings.activeTab == 2 then
        StateSettings.drawRow("Field Impact FX Intensity", SettingsData.impactFx, y)
        StateSettings.drawRow("Turf & Weather Stains", SettingsData.weatherStains and "ON" or "OFF", y + 40)
        StateSettings.drawRow("Turnover Sequence Animation", SettingsData.turnoverSequence and "ON" or "OFF", y + 80)
        StateSettings.drawRow("Flash Effect Dampener", SettingsData.reducedFlashing and "ON" or "OFF", y + 120)

    elseif StateSettings.activeTab == 3 then
        StateSettings.drawRow("Master Volume", tostring(math.floor(SettingsData.masterVolume * 100)) .. "%", y)
        StateSettings.drawRow("SFX Volume", tostring(math.floor(SettingsData.sfxVolume * 100)) .. "%", y + 40)
        StateSettings.drawRow("Music Volume", tostring(math.floor(SettingsData.musicVolume * 100)) .. "%", y + 80)
        StateSettings.drawRow("Sudden Noise Softener", SettingsData.soundSoftener and "ON" or "OFF", y + 120)

    elseif StateSettings.activeTab == 4 then
        StateSettings.drawRow("Streamer Safe Music (DMCA Free)", SettingsData.streamerMode and "ON" or "OFF", y)
        StateSettings.drawRow("Profanity & Trash Talk Filter", SettingsData.profanityFilter and "CENSORED" or "UNCENSORED", y + 40)
        StateSettings.drawRow("Hide Account / Seed Identifiers", SettingsData.hideUserTag and "ON" or "OFF", y + 80)
    end
end

function StateSettings.drawRow(label, value, y)
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.print(label, 140, y)
    love.graphics.setColor(0.3, 0.7, 1.0, 1)
    love.graphics.print(value, 720, y)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    love.graphics.line(140, y + 28, 810, y + 28)
end

local function checkHover(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end

function StateSettings.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Check tabs
    for i, name in ipairs(StateSettings.tabs) do
        local tx = 110 + (i - 1) * 180
        if checkHover(tx, 75, 160, 32) then
            StateSettings.activeTab = i
            SoundManager.playSFX("click")
            return
        end
    end
    
    -- Check rows
    local rowY = 145
    local function clickedRow(offset) return checkHover(140, rowY + offset * 40, 670, 30) end
    
    if StateSettings.activeTab == 1 then
        if clickedRow(0) then SettingsData.stadiumPulseEnabled = not SettingsData.stadiumPulseEnabled; SoundManager.playSFX("click")
        elseif clickedRow(1) then SettingsData.pulseCounterScaling = not SettingsData.pulseCounterScaling; SoundManager.playSFX("click")
        elseif clickedRow(2) then SettingsData.rpoMinigameEnabled = not SettingsData.rpoMinigameEnabled; SoundManager.playSFX("click")
        elseif clickedRow(3) then SettingsData.gameSpeed = (SettingsData.gameSpeed == 1.0) and 1.5 or 1.0; SoundManager.playSFX("click") end
    elseif StateSettings.activeTab == 2 then
        if clickedRow(0) then SettingsData.impactFx = (SettingsData.impactFx == "FULL") and "LOW" or "FULL"; SoundManager.playSFX("click")
        elseif clickedRow(1) then SettingsData.weatherStains = not SettingsData.weatherStains; SoundManager.playSFX("click")
        elseif clickedRow(2) then SettingsData.turnoverSequence = not SettingsData.turnoverSequence; SoundManager.playSFX("click")
        elseif clickedRow(3) then SettingsData.reducedFlashing = not SettingsData.reducedFlashing; SoundManager.playSFX("click") end
    elseif StateSettings.activeTab == 3 then
        if clickedRow(0) then SettingsData.masterVolume = (SettingsData.masterVolume >= 1.0) and 0.0 or (SettingsData.masterVolume + 0.1); SoundManager.playSFX("click")
        elseif clickedRow(1) then SettingsData.sfxVolume = (SettingsData.sfxVolume >= 1.0) and 0.0 or (SettingsData.sfxVolume + 0.1); SoundManager.playSFX("click")
        elseif clickedRow(2) then SettingsData.musicVolume = (SettingsData.musicVolume >= 1.0) and 0.0 or (SettingsData.musicVolume + 0.1); SoundManager.playSFX("click")
        elseif clickedRow(3) then SettingsData.soundSoftener = not SettingsData.soundSoftener; SoundManager.playSFX("click") end
    elseif StateSettings.activeTab == 4 then
        if clickedRow(0) then SettingsData.streamerMode = not SettingsData.streamerMode; SoundManager.playSFX("click")
        elseif clickedRow(1) then SettingsData.profanityFilter = not SettingsData.profanityFilter; SoundManager.playSFX("click")
        elseif clickedRow(2) then SettingsData.hideUserTag = not SettingsData.hideUserTag; SoundManager.playSFX("click") end
    end
end

function StateSettings.keypressed(key)
    if key == "escape" then
        StateManager.switch(require("src.states.state_menu"))
    elseif key == "tab" or key == "right" then
        StateSettings.activeTab = (StateSettings.activeTab % #StateSettings.tabs) + 1
    elseif key == "left" then
        StateSettings.activeTab = StateSettings.activeTab == 1 and #StateSettings.tabs or StateSettings.activeTab - 1
    end
end

return StateSettings
