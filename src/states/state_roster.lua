-- src/states/state_roster.lua
-- Retro Bowl-Style Lineup Editor with Player Carousel
local StateManager = require("src.states.state_manager")
local GameStateData = require("src.engine.game_state")
local AssetManager = require("src.engine.asset_manager")
local PlayerVisualProfile = require("src.data.player_visual_profile")
local SoundManager = require("src.engine.sound_manager")

local StateRoster = {}

local C_BG = {0.06, 0.08, 0.12}
local C_HIGHLIGHT = {0.18, 0.65, 0.15}
local C_NEON_CYAN = {0.0, 0.76, 1.0}
local C_GOLD = {1.0, 0.84, 0.0}

local function drawShadowText(text, x, y, r, g, b, scale, align, limit)
    scale = scale or 1
    love.graphics.setColor(0, 0, 0, 0.8)
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

local function drawSegmentBar(label, value, x, y)
    local maxSeg = 4
    local filled = math.floor((value / 99) * maxSeg + 0.5)
    drawShadowText(label, x, y, 0.7, 0.7, 0.7, 0.9)
    for s = 1, maxSeg do
        if s <= filled then
            love.graphics.setColor(C_HIGHLIGHT)
        else
            love.graphics.setColor(0.2, 0.22, 0.25)
        end
        love.graphics.rectangle("fill", x + 36 + (s - 1) * 14, y + 2, 11, 10)
    end
end

function StateRoster:enter()
    self.players = {}
    self.selectedIdx = 1
    
    if GameStateData.rosterSlots then
        local order = {"QB", "RB", "WR1", "WR2", "FLEX"}
        for _, pos in ipairs(order) do
            if GameStateData.rosterSlots[pos] then
                for _, card in ipairs(GameStateData.rosterSlots[pos].cards) do
                    table.insert(self.players, { card = card, pos = pos })
                end
            end
        end
    end
    
    if #self.players == 0 then
        -- Add placeholder if no players
        table.insert(self.players, { card = { name = "Empty Slot", overall = 0, visualProfile = {skinTone = 3} }, pos = "QB" })
    end
end

function StateRoster:exit()
end

function StateRoster:update(dt)
end

function StateRoster:draw()
    -- Background
    love.graphics.setColor(C_BG)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Title
    drawShadowText("Lineup Editor", 0, 12, 1, 1, 1, 1.8, "center", 960)
    
    -- ═══════════════════════════════════════════════════════════════
    -- TOP-LEFT: Team Badge Area
    -- ═══════════════════════════════════════════════════════════════
    local teamName = "CHAIN GAIN"
    local teamAbbr = "CG"
    if GameStateData.config and GameStateData.config.team then
        teamName = (GameStateData.config.team.name or "CHAIN GAIN"):upper()
        teamAbbr = (GameStateData.config.team.abbreviation or teamName:sub(1, 3)):upper()
    end
    
    love.graphics.setColor(0.10, 0.12, 0.16)
    love.graphics.rectangle("fill", 20, 55, 200, 120, 6, 6)
    
    -- Team logo area
    local teamPrimary = GameStateData.config and GameStateData.config.team and GameStateData.config.team.primaryColor or {0.13, 0.34, 0.13}
    local teamSecondary = GameStateData.config and GameStateData.config.team and GameStateData.config.team.secondaryColor or {1, 0.84, 0}
    
    -- Star badge
    love.graphics.setColor(teamSecondary)
    local cx, cy = 70, 110
    local points = {}
    for i = 1, 10 do
        local r = (i % 2 == 0) and 18 or 30
        local angle = (i / 10) * math.pi * 2 - math.pi / 2
        table.insert(points, cx + r * math.cos(angle))
        table.insert(points, cy + r * math.sin(angle))
    end
    love.graphics.polygon("fill", points)
    love.graphics.setColor(teamPrimary)
    local innerPoints = {}
    for i = 1, 10 do
        local r = (i % 2 == 0) and 12 or 22
        local angle = (i / 10) * math.pi * 2 - math.pi / 2
        table.insert(innerPoints, cx + r * math.cos(angle))
        table.insert(innerPoints, cy + r * math.sin(angle))
    end
    love.graphics.polygon("fill", innerPoints)
    
    drawShadowText(teamAbbr, 110, 70, 1, 1, 1, 1.2)
    drawShadowText(teamName, 110, 95, teamSecondary[1], teamSecondary[2], teamSecondary[3], 1.4)
    
    -- ═══════════════════════════════════════════════════════════════
    -- CENTER: Selected Player Bust + Info
    -- ═══════════════════════════════════════════════════════════════
    local sel = self.players[self.selectedIdx]
    if sel then
        local card = sel.card
        local profile = card.visualProfile or {}
        local isMyPlayer = card.isMyPlayer
        if isMyPlayer then profile = PlayerVisualProfile end
        
        -- Bust portrait area
        local bustX, bustY = 380, 55
        love.graphics.setColor(0.04, 0.05, 0.08)
        love.graphics.rectangle("fill", bustX, bustY, 200, 180, 8, 8)
        
        -- Spotlight
        love.graphics.setColor(1, 1, 1, 0.03)
        love.graphics.polygon("fill",
            bustX + 80, bustY,
            bustX + 120, bustY,
            bustX + 160, bustY + 180,
            bustX + 40, bustY + 180
        )
        
        -- Draw bust
        local jerseyCol = teamPrimary
        local helmetCol = teamSecondary
        AssetManager.drawRetroPlayerBust(
            bustX + 100, bustY + 110,
            jerseyCol, helmetCol,
            profile, 8
        )
        
        love.graphics.setColor(C_NEON_CYAN[1], C_NEON_CYAN[2], C_NEON_CYAN[3], 0.4)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", bustX, bustY, 200, 180, 8, 8)
        
        -- Player info (right of bust)
        local infoX = 600
        local jNum = profile.jerseyNumber or 0
        drawShadowText("#" .. jNum .. " - " .. card.name:upper(), infoX, 65, 1, 1, 1, 1.3)
        drawShadowText(sel.pos .. "  |  OVR " .. (card.overall or 0), infoX, 95, C_GOLD[1], C_GOLD[2], C_GOLD[3], 1.1)
        
        if card.archetypeTag then
            drawShadowText(card.archetypeTag, infoX, 120, C_NEON_CYAN[1], C_NEON_CYAN[2], C_NEON_CYAN[3], 0.95)
        end
        
        -- Stat bars
        local statY = 150
        local statData = {
            {"SKL", card.awr or 75},  {"STR", card.str or 75},
            {"SPD", card.spd or 75},  {"STM", 80},
            {"AGI", card.cth or 75},  {"INJ", 90},
        }
        for i, s in ipairs(statData) do
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            drawSegmentBar(s[1], s[2], infoX + col * 130, statY + row * 24)
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- BOTTOM: Player Carousel
    -- ═══════════════════════════════════════════════════════════════
    local carouselY = 310
    local carouselH = 170
    love.graphics.setColor(0.04, 0.05, 0.08)
    love.graphics.rectangle("fill", 0, carouselY, 960, carouselH)
    love.graphics.setColor(0.1, 0.12, 0.16)
    love.graphics.rectangle("fill", 0, carouselY, 960, 3)
    
    -- Draw player sprites in carousel
    local slotW = 120
    local totalW = #self.players * slotW
    local startX = (960 - totalW) / 2
    if startX < 20 then startX = 20 end
    
    -- Scroll offset for many players
    local scrollX = 0
    if #self.players > 7 then
        scrollX = (self.selectedIdx - 4) * slotW
        scrollX = math.max(0, math.min(scrollX, totalW - 840))
    end
    
    local time = love.timer.getTime()
    for i, pData in ipairs(self.players) do
        local px = startX + (i - 1) * slotW - scrollX
        if px > -slotW and px < 960 + slotW then
            local isSel = (i == self.selectedIdx)
            local card = pData.card
            local profile = card.visualProfile or {}
            if card.isMyPlayer then profile = PlayerVisualProfile end
            
            -- Pedestal
            love.graphics.setColor(0.12, 0.14, 0.18)
            love.graphics.ellipse("fill", px + slotW/2, carouselY + carouselH - 25, 40, 8)
            
            -- Selection highlight box
            if isSel then
                love.graphics.setColor(C_HIGHLIGHT[1], C_HIGHLIGHT[2], C_HIGHLIGHT[3], 0.4)
                love.graphics.rectangle("fill", px + 10, carouselY + 10, slotW - 20, carouselH - 40, 4, 4)
                love.graphics.setColor(C_HIGHLIGHT)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", px + 10, carouselY + 10, slotW - 20, carouselH - 40, 4, 4)
                love.graphics.setLineWidth(1)
            end
            
            -- Draw full body sprite
            local jerseyCol = teamPrimary
            local helmetCol = teamSecondary
            AssetManager.drawRetroPlayer(
                px + slotW/2, carouselY + carouselH - 50,
                jerseyCol, {0.9, 0.9, 0.9}, helmetCol,
                0, 0, true, time, false, profile, 6
            )
            
            -- Position label
            drawShadowText(pData.pos, px + slotW/2 - 10, carouselY + carouselH - 15, 0.7, 0.7, 0.7, 0.8)
        end
    end
    
    -- Left/right arrows
    if self.selectedIdx > 1 then
        love.graphics.setColor(C_HIGHLIGHT)
        love.graphics.polygon("fill", 10, carouselY + carouselH/2, 25, carouselY + carouselH/2 - 12, 25, carouselY + carouselH/2 + 12)
    end
    if self.selectedIdx < #self.players then
        love.graphics.setColor(C_HIGHLIGHT)
        love.graphics.polygon("fill", 950, carouselY + carouselH/2, 935, carouselY + carouselH/2 - 12, 935, carouselY + carouselH/2 + 12)
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- BOTTOM BAR
    -- ═══════════════════════════════════════════════════════════════
    love.graphics.setColor(0.08, 0.1, 0.14)
    love.graphics.rectangle("fill", 0, 490, 960, 50)
    
    drawShadowText("B  back", 30, 505, 0.8, 0.2, 0.2, 0.95)
    drawShadowText("< >  select", 0, 505, 0.7, 0.7, 0.7, 0.95, "center", 960)
    drawShadowText("PLAYERS " .. #self.players, 800, 505, 0.7, 0.7, 0.7, 0.95)
end

function StateRoster:keypressed(key)
    if key == "left" then
        self.selectedIdx = math.max(1, self.selectedIdx - 1)
        SoundManager.playSFX("click")
    elseif key == "right" then
        self.selectedIdx = math.min(#self.players, self.selectedIdx + 1)
        SoundManager.playSFX("click")
    elseif key == "escape" then
        local StateShop = require("src.states.state_shop")
        StateManager.switch(StateShop)
    end
end

function StateRoster:mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Carousel clicks
    local carouselY = 310
    local carouselH = 170
    if y >= carouselY and y <= carouselY + carouselH then
        local slotW = 120
        local totalW = #self.players * slotW
        local startX = (960 - totalW) / 2
        if startX < 20 then startX = 20 end
        local scrollXOff = 0
        if #self.players > 7 then
            scrollXOff = (self.selectedIdx - 4) * slotW
            scrollXOff = math.max(0, math.min(scrollXOff, totalW - 840))
        end
        
        for i = 1, #self.players do
            local px = startX + (i - 1) * slotW - scrollXOff
            if x >= px and x <= px + slotW then
                self.selectedIdx = i
                SoundManager.playSFX("click")
                return
            end
        end
    end
end

return StateRoster
