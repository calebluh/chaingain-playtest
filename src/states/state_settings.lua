-- src/states/state_settings.lua
local PauseOverlay = require("src.ui.pause_overlay")
local StateManager = require("src.states.state_manager")
local StateMenu = require("src.states.state_menu")

local StateSettings = {}

function StateSettings:enter()
    PauseOverlay.viewMode = "SETTINGS"
    PauseOverlay.activeTab = 1
    StateManager.openOverlay(PauseOverlay)
end

function StateSettings:draw()
    -- Render state menu background if active, overlay draws on top
    local StateMenu = require("src.states.state_menu")
    StateMenu:draw()
end

function StateSettings:keypressed(key)
    PauseOverlay:keypressed(key)
end

function StateSettings:mousepressed(x, y, button)
    PauseOverlay:mousepressed(x, y, button)
end

return StateSettings
