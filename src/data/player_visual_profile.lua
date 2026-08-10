-- src/data/player_visual_profile.lua
-- Data model for pixel football character customization.
-- Used by field_animator.lua drawRetroPlayer() and asset_manager.lua drawPlayerPortrait().

local PlayerVisualProfile = {}

-- ─── Default Profile ────────────────────────────────────────────
PlayerVisualProfile.archetype = "stocky"    -- "lean", "stocky", "heavy"
PlayerVisualProfile.skinTone = 3            -- Index into skinTones palette (1-8)
PlayerVisualProfile.eyeBlack = "clean"      -- "clean", "single_bar", "warpaint", "cross"

-- Helmet
PlayerVisualProfile.helmetStyle = "speedflex"  -- "vintage", "classic_2bar", "speedflex", "cage"
PlayerVisualProfile.shellColor = {0.07, 0.13, 0.27}
PlayerVisualProfile.maskColor = {0.75, 0.75, 0.75}
PlayerVisualProfile.visor = "clear"         -- "clear", "dark", "gold_mirror", "iridescent"
PlayerVisualProfile.stripeColor = {1.0, 1.0, 1.0}

-- Jersey
PlayerVisualProfile.jerseyCut = "standard"  -- "standard", "cropped", "sleeveless"
PlayerVisualProfile.primaryColor = {0.13, 0.34, 0.13}
PlayerVisualProfile.secondaryColor = {1.0, 1.0, 1.0}
PlayerVisualProfile.jerseyPattern = "solid" -- "solid", "shoulder_stripes", "sleeve_cuffs", "camo_panels"
PlayerVisualProfile.jerseyNumber = 88
PlayerVisualProfile.numberFont = "classic_block" -- "classic_block", "modern_apex", "bold_outline"

-- Accessories
PlayerVisualProfile.armGear = "none"        -- "none", "turf_tape", "elbow_sleeve", "wristband", "full_sleeve"
PlayerVisualProfile.armGearColor = {1.0, 1.0, 1.0}
PlayerVisualProfile.handGear = "receiver"   -- "none", "receiver", "lineman"
PlayerVisualProfile.handGearColor = {1.0, 1.0, 1.0}
PlayerVisualProfile.cleats = "low"          -- "low", "mid", "high"
PlayerVisualProfile.cleatsColor = {0.1, 0.1, 0.1}

-- ─── Palette Data ───────────────────────────────────────────────
PlayerVisualProfile.skinTones = {
    {1.00, 0.87, 0.73},  -- 1: Light
    {0.96, 0.80, 0.64},  -- 2: Fair
    {0.85, 0.65, 0.45},  -- 3: Medium
    {0.72, 0.52, 0.34},  -- 4: Tan
    {0.60, 0.40, 0.24},  -- 5: Brown
    {0.45, 0.28, 0.16},  -- 6: Dark Brown
    {0.33, 0.20, 0.12},  -- 7: Deep
    {0.22, 0.14, 0.09},  -- 8: Ebony
}

PlayerVisualProfile.colorPalette = {
    {1.0, 1.0, 1.0},      -- White
    {0.1, 0.1, 0.1},      -- Black
    {0.07, 0.13, 0.27},   -- Navy
    {0.13, 0.34, 0.13},   -- Dark Green
    {0.65, 0.1, 0.15},    -- Crimson
    {1.0, 0.84, 0.0},     -- Gold
    {0.0, 0.58, 1.0},     -- Royal Blue
    {1.0, 0.4, 0.0},      -- Orange
    {0.4, 0.0, 0.6},      -- Purple
    {0.0, 0.6, 0.6},      -- Teal
    {0.75, 0.75, 0.75},   -- Silver
    {0.55, 0.0, 0.0},     -- Maroon
}

PlayerVisualProfile.archetypeOptions = { "lean", "stocky", "heavy" }
PlayerVisualProfile.eyeBlackOptions = { "clean", "single_bar", "warpaint", "cross" }
PlayerVisualProfile.helmetOptions = { "vintage", "classic_2bar", "speedflex", "cage" }
PlayerVisualProfile.visorOptions = { "clear", "dark", "gold_mirror", "iridescent" }
PlayerVisualProfile.jerseyCutOptions = { "standard", "cropped", "sleeveless" }
PlayerVisualProfile.jerseyPatternOptions = { "solid", "shoulder_stripes", "sleeve_cuffs", "camo_panels" }
PlayerVisualProfile.numberFontOptions = { "classic_block", "modern_apex", "bold_outline" }
PlayerVisualProfile.armGearOptions = { "none", "turf_tape", "elbow_sleeve", "wristband", "full_sleeve" }
PlayerVisualProfile.handGearOptions = { "none", "receiver", "lineman" }
PlayerVisualProfile.cleatsOptions = { "low", "mid", "high" }

-- ─── Helpers ────────────────────────────────────────────────────
function PlayerVisualProfile.getSkinColor()
    return PlayerVisualProfile.skinTones[PlayerVisualProfile.skinTone] or PlayerVisualProfile.skinTones[3]
end

function PlayerVisualProfile.getVisorColor()
    local v = PlayerVisualProfile.visor
    if v == "dark" then return {0.08, 0.08, 0.08, 0.95}
    elseif v == "gold_mirror" then return {1.0, 0.8, 0.0, 0.85}
    elseif v == "iridescent" then
        local t = love.timer.getTime()
        local r = 0.5 + 0.5 * math.sin(t * 2)
        local g = 0.5 + 0.5 * math.sin(t * 2 + 2.1)
        local b = 0.5 + 0.5 * math.sin(t * 2 + 4.2)
        return {r, g, b, 0.8}
    else
        return {0.7, 0.85, 1.0, 0.5} -- Clear
    end
end

function PlayerVisualProfile.getArchetypeScale()
    local a = PlayerVisualProfile.archetype
    if a == "lean" then return { torsoW = 6, torsoH = 9, legW = 2, shoulderW = 0 }
    elseif a == "heavy" then return { torsoW = 10, torsoH = 11, legW = 4, shoulderW = 3 }
    else return { torsoW = 8, torsoH = 10, legW = 3, shoulderW = 1 } -- stocky (default)
    end
end

function PlayerVisualProfile.randomize()
    PlayerVisualProfile.archetype = PlayerVisualProfile.archetypeOptions[math.random(#PlayerVisualProfile.archetypeOptions)]
    PlayerVisualProfile.skinTone = math.random(1, #PlayerVisualProfile.skinTones)
    PlayerVisualProfile.eyeBlack = PlayerVisualProfile.eyeBlackOptions[math.random(#PlayerVisualProfile.eyeBlackOptions)]
    PlayerVisualProfile.helmetStyle = PlayerVisualProfile.helmetOptions[math.random(#PlayerVisualProfile.helmetOptions)]
    PlayerVisualProfile.shellColor = PlayerVisualProfile.colorPalette[math.random(#PlayerVisualProfile.colorPalette)]
    PlayerVisualProfile.maskColor = PlayerVisualProfile.colorPalette[math.random(#PlayerVisualProfile.colorPalette)]
    PlayerVisualProfile.visor = PlayerVisualProfile.visorOptions[math.random(#PlayerVisualProfile.visorOptions)]
    PlayerVisualProfile.stripeColor = PlayerVisualProfile.colorPalette[math.random(#PlayerVisualProfile.colorPalette)]
    PlayerVisualProfile.jerseyCut = PlayerVisualProfile.jerseyCutOptions[math.random(#PlayerVisualProfile.jerseyCutOptions)]
    PlayerVisualProfile.primaryColor = PlayerVisualProfile.colorPalette[math.random(#PlayerVisualProfile.colorPalette)]
    PlayerVisualProfile.secondaryColor = PlayerVisualProfile.colorPalette[math.random(#PlayerVisualProfile.colorPalette)]
    PlayerVisualProfile.jerseyPattern = PlayerVisualProfile.jerseyPatternOptions[math.random(#PlayerVisualProfile.jerseyPatternOptions)]
    PlayerVisualProfile.jerseyNumber = math.random(0, 99)
    PlayerVisualProfile.numberFont = PlayerVisualProfile.numberFontOptions[math.random(#PlayerVisualProfile.numberFontOptions)]
    PlayerVisualProfile.armGear = PlayerVisualProfile.armGearOptions[math.random(#PlayerVisualProfile.armGearOptions)]
    PlayerVisualProfile.handGear = PlayerVisualProfile.handGearOptions[math.random(#PlayerVisualProfile.handGearOptions)]
    PlayerVisualProfile.cleats = PlayerVisualProfile.cleatsOptions[math.random(#PlayerVisualProfile.cleatsOptions)]
end

function PlayerVisualProfile.save()
    -- Serialization handled by SaveManager
end

return PlayerVisualProfile
