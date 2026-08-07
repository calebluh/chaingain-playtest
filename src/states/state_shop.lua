-- src/states/state_shop.lua
local GameStateData = require("src.engine.game_state")
local DeckManager = require("src.engine.deck_manager")
local DefenseManager = require("src.engine.defense_manager")
local PlayerCard = require("src.entities.player_card")
local PlayCard = require("src.entities.play_card")
local BadgesData = require("src.data.badges")
local VouchersData = require("src.data.vouchers")
local MyPlayerProfile = require("src.data.myplayer_profile")
local StateManager = require("src.states.state_manager")
local SoundManager = require("src.engine.sound_manager")
local FxManager = require("src.engine.fx_manager")
local CardRender = require("src.ui.card_render")
local Loc = require("src.engine.loc_manager")
local RosterPlayersExpanded = require("src.data.roster_players_expanded")

local StateShop = {}

local C_SLATE_CONTAINER = {0.129, 0.149, 0.192} -- #212631
local C_NEON_BORDER = {0.0, 0.76, 1.0} -- #00C3FF
local C_BLUE = {0.0, 0.58, 1.0} -- #0094FF
local C_AMBER = {1.0, 0.6, 0.0} -- #FF9900

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

function StateShop:enter()
    FxManager.clear()
    self.shopMessage = "Welcome to the Front Office Shop!"
    self.pendingEquipment = nil
    self.pendingTraining = false
    self:rerollShop()
    SoundManager.playMusic("shop_theme")
end

function StateShop:rerollShop()
    local discount = GameStateData.shopDiscount or 0
    local pack1Types = {
        { packType = "OFFENSIVE", title = "OFFENSIVE SCOUT", desc = "Open a Scout Report containing 3 random Offensive players. Draft 1." },
        { packType = "PLAY", title = "PLAYBOOK PACK", desc = "Open a Standard Pack containing 3 random Play Cards. Draft 1 to your Playbook." }
    }
    local pack2Types = {
        { packType = "OFFENSIVE", title = "OFFENSIVE SCOUT", desc = "Open a Scout Report containing 3 random Offensive players. Draft 1." },
        { packType = "CONSUMABLE", title = "SIDELINE CALL PACK", desc = "Open an Adjustment Pack containing 3 random Audibles/Decals. Draft 1." }
    }
    
    local p1 = pack1Types[math.random(#pack1Types)]
    local p2 = pack2Types[math.random(#pack2Types)]
    
    self.shopItems = {
        { slot = 1, packType = p1.packType, title = p1.title, desc = p1.desc, cost = math.max(1, 4 - discount) },
        { slot = 2, packType = p2.packType, title = p2.title, desc = p2.desc, cost = math.max(1, 4 - discount) },
        { slot = 3, packType = "MEGA", title = "MEGA SCOUT", desc = "Open a Scout Report containing 5 random players with boosted Edition odds. Draft 1.", cost = math.max(1, 8 - discount) }
    }
    
    local ConsumablesData = require("src.data.consumables")
    local randomConsumable = ConsumablesData[math.random(#ConsumablesData)]
    table.insert(self.shopItems, { slot = 4, title = "SIDELINE ADJUSTMENT", desc = randomConsumable.name .. ": " .. randomConsumable.description, cost = math.max(1, 3 - discount), consumable = randomConsumable })
    
    local randomVoucher = VouchersData[math.random(#VouchersData)]
    table.insert(self.shopItems, { slot = 5, title = "STAFF UPGRADE", desc = randomVoucher.name .. ": " .. randomVoucher.description, cost = math.max(1, 10 - discount), voucher = randomVoucher })
end

function StateShop:exit()
end

function StateShop:update(dt)
end

function StateShop:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Title Banner & Cash Header
    love.graphics.setColor(C_SLATE_CONTAINER)
    love.graphics.rectangle("fill", 0, 15, 960, 65)
    love.graphics.setColor(C_NEON_BORDER)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 0, 15, 960, 65)
    love.graphics.setLineWidth(1)
    
    drawShadowText(Loc.get("FRONT_OFFICE_SHOP"), 30, 25, 1, 0.84, 0, 2.2)
    drawShadowText(string.format(Loc.get("CAP_CASH", GameStateData.capCash or 0), GameStateData.capCash or 0), 520, 32, 0.2, 0.8, 0.2, 1.6)
    
    -- Reroll Shop Button
    local rerollCost = GameStateData.rerollCost or 2
    local isRerollHover = checkHover(760, 25, 170, 45)
    love.graphics.setColor(isRerollHover and {0.0, 0.76, 1.0} or C_BLUE)
    love.graphics.rectangle("fill", 760, 25, 170, 45, 8, 8)
    drawShadowText(string.format("REROLL ($%d)", rerollCost), 760, 38, 1, 1, 1, 1.1, "center", 170)
    
    -- Render 5 Buying Zone Cards
    local cardW = 165
    local spacing = 180
    
    self.hoveredShopItem = nil
    for i, item in ipairs(self.shopItems) do
        local x = 30 + (i - 1) * spacing
        local y = 95
        local h = 220
        local isHover = checkHover(x, y, cardW, h)
        if isHover then
            self.hoveredShopItem = item
        end
        
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", x + 3, y + 3, cardW, h, 8, 8)
        
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", x, y, cardW, h, 8, 8)
        
        local borderColor = isHover and {0.0, 0.76, 1.0} or (item.voucher and {1.0, 0.84, 0.0} or {0.22, 0.26, 0.32})
        love.graphics.setColor(borderColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, cardW, h, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText("[" .. item.slot .. "] " .. item.title, x + 6, y + 12, 1, 1, 1, 0.9)
        drawShadowText(item.desc, x + 6, y + 45, 0.8, 0.8, 0.8, 0.8, "left", cardW - 12)
        drawShadowText(string.format(Loc.get("COST", item.cost), item.cost), x + 6, y + h - 30, 1, 0.84, 0, 1.05)
    end

    -- Active Roster Display Bar
    love.graphics.setColor(C_SLATE_CONTAINER)
    love.graphics.rectangle("fill", 30, 335, 900, 130, 8, 8)
    love.graphics.setColor(C_NEON_BORDER)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 30, 335, 900, 130, 8, 8)
    love.graphics.setLineWidth(1)
    
    local rosterTitle = "ACTIVE ROSTER (Click card to Release for +$3 Cap Space)"
    if self.pendingEquipment then
        rosterTitle = "CLICK A ROSTER CARD TO ATTACH: " .. self.pendingEquipment.name
    elseif self.pendingTraining then
        rosterTitle = "CLICK A ROSTER CARD TO BOOST +3 OVR (TRAINING CAMP)"
    end
    drawShadowText(rosterTitle, 40, 342, 1, 0.84, 0, 0.95)
    
    self.hoveredRosterPlayer = nil
    local drawOrder = {"QB", "RB", "WR1", "WR2", "FLEX"}
    local slotIdx = 0
    if GameStateData.rosterSlots then
        for _, pos in ipairs(drawOrder) do
            local posData = GameStateData.rosterSlots[pos]
            if posData then
                for i = 1, posData.max do
                    local rx = 50 + slotIdx * 125
                    local ry = 362
                    
                    local player = posData.cards[i]
                    local isHoverRoster = checkHover(rx, ry, 110, 95)
                    if isHoverRoster and player then
                        self.hoveredRosterPlayer = player
                    end
                    
                    if player then
                        CardRender.drawPlayerCard(rx + 55, ry + 40, player, isHoverRoster, love.timer.getDelta())
                        if _G.GAME_MODE == "roguelite" and slotIdx == 0 then
                            drawShadowText("[LOCKED]", rx + 15, ry + 80, 1, 0.3, 0.3, 0.75)
                        end
                    else
                        love.graphics.setColor(0.08, 0.1, 0.14, 0.8)
                        love.graphics.rectangle("fill", rx, ry, 110, 95, 6, 6)
                        drawShadowText("[" .. pos .. " Empty]", rx + 10, ry + 40, 0.5, 0.5, 0.5, 0.85)
                    end
                    slotIdx = slotIdx + 1
                end
            end
        end
    end

    -- Navigation Text & Next Drive Button
    local isNextHover = checkHover(40, 480, 300, 45)
    love.graphics.setColor(isNextHover and {0.0, 0.76, 1.0} or {0.0, 0.58, 1.0})
    love.graphics.rectangle("fill", 40, 480, 300, 45, 8, 8)
    drawShadowText("NEXT DRIVE", 40, 492, 1, 1, 1, 1.1, "center", 300)
    
    drawShadowText("Press [SPACE] or Click NEXT DRIVE | [R] Reroll ($" .. (GameStateData.rerollCost or 2) .. ")", 360, 492, 1, 1, 1, 1.0)
    drawShadowText(self.shopMessage, 360, 515, 1, 0.84, 0, 1.0)
    
    -- Draw Tooltips at the end of shop draw
    local mx, my = love.mouse.getPosition()
    if self.hoveredShopItem then
        CardRender.drawTooltip(mx, my, self.hoveredShopItem)
    elseif self.hoveredRosterPlayer then
        CardRender.drawTooltip(mx, my, self.hoveredRosterPlayer)
    end
end

function StateShop:mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        local rerollCost = GameStateData.rerollCost or 2
        if checkHover(760, 25, 170, 45) then
            if GameStateData.capCash >= rerollCost then
                GameStateData.capCash = GameStateData.capCash - rerollCost
                SoundManager.playSFX("coin")
                self:rerollShop()
                self.shopMessage = "Rerolled Front Office Shop!"
            else
                self.shopMessage = "Not enough Cap Space to reroll!"
            end
            return
        end

        local cardW = 165
        local spacing = 180
        
        for i, item in ipairs(self.shopItems) do
            local ix = 30 + (i - 1) * spacing
            if checkHover(ix, 95, cardW, 220) then
                self:buyItem(item.slot)
                return
            end
        end
        
        local drawOrder = {"QB", "RB", "WR1", "WR2", "FLEX"}
        local slotIdx = 0
        if GameStateData.rosterSlots then
            for _, pos in ipairs(drawOrder) do
                local posData = GameStateData.rosterSlots[pos]
                if posData then
                    for i = 1, posData.max do
                        local rx = 50 + slotIdx * 125
                        local ry = 362
                        local player = posData.cards[i]
                        
                        if checkHover(rx, ry, 110, 95) and player then
                            if self.pendingEquipment then
                                player:addEquippedBadge(self.pendingEquipment)
                                SoundManager.playSFX("coin")
                                self.shopMessage = "Attached " .. self.pendingEquipment.name .. " to " .. player.name .. "!"
                                self.pendingEquipment = nil
                            elseif self.pendingTraining then
                                player:trainPlayer()
                                SoundManager.playSFX("coin")
                                self.shopMessage = "Trained " .. player.name .. "! Now " .. player.overall .. " OVR!"
                                self.pendingTraining = false
                            else
                                if _G.GAME_MODE == "roguelite" and slotIdx == 0 then
                                    self.shopMessage = "MyPlayer card is locked and cannot be released!"
                                    SoundManager.playSFX("click")
                                else
                                    local removed = table.remove(posData.cards, i)
                                    GameStateData.capCash = GameStateData.capCash + 3
                                    SoundManager.playSFX("coin")
                                    self.shopMessage = "Released " .. removed.name .. " for +$3 Cap Space!"
                                end
                            end
                            return
                        end
                        slotIdx = slotIdx + 1
                    end
                end
            end
        end
        
        if checkHover(40, 480, 300, 45) then
            local StateGame = require("src.states.state_game")
            if DefenseManager.activeBlind and DefenseManager.activeBlind.type == "standard" then
                GameStateData.nextRound("boss")
            else
                GameStateData.nextRound("standard")
            end
            DeckManager.drawHand()
            StateManager.switch(StateGame)
            return
        end
    elseif button == 2 then
        local drawOrder = {"QB", "RB", "WR1", "WR2", "FLEX"}
        local slotIdx = 0
        if GameStateData.rosterSlots then
            for _, pos in ipairs(drawOrder) do
                local posData = GameStateData.rosterSlots[pos]
                if posData then
                    for i = 1, posData.max do
                        local rx = 50 + slotIdx * 125
                        local ry = 362
                        local player = posData.cards[i]
                        
                        if checkHover(rx, ry, 110, 95) and player then
                            player.isFlipped = not player.isFlipped
                            SoundManager.playSFX("click")
                            return
                        end
                        slotIdx = slotIdx + 1
                    end
                end
            end
        end
    end
end

function StateShop:buyItem(slot)
    local item = self.shopItems[slot]
    if not item then return end
    
    if GameStateData.capCash < item.cost then
        self.shopMessage = "Not enough Cap Space!"
        return
    end
    
    if item.packType then
        GameStateData.capCash = GameStateData.capCash - item.cost
        SoundManager.playSFX("coin")
        
        local StatePackOpening = require("src.states.state_pack_opening")
        StatePackOpening.packType = item.packType
        StateManager.switch(StatePackOpening)
        return
    elseif slot == 4 and item.consumable then
        if #GameStateData.consumables >= GameStateData.maxConsumables then
            self.shopMessage = "Sideline Perk Tray is full (Max " .. GameStateData.maxConsumables .. ")!"
            SoundManager.playSFX("click")
            return
        end
        GameStateData.capCash = GameStateData.capCash - item.cost
        GameStateData.addConsumable(item.consumable)
        SoundManager.playSFX("coin")
        self.shopMessage = "Purchased Sideline Perk: " .. item.consumable.name .. "!"
        table.remove(self.shopItems, 4) -- Remove from shop after buy
    elseif slot == 5 and item.voucher then
        GameStateData.capCash = GameStateData.capCash - item.cost
        item.voucher.apply(GameStateData)
        SoundManager.playSFX("coin")
        self.shopMessage = "Activated Staff Upgrade: " .. item.voucher.name .. "!"
    end
end

function StateShop:keypressed(key)
    local rerollCost = GameStateData.rerollCost or 2
    if key == "r" then
        if GameStateData.capCash >= rerollCost then
            GameStateData.capCash = GameStateData.capCash - rerollCost
            SoundManager.playSFX("coin")
            self:rerollShop()
            self.shopMessage = "Rerolled Front Office Shop!"
        end
    elseif key == "1" then self:buyItem(1)
    elseif key == "2" then self:buyItem(2)
    elseif key == "3" then self:buyItem(3)
    elseif key == "4" then self:buyItem(4)
    elseif key == "5" then self:buyItem(5)
    elseif key == "space" then
        local StateGame = require("src.states.state_game")
        if DefenseManager.activeBlind and DefenseManager.activeBlind.type == "standard" then
            GameStateData.nextRound("boss")
        else
            GameStateData.nextRound("standard")
        end
        DeckManager.drawHand()
        StateManager.switch(StateGame)
    end
end

return StateShop
