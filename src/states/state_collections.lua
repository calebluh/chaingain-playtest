-- src/states/state_collections.lua
local StateManager = require("src.states.state_manager")
local DeckManager = require("src.engine.deck_manager")
local DefensiveSchemesData = require("src.data.defensive_schemes")
local VouchersData = require("src.data.vouchers")
local RosterPlayersExpanded = require("src.data.roster_players_expanded")
local TagsData = require("src.data.tags")
local ConsumablesData = require("src.data.consumables")
local CardRender = require("src.ui.card_render")
local AssetManager = require("src.engine.asset_manager")
local SoundManager = require("src.engine.sound_manager")

local StateCollections = {}

local C_SLATE_CONTAINER = {0.129, 0.149, 0.192} -- #212631
local C_NEON_BORDER = {0.0, 0.76, 1.0} -- #00C3FF

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

function StateCollections:enter()
    self.tabIndex = 1
    self.tabs = {"ROSTER PLAYERS", "PLAYBOOK", "DEFENSIVE SCHEMES", "STAFF UPGRADES", "STRATEGY BONUSES", "SIDELINE ADJUSTMENTS / DECALS"}
    if not DeckManager.playbook or #DeckManager.playbook == 0 then
        DeckManager.init()
    end
    
    -- Generate static gallery players once
    self.galleryPlayers = {}
    for i = 1, 12 do
        local pos = i <= 3 and "QB" or (i <= 6 and "RB" or (i <= 9 and "WR" or "TE"))
        local player = RosterPlayersExpanded.getRandomPlayer(pos)
        player.pos = pos
        table.insert(self.galleryPlayers, player)
    end
end

function StateCollections:exit()
end

function StateCollections:update(dt)
end

function StateCollections:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    local activeTab = self.tabs[self.tabIndex]
    drawShadowText("COLLECTION GALLERY", 40, 15, 1, 0.84, 0, 1.4)
    drawShadowText("Click tabs or press [A/D]/[←/→] to browse | [ESC] Main Menu", 440, 20, 0.7, 0.75, 0.8, 0.85)
    
    -- Draw horizontal clickable tabs
    local tabLabels = {"ROSTER", "PLAYBOOK", "DEFENSES", "STAFF", "BONUSES", "DECALS"}
    local tabW = 120
    local tabH = 30
    local startX = 40
    local tabY = 55
    
    for idx, label in ipairs(tabLabels) do
        local tx = startX + (idx - 1) * 135
        local isSel = (self.tabIndex == idx)
        local hover = checkHover(tx, tabY, tabW, tabH)
        
        love.graphics.setColor(isSel and C_NEON_BORDER or (hover and {0.2, 0.25, 0.3} or {0.129, 0.149, 0.192}))
        love.graphics.rectangle("fill", tx, tabY, tabW, tabH, 6, 6)
        
        love.graphics.setColor(isSel and {1, 1, 1} or {0.3, 0.35, 0.4})
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", tx, tabY, tabW, tabH, 6, 6)
        love.graphics.setLineWidth(1)
        
        drawShadowText(label, tx, tabY + 7, 1, 1, 1, 0.95, "center", tabW)
        
        if isSel then
            love.graphics.setColor(C_NEON_BORDER)
            love.graphics.rectangle("fill", tx + 10, tabY + tabH - 4, tabW - 20, 3)
        end
    end
    
    self.hoveredCollectionCard = nil
    local mx, my = love.mouse.getPosition()
    
    if activeTab == "ROSTER PLAYERS" then
        for i = 1, 12 do
            local col = (i - 1) % 6
            local row = math.floor((i - 1) / 6)
            local x = 90 + col * 140
            local y = 140 + row * 180
            
            local player = self.galleryPlayers[i]
            if player then
                local isHover = mx >= x - 55 and mx <= x + 55 and my >= y - 65 and my <= y + 65
                if isHover then
                    self.hoveredCollectionCard = player
                end
                CardRender.drawPlayerCard(x, y, player, false, love.timer.getDelta())
            end
        end
    elseif activeTab == "PLAYBOOK" then
        for i, card in ipairs(DeckManager.playbook) do
            local col = (i - 1) % 6
            local row = math.floor((i - 1) / 6)
            local x = 90 + col * 140
            local y = 150 + row * 185
            
            local isHover = mx >= x - 65 and mx <= x + 65 and my >= y - 87 and my <= y + 87
            if isHover then
                self.hoveredCollectionCard = card
            end
            CardRender.drawPlayCard(x, y, card, false, 0)
        end
    elseif activeTab == "DEFENSIVE SCHEMES" then
        for i, blind in ipairs(DefensiveSchemesData) do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local x = 40 + col * 290
            local y = 110 + row * 130
            
            love.graphics.setColor(C_SLATE_CONTAINER)
            love.graphics.rectangle("fill", x, y, 270, 115, 8, 8)
            love.graphics.setColor(C_NEON_BORDER)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, 270, 115, 8, 8)
            love.graphics.setLineWidth(1)
            
            AssetManager.drawBlindIcon(x + 40, y + 55, 25, blind.name, blind.type == "boss")
            
            drawShadowText(blind.name, x + 75, y + 15, 1, 1, 1, 1.1)
            drawShadowText(blind.tier:upper(), x + 75, y + 35, 1, 0.84, 0, 0.85)
            drawShadowText(blind.description, x + 15, y + 70, 0.8, 0.8, 0.8, 0.9, "left", 240)
        end
    elseif activeTab == "STAFF UPGRADES" then
        for i, v in ipairs(VouchersData) do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local x = 40 + col * 290
            local y = 110 + row * 105
            
            love.graphics.setColor(C_SLATE_CONTAINER)
            love.graphics.rectangle("fill", x, y, 270, 90, 8, 8)
            love.graphics.setColor(1.0, 0.84, 0.0)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, 270, 90, 8, 8)
            love.graphics.setLineWidth(1)
            
            drawShadowText(v.name, x + 15, y + 12, 1, 0.84, 0, 1.1)
            drawShadowText("STAFF UPGRADE", x + 15, y + 32, 0.2, 0.8, 1, 0.75)
            drawShadowText(v.description, x + 15, y + 50, 0.8, 0.8, 0.8, 0.85, "left", 240)
        end
    elseif activeTab == "STRATEGY BONUSES" then
        for i, t in ipairs(TagsData) do
            local col = (i - 1) % 4
            local row = math.floor((i - 1) / 4)
            local x = 40 + col * 220
            local y = 110 + row * 105
            
            love.graphics.setColor(C_SLATE_CONTAINER)
            love.graphics.rectangle("fill", x, y, 200, 90, 8, 8)
            love.graphics.setColor(1.0, 0.4, 0.0)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, 200, 90, 8, 8)
            love.graphics.setLineWidth(1)
            
            drawShadowText(t.name:upper(), x + 10, y + 12, 1, 0.84, 0, 1.0)
            drawShadowText("STRATEGY BONUS", x + 10, y + 32, 0.8, 0.4, 0.0, 0.75)
            drawShadowText(t.description, x + 10, y + 50, 0.8, 0.8, 0.8, 0.85, "left", 180)
        end
    elseif activeTab == "SIDELINE ADJUSTMENTS / DECALS" then
        for i, c in ipairs(ConsumablesData) do
            local col = (i - 1) % 6
            local row = math.floor((i - 1) / 6)
            local x = 60 + col * 140
            local y = 140 + row * 190
            
            local rx, ry = x + 65, y + 87
            local isHover = mx >= rx - 65 and mx <= rx + 65 and my >= ry - 87 and my <= ry + 87
            if isHover then
                self.hoveredCollectionCard = { consumable = c }
            end
            
            love.graphics.setColor(0.129, 0.149, 0.192)
            love.graphics.rectangle("fill", x, y, 130, 175, 8, 8)
            love.graphics.setColor(0, 0.76, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, 130, 175, 8, 8)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(c.name:upper(), x + 5, y + 15, 120, "center")
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.printf(c.description, x + 5, y + 65, 120 / 0.75, "center", 0, 0.75, 0.75)
        end
    end
    
    -- Draw hover tooltips
    if self.hoveredCollectionCard then
        CardRender.drawTooltip(mx, my, self.hoveredCollectionCard)
    end
end

function StateCollections:keypressed(key)
    if key == "escape" then
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    elseif key == "left" or key == "a" then
        SoundManager.playSFX("click")
        self.tabIndex = self.tabIndex == 1 and #self.tabs or self.tabIndex - 1
    elseif key == "right" or key == "d" then
        SoundManager.playSFX("click")
        self.tabIndex = self.tabIndex == #self.tabs and 1 or self.tabIndex + 1
    end
end

function StateCollections:mousepressed(x, y, button)
    if button == 1 then
        local tabW = 120
        local tabH = 30
        local startX = 40
        local tabY = 55
        for idx = 1, 6 do
            local tx = startX + (idx - 1) * 135
            if checkHover(tx, tabY, tabW, tabH) then
                self.tabIndex = idx
                SoundManager.playSFX("click")
                return
            end
        end
    end

    if button == 2 and self.tabs[self.tabIndex] == "ROSTER PLAYERS" then
        for i = 1, 12 do
            local col = (i - 1) % 6
            local row = math.floor((i - 1) / 6)
            local rx = 90 + col * 140
            local ry = 140 + row * 180
            
            if x >= rx - 55 and x <= rx + 55 and y >= ry - 65 and y <= ry + 65 then
                local player = self.galleryPlayers[i]
                if player then
                    player.isFlipped = not player.isFlipped
                    SoundManager.playSFX("click")
                    return
                end
            end
        end
    end
end

return StateCollections
