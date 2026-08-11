-- src/states/state_hall_of_fame.lua
local StateManager = require("src.states.state_manager")
local SaveManager = require("src.engine.save_manager")
local SoundManager = require("src.engine.sound_manager")

local StateHallOfFame = {}

function StateHallOfFame:enter()
    self.selectedTab = 1
end

function StateHallOfFame:draw()
    love.graphics.setColor(0.08, 0.1, 0.14)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Main Container
    love.graphics.setColor(0.12, 0.15, 0.2)
    love.graphics.rectangle("fill", 60, 40, 840, 460, 10, 10)
    love.graphics.setColor(1.0, 0.84, 0.0, 0.9)
    love.graphics.setLineWidth(2.5)
    love.graphics.rectangle("line", 60, 40, 840, 460, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- Header Title
    love.graphics.setColor(1.0, 0.84, 0.0)
    love.graphics.printf("🏆 CHAIN GAIN HALL OF FAME 🏆", 60, 55, 840, "center", 0, 1.6, 1.6)
    
    -- Stats & Rings Overview Box
    love.graphics.setColor(0.16, 0.2, 0.28, 1)
    love.graphics.rectangle("fill", 90, 110, 780, 100, 8, 8)
    love.graphics.setColor(0.0, 0.76, 1.0, 0.8)
    love.graphics.rectangle("line", 90, 110, 780, 100, 8, 8)
    
    local rings = (SaveManager.data and SaveManager.data.superBowlRings) or 0
    local tdCount = (SaveManager.data and SaveManager.data.touchdownCount) or 0
    local highYards = (SaveManager.data and SaveManager.data.highYards) or 0
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("SUPER BOWL RINGS: " .. rings .. " 💍", 120, 130, 0, 1.2, 1.2)
    love.graphics.print("CAREER TOUCHDOWNS: " .. tdCount .. " 🏈", 120, 165, 0, 1.1, 1.1)
    love.graphics.print("LONGEST SINGLE PLAY: " .. highYards .. " YARDS", 480, 130, 0, 1.1, 1.1)
    love.graphics.print("LEGEND STATUS: " .. (rings >= 5 and "DYNASTY GOAT" or (rings >= 1 and "CHAMPION" or "CONTENDER")), 480, 165, 0, 1.1, 1.1)
    
    -- Trophy Cabinet Grid
    love.graphics.setColor(0.14, 0.17, 0.22, 1)
    love.graphics.rectangle("fill", 90, 230, 780, 210, 8, 8)
    
    local trophies = {
        { name = "ROOKIE BOWL", desc = "Won First Game", unlocked = tdCount >= 1 },
        { name = "LOMBARDI TROPHY", desc = "Super Bowl Champ", unlocked = rings >= 1 },
        { name = "DYNASTY RING", desc = "3x Super Bowls", unlocked = rings >= 3 },
        { name = "CENTURY CLUB", desc = "50+ Yd Single Play", unlocked = highYards >= 50 }
    }
    
    for i, tr in ipairs(trophies) do
        local tx = 110 + (i - 1) * 185
        local ty = 250
        love.graphics.setColor(tr.unlocked and {0.2, 0.25, 0.35} or {0.1, 0.12, 0.16})
        love.graphics.rectangle("fill", tx, ty, 165, 170, 6, 6)
        love.graphics.setColor(tr.unlocked and {1.0, 0.84, 0.0} or {0.4, 0.4, 0.4})
        love.graphics.rectangle("line", tx, ty, 165, 170, 6, 6)
        
        love.graphics.printf(tr.unlocked and "🏆" or "🔒", tx, ty + 20, 165, "center", 0, 2.5, 2.5)
        love.graphics.setColor(tr.unlocked and {1, 1, 1} or {0.5, 0.5, 0.5})
        love.graphics.printf(tr.name, tx + 5, ty + 105, 155, "center", 0, 0.95, 0.95)
        love.graphics.setColor(tr.unlocked and {0.0, 0.76, 1.0} or {0.4, 0.4, 0.4})
        love.graphics.printf(tr.desc, tx + 5, ty + 130, 155, "center", 0, 0.75, 0.75)
    end
    
    -- Back Button
    local mx, my = love.mouse.getPosition()
    local hoverBack = (mx >= 90 and mx <= 200 and my >= 452 and my <= 486)
    love.graphics.setColor(hoverBack and {0.9, 0.3, 0.3} or {0.7, 0.2, 0.2})
    love.graphics.rectangle("fill", 90, 452, 110, 34, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("BACK", 90, 461, 110, "center")
end

function StateHallOfFame:mousepressed(x, y, button)
    if button == 1 then
        if x >= 90 and x <= 200 and y >= 452 and y <= 486 then
            SoundManager.playSFX("click")
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
        end
    end
end

function StateHallOfFame:keypressed(key)
    if key == "escape" or key == "space" or key == "return" then
        SoundManager.playSFX("click")
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    end
end

return StateHallOfFame
