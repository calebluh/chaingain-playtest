-- src/states/state_loadout.lua
local StateManager = require("src.states.state_manager")
local GameStateData = require("src.engine.game_state")
local DeckManager = require("src.engine.deck_manager")
local PlayerCard = require("src.entities.player_card")

local StateLoadout = {}

local C_SLATE = {0.14, 0.19, 0.22}
local C_OUTLINE = {0.35, 0.41, 0.45}
local C_BLUE = {0.0, 0.58, 1.0}
local C_AMBER = {1.0, 0.6, 0.0}
local C_RED = {1.0, 0.3, 0.3}

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
    
    if r then
        love.graphics.setColor(r, g, b, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    if align and limit then
        love.graphics.printf(text, x, y, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x, y, 0, scale, scale)
    end
end

local function drawPillButton(btn)
    local hover = checkHover(btn.x, btn.y, btn.w, btn.h)
    local drawX, drawY, drawW, drawH = btn.x, btn.y, btn.w, btn.h
    local txtScale = btn.txtScale or 1.1
    
    if hover then
        drawX = drawX - 2
        drawY = drawY - 2
        drawW = drawW + 4
        drawH = drawH + 4
        txtScale = txtScale + 0.05
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
    end
    
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", drawX, drawY + 4, drawW, drawH, 8, 8)
    love.graphics.setColor(btn.color)
    love.graphics.rectangle("fill", drawX, drawY, drawW, drawH, 8, 8)
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("fill", drawX, drawY, drawW, drawH * 0.4, 8, 8)
    
    drawShadowText(btn.name, drawX, drawY + (drawH/2) - 10, 1, 1, 1, txtScale, "center", drawW)
end

function StateLoadout:enter()
    self.step = 1 -- 1 = Formation, 2 = Stake
    self.hoveredFormation = nil
    self.selectedFormation = nil
    
    self.formations = {
        { id = "air_raid", name = "10 Spread", desc = "4 WR, 0 TE. Pass-heavy playbook. Starts with Elite Slot WR.", color = {0.2, 0.4, 0.8} },
        { id = "ground_pound", name = "22 Heavy", desc = "2 TE, 2 RB. Run-heavy playbook. Starts with Power Back and Blocking TE.", color = {0.8, 0.2, 0.2} },
        { id = "west_coast", name = "12 Personnel", desc = "2 TE, 1 RB. Balanced playbook. Starts with All-Pro QB.", color = {0.2, 0.8, 0.2} }
    }
    
    self.stakes = {
        { id = "rookie", name = "Rookie", desc = "Standard scoring targets. White Stake.", color = {0.9, 0.9, 0.9} },
        { id = "pro", name = "Pro", desc = "-1 Audible per drive. Red Stake.", color = {0.8, 0.2, 0.2} },
        { id = "all_pro", name = "All-Pro", desc = "Defensive targets scale 25% faster. Gold Stake.", color = {1.0, 0.84, 0.0} },
        { id = "hof", name = "Hall of Fame", desc = "Boss Defenses have dual debuffs. Obsidian Stake.", color = {0.2, 0.2, 0.2} }
    }
    
    self.backBtn = { id = "BACK", name = "BACK", color = C_AMBER, x = 40, y = 470, w = 120, h = 40 }
    self.playBtn = { id = "PLAY", name = "PLAY", color = C_BLUE, x = 800, y = 470, w = 120, h = 40 }
end

function StateLoadout:exit()
end

function StateLoadout:update(dt)
    self.hoveredFormation = nil
    if self.step == 1 then
        for i, form in ipairs(self.formations) do
            local x = 80 + (i - 1) * 160
            if checkHover(x, 150, 140, 200) then
                self.hoveredFormation = form
            end
        end
    end
end

function StateLoadout:draw()
    -- Overlay Background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Main Modal Container
    love.graphics.setColor(C_OUTLINE)
    love.graphics.rectangle("fill", 37, 37, 886, 466, 14, 14)
    love.graphics.setColor(C_SLATE)
    love.graphics.rectangle("fill", 40, 40, 880, 460, 12, 12)
    
    if self.step == 1 then
        drawShadowText("SELECT FORMATION DECK", 40, 60, 1, 1, 1, 2, "center", 880)
        
        for i, form in ipairs(self.formations) do
            local x = 80 + (i - 1) * 160
            local y = 150
            
            if form == self.hoveredFormation then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle("line", x-2, y-2, 144, 204, 8, 8)
            end
            
            if form == self.selectedFormation then
                love.graphics.setColor(1, 0.84, 0, 1)
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", x-2, y-2, 144, 204, 8, 8)
                love.graphics.setLineWidth(1)
            end
            
            love.graphics.setColor(form.color)
            love.graphics.rectangle("fill", x, y, 140, 200, 8, 8)
            drawShadowText(form.name, x, y + 20, 1, 1, 1, 1.2, "center", 140)
        end
        
        -- Right Info Panel
        love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
        love.graphics.rectangle("fill", 600, 150, 280, 200, 8, 8)
        
        local activeForm = self.hoveredFormation or self.selectedFormation
        if activeForm then
            drawShadowText(activeForm.name, 610, 160, 1, 1, 1, 1.5)
            drawShadowText(activeForm.desc, 610, 200, 0.8, 0.8, 0.8, 1, "left", 260)
        else
            drawShadowText("Hover over a formation to view details.", 610, 220, 0.5, 0.5, 0.5, 1, "center", 260)
        end
        
    elseif self.step == 2 then
        drawShadowText("SELECT DIVISION STAKE", 40, 60, 1, 1, 1, 2, "center", 880)
        
        for i, stake in ipairs(self.stakes) do
            local x = 120 + (i - 1) * 180
            local y = 150
            local hover = checkHover(x, y, 140, 200)
            
            if hover then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle("line", x-2, y-2, 144, 204, 8, 8)
            end
            
            love.graphics.setColor(stake.color)
            love.graphics.rectangle("fill", x, y, 140, 200, 8, 8)
            drawShadowText(stake.name, x, y + 20, 1, 1, 1, 1.2, "center", 140)
            
            if hover then
                drawShadowText(stake.desc, x, y + 80, 1, 1, 1, 1, "center", 140)
            end
        end
    end
    
    drawPillButton(self.backBtn)
    if self.step == 1 and self.selectedFormation then
        self.playBtn.name = "NEXT"
        drawPillButton(self.playBtn)
    elseif self.step == 2 then
        self.playBtn.name = "PLAY"
        drawPillButton(self.playBtn)
    end
end

function StateLoadout:mousepressed(x, y, button)
    if button == 1 then
        if checkHover(self.backBtn.x, self.backBtn.y, self.backBtn.w, self.backBtn.h) then
            if self.step == 2 then
                self.step = 1
            else
                local StateMenu = require("src.states.state_menu")
                StateManager.switch(StateMenu)
            end
            return
        end
        
        if (self.step == 1 and self.selectedFormation) or self.step == 2 then
            if checkHover(self.playBtn.x, self.playBtn.y, self.playBtn.w, self.playBtn.h) then
                if self.step == 1 then
                    self.step = 2
                elseif self.step == 2 then
                    -- Launch Game (Need to pick stake, assuming default to rookie if none clicked directly)
                    local config = {
                        archetype = self.selectedFormation,
                        stake = "rookie" -- Fallback
                    }
                    GameStateData.init(config)
                    DeckManager.init(config.archetype)
                    DeckManager.drawHand()
                    local StateGame = require("src.states.state_game")
                    StateManager.switch(StateGame)
                end
                return
            end
        end
        
        if self.step == 1 then
            for i, form in ipairs(self.formations) do
                local fx = 80 + (i - 1) * 160
                if checkHover(fx, 150, 140, 200) then
                    self.selectedFormation = form
                end
            end
        elseif self.step == 2 then
            for i, stake in ipairs(self.stakes) do
                local sx = 120 + (i - 1) * 180
                if checkHover(sx, 150, 140, 200) then
                    local config = {
                        archetype = self.selectedFormation,
                        stake = stake.id
                    }
                    GameStateData.init(config)
                    DeckManager.init(config.archetype)
                    DeckManager.drawHand()
                    local StateGame = require("src.states.state_game")
                    StateManager.switch(StateGame)
                end
            end
        end
    end
end

function StateLoadout:keypressed(key)
    if key == "escape" then
        local SoundManager = require("src.engine.sound_manager")
        SoundManager.playSFX("click")
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    end
end

return StateLoadout
