-- src/ui/card_render.lua
local AssetManager = require("src.engine.asset_manager")
local CardRender = {}

-- Color Palette
local C_SLATE_CARD = {0.094, 0.11, 0.141} -- #181C24
local C_BACK_CARD = {0.07, 0.086, 0.122} -- #12161F
local C_BORDER_NORMAL = {0.227, 0.259, 0.322} -- #3A4252
local C_BORDER_SELECTED = {0.0, 0.76, 1.0} -- #00C3FF
local C_NEON_GREEN = {0.18, 0.72, 0.45} -- #2EB872
local C_NEON_CYAN = {0.0, 0.76, 1.0} -- #00C3FF
local C_NEON_YELLOW = {1.0, 0.84, 0.0} -- #FFD700
local C_NEON_PURPLE = {0.7, 0.3, 1.0}
local C_CHIP_BLUE = {0.0, 0.58, 1.0} -- Base Yards pill color
local C_MULT_RED = {1.0, 0.3, 0.3} -- Drive Momentum pill color

local function drawShadowText(text, x, y, r, g, b, scale, align, limit)
    scale = scale or 1
    love.graphics.setColor(0, 0, 0, 0.95)
    if align and limit then
        love.graphics.printf(text, x + 1, y + 1, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x + 1, y + 1, 0, scale, scale)
    end
    
    love.graphics.setColor(r or 1, g or 1, b or 1, 1)
    if align and limit then
        love.graphics.printf(text, x, y, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x, y, 0, scale, scale)
    end
end

function CardRender.drawPlayCard(x, y, card, isSelected, time)
    love.graphics.push()
    love.graphics.translate(x, y)
    
    local w, h = 130, 175
    local cx, cy = -w/2, -h/2
    
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", cx + 4, cy + 4, w, h, 8, 8)
    
    if isSelected then
        love.graphics.setColor(C_BORDER_SELECTED)
        love.graphics.rectangle("fill", cx - 3, cy - 3, w + 6, h + 6, 10, 10)
    else
        love.graphics.setColor(C_BORDER_NORMAL)
        love.graphics.rectangle("fill", cx - 2, cy - 2, w + 4, h + 4, 8, 8)
    end
    
    love.graphics.setColor(C_SLATE_CARD)
    love.graphics.rectangle("fill", cx, cy, w, h, 6, 6)
    
    love.graphics.setColor(0.12, 0.15, 0.20, 1)
    love.graphics.rectangle("fill", cx, cy, w, 28, 6, 6)
    love.graphics.rectangle("fill", cx, cy + 22, w, 6)
    
    drawShadowText(card.name, cx + 6, cy + 4, 1, 1, 1, 0.95)
    drawShadowText(card.type:upper(), cx + 6, cy + 16, 0.7, 0.75, 0.8, 0.75)
    
    local frameX, frameY = cx + 8, cy + 32
    local frameW, frameH = w - 16, 90
    
    love.graphics.setColor(0.06, 0.08, 0.11, 1)
    love.graphics.rectangle("fill", frameX, frameY, frameW, frameH, 4, 4)
    
    -- Draw Enhancements Background Shading
    if card.enhancement == "Glass" then
        love.graphics.setColor(0.9, 0.9, 1.0, 0.4)
        love.graphics.rectangle("fill", frameX, frameY, frameW, frameH, 4, 4)
    elseif card.enhancement == "Steel" then
        love.graphics.setColor(0.6, 0.65, 0.7, 0.5)
        love.graphics.rectangle("fill", frameX, frameY, frameW, frameH, 4, 4)
    elseif card.enhancement == "Gold" then
        love.graphics.setColor(1.0, 0.84, 0.0, 0.3)
        love.graphics.rectangle("fill", frameX, frameY, frameW, frameH, 4, 4)
    elseif card.enhancement == "Stone" then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        love.graphics.rectangle("fill", frameX, frameY, frameW, frameH, 4, 4)
    end
    
    local img = card.name and AssetManager.getImage("cards/card_" .. string.lower(string.gsub(card.name, "%s+", "_")) .. ".png")
    if img then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, frameX, frameY, 0, frameW / img:getWidth(), frameH / img:getHeight())
    else
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.4, 0.45, 0.5, 0.6)
        for d = 0, 3 do
            local dx = frameX + 18 + (d * 24)
            local dy = frameY + 30
            love.graphics.line(dx-4, dy-4, dx+4, dy+4)
            love.graphics.line(dx-4, dy+4, dx+4, dy-4)
        end
        
        for o = 0, 3 do
            local ox = frameX + 18 + (o * 24)
            local oy = frameY + 65
            love.graphics.circle("line", ox, oy, 4)
        end
        
        if card.type == "Run" then
            love.graphics.setColor(C_NEON_GREEN)
            love.graphics.line(frameX + 42, frameY + 65, frameX + 42, frameY + 20, frameX + 66, frameY + 12)
            love.graphics.polygon("fill", frameX + 66, frameY + 12, frameX + 58, frameY + 10, frameX + 62, frameY + 18)
        elseif card.type == "Short Pass" or card.type == "Medium Pass" then
            love.graphics.setColor(card.type == "Short Pass" and C_NEON_CYAN or C_NEON_YELLOW)
            love.graphics.line(frameX + 18, frameY + 65, frameX + 18, frameY + 40, frameX + 80, frameY + 40)
            love.graphics.polygon("fill", frameX + 80, frameY + 40, frameX + 72, frameY + 35, frameX + 72, frameY + 45)
        elseif card.type == "Deep Pass" then
            love.graphics.setColor(C_NEON_YELLOW)
            love.graphics.line(frameX + 18, frameY + 65, frameX + 18, frameY + 10)
            love.graphics.line(frameX + 90, frameY + 65, frameX + 90, frameY + 10)
            love.graphics.polygon("fill", frameX + 18, frameY + 10, frameX + 13, frameY + 18, frameX + 23, frameY + 18)
            love.graphics.polygon("fill", frameX + 90, frameY + 10, frameX + 85, frameY + 18, frameX + 95, frameY + 18)
        elseif card.type == "Kick" then
            love.graphics.setLineWidth(2)
            love.graphics.setColor(C_NEON_YELLOW)
            love.graphics.line(frameX + 24, frameY + 20, frameX + 24, frameY + 55)
            love.graphics.line(frameX + 76, frameY + 20, frameX + 76, frameY + 55)
            love.graphics.line(frameX + 24, frameY + 45, frameX + 76, frameY + 45)
            love.graphics.line(frameX + 50, frameY + 45, frameX + 50, frameY + 75)
            love.graphics.setColor(C_BORDER_SELECTED)
            love.graphics.circle("fill", frameX + 50, frameY + 12, 3)
        elseif card.type == "Punt" then
            love.graphics.setLineWidth(2)
            love.graphics.setColor(C_NEON_CYAN)
            love.graphics.line(frameX + 18, frameY + 65, frameX + 50, frameY + 15)
            love.graphics.line(frameX + 50, frameY + 15, frameX + 82, frameY + 65)
            love.graphics.circle("line", frameX + 50, frameY + 15, 3)
        else
            love.graphics.setColor(C_NEON_PURPLE)
            love.graphics.line(frameX + 42, frameY + 65, frameX + 25, frameY + 50, frameX + 75, frameY + 15)
            love.graphics.polygon("fill", frameX + 75, frameY + 15, frameX + 66, frameY + 15, frameX + 73, frameY + 23)
        end
        love.graphics.setLineWidth(1)
    end
    
    local pillY = cy + 128
    love.graphics.setColor(C_CHIP_BLUE)
    love.graphics.rectangle("fill", cx + 6, pillY, 56, 38, 5, 5)
    drawShadowText(card.baseChips .. " YDS", cx + 6, pillY + 12, 1, 1, 1, 0.9, "center", 56)
    
    love.graphics.setColor(C_MULT_RED)
    love.graphics.rectangle("fill", cx + 68, pillY, 56, 38, 5, 5)
    drawShadowText("x" .. string.format("%.1f", card.baseMult) .. " MTM", cx + 68, pillY + 12, 1, 1, 1, 0.8, "center", 56)
    
    if card.enhancement then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", cx + 10, frameY - 14, 100, 20, 4, 4)
        local er, eg, eb = 1, 1, 1
        if card.enhancement == "Glass" then er, eg, eb = 0.9, 0.9, 1.0
        elseif card.enhancement == "Steel" then er, eg, eb = 0.7, 0.7, 0.8
        elseif card.enhancement == "Gold" then er, eg, eb = 1.0, 0.84, 0.0
        elseif card.enhancement == "Stone" then er, eg, eb = 0.6, 0.6, 0.6 end
        local dispName = card.enhancement:upper() .. " PLAY"
        if card.enhancement == "Glass" then dispName = "HIGH-OCTANE"
        elseif card.enhancement == "Steel" then dispName = "REINFORCED"
        elseif card.enhancement == "Gold" then dispName = "SPONSOR"
        elseif card.enhancement == "Stone" then dispName = "HEAVY STUD" end
        drawShadowText(dispName, cx + 10, frameY - 10, er, eg, eb, 0.9, "center", 100)
    end
    
    if card.seal then
        local sr, sg, sb = 1, 1, 1
        if card.seal == "Red" then sr, sg, sb = 1.0, 0.2, 0.2
        elseif card.seal == "Gold" then sr, sg, sb = 1.0, 0.84, 0.0
        elseif card.seal == "Blue" then sr, sg, sb = 0.0, 0.58, 1.0 end
        
        local sx, sy = cx + w - 16, cy + 30
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.circle("fill", sx, sy, 12)
        love.graphics.setColor(sr, sg, sb)
        love.graphics.circle("fill", sx, sy, 10)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("line", sx, sy, 10)
        love.graphics.setLineWidth(1)
        drawShadowText("D", sx - 5, sy - 8, 1, 1, 1, 1.2)
    end
    
    love.graphics.pop()
end

-- MUT Card Art & 3D Y-Axis Card Flip Inspector Engine
function CardRender.drawPlayerCard(x, y, player, isHovered, dt)
    if not player then return end
    if dt then player:update(dt) end
    
    love.graphics.push()
    love.graphics.translate(x, y + (player.jumpY or 0))
    
    local scaleX = math.abs(math.cos((player.flipProgress or 0) * math.pi))
    love.graphics.scale(math.max(0.05, scaleX), 1.0)
    
    local w, h = 110, 130
    local cx, cy = -w/2, -h/2
    
    -- Drop Shadow
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", cx + 3, cy + 3, w, h, 6, 6)
    
    if (player.flipProgress or 0) < 0.5 then
        -- -------------------------------------------------------------
        -- FRONT FACE: Madden Ultimate Team (MUT) Style
        -- -------------------------------------------------------------
        if player.edition == "Negative" then
            love.graphics.setColor(0.1, 0.1, 0.15, 1)
            love.graphics.rectangle("fill", cx - 4, cy - 4, w + 8, h + 8, 10, 10)
            love.graphics.setColor(0.9, 0.9, 1.0, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", cx - 3, cy - 3, w + 6, h + 6, 9, 9)
            love.graphics.setLineWidth(1)
        elseif player.edition == "Polychrome" then
            local r = (math.sin(love.timer.getTime() * 4) + 1) / 2
            local g = (math.sin(love.timer.getTime() * 4 + 2) + 1) / 2
            local b = (math.sin(love.timer.getTime() * 4 + 4) + 1) / 2
            love.graphics.setColor(r, g, b, 1)
            love.graphics.rectangle("fill", cx - 3, cy - 3, w + 6, h + 6, 9, 9)
        elseif player.edition == "Holographic" then
            love.graphics.setColor(0.7, 0.3, 1.0)
            love.graphics.rectangle("fill", cx - 3, cy - 3, w + 6, h + 6, 9, 9)
        elseif player.edition == "Foil" then
            love.graphics.setColor(0.2, 0.8, 1.0)
            love.graphics.rectangle("fill", cx - 3, cy - 3, w + 6, h + 6, 9, 9)
        else
            love.graphics.setColor(player.borderColor or C_BORDER_NORMAL)
            love.graphics.rectangle("fill", cx - 2, cy - 2, w + 4, h + 4, 8, 8)
        end
        
        -- Card Base Body
        love.graphics.setColor(player.cardColor or C_SLATE_CARD)
        love.graphics.rectangle("fill", cx, cy, w, h, 6, 6)
        
        -- Top-Left Badge: [80 OVR - QB]
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", cx + 3, cy + 3, w - 6, 22, 4, 4)
        drawShadowText(string.format("%d OVR - %s", player.overall, player.position), cx + 5, cy + 6, 1, 0.84, 0, 0.85)
        
        -- Edition Tag Badge if non-standard
        if player.edition and player.edition ~= "Standard" then
            drawShadowText(player.edition:upper(), cx + w - 46, cy + 6, 1, 1, 1, 0.7)
        end
        
        -- Center Frame: Player Silhouette
        local portraitX, portraitY = cx + 8, cy + 28
        local portraitW, portraitH = w - 16, 60
        love.graphics.setColor(0.06, 0.08, 0.12, 1)
        love.graphics.rectangle("fill", portraitX, portraitY, portraitW, portraitH, 4, 4)
        
        AssetManager.drawPlayerPortrait(portraitX, portraitY, portraitW, portraitH, player.name, player.position, player.overall >= 90, player.isMyPlayer)
        
        -- Bottom Banner: Player Name + Archetype Tag
        love.graphics.setColor(0.08, 0.1, 0.14, 0.95)
        love.graphics.rectangle("fill", cx + 3, cy + h - 38, w - 6, 35, 4, 4)
        
        drawShadowText(player.name:sub(1, 13), cx + 5, cy + h - 35, 1, 1, 1, 0.8)
        drawShadowText(player.archetypeTag or "STARTER", cx + 5, cy + h - 20, 0.2, 0.8, 1, 0.8)
        
        
        -- Edition Shaders (Overlays)
        if player.edition == "Foil" then
            -- Glossy sweeping white sheen
            local sweep = (love.timer.getTime() * 1.5) % 2.0
            love.graphics.setColor(1, 1, 1, 0.15)
            love.graphics.polygon("fill", cx, cy + (sweep * h) - 20, cx + w, cy + (sweep * h) - 60, cx + w, cy + (sweep * h) - 40, cx, cy + (sweep * h))
        elseif player.edition == "Holographic" then
            -- Shimmering scanline overlay
            local time = love.timer.getTime()
            for i = 0, h, 10 do
                local alpha = 0.1 + 0.1 * math.sin(time * 5 + i * 0.5)
                love.graphics.setColor(0.7, 0.3, 1.0, alpha)
                love.graphics.rectangle("fill", cx, cy + i, w, 5)
            end
        elseif player.edition == "Polychrome" then
            -- Animated rainbow diagonal overlay
            local time = love.timer.getTime()
            love.graphics.setBlendMode("add")
            for i = 0, 5 do
                local r = (math.sin(time * 2 + i) + 1) / 2
                local g = (math.sin(time * 2 + i + 2) + 1) / 2
                local b = (math.sin(time * 2 + i + 4) + 1) / 2
                love.graphics.setColor(r, g, b, 0.15)
                love.graphics.line(cx + i*15, cy, cx + w, cy + h - i*15)
                love.graphics.line(cx, cy + i*15, cx + w - i*15, cy + h)
            end
            love.graphics.setBlendMode("alpha")
        elseif player.edition == "Franchise" then
            -- Dark pulsing ethereal glow
            local time = love.timer.getTime()
            love.graphics.setBlendMode("add")
            for i = 0, h, 15 do
                local alpha = 0.05 + 0.15 * math.sin(time * 4 + i * 0.1)
                love.graphics.setColor(0.3, 0.1, 0.6, alpha)
                love.graphics.rectangle("fill", cx, cy + i, w, 10)
            end
            love.graphics.setBlendMode("alpha")
        end
        
    else
        -- -------------------------------------------------------------
        -- BACK FACE: Scouting & Synergy Report
        -- -------------------------------------------------------------
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", cx - 2, cy - 2, w + 4, h + 4, 8, 8)
        
        love.graphics.setColor(C_BACK_CARD)
        love.graphics.rectangle("fill", cx, cy, w, h, 6, 6)
        
        drawShadowText("SCOUTING REPORT", cx + 4, cy + 4, 1, 0.84, 0, 0.8, "center", w - 8)
        drawShadowText(player.name, cx + 4, cy + 18, 1, 1, 1, 0.85, "center", w - 8)
        
        -- Primary Roster Synergy Ability Box
        love.graphics.setColor(0.15, 0.18, 0.24, 1)
        love.graphics.rectangle("fill", cx + 4, cy + 34, w - 8, 38, 4, 4)
        love.graphics.setColor(C_NEON_YELLOW)
        love.graphics.rectangle("line", cx + 4, cy + 34, w - 8, 38, 4, 4)
        
        drawShadowText("SYNERGY:", cx + 6, cy + 36, 1, 0.84, 0, 0.7)
        drawShadowText(player.abilityDesc or "+YDS & +MTM", cx + 6, cy + 46, 1, 1, 1, 0.65, "left", w - 12)
        
        -- Equipped Badges Panel
        if player.equippedBadges and #player.equippedBadges > 0 then
            love.graphics.setColor(0.1, 0.3, 0.4)
            love.graphics.rectangle("fill", cx + 4, cy + 74, w - 8, 16, 3, 3)
            local badgeStr = "BADGES: " .. #player.equippedBadges .. "/2"
            drawShadowText(badgeStr, cx + 6, cy + 76, 0.2, 0.8, 1, 0.65)
        end
        
        -- Attributes Bars (SPD, STR, AWR, CTH)
        local barY = cy + 90
        local function drawStatBar(label, statVal, offset, yOffset)
            local bx = cx + 6 + offset * 48
            local by = barY + (yOffset or 0)
            drawShadowText(label .. ":" .. statVal, bx, by, 0.8, 0.8, 0.8, 0.6)
            love.graphics.setColor(0.2, 0.25, 0.3)
            love.graphics.rectangle("fill", bx, by + 10, 42, 4)
            love.graphics.setColor(0.0, 0.76, 1.0)
            love.graphics.rectangle("fill", bx, by + 10, 42 * (statVal / 99), 4)
        end
        
        drawStatBar("SPD", player.spd or 80, 0, 0)
        drawStatBar("STR", player.str or 80, 1, 0)
        drawStatBar("AWR", player.awr or 80, 0, 18)
        drawStatBar("CTH", player.cth or 80, 1, 18)
    end
    
    love.graphics.pop()
end

function CardRender.drawTooltip(mx, my, card)
    if not card then return end
    
    local tips = {}
    
    -- 1. Edition (Helmet Finish)
    if card.edition and card.edition ~= "Standard" then
        if card.edition == "Foil" then
            table.insert(tips, { title = "FOIL FINISH", desc = "Grants +5 Base Yards to this play/player." })
        elseif card.edition == "Holographic" then
            table.insert(tips, { title = "HOLO FINISH", desc = "Grants +0.5 Drive Momentum (MTM) multiplier." })
        elseif card.edition == "Polychrome" then
            table.insert(tips, { title = "POLYCHROME FINISH", desc = "Grants x1.5 Drive Momentum (MTM) multiplier." })
        elseif card.edition == "Franchise" or card.edition == "Negative" then
            table.insert(tips, { title = "FRANCHISE EDITION", desc = "Grants +1 Active Roster Slot limit." })
        end
    end
    
    -- 2. Enhancement (Equipment Attribute)
    if card.enhancement then
        if card.enhancement == "Glass" then
            table.insert(tips, { title = "HIGH-OCTANE CLEATS", desc = "Grants x2.0 Drive Momentum (MTM), but 25% chance to bench card after play." })
        elseif card.enhancement == "Steel" then
            table.insert(tips, { title = "REINFORCED PADS", desc = "Grants x1.5 Drive Momentum (MTM) if held in hand at end of play." })
        elseif card.enhancement == "Gold" then
            table.insert(tips, { title = "SPONSOR DECAL", desc = "Grants +$3 Cap Space if held in hand at end of play." })
        elseif card.enhancement == "Stone" then
            table.insert(tips, { title = "HEAVY STUDS", desc = "Grants +50 Yards on play, but no Drive Momentum (MTM)." })
        end
    end
    
    -- 3. Seal (Helmet Decal)
    if card.seal then
        if card.seal == "Red" then
            table.insert(tips, { title = "RED STRIPE DECAL", desc = "Retriggers this card's yards and momentum bonuses 1 additional time." })
        elseif card.seal == "Gold" then
            table.insert(tips, { title = "GOLD STAR DECAL", desc = "Grants +$3 Cap Space when this card is played." })
        elseif card.seal == "Blue" then
            table.insert(tips, { title = "BLUE RIBBON DECAL", desc = "Generates a random Audible card in hand if discarded." })
        end
    end
    
    -- 4. Play Card properties (if play card)
    if card.baseChips and card.type then
        table.insert(tips, { title = card.name:upper() .. " (" .. card.type:upper() .. ")", desc = "Play Card. Adds base yards and drive momentum multiplier." })
    end
    
    -- 5. Roster Player properties (if roster player)
    if card.overall and card.position then
        table.insert(tips, { title = card.name:upper() .. " (" .. card.position .. ")", desc = "Roster Player. Overall: " .. card.overall .. " OVR. " .. (card.abilityDesc or "") })
    end
    
    -- 6. Consumable (Audible Perk)
    if card.consumable then
        table.insert(tips, { title = card.consumable.name:upper(), desc = "Sideline Perk. " .. card.consumable.description })
    end
    
    -- 7. Voucher (Staff Upgrade)
    if card.voucher then
        table.insert(tips, { title = card.voucher.name:upper(), desc = "Staff Upgrade. " .. card.voucher.description })
    end
    
    if #tips == 0 then return end
    
    -- Draw tooltips vertically stacked
    local tx, ty = mx + 20, my - 10
    local tipW = 240
    local tipH = 75
    
    for _, tip in ipairs(tips) do
        love.graphics.setColor(0.129, 0.149, 0.192, 0.95)
        love.graphics.rectangle("fill", tx, ty, tipW, tipH, 6, 6)
        love.graphics.setColor(0.0, 0.76, 1.0, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", tx, ty, tipW, tipH, 6, 6)
        love.graphics.setLineWidth(1)
        
        drawShadowText(tip.title, tx + 8, ty + 6, 1, 0.84, 0, 0.9)
        drawShadowText(tip.desc, tx + 8, ty + 20, 0.9, 0.9, 0.9, 0.75, "left", tipW - 16)
        
        ty = ty + tipH + 8
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return CardRender
