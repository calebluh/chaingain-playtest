-- src/data/settings_data.lua
local SettingsData = {
    -- Gameplay
    stadiumPulseEnabled = true,
    pulseCounterScaling = true,
    gameSpeed = 1.0,
    autoEndDrive = true,
    
    -- Visuals & Impact
    impactFx = "FULL",         -- "FULL", "LOW", "OFF"
    weatherStains = true,
    turnoverSequence = true,
    reducedFlashing = false,
    
    -- Audio
    masterVolume = 0.8,
    sfxVolume = 1.0,
    musicVolume = 0.7,
    crowdVolume = 0.9,
    soundSoftener = false,
    
    -- Streamer & Content
    streamerMode = false,
    profanityFilter = true,
    hideUserTag = false
}

return SettingsData
