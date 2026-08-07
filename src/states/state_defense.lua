-- src/states/state_defense.lua
local GameStateData = require("src.engine.game_state")
local SoundManager = require("src.engine.sound_manager")
local FxManager = require("src.engine.fx_manager")
local StateManager = require("src.states.state_manager")

local StateDefense = {}

StateDefense.previousYardLine = 50
StateDefense.previousDown = 1
StateDefense.previousDistance = 10
StateDefense.turnoverType = "INT"

local C_SLATE_CONTAINER = {0.129, 0.149, 0.192}
local C_BORDER_NORMAL = {0.27, 0.31, 0.39}
local C_NEON_BLUE = {0.0, 0.76, 1.0}
local C_NEON_AMBER = {1.0, 0.6, 0.0}
local C_NEON_GREEN = {0.18, 0.8, 0.44}

local opponentPlays = {
    {
        formation = "Heavy I-Formation",
        desc = "Opponent lining up in Heavy I-Form...",
        hint = "Matches physical, inside ground attacks.",
        correct = "RUN STUFF",
        winResult = "RUN STUFFED! You forced a fumble and recovered the ball!",
        loseResult = "MISSED TACKLE! They broke outside for a 15-yard gain."
    },
    {
        formation = "Shotgun Spread",
        desc = "Opponent lining up in Shotgun Spread...",
        hint = "Spread set. Air attack likely.",
        correct = "COVER 3 ZONE",
        winResult = "INTERCEPTION! Your DB made a spectacular diving pick down the sideline!",
        loseResult = "BURNT COVERAGE! They scored a touchdown on a deep post route."
    },
    {
        formation = "Empty Backfield",
        desc = "Opponent lining up in Empty Set...",
        hint = "No protection helper. Quick dropback or slow screen.",
        correct = "BLITZ",
        winResult = "SACK! Your blitzing linebacker slammed the QB for a 10-yard loss!",
        loseResult = "QUICK RELEASE! The QB found the open hot route for a first down."
    }
}

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

function StateDefense:enter()
    self.activePlay = opponentPlays[math.random(#opponentPlays)]
    self.selectedChoice = nil
    self.resultText = nil
    self.resultStatus = nil
    
    SoundManager.playSFX("whistle")
    if _G.triggerScreenShake then _G.triggerScreenShake(15, 0.4) end
end

function StateDefense:update(dt)
    -- Nothing dynamic needed
end

function StateDefense:draw()
    -- Draw background
    love.graphics.clear(0.08, 0.1, 0.12)
    
    -- Draw neon top header
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 20, 20, 920, 70, 8, 8)
    love.graphics.setColor(0.12, 0.08, 0.1)
    love.graphics.rectangle("fill", 20, 20, 920, 70, 8, 8)
    love.graphics.setLineWidth(1)
    
    local titleText = string.format("TURNOVER: %s COMMITTED!  |  DEFENSIVE STAND!", self.turnoverType)
    drawShadowText(titleText, 20, 42, 1.0, 0.2, 0.2, 1.4, "center", 920)
    
    if not self.resultText then
        -- Draw opposing telegraphed play marquee
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", 40, 110, 880, 110, 6, 6)
        love.graphics.setColor(C_BORDER_NORMAL)
        love.graphics.rectangle("line", 40, 110, 880, 110, 6, 6)
        
        drawShadowText(self.activePlay.desc, 60, 130, 1.0, 0.84, 0.0, 1.25)
        drawShadowText("FORMATION INTEL: " .. self.activePlay.hint, 60, 170, 0.7, 0.8, 0.9, 1.0)
        drawShadowText("Choose a Defensive Card to counter their scheme and win your drive back!", 60, 195, 0.5, 0.7, 1.0, 0.85)
        
        -- Draw the 3 defensive cards
        local choices = {
            { name = "BLITZ", color = C_NEON_AMBER, desc = "Heavy rush. Counters slow Empty Sets / Play Actions.", x = 100 },
            { name = "COVER 3 ZONE", color = C_NEON_BLUE, desc = "Deep double-bracket. Counters Spread / Pass plays.", x = 370 },
            { name = "RUN STUFF", color = C_NEON_GREEN, desc = "Physical front. Counters I-Form / Ground plays.", x = 640 }
        }
        
        for _, c in ipairs(choices) do
            local hover = checkHover(c.x, 240, 220, 180)
            
            -- Card base
            love.graphics.setColor(hover and {c.color[1]*0.25, c.color[2]*0.25, c.color[3]*0.25} or {0.11, 0.13, 0.16})
            love.graphics.rectangle("fill", c.x, 240, 220, 180, 8, 8)
            
            -- Border
            love.graphics.setColor(hover and c.color or C_BORDER_NORMAL)
            love.graphics.setLineWidth(hover and 3 or 2)
            love.graphics.rectangle("line", c.x, 240, 220, 180, 8, 8)
            love.graphics.setLineWidth(1)
            
            -- Title
            drawShadowText(c.name, c.x, 260, hover and 1 or 0.85, hover and 1 or 0.85, hover and 1 or 0.85, 1.15, "center", 220)
            
            -- Description
            love.graphics.setColor(0.7, 0.75, 0.8)
            love.graphics.printf(c.desc, c.x + 15, 305, 190, "center", 0, 0.85, 0.85)
            
            love.graphics.setColor(c.color)
            love.graphics.printf("[SELECT]", c.x, 385, 220, "center")
        end
    else
        -- Draw results marquee
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", 100, 140, 760, 240, 10, 10)
        
        local outlineColor = (self.resultStatus == "win") and C_NEON_GREEN or {1.0, 0.2, 0.2}
        love.graphics.setColor(outlineColor)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", 100, 140, 760, 240, 10, 10)
        love.graphics.setLineWidth(1)
        
        local headerText = (self.resultStatus == "win") and "DEFENSIVE STAND SUCCEEDED! (DRIVE RECOVERED)" or "DEFENSIVE STAND FAILED! (TURNOVER CONFIRMED)"
        local hr, hg, hb = unpack(outlineColor)
        drawShadowText(headerText, 100, 175, hr, hg, hb, 1.25, "center", 760)
        
        drawShadowText(self.resultText, 120, 230, 0.95, 0.95, 0.95, 1.05, "center", 720)
        
        local rewardsText = (self.resultStatus == "win") and "Possession restored at original yard line! Gained +1 Audible!" or "Opponent completes drive. Possession consumed."
        drawShadowText(rewardsText, 120, 275, 0.7, 0.75, 0.8, 0.9, "center", 720)
        
        -- Prompt to continue
        local pulse = 0.6 + 0.4 * math.sin(love.timer.getTime() * 8)
        drawShadowText("PRESS [SPACE] OR CLICK ANYWHERE TO CONTINUE", 100, 335, pulse, pulse, pulse, 1.0, "center", 760)
    end
end

function StateDefense:mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        if self.resultText then
            self:continueToGame()
            return
        end
        
        local choices = {
            { name = "BLITZ", x = 100 },
            { name = "COVER 3 ZONE", x = 370 },
            { name = "RUN STUFF", x = 640 }
        }
        
        for _, c in ipairs(choices) do
            if checkHover(c.x, 240, 220, 180) then
                self:resolveChoice(c.name)
                return
            end
        end
    end
end

function StateDefense:keypressed(key)
    if key == "space" or key == "return" then
        if self.resultText then
            self:continueToGame()
        end
    end
end

function StateDefense:resolveChoice(choiceName)
    self.selectedChoice = choiceName
    if choiceName == self.activePlay.correct then
        self.resultStatus = "win"
        self.resultText = self.activePlay.winResult
        SoundManager.playSFX("chime")
        if _G.triggerScreenShake then _G.triggerScreenShake(15, 0.4) end
        
        -- Refund Possession: Restore previous stats
        GameStateData.yardLine = self.previousYardLine
        GameStateData.down = 1
        GameStateData.distance = 10
        GameStateData.status = "PLAYING"
        GameStateData.audibles = (GameStateData.audibles or 0) + 1
    else
        self.resultStatus = "lose"
        self.resultText = self.activePlay.loseResult
        SoundManager.playSFX("tackle")
        if _G.triggerScreenShake then _G.triggerScreenShake(20, 0.5) end
        
        -- Turnover Stands: Confirm loss
        if GameStateData.drivesRemaining <= 0 then
            GameStateData.status = "GAME_LOST"
        else
            GameStateData.status = "DRIVE_LOST"
        end
    end
end

function StateDefense:continueToGame()
    local StateGame = require("src.states.state_game")
    
    if self.resultStatus == "win" then
        -- Continue current drive
        local DeckManager = require("src.engine.deck_manager")
        DeckManager.drawHand()
    else
        -- Start new drive or game over screen if no drives remaining
        if GameStateData.status == "DRIVE_LOST" then
            -- Reset downs and markers for next round
            GameStateData.down = 1
            GameStateData.distance = 10
            GameStateData.yardLine = 25
            GameStateData.startDrive()
        end
    end
    
    StateManager.switch(StateGame)
end

return StateDefense
