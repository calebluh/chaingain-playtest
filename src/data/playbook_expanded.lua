-- src/data/playbook_expanded.lua
local PlayCard = require("src.entities.play_card")

-- 5 Distinct NFL Playbook Schemes
local schemePlaybooks = {
    shanahan_wide_zone = {
        name = "Shanahan / McVay Wide Zone Tree",
        desc = "Outside zone runs paired with heavy motion, condensed splits, and bootleg play-actions.",
        plays = {
            { name = "Outside Zone Left", type = "Run", chips = 5, mult = 1.35 },
            { name = "Wide Zone Stretch", type = "Run", chips = 4, mult = 1.4 },
            { name = "PA Boot Flood", type = "Play Action", chips = 11, mult = 2.2 },
            { name = "PA Deep Crossers", type = "Play Action", chips = 14, mult = 2.4 },
            { name = "Wz Cutback Counter", type = "Run", chips = 6, mult = 1.3 },
            { name = "PA Keeper Bootleg", type = "Play Action", chips = 10, mult = 2.1 }
        }
    },
    west_coast = {
        name = "Modern West Coast Offense",
        desc = "Short, precise passing game used as an extension of the run game to control tempo.",
        plays = {
            { name = "Quick Slant", type = "Short Pass", chips = 6, mult = 1.5 },
            { name = "Mesh Rail", type = "Short Pass", chips = 7, mult = 1.45 },
            { name = "HB Screen", type = "Short Pass", chips = 5, mult = 1.75 },
            { name = "WR Option Route", type = "Short Pass", chips = 8, mult = 1.6 },
            { name = "Shallow Cross", type = "Short Pass", chips = 6, mult = 1.55 },
            { name = "FL Drive", type = "Medium Pass", chips = 10, mult = 1.7 }
        }
    },
    spread_rpo = {
        name = "Spread & RPO System",
        desc = "Isolate conflict defenders sideways by forcing them to defend run vs quick throw.",
        plays = {
            { name = "RPO Zone Bubble", type = "Run", chips = 5, mult = 1.5 },
            { name = "RPO Slant Peek", type = "Short Pass", chips = 7, mult = 1.6 },
            { name = "QB Zone Read", type = "Run", chips = 6, mult = 1.4 },
            { name = "Quad Verts", type = "Deep Pass", chips = 17, mult = 2.3 },
            { name = "Jet Motion Touch Pass", type = "Run", chips = 4, mult = 1.65 },
            { name = "Tunnel Screen", type = "Short Pass", chips = 5, mult = 1.7 }
        }
    },
    air_raid = {
        name = "Air Raid & Vertical Passing",
        desc = "Simple, high-speed vertical route combinations with wide splits to stress coverage.",
        plays = {
            { name = "Four Verticals", type = "Deep Pass", chips = 16, mult = 2.2 },
            { name = "Y-Cross", type = "Medium Pass", chips = 12, mult = 1.9 },
            { name = "98 Smash", type = "Medium Pass", chips = 10, mult = 1.85 },
            { name = "Deep Post-Corner", type = "Deep Pass", chips = 19, mult = 2.5 },
            { name = "Double Move Go", type = "Deep Pass", chips = 22, mult = 2.7 },
            { name = "Hail Mary", type = "Deep Pass", chips = 25, mult = 2.8 }
        }
    },
    heavy_power = {
        name = "Heavy Power & Gap Scheme",
        desc = "Direct physical dominance using pulling guards, extra TEs, fullbacks, and max-protect PA.",
        plays = {
            { name = "Power-O", type = "Run", chips = 5, mult = 1.25 },
            { name = "Counter Trap", type = "Run", chips = 6, mult = 1.3 },
            { name = "Fullback Lead Iso", type = "Run", chips = 4, mult = 1.2 },
            { name = "Heavy PA TE Leak", type = "Play Action", chips = 13, mult = 2.3 },
            { name = "Jumbo QB Sneak", type = "Run", chips = 3, mult = 1.1 },
            { name = "Duo Power Slam", type = "Run", chips = 5, mult = 1.35 }
        }
    }
}

local defaultPlays = {
    -- Runs
    { name = "HB Dive", type = "Run", chips = 3, mult = 1.2 },
    { name = "HB Stretch", type = "Run", chips = 4, mult = 1.3 },
    { name = "Inside Zone", type = "Run", chips = 4, mult = 1.25 },
    { name = "QB Draw", type = "Run", chips = 5, mult = 1.35 },
    { name = "Jet Sweep", type = "Run", chips = 3, mult = 1.6 },
    { name = "Counter Trap", type = "Run", chips = 5, mult = 1.2 },
    
    -- Short Passes
    { name = "Quick Slant", type = "Short Pass", chips = 6, mult = 1.5 },
    { name = "Drag Route", type = "Short Pass", chips = 5, mult = 1.4 },
    { name = "Mesh", type = "Short Pass", chips = 7, mult = 1.35 },
    { name = "HB Screen", type = "Short Pass", chips = 4, mult = 1.7 },
    { name = "Stick Route", type = "Short Pass", chips = 6, mult = 1.45 },
    
    -- Medium Passes
    { name = "Dig Route", type = "Medium Pass", chips = 10, mult = 1.7 },
    { name = "Out Route", type = "Medium Pass", chips = 9, mult = 1.65 },
    { name = "Curls", type = "Medium Pass", chips = 8, mult = 1.8 },
    { name = "Corner Route", type = "Medium Pass", chips = 11, mult = 1.6 },
    { name = "TE Seam", type = "Medium Pass", chips = 12, mult = 1.55 },
    
    -- Deep Passes
    { name = "Four Verticals", type = "Deep Pass", chips = 16, mult = 2.2 },
    { name = "Post Route", type = "Deep Pass", chips = 18, mult = 2.3 },
    { name = "Go Route", type = "Deep Pass", chips = 20, mult = 2.5 },
    { name = "Hail Mary", type = "Deep Pass", chips = 25, mult = 2.8 },
    { name = "Flea Flicker", type = "Deep Pass", chips = 24, mult = 3.0 },
    
    -- Play Action
    { name = "PA Crossers", type = "Play Action", chips = 12, mult = 2.1 },
    { name = "PA Bootleg", type = "Play Action", chips = 10, mult = 2.0 },
    { name = "Philly Special", type = "Play Action", chips = 20, mult = 2.6 },
    { name = "Hook & Lateral", type = "Play Action", chips = 18, mult = 2.7 },
    
    -- New v2.0 & Legendary Scheme Play Cards
    { name = "QB Scramble", type = "Run", chips = 8, mult = 1.8, tag = "clutch_rush" },
    { name = "Lateral Pass", type = "Short Pass", chips = 5, mult = 2.0, tag = "no_int_risk" },
    { name = "Wildcat Formation", type = "Run", chips = 9, mult = 1.5, tag = "bypasses_blitz" },
    { name = "Spike Ball", type = "Run", chips = 0, mult = 0, tag = "spike_ball" },
    { name = "Trick Lateral", type = "Play Action", chips = 22, mult = 3.2, tag = "trick_play_risk" },
    { name = "Spider 2 Y Banana", type = "Play Action", chips = 13, mult = 2.3, tag = "clutch_te" },
    { name = "Philly Special Reverse", type = "Play Action", chips = 22, mult = 2.8, tag = "trick_play_risk" },
    { name = "Wildcat Jet Sweep", type = "Run", chips = 8, mult = 1.65, tag = "bypasses_blitz" },
    { name = "TE Wheel Route", type = "Medium Pass", chips = 14, mult = 1.85 },
    { name = "Triple Option Pitch", type = "Run", chips = 7, mult = 1.7 },
    { name = "Engage Eight Screen", type = "Short Pass", chips = 9, mult = 1.9, tag = "bypasses_blitz" },
    { name = "Hail Mary Prayer", type = "Deep Pass", chips = 28, mult = 3.2, tag = "high_risk_deep" }
}

local PlaybookExpanded = {}

PlaybookExpanded.schemes = schemePlaybooks

function PlaybookExpanded.getSchemePlaybook(schemeId)
    local scheme = schemePlaybooks[schemeId] or schemePlaybooks.shanahan_wide_zone
    local playbook = {}
    for _, play in ipairs(scheme.plays) do
        table.insert(playbook, PlayCard.new(play.name, play.type, play.chips, play.mult))
        table.insert(playbook, PlayCard.new(play.name, play.type, play.chips, play.mult))
    end
    return playbook
end

function PlaybookExpanded.generateFullPlaybook()
    local playbook = {}
    for _, play in ipairs(defaultPlays) do
        table.insert(playbook, PlayCard.new(play.name, play.type, play.chips, play.mult, 1, play.tag))
    end
    return playbook
end

return PlaybookExpanded
