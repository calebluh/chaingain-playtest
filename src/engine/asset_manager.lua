-- src/engine/asset_manager.lua
local AssetManager = {}

local images = {}
local fontCache = {}

local function buildAssetCandidates(relativePath)
    local normalized = (relativePath or ""):gsub("\\", "/")
    normalized = normalized:gsub("^%./+", "")
    normalized = normalized:gsub("^/+", "")

    if normalized == "" then
        return {}
    end

    local candidates = {}
    local seen = {}

    local function addCandidate(path)
        if not path or seen[path] then
            return
        end
        seen[path] = true
        table.insert(candidates, path)
    end

    local normalizedNoExt = normalized:gsub("%.png$", "")

    addCandidate(normalized)
    addCandidate("assets/2x/" .. normalized)
    addCandidate("assets/1x/" .. normalized)
    addCandidate("assets/images/" .. normalized)
    addCandidate("assets/images/2x/" .. normalized)
    addCandidate("assets/" .. normalized)

    if normalizedNoExt:match("^ui/") then
        addCandidate("assets/images/" .. normalizedNoExt:gsub("^ui/", ""))
        addCandidate("assets/images/ui/" .. normalizedNoExt:gsub("^ui/", "") .. ".png")
    end

    if normalized:match("^cards/") or normalizedNoExt:match("^cards/") then
        addCandidate("assets/images/cards/" .. normalized:gsub("^cards/", ""))
        addCandidate("assets/images/cards/" .. normalizedNoExt:gsub("^cards/", "") .. ".png")
    end

    if normalized:match("^players/") or normalizedNoExt:match("^players/") then
        addCandidate("assets/images/players/" .. normalized:gsub("^players/", ""))
        addCandidate("assets/images/players/" .. normalizedNoExt:gsub("^players/", "") .. ".png")
    end

    if normalized:match("^blinds/") or normalizedNoExt:match("^blinds/") then
        addCandidate("assets/images/blinds/" .. normalized:gsub("^blinds/", ""))
        addCandidate("assets/images/blinds/" .. normalizedNoExt:gsub("^blinds/", "") .. ".png")
    end

    if normalized:match("^ui/") or normalizedNoExt:match("^ui/") then
        addCandidate("assets/images/ui/" .. normalized:gsub("^ui/", ""))
        addCandidate("assets/images/ui/" .. normalizedNoExt:gsub("^ui/", "") .. ".png")
    end

    if normalized:match("^sprites/") or normalizedNoExt:match("^sprites/") then
        addCandidate("assets/sprites/" .. normalized:gsub("^sprites/", ""))
        addCandidate("assets/sprites/" .. normalizedNoExt:gsub("^sprites/", "") .. ".png")
    end

    if not normalized:match("^images/") and not normalized:match("^cards/") and not normalized:match("^blinds/") and not normalized:match("^players/") and not normalized:match("^ui/") and not normalized:match("^sprites/") then
        addCandidate("assets/sprites/" .. normalized)
        addCandidate("assets/images/" .. normalized)
        addCandidate("assets/" .. normalized)
        addCandidate("assets/images/cards/" .. normalized)
        addCandidate("assets/images/players/" .. normalized)
        addCandidate("assets/images/blinds/" .. normalized)
        addCandidate("assets/images/ui/" .. normalized)
    end

    return candidates
end

function AssetManager.init()
    images = {}
    fontCache = {}
    
    -- Dynamically generate modular player layers at runtime
    AssetManager.initModularPlayer()
end

function AssetManager.initModularPlayer()
    -- Replaced by dynamic shader rendering in drawModularPlayer to prevent massive game freeze on start
end

function AssetManager.getImage(relativePath, filterMode)
    -- Cache key includes filter mode so "linear" and "nearest" versions don't collide
    local cacheKey = relativePath .. (filterMode and (":" .. filterMode) or "")
    if images[cacheKey] ~= nil then
        return images[cacheKey]
    end

    local candidatePaths = buildAssetCandidates(relativePath)
    for _, fullPath in ipairs(candidatePaths) do
        if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(fullPath) then
            local ok, img = pcall(love.graphics.newImage, fullPath)
            if ok and img then
                local f = filterMode or "nearest"
                img:setFilter(f, f)
                images[cacheKey] = img
                return img
            end
        end
    end

    images[cacheKey] = false
    return false
end

function AssetManager.getFont(size)
    size = size or 14
    if fontCache[size] then
        return fontCache[size]
    end
    local font = love.graphics.newFont(size)
    fontCache[size] = font
    return font
end

function AssetManager.drawPlayCardArt(x, y, w, h, playName, playType)
    love.graphics.push()
    love.graphics.translate(x, y)
    
    local relPath = "cards/card_" .. string.lower(string.gsub(playName, "%s+", "_")) .. ".png"
    local img = AssetManager.getImage(relPath)
    
    if img then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, 0, 0, 0, w / img:getWidth(), h / img:getHeight())
    else
        -- HD Balatro-Style Chalkboard Grid Base
        love.graphics.setColor(0.05, 0.12, 0.08, 0.95)
        love.graphics.rectangle("fill", 0, 0, w, h, 6, 6)
        
        -- Chalkboard Grid Lines
        love.graphics.setColor(0.18, 0.35, 0.22, 0.4)
        love.graphics.setLineWidth(1)
        for lx = 15, w - 15, 18 do
            love.graphics.line(lx, 6, lx, h - 6)
        end
        for ly = 15, h - 15, 18 do
            love.graphics.line(6, ly, w - 6, ly)
        end
        
        -- Line of Scrimmage Hash
        love.graphics.setColor(0.1, 0.45, 0.8, 0.6)
        love.graphics.rectangle("fill", 8, h - 22, w - 16, 2)
        
        -- Vector Play Diagram with Neon Halos
        if playType == "Run" then
            -- Outer Glow
            love.graphics.setColor(0.18, 0.72, 0.45, 0.3)
            love.graphics.setLineWidth(5)
            love.graphics.line(w/2, h - 20, w/2, h/2 + 5, w/2 + 25, h/2 - 25)
            -- Main Route Line
            love.graphics.setColor(0.18, 0.72, 0.45, 1.0)
            love.graphics.setLineWidth(3)
            love.graphics.line(w/2, h - 20, w/2, h/2 + 5, w/2 + 25, h/2 - 25)
            love.graphics.polygon("fill", w/2 + 25, h/2 - 25, w/2 + 16, h/2 - 23, w/2 + 22, h/2 - 16)
        elseif playType == "Short Pass" or playType == "Medium Pass" then
            local mainColor = (playType == "Short Pass") and {0.0, 0.76, 1.0} or {1.0, 0.84, 0.0}
            love.graphics.setColor(mainColor[1], mainColor[2], mainColor[3], 0.3)
            love.graphics.setLineWidth(5)
            love.graphics.line(w/4, h - 20, w/4, h/2, w/2 + 25, h/2)
            love.graphics.line(3*w/4, h - 20, 3*w/4, h/2 + 10, w/2 - 25, h/2 + 10)
            
            love.graphics.setColor(mainColor[1], mainColor[2], mainColor[3], 1.0)
            love.graphics.setLineWidth(3)
            love.graphics.line(w/4, h - 20, w/4, h/2, w/2 + 25, h/2)
            love.graphics.polygon("fill", w/2 + 25, h/2, w/2 + 18, h/2 - 4, w/2 + 18, h/2 + 4)
            love.graphics.line(3*w/4, h - 20, 3*w/4, h/2 + 10, w/2 - 25, h/2 + 10)
            love.graphics.polygon("fill", w/2 - 25, h/2 + 10, w/2 - 18, h/2 + 6, w/2 - 18, h/2 + 14)
        elseif playType == "Deep Pass" then
            love.graphics.setColor(1.0, 0.84, 0.0, 0.3)
            love.graphics.setLineWidth(5)
            love.graphics.line(w/4, h - 20, w/4, 18)
            love.graphics.line(3*w/4, h - 20, 3*w/4, 18)
            
            love.graphics.setColor(1.0, 0.84, 0.0, 1.0)
            love.graphics.setLineWidth(3)
            love.graphics.line(w/4, h - 20, w/4, 18)
            love.graphics.line(3*w/4, h - 20, 3*w/4, 18)
            love.graphics.polygon("fill", w/4, 12, w/4 - 5, 22, w/4 + 5, 22)
            love.graphics.polygon("fill", 3*w/4, 12, 3*w/4 - 5, 22, 3*w/4 + 5, 22)
        else
            love.graphics.setColor(0.7, 0.3, 1.0, 0.3)
            love.graphics.setLineWidth(5)
            love.graphics.line(w/2, h - 20, w/2 - 22, h/2 + 8, w/2 + 30, 20)
            
            love.graphics.setColor(0.7, 0.3, 1.0, 1.0)
            love.graphics.setLineWidth(3)
            love.graphics.line(w/2, h - 20, w/2 - 22, h/2 + 8, w/2 + 30, 20)
            love.graphics.polygon("fill", w/2 + 30, 20, w/2 + 20, 20, w/2 + 27, 28)
        end
        love.graphics.setLineWidth(1)
        
        -- Sleek Playbook Monogram Tag
        love.graphics.setColor(1, 1, 1, 0.25)
        local font = AssetManager.getFont(9)
        love.graphics.setFont(font)
        love.graphics.printf(playName:upper(), 4, h - 14, w - 8, "center")
    end
    
    love.graphics.pop()
end

function AssetManager.drawPlayerPortrait(x, y, w, h, playerName, position, isStar, isMyPlayer)
    love.graphics.push()
    love.graphics.translate(x, y)
    
    local relPath = "players/player_" .. string.lower(string.gsub(playerName, "%s+", "_")) .. ".png"
    local img = AssetManager.getImage(relPath)
    
    if img and not isMyPlayer then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, 0, 0, 0, w / img:getWidth(), h / img:getHeight())
    else
        if isMyPlayer then
            local PlayerVisualProfile = require("src.data.player_visual_profile")
            local skinColor = PlayerVisualProfile.getSkinColor()
            local visorColor = PlayerVisualProfile.getVisorColor()
            
            love.graphics.setColor(0.08, 0.15, 0.25, 1)
            love.graphics.rectangle("fill", 0, 0, w, h, 6, 6)
            
            -- Jersey shoulders
            love.graphics.setColor(PlayerVisualProfile.primaryColor or {0.13, 0.34, 0.13})
            love.graphics.rectangle("fill", w/2 - 22, h/2 + 10, 44, 25, 6, 6)
            
            -- Neck
            love.graphics.setColor(skinColor)
            love.graphics.rectangle("fill", w/2 - 7, h/2 - 2, 14, 15)
            
            -- Helmet Shell
            love.graphics.setColor(PlayerVisualProfile.shellColor or {0.07, 0.13, 0.27})
            love.graphics.circle("fill", w/2, h/2 - 10, 18)
            
            -- Helmet Stripe
            if PlayerVisualProfile.stripeColor then
                love.graphics.setColor(PlayerVisualProfile.stripeColor)
                love.graphics.rectangle("fill", w/2 - 2, h/2 - 28, 4, 18)
            end
            
            -- Facemask
            love.graphics.setColor(PlayerVisualProfile.maskColor or {0.75, 0.75, 0.75})
            love.graphics.rectangle("fill", w/2 + 2, h/2 - 5, 15, 10, 2, 2)
            
            -- Visor Tint
            love.graphics.setColor(visorColor)
            love.graphics.rectangle("fill", w/2 + 1, h/2 - 13, 14, 7, 2, 2)
            
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", 4, h - 22, w - 8, 18, 3, 3)
            love.graphics.setColor(0.0, 0.76, 1.0)
            local font = AssetManager.getFont(10)
            love.graphics.setFont(font)
            love.graphics.printf(playerName:upper(), 4, h - 19, w - 8, "center")
        else
            -- Balatro HD Roster Vector Silhouette
            if isStar then
                love.graphics.setColor(0.2, 0.16, 0.04, 1)
            else
                love.graphics.setColor(0.08, 0.12, 0.18, 1)
            end
            love.graphics.rectangle("fill", 0, 0, w, h, 6, 6)
            
            -- Glowing Star Aura Frame
            if isStar then
                love.graphics.setColor(1.0, 0.84, 0.0, 0.35)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", 2, 2, w - 4, h - 4, 5, 5)
                love.graphics.setLineWidth(1)
            end
            
            -- Vector Player Silhouette
            love.graphics.setColor(0.2, 0.28, 0.38, 0.7)
            love.graphics.rectangle("fill", w/2 - 20, h/2 + 6, 40, 26, 6, 6) -- Shoulders
            love.graphics.circle("fill", w/2, h/2 - 10, 16) -- Helmet
            love.graphics.setColor(0.0, 0.76, 1.0, 0.6)
            love.graphics.rectangle("fill", w/2 + 1, h/2 - 13, 12, 6, 2, 2) -- Visor Highlight
            
            -- Top Position Badge
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 4, 4, 34, 18, 4, 4)
            love.graphics.setColor(isStar and {1.0, 0.84, 0.0} or {0.0, 0.76, 1.0})
            local font = AssetManager.getFont(10)
            love.graphics.setFont(font)
            love.graphics.printf(position, 4, 7, 34, "center")
        end
    end
    
    love.graphics.pop()
end

function AssetManager.drawBlindIcon(x, y, radius, blindName, isBoss)
    love.graphics.push()
    love.graphics.translate(x, y)
    
    local relPath = "blinds/blind_" .. string.lower(string.gsub(blindName, "%s+", "_")) .. ".png"
    local img = AssetManager.getImage(relPath)
    
    if img then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, -radius, -radius, 0, (radius * 2) / img:getWidth(), (radius * 2) / img:getHeight())
    else
        if isBoss then
            love.graphics.setColor(0.8, 0.1, 0.1, 1)
        else
            love.graphics.setColor(0.2, 0.4, 0.7, 1)
        end
        love.graphics.circle("fill", 0, 0, radius)
        
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("line", 0, 0, radius - 2)
        
        love.graphics.setLineWidth(2)
        love.graphics.line(-radius*0.4, 0, radius*0.4, 0)
        love.graphics.line(0, -radius*0.4, 0, radius*0.4)
        love.graphics.setLineWidth(1)
    end
    
    love.graphics.pop()
end


-- ─── Full-Body Retro Player Renderer ────────────────────────────
-- Fully customizable sprite with pixel accessories & animations
function AssetManager.drawRetroPlayer(x, y, jerseyColor, pantsColor, helmetColor, vx, vy, isOffense, time, isTackled, profileData, scaleOverride)
    vx = vx or 0
    vy = vy or 0
    time = time or 0
    local speed = math.sqrt(vx*vx + vy*vy)
    local state = "idle"
    if isTackled then state = "tackled"
    elseif speed > 10 then state = "run"
    elseif speed > 2 then state = "walk"
    end
    
    local PlayerVisualProfile = require("src.data.player_visual_profile")
    local profile = nil
    if type(profileData) == "table" then
        profile = profileData
    elseif profileData == true then
        profile = PlayerVisualProfile
    end
    
    local skinColor = {0.85, 0.65, 0.45}
    local visorColor = {0.1, 0.1, 0.1, 0.85}
    jerseyColor = jerseyColor or {0.18, 0.72, 0.45}
    pantsColor = pantsColor or {0.9, 0.9, 0.9}
    helmetColor = helmetColor or jerseyColor
    
    if profile then
        if profile.skinTone then skinColor = PlayerVisualProfile.skinTones[profile.skinTone] or skinColor
        elseif profile.getSkinColor then skinColor = profile.getSkinColor() end
        if profile.primaryColor then jerseyColor = profile.primaryColor end
        if profile.shellColor then helmetColor = profile.shellColor end
        
        if profile.visor == "dark" then visorColor = {0.08, 0.08, 0.08, 0.95}
        elseif profile.visor == "gold_mirror" then visorColor = {1.0, 0.8, 0.0, 0.85}
        elseif profile.visor == "clear" then visorColor = {0, 0, 0, 0}
        elseif profile.visor == "iridescent" then
            visorColor = {0.5 + 0.5*math.sin(time*2), 0.5 + 0.5*math.sin(time*2+2.1), 0.5 + 0.5*math.sin(time*2+4.2), 0.8}
        end
    end
    
    love.graphics.push()
    love.graphics.translate(x, y)
    local scale = (scaleOverride or 1.0) * 1.5
    love.graphics.scale(scale, scale)
    
    if state == "tackled" then
        love.graphics.rotate(math.pi / 2)
        love.graphics.translate(0, -6)
    end
    
    -- Animation Offsets
    local legOffset, armOffset, bobY = 0, 0, 0
    if state == "run" then
        legOffset = math.sin(time * 15) * 4
        armOffset = math.cos(time * 15) * 4
        bobY = math.abs(math.sin(time * 15)) * -1.5
    elseif state == "walk" then
        legOffset = math.sin(time * 8) * 2
        armOffset = math.cos(time * 8) * 2
        bobY = math.abs(math.sin(time * 8)) * -0.5
    elseif state == "idle" then
        bobY = math.sin(time * 4) * 0.5
    end
    
    love.graphics.translate(0, bobY)
    
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse("fill", 0, 10 - bobY, 12, 4)
    
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")
    
    local isFacingDown = (isOffense == nil or isOffense == true)
    
    -- LEGS & CALF SLEEVES
    love.graphics.setColor(pantsColor)
    love.graphics.setLineWidth(5)
    love.graphics.line(-4, 3, -4, 8 + legOffset)
    love.graphics.line(4, 3, 4, 8 - legOffset)
    
    -- Calf sleeves if active
    if profile and profile.calfSleeves and profile.calfSleeves ~= "none" then
        local csColor = {1, 1, 1}
        if profile.calfSleeves == "black" then csColor = {0.1, 0.1, 0.1}
        elseif profile.calfSleeves == "team" then csColor = jerseyColor end
        love.graphics.setColor(csColor)
        love.graphics.setLineWidth(5)
        love.graphics.line(-4, 5 + legOffset*0.5, -4, 8 + legOffset)
        love.graphics.line(4, 5 - legOffset*0.5, 4, 8 - legOffset)
    end
    
    -- CLEATS
    local cleatColor = {0.1, 0.1, 0.1}
    if profile and profile.cleats then
        if profile.cleats == "white" then cleatColor = {0.95, 0.95, 0.95}
        elseif profile.cleats == "gold" then cleatColor = {1.0, 0.84, 0.0}
        elseif profile.cleats == "team" then cleatColor = jerseyColor end
    end
    love.graphics.setColor(cleatColor)
    if isFacingDown then
        love.graphics.circle("fill", -4, 9 + legOffset, 2.5)
        love.graphics.circle("fill", 4, 9 - legOffset, 2.5)
    else
        love.graphics.circle("fill", -4, 8 + legOffset, 2)
        love.graphics.circle("fill", 4, 8 - legOffset, 2)
    end
    
    -- ARMS (Back layer if facing up)
    if not isFacingDown then
        love.graphics.setColor(skinColor)
        love.graphics.setLineWidth(4)
        love.graphics.line(-7, -2, -9, 4 - armOffset)
        love.graphics.line(7, -2, 9, 4 + armOffset)
        
        love.graphics.setColor(jerseyColor)
        love.graphics.line(-7, -2, -8, 1 - armOffset*0.5)
        love.graphics.line(7, -2, 8, 1 + armOffset*0.5)
    end
    
    -- TORSO / JERSEY
    love.graphics.setColor(jerseyColor)
    love.graphics.rectangle("fill", -7, -4, 14, 10, 3, 3)
    
    -- Jersey Number
    local jNum = profile and profile.jerseyNumber
    if jNum and jNum > 0 then
        love.graphics.setColor(1, 1, 1, 0.95)
        local font = AssetManager.getFont(9)
        love.graphics.setFont(font)
        love.graphics.printf(tostring(jNum), -10, -3, 20, "center")
    end
    
    -- ARMS (Front layer if facing down)
    if isFacingDown then
        love.graphics.setColor(skinColor)
        love.graphics.setLineWidth(4)
        love.graphics.line(-7, -2, -9, 4 - armOffset)
        love.graphics.line(7, -2, 9, 4 + armOffset)
        
        -- Arm Gear (Sleeves / Turf tape / Bands)
        if profile and profile.armGear and profile.armGear ~= "none" then
            local agColor = (profile.armGear == "white") and {1, 1, 1} or ((profile.armGear == "black") and {0.1, 0.1, 0.1} or jerseyColor)
            love.graphics.setColor(agColor)
            love.graphics.line(-7, -1, -9, 3 - armOffset)
            love.graphics.line(7, -1, 9, 3 + armOffset)
        else
            -- Standard short sleeves
            love.graphics.setColor(jerseyColor)
            love.graphics.line(-7, -2, -8, 1 - armOffset*0.5)
            love.graphics.line(7, -2, 8, 1 + armOffset*0.5)
        end
        
        -- Gloves / Hand Gear
        if profile and profile.handGear and profile.handGear ~= "none" then
            local gColor = {1, 1, 1}
            if profile.handGearColor == "black" then gColor = {0.1, 0.1, 0.1}
            elseif profile.handGearColor == "team" then gColor = jerseyColor
            elseif profile.handGearColor == "gold" then gColor = {1.0, 0.84, 0.0} end
            love.graphics.setColor(gColor)
            love.graphics.circle("fill", -9, 4 - armOffset, 2)
            love.graphics.circle("fill", 9, 4 + armOffset, 2)
        end
    end
    
    -- HAIR BEHIND HELMET
    if profile and profile.hairStyle and profile.hairStyle ~= "none" then
        love.graphics.setColor(profile.hairColor or {0.1, 0.1, 0.1})
        if profile.hairStyle == "dreads" then
            love.graphics.rectangle("fill", -6, -8, 2, 7)
            love.graphics.rectangle("fill", -4, -6, 2, 6)
            love.graphics.rectangle("fill", 4, -8, 2, 7)
        elseif profile.hairStyle == "afro" then
            love.graphics.circle("fill", 0, -11, 7)
        elseif profile.hairStyle == "braids" then
            love.graphics.rectangle("fill", -5, -7, 2, 8)
            love.graphics.rectangle("fill", 3, -7, 2, 8)
        elseif profile.hairStyle == "mullet" then
            love.graphics.rectangle("fill", -4, -6, 8, 5)
        end
    end
    
    -- HEAD / HELMET SHELL
    love.graphics.setColor(helmetColor)
    love.graphics.circle("fill", 0, -10, 7.5)
    
    if isFacingDown then
        -- Visor / Face Cutout
        love.graphics.setColor(0.1, 0.1, 0.15)
        love.graphics.rectangle("fill", -5, -12, 10, 6, 2, 2)
        
        -- Skin visible inside helmet
        love.graphics.setColor(skinColor)
        love.graphics.rectangle("fill", -4, -10, 8, 4, 1, 1)
        
        -- Eye Black
        if profile and profile.eyeBlack and profile.eyeBlack ~= "clean" then
            love.graphics.setColor(0.1, 0.1, 0.1)
            if profile.eyeBlack == "single_bar" then
                love.graphics.rectangle("fill", -3, -9, 6, 1)
            elseif profile.eyeBlack == "warpaint" then
                love.graphics.rectangle("fill", -4, -9, 3, 2)
                love.graphics.rectangle("fill", 1, -9, 3, 2)
            elseif profile.eyeBlack == "cross" then
                love.graphics.rectangle("fill", -2, -10, 1, 3)
                love.graphics.rectangle("fill", 1, -10, 1, 3)
            end
        end
        
        -- Earrings
        local earCount = profile and profile.earrings or 0
        if earCount > 0 then
            love.graphics.setColor(1.0, 0.84, 0.0)
            for ei = 1, math.min(earCount, 2) do
                love.graphics.rectangle("fill", -6, -9 + (ei-1)*2, 1.5, 1.5)
            end
        end
        
        -- Visor tint
        if visorColor[4] and visorColor[4] > 0 then
            love.graphics.setColor(visorColor)
            love.graphics.rectangle("fill", -5, -12, 10, 3.5, 1, 1)
        end
        
        -- Facemask (styles 1-6)
        local fm = profile and profile.facemask or 5
        local maskColor = profile and profile.maskColor or {0.85, 0.85, 0.85}
        love.graphics.setColor(maskColor)
        love.graphics.setLineWidth(1.5)
        if fm == 1 then
            love.graphics.line(-5, -7, 5, -7)
        elseif fm == 2 then
            love.graphics.line(-5, -8, 5, -8)
            love.graphics.line(-4, -6, 4, -6)
        elseif fm == 3 then
            love.graphics.line(-5, -9, 5, -9)
            love.graphics.line(-5, -7, 5, -7)
            love.graphics.line(-4, -5, 4, -5)
        elseif fm == 4 then
            love.graphics.line(-5, -9, 5, -9)
            love.graphics.line(-5, -7, 5, -7)
            love.graphics.line(-4, -5, 4, -5)
            love.graphics.line(-2, -9, -2, -5)
            love.graphics.line(2, -9, 2, -5)
        elseif fm == 5 then
            love.graphics.line(-5, -8, 5, -8)
            love.graphics.line(-4, -6, 4, -6)
            love.graphics.line(0, -11, 0, -6)
        elseif fm == 6 then
            love.graphics.rectangle("fill", -4, -9, 8, 4)
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", -3, -8, 6, 2)
        end
        
        -- Helmet Stripe
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.line(0, -17, 0, -12)
    else
        -- Back of helmet stripe
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.line(0, -17, 0, -6)
    end
    
    love.graphics.setLineWidth(1)
    love.graphics.pop()
end

-- ─── Modular Player Renderer ────────────────────────────────────
function AssetManager.drawModularPlayer(x, y, scaleOverride, profile, teamColors, isOffense, time, isTackled)
    local scale = scaleOverride or 1.0
    
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale, scale)
    
    if isTackled then
        love.graphics.rotate(math.pi / 2)
        love.graphics.translate(0, -6)
    end
    
    local bobY = 0
    if time then
        bobY = math.sin(time * 4) * 0.5
    end
    love.graphics.translate(0, bobY)
    
    local img = AssetManager.getImage("sprites/player_home.png", "nearest")
    if img then
        if not AssetManager._modularShader then
            AssetManager._modularShader = love.graphics.newShader[[
                extern vec3 primaryColor;
                extern vec3 secondaryColor;
                extern vec3 pantsColor;
                extern vec3 skinColor;
                extern vec4 visorColor;
                
                vec3 RGBtoHSL(vec3 c) {
                    float cMax = max(max(c.r, c.g), c.b);
                    float cMin = min(min(c.r, c.g), c.b);
                    float delta = cMax - cMin;
                    vec3 hsl = vec3(0.0, 0.0, (cMax + cMin) / 2.0);
                    if (delta != 0.0) {
                        hsl.y = hsl.z < 0.5 ? delta / (cMax + cMin) : delta / (2.0 - cMax - cMin);
                        if (cMax == c.r) {
                            hsl.x = (c.g - c.b) / delta + (c.g < c.b ? 6.0 : 0.0);
                        } else if (cMax == c.g) {
                            hsl.x = (c.b - c.r) / delta + 2.0;
                        } else {
                            hsl.x = (c.r - c.g) / delta + 4.0;
                        }
                        hsl.x /= 6.0;
                    }
                    return hsl;
                }

                vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
                    vec4 pix = Texel(tex, tc);
                    if (pix.a == 0.0) return pix;
                    
                    vec3 hsl = RGBtoHSL(pix.rgb);
                    bool isHelmetArea = tc.y < 0.4;
                    
                    vec4 outColor = pix;
                    
                    if (hsl.z < 0.15 && hsl.y < 0.2) {
                        if (isHelmetArea && tc.y > 0.15 && tc.x > 0.25) {
                            // Visor
                            if (visorColor.a > 0.0) {
                                outColor = vec4(visorColor.rgb, visorColor.a * pix.a);
                            } else {
                                outColor = vec4(0.0);
                            }
                        } else {
                            // Outline
                            outColor = pix;
                        }
                    } else if (hsl.y < 0.15 && hsl.z > 0.5) {
                        // White parts
                        float intensity = min(1.0, hsl.z * 2.5);
                        if (isHelmetArea) {
                            outColor = vec4(secondaryColor * intensity, pix.a);
                        } else {
                            outColor = vec4(pantsColor * intensity, pix.a);
                        }
                    } else if (hsl.x > 0.02 && hsl.x < 0.15 && hsl.y > 0.3) {
                        // Skin
                        float intensity = hsl.z / 0.3;
                        outColor = vec4(skinColor * intensity, pix.a);
                    } else if (hsl.x > 0.4 && hsl.x < 0.6) {
                        // Midnight green (original team color)
                        float intensity = min(1.0, hsl.z * 2.5);
                        if (isHelmetArea) {
                            outColor = vec4(secondaryColor * intensity, pix.a);
                        } else {
                            outColor = vec4(primaryColor * intensity, pix.a);
                        }
                    } else {
                        // Default to jersey
                        float intensity = min(1.0, hsl.z * 2.5);
                        outColor = vec4(primaryColor * intensity, pix.a);
                    }
                    
                    return outColor * color;
                }
            ]]
        end

        local jColor = (teamColors and teamColors.primary) or {0.06, 0.24, 0.15}
        local hColor = (teamColors and teamColors.secondary) or {0.06, 0.24, 0.15}
        local skinColor = {0.85, 0.65, 0.45}
        local visorColor = {0.1, 0.1, 0.1, 0.85}
        local pColor = {0.9, 0.9, 0.9, 1}
        
        if profile then
            local PlayerVisualProfile = require("src.data.player_visual_profile")
            if type(profile) ~= "table" then profile = PlayerVisualProfile end
            
            if profile.skinTone then skinColor = PlayerVisualProfile.skinTones[profile.skinTone] or skinColor
            elseif profile.getSkinColor then skinColor = profile.getSkinColor() end
            
            if profile.visor == "dark" then visorColor = {0.08, 0.08, 0.08, 0.95}
            elseif profile.visor == "gold_mirror" then visorColor = {1.0, 0.8, 0.0, 0.85}
            elseif profile.visor == "clear" then visorColor = {0,0,0,0}
            elseif profile.visor == "iridescent" then
                local t = love.timer.getTime()
                visorColor = {0.5 + 0.5*math.sin(t*2), 0.5 + 0.5*math.sin(t*2+2.1), 0.5 + 0.5*math.sin(t*2+4.2), 0.8}
            end
            
            if profile.primaryColor then jColor = profile.primaryColor end
            if profile.shellColor then hColor = profile.shellColor end
        end
        
        local cx = -img:getWidth() / 2
        local cy = -img:getHeight() + 4
        
        love.graphics.setShader(AssetManager._modularShader)
        AssetManager._modularShader:send("primaryColor", {jColor[1], jColor[2], jColor[3]})
        AssetManager._modularShader:send("secondaryColor", {hColor[1], hColor[2], hColor[3]})
        AssetManager._modularShader:send("pantsColor", {pColor[1], pColor[2], pColor[3]})
        AssetManager._modularShader:send("skinColor", {skinColor[1], skinColor[2], skinColor[3]})
        AssetManager._modularShader:send("visorColor", visorColor)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, cx, cy)
        love.graphics.setShader()
    end
    
    love.graphics.setLineWidth(1)
    love.graphics.pop()
end


-- ─── Bust Portrait Renderer ─────────────────────────────────────
-- Renders head/shoulders closeup for Player Editor and Lineup Editor
function AssetManager.drawRetroPlayerBust(x, y, jerseyColor, helmetColor, profile, scale)
    local PlayerVisualProfile = require("src.data.player_visual_profile")
    scale = scale or 6
    
    local skinColor = {0.85, 0.65, 0.45}
    local visorColor = {0.7, 0.85, 1.0, 0.5}
    local maskColor = {0.75, 0.75, 0.75}
    
    if profile then
        if profile.skinTone then
            skinColor = PlayerVisualProfile.skinTones[profile.skinTone] or skinColor
        elseif profile.getSkinColor then
            skinColor = profile.getSkinColor()
        end
        if profile.visor == "dark" then visorColor = {0.08, 0.08, 0.08, 0.95}
        elseif profile.visor == "gold_mirror" then visorColor = {1.0, 0.8, 0.0, 0.85}
        elseif profile.visor == "iridescent" then
            local t = love.timer.getTime()
            visorColor = {0.5 + 0.5*math.sin(t*2), 0.5 + 0.5*math.sin(t*2+2.1), 0.5 + 0.5*math.sin(t*2+4.2), 0.8}
        end
        maskColor = profile.maskColor or maskColor
    end
    
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale, scale)
    
    -- Neck
    love.graphics.setColor(skinColor)
    love.graphics.rectangle("fill", -1, 2, 3, 3)
    
    -- Shoulder Pads / Jersey Collar
    love.graphics.setColor(jerseyColor)
    love.graphics.rectangle("fill", -6, 4, 13, 5, 1, 1)
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("fill", -5, 4, 6, 5)
    if helmetColor then
        love.graphics.setColor(helmetColor)
        love.graphics.rectangle("fill", -6, 4, 13, 2)
    end
    
    -- Hair behind helmet
    if profile and profile.hairStyle and profile.hairStyle ~= "none" then
        love.graphics.setColor(profile.hairColor or {0.1, 0.1, 0.1})
        if profile.hairStyle == "dreads" then
            love.graphics.rectangle("fill", -5, -4, 2, 8)
            love.graphics.rectangle("fill", -3, -2, 2, 7)
        elseif profile.hairStyle == "afro" then
            love.graphics.circle("fill", 0, -8, 6)
        elseif profile.hairStyle == "braids" then
            love.graphics.rectangle("fill", -5, -5, 2, 10)
            love.graphics.rectangle("fill", -3, -4, 2, 9)
        elseif profile.hairStyle == "mullet" then
            love.graphics.rectangle("fill", -4, -5, 9, 2)
            love.graphics.rectangle("fill", -5, -3, 2, 10)
        else -- "short"
            love.graphics.rectangle("fill", -4, -7, 9, 3)
        end
    end
    
    -- Helmet shell
    local fm = profile and profile.facemask or 5
    if profile and profile.helmetStyle == "vintage" then
        love.graphics.setColor(0.55, 0.27, 0.07)
        love.graphics.rectangle("fill", -4, -7, 9, 9, 3, 3)
    else
        love.graphics.setColor(helmetColor)
        love.graphics.rectangle("fill", -4, -7, 9, 9, 2, 2)
        love.graphics.setColor(jerseyColor)
        love.graphics.rectangle("fill", -1, -7, 2, 9) -- Center stripe
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.rectangle("fill", -3, -7, 3, 3) -- Shine
    end
    
    -- Face
    love.graphics.setColor(skinColor)
    love.graphics.rectangle("fill", 2, -4, 4, 5)
    
    -- Eye black
    if profile and profile.eyeBlack and profile.eyeBlack ~= "clean" then
        love.graphics.setColor(0.1, 0.1, 0.1)
        if profile.eyeBlack == "single_bar" then
            love.graphics.rectangle("fill", 3, -3, 3, 1)
        elseif profile.eyeBlack == "warpaint" then
            love.graphics.rectangle("fill", 3, -3, 3, 2)
        elseif profile.eyeBlack == "cross" then
            love.graphics.rectangle("fill", 4, -4, 1, 3)
            love.graphics.rectangle("fill", 3, -3, 3, 1)
        end
    end
    
    -- Earrings
    local earCount = profile and profile.earrings or 0
    if earCount > 0 then
        love.graphics.setColor(1.0, 0.84, 0.0)
        for ei = 1, math.min(earCount, 3) do
            love.graphics.rectangle("fill", -4, -2 + (ei - 1) * 2, 1.5, 1.5)
        end
    end
    
    -- Visor
    love.graphics.setColor(visorColor)
    love.graphics.rectangle("fill", 2, -5, 5, 3)
    
    -- Facemask
    if not profile or profile.helmetStyle ~= "vintage" then
        love.graphics.setColor(maskColor)
        if fm == 1 then
            love.graphics.rectangle("fill", 2, -1, 5, 1)
        elseif fm == 2 then
            love.graphics.rectangle("fill", 2, -2, 5, 1)
            love.graphics.rectangle("fill", 2, 0, 5, 1)
        elseif fm == 3 then
            love.graphics.rectangle("fill", 2, -3, 5, 1)
            love.graphics.rectangle("fill", 2, -1, 5, 1)
            love.graphics.rectangle("fill", 2, 1, 5, 1)
        elseif fm == 4 then
            love.graphics.rectangle("fill", 5, -4, 2, 6)
            love.graphics.rectangle("fill", 2, 0, 5, 1)
            love.graphics.rectangle("fill", 2, -2, 5, 1)
            love.graphics.rectangle("fill", 2, -4, 5, 1)
        elseif fm == 5 then
            love.graphics.rectangle("fill", 5, -3, 2, 4)
            love.graphics.rectangle("fill", 2, 0, 4, 1)
        elseif fm == 6 then
            love.graphics.rectangle("fill", 4, -4, 3, 6)
            love.graphics.setColor(0, 0, 0, 0.4)
            love.graphics.rectangle("fill", 5, -3, 1, 4)
        end
    end
    
    love.graphics.pop()
end

return AssetManager

