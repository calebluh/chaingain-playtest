-- src/engine/asset_manager.lua
local AssetManager = {}

local images = {}
local fontCache = {}

function AssetManager.init()
    images = {}
    fontCache = {}
end

function AssetManager.getImage(relativePath)
    if images[relativePath] ~= nil then
        return images[relativePath]
    end
    
    local candidatePaths = {
        "assets/images/" .. relativePath,
        "assets/" .. relativePath
    }
    
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
            local MyPlayerProfile = require("src.data.myplayer_profile")
            love.graphics.setColor(0.08, 0.15, 0.25, 1)
            love.graphics.rectangle("fill", 0, 0, w, h, 6, 6)
            
            love.graphics.setColor(0.0, 0.45, 0.8)
            love.graphics.rectangle("fill", w/2 - 22, h/2 + 10, 44, 25, 6, 6)
            
            love.graphics.setColor(0.85, 0.65, 0.45)
            love.graphics.rectangle("fill", w/2 - 7, h/2 - 2, 14, 15)
            
            love.graphics.setColor(0.0, 0.58, 1.0)
            
            local hStyle = MyPlayerProfile.helmetStyle or "Modern"
            if hStyle == "Classic" then
                love.graphics.circle("fill", w/2, h/2 - 10, 18)
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.setLineWidth(2)
                love.graphics.line(w/2 + 2, h/2 - 5, w/2 + 18, h/2 + 5)
                love.graphics.line(w/2 + 2, h/2 - 2, w/2 + 18, h/2 + 5)
                love.graphics.setLineWidth(1)
            elseif hStyle == "Speed" then
                love.graphics.circle("fill", w/2, h/2 - 10, 18)
                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.arc("fill", w/2, h/2 - 10, 18, -math.pi/2 - 0.2, -math.pi/2 + 0.2)
            else
                love.graphics.circle("fill", w/2, h/2 - 10, 18)
                love.graphics.setColor(0.15, 0.15, 0.15)
                love.graphics.rectangle("fill", w/2 + 2, h/2 - 5, 15, 10, 2, 2)
            end
            
            local vColor = {0.3, 0.75, 1.0, 0.7}
            if MyPlayerProfile.visorTint == "Dark" then
                vColor = {0.08, 0.08, 0.08, 0.95}
            elseif MyPlayerProfile.visorTint == "Gold" then
                vColor = {1.0, 0.8, 0.0, 0.85}
            end
            love.graphics.setColor(vColor)
            love.graphics.rectangle("fill", w/2 + 1, h/2 - 13, 14, 7, 2, 2)
            
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", 4, h - 22, w - 8, 18, 3, 3)
            love.graphics.setColor(0.0, 0.76, 1.0)
            local font = AssetManager.getFont(10)
            love.graphics.setFont(font)
            love.graphics.printf("MYPLAYER", 4, h - 19, w - 8, "center")
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

return AssetManager
