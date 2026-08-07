-- src/states/state_tutorial.lua
local StateManager = require("src.states.state_manager")
local AssetManager = require("src.engine.asset_manager")
local SoundManager = require("src.engine.sound_manager")

local StateTutorial = {}

local steps = {
    {
        title = "READING THE DEFENSE",
        desc = "Before calling a play, watch the Defensive Tells at the bottom of the screen. If the safeties split high, it's Cover 2 - attack them with a Run play!",
    },
    {
        title = "DRAG AND DROP",
        desc = "Click and drag cards from your hand onto the field. Velocity affects the physics, so toss them with some juice!",
    },
    {
        title = "FRONT OFFICE SHOP",
        desc = "After each drive, you'll visit the shop. Spend Cap Space to sign Free Agents, buy playbook expansions, or apply equipment badges to your players.",
    }
}

function StateTutorial:enter()
    self.step = 1
    self.time = 0
end

function StateTutorial:exit()
end

function StateTutorial:update(dt)
    self.time = self.time + dt
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

local function checkHover(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end

function StateTutorial:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    love.graphics.setColor(0.12, 0.15, 0.22, 0.4)
    for i = 0, 24 do
        local yPos = (i * 25 + self.time * 15) % 560
        love.graphics.line(0, yPos, 960, yPos)
    end
    
    local currentStep = steps[self.step]
    
    -- Window
    love.graphics.setColor(0.129, 0.149, 0.192)
    love.graphics.rectangle("fill", 230, 150, 500, 240, 8, 8)
    
    love.graphics.setColor(0.0, 0.76, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 230, 150, 500, 240, 8, 8)
    love.graphics.setLineWidth(1)
    
    drawShadowText("TUTORIAL (" .. self.step .. "/3)", 230, 170, 0.6, 0.6, 0.6, 1.0, "center", 500)
    drawShadowText(currentStep.title, 230, 210, 1, 0.84, 0, 1.5, "center", 500)
    
    drawShadowText(currentStep.desc, 250, 250, 1, 1, 1, 1.2, "center", 460)
    
    -- Next Button
    local btnX = 380
    local btnY = 330
    local btnW = 200
    local btnH = 40
    
    local isHover = checkHover(btnX, btnY, btnW, btnH)
    love.graphics.setColor(isHover and {0.0, 0.76, 1.0} or {0.0, 0.58, 1.0})
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
    
    local btnText = self.step < 3 and "NEXT" or "FINISH"
    drawShadowText(btnText, btnX, btnY + 12, 1, 1, 1, 1.2, "center", btnW)
end

function StateTutorial:mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        if checkHover(380, 330, 200, 40) then
            SoundManager.playSFX("click")
            if self.step < 3 then
                self.step = self.step + 1
            else
                local StateModeSelect = require("src.states.state_mode_select")
                StateManager.switch(StateModeSelect)
            end
        end
    end
end

function StateTutorial:keypressed(key)
    if key == "escape" then
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    end
end

return StateTutorial
