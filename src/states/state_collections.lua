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

function StateCollections:enter()
    self.tabIndex = 1
    self.currentPage = 1
    self.tabs = {"ROSTER PLAYERS", "PLAYBOOK", "DEFENSIVE SCHEMES", "STAFF UPGRADES", "STRATEGY BONUSES", "SIDELINE ADJUSTMENTS / DECALS"}
    if not DeckManager.playbook or #DeckManager.playbook == 0 then
        DeckManager.init()
    end
    
    -- Load the entire predetermined player catalog
    self.galleryPlayers = RosterPlayersExpanded.getAllPlayers()
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
    drawShadowText("Click tabs or press [A/D]/[←/→] to browse | [ESC] Main Menu", 320, 20, 0.7, 0.75, 0.8, 0.85)
    
    -- Draw Back Button
    local hoverBack = checkHover(830, 15, 90, 25)
    love.graphics.setColor(hoverBack and {0.9, 0.3, 0.3} or {0.7, 0.2, 0.2})
    love.graphics.rectangle("fill", 830, 15, 90, 25, 4, 4)
    drawShadowText("BACK", 830, 19, 1, 1, 1, 0.8, "center", 90)
    
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
    
    local itemsPerPage = 15
    local totalItems = 0
    
    love.graphics.setScissor(0, 100, 960, 390)
    if activeTab == "ROSTER PLAYERS" then
        totalItems = #self.galleryPlayers
        local startIdx = (self.currentPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, totalItems)
        
        local drawn = 0
        for i = startIdx, endIdx do
            local col = drawn % 5
            local row = math.floor(drawn / 5)
            local x = 140 + col * 170
            local y = 140 + row * 180
            
            local player = self.galleryPlayers[i]
            if player then
                local isHover = mx >= x - 55 and mx <= x + 55 and my >= y - 65 and my <= y + 65
                if isHover then
                    self.hoveredCollectionCard = player
                end
                CardRender.drawPlayerCard(x, y, player, false, love.timer.getDelta())
            end
            drawn = drawn + 1
        end
    elseif activeTab == "PLAYBOOK" then
        totalItems = #DeckManager.playbook
        local startIdx = (self.currentPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, totalItems)
        
        local drawn = 0
        for i = startIdx, endIdx do
            local card = DeckManager.playbook[i]
            local col = drawn % 5
            local row = math.floor(drawn / 5)
            local x = 140 + col * 170
            local y = 150 + row * 185
            
            local isHover = mx >= x - 65 and mx <= x + 65 and my >= y - 87 and my <= y + 87
            if isHover then
                self.hoveredCollectionCard = card
            end
            CardRender.drawPlayCard(x, y, card, false, 0)
            drawn = drawn + 1
        end
    elseif activeTab == "DEFENSIVE SCHEMES" then
        totalItems = #DefensiveSchemesData
        itemsPerPage = 9
        local startIdx = (self.currentPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, totalItems)
        
        local drawn = 0
        for i = startIdx, endIdx do
            local blind = DefensiveSchemesData[i]
            local col = drawn % 3
            local row = math.floor(drawn / 3)
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
            drawn = drawn + 1
        end
    elseif activeTab == "STAFF UPGRADES" then
        totalItems = #VouchersData
        itemsPerPage = 9
        local startIdx = (self.currentPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, totalItems)
        
        local drawn = 0
        for i = startIdx, endIdx do
            local v = VouchersData[i]
            local col = drawn % 3
            local row = math.floor(drawn / 3)
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
            drawn = drawn + 1
        end
    elseif activeTab == "STRATEGY BONUSES" then
        totalItems = #TagsData
        itemsPerPage = 12
        local startIdx = (self.currentPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, totalItems)
        
        local drawn = 0
        for i = startIdx, endIdx do
            local t = TagsData[i]
            local col = drawn % 4
            local row = math.floor(drawn / 4)
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
            drawn = drawn + 1
        end
    elseif activeTab == "SIDELINE ADJUSTMENTS / DECALS" then
        totalItems = #ConsumablesData
        itemsPerPage = 10
        local startIdx = (self.currentPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, totalItems)
        
        local drawn = 0
        for i = startIdx, endIdx do
            local c = ConsumablesData[i]
            local col = drawn % 5
            local row = math.floor(drawn / 5)
            local x = 120 + col * 150
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
            drawn = drawn + 1
        end
    end
    love.graphics.setScissor()
    
    -- Bottom Pagination UI (Balatro Style)
    self.totalPages = math.max(1, math.ceil(totalItems / itemsPerPage))
    
    local pageY = 495
    love.graphics.setColor(0.85, 0.25, 0.25) -- Red Banner
    love.graphics.rectangle("fill", 380, pageY, 200, 35, 6, 6)
    drawShadowText("Page " .. self.currentPage .. " / " .. self.totalPages, 380, pageY + 8, 1, 1, 1, 1.2, "center", 200)
    
    -- Prev Button
    local hoverPrev = checkHover(330, pageY, 40, 35)
    love.graphics.setColor(hoverPrev and {0.95, 0.35, 0.35} or {0.85, 0.25, 0.25})
    love.graphics.rectangle("fill", 330, pageY, 40, 35, 6, 6)
    drawShadowText("<", 330, pageY + 7, 1, 1, 1, 1.3, "center", 40)
    
    -- Next Button
    local hoverNext = checkHover(590, pageY, 40, 35)
    love.graphics.setColor(hoverNext and {0.95, 0.35, 0.35} or {0.85, 0.25, 0.25})
    love.graphics.rectangle("fill", 590, pageY, 40, 35, 6, 6)
    drawShadowText(">", 590, pageY + 7, 1, 1, 1, 1.3, "center", 40)
    
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
        self.currentPage = 1
    elseif key == "right" or key == "d" then
        SoundManager.playSFX("click")
        self.tabIndex = self.tabIndex == #self.tabs and 1 or self.tabIndex + 1
        self.currentPage = 1
    end
end

function StateCollections:wheelmoved(x, y)
    if y > 0 then
        -- Scroll up = Prev Page
        if self.currentPage > 1 then
            self.currentPage = self.currentPage - 1
            SoundManager.playSFX("click")
        end
    elseif y < 0 then
        -- Scroll down = Next Page
        if self.currentPage < (self.totalPages or 1) then
            self.currentPage = self.currentPage + 1
            SoundManager.playSFX("click")
        end
    end
end

function StateCollections:mousepressed(x, y, button)
    if button == 1 then
        if checkHover(830, 15, 90, 25) then
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
            SoundManager.playSFX("click")
            return
        end
        
        local tabW = 120
        local tabH = 30
        local startX = 40
        local tabY = 55
        for idx = 1, 6 do
            local tx = startX + (idx - 1) * 135
            if checkHover(tx, tabY, tabW, tabH) then
                self.tabIndex = idx
                self.currentPage = 1
                SoundManager.playSFX("click")
                return
            end
        end
        
        -- Pagination Buttons
        local pageY = 495
        if checkHover(330, pageY, 40, 35) then
            if self.currentPage > 1 then
                self.currentPage = self.currentPage - 1
                SoundManager.playSFX("click")
            end
            return
        end
        if checkHover(590, pageY, 40, 35) then
            if self.currentPage < (self.totalPages or 1) then
                self.currentPage = self.currentPage + 1
                SoundManager.playSFX("click")
            end
            return
        end
    end

    if button == 2 and self.tabs[self.tabIndex] == "ROSTER PLAYERS" then
        local itemsPerPage = 15
        local startIdx = (self.currentPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, #self.galleryPlayers)
        
        local drawn = 0
        for i = startIdx, endIdx do
            local col = drawn % 5
            local row = math.floor(drawn / 5)
            local rx = 140 + col * 170
            local ry = 140 + row * 180
            
            if x >= rx - 55 and x <= rx + 55 and y >= ry - 65 and y <= ry + 65 then
                local player = self.galleryPlayers[i]
                if player then
                    player.isFlipped = not player.isFlipped
                    SoundManager.playSFX("click")
                    return
                end
            end
            drawn = drawn + 1
        end
    end
end

return StateCollections
