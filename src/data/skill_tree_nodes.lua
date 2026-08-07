-- src/data/skill_tree_nodes.lua
local nodes = {}
local nodeDict = {}

local function addNode(id, req, name, desc, cost, qType, color, x, y)
    local n = { id = id, req = req, name = name, desc = desc, cost = cost, qType = qType, color = color, x = x, y = y }
    table.insert(nodes, n)
    nodeDict[id] = n
end

-- Center Node
addNode("rookie", nil, "Rookie Combine", "Welcome to the League.", 0, "CORE", {1, 1, 1}, 0, 0)

-- Quadrant Configuration
local quadrants = {
    QB = {
        color = {0.0, 0.58, 1.0},
        angleBase = -math.pi / 4, -- Top Right
        branches = {
            { name = "Field General", prefix = "IQ", effects = {"+1 Base Yards on Short Passes", "Reveal Coverages", "Reduced Audible Cost"} },
            { name = "Scrambler", prefix = "Legs", effects = {"+2 Drive Momentum on Scrambles", "Negate Sacks", "Boost Speed"} },
            { name = "Gunslinger", prefix = "Arm", effects = {"+5 Base Yards on Deep Passes", "Boost Throw Power", "Ignore Weather Penalties"} }
        }
    },
    RB = {
        color = {0.18, 0.72, 0.45},
        angleBase = math.pi / 4, -- Bottom Right
        branches = {
            { name = "Power Back", prefix = "Truck", effects = {"+3 Base Yards on Inside Runs", "Break Tackles", "Fall Forward"} },
            { name = "Elusive", prefix = "Juke", effects = {"+0.5x Momentum on Outside Runs", "Spin Move Boost", "Negate Loss of Yards"} },
            { name = "Receiving", prefix = "Hands", effects = {"+2 Yards on Screens", "Boost Catch Rating", "Mismatched LB Bonus"} }
        }
    },
    WR = {
        color = {0.9, 0.2, 0.3},
        angleBase = 3 * math.pi / 4, -- Bottom Left
        branches = {
            { name = "Deep Threat", prefix = "Burn", effects = {"+0.7x Momentum on Deep Passes", "Beat Press Coverage", "Boost Sprint Speed"} },
            { name = "Route Runner", prefix = "Cut", effects = {"+4 Base Yards on Medium Passes", "Create Separation", "Boost Agility"} },
            { name = "Possession", prefix = "Grip", effects = {"+10 Yards on 3rd Down", "Secure Catch", "Negate Drops"} }
        }
    },
    TE = {
        color = {1.0, 0.6, 0.0},
        angleBase = 5 * math.pi / 4, -- Top Left
        branches = {
            { name = "Blocking TE", prefix = "Block", effects = {"+2 Base Yards on Inside Runs", "Boost TE Run Block", "FLEX Slot Block Modifier"} },
            { name = "Security Blanket", prefix = "Safety", effects = {"+3 Yards on Short Passes", "Boost Catch in Traffic", "Automatic 1st Down on 3rd & Short"} },
            { name = "Vertical Threat", prefix = "Seam", effects = {"+5 Yards on Seam Routes", "Mismatched Safety Bonus", "Double Multiplier on Redzone Passes"} }
        }
    }
}

-- Procedural Generation of 100+ Nodes
local rStep = 180
local nodesPerBranch = 8

for qKey, qData in pairs(quadrants) do
    local branchAngles = { qData.angleBase - 0.25, qData.angleBase, qData.angleBase + 0.25 }
    
    -- Root for quadrant
    local qRootId = "root_" .. qKey
    local qX = math.cos(qData.angleBase) * (rStep * 0.8)
    local qY = math.sin(qData.angleBase) * (rStep * 0.8)
    addNode(qRootId, "rookie", qKey .. " Fundamentals", "Unlock " .. qKey .. " skill paths.", 1, qKey, qData.color, qX, qY)
    
    for bIdx, bData in ipairs(qData.branches) do
        local prevId = qRootId
        local angle = branchAngles[bIdx]
        
        for i = 1, nodesPerBranch do
            local id = qKey .. "_" .. bIdx .. "_" .. i
            local cost = math.ceil(i / 2)
            
            local name = bData.prefix .. " Drill " .. i
            local desc = bData.effects[(i % #bData.effects) + 1]
            
            local radius = (rStep * 0.8) + (i * 120)
            local jitterAngle = angle + (math.random() * 0.1 - 0.05)
            local x = math.cos(jitterAngle) * radius
            local y = math.sin(jitterAngle) * radius
            
            if i == nodesPerBranch then
                name = "CAPSTONE: " .. bData.name:upper()
                desc = "Mastery of the " .. bData.name .. " archetype."
                cost = 5
                -- Capstone is drawn larger
            end
            
            addNode(id, prevId, name, desc, cost, qKey, qData.color, x, y)
            prevId = id
        end
    end
end

return {
    list = nodes,
    dict = nodeDict
}
