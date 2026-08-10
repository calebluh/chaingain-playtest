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

function AssetManager.drawRetroPlayer(x, y, jerseyColor, pantsColor, helmetColor, vx, vy, isOffense, time, isTackled, isMyPlayer, scaleOverride)
    vx = vx or 0
    vy = vy or 0
    local speed = math.sqrt(vx*vx + vy*vy)
    local isMoving = speed > 10 and not isTackled
    
    local PlayerVisualProfile = require("src.data.player_visual_profile")
    local skinColor = {0.85, 0.65, 0.45}
    local visorColor = {0.7, 0.85, 1.0, 0.5}
    local torsoW, torsoH = 8, 10
    
    if isMyPlayer then
        skinColor = PlayerVisualProfile.getSkinColor()
        visorColor = PlayerVisualProfile.getVisorColor()
        local scale = PlayerVisualProfile.getArchetypeScale()
        torsoW = scale.torsoW
        torsoH = scale.torsoH
        jerseyColor = PlayerVisualProfile.primaryColor or jerseyColor
        helmetColor = PlayerVisualProfile.shellColor or helmetColor
    end
    
    love.graphics.push()
    love.graphics.translate(x, y)
    
    if scaleOverride then
        love.graphics.scale(scaleOverride, scaleOverride)
    end
    
    if isTackled then
        love.graphics.rotate(math.pi / 2)
        love.graphics.translate(0, -6)
    end
    
    local dir = 1
    if isMoving then
        dir = vx > 0 and 1 or -1
    else
        dir = isOffense and 1 or -1
    end
    love.graphics.scale(dir, 1)
    
    local legOffset = 0
    local armOffset = 0
    if isMoving then
        legOffset = math.sin(time * 7) * 5
        armOffset = math.cos(time * 7) * 3
    end
    
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", 0, 12, torsoW * 0.75, 2)
    
    -- Legs (Pants / Socks)
    love.graphics.setColor(pantsColor)
    love.graphics.rectangle("fill", -math.floor(torsoW/2) + 1 + legOffset * 0.5, 4, 3, 6)
    love.graphics.rectangle("fill", 1 - legOffset * 0.5, 4, 3, 6)
    
    -- Cleats / Shoes
    local cleatColor = (isMyPlayer and PlayerVisualProfile.cleatsColor) or {1, 1, 1}
    love.graphics.setColor(cleatColor)
    love.graphics.rectangle("fill", -math.floor(torsoW/2) + 1 + legOffset * 0.5 + (dir > 0 and 1 or -1), 10, 3, 2)
    love.graphics.rectangle("fill", 1 - legOffset * 0.5 + (dir > 0 and 1 or -1), 10, 3, 2)
    
    -- Torso (Jersey)
    love.graphics.setColor(jerseyColor)
    love.graphics.rectangle("fill", -math.floor(torsoW/2), -6, torsoW, torsoH)
    
    -- Arms
    love.graphics.setColor(jerseyColor)
    love.graphics.rectangle("fill", -math.floor(torsoW/2) - 2 - armOffset * 0.5, -4, 3, 6)
    love.graphics.rectangle("fill", math.floor(torsoW/2) - 1 + armOffset * 0.5, -4, 3, 6)
    
    if isMyPlayer and PlayerVisualProfile.armGear ~= "none" then
        love.graphics.setColor(PlayerVisualProfile.armGearColor or {1, 1, 1})
        love.graphics.rectangle("fill", -math.floor(torsoW/2) - 2 - armOffset * 0.5, -2, 3, 2)
        love.graphics.rectangle("fill", math.floor(torsoW/2) - 1 + armOffset * 0.5, -2, 3, 2)
    end
    
    -- Hands / Gloves
    if isMyPlayer and PlayerVisualProfile.handGear ~= "none" then
        love.graphics.setColor(PlayerVisualProfile.handGearColor or {1, 1, 1})
    else
        love.graphics.setColor(skinColor)
    end
    love.graphics.rectangle("fill", -math.floor(torsoW/2) - 2 - armOffset * 0.5, 2, 3, 2)
    love.graphics.rectangle("fill", math.floor(torsoW/2) - 1 + armOffset * 0.5, 2, 3, 2)
    
    -- Helmet
    love.graphics.setColor(helmetColor)
    love.graphics.rectangle("fill", -3.5, -13, 7, 7)
    
    -- Helmet stripe
    if isMyPlayer and PlayerVisualProfile.stripeColor then
        love.graphics.setColor(PlayerVisualProfile.stripeColor)
        love.graphics.rectangle("fill", -1, -13, 2, 7)
    end
    
    -- Facemask & Visor
    love.graphics.setColor(isMyPlayer and PlayerVisualProfile.maskColor or {0.7, 0.7, 0.7})
    love.graphics.rectangle("fill", 2, -10, 3, 3)
    
    love.graphics.setColor(visorColor)
    love.graphics.rectangle("fill", 2, -12, 4, 3, 1, 1)
    
    love.graphics.pop()
end

return AssetManager
