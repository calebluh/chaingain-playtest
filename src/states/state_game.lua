-- src/states/state_game.lua
local GameStateData = require("src.engine.game_state")
local DeckManager = require("src.engine.deck_manager")
local DefenseManager = require("src.engine.defense_manager")
local PlayerCard = require("src.entities.player_card")
local CardRender = require("src.ui.card_render")
local ScoringEvaluator = require("src.engine.scoring_evaluator")
local FieldAnimator = require("src.ui.field_animator")
local StadiumPulse = require("src.engine.stadium_pulse")
local StateManager = require("src.states.state_manager")
local PhysicsUtils = require("src.engine.physics_utils")
local AssetManager = require("src.engine.asset_manager")
local SoundManager = require("src.engine.sound_manager")
local FxManager = require("src.engine.fx_manager")
local SaveManager = require("src.engine.save_manager")
local Loc = require("src.engine.loc_manager")
local SettingsData = require("src.data.settings_data")
local RPOMinigame = require("src.ui.rpo_minigame")

local StateGame = {}

local C_SLATE_CONTAINER = {0.129, 0.149, 0.192} -- #212631
local C_BORDER_NORMAL = {0.227, 0.259, 0.322} -- #3A4252
local C_NEON_BORDER = {0.0, 0.76, 1.0} -- #00C3FF
local C_NEON_ACCENT = {1.0, 0.84, 0.0} -- #FFD700
local C_CHIP_BLUE = {0.0, 0.58, 1.0} -- #0094FF
local C_MULT_RED = {1.0, 0.3, 0.3} -- #FF4D4D

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

function StateGame:enter()
    self.selectedPlayIndex = nil
    self.draggingCardIndex = nil
    self.dragLastX = 0
    self.time = 0
    self.paused = false
    self.showPlaybookModal = false
    self.hoveredRosterPlayer = nil
    self.justSelectedThisClick = false
    self.show4thDownPrompt = false
    self.was4thDown = false
    
    if #DeckManager.hand == 0 then
        DeckManager.drawHand()
    end
    
    SoundManager.playMusic("gameplay_theme")
end

function StateGame:exit()
end

function StateGame:update(dt)
    if self.paused or self.showPlaybookModal then return end
    
    RPOMinigame.update(dt)
    if RPOMinigame.active then return end
    
    self.time = self.time + dt
    local weatherType = GameStateData.weather or "clear"
    FxManager.update(dt, weatherType)
    
    GameStateData.updatePlayClock(dt)
    ScoringEvaluator.update(dt)
    
    -- Handle Status Transitions when play animations complete
    if not ScoringEvaluator.active and not FieldAnimator.active then
        if GameStateData.status == "TOUCHDOWN" or GameStateData.status == "DRIVE_COMPLETE" then
            if GameStateData.drivesRemaining > 0 and GameStateData.currentPoints < GameStateData.targetPoints then
                GameStateData.startDrive()
                DeckManager.drawHand()
            elseif GameStateData.currentPoints >= GameStateData.targetPoints then
                GameStateData.status = "GAME_WON"
            else
                GameStateData.status = "GAME_LOST"
            end
        elseif GameStateData.status == "DRIVE_LOST" then
            if GameStateData.drivesRemaining > 0 then
                GameStateData.startDrive()
                DeckManager.drawHand()
            else
                GameStateData.status = "GAME_LOST"
            end
        elseif GameStateData.status == "GAME_WON" then
            local StateShop = require("src.states.state_shop")
            StateManager.switch(StateShop)
        elseif GameStateData.status == "GAME_LOST" or GameStateData.status == "TURNOVER" then
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
        end
    end
    
    if GameStateData.down == 4 and GameStateData.status == "PLAYING" then
        if not self.was4thDown then
            self.show4thDownPrompt = true
            self.was4thDown = true
        end
    else
        self.was4thDown = false
        self.show4thDownPrompt = false
    end

    if self.selectedPlayIndex and self.selectedPlayIndex > #DeckManager.hand then
        self.selectedPlayIndex = nil
    end

    local mx, my = love.mouse.getPosition()
    local N = #DeckManager.hand
    local startX = 480 - ((N - 1) * 95) / 2
    
    for i, card in ipairs(DeckManager.hand) do
        local targetX = startX + (i - 1) * 95
        local targetY = 390
        local isHovered = (mx >= targetX - 45 and mx <= targetX + 45 and my >= targetY - 60 and my <= targetY + 80)
        local relX = mx - targetX
        if card.update then card:update(dt, isHovered, relX) end
        
        if self.draggingCardIndex == i then
            targetX = mx
            targetY = my
        end
            local dx = mx - self.dragLastX
            baseRot = dx * 0.015
        elseif i == self.selectedPlayIndex then
            targetY = 340
            baseRot = math.sin(self.time * 4) * 0.03
        elseif isHovered then
            targetY = 370
            baseRot = (i - (N + 1) / 2) * 0.05
        end
        
        card.xOffset = card.xOffset or targetX
        card.yOffset = card.yOffset or targetY
        card.rot = card.rot or baseRot
        card.scale = card.scale or 1.0
        
        card.xVelocity = card.xVelocity or 0
        card.yVelocity = card.yVelocity or 0
        card.rotVelocity = card.rotVelocity or 0
        card.scaleVelocity = card.scaleVelocity or 0
        
        local targetScale = (i == self.selectedPlayIndex or self.draggingCardIndex == i) and 1.15 or 1.0
        
        card.xOffset, card.xVelocity = PhysicsUtils.spring(card.xOffset, targetX, card.xVelocity, dt, 4, 0.7, 0)
        card.yOffset, card.yVelocity = PhysicsUtils.spring(card.yOffset, targetY, card.yVelocity, dt, 4, 0.6, 0)
        card.rot, card.rotVelocity = PhysicsUtils.spring(card.rot, baseRot, card.rotVelocity, dt, 3, 0.6, 0)
        card.scale, card.scaleVelocity = PhysicsUtils.spring(card.scale, targetScale, card.scaleVelocity, dt, 4, 0.6, 0)
    end
    
    self.dragLastX = mx
end

function StateGame:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    love.graphics.setColor(0.12, 0.15, 0.22, 0.4)
    for i = 0, 24 do
        local yPos = (i * 25 + self.time * 15) % 560
        love.graphics.line(0, yPos, 960, yPos)
    end
    
    local weatherType = GameStateData.weather or "clear"
    FxManager.draw(weatherType)

    local previewChips = 0
    local previewMult = 0
    
    if ScoringEvaluator.active then
        previewChips = math.floor(ScoringEvaluator.displayedChips)
        previewMult = ScoringEvaluator.displayedMult
    else
        local activeCard = DeckManager.hand[self.selectedPlayIndex]
        if activeCard then
            previewChips = activeCard.baseChips
            previewMult = activeCard.baseMult
            
            local rosterChips = 0
            local rosterMult = 0
            if GameStateData.rosterSlots then
                for posName, posData in pairs(GameStateData.rosterSlots) do
                    for _, player in ipairs(posData.cards) do
                        local chipBonus, multBonus = player:evaluatePlay(activeCard, GameStateData)
                        rosterChips = rosterChips + chipBonus
                        rosterMult = rosterMult + multBonus
                    end
                end
            end
            
            previewChips = previewChips + rosterChips
            previewMult = previewMult + rosterMult + (GameStateData.tempMultBoost or 0)
            previewChips, previewMult = DefenseManager.evaluatePlay(activeCard.type, previewChips, previewMult)
            previewMult = math.max(0.1, previewMult)
        end
    end

    local function drawNeonPanel(px, py, pw, ph, colorOverride)
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", px, py, pw, ph, 6, 6)
        love.graphics.setColor(colorOverride or C_BORDER_NORMAL)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", px, py, pw, ph, 6, 6)
        love.graphics.setLineWidth(1)
    end

    local panelY = 8
    drawNeonPanel(12, panelY, 155, 68)
    local tierStr = "DIFFICULTY: " .. (GameStateData.stakeTier or "white"):upper()
    drawShadowText("OPPONENT DEFENSE", 12, panelY + 6, 0.8, 0.8, 0.8, 0.85, "center", 155)
    if DefenseManager.activeBlind then
        drawShadowText(tierStr, 12, panelY + 26, 0.6, 0.6, 0.7, 0.7, "center", 155)
        drawShadowText(DefenseManager.activeBlind.name, 12, panelY + 40, 1, 1, 1, 0.9, "center", 155)
    end

    drawNeonPanel(174, panelY, 165, 68)
    drawShadowText("POINTS SCORE", 174, panelY + 6, 0.8, 0.8, 0.8, 0.85, "center", 165)
    drawShadowText(GameStateData.currentPoints .. " / " .. GameStateData.targetPoints .. " PTS", 174, panelY + 24, 1, 0.84, 0, 1.25, "center", 165)
    drawShadowText("DRIVES LEFT: " .. GameStateData.drivesRemaining, 174, panelY + 46, 1, 1, 1, 0.85, "center", 165)

    drawNeonPanel(346, panelY, 250, 68)
    love.graphics.setColor(C_CHIP_BLUE)
    love.graphics.rectangle("fill", 354, panelY + 10, 100, 48, 5, 5)
    drawShadowText(tostring(previewChips) .. " YDS", 354, panelY + 24, 1, 1, 1, 1.2, "center", 100)
    
    drawShadowText("X", 458, panelY + 24, 1, 0.3, 0.3, 1.2, "center", 25)
    
    love.graphics.setColor(C_MULT_RED)
    love.graphics.rectangle("fill", 488, panelY + 10, 100, 48, 5, 5)
    drawShadowText(string.format("x%.1f MTM", previewMult), 488, panelY + 24, 1, 1, 1, 1.2, "center", 100)

    drawNeonPanel(603, panelY, 130, 68, C_NEON_ACCENT)
    drawShadowText("ADJUST", 603, panelY + 4, 1, 0.84, 0, 0.85, "center", 130)
    for ci = 1, GameStateData.maxConsumables do
        local cx = 610 + (ci - 1) * 58
        local cy = panelY + 20
        local item = GameStateData.consumables[ci]
        love.graphics.setColor(item and {0.8, 0.3, 0.1} or {0.18, 0.22, 0.28})
        love.graphics.rectangle("fill", cx, cy, 52, 42, 4, 4)
        love.graphics.setColor(C_BORDER_NORMAL)
        love.graphics.rectangle("line", cx, cy, 52, 42, 4, 4)
        if item then
            drawShadowText(item.name:sub(1, 7), cx + 2, cy + 14, 1, 1, 1, 0.75, "center", 48)
        else
            drawShadowText("[EMPTY]", cx + 2, cy + 14, 0.5, 0.5, 0.5, 0.75, "center", 48)
        end
    end

    local clockSecs = math.max(0, math.ceil(GameStateData.playClock))
    local isLowClock = clockSecs <= 5
    local clockColor = isLowClock and {1.0, 0.2, 0.2} or C_NEON_BORDER
    drawNeonPanel(740, panelY, 80, 68, clockColor)
    drawShadowText("CLOCK", 740, panelY + 6, 0.8, 0.8, 0.8, 0.85, "center", 80)
    drawShadowText(string.format("%02d", clockSecs), 740, panelY + 28, isLowClock and 1 or 0, isLowClock and 0.2 or 0.84, isLowClock and 0.2 or 0, 1.8, "center", 80)

    drawNeonPanel(820, panelY, 63, 68)
    local ballStr = GameStateData.yardLine < 50 and ("O" .. GameStateData.yardLine) or ("D" .. (100 - GameStateData.yardLine))
    drawShadowText("D:" .. GameStateData.down, 822, panelY + 6, 1, 1, 1, 0.75)
    drawShadowText("Y:" .. GameStateData.distance, 822, panelY + 24, 1, 1, 1, 0.75)
    drawShadowText(ballStr, 822, panelY + 44, 1, 0.84, 0, 0.75)

    local hoverSpeed = checkHover(886, panelY, 36, 68)
    local speedStr = string.format("%.0fx", SettingsData.gameSpeed or 1.0)
    drawNeonPanel(886, panelY, 36, 68, hoverSpeed and {1.0, 0.84, 0.0} or C_BORDER_NORMAL)
    drawShadowText("⏩", 886, panelY + 12, 1, 0.84, 0, 0.9, "center", 36)
    drawShadowText(speedStr, 886, panelY + 38, 1, 1, 1, 0.9, "center", 36)

    local hoverOpt = checkHover(925, panelY, 23, 68)
    drawNeonPanel(925, panelY, 23, 68, hoverOpt and {0.0, 0.76, 1.0} or C_BORDER_NORMAL)
    drawShadowText("⚙", 925, panelY + 22, 1, 1, 1, 1.2, "center", 23)

    -- Progress Bar
    love.graphics.setColor(0.08, 0.1, 0.14, 0.9)
    love.graphics.rectangle("fill", 12, 82, 915, 18, 4, 4)
    local pct = math.min(1.0, GameStateData.yardLine / 100)
    love.graphics.setColor(0.18, 0.72, 0.45, 1)
    love.graphics.rectangle("fill", 12, 82, 915 * pct, 18, 4, 4)
    
    love.graphics.setColor(1, 0.84, 0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(12 + 915 * 0.65, 82, 12 + 915 * 0.65, 100)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(C_NEON_BORDER)
    love.graphics.rectangle("line", 12, 82, 915, 18, 4, 4)
    
    local ydsToEndZone = math.max(0, 100 - GameStateData.yardLine)
    drawShadowText("FIELD POSITION: " .. ballStr .. " (" .. ydsToEndZone .. " YDS TO END ZONE)", 12, 84, 1, 1, 1, 0.85, "center", 915)

    -- Stadium Pulse Meter
    StadiumPulse.draw(935, 10)

    -- Roster Slots
    local drawOrder = {"QB", "RB", "WR1", "WR2", "FLEX"}
    local totalSlots = 0
    if GameStateData.rosterSlots then
        for _, pos in ipairs(drawOrder) do
            if GameStateData.rosterSlots[pos] then
                totalSlots = totalSlots + GameStateData.rosterSlots[pos].max
            end
        end
    end
    
    local startXRoster = 480 - ((totalSlots - 1) * 110) / 2
    local currentSlotIdx = 0
    self.hoveredRosterPlayer = nil
    local mx, my = love.mouse.getPosition()
    
    if GameStateData.rosterSlots then
        for _, pos in ipairs(drawOrder) do
            local posData = GameStateData.rosterSlots[pos]
            if posData then
                for i = 1, posData.max do
                    local rx = startXRoster + currentSlotIdx * 110
                    local ry = 165
                    local isRosterHover = (mx >= rx - 45 and mx <= rx + 45 and my >= ry - 55 and my <= ry + 55)
                    
                    local player = posData.cards[i]
                    if player then
                        if isRosterHover then self.hoveredRosterPlayer = player end
                        CardRender.drawPlayerCard(rx, ry, player, isRosterHover, love.timer.getDelta())
                    else
                        love.graphics.push()
                        love.graphics.translate(rx, ry)
                        love.graphics.setColor(C_SLATE_CONTAINER)
                        love.graphics.rectangle("fill", -50, -55, 100, 110, 6, 6)
                        love.graphics.setColor(C_BORDER_NORMAL)
                        love.graphics.rectangle("line", -50, -55, 100, 110, 6, 6)
                        local label = (posData.max > 1) and (pos .. " " .. i) or pos
                        drawShadowText("[" .. label .. "]", -50, -5, 0.5, 0.5, 0.5, 1.0, "center", 100)
                        love.graphics.pop()
                    end
                    currentSlotIdx = currentSlotIdx + 1
                end
            end
        end
    end

    -- 4th Down Decision Tree
    if self.show4thDownPrompt and GameStateData.status == "PLAYING" then
        love.graphics.setColor(0.12, 0.15, 0.22, 0.95)
        love.graphics.rectangle("fill", 160, 232, 640, 45, 8, 8)
        love.graphics.setColor(C_NEON_ACCENT)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 160, 232, 640, 45, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText("4TH DOWN DECISION:", 170, 244, 1, 0.84, 0, 1.1)
        
        local isPlayHover = checkHover(340, 240, 140, 30)
        love.graphics.setColor(isPlayHover and {0.0, 0.76, 1.0} or C_CHIP_BLUE)
        love.graphics.rectangle("fill", 340, 240, 140, 30, 6, 6)
        drawShadowText("GO FOR IT", 340, 248, 1, 1, 1, 0.9, "center", 140)
        
        local canFG = GameStateData.yardLine >= 65
        local isFgHover = canFG and checkHover(490, 240, 150, 30)
        love.graphics.setColor(canFG and (isFgHover and {0.0, 0.76, 1.0} or C_NEON_ACCENT) or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", 490, 240, 150, 30, 6, 6)
        drawShadowText(canFG and "KICK FG (+3 PTS)" or "FG OUT OF RANGE", 490, 248, canFG and 1 or 0.5, canFG and 1 or 0.5, canFG and 1 or 0.5, 0.85, "center", 150)
        
        local isPuntHover = checkHover(650, 240, 140, 30)
        love.graphics.setColor(isPuntHover and {0.0, 0.76, 1.0} or C_BORDER_NORMAL)
        love.graphics.rectangle("fill", 650, 240, 140, 30, 6, 6)
        drawShadowText("PUNT BALL", 650, 248, 1, 1, 1, 0.9, "center", 140)
    end

    -- Play Cards
    self.hoveredPlayCard = nil
    for i, card in ipairs(DeckManager.hand) do
        local isHover = mx >= card.xOffset - 45 and mx <= card.xOffset + 45 and my >= card.yOffset - 60 and my <= card.yOffset + 60
        if isHover then
            self.hoveredPlayCard = card
        end
        
        love.graphics.push()
        love.graphics.translate(card.xOffset, card.yOffset)
        love.graphics.rotate(card.rot)
        
        -- Pseudo-3D velocity tilt
        local tiltX = (card.xVelocity or 0) * 0.0005
        local tiltY = (card.yVelocity or 0) * -0.0005
        love.graphics.shear(tiltY, tiltX)
        
        love.graphics.scale(card.scale or 1.0, card.scale or 1.0)
        
        CardRender.drawPlayCard(0, 0, card, i == self.selectedPlayIndex, self.time)
        
        love.graphics.pop()
    end

    -- 1st/2nd/3rd Down Call Play Button (if card selected)
    if GameStateData.down < 4 and GameStateData.status == "PLAYING" and self.selectedPlayIndex then
        local playCard = DeckManager.hand[self.selectedPlayIndex]
        local ScoringEvaluator = require("src.engine.scoring_evaluator")
        local risk, riskType = ScoringEvaluator.calculateTurnoverRisk(playCard, GameStateData)
        
        local isPlayHover = checkHover(380, 240, 200, 30)
        local buttonColor = C_CHIP_BLUE
        local neonColor = C_NEON_BORDER
        if risk > 0 then
            buttonColor = isPlayHover and {1.0, 0.45, 0.0} or {0.85, 0.3, 0.0}
            neonColor = {1.0, 0.7, 0.0}
        else
            buttonColor = isPlayHover and {0.0, 0.76, 1.0} or C_CHIP_BLUE
        end
        
        love.graphics.setColor(buttonColor)
        love.graphics.rectangle("fill", 380, 240, 200, 30, 6, 6)
        love.graphics.setColor(neonColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 380, 240, 200, 30, 6, 6)
        love.graphics.setLineWidth(1)
        
        local buttonText = "CALL PLAY"
        if risk > 0 then
            buttonText = string.format("CALL PLAY (%s: %d%%)", riskType, risk)
        end
        drawShadowText(buttonText, 380, 248, 1, 1, 1, 0.85, "center", 200)
    end

    -- Hover Tooltip
    if self.hoveredRosterPlayer then
        CardRender.drawTooltip(mx, my, self.hoveredRosterPlayer)
    elseif self.hoveredPlayCard then
        CardRender.drawTooltip(mx, my, self.hoveredPlayCard)
    end
    
    local FieldAnimator = require("src.ui.field_animator")
    if FieldAnimator.active then
        FieldAnimator.draw()
    end
    
    if ScoringEvaluator.active then
        ScoringEvaluator.draw()
    end

    RPOMinigame.draw()

    -- Status Banners & Navigation
    if GameStateData.status == "PLAYING" then
        if DefenseManager.currentPlay then
            drawShadowText("DEFENSIVE TELL: " .. DefenseManager.currentPlay.hint, 20, 485, 0.8, 1, 0.8, 1.1)
        end
        drawShadowText("[←/→/Click]: Play | [Right-Click]: Flip Card | [1/2]: Adjustments | [Q]: Audible | [ESC]: Pause", 20, 512, 1, 1, 1, 1.0)
        
        local isPlaybookHover = checkHover(800, 475, 145, 30)
        love.graphics.setColor(isPlaybookHover and {0.0, 0.76, 1.0} or {0.129, 0.149, 0.192})
        love.graphics.rectangle("fill", 800, 475, 145, 30, 6, 6)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", 800, 475, 145, 30, 6, 6)
        love.graphics.setLineWidth(1)
        
        local totalCards = #DeckManager.playbook
        local drawCount = #DeckManager.drawPile
        local btnText = string.format("PLAYBOOK (%d/%d)", drawCount, totalCards)
        drawShadowText(btnText, 800, 483, 1, 1, 1, 0.85, "center", 145)
        
        if isPlaybookHover and not self.showPlaybookModal then
            local mx, my = love.mouse.getPosition()
            CardRender.drawDeckTooltip(mx, my)
        end
    elseif GameStateData.status == "TOUCHDOWN" then
        drawShadowText("DRIVE COMPLETED! PRESS [SPACE] TO VISIT FRONT OFFICE SHOP", 20, 510, 1, 0.84, 0, 1.2)
    elseif GameStateData.status == "GAME_WON" then
        drawShadowText("GAME WON! TARGET REACHED! PRESS [SPACE] FOR NEXT WEEK", 20, 510, 0.2, 0.8, 0.4, 1.3)
    elseif GameStateData.status == "TURNOVER" then
        drawShadowText("OUT OF DRIVES! PRESS [R] TO RESTART SEASON RUN", 20, 510, 1, 0.2, 0.2, 1.2)
    end
    
    -- In-Game Pause Overlay Modal
    if self.paused then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", 310, 120, 340, 300, 8, 8)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 310, 120, 340, 300, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText("GAME PAUSED", 310, 140, 1, 1, 1, 2.0, "center", 340)
        
        -- Resume Button
        local isResumeHover = checkHover(360, 200, 240, 45)
        love.graphics.setColor(isResumeHover and {0.0, 0.76, 1.0} or C_CHIP_BLUE)
        love.graphics.rectangle("fill", 360, 200, 240, 45, 6, 6)
        drawShadowText("RESUME GAME", 360, 213, 1, 1, 1, 1.1, "center", 240)
        
        -- Save & Quit Button
        local isSaveHover = checkHover(360, 265, 240, 45)
        love.graphics.setColor(isSaveHover and {0.0, 0.76, 1.0} or C_NEON_ACCENT)
        love.graphics.rectangle("fill", 360, 265, 240, 45, 6, 6)
        drawShadowText("SAVE & QUIT TO MENU", 360, 278, 0, 0, 0, 1.0, "center", 240)
        
        -- Abandon Run Button
        local isAbandonHover = checkHover(360, 330, 240, 45)
        love.graphics.setColor(isAbandonHover and {1.0, 0.4, 0.4} or C_MULT_RED)
        love.graphics.rectangle("fill", 360, 330, 240, 45, 6, 6)
        drawShadowText("ABANDON RUN", 360, 343, 1, 1, 1, 1.1, "center", 240)
    end

    -- In-Game Playbook Overlay Modal
    if self.showPlaybookModal then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        
        love.graphics.setColor(0.08, 0.1, 0.12, 0.98)
        love.graphics.rectangle("fill", 40, 20, 880, 500, 10, 10)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2.5)
        love.graphics.rectangle("line", 40, 20, 880, 500, 10, 10)
        love.graphics.setLineWidth(1)
        
        drawShadowText("YOUR PLAYBOOK (DECK STATUS)", 60, 35, 1, 0.84, 0, 1.4)
        
        -- Legend
        love.graphics.setColor(0.0, 0.58, 1.0)
        love.graphics.circle("fill", 500, 46, 5)
        drawShadowText("DECK", 510, 38, 0.7, 0.8, 0.9, 0.85)
        
        love.graphics.setColor(0.2, 0.8, 0.4)
        love.graphics.circle("fill", 600, 46, 5)
        drawShadowText("HAND", 610, 38, 0.7, 0.8, 0.9, 0.85)
        
        love.graphics.setColor(0.85, 0.3, 0.3)
        love.graphics.circle("fill", 700, 46, 5)
        drawShadowText("DISCARD", 710, 38, 0.7, 0.8, 0.9, 0.85)
        
        self.hoveredPlaybookCard = nil
        
        local mx, my = love.mouse.getPosition()
        for i, card in ipairs(DeckManager.playbook or {}) do
            local col = (i - 1) % 8
            local row = math.floor((i - 1) / 8)
            local cx = 100 + col * 108
            local cy = 135 + row * 155
            
            love.graphics.push()
            love.graphics.translate(cx, cy)
            love.graphics.scale(0.68, 0.68)
            CardRender.drawPlayCard(0, 0, card, false, self.time)
            love.graphics.pop()
            
            -- Check Status
            local status = "DECK"
            local statusColor = {0.0, 0.58, 1.0}
            for _, hc in ipairs(DeckManager.hand or {}) do
                if hc == card then status = "HAND"; statusColor = {0.2, 0.8, 0.4} end
            end
            for _, dc in ipairs(DeckManager.discardPile or {}) do
                if dc == card then status = "DISCARD"; statusColor = {0.85, 0.3, 0.3} end
            end
            
            love.graphics.setColor(statusColor)
            love.graphics.rectangle("fill", cx - 40, cy + 64, 80, 16, 4, 4)
            drawShadowText(status, cx - 40, cy + 66, 1, 1, 1, 0.75, "center", 80)
            
            local isHover = mx >= cx - 44 and mx <= cx + 44 and my >= cy - 60 and my <= cy + 60
            if isHover then
                self.hoveredPlaybookCard = card
            end
        end
        
        -- Draw close button
        local isCloseHover = checkHover(420, 480, 120, 32)
        love.graphics.setColor(isCloseHover and {0.9, 0.3, 0.3} or {0.7, 0.2, 0.2})
        love.graphics.rectangle("fill", 420, 480, 120, 32, 6, 6)
        drawShadowText("CLOSE", 420, 488, 1, 1, 1, 0.85, "center", 120)
    end

    if self.showPlaybookModal and self.hoveredPlaybookCard then
        local mx, my = love.mouse.getPosition()
        CardRender.drawTooltip(mx, my, self.hoveredPlaybookCard)
    end
end

function StateGame:mousepressed(x, y, button, istouch, presses)
    if ScoringEvaluator.active then return end
    
    if self.paused and button == 1 then
        if checkHover(360, 200, 240, 45) then
            self.paused = false
            SoundManager.playSFX("click")
        elseif checkHover(360, 265, 240, 45) then
            SaveManager.saveActiveRun(GameStateData)
            SoundManager.playSFX("click")
            self.paused = false
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
        elseif checkHover(360, 330, 240, 45) then
            SaveManager.clearActiveRun()
            SoundManager.playSFX("click")
            self.paused = false
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
        end
        return
    end

    if self.showPlaybookModal and button == 1 then
        if checkHover(420, 480, 120, 32) then
            self.showPlaybookModal = false
            SoundManager.playSFX("click")
        elseif x < 40 or x > 920 or y < 20 or y > 520 then
            self.showPlaybookModal = false
            SoundManager.playSFX("click")
        end
        return
    end

    if GameStateData.status == "PLAYING" and not self.paused then
        if button == 1 and checkHover(886, 8, 36, 68) then
            local currentSpeed = SettingsData.gameSpeed or 1.0
            SettingsData.gameSpeed = (currentSpeed == 1.0) and 2.0 or ((currentSpeed == 2.0) and 4.0 or 1.0)
            SoundManager.playSFX("click")
            return
        end
        if button == 1 and checkHover(925, 8, 23, 68) then
            local PauseOverlay = require("src.ui.pause_overlay")
            StateManager.openOverlay(PauseOverlay)
            SoundManager.playSFX("click")
            return
        end
        if button == 1 and checkHover(800, 475, 145, 30) then
            self.showPlaybookModal = true
            SoundManager.playSFX("click")
            return
        end
        if button == 1 then
            if self.show4thDownPrompt then
                if checkHover(340, 240, 140, 30) then
                    self.show4thDownPrompt = false
                    SoundManager.playSFX("click")
                    return
                elseif checkHover(490, 240, 150, 30) and GameStateData.yardLine >= 65 then
                    self.show4thDownPrompt = false
                    SoundManager.playSFX("click")
                    self:dealSpecialTeams("Kick")
                    return
                elseif checkHover(650, 240, 140, 30) then
                    self.show4thDownPrompt = false
                    SoundManager.playSFX("click")
                    self:dealSpecialTeams("Punt")
                    return
                end
                return
            elseif GameStateData.down < 4 and self.selectedPlayIndex then
                if checkHover(380, 240, 200, 30) then
                    self:callPlay()
                    return
                end
            end
            
            for ci = 1, GameStateData.maxConsumables do
                local cx = 610 + (ci - 1) * 58
                local cy = 8 + 20
                if checkHover(cx, cy, 52, 42) and GameStateData.consumables[ci] then
                    local msg = GameStateData.useConsumable(ci)
                    SoundManager.playSFX("coin")
                    FxManager.addFloatingText(msg, 480, 250, 1, 0.84, 0, 1.3)
                    return
                end
            end

            local clickedCardIdx = nil
            for i, c in ipairs(DeckManager.hand) do
                if checkHover(c.xOffset - 45, c.yOffset - 60, 90, 140) then
                    clickedCardIdx = i
                    break
                end
            end
            
            if clickedCardIdx then
                if self.selectedPlayIndex == clickedCardIdx then
                    self:callPlay()
                else
                    self.selectedPlayIndex = clickedCardIdx
                    self.draggingCardIndex = clickedCardIdx
                    self.dragStartX = x
                    self.dragStartY = y
                    self.justSelectedThisClick = true
                    SoundManager.playSFX("click")
                end
            else
                self.selectedPlayIndex = nil
            end
        elseif button == 2 then
            if self.hoveredRosterPlayer then
                self.hoveredRosterPlayer.isFlipped = not self.hoveredRosterPlayer.isFlipped
                SoundManager.playSFX("click")
            end
        end
    end
end

function StateGame:mousereleased(x, y, button, istouch, presses)
    if button == 1 and self.draggingCardIndex then
        local dragDist = 0
        if self.dragStartX and self.dragStartY then
            local dx = x - self.dragStartX
            local dy = y - self.dragStartY
            dragDist = math.sqrt(dx*dx + dy*dy)
        end
        
        if y < 280 then
            self.selectedPlayIndex = self.draggingCardIndex
            self:callPlay()
        elseif dragDist < 8 and not self.justSelectedThisClick and self.draggingCardIndex == self.selectedPlayIndex then
            self:callPlay()
        end
        self.draggingCardIndex = nil
        self.justSelectedThisClick = false
    end
end

function StateGame:callPlay()
    if self.selectedPlayIndex and #DeckManager.hand > 0 and not ScoringEvaluator.active then
        local playCard = table.remove(DeckManager.hand, self.selectedPlayIndex)
        self.selectedPlayIndex = nil
        
        if SettingsData.rpoMinigameEnabled and playCard.type == "Play Action" then
            RPOMinigame.start(function(result)
                if result == "PERFECT" then
                    playCard.baseChips = playCard.baseChips + 5
                    playCard.baseMult = playCard.baseMult * 1.5
                    FxManager.addFloatingText("PERFECT READ! +5 YDS x1.5 MTM", 480, 200, 0.2, 0.8, 0.3, 1.8)
                    SoundManager.playSFX("touchdown")
                elseif result == "GOOD" then
                    FxManager.addFloatingText("GOOD READ!", 480, 200, 0.9, 0.8, 0.2, 1.2)
                else
                    playCard.baseChips = playCard.baseChips - 8
                    FxManager.addFloatingText("MISSED READ! SACKED!", 480, 200, 1.0, 0.2, 0.2, 1.8)
                    SoundManager.playSFX("tackle")
                end
                self:executePlaycard(playCard)
            end)
        else
            self:executePlaycard(playCard)
        end
    end
end

function StateGame:executePlaycard(playCard)
    if _G.triggerScreenShake then _G.triggerScreenShake(14, 0.25) end
    FxManager.addBurstParticles(480, 320, 35, 0.0, 0.76, 1.0)
    SoundManager.playSFX("tackle")
    
    if playCard.type == "Kick" then
        GameStateData.kickFieldGoal()
    elseif playCard.type == "Punt" then
        GameStateData.puntBall()
    else
        local ScoringEvaluator = require("src.engine.scoring_evaluator")
        local risk, riskType = ScoringEvaluator.calculateTurnoverRisk(playCard, GameStateData)
        local isTurnover = false
        if risk > 0 and math.random(1, 100) <= risk then
            isTurnover = true
        end
        
        GameStateData.executePlay(playCard, isTurnover, riskType)
        DeckManager.discardPlay(playCard)
        DeckManager.fillHand()
    end
end

function StateGame:dealSpecialTeams(mode)
    local DeckManager = require("src.engine.deck_manager")
    while #DeckManager.hand > 0 do
        table.insert(DeckManager.discardPile, table.remove(DeckManager.hand))
    end
    
    local PlayCard = require("src.entities.play_card")
    if mode == "Kick" then
        local fgCard = PlayCard.new("Field Goal Kick", "Kick", 0, 0)
        local fakeFgCard = PlayCard.new("Fake Field Goal", "Play Action", 12, 1.5)
        table.insert(DeckManager.hand, fgCard)
        table.insert(DeckManager.hand, fakeFgCard)
    elseif mode == "Punt" then
        local puntCard = PlayCard.new("Punt Ball", "Punt", 0, 0)
        local fakePuntCard = PlayCard.new("Fake Punt", "Run", 8, 1.2)
        table.insert(DeckManager.hand, puntCard)
        table.insert(DeckManager.hand, fakePuntCard)
    end
    
    self.selectedPlayIndex = nil
end

function StateGame:keypressed(key)
    if RPOMinigame.active then
        RPOMinigame.keypressed(key)
        return
    end

    if self.showPlaybookModal then
        if key == "escape" or key == "space" or key == "return" or key == "enter" then
            self.showPlaybookModal = false
            SoundManager.playSFX("click")
        end
        return
    end

    if key == "escape" then
        self.paused = not self.paused
        return
    end
    
    if self.paused then
        if key == "r" then
            self.paused = false
            GameStateData.init(GameStateData.config)
            DeckManager.drawHand()
        elseif key == "q" then
            self.paused = false
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
        end
        return
    end

    if GameStateData.status == "PLAYING" and not ScoringEvaluator.active then
        if key == "1" and GameStateData.consumables[1] then
            local msg = GameStateData.useConsumable(1)
            SoundManager.playSFX("coin")
            FxManager.addFloatingText(msg, 480, 250, 1, 0.84, 0, 1.3)
        elseif key == "2" and GameStateData.consumables[2] then
            local msg = GameStateData.useConsumable(2)
            SoundManager.playSFX("coin")
            FxManager.addFloatingText(msg, 480, 250, 1, 0.84, 0, 1.3)
        elseif key == "left" or key == "a" then
            if self.selectedPlayIndex then
                self.selectedPlayIndex = math.max(1, self.selectedPlayIndex - 1)
            else
                self.selectedPlayIndex = #DeckManager.hand
            end
            SoundManager.playSFX("click")
        elseif key == "right" or key == "d" then
            if self.selectedPlayIndex then
                self.selectedPlayIndex = math.min(#DeckManager.hand, self.selectedPlayIndex + 1)
            else
                self.selectedPlayIndex = 1
            end
            SoundManager.playSFX("click")
        elseif key == "return" or key == "space" or key == "enter" then
            self:callPlay()
        elseif key == "q" then
            if self.selectedPlayIndex and GameStateData.audiblesRemaining > 0 and #DeckManager.hand > 0 then
                SoundManager.playSFX("click")
                local playCard = table.remove(DeckManager.hand, self.selectedPlayIndex)
                DeckManager.discardPlay(playCard)
                GameStateData.audiblesRemaining = GameStateData.audiblesRemaining - 1
                DeckManager.fillHand()
                self.selectedPlayIndex = nil
                FxManager.addFloatingText("AUDIBLE!", 480, 260, 1, 0.84, 0, 1.5)
            end
        end
    elseif key == "space" and (GameStateData.status == "TOUCHDOWN" or GameStateData.status == "GAME_WON") then
         local StateShop = require("src.states.state_shop")
         StateManager.switch(StateShop)
    elseif key == "r" and GameStateData.status == "TURNOVER" then
        if _G.GAME_MODE == "roguelite" then
            local MyPlayerProfile = require("src.data.myplayer_profile")
            MyPlayerProfile.seasonsPlayed = MyPlayerProfile.seasonsPlayed + 1
            if MyPlayerProfile.seasonsPlayed >= MyPlayerProfile.maxSeasons then
                MyPlayerProfile.retire()
            else
                MyPlayerProfile.save()
            end
        end
        SaveManager.clearActiveRun()
        GameStateData.init(GameStateData.config)
        DeckManager.drawHand()
    end
end

return StateGame
