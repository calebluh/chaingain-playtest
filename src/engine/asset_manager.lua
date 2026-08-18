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

    if not normalized:match("^images/") and not normalized:match("^cards/") and not normalized:match("^blinds/") and not normalized:match("^players/") and not normalized:match("^ui/") then
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
end

function AssetManager.getImage(relativePath)
    if images[relativePath] ~= nil then
        return images[relativePath]
    end

    local candidatePaths = buildAssetCandidates(relativePath)
    for _, fullPath in ipairs(candidatePaths) do
        if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(fullPath) then
            local ok, img = pcall(love.graphics.newImage, fullPath)
            if ok and img then
                img:setFilter("nearest", "nearest")
                images[relativePath] = img
                return img
            end
        end
    end

    images[relativePath] = false
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

function AssetManager.drawRetroPlayer(x, y, jerseyColor, pantsColor, helmetColor, vx, vy, isOffense, time, isTackled, profileData, scaleOverride)
    vx = vx or 0
    vy = vy or 0
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
    local visorColor = {0.7, 0.85, 1.0, 0.5}
    local torsoW, torsoH = 9, 11
    
    if profile then
        if profile.skinTone then
            skinColor = PlayerVisualProfile.skinTones[profile.skinTone] or skinColor
        elseif profile.getSkinColor then
            skinColor = profile.getSkinColor()
        end
        
        if profile.visor then
            if profile.visor == "dark" then visorColor = {0.08, 0.08, 0.08, 0.95}
            elseif profile.visor == "gold_mirror" then visorColor = {1.0, 0.8, 0.0, 0.85}
            elseif profile.visor == "iridescent" then visorColor = {0.8, 0.3, 0.9, 0.8}
            end
        end
        
        local arch = profile.archetype or "stocky"
        if arch == "lean" then torsoW, torsoH = 7, 11
        elseif arch == "heavy" then torsoW, torsoH = 11, 10
        end
        if profile.jerseyCut == "cropped" then
            torsoH = torsoH - 2
        end
        
        jerseyColor = (profile.useCustomJersey and profile.primaryColor) or jerseyColor
        helmetColor = (profile.useCustomHelmet and profile.shellColor) or helmetColor
    end
    
    love.graphics.push()
    love.graphics.translate(x, y)
    if scaleOverride then love.graphics.scale(scaleOverride, scaleOverride) end
    
    if state == "tackled" then
        love.graphics.rotate(math.pi / 2)
        love.graphics.translate(0, -6)
    end
    
    local dir = (state == "run" or state == "walk") and (vx > 0 and 1 or -1) or (isOffense and 1 or -1)
    love.graphics.scale(dir, 1)
    
    -- Animation Offsets
    local legOffset, armOffset, bobY = 0, 0, 0
    if state == "run" then
        legOffset = math.sin(time * 15) * 6
        armOffset = math.cos(time * 15) * 5
        bobY = math.abs(math.sin(time * 15)) * -1.5
    elseif state == "walk" then
        legOffset = math.sin(time * 8) * 3
        armOffset = math.cos(time * 8) * 2
        bobY = math.abs(math.sin(time * 8)) * -0.5
    elseif state == "idle" then
        bobY = math.sin(time * 4) * 0.5
    end
    
    love.graphics.translate(0, bobY)
    
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", 0, 14 - bobY, torsoW * 0.8, 2)
    
    local backLegX = -math.floor(torsoW/2) + 1 + legOffset
    local frontLegX = 1 - legOffset
    local backArmX = -math.floor(torsoW/2) - 1 - armOffset
    local frontArmX = math.floor(torsoW/2) - 1 + armOffset
    
    local armJerseyColor = (profile and profile.jerseyCut == "sleeveless") and skinColor or jerseyColor
    local handGearColor = profile and profile.handGearColor or {1, 1, 1}
    local cleatH, cleatY = 2, 11
    if profile and profile.cleats == "mid" then cleatH = 3; cleatY = 10
    elseif profile and profile.cleats == "high" then cleatH = 4; cleatY = 9 end

    -- Back Arm
    love.graphics.setColor(armJerseyColor[1]*0.8, armJerseyColor[2]*0.8, armJerseyColor[3]*0.8)
    love.graphics.rectangle("fill", backArmX, -4, 3.5, 6)
    if profile and profile.armGear and profile.armGear ~= "none" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", backArmX, -2, 3.5, 3)
    end
    if profile and profile.handGear and profile.handGear ~= "none" then
        love.graphics.setColor(handGearColor[1]*0.8, handGearColor[2]*0.8, handGearColor[3]*0.8)
    else
        love.graphics.setColor(skinColor[1]*0.8, skinColor[2]*0.8, skinColor[3]*0.8)
    end
    love.graphics.rectangle("fill", backArmX, 2, 3.5, 3)
    
    -- Back Leg (Pants)
    love.graphics.setColor(pantsColor[1]*0.8, pantsColor[2]*0.8, pantsColor[3]*0.8)
    love.graphics.rectangle("fill", backLegX, 5, 3.5, 6)
    if profile and profile.calfSleeves and profile.calfSleeves ~= "none" then
        if profile.calfSleeves == "black" then love.graphics.setColor(0.15, 0.15, 0.15)
        elseif profile.calfSleeves == "team_primary" then love.graphics.setColor(jerseyColor[1]*0.8, jerseyColor[2]*0.8, jerseyColor[3]*0.8)
        else love.graphics.setColor(0.8, 0.8, 0.8) end
        love.graphics.rectangle("fill", backLegX, 8, 3.5, 3)
    end
    love.graphics.setColor(profile and profile.cleatsColor or {0.1, 0.1, 0.1})
    love.graphics.rectangle("fill", backLegX + 1, cleatY, 3.5, cleatH)
    
    -- Hair (Back of helmet)
    if profile and profile.hairStyle and profile.hairStyle ~= "none" then
        love.graphics.setColor(profile.hairColor or {0.1, 0.1, 0.1})
        if profile.hairStyle == "dreads" then
            love.graphics.rectangle("fill", -5, -8, 2, 6)
            love.graphics.rectangle("fill", -3, -6, 2, 5)
            love.graphics.rectangle("fill", -6, -7, 2, 4)
        elseif profile.hairStyle == "afro" then
            love.graphics.circle("fill", -1, -16, 5)
        elseif profile.hairStyle == "braids" then
            love.graphics.rectangle("fill", -5, -9, 2, 8)
            love.graphics.rectangle("fill", -3, -8, 2, 7)
        elseif profile.hairStyle == "mullet" then
            love.graphics.rectangle("fill", -4, -8, 8, 2)
            love.graphics.rectangle("fill", -5, -6, 2, 8)
        else -- "short"
            love.graphics.rectangle("fill", -4, -14, 8, 3)
        end
    end
    
    -- Torso (Jersey)
    love.graphics.setColor(jerseyColor)
    love.graphics.rectangle("fill", -math.floor(torsoW/2), -5, torsoW, torsoH, 1, 1)
    love.graphics.setColor(1, 1, 1, 0.15) -- Jersey highlight
    love.graphics.rectangle("fill", -math.floor(torsoW/2) + 1, -5, torsoW/2, torsoH)
    if helmetColor then
        love.graphics.setColor(helmetColor)
        love.graphics.rectangle("fill", -math.floor(torsoW/2), -5, torsoW, 2) -- Collar trim
    end
    
    -- Jersey Number (3x5 pixel digit font)
    local jNum = profile and profile.jerseyNumber
    if jNum and jNum > 0 and torsoW >= 8 then
        local digits = {
            [0] = {{1,1,1},{1,0,1},{1,0,1},{1,0,1},{1,1,1}},
            [1] = {{0,1,0},{1,1,0},{0,1,0},{0,1,0},{1,1,1}},
            [2] = {{1,1,1},{0,0,1},{1,1,1},{1,0,0},{1,1,1}},
            [3] = {{1,1,1},{0,0,1},{1,1,1},{0,0,1},{1,1,1}},
            [4] = {{1,0,1},{1,0,1},{1,1,1},{0,0,1},{0,0,1}},
            [5] = {{1,1,1},{1,0,0},{1,1,1},{0,0,1},{1,1,1}},
            [6] = {{1,1,1},{1,0,0},{1,1,1},{1,0,1},{1,1,1}},
            [7] = {{1,1,1},{0,0,1},{0,0,1},{0,1,0},{0,1,0}},
            [8] = {{1,1,1},{1,0,1},{1,1,1},{1,0,1},{1,1,1}},
            [9] = {{1,1,1},{1,0,1},{1,1,1},{0,0,1},{1,1,1}},
        }
        local numStr = tostring(jNum)
        local totalW = #numStr * 4 - 1
        local startX = -math.floor(totalW / 2)
        love.graphics.setColor(1, 1, 1, 0.85)
        for ci = 1, #numStr do
            local d = tonumber(numStr:sub(ci, ci))
            local glyph = digits[d]
            if glyph then
                local ox = startX + (ci - 1) * 4
                for row = 1, 5 do
                    for col = 1, 3 do
                        if glyph[row][col] == 1 then
                            love.graphics.rectangle("fill", ox + col - 2, -3 + row, 1, 1)
                        end
                    end
                end
            end
        end
    end
    
    -- Front Leg
    love.graphics.setColor(pantsColor)
    love.graphics.rectangle("fill", frontLegX, 5, 3.5, 6)
    if profile and profile.calfSleeves and profile.calfSleeves ~= "none" then
        if profile.calfSleeves == "black" then love.graphics.setColor(0.2, 0.2, 0.2)
        elseif profile.calfSleeves == "team_primary" then love.graphics.setColor(jerseyColor)
        else love.graphics.setColor(1, 1, 1) end
        love.graphics.rectangle("fill", frontLegX, 8, 3.5, 3)
    end
    love.graphics.setColor(profile and profile.cleatsColor or {0.1, 0.1, 0.1})
    love.graphics.rectangle("fill", frontLegX + 1, cleatY, 3.5, cleatH)
    
    -- Helmet
    local fm = profile and profile.facemask or 5
    if profile and profile.helmetStyle == "vintage" then
        love.graphics.setColor(0.55, 0.27, 0.07) -- Leather
        love.graphics.rectangle("fill", -4, -14, 8, 8, 3, 3)
    else
        love.graphics.setColor(helmetColor)
        love.graphics.rectangle("fill", -4, -14, 8, 8, 2, 2)
        love.graphics.setColor(jerseyColor)
        love.graphics.rectangle("fill", -1, -14, 2, 8) -- Center Helmet Stripe
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.rectangle("fill", -3, -14, 3, 3) -- Specular Shine
    end
    
    -- Face & Visor area
    love.graphics.setColor(skinColor)
    love.graphics.rectangle("fill", 1, -11, 4, 4)
    
    if profile and profile.eyeBlack and profile.eyeBlack ~= "clean" then
        love.graphics.setColor(0.1, 0.1, 0.1)
        if profile.eyeBlack == "single_bar" then
            love.graphics.rectangle("fill", 2, -10, 3, 1)
        elseif profile.eyeBlack == "warpaint" then
            love.graphics.rectangle("fill", 2, -10, 3, 2)
        elseif profile.eyeBlack == "cross" then
            love.graphics.rectangle("fill", 3, -11, 1, 3)
            love.graphics.rectangle("fill", 2, -10, 3, 1)
        end
    end
    
    -- Earrings
    local earCount = profile and profile.earrings or 0
    if earCount > 0 then
        love.graphics.setColor(1.0, 0.84, 0.0) -- Gold studs
        for ei = 1, math.min(earCount, 3) do
            love.graphics.rectangle("fill", -4, -9 + (ei - 1) * 2, 1.5, 1.5)
        end
    end
    
    love.graphics.setColor(visorColor)
    love.graphics.rectangle("fill", 1, -12, 4.5, 3)
    
    -- Facemask (6 styles)
    if not profile or profile.helmetStyle ~= "vintage" then
        love.graphics.setColor(profile and profile.maskColor or {0.7, 0.7, 0.7})
        if fm == 1 then
            -- Single bar
            love.graphics.rectangle("fill", 1, -8, 5, 1)
        elseif fm == 2 then
            -- Classic 2-bar
            love.graphics.rectangle("fill", 1, -9, 4, 1)
            love.graphics.rectangle("fill", 1, -7, 4, 1)
        elseif fm == 3 then
            -- 3-bar cage
            love.graphics.rectangle("fill", 1, -10, 5, 1)
            love.graphics.rectangle("fill", 1, -8, 5, 1)
            love.graphics.rectangle("fill", 1, -6, 5, 1)
        elseif fm == 4 then
            -- Full cage
            love.graphics.rectangle("fill", 4, -11, 2, 5)
            love.graphics.rectangle("fill", 1, -7, 5, 1)
            love.graphics.rectangle("fill", 1, -9, 5, 1)
            love.graphics.rectangle("fill", 1, -11, 5, 1)
        elseif fm == 5 then
            -- Speedflex open
            love.graphics.rectangle("fill", 4, -10, 2, 4)
            love.graphics.rectangle("fill", 1, -7, 4, 1)
        elseif fm == 6 then
            -- Bull-rush closed (lineman)
            love.graphics.rectangle("fill", 3, -11, 3, 6)
            love.graphics.setColor(0, 0, 0, 0.4)
            love.graphics.rectangle("fill", 4, -10, 1, 4)
        end
    end
    
    -- Front Arm
    love.graphics.setColor(armJerseyColor)
    love.graphics.rectangle("fill", frontArmX, -4, 3.5, 6)
    if profile and profile.armGear and profile.armGear ~= "none" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", frontArmX, -2, 3.5, 3)
    end
    if profile and profile.handGear and profile.handGear ~= "none" then
        love.graphics.setColor(handGearColor)
    else
        love.graphics.setColor(skinColor)
    end
    love.graphics.rectangle("fill", frontArmX, 2, 3.5, 3)
    
    -- Tattoos
    if profile and profile.tattoos then
        love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
        love.graphics.rectangle("fill", frontArmX + 1, 3, 1.5, 1.5)
    end
    
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

