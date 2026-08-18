-- src/states/state_myplayer_tree.lua
local StateManager = require("src.states.state_manager")
local MyPlayerProfile = require("src.data.myplayer_profile")
local SoundManager = require("src.engine.sound_manager")
local FxManager = require("src.engine.fx_manager")
local SkillTreeData = require("src.data.skill_tree_nodes")

local StateMyPlayerTree = {}

local C_BG = {0.06, 0.08, 0.12}
local C_NEON_BORDER = {0.0, 0.76, 1.0}

local function checkHover(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end

local function checkHoverCam(x, y, radius, cx, cy, zoom)
    local mx, my = love.mouse.getPosition()
    local relMx = mx - cx
    local relMy = my - cy
    local worldMx = relMx / zoom
    local worldMy = relMy / zoom
    
    local dx = worldMx - x
    local dy = worldMy - y
    return (dx*dx + dy*dy) <= (radius*radius)
end

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

function StateMyPlayerTree:enter()
    self.message = "Spend Class Points (CP) to unlock Archetype perks! Drag to Pan, Scroll to Zoom."
    
    -- Camera & Zoom
    self.camX = 480
    self.camY = 270
    self.targetCamX = 480
    self.targetCamY = 270
    self.zoom = 1.0
    self.targetZoom = 1.0
    self.isDragging = false
    self.dragStartX = 0
    self.dragStartY = 0
    
    self.hoveredNode = nil
    
    -- Generate Stars for Parallax
    self.stars = {}
    for i=1, 200 do
        table.insert(self.stars, {
            x = math.random(-2000, 2000),
            y = math.random(-2000, 2000),
            size = math.random(1, 3),
            depth = math.random() * 0.8 + 0.2, -- 0.2 to 1.0
            phase = math.random() * math.pi * 2
        })
    end
end

function StateMyPlayerTree:isUnlocked(id)
    return MyPlayerProfile.hasNode(id)
end

function StateMyPlayerTree:canUnlock(node)
    if self:isUnlocked(node.id) then return false end
    if MyPlayerProfile.classPoints < node.cost then return false end
    if node.req and not self:isUnlocked(node.req) then return false end
    return true
end

function StateMyPlayerTree:update(dt)
    local mx, my = love.mouse.getPosition()
    
    if love.mouse.isDown(2) or love.mouse.isDown(3) then
        if not self.isDragging then
            self.isDragging = true
            self.dragStartX = mx - self.camX
            self.dragStartY = my - self.camY
        else
            self.targetCamX = mx - self.dragStartX
            self.targetCamY = my - self.dragStartY
        end
    else
        self.isDragging = false
    end
    
    -- Smooth camera and zoom lerps
    self.camX = self.camX + (self.targetCamX - self.camX) * dt * 10
    self.camY = self.camY + (self.targetCamY - self.camY) * dt * 10
    self.zoom = self.zoom + (self.targetZoom - self.zoom) * dt * 10
    
    self.hoveredNode = nil
    for _, node in ipairs(SkillTreeData.list) do
        local r = node.name:match("CAPSTONE") and 35 or 25
        if checkHoverCam(node.x, node.y, r, self.camX, self.camY, self.zoom) then
            self.hoveredNode = node
        end
    end
end

function StateMyPlayerTree:wheelmoved(x, y)
    if y > 0 then
        self.targetZoom = math.clamp(self.targetZoom + 0.15, 0.4, 2.5)
    elseif y < 0 then
        self.targetZoom = math.clamp(self.targetZoom - 0.15, 0.4, 2.5)
    end
end

function StateMyPlayerTree:draw()
    -- Deep space background
    love.graphics.setColor(0.02, 0.03, 0.06)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    local time = love.timer.getTime()
    
    -- Draw Parallax Stars
    for _, star in ipairs(self.stars) do
        local sx = (star.x + self.camX * star.depth) % 960
        local sy = (star.y + self.camY * star.depth) % 540
        local twinkle = 0.5 + 0.5 * math.sin(time * 3 + star.phase)
        love.graphics.setColor(1, 1, 1, twinkle * star.depth)
        love.graphics.rectangle("fill", sx, sy, star.size, star.size)
    end
    
    love.graphics.push()
    love.graphics.translate(self.camX, self.camY)
    love.graphics.scale(self.zoom, self.zoom)
    
    -- Draw Glowing Connections
    for _, node in ipairs(SkillTreeData.list) do
        if node.req then
            local pNode = SkillTreeData.dict[node.req]
            if pNode then
                if self:isUnlocked(node.id) then
                    love.graphics.setLineWidth(6)
                    love.graphics.setColor(node.color[1], node.color[2], node.color[3], 0.3)
                    love.graphics.line(node.x, node.y, pNode.x, pNode.y)
                    
                    love.graphics.setLineWidth(3)
                    love.graphics.setColor(node.color[1], node.color[2], node.color[3], 0.9 + 0.1 * math.sin(time*10))
                elseif self:isUnlocked(pNode.id) then
                    love.graphics.setLineWidth(2)
                    love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
                else
                    love.graphics.setLineWidth(2)
                    love.graphics.setColor(0.1, 0.1, 0.1, 0.4)
                end
                love.graphics.line(node.x, node.y, pNode.x, pNode.y)
            end
        end
    end
    love.graphics.setLineWidth(1)
    
    -- Draw Nodes
    for _, node in ipairs(SkillTreeData.list) do
        local isCap = node.name:match("CAPSTONE")
        local r = isCap and 35 or 25
        
        local unlocked = self:isUnlocked(node.id)
        local canUnlock = self:canUnlock(node)
        
        -- Capstone Aura
        if isCap and unlocked then
            love.graphics.push()
            love.graphics.translate(node.x, node.y)
            love.graphics.rotate(time * 0.5)
            love.graphics.setColor(node.color[1], node.color[2], node.color[3], 0.2 + 0.1 * math.sin(time*2))
            love.graphics.rectangle("fill", -r*1.5, -r*1.5, r*3, r*3, 8, 8)
            love.graphics.pop()
        end
        
        if unlocked then
            love.graphics.setColor(node.color[1], node.color[2], node.color[3], 1.0)
            love.graphics.circle("fill", node.x, node.y, r)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", node.x, node.y, r)
            love.graphics.setLineWidth(1)
        elseif canUnlock then
            -- Pulse effect
            local pulse = 0.5 + 0.5 * math.sin(time * 5)
            love.graphics.setColor(node.color[1] * pulse, node.color[2] * pulse, node.color[3] * pulse, 1.0)
            love.graphics.circle("fill", node.x, node.y, r)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", node.x, node.y, r)
            love.graphics.setLineWidth(1)
        else
            love.graphics.setColor(0.1, 0.15, 0.2, 1.0)
            love.graphics.circle("fill", node.x, node.y, r)
            love.graphics.setColor(0.25, 0.3, 0.4)
            love.graphics.circle("line", node.x, node.y, r)
        end
        
        if isCap then
            love.graphics.setColor(0, 0, 0)
            love.graphics.circle("fill", node.x, node.y, 10)
        end
    end
    
    love.graphics.pop()
    
    -- Draw UI Overlay
    love.graphics.setColor(0.129, 0.149, 0.192, 0.95)
    love.graphics.rectangle("fill", 0, 0, 960, 50)
    love.graphics.setColor(0, 0.76, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, 50, 960, 50)
    love.graphics.setLineWidth(1)
    
    drawShadowText("ARCHETYPE SKILL TREE", 20, 15, 1, 1, 1, 1.5)
    drawShadowText("CLASS POINTS: " .. MyPlayerProfile.classPoints, 750, 15, 1, 0.84, 0, 1.5)
    
    if self.hoveredNode then
        local n = self.hoveredNode
        local hx, hy = love.mouse.getPosition()
        
        love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
        love.graphics.rectangle("fill", hx + 15, hy + 15, 260, 120, 8, 8)
        love.graphics.setColor(n.color)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", hx + 15, hy + 15, 260, 120, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText(n.name, hx + 25, hy + 25, 1, 1, 1, 1.2, "left", 240)
        drawShadowText(n.desc, hx + 25, hy + 50, 0.8, 0.8, 0.8, 0.9, "left", 240)
        
        if self:isUnlocked(n.id) then
            drawShadowText("[UNLOCKED]", hx + 25, hy + 105, 0.2, 1, 0.2, 1.0)
        else
            local costColor = MyPlayerProfile.classPoints >= n.cost and {1, 0.84, 0} or {1, 0.2, 0.2}
            drawShadowText("COST: " .. n.cost .. " CP", hx + 25, hy + 105, costColor[1], costColor[2], costColor[3], 1.0)
            if self:canUnlock(n) then
                drawShadowText("Click to Unlock!", hx + 120, hy + 105, 0, 0.76, 1, 0.9)
            elseif n.req and not self:isUnlocked(n.req) then
                drawShadowText("Requires previous node", hx + 120, hy + 105, 1, 0.2, 0.2, 0.8)
            end
        end
    end
    
    -- Back button
    local hBack = checkHover(20, 498, 110, 32)
    love.graphics.setColor(hBack and {1, 0.3, 0.3} or {0.8, 0.2, 0.2})
    love.graphics.rectangle("fill", 20, 498, 110, 32, 5, 5)
    drawShadowText("B  back", 20, 505, 1, 1, 1, 0.95, "center", 110)
    
    -- Draw zoom buttons
    local hoverZIn = checkHover(640, 502, 65, 25)
    love.graphics.setColor(hoverZIn and {0.0, 0.76, 1.0} or {0.129, 0.149, 0.192})
    love.graphics.rectangle("fill", 640, 502, 65, 25, 4, 4)
    love.graphics.setColor(C_NEON_BORDER)
    love.graphics.rectangle("line", 640, 502, 65, 25, 4, 4)
    drawShadowText("ZOOM +", 640, 506, 1, 1, 1, 0.8, "center", 65)
    
    local hoverZOut = checkHover(710, 502, 65, 25)
    love.graphics.setColor(hoverZOut and {0.0, 0.76, 1.0} or {0.129, 0.149, 0.192})
    love.graphics.rectangle("fill", 710, 502, 65, 25, 4, 4)
    love.graphics.setColor(C_NEON_BORDER)
    love.graphics.rectangle("line", 710, 502, 65, 25, 4, 4)
    drawShadowText("ZOOM -", 710, 506, 1, 1, 1, 0.8, "center", 65)
    
    drawShadowText(self.message, 140, 510, 1, 1, 1, 1.0)
end

function StateMyPlayerTree:mousepressed(x, y, button)
    if button == 1 then
        if checkHover(20, 498, 110, 32) then
            SoundManager.playSFX("click")
            local StateMyPlayer = require("src.states.state_myplayer")
            StateManager.switch(StateMyPlayer)
            return
        end
        if checkHover(640, 502, 65, 25) then
            self.targetZoom = math.clamp(self.targetZoom + 0.25, 0.4, 2.5)
            SoundManager.playSFX("click")
            return
        elseif checkHover(710, 502, 65, 25) then
            self.targetZoom = math.clamp(self.targetZoom - 0.25, 0.4, 2.5)
            SoundManager.playSFX("click")
            return
        end
    end

    if button == 1 and self.hoveredNode then
        local n = self.hoveredNode
        if self:canUnlock(n) then
            MyPlayerProfile.classPoints = MyPlayerProfile.classPoints - n.cost
            table.insert(MyPlayerProfile.unlockedNodes, n.id)
            MyPlayerProfile.save()
            
            SoundManager.playSFX("slam")
            if _G.triggerScreenShake then _G.triggerScreenShake(15, 0.3) end
            
            -- Convert world coords to screen for particles
            local screenX = self.camX + (n.x * self.zoom)
            local screenY = self.camY + (n.y * self.zoom)
            FxManager.addBurstParticles(screenX, screenY, 60, n.color[1], n.color[2], n.color[3])
            
            self.message = "Unlocked " .. n.name .. "!"
        else
            SoundManager.playSFX("click")
        end
    end
end

function StateMyPlayerTree:keypressed(key)
    if key == "escape" or key == "b" then
        SoundManager.playSFX("click")
        local StateMyPlayer = require("src.states.state_myplayer")
        StateManager.switch(StateMyPlayer)
    elseif key == "c" then
        -- Recenter
        self.targetCamX = 480
        self.targetCamY = 270
        self.targetZoom = 1.0
    elseif key == "=" or key == "kp+" or key == "i" then
        self.targetZoom = math.clamp(self.targetZoom + 0.25, 0.4, 2.5)
        SoundManager.playSFX("click")
    elseif key == "-" or key == "kp-" or key == "o" then
        self.targetZoom = math.clamp(self.targetZoom - 0.25, 0.4, 2.5)
        SoundManager.playSFX("click")
    end
end

return StateMyPlayerTree
