package.path = package.path .. ';F:/Projects/ChainGain/?.lua;F:/Projects/ChainGain/src/?.lua;'

local StateManager = require('src.states.state_manager')
local StateSettings = require('src.states.state_settings')

function love.load()
    print('state_settings loaded:', tostring(StateSettings and true), 'tab=', tostring(StateSettings.activeTab))
    StateManager.init(StateSettings)
    print('state_manager active:', tostring(StateManager.activeState and StateManager.activeState.__name or 'none'))
    local StateMenu = require('src.states.state_menu')
    StateManager.switch(StateMenu)
    print('switched_to_menu:', tostring(StateManager.activeState and StateManager.activeState.__name or 'none'))
    love.event.quit()
end

function love.update(dt)
end

function love.draw()
end
