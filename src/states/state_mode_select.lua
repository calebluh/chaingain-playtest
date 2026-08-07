-- src/states/state_mode_select.lua
local StateManager = require("src.states.state_manager")
local GameStateData = require("src.engine.game_state")
local DeckManager = require("src.engine.deck_manager")
local SoundManager = require("src.engine.sound_manager")
local FranchiseTeams = require("src.data.franchise_teams")

local StateModeSelect = {}

local C_BG = {0.08, 0.1, 0.14}
local C_MODAL = {0.12, 0.15, 0.20}
local C_TAB_BG = {0.06, 0.08, 0.11}
local C_BUTTON_ACTIVE = {0.0, 0.58, 1.0}
local C_BUTTON_INACTIVE = {0.18, 0.22, 0.28}
local C_TEXT_MUTED = {0.6, 0.65, 0.7}
local C_AMBER = {1.0, 0.6, 0.0}
local C_GREEN = {0.18, 0.72, 0.45}

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

function StateModeSelect:enter()
    self.selectedTeamIdx = 1
    self.selectedArchIdx = 1
    self.selectedStakeIdx = 1
    self.selectedMode = "roguelite" -- "arcade" or "roguelite"
    self.time = 0
    
    self.archetypes = {
        { id = "air_raid", name = "Air Raid Scheme", desc = "Start with +4 WR slots, 0 TEs. QB + WR starter cards. Great for passing." },
        { id = "ground_pound", name = "Ground & Pound", desc = "Start with +2 RB, +2 TE, +1 WR slots. Heavy run & play-action." },
        { id = "west_coast", name = "West Coast Scheme", desc = "Start with +1 RB, +2 TE, +2 WR slots. Balanced attack approach." }
    }
    
    self.stakes = {
        { id = "white", name = "White Stake", desc = "Standard championship rules. Recommended for beginners." },
        { id = "red", name = "Red Stake", desc = "Coaching Pressure: -5 seconds off the Play Clock." },
        { id = "purple", name = "Purple Stake", desc = "Crowded Box: -10 seconds off Play Clock, -10% Base Yards." },
        { id = "gold", name = "Gold Stake", desc = "Championship Heat: -15 seconds off Play Clock, Red Zone is 45% yardage." }
    }
end

function StateModeSelect:exit()
end

function StateModeSelect:update(dt)
    self.time = self.time + dt
end

function StateModeSelect:draw()
    love.graphics.setColor(C_BG)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Decorative grid lines
    love.graphics.setColor(0.15, 0.2, 0.25, 0.2)
    for i = 0, 24 do
        love.graphics.line(i * 40, 0, i * 40, 540)
    end
    for i = 0, 14 do
        love.graphics.line(0, i * 40, 960, i * 40)
    end
    
    -- Main Modal Layout
    local mw, mh = 880, 450
    local mx, my = (960 - mw) / 2, (540 - mh) / 2
    
    -- Modal Base
    love.graphics.setColor(C_MODAL)
    love.graphics.rectangle("fill", mx, my, mw, mh, 10, 10)
    love.graphics.setColor(0.25, 0.3, 0.38)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", mx, my, mw, mh, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- Title
    drawShadowText("OFFENSIVE CAMPAIGN SETUP", mx + 20, my + 15, 1, 0.84, 0, 1.8)
    
    -- -------------------------------------------------------------
    -- COLUMN 1: CHOOSE FRANCHISE TEAM (mx + 20 to mx + 280)
    -- -------------------------------------------------------------
    local col1X = mx + 20
    drawShadowText("1. SELECT FRANCHISE", col1X, my + 55, 0.0, 0.76, 1.0, 1.1)
    
    for i, team in ipairs(FranchiseTeams) do
        local ty = my + 80 + (i - 1) * 38
        local isSelected = (self.selectedTeamIdx == i)
        local isHover = checkHover(col1X, ty, 250, 32)
        
        if isSelected then
            love.graphics.setColor(team.primaryColor or C_BUTTON_ACTIVE)
        elseif isHover then
            love.graphics.setColor(0.25, 0.29, 0.37)
        else
            love.graphics.setColor(C_BUTTON_INACTIVE)
        end
        
        love.graphics.rectangle("fill", col1X, ty, 250, 32, 6, 6)
        
        -- Team Selection Border Accent
        if isSelected then
            love.graphics.setColor(team.secondaryColor or {1, 1, 1})
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", col1X, ty, 250, 32, 6, 6)
            love.graphics.setLineWidth(1)
        end
        
        drawShadowText(team.name:upper(), col1X + 10, ty + 8, 1, 1, 1, 0.9)
    end
    
    -- -------------------------------------------------------------
    -- COLUMN 2: CHOOSE OFFENSIVE SCHEME (mx + 290 to mx + 570)
    -- -------------------------------------------------------------
    local col2X = mx + 290
    drawShadowText("2. SELECT SCHEME (PLAYBOOK)", col2X, my + 55, 0.0, 0.76, 1.0, 1.1)
    
    for i, arch in ipairs(self.archetypes) do
        local ay = my + 80 + (i - 1) * 115
        local isSelected = (self.selectedArchIdx == i)
        local isHover = checkHover(col2X, ay, 270, 105)
        
        if isSelected then
            love.graphics.setColor(0.18, 0.28, 0.42)
        elseif isHover then
            love.graphics.setColor(0.22, 0.26, 0.33)
        else
            love.graphics.setColor(C_BUTTON_INACTIVE)
        end
        
        love.graphics.rectangle("fill", col2X, ay, 270, 105, 8, 8)
        
        if isSelected then
            love.graphics.setColor(0, 0.76, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", col2X, ay, 270, 105, 8, 8)
            love.graphics.setLineWidth(1)
        end
        
        drawShadowText(arch.name:upper(), col2X + 12, ay + 12, 1, 0.84, 0, 1.1)
        drawShadowText(arch.desc, col2X + 12, ay + 38, 0.8, 0.85, 0.9, 0.8, "left", 246)
    end
    
    -- -------------------------------------------------------------
    -- COLUMN 3: STAKE TIER & MODE SELECTION (mx + 580 to mx + 860)
    -- -------------------------------------------------------------
    local col3X = mx + 580
    drawShadowText("3. SELECT STAKE TIER", col3X, my + 55, 0.0, 0.76, 1.0, 1.1)
    
    for i, stake in ipairs(self.stakes) do
        local sy = my + 80 + (i - 1) * 44
        local isSelected = (self.selectedStakeIdx == i)
        local isHover = checkHover(col3X, sy, 280, 38)
        
        if isSelected then
            love.graphics.setColor(0.24, 0.2, 0.3)
        elseif isHover then
            love.graphics.setColor(0.22, 0.26, 0.33)
        else
            love.graphics.setColor(C_BUTTON_INACTIVE)
        end
        
        love.graphics.rectangle("fill", col3X, sy, 280, 38, 6, 6)
        
        -- Custom Stake Colors
        local sc = {1, 1, 1}
        if stake.id == "red" then sc = {1.0, 0.3, 0.3}
        elseif stake.id == "purple" then sc = {0.7, 0.3, 1.0}
        elseif stake.id == "gold" then sc = {1.0, 0.84, 0.0} end
        
        if isSelected then
            love.graphics.setColor(sc)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", col3X, sy, 280, 38, 6, 6)
            love.graphics.setLineWidth(1)
        end
        
        drawShadowText(stake.name:upper(), col3X + 10, sy + 10, sc[1], sc[2], sc[3], 1.0)
    end
    
    -- Selected Perk Descriptions Footer Box
    local descY = my + 265
    love.graphics.setColor(C_TAB_BG)
    love.graphics.rectangle("fill", col3X, descY, 280, 95, 6, 6)
    
    local activeTeam = FranchiseTeams[self.selectedTeamIdx]
    local activeStake = self.stakes[self.selectedStakeIdx]
    
    drawShadowText("TEAM PERK: " .. activeTeam.perk, col3X + 10, descY + 10, 0.2, 0.8, 1, 0.75, "left", 260)
    drawShadowText("STAKE: " .. activeStake.desc, col3X + 10, descY + 50, 1, 0.84, 0, 0.75, "left", 260)
    
    -- Mode Select Buttons (Arcade vs Career)
    local modeY = my + 380
    drawShadowText("MODE:", col1X, modeY + 10, 1, 1, 1, 1.2)
    
    -- Arcade Mode Button
    local isArcadeHover = checkHover(col1X + 70, modeY, 120, 35)
    local isArcadeSelected = (self.selectedMode == "arcade")
    love.graphics.setColor(isArcadeSelected and C_BUTTON_ACTIVE or (isArcadeHover and {0.25, 0.29, 0.37} or C_BUTTON_INACTIVE))
    love.graphics.rectangle("fill", col1X + 70, modeY, 120, 35, 6, 6)
    drawShadowText("ARCADE RUN", col1X + 70, modeY + 9, 1, 1, 1, 0.95, "center", 120)
    
    -- MyPlayer Career Mode Button
    local isCareerHover = checkHover(col1X + 200, modeY, 150, 35)
    local isCareerSelected = (self.selectedMode == "roguelite")
    love.graphics.setColor(isCareerSelected and C_BUTTON_ACTIVE or (isCareerHover and {0.25, 0.29, 0.37} or C_BUTTON_INACTIVE))
    love.graphics.rectangle("fill", col1X + 200, modeY, 150, 35, 6, 6)
    drawShadowText("MYPLAYER CAREER", col1X + 200, modeY + 9, 1, 1, 1, 0.95, "center", 150)
    
    -- Bottom Navigation: PLAY and BACK
    local playHover = checkHover(col3X + 100, modeY - 5, 180, 45)
    love.graphics.setColor(playHover and C_GREEN or {0.15, 0.6, 0.38})
    love.graphics.rectangle("fill", col3X + 100, modeY - 5, 180, 45, 6, 6)
    drawShadowText("START PLAY", col3X + 100, modeY + 7, 1, 1, 1, 1.4, "center", 180)
    
    local backHover = checkHover(col3X - 80, modeY - 5, 160, 45)
    love.graphics.setColor(backHover and {1, 0.3, 0.3} or {0.8, 0.2, 0.2})
    love.graphics.rectangle("fill", col3X - 80, modeY - 5, 160, 45, 6, 6)
    drawShadowText("BACK TO LOBBY", col3X - 80, modeY + 7, 1, 1, 1, 1.2, "center", 160)
end

function StateModeSelect:mousepressed(x, y, button, istouch, presses)
    if button ~= 1 then return end
    
    local mw, mh = 880, 450
    local mx, my = (960 - mw) / 2, (540 - mh) / 2
    
    local col1X = mx + 20
    local col2X = mx + 290
    local col3X = mx + 580
    local modeY = my + 380
    
    -- 1. Check Franchise Team Clicks
    for i, team in ipairs(FranchiseTeams) do
        local ty = my + 80 + (i - 1) * 38
        if checkHover(col1X, ty, 250, 32) then
            self.selectedTeamIdx = i
            SoundManager.playSFX("click")
            return
        end
    end
    
    -- 2. Check Scheme Archetype Clicks
    for i, arch in ipairs(self.archetypes) do
        local ay = my + 80 + (i - 1) * 115
        if checkHover(col2X, ay, 270, 105) then
            self.selectedArchIdx = i
            SoundManager.playSFX("click")
            return
        end
    end
    
    -- 3. Check Stake Tier Clicks
    for i, stake in ipairs(self.stakes) do
        local sy = my + 80 + (i - 1) * 44
        if checkHover(col3X, sy, 280, 38) then
            self.selectedStakeIdx = i
            SoundManager.playSFX("click")
            return
        end
    end
    
    -- 4. Check Mode Clicks
    if checkHover(col1X + 70, modeY, 120, 35) then
        self.selectedMode = "arcade"
        SoundManager.playSFX("click")
        return
    elseif checkHover(col1X + 200, modeY, 150, 35) then
        self.selectedMode = "roguelite"
        SoundManager.playSFX("click")
        return
    end
    
    -- 5. Check Start Play Click
    if checkHover(col3X + 100, modeY - 5, 180, 45) then
        SoundManager.playSFX("touchdown")
        
        _G.GAME_MODE = self.selectedMode
        _G.STAKE_TIER = self.stakes[self.selectedStakeIdx].id
        
        local teamObj = FranchiseTeams[self.selectedTeamIdx]
        local archObj = self.archetypes[self.selectedArchIdx]
        
        GameStateData.init({
            team = teamObj,
            archetype = archObj,
            stakeTier = _G.STAKE_TIER
        })
        
        DeckManager.drawHand()
        
        local StateGame = require("src.states.state_game")
        StateManager.switch(StateGame)
        return
    end
    
    -- 6. Check Back Click
    if checkHover(col3X - 80, modeY - 5, 160, 45) then
        SoundManager.playSFX("click")
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
        return
    end
end

function StateModeSelect:keypressed(key)
    if key == "escape" then
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    end
end

return StateModeSelect
