-- src/states/state_event.lua
local StateManager = require("src.engine.state_manager")
local SoundManager = require("src.engine.sound_manager")
local GameStateData = require("src.engine.game_state")
local FxManager = require("src.engine.fx_manager")
local DeckManager = require("src.engine.deck_manager")

local StateEvent = {}

local EVENTS = {
    {
        title = "Trade Deadline Offer",
        desc = "A rival team wants to trade for your starting QB.",
        optionA = { label = "Accept Trade: +$20 Cap Cash, lose QB", action = function()
            GameStateData.capCash = GameStateData.capCash + 20
            if GameStateData.rosterSlots.QB.cards[1] then
                GameStateData.rosterSlots.QB.cards[1] = nil
            end
            return "Trade Accepted! +$20 Cap Cash, QB traded away."
        end},
        optionB = { label = "Decline: Keep your QB", action = function()
            return "You hung up the phone. Chemistry improved!"
        end}
    },
    {
        title = "Press Conference Dilemma",
        desc = "The media is criticizing your playcalling after a bad drive.",
        optionA = { label = "Defend Team: Lose $5 Cap Cash", action = function()
            GameStateData.capCash = math.max(0, GameStateData.capCash - 5)
            return "You defended the team. Respect earned, but fined $5."
        end},
        optionB = { label = "Throw under bus: +1 Audible, Team Morale down", action = function()
            GameStateData.audiblesRemaining = GameStateData.audiblesRemaining + 1
            return "Threw the defense under the bus. +1 Audible gained."
        end}
    },
    {
        title = "Halftime Speech",
        desc = "The team is looking for a spark in the locker room.",
        optionA = { label = "Fiery Speech: +$5 Cap Cash", action = function()
            GameStateData.capCash = GameStateData.capCash + 5
            return "The team is fired up! +$5 Cap Cash."
        end},
        optionB = { label = "Tactical Review: +1 MTM next play", action = function()
            GameStateData.tempMultBoost = 1.0
            return "Brilliant tactical adjustment. +1.0 MTM on the first play."
        end}
    }
}

function StateEvent:enter()
    self.time = 0
    self.event = EVENTS[math.random(1, #EVENTS)]
    self.resultMessage = nil
end

local function checkHover(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
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

function StateEvent:draw()
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    local innerX, innerY, innerW, innerH = 180, 100, 600, 340
    love.graphics.setColor(0.1, 0.15, 0.2)
    love.graphics.rectangle("fill", innerX, innerY, innerW, innerH, 8, 8)
    
    love.graphics.setColor(0.0, 0.76, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", innerX, innerY, innerW, innerH, 8, 8)
    love.graphics.setLineWidth(1)
    
    drawShadowText("LOCKER ROOM EVENT", 480, 120, 1.0, 0.84, 0.0, 1.5, "center")
    drawShadowText(self.event.title, 480, 170, 1, 1, 1, 1.2, "center")
    drawShadowText(self.event.desc, 200, 210, 0.8, 0.8, 0.8, 1.0, "center", 560)
    
    if self.resultMessage then
        drawShadowText(self.resultMessage, 480, 260, 0.0, 1.0, 0.5, 1.1, "center")
        
        local isHover = checkHover(400, 350, 160, 40)
        love.graphics.setColor(isHover and {0.0, 0.76, 1.0} or {0.0, 0.58, 1.0})
        love.graphics.rectangle("fill", 400, 350, 160, 40, 6, 6)
        drawShadowText("CONTINUE", 480, 360, 1, 1, 1, 1.0, "center")
    else
        -- Option A
        local hoverA = checkHover(220, 280, 520, 40)
        love.graphics.setColor(hoverA and {0.2, 0.8, 0.2} or {0.1, 0.5, 0.1})
        love.graphics.rectangle("fill", 220, 280, 520, 40, 6, 6)
        drawShadowText(self.event.optionA.label, 480, 290, 1, 1, 1, 1.0, "center")
        
        -- Option B
        local hoverB = checkHover(220, 340, 520, 40)
        love.graphics.setColor(hoverB and {0.8, 0.2, 0.2} or {0.5, 0.1, 0.1})
        love.graphics.rectangle("fill", 220, 340, 520, 40, 6, 6)
        drawShadowText(self.event.optionB.label, 480, 350, 1, 1, 1, 1.0, "center")
    end
end

function StateEvent:mousepressed(x, y, button)
    if button ~= 1 then return end
    if self.resultMessage then
        if checkHover(400, 350, 160, 40) then
            SoundManager.playSFX("click")
            local StateGame = require("src.states.state_game")
            StateManager.switch(StateGame)
        end
        return
    end
    
    if checkHover(220, 280, 520, 40) then
        SoundManager.playSFX("coin")
        self.resultMessage = self.event.optionA.action()
    elseif checkHover(220, 340, 520, 40) then
        SoundManager.playSFX("click")
        self.resultMessage = self.event.optionB.action()
    end
end

function StateEvent:keypressed(key)
    if key == "escape" and self.resultMessage then
        local StateGame = require("src.states.state_game")
        StateManager.switch(StateGame)
    end
end

return StateEvent
