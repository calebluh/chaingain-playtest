-- src/states/state_settings.lua
local StateManager = require("src.states.state_manager")
local SoundManager = require("src.engine.sound_manager")
local SaveManager = require("src.engine.save_manager")
local SettingsData = require("src.data.settings_data")

local StateSettings = {}

local function checkHover(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
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

function StateSettings:enter()
    self.scrollY = 0
    -- Load from SaveManager if exists, else defaults
    if not SaveManager.data.settings then
        SaveManager.data.settings = {}
    end
    for k, v in pairs(SettingsData) do
        if SaveManager.data.settings[k] == nil then
            SaveManager.data.settings[k] = v
        end
    end
    self.settings = SaveManager.data.settings
end

function StateSettings:exit()
    SaveManager.save()
end

function StateSettings:update(dt)
end

function StateSettings:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    drawShadowText("SETTINGS & CONFIGURATION", 40, 15, 1, 0.84, 0, 1.4)
    drawShadowText("Use Mouse Wheel to scroll | Press ESC to return", 40, 45, 0.7, 0.75, 0.8, 0.85)
    
    local mx, my = love.mouse.getPosition()
    local yPos = 80 + self.scrollY
    
    local function drawHeader(title)
        love.graphics.setColor(0.129, 0.149, 0.192)
        love.graphics.rectangle("fill", 40, yPos, 880, 30, 4, 4)
        drawShadowText(title, 50, yPos + 6, 0.0, 0.76, 1.0, 1.1)
        yPos = yPos + 40
    end
    
    local function drawToggle(key, label)
        local val = self.settings[key]
        local isHover = checkHover(40, yPos, 880, 30)
        if isHover then love.graphics.setColor(0.15, 0.18, 0.22) else love.graphics.setColor(0.1, 0.12, 0.15) end
        love.graphics.rectangle("fill", 40, yPos, 880, 30, 4, 4)
        
        drawShadowText(label, 50, yPos + 6, 0.9, 0.9, 0.9, 1.0)
        drawShadowText(val and "ON" or "OFF", 850, yPos + 6, val and 0.2 or 0.8, val and 0.8 or 0.2, 0.2, 1.0)
        yPos = yPos + 35
    end
    
    local function drawSlider(key, label)
        local val = self.settings[key] or 0
        local isHover = checkHover(40, yPos, 880, 40)
        if isHover then love.graphics.setColor(0.15, 0.18, 0.22) else love.graphics.setColor(0.1, 0.12, 0.15) end
        love.graphics.rectangle("fill", 40, yPos, 880, 40, 4, 4)
        
        drawShadowText(label .. ": " .. math.floor(val * 100) .. "%", 50, yPos + 12, 0.9, 0.9, 0.9, 1.0)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 300, yPos + 15, 580, 10, 4, 4)
        love.graphics.setColor(1.0, 0.84, 0.0)
        love.graphics.rectangle("fill", 300, yPos + 15, 580 * val, 10, 4, 4)
        yPos = yPos + 45
    end
    
    local function drawCycle(key, label, options)
        local val = self.settings[key]
        local isHover = checkHover(40, yPos, 880, 30)
        if isHover then love.graphics.setColor(0.15, 0.18, 0.22) else love.graphics.setColor(0.1, 0.12, 0.15) end
        love.graphics.rectangle("fill", 40, yPos, 880, 30, 4, 4)
        
        drawShadowText(label, 50, yPos + 6, 0.9, 0.9, 0.9, 1.0)
        drawShadowText(tostring(val), 800, yPos + 6, 0.0, 0.76, 1.0, 1.0)
        yPos = yPos + 35
    end

    drawHeader("GAMEPLAY & RULES")
    drawToggle("stadiumPulseEnabled", "Stadium Pulse Mechanic")
    drawToggle("pulseCounterScaling", "Opponent Pulse Counter-Scaling")
    drawCycle("gameSpeed", "Game Speed", {1.0, 1.25, 1.5, 2.0})
    drawToggle("autoEndDrive", "Auto-End Drive on Turnover")
    
    drawHeader("VISUALS & IMPACT")
    drawCycle("impactFx", "Field Impact FX", {"FULL", "LOW", "OFF"})
    drawToggle("weatherStains", "Turf & Uniform Weather Stains")
    drawToggle("turnoverSequence", "Turnover Camera Focus")
    drawToggle("reducedFlashing", "Reduced Flashing Lights")
    
    drawHeader("AUDIO")
    drawSlider("masterVolume", "Master Volume")
    drawSlider("sfxVolume", "SFX Volume")
    drawSlider("musicVolume", "Music Volume")
    drawSlider("crowdVolume", "Crowd Noise Volume")
    drawToggle("soundSoftener", "Sudden Noise Softener")
    
    drawHeader("STREAMER & CONTENT")
    drawToggle("streamerMode", "Streamer Safe Music")
    drawToggle("profanityFilter", "Profanity & Trash Talk Filter")
    drawToggle("hideUserTag", "Hide Account Identifiers")
end

function StateSettings:wheelmoved(x, y)
    self.scrollY = self.scrollY + y * 30
    self.scrollY = math.min(0, self.scrollY)
end

function StateSettings:mousepressed(x, y, button)
    if button == 1 then
        local yPos = 80 + self.scrollY
        
        local function checkToggle(key)
            yPos = yPos + 40 -- header offset if applied manually, wait we need to recreate the layout logic
            -- This is too brittle. Let's just re-evaluate layout:
        end
        
        -- Safe layout evaluation for clicks
        local curY = 80 + self.scrollY
        local function clickHeader() curY = curY + 40 end
        local function clickToggle(key)
            if checkHover(40, curY, 880, 30) then
                self.settings[key] = not self.settings[key]
                SoundManager.playSFX("click")
            end
            curY = curY + 35
        end
        local function clickSlider(key)
            if checkHover(300, curY, 580, 40) then
                local pct = math.clamp((x - 300) / 580, 0, 1)
                self.settings[key] = pct
            end
            curY = curY + 45
        end
        local function clickCycle(key, options)
            if checkHover(40, curY, 880, 30) then
                local current = self.settings[key]
                local idx = 1
                for i, v in ipairs(options) do
                    if v == current then idx = i break end
                end
                self.settings[key] = options[(idx % #options) + 1]
                SoundManager.playSFX("click")
            end
            curY = curY + 35
        end
        
        clickHeader()
        clickToggle("stadiumPulseEnabled")
        clickToggle("pulseCounterScaling")
        clickCycle("gameSpeed", {1.0, 1.25, 1.5, 2.0})
        clickToggle("autoEndDrive")
        
        clickHeader()
        clickCycle("impactFx", {"FULL", "LOW", "OFF"})
        clickToggle("weatherStains")
        clickToggle("turnoverSequence")
        clickToggle("reducedFlashing")
        
        clickHeader()
        clickSlider("masterVolume")
        clickSlider("sfxVolume")
        clickSlider("musicVolume")
        clickSlider("crowdVolume")
        clickToggle("soundSoftener")
        
        clickHeader()
        clickToggle("streamerMode")
        clickToggle("profanityFilter")
        clickToggle("hideUserTag")
    end
end

function StateSettings:keypressed(key)
    if key == "escape" then
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    end
end

return StateSettings
