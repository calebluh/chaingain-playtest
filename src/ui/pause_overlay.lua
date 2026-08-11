-- src/ui/pause_overlay.lua
local SettingsData = require("src.data.settings_data")
local SoundManager = require("src.engine.sound_manager")
local SaveManager = require("src.engine.save_manager")

local PauseOverlay = {}

PauseOverlay.viewMode = "MAIN" -- "MAIN" or "SETTINGS"
PauseOverlay.activeTab = 1 -- 1: GAME, 2: VIDEO, 3: GRAPHICS, 4: AUDIO
PauseOverlay.tabs = { "GAME", "VIDEO", "GRAPHICS", "AUDIO" }
PauseOverlay.showAbandonConfirm = false

local function inRect(px, py, rx, ry, rw, rh)
    return px and py and px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

local function getMousePos()
    return love.mouse.getPosition()
end

local function drawShadowText(text, x, y, r, g, b, scale, align, limit)
    scale = scale or 1
    love.graphics.setColor(0, 0, 0, 0.95)
    if align and limit then
        love.graphics.printf(text, x + 1, y + 1, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x + 1, y + 1, 0, scale, scale)
    end
    
    love.graphics.setColor(r or 1, g or 1, b or 1, 1)
    if align and limit then
        love.graphics.printf(text, x, y, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x, y, 0, scale, scale)
    end
end

local function drawChunkyButton(label, x, y, w, h, bgColor, hoverColor)
    local mx, my = getMousePos()
    local hover = inRect(mx, my, x, y, w, h)
    local col = hover and (hoverColor or {1.0, 0.45, 0.45}) or (bgColor or {0.95, 0.3, 0.3})

    -- Drop Shadow
    love.graphics.setColor(0.06, 0.08, 0.12, 0.8)
    love.graphics.rectangle("fill", x, y + 3, w, h, 8, 8)

    -- Button Body
    love.graphics.setColor(col)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)

    -- Top Highlight
    love.graphics.setColor(1, 1, 1, 0.18)
    love.graphics.rectangle("fill", x, y, w, h * 0.4, 8, 8)

    -- Text
    drawShadowText(label, x, y + (h / 2) - 8, 1, 1, 1, 1.1, "center", w)
    return hover
end

function PauseOverlay.syncAndSave()
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
    SoundManager.updateVolume()

    if love.window then
        pcall(love.window.setFullscreen, _G.CONFIG_FULLSCREEN or false)
        pcall(love.window.setVSync, (_G.CONFIG_VSYNC ~= false) and 1 or 0)
    end
end

function PauseOverlay:enter()
    local StateManager = require("src.states.state_manager")
    self.isMainMenu = (StateManager.currentState == require("src.states.state_menu"))
    
    if self.isMainMenu then
        self.viewMode = "SETTINGS"
    else
        self.viewMode = "MAIN"
    end
    
    self.activeTab = 1
    self.showAbandonConfirm = false
end

function PauseOverlay:draw()
    local mx, my = getMousePos()

    if self.viewMode == "MAIN" then
        self:drawMainModal(mx, my)
    elseif self.viewMode == "SETTINGS" then
        self:drawSettingsModal(mx, my)
    end
end

function PauseOverlay:drawMainModal(mx, my)
    local w, h = 340, 360
    local x = (960 - w) / 2
    local y = (540 - h) / 2

    -- Modal Container Window (Balatro Style Dark Slate)
    love.graphics.setColor(0.129, 0.153, 0.176, 0.98)
    love.graphics.rectangle("fill", x, y, w, h, 12, 12)
    love.graphics.setColor(0.0, 0.76, 1.0, 0.9)
    love.graphics.setLineWidth(2.5)
    love.graphics.rectangle("line", x, y, w, h, 12, 12)
    love.graphics.setLineWidth(1)

    -- Options Header
    drawShadowText("CHAIN GAIN", x, y + 18, 1, 0.84, 0, 1.4, "center", w)

    local btnW = 280
    local btnH = 42
    local btnX = x + (w - btnW) / 2
    local startY = y + 58
    local gap = 48

    -- Button 1: SETTINGS
    drawChunkyButton("SETTINGS", btnX, startY, btnW, btnH, {0.95, 0.3, 0.3}, {1.0, 0.45, 0.45})

    -- Button 2: COLLECTION
    drawChunkyButton("COLLECTION", btnX, startY + gap, btnW, btnH, {0.0, 0.76, 1.0}, {0.3, 0.85, 1.0})

    -- Button 3: ABANDON RUN / MAIN MENU
    local menuLabel = SaveManager.hasActiveRun() and "ABANDON RUN" or "MAIN MENU"
    if self.showAbandonConfirm then menuLabel = "CONFIRM QUIT?" end
    drawChunkyButton(menuLabel, btnX, startY + gap * 2, btnW, btnH, {0.85, 0.25, 0.25}, {1.0, 0.35, 0.35})

    -- Button 4 (Bottom Amber Pill): BACK / RESUME
    local backY = y + h - 54
    drawChunkyButton("RESUME", btnX, backY, btnW, 44, {1.0, 0.6, 0.0}, {1.0, 0.75, 0.2})
end

function PauseOverlay:drawSettingsModal(mx, my)
    local w, h = 640, 440
    local x = (960 - w) / 2
    local y = (540 - h) / 2

    -- Modal Container Box (Dark Slate Balatro Style)
    love.graphics.setColor(0.129, 0.153, 0.176, 0.98)
    love.graphics.rectangle("fill", x, y, w, h, 12, 12)
    love.graphics.setColor(0.0, 0.76, 1.0, 0.9)
    love.graphics.setLineWidth(2.5)
    love.graphics.rectangle("line", x, y, w, h, 12, 12)
    love.graphics.setLineWidth(1)

    -- Top Tabs: [ Game ] [ Video ] [ Graphics ] [ Audio ]
    local tabCount = #self.tabs
    local tabW = 125
    local tabH = 34
    local startTabX = x + (w - (tabCount * 135 - 10)) / 2
    local tabY = y + 25

    for i, name in ipairs(self.tabs) do
        local tx = startTabX + (i - 1) * 135
        local isSel = (self.activeTab == i)
        local hover = inRect(mx, my, tx, tabY, tabW, tabH)

        -- Indicator Red Arrow above active tab
        if isSel then
            love.graphics.setColor(0.95, 0.3, 0.3)
            love.graphics.polygon("fill", tx + tabW/2 - 6, tabY - 8, tx + tabW/2 + 6, tabY - 8, tx + tabW/2, tabY - 2)
        end

        local col = isSel and {0.95, 0.3, 0.3} or (hover and {0.35, 0.4, 0.48} or {0.2, 0.23, 0.29})
        love.graphics.setColor(col)
        love.graphics.rectangle("fill", tx, tabY, tabW, tabH, 6, 6)
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.rectangle("fill", tx, tabY, tabW, tabH * 0.4, 6, 6)

        drawShadowText(name, tx, tabY + 8, 1, 1, 1, 1.0, "center", tabW)
    end

    -- Inner Options Area
    local boxX = x + 20
    local boxY = y + 72
    local boxW = w - 40
    local boxH = h - 140
    love.graphics.setColor(0.09, 0.11, 0.14, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 8, 8)

    self:drawTabOptions(boxX, boxY, boxW, boxH, mx, my)

    -- Bottom Amber Back Button
    local backW = w - 40
    local backX = x + 20
    local backY = y + h - 52
    drawChunkyButton("BACK", backX, backY, backW, 40, {1.0, 0.6, 0.0}, {1.0, 0.75, 0.2})
end

function PauseOverlay:drawTabOptions(bx, by, bw, bh, mx, my)
    local startY = by + 12
    local stepY = 62

    if self.activeTab == 1 then -- GAME
        self:drawStepperRow("Game Execution Speed", string.format("%.1fx", SettingsData.gameSpeed or 1.0), bx + 20, startY, bw - 40, 1, mx, my)
        self:drawSliderRow("Screenshake", math.floor((_G.CONFIG_SCREENSHAKE or 1.0) * 100), 0, 100, bx + 20, startY + stepY, bw - 40, 2, mx, my)
        self:drawCheckboxRow("Stadium Pulse System", SettingsData.stadiumPulseEnabled, bx + 20, startY + stepY * 2, bw - 40, 3, mx, my)
        self:drawCheckboxRow("RPO Active Read Minigame", SettingsData.rpoMinigameEnabled, bx + 20, startY + stepY * 3, bw - 40, 4, mx, my)

    elseif self.activeTab == 2 then -- VIDEO
        self:drawStepperRow("Window Mode", _G.CONFIG_FULLSCREEN and "Fullscreen" or "Windowed", bx + 20, startY + 20, bw - 40, 1, mx, my)
        self:drawStepperRow("Vertical Sync", _G.CONFIG_VSYNC and "VSync On" or "VSync Off", bx + 20, startY + 20 + stepY, bw - 40, 2, mx, my)

    elseif self.activeTab == 3 then -- GRAPHICS
        self:drawCheckboxRow("CRT Shader Filter", _G.CONFIG_ENABLE_CRT, bx + 20, startY, bw - 40, 1, mx, my)
        self:drawCheckboxRow("Show FPS Counter", _G.CONFIG_SHOW_FPS, bx + 20, startY + stepY, bw - 40, 2, mx, my)
        self:drawCheckboxRow("Turf & Weather Stains", SettingsData.weatherStains, bx + 20, startY + stepY * 2, bw - 40, 3, mx, my)
        self:drawStepperRow("Field Impact FX", SettingsData.impactFx or "FULL", bx + 20, startY + stepY * 3, bw - 40, 4, mx, my)

    elseif self.activeTab == 4 then -- AUDIO
        self:drawSliderRow("Master Volume", math.floor((SettingsData.masterVolume or 0.8) * 100), 0, 100, bx + 20, startY, bw - 40, 1, mx, my)
        self:drawSliderRow("SFX Volume", math.floor((_G.CONFIG_SFX_VOLUME or 0.8) * 100), 0, 100, bx + 20, startY + stepY, bw - 40, 2, mx, my)
        self:drawSliderRow("Music Volume", math.floor((_G.CONFIG_MUSIC_VOLUME or 0.5) * 100), 0, 100, bx + 20, startY + stepY * 2, bw - 40, 3, mx, my)
        self:drawCheckboxRow("Mute on Focus Lost", _G.CONFIG_MUTE_ON_FOCUS_LOST, bx + 20, startY + stepY * 3, bw - 40, 4, mx, my)
    end
end

-- Stepper Control: < Value >
function PauseOverlay:drawStepperRow(title, valStr, x, y, w, index, mx, my)
    drawShadowText(title, x, y, 0.9, 0.9, 0.9, 1.0, "center", w)

    local btnW = 160
    local btnH = 30
    local btnX = x + (w - btnW) / 2
    local btnY = y + 20

    local leftHover = inRect(mx, my, btnX - 34, btnY, 28, btnH)
    local rightHover = inRect(mx, my, btnX + btnW + 6, btnY, 28, btnH)

    -- Left Arrow Button <
    love.graphics.setColor(leftHover and {1.0, 0.45, 0.45} or {0.95, 0.3, 0.3})
    love.graphics.rectangle("fill", btnX - 34, btnY, 28, btnH, 5, 5)
    drawShadowText("<", btnX - 34, btnY + 6, 1, 1, 1, 1.1, "center", 28)

    -- Middle Value Pill
    love.graphics.setColor(0.95, 0.3, 0.3)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 5, 5)
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH * 0.4, 5, 5)
    drawShadowText(valStr, btnX, btnY + 7, 1, 1, 1, 1.05, "center", btnW)

    -- Right Arrow Button >
    love.graphics.setColor(rightHover and {1.0, 0.45, 0.45} or {0.95, 0.3, 0.3})
    love.graphics.rectangle("fill", btnX + btnW + 6, btnY, 28, btnH, 5, 5)
    drawShadowText(">", btnX + btnW + 6, btnY + 6, 1, 1, 1, 1.1, "center", 28)
end

-- Slider Control
function PauseOverlay:drawSliderRow(title, valNum, minV, maxV, x, y, w, index, mx, my)
    drawShadowText(title, x, y, 0.9, 0.9, 0.9, 1.0, "center", w)

    local trackW = 240
    local trackH = 14
    local trackX = x + (w - trackW) / 2 - 20
    local trackY = y + 24

    -- Track Fill
    love.graphics.setColor(0.12, 0.14, 0.18, 1)
    love.graphics.rectangle("fill", trackX, trackY, trackW, trackH, 6, 6)

    local pct = math.clamp((valNum - minV) / math.max(1, (maxV - minV)), 0, 1)
    love.graphics.setColor(0.95, 0.3, 0.3)
    love.graphics.rectangle("fill", trackX, trackY, trackW * pct, trackH, 6, 6)

    -- Badge on Right
    love.graphics.setColor(0.95, 0.3, 0.3)
    love.graphics.rectangle("fill", trackX + trackW + 12, trackY - 2, 40, 18, 4, 4)
    drawShadowText(valNum .. "%", trackX + trackW + 12, trackY, 1, 1, 1, 0.85, "center", 40)
end

-- Checkbox Control
function PauseOverlay:drawCheckboxRow(title, isChecked, x, y, w, index, mx, my)
    local boxSize = 24
    local boxX = x + w - 40
    local boxY = y + 4

    drawShadowText(title, x, y + 6, 0.9, 0.9, 0.9, 1.0)

    local hover = inRect(mx, my, boxX, boxY, boxSize, boxSize)

    love.graphics.setColor(isChecked and {0.95, 0.3, 0.3} or (hover and {0.25, 0.3, 0.38} or {0.14, 0.16, 0.20}))
    love.graphics.rectangle("fill", boxX, boxY, boxSize, boxSize, 5, 5)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxSize, boxSize, 5, 5)
    love.graphics.setLineWidth(1)

    if isChecked then
        drawShadowText("✓", boxX, boxY + 2, 1, 1, 1, 1.2, "center", boxSize)
    end
end

function PauseOverlay:mousepressed(x, y, button)
    if button ~= 1 then return end
    local StateManager = require("src.states.state_manager")

    if self.viewMode == "MAIN" then
        local w, h = 340, 360
        local modalX = (960 - w) / 2
        local modalY = (540 - h) / 2
        local btnW = 280
        local btnH = 42
        local btnX = modalX + (w - btnW) / 2
        local startY = modalY + 58
        local gap = 48

        -- SETTINGS button
        if inRect(x, y, btnX, startY, btnW, btnH) then
            SoundManager.playSFX("click")
            self.viewMode = "SETTINGS"
            return
        end

        -- COLLECTION button
        if inRect(x, y, btnX, startY + gap, btnW, btnH) then
            SoundManager.playSFX("click")
            StateManager.closeOverlay()
            local StateCollections = require("src.states.state_collections")
            StateManager.switch(StateCollections)
            return
        end

        -- MAIN MENU / ABANDON RUN button
        if inRect(x, y, btnX, startY + gap * 2, btnW, btnH) then
            SoundManager.playSFX("click")
            if not self.showAbandonConfirm then
                self.showAbandonConfirm = true
            else
                SaveManager.clearActiveRun()
                StateManager.closeOverlay()
                local StateMenu = require("src.states.state_menu")
                StateManager.switch(StateMenu)
            end
            return
        end

        -- RESUME button (bottom amber pill)
        local backY = modalY + h - 54
        if inRect(x, y, btnX, backY, btnW, 44) then
            SoundManager.playSFX("click")
            StateManager.closeOverlay()
            return
        end

    elseif self.viewMode == "SETTINGS" then
        local w, h = 640, 440
        local modalX = (960 - w) / 2
        local modalY = (540 - h) / 2

        -- Tab Clicks
        local tabCount = #self.tabs
        local tabW = 125
        local tabH = 34
        local startTabX = modalX + (w - (tabCount * 135 - 10)) / 2
        local tabY = modalY + 25

        for i = 1, tabCount do
            local tx = startTabX + (i - 1) * 135
            if inRect(x, y, tx, tabY, tabW, tabH) then
                SoundManager.playSFX("click")
                self.activeTab = i
                return
            end
        end

        -- Check Option Clicks inside active tab
        local bx = modalX + 20
        local by = modalY + 72
        local bw = w - 40
        local startY = by + 12
        local stepY = 62

        if self.activeTab == 1 then -- GAME
            -- Game speed stepper
            local btnW, btnH = 160, 30
            local btnX = bx + (bw - btnW) / 2
            local btnY = startY + 20
            if inRect(x, y, btnX - 34, btnY, 28, btnH) or inRect(x, y, btnX, btnY, btnW + 34, btnH) then
                SettingsData.gameSpeed = (SettingsData.gameSpeed == 1.0) and 1.5 or ((SettingsData.gameSpeed == 1.5) and 2.0 or 1.0)
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end

            -- Screenshake slider
            local trackX = bx + (bw - 240) / 2 - 20
            local trackY = startY + stepY + 20
            if inRect(x, y, trackX - 10, trackY - 10, 290, 34) then
                local pct = math.clamp((x - trackX) / 240, 0, 1)
                _G.CONFIG_SCREENSHAKE = pct > 0.6 and 1.0 or (pct > 0.2 and 0.5 or 0.0)
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end

            -- Stadium pulse checkbox
            if inRect(x, y, bx + 20, startY + stepY * 2, bw - 40, 32) then
                SettingsData.stadiumPulseEnabled = not SettingsData.stadiumPulseEnabled
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end

            -- RPO minigame checkbox
            if inRect(x, y, bx + 20, startY + stepY * 3, bw - 40, 32) then
                SettingsData.rpoMinigameEnabled = not SettingsData.rpoMinigameEnabled
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end

        elseif self.activeTab == 2 then -- VIDEO
            -- Window mode
            local btnW, btnH = 160, 30
            local btnX = bx + (bw - btnW) / 2
            local btnY = startY + 40
            if inRect(x, y, btnX - 34, btnY, btnW + 68, btnH) then
                _G.CONFIG_FULLSCREEN = not _G.CONFIG_FULLSCREEN
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end

            -- VSync
            local vsyncY = startY + 40 + stepY
            if inRect(x, y, btnX - 34, vsyncY, btnW + 68, btnH) then
                _G.CONFIG_VSYNC = not _G.CONFIG_VSYNC
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end

        elseif self.activeTab == 3 then -- GRAPHICS
            if inRect(x, y, bx + 20, startY, bw - 40, 32) then
                _G.CONFIG_ENABLE_CRT = not _G.CONFIG_ENABLE_CRT
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end
            if inRect(x, y, bx + 20, startY + stepY, bw - 40, 32) then
                _G.CONFIG_SHOW_FPS = not _G.CONFIG_SHOW_FPS
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end
            if inRect(x, y, bx + 20, startY + stepY * 2, bw - 40, 32) then
                SettingsData.weatherStains = not SettingsData.weatherStains
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end
            local btnW, btnH = 160, 30
            local btnX = bx + (bw - btnW) / 2
            local fxY = startY + stepY * 3 + 20
            if inRect(x, y, btnX - 34, fxY, btnW + 68, btnH) then
                SettingsData.impactFx = (SettingsData.impactFx == "FULL") and "LOW" or ((SettingsData.impactFx == "LOW") and "OFF" or "FULL")
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end

        elseif self.activeTab == 4 then -- AUDIO
            -- Master volume slider
            local trackX = bx + (bw - 240) / 2 - 20
            local trackY = startY + 20
            if inRect(x, y, trackX - 10, trackY - 10, 290, 34) then
                local pct = math.clamp((x - trackX) / 240, 0, 1)
                SettingsData.masterVolume = math.floor(pct * 10 + 0.5) / 10
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end
            -- SFX volume slider
            local sfxY = startY + stepY + 20
            if inRect(x, y, trackX - 10, sfxY - 10, 290, 34) then
                local pct = math.clamp((x - trackX) / 240, 0, 1)
                _G.CONFIG_SFX_VOLUME = math.floor(pct * 10 + 0.5) / 10
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end
            -- Music volume slider
            local musicY = startY + stepY * 2 + 20
            if inRect(x, y, trackX - 10, musicY - 10, 290, 34) then
                local pct = math.clamp((x - trackX) / 240, 0, 1)
                _G.CONFIG_MUSIC_VOLUME = math.floor(pct * 10 + 0.5) / 10
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end
            -- Mute on focus lost
            if inRect(x, y, bx + 20, startY + stepY * 3, bw - 40, 32) then
                _G.CONFIG_MUTE_ON_FOCUS_LOST = not _G.CONFIG_MUTE_ON_FOCUS_LOST
                SoundManager.playSFX("click")
                self.syncAndSave()
                return
            end
        end

        -- BACK button in Settings
        local backW = w - 40
        local backX = modalX + 20
        local backY = modalY + h - 52
        if inRect(x, y, backX, backY, backW, 40) then
            SoundManager.playSFX("click")
            if self.isMainMenu then
                local StateManager = require("src.states.state_manager")
                StateManager.closeOverlay()
            else
                self.viewMode = "MAIN"
            end
            return
        end
    end
end

function PauseOverlay:keypressed(key)
    local StateManager = require("src.states.state_manager")
    if key == "escape" then
        SoundManager.playSFX("click")
        if self.viewMode == "SETTINGS" then
            if self.isMainMenu then
                StateManager.closeOverlay()
            else
                self.viewMode = "MAIN"
            end
        else
            StateManager.closeOverlay()
        end
    elseif key == "tab" or key == "right" or key == "d" then
        if self.viewMode == "SETTINGS" then
            self.activeTab = (self.activeTab % #self.tabs) + 1
            SoundManager.playSFX("click")
        end
    elseif key == "left" or key == "a" then
        if self.viewMode == "SETTINGS" then
            self.activeTab = self.activeTab == 1 and #self.tabs or self.activeTab - 1
            SoundManager.playSFX("click")
        end
    end
end

return PauseOverlay
