-- src/data/myplayer_profile.lua
local MyPlayerProfile = {
    isCreated = false,
    name = "Rookie",
    position = "QB",
    legacyPoints = 0,
    baseChips = 10,
    baseMult = 2.0,
    equippedBadges = {},
    
    -- Visual Customization
    helmetStyle = "Modern", -- Classic, Modern, Speed
    visorTint = "Clear", -- Clear, Dark, Gold
    gearTape = "Wrist", -- None, Wrist, Elbow
    gearColor = {0.0, 0.76, 1.0},
    
    -- Progression
    ovr = 70,
    devTrait = "Normal",
    xp = 0,
    xpToNext = 1000,
    classPoints = 0,
    
    -- Stats
    totalYards = 0,
    totalTouchdowns = 0,
    superBowlRings = 0,
    seasonsPlayed = 0,
    maxSeasons = 10,
    
    -- Skill Tree Nodes
    unlockedNodes = {}
}

function MyPlayerProfile.addXP(amount)
    MyPlayerProfile.xp = MyPlayerProfile.xp + amount
    while MyPlayerProfile.xp >= MyPlayerProfile.xpToNext do
        MyPlayerProfile.xp = MyPlayerProfile.xp - MyPlayerProfile.xpToNext
        MyPlayerProfile.classPoints = MyPlayerProfile.classPoints + 1
        MyPlayerProfile.ovr = math.min(99, MyPlayerProfile.ovr + 1)
        MyPlayerProfile.xpToNext = math.floor(MyPlayerProfile.xpToNext * 1.15)
        
        if MyPlayerProfile.ovr >= 85 then MyPlayerProfile.devTrait = "Star" end
        if MyPlayerProfile.ovr >= 92 then MyPlayerProfile.devTrait = "Superstar" end
        if MyPlayerProfile.ovr >= 98 then MyPlayerProfile.devTrait = "X-Factor" end
    end
    MyPlayerProfile.save()
end

function MyPlayerProfile.hasNode(id)
    for _, n in ipairs(MyPlayerProfile.unlockedNodes or {}) do
        if n == id then return true end
    end
    return false
end

function MyPlayerProfile.retire()
    -- Grant massive legacy points based on total yards and TDs
    local legacyBonus = math.floor(MyPlayerProfile.totalYards / 50) + (MyPlayerProfile.totalTouchdowns * 5) + (MyPlayerProfile.superBowlRings * 100)
    MyPlayerProfile.addLegacyPoints(legacyBonus)
    
    -- Reset character stats to create a new rookie
    MyPlayerProfile.isCreated = false
    MyPlayerProfile.name = "Player"
    MyPlayerProfile.ovr = 70
    MyPlayerProfile.devTrait = "Normal"
    MyPlayerProfile.xp = 0
    MyPlayerProfile.xpToNext = 1000
    MyPlayerProfile.classPoints = 0
    MyPlayerProfile.totalYards = 0
    MyPlayerProfile.totalTouchdowns = 0
    MyPlayerProfile.superBowlRings = 0
    MyPlayerProfile.seasonsPlayed = 0
    MyPlayerProfile.unlockedNodes = {}
    
    MyPlayerProfile.save()
end

function MyPlayerProfile.addLegacyPoints(amount)
    MyPlayerProfile.legacyPoints = (MyPlayerProfile.legacyPoints or 0) + amount
    MyPlayerProfile.addXP(amount)
end

function MyPlayerProfile.save()
    local data = {
        isCreated = MyPlayerProfile.isCreated,
        name = MyPlayerProfile.name,
        position = MyPlayerProfile.position,
        helmetStyle = MyPlayerProfile.helmetStyle,
        visorTint = MyPlayerProfile.visorTint,
        gearTape = MyPlayerProfile.gearTape,
        ovr = MyPlayerProfile.ovr,
        devTrait = MyPlayerProfile.devTrait,
        xp = MyPlayerProfile.xp,
        xpToNext = MyPlayerProfile.xpToNext,
        classPoints = MyPlayerProfile.classPoints,
        totalYards = MyPlayerProfile.totalYards,
        totalTouchdowns = MyPlayerProfile.totalTouchdowns,
        superBowlRings = MyPlayerProfile.superBowlRings,
        seasonsPlayed = MyPlayerProfile.seasonsPlayed,
        unlockedNodes = MyPlayerProfile.unlockedNodes,
        legacyPoints = MyPlayerProfile.legacyPoints,
        baseChips = MyPlayerProfile.baseChips,
        baseMult = MyPlayerProfile.baseMult,
        abilityDesc = MyPlayerProfile.abilityDesc,
        archetypeTitle = MyPlayerProfile.archetypeTitle
    }
    
    local str = "return {\n"
    for k, v in pairs(data) do
        if type(v) == "table" then
            str = str .. "  " .. k .. " = { "
            for _, val in ipairs(v) do
                str = str .. '"' .. tostring(val) .. '", '
            end
            str = str .. "},\n"
        elseif type(v) == "string" then
            str = str .. "  " .. k .. ' = "' .. v .. '",\n'
        else
            str = str .. "  " .. k .. " = " .. tostring(v) .. ",\n"
        end
    end
    str = str .. "}"
    
    love.filesystem.write("myplayer_data.lua", str)
end

function MyPlayerProfile.load()
    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo("myplayer_data.lua") then
        local chunk = love.filesystem.load("myplayer_data.lua")
        if chunk then
            local data = chunk()
            if data then
                MyPlayerProfile.isCreated = (data.isCreated == nil) and false or data.isCreated
                MyPlayerProfile.name = data.name or MyPlayerProfile.name
                MyPlayerProfile.position = data.position or MyPlayerProfile.position
                MyPlayerProfile.helmetStyle = data.helmetStyle or "Modern"
                MyPlayerProfile.visorTint = data.visorTint or "Clear"
                MyPlayerProfile.gearTape = data.gearTape or "Wrist"
                MyPlayerProfile.ovr = data.ovr or MyPlayerProfile.ovr
                MyPlayerProfile.devTrait = data.devTrait or MyPlayerProfile.devTrait
                MyPlayerProfile.xp = data.xp or 0
                MyPlayerProfile.xpToNext = data.xpToNext or 1000
                MyPlayerProfile.classPoints = data.classPoints or 0
                MyPlayerProfile.totalYards = data.totalYards or 0
                MyPlayerProfile.totalTouchdowns = data.totalTouchdowns or 0
                MyPlayerProfile.superBowlRings = data.superBowlRings or 0
                MyPlayerProfile.seasonsPlayed = data.seasonsPlayed or 0
                MyPlayerProfile.unlockedNodes = data.unlockedNodes or {}
                MyPlayerProfile.legacyPoints = data.legacyPoints or 0
                MyPlayerProfile.baseChips = data.baseChips or 10
                MyPlayerProfile.baseMult = data.baseMult or 2.0
                MyPlayerProfile.abilityDesc = data.abilityDesc or "Provides team bonus."
                MyPlayerProfile.archetypeTitle = data.archetypeTitle or "Gunslinger"
            end
        end
    end
end

MyPlayerProfile.load()

return MyPlayerProfile
