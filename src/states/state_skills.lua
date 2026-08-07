-- src/states/state_skills.lua
local StateManager = require("src.states.state_manager")

local StateSkills = {}

function StateSkills:enter()
    self.selectedCol = 1
    self.selectedRow = 1
    
    self.staffPoints = 3
    
    self.trees = {
        {
            name = "PLAYER GROWTH",
            nodes = {
                { id = "pg1", name = "Rookie Camp", maxLevel = 1, currentLevel = 1, desc1 = "Not Unlocked", desc2 = "WRs gain +5% XP", icon = "A" },
                { id = "pg2", name = "Receptions Galore", maxLevel = 2, currentLevel = 1, desc1 = "Increase XP gains for WRs/TEs by 10%", desc2 = "Increase XP gains for WRs/TEs by 20%", icon = "B" },
                { id = "pg3", name = "Weight Room", maxLevel = 2, currentLevel = 0, desc1 = "Not Unlocked", desc2 = "OL/DL gain +10% XP", icon = "C" },
            }
        },
        {
            name = "STAFF MODIFICATIONS",
            nodes = {
                { id = "sm1", name = "Scouting Network", maxLevel = 2, currentLevel = 2, desc1 = "Reveal Defensive Tells automatically.", desc2 = "N/A (Maxed)", icon = "D" },
                { id = "sm2", name = "Salary Cap", maxLevel = 3, currentLevel = 0, desc1 = "Not Unlocked", desc2 = "Gain +1 Cap Cash per Touchdown", icon = "E" },
            }
        }
    }
end

function StateSkills:exit()
end

function StateSkills:update(dt)
end

local function drawShadowText(text, x, y, r, g, b, scale, align, limit)
    scale = scale or 1
    love.graphics.setColor(0, 0, 0, 0.8)
    if align and limit then
        love.graphics.printf(text, x + 1, y + 1, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x + 1, y + 1, 0, scale, scale)
    end
    
    if r then
        love.graphics.setColor(r, g, b, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    if align and limit then
        love.graphics.printf(text, x, y, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x, y, 0, scale, scale)
    end
end

function StateSkills:draw()
    -- Background
    love.graphics.setColor(0.12, 0.13, 0.14)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Title
    drawShadowText("TALENT TREES", 40, 20, 1, 1, 1, 2)
    drawShadowText("STAFF POINTS: " .. self.staffPoints, 650, 30, 0.75, 1, 0, 1.2)
    
    -- Draw Trees
    for c, tree in ipairs(self.trees) do
        local colX = 100 + (c - 1) * 250
        drawShadowText(tree.name, colX, 80, 0.8, 0.8, 0.8, 1.2)
        
        for r, node in ipairs(tree.nodes) do
            local nodeY = 150 + (r - 1) * 90
            
            -- Draw connector line to previous node
            if r > 1 then
                love.graphics.setColor(0.3, 0.3, 0.3)
                love.graphics.line(colX + 30, nodeY - 90 + 60, colX + 30, nodeY)
            end
            
            -- Box
            if c == self.selectedCol and r == self.selectedRow then
                love.graphics.setColor(0.75, 1, 0) -- Neon Green
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", colX, nodeY, 60, 60, 4, 4)
                love.graphics.setLineWidth(1)
            else
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("line", colX, nodeY, 60, 60, 4, 4)
            end
            
            love.graphics.setColor(0.05, 0.05, 0.05)
            love.graphics.rectangle("fill", colX, nodeY, 60, 60, 4, 4)
            
            -- Icon placeholder
            if node.currentLevel > 0 then
                love.graphics.setColor(0.75, 1, 0)
            else
                love.graphics.setColor(0.4, 0.4, 0.4)
            end
            love.graphics.print(node.icon, colX + 22, nodeY + 15, 0, 1.5, 1.5)
            
            -- Level text
            drawShadowText(node.currentLevel .. "/" .. node.maxLevel, colX + 20, nodeY + 40, 0.9, 0.9, 0.9, 0.9)
        end
    end
    
    -- Right Detail Panel
    local activeNode = self.trees[self.selectedCol].nodes[self.selectedRow]
    love.graphics.setColor(0.08, 0.08, 0.08)
    love.graphics.rectangle("fill", 650, 100, 280, 400)
    
    drawShadowText(string.upper(activeNode.name), 670, 120, 1, 1, 1, 1.4)
    
    love.graphics.setColor(0.75, 1, 0)
    love.graphics.circle("line", 790, 200, 40)
    love.graphics.print(activeNode.icon, 780, 185, 0, 2, 2)
    
    drawShadowText(activeNode.currentLevel .. "/" .. activeNode.maxLevel, 775, 250, 0.75, 1, 0, 1.2)
    
    drawShadowText("Currently Owned", 670, 290, 0.6, 0.6, 0.6, 1)
    drawShadowText(activeNode.desc1, 670, 310, 1, 1, 1, 1, "left", 260)
    
    drawShadowText("Next Tier", 670, 360, 0.6, 0.6, 0.6, 1)
    drawShadowText(activeNode.desc2, 670, 380, 1, 1, 1, 1, "left", 260)
    
    if activeNode.currentLevel < activeNode.maxLevel then
        drawShadowText("Press [ENTER] to Upgrade (Cost: 1)", 670, 450, 0.75, 1, 0, 1)
    else
        drawShadowText("MAX LEVEL REACHED", 670, 450, 0.5, 0.5, 0.5, 1)
    end
    
    drawShadowText("Press ESC to return to the Main Menu", 20, 510, 1, 1, 1, 1)
end

function StateSkills:keypressed(key)
    if key == "escape" then
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    elseif key == "right" or key == "d" then
        self.selectedCol = math.min(self.selectedCol + 1, #self.trees)
        self.selectedRow = math.min(self.selectedRow, #self.trees[self.selectedCol].nodes)
    elseif key == "left" or key == "a" then
        self.selectedCol = math.max(self.selectedCol - 1, 1)
        self.selectedRow = math.min(self.selectedRow, #self.trees[self.selectedCol].nodes)
    elseif key == "down" or key == "s" then
        self.selectedRow = math.min(self.selectedRow + 1, #self.trees[self.selectedCol].nodes)
    elseif key == "up" or key == "w" then
        self.selectedRow = math.max(self.selectedRow - 1, 1)
    elseif key == "return" or key == "enter" then
        local activeNode = self.trees[self.selectedCol].nodes[self.selectedRow]
        if activeNode.currentLevel < activeNode.maxLevel and self.staffPoints > 0 then
            activeNode.currentLevel = activeNode.currentLevel + 1
            self.staffPoints = self.staffPoints - 1
            activeNode.desc1 = activeNode.desc2
            if activeNode.currentLevel == activeNode.maxLevel then
                activeNode.desc2 = "N/A (Maxed)"
            end
        end
    end
end

return StateSkills
