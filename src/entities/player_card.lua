-- src/entities/player_card.lua

local BadgesData = require("src.data.badges")
local PlayerCard = {}
PlayerCard.__index = PlayerCard

local firstNames = {"Marcus", "Jalen", "Trevor", "Ceedee", "Micah", "Justin", "Derrick", "Patrick", "Ja'Marr", "Davante", "A.J.", "Lamar", "Josh", "Tyreek", "Travis", "Saquon", "Nick", "Christian", "Deebo"}
local lastNames = {"Vance", "Carter", "Stiles", "Lamb", "Parsons", "Jefferson", "Henry", "Mahomes", "Chase", "Adams", "Brown", "Jackson", "Allen", "Hill", "Kelce", "Barkley", "Bosa", "McCaffrey", "Samuel"}

local archetypes = {
    QB = {
        { title = "Gunslinger", tag = "GUNSLINGER", chip = 2, mult = 0.5, desc = "+0.5 MTM on all Pass plays" },
        { title = "Scrambler", tag = "IMPROVISER", chip = 3, mult = 0.2, desc = "+3 YDS on Run plays" },
        { title = "Clutch QB", tag = "FIELD GENERAL", chip = 4, mult = 0.8, desc = "+4 YDS, +0.8 MTM on 3rd & 4th Down" },
        { title = "Field General", tag = "TACTICIAN", chip = 1, mult = 0.4, desc = "+1 Audible per drive" }
    },
    RB = {
        { title = "Power Back", tag = "POWER BACK", chip = 4, mult = 0.1, desc = "+4 Base Yards on Run plays" },
        { title = "Speedster", tag = "ELUSIVE BACK", chip = 1, mult = 0.6, desc = "+0.6 MTM on outside Run plays" },
        { title = "Dual Threat", tag = "RECEIVING BACK", chip = 3, mult = 0.4, desc = "+3 YDS on Play Action & Screen plays" }
    },
    WR = {
        { title = "Deep Threat", tag = "DEEP THREAT", chip = 5, mult = 0.7, desc = "+5 YDS, +0.7 MTM on Deep Passes" },
        { title = "Slot Specialist", tag = "SLOT GOD", chip = 2, mult = 0.5, desc = "+0.5 MTM on Short & Medium Passes" },
        { title = "YAC Monster", tag = "PLAYMAKER", chip = 3, mult = 0.3, desc = "+3 YDS after catch on Pass plays" }
    },
    TE = {
        { title = "Pancake Blocker", tag = "PANCAKE TE", chip = 3, mult = 0.3, desc = "+3 YDS on Run & Play Action" },
        { title = "Seam Threat", tag = "VERTICAL TE", chip = 4, mult = 0.5, desc = "+4 YDS on Medium Passes" }
    }
}

function PlayerCard.new(name, position, rarity, multBonus, chipBonus, edition)
    local self = setmetatable({}, PlayerCard)
    
    self.position = position or "WR1"
    local posType = self.position:sub(1, 2)
    if not archetypes[posType] then posType = "WR" end
    
    if name and name ~= "" and not name:match("^Rookie") then
        self.name = name
        self.overall = 90
        self.rarity = rarity or "Elite"
        self.chipBonus = chipBonus or 3
        self.multBonus = multBonus or 0.4
        self.abilityDesc = "Provides team bonus."
        self.archetypeTag = "GRIDIRON LEGEND"
    else
        local archList = archetypes[posType] or archetypes.WR
        local arch = archList[math.random(#archList)]
        
        self.name = firstNames[math.random(#firstNames)] .. " " .. lastNames[math.random(#lastNames)]
        self.overall = math.random(74, 99)
        self.rarity = self.overall >= 90 and "X-Factor" or (self.overall >= 80 and "Gold" or "Silver")
        
        self.chipBonus = arch.chip + math.floor((self.overall - 74) * 0.08)
        self.multBonus = arch.mult + ((self.overall - 74) * 0.02)
        self.abilityDesc = arch.desc
        self.archetypeTitle = arch.title
        self.archetypeTag = arch.tag
    end
    
    -- Editions: Standard, Foil (+5 YDS), Holographic (+1.0 MTM), Polychrome (x1.5 MTM), Negative (+1 Roster Slot)
    if edition then
        self.edition = edition
    else
        local roll = math.random(1, 100)
        if roll > 96 then self.edition = "Negative"
        elseif roll > 90 then self.edition = "Polychrome"
        elseif roll > 80 then self.edition = "Holographic"
        elseif roll > 70 then self.edition = "Foil"
        else self.edition = "Standard" end
    end
    
    -- Player Attributes (70..99)
    self.spd = math.clamp(math.floor(self.overall * 0.95 + math.random(-4, 4)), 60, 99)
    self.str = math.clamp(math.floor(self.overall * 0.90 + math.random(-4, 4)), 60, 99)
    self.awr = math.clamp(math.floor(self.overall * 0.98 + math.random(-3, 3)), 60, 99)
    self.cth = math.clamp(math.floor(self.overall * 0.92 + math.random(-4, 4)), 60, 99)

    -- MUT Tier Frame Colors
    if self.overall >= 90 then
        self.tierName = "X-Factor"
        self.cardColor = {0.12, 0.08, 0.22}
        self.borderColor = {0.0, 0.94, 1.0}
        self.secondaryBorderColor = {0.61, 0.0, 1.0}
    elseif self.overall >= 80 then
        self.tierName = "Gold"
        self.cardColor = {0.22, 0.18, 0.05}
        self.borderColor = {1.0, 0.84, 0.0}
    else
        self.tierName = "Silver"
        self.cardColor = {0.12, 0.14, 0.18}
        self.borderColor = {0.62, 0.66, 0.71}
    end
    
    self.isFlipped = false
    self.flipProgress = 0
    self.jumpY = 0
    self.equippedBadges = {}
    
    return self
end

function math.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function PlayerCard:trainPlayer()
    self.overall = math.min(99, self.overall + 3)
    self.chipBonus = self.chipBonus + 1
    self.multBonus = self.multBonus + 0.2
    self.spd = math.min(99, self.spd + 2)
    self.str = math.min(99, self.str + 2)
    self.awr = math.min(99, self.awr + 2)
    self.cth = math.min(99, self.cth + 2)
end

function PlayerCard:addEquippedBadge(badge)
    if #self.equippedBadges < 2 then
        table.insert(self.equippedBadges, badge)
    else
        self.equippedBadges[2] = badge
    end
end

function PlayerCard:update(dt)
    local targetFlip = self.isFlipped and 1 or 0
    self.flipProgress = self.flipProgress + (targetFlip - self.flipProgress) * math.min(1.0, dt * 12)
    if self.jumpY and self.jumpY < 0 then
        self.jumpY = math.min(0, self.jumpY + dt * 60)
    end
end

function PlayerCard:evaluatePlay(playCard, gameStateData)
    local activeChips = self.chipBonus
    local activeMult = self.multBonus
    
    if gameStateData and gameStateData.consecutiveDrivesWithoutRest > 5 then
        activeChips = math.floor(activeChips * 0.5)
        activeMult = activeMult * 0.5
    end
    
    if self.archetypeTitle == "Clutch QB" and gameStateData and (gameStateData.down == 3 or gameStateData.down == 4) then
        activeChips = activeChips + 3
        activeMult = activeMult + 0.5
    elseif self.archetypeTitle == "Gunslinger" and playCard and playCard.type:match("Pass") then
        activeMult = activeMult + 0.3
    elseif self.archetypeTitle == "Power Back" and playCard and playCard.type == "Run" then
        activeChips = activeChips + 3
    elseif self.archetypeTitle == "Deep Threat" and playCard and playCard.type == "Deep Pass" then
        activeChips = activeChips + 4
        activeMult = activeMult + 0.4
    end

    if self.isMyPlayer then
        local MyPlayerProfile = require("src.data.myplayer_profile")
        if MyPlayerProfile.hasNode("pass_1") and playCard and playCard.type == "Short Pass" then
            activeChips = activeChips + 2
        end
        if MyPlayerProfile.hasNode("pass_2") and playCard and playCard.type == "Deep Pass" then
            activeChips = math.floor(activeChips * 1.2)
        end
        if MyPlayerProfile.hasNode("rush_1") and playCard and (playCard.name == "HB Dive" or playCard.name == "Inside Zone" or playCard.name == "QB Draw") then
            activeMult = activeMult + 0.3
        end
        if MyPlayerProfile.hasNode("rush_3") and playCard and playCard.type == "Run" and gameStateData and (gameStateData.down == 3 or gameStateData.down == 4) then
            activeChips = activeChips + 5
        end
    end

    for _, b in ipairs(self.equippedBadges) do
        if b.evaluate then
            activeChips, activeMult = b.evaluate(gameStateData, playCard, activeChips, activeMult)
        end
    end
    
    if self.ability then
        activeChips, activeMult = self.ability(self, playCard, gameStateData, activeChips, activeMult)
    end
    
    return activeChips, activeMult
end

return PlayerCard
