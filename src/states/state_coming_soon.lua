-- src/states/state_coming_soon.lua
local StateManager = require("src.states.state_manager")

local StateComingSoon = {}

function StateComingSoon:enter()
end

function StateComingSoon:exit()
end

function StateComingSoon:update(dt)
end

function StateComingSoon:draw()
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.print("FEATURE COMING SOON", 480 - 150, 250, 0, 1.5, 1.5)
    
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("Press ESC to return to the Main Menu", 480 - 180, 300, 0, 1.2, 1.2)
end

function StateComingSoon:keypressed(key)
    if key == "escape" then
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    end
end

return StateComingSoon
