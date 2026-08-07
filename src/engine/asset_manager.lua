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
    
    local fullPath = "assets/images/" .. relativePath
    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(fullPath) then
        local ok, img = pcall(love.graphics.newImage, fullPath)
        if ok and img then
            images[relativePath] = img
            return img
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
        love.graphics.setColor(0.08, 0.16, 0.12, 0.9)
        love.graphics.rectangle("fill", 0, 0, w, h, 6, 6)
        
        love.graphics.setColor(1, 1, 1, 0.15)
        for lx = 10, w - 10, 20 do
            love.graphics.line(lx, 5, lx, h - 5)
        end
        for ly = 10, h - 10, 20 do
            love.graphics.line(5, ly, w - 5, ly)
        end
        
        love.graphics.setLineWidth(2)
        if playType == "Run" then
            love.graphics.setColor(0.2, 0.8, 1, 0.9)
            love.graphics.line(w/2, h - 15, w/2, h/2, w/2 + 20, h/2 - 20)
            love.graphics.circle("fill", w/2 + 20, h/2 - 20, 4)
        elseif playType == "Short Pass" then
            love.graphics.setColor(1, 0.8, 0.2, 0.9)
            love.graphics.line(w/4, h - 15, w/4, h/2, w/2 + 15, h/2)
            love.graphics.line(3*w/4, h - 15, 3*w/4, h/2 + 10, w/2 - 15, h/2 + 10)
        elseif playType == "Deep Pass" then
            love.graphics.setColor(1, 0.3, 0.3, 0.9)
            love.graphics.line(w/4, h - 15, w/4, 15)
            love.graphics.line(3*w/4, h - 15, 3*w/4, 15)
            love.graphics.polygon("fill", w/4, 10, w/4 - 5, 20, w/4 + 5, 20)
            love.graphics.polygon("fill", 3*w/4, 10, 3*w/4 - 5, 20, 3*w/4 + 5, 20)
        else
            love.graphics.setColor(0.8, 0.3, 1, 0.9)
            love.graphics.line(w/2, h - 15, w/2 - 20, h/2 + 10, w/2 + 30, 20)
        end
        love.graphics.setLineWidth(1)
        
        love.graphics.setColor(1, 1, 1, 0.35)
        local font = AssetManager.getFont(10)
        love.graphics.setFont(font)
        love.graphics.printf("[ART PLACEHOLDER]\ncard_" .. string.lower(string.gsub(playName, "%s+", "_")) .. ".png", 2, h/2 - 12, w - 4, "center")
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
            -- Custom Neon Background
            love.graphics.setColor(0.08, 0.15, 0.25, 1)
            love.graphics.rectangle("fill", 0, 0, w, h, 6, 6)
            
            -- Draw jersey shoulders
            love.graphics.setColor(0.0, 0.45, 0.8)
            love.graphics.rectangle("fill", w/2 - 22, h/2 + 10, 44, 25, 6, 6)
            
            -- Neck / Face opening
            love.graphics.setColor(0.85, 0.65, 0.45)
            love.graphics.rectangle("fill", w/2 - 7, h/2 - 2, 14, 15)
            
            -- Helmet base
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
                -- Modern
                love.graphics.circle("fill", w/2, h/2 - 10, 18)
                love.graphics.setColor(0.15, 0.15, 0.15)
                love.graphics.rectangle("fill", w/2 + 2, h/2 - 5, 15, 10, 2, 2)
            end
            
            -- Draw Visor
            local vColor = {0.3, 0.75, 1.0, 0.7}
            if MyPlayerProfile.visorTint == "Dark" then
                vColor = {0.08, 0.08, 0.08, 0.95}
            elseif MyPlayerProfile.visorTint == "Gold" then
                vColor = {1.0, 0.8, 0.0, 0.85}
            end
            love.graphics.setColor(vColor)
            love.graphics.rectangle("fill", w/2 + 1, h/2 - 13, 14, 7, 2, 2)
            
            -- Text Label
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", 4, h - 22, w - 8, 18, 3, 3)
            love.graphics.setColor(0.0, 0.76, 1.0)
            local font = AssetManager.getFont(10)
            love.graphics.setFont(font)
            love.graphics.printf("MYPLAYER", 4, h - 19, w - 8, "center")
        else
            if isStar then
                love.graphics.setColor(0.3, 0.25, 0.05, 1)
            else
                love.graphics.setColor(0.12, 0.16, 0.22, 1)
            end
            love.graphics.rectangle("fill", 0, 0, w, h, 6, 6)
            
            love.graphics.setColor(0.3, 0.4, 0.5, 0.6)
            love.graphics.circle("fill", w/2, h/2 - 5, math.min(w, h) * 0.25)
            love.graphics.rectangle("fill", w/2 - 15, h/2 + 5, 30, 20, 4, 4)
            
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", 4, 4, 32, 18, 3, 3)
            love.graphics.setColor(1, 0.84, 0)
            local font = AssetManager.getFont(10)
            love.graphics.setFont(font)
            love.graphics.printf(position, 4, 7, 32, "center")
            
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.printf("PORTRAIT", 0, h - 20, w, "center")
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
