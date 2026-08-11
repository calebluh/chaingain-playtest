-- src/states/state_settings.lua
local SettingsData = require("src.data.settings_data")
local StateManager = require("src.states.state_manager")
local SoundManager = require("src.engine.sound_manager")
local SaveManager = require("src.engine.save_manager")
local StateMenu = require("src.states.state_menu")

local StateSettings = {}

StateSettings.activeTab = 1
StateSettings.tabs = { "GAMEPLAY", "VISUALS", "AUDIO", "DISPLAY & STREAMER" }

local function checkHover(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end

function StateSettings.syncAndSave()
    SaveManager.data.settings.enableCRT = _G.CONFIG_ENABLE_CRT or false
    SaveManager.data.settings.screenshake = _G.CONFIG_SCREENSHAKE or 1.0
    SaveManager.data.settings.sfxVolume = _G.CONFIG_SFX_VOLUME or 0.8
    SaveManager.data.settings.musicVolume = _G.CONFIG_MUSIC_VOLUME or 0.5
    SaveManager.data.settings.fullscreen = _G.CONFIG_FULLSCREEN or false
    SaveManager.data.settings.vsync = _G.CONFIG_VSYNC ~= false
    SaveManager.data.settings.muteOnFocus = _G.CONFIG_MUTE_ON_FOCUS_LOST or false
    SaveManager.data.settings.showFPS = _G.CONFIG_SHOW_FPS or false
    SaveManager.data.settings.masterVolume = SettingsData.masterVolume or 0.8
    SaveManager.data.settings.stadiumPulseEnabled = SettingsData.stadiumPulseEnabled
    SaveManager.data.settings.gameSpeed = SettingsData.gameSpeed
    SaveManager.data.settings.impactFx = SettingsData.impactFx
    SaveManager.data.settings.weatherStains = SettingsData.weatherStains
    SaveManager.data.settings.reducedFlashing = SettingsData.reducedFlashing
    SaveManager.data.settings.streamerMode = SettingsData.streamerMode
    SaveManager.data.settings.profanityFilter = SettingsData.profanityFilter

    SaveManager.save()

    if love.window then
        pcall(love.window.setFullscreen, _G.CONFIG_FULLSCREEN or false)
        pcall(love.window.setVSync, (_G.CONFIG_VSYNC ~= false) and 1 or 0)
    end
end

function StateSettings:enter()
    self.activeTab = 1
end

function StateSettings:draw()
    -- Outer Modal Window (fits 960x540 screen)
    love.graphics.setColor(0.10, 0.12, 0.16, 0.96)
    love.graphics.rectangle("fill", 80, 25, 800, 485, 10, 10)
    love.graphics.setColor(0.0, 0.76, 1.0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 80, 25, 800, 485, 10, 10)
    love.graphics.setLineWidth(1)

    -- Header Tabs
    for i, name in ipairs(StateSettings.tabs) do
        local tx = 110 + (i - 1) * 180
        local isSel = (StateSettings.activeTab == i)
        local hover = checkHover(tx, 45, 165, 32)
        if isSel then
            love.graphics.setColor(0.0, 0.58, 1.0, 1)
        elseif hover then
            love.graphics.setColor(0.25, 0.3, 0.38, 1)
        else
            love.graphics.setColor(0.16, 0.18, 0.23, 1)
        end
        love.graphics.rectangle("fill", tx, 45, 165, 32, 6, 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(name, tx, 54, 165, "center")
    end

    -- Options List Display Box
    love.graphics.setColor(0.13, 0.15, 0.19, 1)
    love.graphics.rectangle("fill", 100, 90, 760, 360, 8, 8)
    love.graphics.setColor(0.25, 0.3, 0.38, 0.5)
    love.graphics.rectangle("line", 100, 90, 760, 360, 8, 8)

    StateSettings.drawCategoryOptions()

    -- Clickable BACK button
    local hoverBack = checkHover(110, 462, 110, 34)
    love.graphics.setColor(hoverBack and {0.95, 0.3, 0.3} or {0.8, 0.2, 0.2})
    love.graphics.rectangle("fill", 110, 462, 110, 34, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("BACK", 110, 471, 110, "center")

    -- Footer Navigation Hint
    love.graphics.setColor(0.7, 0.75, 0.8, 1)
    love.graphics.print("[ESC] BACK    [ARROWS / MOUSE] SWITCH TABS    [CLICK / ENTER] TOGGLE", 240, 471)
end

function StateSettings.drawCategoryOptions()
    local startY = 110
    local stepY = 80

    if StateSettings.activeTab == 1 then
        StateSettings.drawRow("CRT Shader Effect", _G.CONFIG_ENABLE_CRT and "ON" or "OFF", startY, 0)
        StateSettings.drawRow("Screen Shake Intensity", (_G.CONFIG_SCREENSHAKE >= 1.0) and "100%" or ((_G.CONFIG_SCREENSHAKE > 0) and "50%" or "OFF"), startY, 1)
        StateSettings.drawRow("Game Execution Speed", string.format("%.1fx", SettingsData.gameSpeed or 1.0), startY, 2)
        StateSettings.drawRow("Stadium Pulse System", SettingsData.stadiumPulseEnabled and "ON" or "OFF", startY, 3)

    elseif StateSettings.activeTab == 2 then
        StateSettings.drawRow("Show FPS Counter", _G.CONFIG_SHOW_FPS and "ON" or "OFF", startY, 0)
        StateSettings.drawRow("Field Impact FX Intensity", SettingsData.impactFx or "FULL", startY, 1)
        StateSettings.drawRow("Turf & Weather Stains", SettingsData.weatherStains and "ON" or "OFF", startY, 2)
        StateSettings.drawRow("Flash Effect Dampener", SettingsData.reducedFlashing and "ON" or "OFF", startY, 3)

    elseif StateSettings.activeTab == 3 then
        StateSettings.drawRow("Master Volume", math.floor((SettingsData.masterVolume or 0.8) * 100 + 0.5) .. "%", startY, 0)
        StateSettings.drawRow("SFX Volume", math.floor((_G.CONFIG_SFX_VOLUME or 0.8) * 100 + 0.5) .. "%", startY, 1)
        StateSettings.drawRow("Music Volume", math.floor((_G.CONFIG_MUSIC_VOLUME or 0.5) * 100 + 0.5) .. "%", startY, 2)
        StateSettings.drawRow("Mute on Focus Lost", _G.CONFIG_MUTE_ON_FOCUS_LOST and "ON" or "OFF", startY, 3)

    elseif StateSettings.activeTab == 4 then
        StateSettings.drawRow("Fullscreen Mode", _G.CONFIG_FULLSCREEN and "ON" or "OFF", startY, 0)
        StateSettings.drawRow("Vertical Sync (VSync)", _G.CONFIG_VSYNC and "ON" or "OFF", startY, 1)
        StateSettings.drawRow("Streamer Mode (DMCA Free)", SettingsData.streamerMode and "ON" or "OFF", startY, 2)
        StateSettings.drawRow("Profanity & Trash Talk Filter", SettingsData.profanityFilter and "CENSORED" or "UNCENSORED", startY, 3)
    end
end

function StateSettings.drawRow(label, valueStr, startY, index)
    local rowY = startY + index * 75
    local rowX = 130
    local rowW = 700
    local rowH = 60

    local hover = checkHover(rowX, rowY, rowW, rowH)
    
    love.graphics.setColor(hover and {0.18, 0.22, 0.28, 1} or {0.15, 0.17, 0.22, 1})
    love.graphics.rectangle("fill", rowX, rowY, rowW, rowH, 6, 6)
    love.graphics.setColor(0.3, 0.35, 0.4, 0.6)
    love.graphics.rectangle("line", rowX, rowY, rowW, rowH, 6, 6)

    love.graphics.setColor(0.95, 0.95, 0.95, 1)
    love.graphics.print(label, rowX + 20, rowY + 20)

    -- Pill value indicator
    local btnX = rowX + rowW - 160
    local btnY = rowY + 12
    local btnW = 140
    local btnH = 36

    local isTrue = (valueStr == "ON" or valueStr == "FULL" or valueStr == "CENSORED" or valueStr == "100%")
    love.graphics.setColor(isTrue and {0.0, 0.58, 1.0} or {0.3, 0.35, 0.45})
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(valueStr, btnX, btnY + 9, btnW, "center")
end

function StateSettings:mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Check BACK button
    if checkHover(110, 462, 110, 34) then
        SoundManager.playSFX("click")
        StateManager.switch(StateMenu)
        return
    end

    -- Check Header Tabs
    for i, name in ipairs(StateSettings.tabs) do
        local tx = 110 + (i - 1) * 180
        if checkHover(tx, 45, 165, 32) then
            StateSettings.activeTab = i
            SoundManager.playSFX("click")
            return
        end
    end
    
    -- Check Option Rows
    local startY = 110
    local rowX = 130
    local rowW = 700
    local rowH = 60

    local function rowClicked(index)
        return checkHover(rowX, startY + index * 75, rowW, rowH)
    end

    if StateSettings.activeTab == 1 then
        if rowClicked(0) then
            _G.CONFIG_ENABLE_CRT = not _G.CONFIG_ENABLE_CRT
        elseif rowClicked(1) then
            _G.CONFIG_SCREENSHAKE = (_G.CONFIG_SCREENSHAKE >= 1.0) and 0.5 or ((_G.CONFIG_SCREENSHAKE > 0) and 0.0 or 1.0)
        elseif rowClicked(2) then
            SettingsData.gameSpeed = (SettingsData.gameSpeed == 1.0) and 1.5 or ((SettingsData.gameSpeed == 1.5) and 2.0 or 1.0)
        elseif rowClicked(3) then
            SettingsData.stadiumPulseEnabled = not SettingsData.stadiumPulseEnabled
        end

    elseif StateSettings.activeTab == 2 then
        if rowClicked(0) then
            _G.CONFIG_SHOW_FPS = not _G.CONFIG_SHOW_FPS
        elseif rowClicked(1) then
            SettingsData.impactFx = (SettingsData.impactFx == "FULL") and "LOW" or ((SettingsData.impactFx == "LOW") and "OFF" or "FULL")
        elseif rowClicked(2) then
            SettingsData.weatherStains = not SettingsData.weatherStains
        elseif rowClicked(3) then
            SettingsData.reducedFlashing = not SettingsData.reducedFlashing
        end

    elseif StateSettings.activeTab == 3 then
        if rowClicked(0) then
            SettingsData.masterVolume = ((SettingsData.masterVolume or 0.8) >= 1.0) and 0.0 or math.min(1.0, (SettingsData.masterVolume or 0.8) + 0.1)
        elseif rowClicked(1) then
            _G.CONFIG_SFX_VOLUME = ((_G.CONFIG_SFX_VOLUME or 0.8) >= 1.0) and 0.0 or math.min(1.0, (_G.CONFIG_SFX_VOLUME or 0.8) + 0.1)
        elseif rowClicked(2) then
            _G.CONFIG_MUSIC_VOLUME = ((_G.CONFIG_MUSIC_VOLUME or 0.5) >= 1.0) and 0.0 or math.min(1.0, (_G.CONFIG_MUSIC_VOLUME or 0.5) + 0.1)
        elseif rowClicked(3) then
            _G.CONFIG_MUTE_ON_FOCUS_LOST = not _G.CONFIG_MUTE_ON_FOCUS_LOST
        end

    elseif StateSettings.activeTab == 4 then
        if rowClicked(0) then
            _G.CONFIG_FULLSCREEN = not _G.CONFIG_FULLSCREEN
        elseif rowClicked(1) then
            _G.CONFIG_VSYNC = not _G.CONFIG_VSYNC
        elseif rowClicked(2) then
            SettingsData.streamerMode = not SettingsData.streamerMode
        elseif rowClicked(3) then
            SettingsData.profanityFilter = not SettingsData.profanityFilter
        end
    end

    SoundManager.playSFX("click")
    StateSettings.syncAndSave()
end

function StateSettings:keypressed(key)
    if key == "escape" then
        StateManager.switch(StateMenu)
    elseif key == "tab" or key == "right" then
        StateSettings.activeTab = (StateSettings.activeTab % #StateSettings.tabs) + 1
        SoundManager.playSFX("click")
    elseif key == "left" then
        StateSettings.activeTab = StateSettings.activeTab == 1 and #StateSettings.tabs or StateSettings.activeTab - 1
        SoundManager.playSFX("click")
    end
end

return StateSettings
