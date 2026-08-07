-- src/data/playbook_expanded.lua
local PlayCard = require("src.entities.play_card")

-- Realistic NFL Base Yards & Drive Momentum Values
-- Runs avg ~4.3 YPC, Short Passes ~6-8 YPR, Medium ~10-13, Deep ~15-22
-- Momentum acts as a multiplier representing execution quality
local defaultPlays = {
    -- Runs (6) - Base Yards: 3-5 (realistic rushing average)
    { name = "HB Dive", type = "Run", chips = 3, mult = 1.2 },
    { name = "HB Stretch", type = "Run", chips = 4, mult = 1.3 },
    { name = "Inside Zone", type = "Run", chips = 4, mult = 1.25 },
    { name = "QB Draw", type = "Run", chips = 5, mult = 1.35 },
    { name = "Jet Sweep", type = "Run", chips = 3, mult = 1.6 },
    { name = "Counter Trap", type = "Run", chips = 5, mult = 1.2 },
    
    -- Short Passes (5) - Base Yards: 5-7 (short crossing routes, screens)
    { name = "Quick Slant", type = "Short Pass", chips = 6, mult = 1.5 },
    { name = "Drag Route", type = "Short Pass", chips = 5, mult = 1.4 },
    { name = "Mesh", type = "Short Pass", chips = 7, mult = 1.35 },
    { name = "HB Screen", type = "Short Pass", chips = 4, mult = 1.7 },
    { name = "Stick Route", type = "Short Pass", chips = 6, mult = 1.45 },
    
    -- Medium Passes (5) - Base Yards: 8-12 (dig, out, curl routes)
    { name = "Dig Route", type = "Medium Pass", chips = 10, mult = 1.7 },
    { name = "Out Route", type = "Medium Pass", chips = 9, mult = 1.65 },
    { name = "Curls", type = "Medium Pass", chips = 8, mult = 1.8 },
    { name = "Corner Route", type = "Medium Pass", chips = 11, mult = 1.6 },
    { name = "TE Seam", type = "Medium Pass", chips = 12, mult = 1.55 },
    
    -- Deep Passes (5) - Base Yards: 16-25 (go routes, verticals, hail mary)
    { name = "Four Verticals", type = "Deep Pass", chips = 16, mult = 2.2 },
    { name = "Post Route", type = "Deep Pass", chips = 18, mult = 2.3 },
    { name = "Go Route", type = "Deep Pass", chips = 20, mult = 2.5 },
    { name = "Hail Mary", type = "Deep Pass", chips = 25, mult = 2.8 },
    { name = "Flea Flicker", type = "Deep Pass", chips = 24, mult = 3.0 },
    
    -- Play Action & Trick Plays (4)
    { name = "PA Crossers", type = "Play Action", chips = 12, mult = 2.1 },
    { name = "PA Bootleg", type = "Play Action", chips = 10, mult = 2.0 },
    { name = "Philly Special", type = "Play Action", chips = 20, mult = 2.6 },
    { name = "Hook & Lateral", type = "Play Action", chips = 18, mult = 2.7 }
}

local PlaybookExpanded = {}

function PlaybookExpanded.generateFullPlaybook()
    local playbook = {}
    for _, play in ipairs(defaultPlays) do
        table.insert(playbook, PlayCard.new(play.name, play.type, play.chips, play.mult))
    end
    return playbook
end

return PlaybookExpanded
