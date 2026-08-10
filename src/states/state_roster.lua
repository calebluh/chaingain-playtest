-- src/states/state_roster.lua
local StateManager = require("src.states.state_manager")
local GameStateData = require("src.engine.game_state")

local StateRoster = {}

local C_BG = {0.18, 0.45, 0.95} -- Retro Bowl Blue
local C_OFFENSE = {0.2, 0.6, 0.8}
local C_DEFENSE = {0.8, 0.2, 0.2}
local C_KICKER = {0.9, 0.5, 0.1}

function StateRoster:enter()
    -- Gather all active players into a flat list
    self.players = {}
    
    if GameStateData.rosterSlots then
        local order = {"QB", "RB", "WR1", "WR2", "FLEX"}
        for _, pos in ipairs(order) do
            if GameStateData.rosterSlots[pos] then
                for _, card in ipairs(GameStateData.rosterSlots[pos].cards) do
                    table.insert(self.players, { card = card, pos = pos })
                end
            end
        end
    end
end

function StateRoster:exit()
end

function StateRoster:update(dt)
end

local function drawShadowText(text, x, y, r, g, b, scale, align, limit)
    scale = scale or 1
    love.graphics.setColor(0, 0, 0, 0.8)
    if align and limit then
        love.graphics.printf(text, x + 2, y + 2, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x + 2, y + 2, 0, scale, scale)
    end
    
    love.graphics.setColor(r or 1, g or 1, b or 1, 1)
    if align and limit then
        love.graphics.printf(text, x, y, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x, y, 0, scale, scale)
    end
end

local function drawPixelFace(x, y)
    love.graphics.push()
    love.graphics.translate(x, y)
    
    -- Neck
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.rectangle("fill", 20, 20, 10, 10)
    -- Face
    love.graphics.rectangle("fill", 10, 0, 30, 25)
    
    -- Hair
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 10, -5, 30, 10)
    
    -- Eyes
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 15, 10, 6, 4)
    love.graphics.rectangle("fill", 29, 10, 6, 4)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 17, 11, 2, 2)
    love.graphics.rectangle("fill", 31, 11, 2, 2)
    
    -- Jersey body
    love.graphics.setColor(0.6, 0.1, 0.1)
    love.graphics.rectangle("fill", 5, 30, 40, 20)
    
    love.graphics.pop()
end

local function drawOverallBadge(x, y, rating)
    love.graphics.setColor(0.12, 0.12, 0.12)
    love.graphics.rectangle("fill", x, y, 54, 16, 3, 3)
    love.graphics.setColor(1, 0.78, 0.18)
    love.graphics.print("OVR", x + 4, y + 2, 0, 0.8, 0.8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tostring(rating), x + 28, y + 2, 0, 0.8, 0.8)
end

function StateRoster:draw()
    love.graphics.setColor(C_BG)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Top Header
    drawShadowText("*** ROSTER ***", 0, 15, 1, 1, 1, 2.0, "center", 960)
    drawShadowText("PLAYERS " .. #self.players .. " / 12", 0, 65, 1, 1, 1, 1.2, "center", 960)
    
    -- Player Grid (2x6)
    local startX = 60
    local startY = 105
    local slotW = 118
    local slotH = 142
    local padX = 18
    local padY = 14
    
    for i = 1, 12 do
        local row = math.floor((i - 1) / 6)
        local col = (i - 1) % 6
        local cx = startX + col * (slotW + padX)
        local cy = startY + row * (slotH + padY)
        
        -- Slot Border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", cx, cy, slotW, slotH, 4, 4)
        love.graphics.setLineWidth(1)
        
        -- Background
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", cx, cy, slotW, slotH, 4, 4)
        
        local pData = self.players[i]
        if pData then
            local card = pData.card
            local pos = pData.pos
            
            love.graphics.setColor(C_OFFENSE)
            love.graphics.rectangle("fill", cx + 2, cy + 2, slotW - 4, 72, 4, 4)
            
            drawShadowText(pos, cx + 5, cy + 5, 1, 1, 1, 1.1)
            
            -- Name block
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", cx + 2, cy + 78, slotW - 4, 56, 0, 0, 4, 4)
            
            -- Truncate name
            local shortName = string.sub(card.name, 1, 12)
            drawShadowText(shortName, cx + 5, cy + 82, 1, 1, 1, 1.1)
            
            -- Overall rating
            drawOverallBadge(cx + 26, cy + 106, card.overall or 75)
        end
    end
    
    -- Bottom Bar: Salary Cap
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 150, 470, 400, 50, 4, 4)
    love.graphics.setColor(0.1, 0.2, 0.4)
    love.graphics.rectangle("fill", 150, 470, 400, 50, 4, 4)
    
    local capUsed = #self.players * 15
    local capMax = 350
    drawShadowText("SALARY CAP " .. capUsed .. "M / " .. capMax .. "M", 160, 475, 1, 1, 1, 1.2)
    love.graphics.setColor(0.9, 0.8, 0.1)
    love.graphics.rectangle("fill", 160, 500, math.min(380, (capUsed/capMax)*380), 12)
    
    -- Morale
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 570, 470, 100, 50, 4, 4)
    drawShadowText("-MORALE-", 570, 475, 1, 1, 1, 1.0, "center", 100)
    drawShadowText("100%", 570, 495, 1, 1, 1, 1.2, "center", 100)
    
    drawShadowText("Press [ESC] To Return", 20, 500, 1, 1, 1, 1.1)
end

function StateRoster:keypressed(key)
    if key == "escape" then
        local StateMenu = require("src.states.state_menu")
        -- Wait, state_roster should return to whatever state launched it.
        -- But for now just going back to shop or game.
        local StateShop = require("src.states.state_shop")
        StateManager.switch(StateShop)
    end
end

return StateRoster
