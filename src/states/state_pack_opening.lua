-- src/states/state_pack_opening.lua
local StateManager = require("src.states.state_manager")
local GameStateData = require("src.engine.game_state")
local RosterPlayersExpanded = require("src.data.roster_players_expanded")
local CardRender = require("src.ui.card_render")
local SoundManager = require("src.engine.sound_manager")
local PhysicsUtils = require("src.engine.physics_utils")
local FxManager = require("src.engine.fx_manager")

local StatePackOpening = {}

function StatePackOpening:enter()
    self.packType = self.packType or "OFFENSIVE"
    self.ripped = false
    self.isRipping = false
    self.ripTime = 0
    self.cards = {}
    self.drafted = false
    
    local numCards = 3
    if self.packType == "MEGA" then numCards = 5 end
    
    for i = 1, numCards do
        local packItem = {}
        
        if self.packType == "PLAY" then
            local playTypes = {"Run", "Short Pass", "Medium Pass", "Deep Pass", "Play Action", "Screen Pass"}
            local pType = playTypes[math.random(#playTypes)]
            local PlayCard = require("src.entities.play_card")
            packItem = PlayCard.new(pType, pType)
            
            -- Small chance for Enhancement/Seal
            if math.random() < 0.15 then
                local e = {"Glass", "Steel", "Gold", "Stone"}
                packItem.enhancement = e[math.random(#e)]
            end
            if math.random() < 0.15 then
                local s = {"Red", "Gold", "Blue"}
                packItem.seal = s[math.random(#s)]
            end
            
        elseif self.packType == "CONSUMABLE" then
            local ConsumablesData = require("src.data.consumables")
            packItem = ConsumablesData[math.random(#ConsumablesData)]
            
        else
            -- Roster Player
            local pos
            if self.packType == "OFFENSIVE" then
                local p = {"QB", "RB", "WR", "TE"}
                if _G.GAME_MODE == "roguelite" then
                    local eligible = {}
                    for _, posName in ipairs(p) do
                        if GameStateData.hasSpaceForPosition(posName) then
                            table.insert(eligible, posName)
                        end
                    end
                    if #eligible > 0 then p = eligible end
                end
                pos = p[math.random(#p)]
            else
                -- MEGA Pack (roster players with boosted edition odds)
                local p = {"QB", "RB", "WR", "TE"}
                if _G.GAME_MODE == "roguelite" then
                    local eligible = {}
                    for _, posName in ipairs(p) do
                        if GameStateData.hasSpaceForPosition(posName) then
                            table.insert(eligible, posName)
                        end
                    end
                    if #eligible > 0 then p = eligible end
                end
                pos = p[math.random(#p)]
            end
            
            packItem = RosterPlayersExpanded.getRandomPlayer(pos)
            packItem.pos = pos
            
            -- Roll for Editions!
            if self.packType == "MEGA" then
                local r = math.random()
                if r < 0.02 then packItem.edition = "Cap Relief"
                elseif r < 0.10 then packItem.edition = "Prism"
                elseif r < 0.30 then packItem.edition = "Chrome"
                elseif r < 0.60 then packItem.edition = "Gold Leaf" 
                else packItem.edition = "Standard" end
            else
                local r = math.random()
                if r < 0.005 then packItem.edition = "Cap Relief"
                elseif r < 0.02 then packItem.edition = "Prism"
                elseif r < 0.05 then packItem.edition = "Chrome"
                elseif r < 0.15 then packItem.edition = "Gold Leaf"
                else packItem.edition = "Standard" end
            end
            
            -- Apply Edition Buffs
            if packItem.edition == "Prism" then packItem.baseMult = packItem.baseMult * 1.5
            elseif packItem.edition == "Chrome" then packItem.baseMult = packItem.baseMult + 0.5
            elseif packItem.edition == "Gold Leaf" then packItem.baseChips = packItem.baseChips + 5 end
        end
        
        table.insert(self.cards, {
            item = packItem,
            isFlipped = false,
            flipProgress = 0,
            x = 480,
            y = 270,
            targetX = 480,
            targetY = 270,
            vx = 0,
            vy = 0,
            rot = 0,
            targetRot = 0,
            vRot = 0,
            revealed = false
        })
    end
end

function StatePackOpening:update(dt)
    if self.isRipping then
        self.ripTime = self.ripTime + dt
        if self.ripTime > 0.4 then
            self.isRipping = false
            self.ripped = true
            SoundManager.playSFX("slam")
            if _G.triggerScreenShake then _G.triggerScreenShake(20, 0.4) end
            if _G.triggerHitStop then _G.triggerHitStop(0.1) end
            FxManager.addBurstParticles(480, 270, 80, 1, 0.84, 0)
            -- Spawn extra confetti for Mega packs
            if self.packType == "MEGA" then
                FxManager.addBurstParticles(480, 270, 100, 0.0, 0.76, 1.0)
            end
        end
    elseif self.ripped then
        local spacing = 160
        local startX = 480 - ((#self.cards - 1) * spacing) / 2
        
        for i, card in ipairs(self.cards) do
            card.targetX = startX + (i - 1) * spacing
            card.targetY = 270
            
            -- Fan rotation
            card.targetRot = (i - (#self.cards + 1) / 2) * 0.1
            
            local mx, my = love.mouse.getPosition()
            local isHovered = (mx >= card.x - 70 and mx <= card.x + 70 and my >= card.y - 100 and my <= card.y + 100)
            
            if isHovered and not self.drafted then
                card.targetY = 240
            end
            
            card.x, card.vx = PhysicsUtils.spring(card.x, card.targetX, card.vx, dt, 4, 0.7, 0)
            card.y, card.vy = PhysicsUtils.spring(card.y, card.targetY, card.vy, dt, 4, 0.6, 0)
            card.rot, card.vRot = PhysicsUtils.spring(card.rot, card.targetRot, card.vRot, dt, 4, 0.6, 0)
            
            if card.isFlipped and card.flipProgress < 1.0 then
                card.flipProgress = card.flipProgress + dt * 4
                if card.flipProgress >= 0.5 and not card.revealed then
                    card.revealed = true
                    -- Play pitch shifted flip sound
                    SoundManager.playSFX("coin", 1.0 + (i * 0.1))
                end
                if card.flipProgress >= 1.0 then card.flipProgress = 1.0 end
            end
        end
    end
end

local function drawCardBack(w, h)
    love.graphics.setColor(0.129, 0.149, 0.192)
    love.graphics.rectangle("fill", -w/2, -h/2, w, h, 8, 8)
    love.graphics.setColor(0, 0.76, 1)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", -w/2, -h/2, w, h, 8, 8)
    love.graphics.setLineWidth(1)
    
    love.graphics.setColor(1, 1, 1, 0.1)
    for i = 1, 10 do
        love.graphics.line(-w/2, -h/2 + i*20, w/2, -h/2 + i*20)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SCOUT\nREPORT", -w/2, -20, w, "center")
end

function StatePackOpening:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    if not self.ripped then
        -- Draw the pack
        love.graphics.push()
        love.graphics.translate(480, 270)
        
        local alpha = 1.0
        if self.isRipping then
            -- Violent shake and scale up
            local shakeX = (math.random() - 0.5) * 40
            local shakeY = (math.random() - 0.5) * 40
            love.graphics.translate(shakeX, shakeY)
            
            local sc = 1.0 + self.ripTime * 1.5
            love.graphics.scale(sc, sc)
            
            alpha = math.max(0, 1.0 - (self.ripTime / 0.4))
        else
            love.graphics.rotate(math.sin(love.timer.getTime() * 2) * 0.05)
        end
        
        -- Flash white at the end of the rip
        if self.isRipping and self.ripTime > 0.25 then
            love.graphics.setColor(1, 1, 1, alpha)
        else
            love.graphics.setColor(1, 0.84, 0, alpha)
        end
        
        love.graphics.rectangle("fill", -120, -160, 240, 320, 10, 10)
        
        love.graphics.setColor(0, 0, 0, alpha * 0.9)
        local pType = self.packType or "OFFENSIVE"
        local displayName = pType .. " PACK"
        if pType == "CONSUMABLE" then displayName = "SIDELINE\nADJUSTMENT"
        elseif pType == "PLAY" then displayName = "PLAYBOOK\nPACK"
        elseif pType == "OFFENSIVE" then displayName = "OFFENSIVE\nSCOUT PACK"
        elseif pType == "MEGA" then displayName = "MEGA\nSCOUT PACK" end
        love.graphics.printf(displayName, -120, -30, 240, "center", 0, 1.2, 1.2)
        
        love.graphics.pop()
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Click Pack to Rip Open", 0, 480, 960, "center")
    else
        self.hoveredCard = nil
        local mx, my = love.mouse.getPosition()
        
        for _, card in ipairs(self.cards) do
            love.graphics.push()
            love.graphics.translate(card.x, card.y)
            love.graphics.rotate(card.rot)
            
            -- 3D Flip effect (scale width based on flipProgress)
            -- 0 to 0.5 shrinks to 0. 0.5 to 1.0 grows to 1
            local scaleX = 1.0
            if card.isFlipped then
                scaleX = math.abs(math.cos(card.flipProgress * math.pi))
            end
            
            love.graphics.scale(scaleX, 1.0)
            
            if not card.revealed then
                drawCardBack(140, 190)
            else
                if self.packType == "PLAY" then
                    CardRender.drawPlayCard(0, 0, card.item, false, love.timer.getTime())
                elseif self.packType == "CONSUMABLE" then
                    love.graphics.setColor(0.129, 0.149, 0.192)
                    love.graphics.rectangle("fill", -70, -95, 140, 190, 8, 8)
                    love.graphics.setColor(0, 0.76, 1)
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", -70, -95, 140, 190, 8, 8)
                    love.graphics.setLineWidth(1)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf(card.item.name:upper(), -60, -80, 120, "center")
                    love.graphics.setColor(0.8, 0.8, 0.8)
                    love.graphics.printf(card.item.description, -60, -30, 120 / 0.75, "center", 0, 0.75, 0.75)
                else
                    CardRender.drawPlayerCard(0, 0, card.item, false, love.timer.getDelta())
                end
            end
            
            love.graphics.pop()
            
            -- Hover check (revealed cards only for tooltip)
            if card.revealed and not self.drafted then
                if mx >= card.x - 70 and mx <= card.x + 70 and my >= card.y - 100 and my <= card.y + 100 then
                    self.hoveredCard = card.item
                end
            end
        end
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Click a card to reveal. Click a revealed card to Draft it.", 0, 465, 960, "center")
        
        -- Draw SKIP PACK button
        local isSkipHover = mx >= 420 and mx <= 540 and my >= 498 and my <= 524
        love.graphics.setColor(isSkipHover and {0.9, 0.3, 0.3} or {0.7, 0.2, 0.2})
        love.graphics.rectangle("fill", 420, 498, 120, 26, 6, 6)
        love.graphics.setColor(0, 0.76, 1)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", 420, 498, 120, 26, 6, 6)
        love.graphics.setLineWidth(1)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SKIP PACK", 420, 503, 120, "center")
        
        -- Draw hover tooltip if active
        if self.hoveredCard then
            CardRender.drawTooltip(mx, my, self.hoveredCard)
        end
    end
end

function StatePackOpening:mousepressed(x, y, button)
    if button == 1 then
        if not self.ripped and not self.isRipping then
            if x >= 360 and x <= 600 and y >= 110 and y <= 430 then
                self.isRipping = true
                self.ripTime = 0
                SoundManager.playSFX("tackle")
            end
            return
        end
        
        -- Check if Skip Pack button clicked
        if not self.drafted then
            if x >= 420 and x <= 540 and y >= 498 and y <= 524 then
                SoundManager.playSFX("click")
                local StateShop = require("src.states.state_shop")
                StateShop.shopMessage = "Pack skipped!"
                StateManager.switch(StateShop)
                return
            end
        end
        
        if self.drafted then return end
        
        for _, card in ipairs(self.cards) do
            if x >= card.x - 70 and x <= card.x + 70 and y >= card.y - 100 and y <= card.y + 100 then
                if not card.isFlipped then
                    card.isFlipped = true
                    SoundManager.playSFX("click")
                elseif card.revealed then
                    -- Draft the card!
                    local success = false
                    local msg = ""
                    
                    if self.packType == "PLAY" then
                        local DeckManager = require("src.engine.deck_manager")
                        table.insert(DeckManager.playbook, card.item)
                        success = true
                        msg = "Drafted " .. card.item.name .. " to Playbook!"
                    elseif self.packType == "CONSUMABLE" then
                        if #GameStateData.consumables < GameStateData.maxConsumables then
                            GameStateData.addConsumable(card.item)
                            success = true
                            msg = "Drafted " .. card.item.name .. " to Sideline!"
                        else
                            -- Tray full: swap out 1st consumable
                            local oldName = GameStateData.consumables[1].name
                            GameStateData.consumables[1] = card.item
                            success = true
                            msg = "Swapped " .. oldName .. " for " .. card.item.name .. "!"
                        end
                    else
                        local cardPos = card.item and (card.item.pos or card.item.position)
                        success = GameStateData.addRosterPlayer(card.item, cardPos)
                        if success then msg = "Drafted " .. ((card.item and card.item.name) or "Player") .. " from Scout Pack!"
                        else msg = "ROSTER SLOT FULL!" end
                    end
                    
                    if success then
                        self.drafted = true
                        SoundManager.playSFX("coin")
                        local FxManager = require("src.engine.fx_manager")
                        FxManager.addFloatingText("DRAFTED!", card.x, card.y - 50, 0, 0.76, 1, 1.5)
                        
                        local StateShop = require("src.states.state_shop")
                        StateShop.shopMessage = msg
                        StateManager.switch(StateShop)
                    else
                        SoundManager.playSFX("tackle")
                        local FxManager = require("src.engine.fx_manager")
                        FxManager.addFloatingText(msg, card.x, card.y - 50, 1, 0.2, 0.2, 1.5)
                    end
                end
                return
            end
        end
    elseif button == 2 and self.ripped then
        for _, card in ipairs(self.cards) do
            if x >= card.x - 70 and x <= card.x + 70 and y >= card.y - 100 and y <= card.y + 100 then
                if card.revealed and card.item.position then
                    card.item.isFlipped = not card.item.isFlipped
                    SoundManager.playSFX("click")
                    return
                end
            end
        end
    end
end

return StatePackOpening
