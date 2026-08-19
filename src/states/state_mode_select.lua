-- src/states/state_mode_select.lua
local StateManager = require("src.states.state_manager")
local GameStateData = require("src.engine.game_state")
local DeckManager = require("src.engine.deck_manager")
local SoundManager = require("src.engine.sound_manager")
local FranchiseTeams = require("src.data.franchise_teams")

local StateModeSelect = {}

local C_BG = {0.08, 0.1, 0.14}
local C_MODAL = {0.18, 0.22, 0.25} -- Balatro-ish blue-grey modal
local C_INNER = {0.12, 0.15, 0.18} -- Inner dark area for the grid
local C_TAB_ACTIVE = {0.9, 0.3, 0.3}
local C_TAB_INACTIVE = {0.7, 0.2, 0.2}
local C_BTN_BLUE = {0.1, 0.6, 0.9}
local C_BTN_GREEN = {0.1, 0.7, 0.3}
local C_BTN_ORANGE = {0.9, 0.5, 0.0}

local function checkHover(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end

local function drawShadowText(text, x, y, r, g, b, scale, align, limit)
    scale = scale or 1
    love.graphics.setColor(0, 0, 0, 0.8)
    if align and limit then
        love.graphics.printf(text, x + 2, y + 2, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x + 2, y + 2, 0, scale, scale)
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
    self.selectedDeckIdx = 1
    self.selectedStakeIdx = 1
    self.selectedMode = "roguelite"
    self.activeTab = "NEW"
    
    self.phase = "TEAM" -- "TEAM", "DECK", or "STAKE"
    self.currentPage = 1
    
    self.time = 0
    
    local FranchiseDecks = require("src.data.franchise_decks")
    self.decks = FranchiseDecks
    
    self.stakes = {
        { id = "white", name = "White Stake", desc = "Standard championship rules. Recommended for beginners.", color = {0.9, 0.9, 0.9} },
        { id = "red", name = "Red Stake", desc = "Coaching Pressure: -5 seconds off the Play Clock.", color = {0.9, 0.2, 0.2} },
        { id = "purple", name = "Purple Stake", desc = "Crowded Box: -10 seconds off Play Clock, -10% Base Yards.", color = {0.6, 0.2, 0.8} },
        { id = "gold", name = "Gold Stake", desc = "Championship Heat: -15 seconds off Play Clock, Red Zone is 45% yardage.", color = {0.9, 0.7, 0.1} }
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
    
    -- Main Modal Layout
    local mw, mh = 800, 460
    local mx, my = (960 - mw) / 2, (540 - mh) / 2 + 10
    
    -- Tabs (drawn behind/above modal)
    local tabW = 120
    local tabH = 35
    
    love.graphics.setColor(self.activeTab == "NEW" and C_TAB_ACTIVE or C_TAB_INACTIVE)
    love.graphics.rectangle("fill", mx + 200, my - 25, tabW, tabH, 8, 8)
    drawShadowText("New Run", mx + 200, my - 20, 1, 1, 1, 1.0, "center", tabW)
    
    love.graphics.setColor(self.activeTab == "CONTINUE" and C_TAB_ACTIVE or C_TAB_INACTIVE)
    love.graphics.rectangle("fill", mx + 330, my - 25, tabW, tabH, 8, 8)
    drawShadowText("Continue", mx + 330, my - 20, 1, 1, 1, 1.0, "center", tabW)
    
    love.graphics.setColor(self.activeTab == "CHALLENGES" and C_TAB_ACTIVE or C_TAB_INACTIVE)
    love.graphics.rectangle("fill", mx + 460, my - 25, tabW, tabH, 8, 8)
    drawShadowText("Daily Mutator", mx + 460, my - 20, 1, 1, 1, 1.0, "center", tabW)
    
    -- Modal Base
    love.graphics.setColor(C_MODAL)
    love.graphics.rectangle("fill", mx, my, mw, mh, 12, 12)
    love.graphics.setColor(0.4, 0.45, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", mx, my, mw, mh, 12, 12)
    love.graphics.setLineWidth(1)
    
    -- Inner Grid Area
    local innerX, innerY = mx + 20, my + 30
    local innerW, innerH = 560, 280
    love.graphics.setColor(C_INNER)
    love.graphics.rectangle("fill", innerX, innerY, innerW, innerH, 8, 8)
    
    if self.phase == "TEAM" then
        self:drawTeamGrid(innerX, innerY, innerW, innerH)
    elseif self.phase == "DECK" then
        self:drawDeckGrid(innerX, innerY, innerW, innerH)
    elseif self.phase == "DAILY" then
        self:drawDailyGrid(innerX, innerY, innerW, innerH)
    else
        self:drawStakeGrid(innerX, innerY, innerW, innerH)
    end
    
    -- Right Info Panel
    self:drawRightPanel(mx + 600, my + 30, 180, 280)
    
    -- Bottom Pagination & Action Buttons
    local botY = my + 325
    
    if self.phase == "TEAM" then
        local maxPages = math.ceil(#FranchiseTeams / 10)
        -- Prev Page
        love.graphics.setColor(C_BTN_BLUE)
        love.graphics.rectangle("fill", innerX + 120, botY, 60, 30, 6, 6)
        drawShadowText("<", innerX + 120, botY + 5, 1, 1, 1, 1.2, "center", 60)
        
        -- Page text
        drawShadowText("Page " .. self.currentPage .. "/" .. maxPages, innerX + 220, botY + 8, 1, 1, 1, 1.1)
        
        -- Next Page
        love.graphics.setColor(C_BTN_BLUE)
        love.graphics.rectangle("fill", innerX + 360, botY, 60, 30, 6, 6)
        drawShadowText(">", innerX + 360, botY + 5, 1, 1, 1, 1.2, "center", 60)
        
        -- Random Team
        love.graphics.setColor(C_BTN_BLUE)
        love.graphics.rectangle("fill", mx + 600, botY, 180, 35, 6, 6)
        drawShadowText("Random Team", mx + 600, botY + 8, 1, 1, 1, 1.0, "center", 180)
    elseif self.phase == "DECK" then
        -- Random Deck
        if checkHover(mx + 600, botY, 180, 35) then
            love.graphics.setColor(C_BTN_ORANGE)
        else
            love.graphics.setColor(C_BTN_BLUE)
        end
        love.graphics.rectangle("fill", mx + 600, botY, 180, 35, 6, 6)
        drawShadowText("Random Playbook", mx + 600, botY + 8, 1, 1, 1, 1.0, "center", 180)
    else
        -- Random Stake
        if checkHover(mx + 600, botY, 180, 35) then
            love.graphics.setColor(C_BTN_ORANGE)
        else
            love.graphics.setColor(C_BTN_BLUE)
        end
        love.graphics.rectangle("fill", mx + 600, botY, 180, 35, 6, 6)
        drawShadowText("Random Difficulty", mx + 600, botY + 8, 1, 1, 1, 1.0, "center", 180)
    end
    
    -- Bottom Action Bar (Select Phase / Play)
    local actY = my + 375
    
    if self.phase == "TEAM" then
        love.graphics.setColor(C_BTN_BLUE)
        love.graphics.rectangle("fill", mx + 430, actY, 170, 35, 6, 6)
        drawShadowText("Select Playbook >", mx + 430, actY + 8, 1, 1, 1, 1.0, "center", 170)
    elseif self.phase == "DECK" then
        love.graphics.setColor(C_BTN_BLUE)
        love.graphics.rectangle("fill", mx + 20, actY, 160, 35, 6, 6)
        drawShadowText("< Select Team", mx + 20, actY + 8, 1, 1, 1, 1.0, "center", 160)
        
        love.graphics.setColor(C_BTN_BLUE)
        love.graphics.rectangle("fill", mx + 430, actY, 170, 35, 6, 6)
        drawShadowText("Select Difficulty >", mx + 430, actY + 8, 1, 1, 1, 1.0, "center", 170)
    elseif self.phase == "DAILY" then
        love.graphics.setColor(C_BTN_GREEN)
        love.graphics.rectangle("fill", mx + 430, actY, 170, 35, 6, 6)
        drawShadowText("PLAY DAILY", mx + 430, actY + 8, 1, 1, 1, 1.2, "center", 170)
    else
        love.graphics.setColor(C_BTN_BLUE)
        love.graphics.rectangle("fill", mx + 20, actY, 160, 35, 6, 6)
        drawShadowText("< Select Playbook", mx + 20, actY + 8, 1, 1, 1, 1.0, "center", 160)
        
        love.graphics.setColor(C_BTN_GREEN)
        love.graphics.rectangle("fill", mx + 430, actY, 170, 35, 6, 6)
        drawShadowText("Play", mx + 430, actY + 8, 1, 1, 1, 1.2, "center", 170)
    end
    
    -- Mode Toggle Button
    local modeColor = C_BTN_ORANGE
    local modeText = "Mode: Franchise"
    if self.selectedMode == "roguelite" then
        modeColor = {0.6, 0.2, 0.8}
        modeText = "Mode: MyPlayer"
    elseif self.selectedMode == "daily" then
        modeColor = {0.2, 0.6, 0.3}
        modeText = "Mode: Daily Run"
    end
    love.graphics.setColor(modeColor)
    love.graphics.rectangle("fill", mx + 610, actY, 170, 35, 6, 6)
    drawShadowText(modeText, mx + 610, actY + 8, 1, 1, 1, 1.0, "center", 170)
    
    -- Back Button (Large bottom bar)
    love.graphics.setColor(C_BTN_ORANGE)
    love.graphics.rectangle("fill", mx + 20, actY + 45, 760, 30, 6, 6)
    drawShadowText("Back", mx + 20, actY + 50, 1, 1, 1, 1.1, "center", 760)
end

function StateModeSelect:drawTeamGrid(x, y, w, h)
    local startIdx = (self.currentPage - 1) * 10 + 1
    local endIdx = math.min(#FranchiseTeams, startIdx + 9)
    
    local paddingX, paddingY = 25, 20
    local cardW, cardH = 80, 110
    
    for i = startIdx, endIdx do
        local team = FranchiseTeams[i]
        local relIdx = i - startIdx
        local col = relIdx % 5
        local row = math.floor(relIdx / 5)
        
        local cx = x + paddingX + col * (cardW + 20)
        local cy = y + paddingY + row * (cardH + 15)
        
        local isSelected = (self.selectedTeamIdx == i)
        local isHover = checkHover(cx, cy, cardW, cardH)
        
        if isSelected then
            love.graphics.setColor(team.secondaryColor or {1, 1, 1})
            love.graphics.rectangle("fill", cx - 4, cy - 4, cardW + 8, cardH + 8, 6, 6)
        elseif isHover then
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.rectangle("fill", cx - 2, cy - 2, cardW + 4, cardH + 4, 6, 6)
        end
        
        -- Draw Team Card
        love.graphics.setColor(team.primaryColor or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", cx, cy, cardW, cardH, 4, 4)
        
        love.graphics.setColor(team.secondaryColor or {1, 1, 1})
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", cx + 4, cy + 4, cardW - 8, cardH - 8, 2, 2)
        love.graphics.setLineWidth(1)
        
        drawShadowText(team.id, cx + 4, cy + cardH/2 - 10, 1, 1, 1, 1.0, "center", cardW - 8)
    end
end

function StateModeSelect:drawDeckGrid(x, y, w, h)
    local cardW, cardH = 220, 110
    local paddingX = (w - (2 * cardW + 20)) / 2
    local paddingY = (h - (2 * cardH + 15)) / 2
    
    for i, deck in ipairs(self.decks) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        
        local cx = x + paddingX + col * (cardW + 20)
        local cy = y + paddingY + row * (cardH + 15)
        
        local isSelected = (self.selectedDeckIdx == i)
        local isHover = checkHover(cx, cy, cardW, cardH)
        
        if isSelected then
            love.graphics.setColor(0, 0.76, 1)
            love.graphics.rectangle("fill", cx - 4, cy - 4, cardW + 8, cardH + 8, 6, 6)
        elseif isHover then
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.rectangle("fill", cx - 2, cy - 2, cardW + 4, cardH + 4, 6, 6)
        end
        
        -- Draw Deck Card
        love.graphics.setColor(0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", cx, cy, cardW, cardH, 4, 4)
        
        love.graphics.setColor(0.1, 0.6, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", cx + 4, cy + 4, cardW - 8, cardH - 8, 2, 2)
        love.graphics.setLineWidth(1)
        
        drawShadowText(deck.name, cx + 4, cy + cardH/2 - 15, 1, 1, 1, 1.2, "center", cardW - 8)
    end
end

function StateModeSelect:drawStakeGrid(x, y, w, h)
    local paddingX, paddingY = 40, 40
    local chipRadius = 35
    
    for i, stake in ipairs(self.stakes) do
        local relIdx = i - 1
        local col = relIdx % 7
        local row = math.floor(relIdx / 7)
        
        local cx = x + paddingX + col * (chipRadius * 2 + 15) + chipRadius
        local cy = y + paddingY + row * (chipRadius * 2 + 15) + chipRadius
        
        local isSelected = (self.selectedStakeIdx == i)
        local isHover = checkHover(cx - chipRadius, cy - chipRadius, chipRadius*2, chipRadius*2)
        
        if isSelected then
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.circle("fill", cx, cy, chipRadius + 6)
        elseif isHover then
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.circle("fill", cx, cy, chipRadius + 4)
        end
        
        -- Draw Stake Chip
        love.graphics.setColor(stake.color)
        love.graphics.circle("fill", cx, cy, chipRadius)
        
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.circle("line", cx, cy, chipRadius - 5)
        
        -- Inner pattern
        for a = 0, 7 do
            local angle = a * (math.pi / 4)
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.line(cx, cy, cx + math.cos(angle) * chipRadius, cy + math.sin(angle) * chipRadius)
        end
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", cx, cy, chipRadius * 0.4)
    end
end

function StateModeSelect:drawDailyGrid(x, y, w, h)
    drawShadowText("DAILY SEEDED CHALLENGE", x + 20, y + 20, 1, 0.84, 0, 1.4)
    drawShadowText("Date Seed: " .. os.date("%Y-%m-%d"), x + 20, y + 50, 0.8, 0.84, 0.9, 1.0)
    
    love.graphics.setColor(0.18, 0.22, 0.3, 1)
    love.graphics.rectangle("fill", x + 20, y + 80, w - 40, 160, 6, 6)
    love.graphics.setColor(0.0, 0.76, 1.0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x + 20, y + 80, w - 40, 160, 6, 6)
    love.graphics.setLineWidth(1)
    
    drawShadowText("ACTIVE GLOBAL MUTATOR:", x + 35, y + 95, 1, 0.84, 0, 1.1)
    drawShadowText("🚀 OOPS ALL HAIL MARYS!", x + 35, y + 120, 1, 1, 1, 1.2)
    drawShadowText("• Playbook is pre-stacked with Deep Pass & Option plays.\n• All Pass plays gain +20 Base Yards.\n• Red Zone penalties are completely negated!", x + 35, y + 145, 0.85, 0.85, 0.85, 0.85, "left", w - 70)
end

function StateModeSelect:drawRightPanel(x, y, w, h)
    
    if self.phase == "TEAM" then
        local team = FranchiseTeams[self.selectedTeamIdx]
        if not team then return end
        
        drawShadowText("Franchise\nTeam", x, y + 10, 0.6, 0.65, 0.7, 1.4, "center", w)
        
        -- Large Card
        local cardW, cardH = 100, 140
        local cx = x + (w - cardW) / 2
        local cy = y + 70
        
        love.graphics.setColor(team.primaryColor)
        love.graphics.rectangle("fill", cx, cy, cardW, cardH, 6, 6)
        love.graphics.setColor(team.secondaryColor)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", cx + 5, cy + 5, cardW - 10, cardH - 10, 4, 4)
        love.graphics.setLineWidth(1)
        
        drawShadowText(team.name:upper(), x - 10, cy + cardH + 15, 1, 1, 1, 0.9, "center", w + 20)
        drawShadowText(team.perk, x + 5, cy + cardH + 40, 0.8, 0.85, 0.9, 0.75, "center", w - 10)
        
    elseif self.phase == "DECK" or self.phase == "SCHEME" then
        local arch = self.decks and self.decks[self.selectedDeckIdx]
        if not arch then return end
        
        drawShadowText("Playbook\nScheme", x, y + 10, 0.6, 0.65, 0.7, 1.4, "center", w)
        
        -- Large Scheme Box
        local cardW, cardH = 120, 140
        local cx = x + (w - cardW) / 2
        local cy = y + 70
        
        love.graphics.setColor(0.2, 0.3, 0.4)
        love.graphics.rectangle("fill", cx, cy, cardW, cardH, 6, 6)
        love.graphics.setColor(0.1, 0.6, 0.9)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", cx + 5, cy + 5, cardW - 10, cardH - 10, 4, 4)
        love.graphics.setLineWidth(1)
        
        drawShadowText(arch.name:upper(), x - 10, cy + cardH + 15, 1, 1, 1, 1.0, "center", w + 20)
        drawShadowText(arch.desc or "", x + 5, cy + cardH + 40, 0.8, 0.85, 0.9, 0.75, "center", w - 10)
        
    elseif self.phase == "STAKE" then
        local stake = self.stakes[self.selectedStakeIdx]
        if not stake then return end
        
        drawShadowText("Game\nDifficulty", x, y + 10, 0.6, 0.65, 0.7, 1.4, "center", w)
        
        -- Large Chip
        local cx, cy = x + w/2, y + 120
        local chipR = 50
        
        love.graphics.setColor(stake.color)
        love.graphics.circle("fill", cx, cy, chipR)
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", cx, cy, chipR - 8)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", cx, cy, chipR * 0.4)
        
        drawShadowText(stake.name:upper(), x, cy + chipR + 25, 1, 1, 1, 1.1, "center", w)
        drawShadowText(stake.desc, x + 5, cy + chipR + 55, 0.8, 0.85, 0.9, 0.8, "center", w - 10)
    end
end

function StateModeSelect:mousepressed(mx, my, button)
    if button ~= 1 then return end
    print(string.format("[DEBUG] StateModeSelect.mousepressed received: mx=%s my=%s button=%s phase=%s", tostring(mx), tostring(my), tostring(button), tostring(self.phase)))
    
    local mw, mh = 800, 460
    local bmx, bmy = (960 - mw) / 2, (540 - mh) / 2 + 10
    
    local innerX, innerY = bmx + 20, bmy + 30
    local innerW, innerH = 560, 280
    local botY = bmy + 325
    local actY = bmy + 375
    
    if checkHover(bmx + 460, bmy - 25, 120, 35) then
        self.activeTab = "CHALLENGES"
        self.phase = "DAILY"
        SoundManager.playSFX("click")
        return
    elseif checkHover(bmx + 200, bmy - 25, 120, 35) then
        self.activeTab = "NEW"
        self.phase = "TEAM"
        SoundManager.playSFX("click")
    end
    
    if self.phase == "TEAM" then
        -- Grid Clicks
        local startIdx = (self.currentPage - 1) * 10 + 1
        local endIdx = math.min(#FranchiseTeams, startIdx + 9)
        local paddingX, paddingY, cardW, cardH = 25, 20, 80, 110
        
        for i = startIdx, endIdx do
            local relIdx = i - startIdx
            local col = relIdx % 5
            local row = math.floor(relIdx / 5)
            local cx = innerX + paddingX + col * (cardW + 20)
            local cy = innerY + paddingY + row * (cardH + 15)
            
            if checkHover(cx, cy, cardW, cardH) then
                self.selectedTeamIdx = i
                SoundManager.playSFX("click")
            end
        end
        
        -- Pagination
        local maxPages = math.ceil(#FranchiseTeams / 10)
        if checkHover(innerX + 120, botY, 60, 30) then
            self.currentPage = math.max(1, self.currentPage - 1)
            SoundManager.playSFX("click")
        elseif checkHover(innerX + 360, botY, 60, 30) then
            self.currentPage = math.min(maxPages, self.currentPage + 1)
            SoundManager.playSFX("click")
        end
        
        -- Random Team
        if checkHover(bmx + 600, botY, 180, 35) then
            self.selectedTeamIdx = math.random(1, #FranchiseTeams)
            self.currentPage = math.ceil(self.selectedTeamIdx / 10)
            SoundManager.playSFX("click")
        end
        
        -- Next Phase (Select Deck)
        if checkHover(bmx + 430, actY, 170, 35) then
            self.phase = "DECK"
            SoundManager.playSFX("click")
        end
        
    elseif self.phase == "DECK" then
        -- Grid Clicks
        local cardW, cardH = 220, 110
        local paddingX = (innerW - (2 * cardW + 20)) / 2
        local paddingY = (innerH - (2 * cardH + 15)) / 2
        for i, deck in ipairs(self.decks) do
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            local cx = innerX + paddingX + col * (cardW + 20)
            local cy = innerY + paddingY + row * (cardH + 15)
            
            if checkHover(cx, cy, cardW, cardH) then
                self.selectedDeckIdx = i
                SoundManager.playSFX("click")
            end
        end
        
        -- Random Deck
        if checkHover(bmx + 600, botY, 180, 35) then
            self.selectedDeckIdx = math.random(1, #self.decks)
            SoundManager.playSFX("click")
        end
        
        -- Prev Phase (Select Team)
        if checkHover(bmx + 20, actY, 160, 35) then
            self.phase = "TEAM"
            SoundManager.playSFX("click")
        end
        
        -- Next Phase (Select Stake)
        if checkHover(bmx + 430, actY, 170, 35) then
            self.phase = "STAKE"
            SoundManager.playSFX("click")
        end
        
    elseif self.phase == "STAKE" then
        -- Grid Clicks
        local paddingX, paddingY, chipRadius = 40, 40, 35
        for i, stake in ipairs(self.stakes) do
            local relIdx = i - 1
            local col = relIdx % 7
            local row = math.floor(relIdx / 7)
            local cx = innerX + paddingX + col * (chipRadius * 2 + 15) + chipRadius
            local cy = innerY + paddingY + row * (chipRadius * 2 + 15) + chipRadius
            
            if checkHover(cx - chipRadius, cy - chipRadius, chipRadius*2, chipRadius*2) then
                self.selectedStakeIdx = i
                SoundManager.playSFX("click")
            end
        end
        
        -- Random Stake
        if checkHover(bmx + 600, botY, 180, 35) then
            self.selectedStakeIdx = math.random(1, #self.stakes)
            SoundManager.playSFX("click")
        end
        
        -- Prev Phase (Select Deck)
        if checkHover(bmx + 20, actY, 160, 35) then
            self.phase = "DECK"
            SoundManager.playSFX("click")
        end
        
        -- Play Button
        if checkHover(bmx + 430, actY, 170, 35) then
            print(string.format("[DEBUG] StateModeSelect Play clicked (phase=%s selectedMode=%s selectedTeam=%s selectedDeck=%s selectedStake=%s)", tostring(self.phase), tostring(self.selectedMode), tostring(self.selectedTeamIdx), tostring(self.selectedDeckIdx), tostring(self.selectedStakeIdx)))
            SoundManager.playSFX("touchdown")
            
            _G.GAME_MODE = self.selectedMode
            _G.STAKE_TIER = self.stakes[self.selectedStakeIdx].id
            
            local teamObj = FranchiseTeams[self.selectedTeamIdx]
            local deckObj = self.decks[self.selectedDeckIdx]
            
            GameStateData.init({
                team = teamObj,
                archetype = deckObj,
                stakeTier = _G.STAKE_TIER
            })
            
            DeckManager.init(deckObj.playbookId or deckObj.id)
            DeckManager.drawHand()
            
            local StateGame = require("src.states.state_game")
            StateManager.switch(StateGame)
            return
        end
    elseif self.phase == "DAILY" then
        if checkHover(bmx + 430, actY, 170, 35) then
            SoundManager.playSFX("touchdown")
            
            _G.GAME_MODE = "daily"
            _G.STAKE_TIER = "white"
            
            -- Seed based on date
            local dateStr = os.date("%Y%m%d")
            math.randomseed(tonumber(dateStr))
            
            local teamObj = FranchiseTeams[1]
            local deckObj = self.decks[2] -- Air Raid
            
            GameStateData.init({
                team = teamObj,
                archetype = deckObj,
                stakeTier = _G.STAKE_TIER
            })
            
            -- Set up mutators
            GameStateData.dailyMutator = "hail_mary"
            GameStateData.passBonus = 20
            GameStateData.ignoreRedZonePenalty = true
            
            DeckManager.init(deckObj.playbookId or deckObj.id)
            DeckManager.drawHand()
            
            local StateGame = require("src.states.state_game")
            StateManager.switch(StateGame)
            return
        end
    end
    
    -- Mode Toggle Logic
    if checkHover(bmx + 610, actY, 170, 35) then
        SoundManager.playSFX("click")
        if self.selectedMode == "roguelite" then
            self.selectedMode = "franchise"
            self.phase = "TEAM"
        elseif self.selectedMode == "franchise" then
            self.selectedMode = "daily"
            self.phase = "DAILY"
        else
            self.selectedMode = "roguelite"
            self.phase = "TEAM"
        end
        return
    end
    
    -- Back Button
    if checkHover(bmx + 20, actY + 45, 760, 30) then
        SoundManager.playSFX("click")
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    end
end

function StateModeSelect:keypressed(key)
    if key == "escape" then
        if self.phase == "STAKE" then
            self.phase = "DECK"
            SoundManager.playSFX("click")
        elseif self.phase == "DECK" then
            self.phase = "TEAM"
            SoundManager.playSFX("click")
        else
            SoundManager.playSFX("click")
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
        end
    end
end

return StateModeSelect
