-- src/states/state_manager.lua
local StateManager = {}

StateManager.activeState = nil
StateManager.overlay = nil

function StateManager.init(initialState)
    StateManager.activeState = initialState
    StateManager.overlay = nil
    if StateManager.activeState and StateManager.activeState.enter then
        StateManager.activeState:enter()
    end
end

function StateManager.switch(newState)
    StateManager.overlay = nil
    if StateManager.activeState and StateManager.activeState.exit then
        StateManager.activeState:exit()
    end
    
    StateManager.activeState = newState
    
    if StateManager.activeState and StateManager.activeState.enter then
        StateManager.activeState:enter()
    end
end

function StateManager.openOverlay(overlayObj)
    StateManager.overlay = overlayObj
    if StateManager.overlay and StateManager.overlay.enter then
        StateManager.overlay:enter()
    end
end

function StateManager.closeOverlay()
    if StateManager.overlay and StateManager.overlay.exit then
        StateManager.overlay:exit()
    end
    StateManager.overlay = nil
end

function StateManager.isOverlayOpen()
    return StateManager.overlay ~= nil
end

function StateManager.update(dt)
    if StateManager.overlay and StateManager.overlay.update then
        StateManager.overlay:update(dt)
    elseif StateManager.activeState and StateManager.activeState.update then
        StateManager.activeState:update(dt)
    end
end

function StateManager.draw()
    if StateManager.activeState and StateManager.activeState.draw then
        StateManager.activeState:draw()
    end
    if StateManager.overlay and StateManager.overlay.draw then
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        StateManager.overlay:draw()
    end
end

function StateManager.keypressed(key)
    if StateManager.overlay then
        if StateManager.overlay.keypressed then
            StateManager.overlay:keypressed(key)
        end
    else
        if StateManager.activeState and StateManager.activeState.keypressed then
            StateManager.activeState:keypressed(key)
        end
    end
end

function StateManager.textinput(t)
    if StateManager.overlay then
        if StateManager.overlay.textinput then
            StateManager.overlay:textinput(t)
        end
    else
        if StateManager.activeState and StateManager.activeState.textinput then
            StateManager.activeState:textinput(t)
        end
    end
end

function StateManager.mousepressed(x, y, button, istouch, presses)
    if StateManager.overlay then
        if StateManager.overlay.mousepressed then
            StateManager.overlay:mousepressed(x, y, button, istouch, presses)
        end
    else
        if StateManager.activeState and StateManager.activeState.mousepressed then
            StateManager.activeState:mousepressed(x, y, button, istouch, presses)
        end
    end
end

function StateManager.mousereleased(x, y, button, istouch, presses)
    if StateManager.overlay then
        if StateManager.overlay.mousereleased then
            StateManager.overlay:mousereleased(x, y, button, istouch, presses)
        end
    else
        if StateManager.activeState and StateManager.activeState.mousereleased then
            StateManager.activeState:mousereleased(x, y, button, istouch, presses)
        end
    end
end

function StateManager.wheelmoved(x, y)
    if StateManager.overlay then
        if StateManager.overlay.wheelmoved then
            StateManager.overlay:wheelmoved(x, y)
        end
    else
        if StateManager.activeState and StateManager.activeState.wheelmoved then
            StateManager.activeState:wheelmoved(x, y)
        end
    end
end

return StateManager
