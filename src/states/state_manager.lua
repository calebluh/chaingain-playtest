-- src/states/state_manager.lua
local StateManager = {}

function StateManager.init(initialState)
    StateManager.activeState = initialState
    if StateManager.activeState and StateManager.activeState.enter then
        StateManager.activeState:enter()
    end
end

function StateManager.switch(newState)
    if StateManager.activeState and StateManager.activeState.exit then
        StateManager.activeState:exit()
    end
    
    StateManager.activeState = newState
    
    if StateManager.activeState and StateManager.activeState.enter then
        StateManager.activeState:enter()
    end
end

function StateManager.update(dt)
    if StateManager.activeState and StateManager.activeState.update then
        StateManager.activeState:update(dt)
    end
end

function StateManager.draw()
    if StateManager.activeState and StateManager.activeState.draw then
        StateManager.activeState:draw()
    end
end

function StateManager.keypressed(key)
    if StateManager.activeState and StateManager.activeState.keypressed then
        StateManager.activeState:keypressed(key)
    end
end

function StateManager.mousepressed(x, y, button, istouch, presses)
    if StateManager.activeState and StateManager.activeState.mousepressed then
        StateManager.activeState:mousepressed(x, y, button, istouch, presses)
    end
end

function StateManager.mousereleased(x, y, button, istouch, presses)
    if StateManager.activeState and StateManager.activeState.mousereleased then
        StateManager.activeState:mousereleased(x, y, button, istouch, presses)
    end
end

function StateManager.wheelmoved(x, y)
    if StateManager.activeState and StateManager.activeState.wheelmoved then
        StateManager.activeState:wheelmoved(x, y)
    end
end

return StateManager
