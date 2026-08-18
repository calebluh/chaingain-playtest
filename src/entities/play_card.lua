-- src/entities/play_card.lua

local PlayCard = {}
PlayCard.__index = PlayCard

function PlayCard.new(name, playType, baseYards, baseMomentum, level)
    local self = setmetatable({}, PlayCard)
    self.name = name or "Play"
    self.type = playType or "Run" -- "Run", "Short Pass", "Medium Pass", "Deep Pass", "Play Action", "Trick", "Field Goal"
    self.baseChips = baseYards or 4    -- Base Yards (kept as baseChips internally for engine compatibility)
    self.baseMult = baseMomentum or 1.5 -- Drive Momentum (kept as baseMult internally for engine compatibility)
    self.level = level or 1
    self.selected = false
    
    -- Physics / Visual Offset Variables
    self.xOffset = nil
    self.yOffset = nil
    self.rot = nil
    self.xVelocity = 0
    self.yVelocity = 0
    self.rotVelocity = 0
    
    -- Asset Path for Custom Image override
    self.assetPath = "cards/card_" .. string.lower(string.gsub(self.name, "%s+", "_")) .. ".png"
    
    return self
end

function PlayCard:upgrade(ydsAmount, mtmAmount)
    self.level = self.level + 1
    self.baseChips = self.baseChips + (ydsAmount or 1)
    self.baseMult = self.baseMult + (mtmAmount or 0.5)
end

function PlayCard:update(dt, isHovered, mouseRelX)
    local PhysicsUtils = require("src.engine.physics_utils")
    local targetRot = 0
    if isHovered and mouseRelX then
        -- Smaller sensitivity and tighter clamp for gentle tilt
        targetRot = math.clamp(mouseRelX * 0.004, -0.12, 0.12)
    end
    -- Store a local rotation offset from hover; actual smoothing is handled by StateGame
    self.rot = self.rot or 0
    self.rotVelocity = self.rotVelocity or 0
    -- Store requested offset; keep it small so StateGame spring produces gentle float
    self.rotOffset = targetRot
end

return PlayCard
