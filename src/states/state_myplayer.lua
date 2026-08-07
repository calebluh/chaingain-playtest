-- src/states/state_myplayer.lua
local StateManager = require("src.states.state_manager")
local MyPlayerProfile = require("src.data.myplayer_profile")
local SoundManager = require("src.engine.sound_manager")

local StateMyPlayer = {}

local C_SLATE = {0.12, 0.14, 0.18}
local C_SLATE_CONTAINER = {0.129, 0.149, 0.192}
local C_NEON_BORDER = {0.0, 0.76, 1.0}
local C_BLUE = {0.0, 0.58, 1.0}
local C_AMBER = {1.0, 0.6, 0.0}

local function checkHover(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
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

local posArchetypes = {
    QB = {"Gunslinger", "Scrambler", "Clutch QB", "Field General"},
    RB = {"Power Back", "Speedster", "Dual Threat"},
    WR = {"Deep Threat", "Slot Specialist", "YAC Monster"},
    TE = {"Pancake Blocker", "Seam Threat"}
}

local archetypeDetails = {
    Gunslinger = { chip = 2, mult = 0.5, desc = "+2 Base Yards & +0.5 MTM on all Pass plays" },
    Scrambler = { chip = 3, mult = 0.2, desc = "+3 Base Yards & +0.2 MTM on Run plays" },
    ["Clutch QB"] = { chip = 4, mult = 0.8, desc = "+4 YDS, +0.8 MTM on 3rd & 4th Down" },
    ["Field General"] = { chip = 1, mult = 0.4, desc = "+1 YDS, +0.4 MTM, and +1 Audible per drive" },
    ["Power Back"] = { chip = 4, mult = 0.1, desc = "+4 Base Yards on Run plays" },
    Speedster = { chip = 1, mult = 0.6, desc = "+0.6 MTM on outside Run plays" },
    ["Dual Threat"] = { chip = 3, mult = 0.4, desc = "+3 YDS on Play Action & Screen plays" },
    ["Deep Threat"] = { chip = 5, mult = 0.7, desc = "+5 YDS, +0.7 MTM on Deep Passes" },
    ["Slot Specialist"] = { chip = 2, mult = 0.5, desc = "+2 YDS, +0.5 MTM on Short & Medium Passes" },
    ["YAC Monster"] = { chip = 3, mult = 0.3, desc = "+3 YDS after catch on Pass plays" },
    ["Pancake Blocker"] = { chip = 3, mult = 0.3, desc = "+3 YDS on Run & Play Action" },
    ["Seam Threat"] = { chip = 4, mult = 0.5, desc = "+4 YDS on Medium Passes" }
}

function StateMyPlayer:enter()
    self.tab = "OVERVIEW"
    self.tabs = {
        { id = "OVERVIEW", name = "BIO & GEAR", x = 60, y = 80, w = 180, h = 40 },
        { id = "QUESTS", name = "MILESTONES", x = 250, y = 80, w = 180, h = 40 }
    }
    
    self.backBtn = { x = 60, y = 450, w = 140, h = 40, name = "MAIN MENU", color = {0.8, 0.2, 0.2} }
    self.treeBtn = { x = 740, y = 80, w = 160, h = 40, name = "SKILL TREE", color = C_AMBER }
    
    if not MyPlayerProfile.isCreated then
        self.creatorActive = true
        self.firstTimePrompt = true
        self.creatorName = ""
        self.creatorPosition = "QB"
        self.creatorArchetype = "Gunslinger"
        self.focusedField = "name"
    else
        self.creatorActive = false
        self.firstTimePrompt = false
        self.creatorName = MyPlayerProfile.name or "Rookie"
        self.creatorPosition = MyPlayerProfile.position or "QB"
        self.creatorArchetype = MyPlayerProfile.archetypeTitle or "Gunslinger"
        self.focusedField = nil
    end
end

function StateMyPlayer:exit()
end

function StateMyPlayer:update(dt)
end

function StateMyPlayer:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    if self.creatorActive then
        drawShadowText("CREATE NEW MYPLAYER ROOKIE", 60, 25, 1, 0.84, 0, 2.0)
        
        -- Form Container (Left Side)
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", 60, 80, 440, 390, 8, 8)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 60, 80, 440, 390, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText("ENTER NAME & ASSIGN STARTING CLASS", 80, 105, 1, 0.84, 0, 1.15)
        
        -- 1. Name input
        drawShadowText("NAME (Click box to type):", 90, 145, 0.8, 0.8, 0.8, 0.95)
        local isNameFocused = (self.focusedField == "name")
        love.graphics.setColor(isNameFocused and {0, 0.76, 1} or {0.15, 0.18, 0.22})
        love.graphics.rectangle("fill", 90, 170, 280, 35, 6, 6)
        love.graphics.setColor(isNameFocused and {1, 1, 1} or {0.4, 0.45, 0.5})
        love.graphics.rectangle("line", 90, 170, 280, 35, 6, 6)
        
        local displayName = self.creatorName
        if isNameFocused and (math.floor(love.timer.getTime() * 2) % 2 == 0) then
            displayName = displayName .. "|"
        end
        drawShadowText(displayName == "" and "Enter Name..." or displayName, 102, 178, displayName == "" and 0.4 or 1, displayName == "" and 0.4 or 1, displayName == "" and 0.4 or 1, 1.1)
        
        -- 2. Position Select
        drawShadowText("POSITION CLASS:", 90, 220, 0.8, 0.8, 0.8, 0.95)
        local positions = {"QB", "RB", "TE", "WR"}
        for idx, pos in ipairs(positions) do
            local bx = 90 + (idx - 1) * 70
            local by = 245
            local isSel = (self.creatorPosition == pos)
            local hover = checkHover(bx, by, 60, 32)
            
            love.graphics.setColor(isSel and C_BLUE or (hover and {0.3, 0.4, 0.5} or {0.15, 0.18, 0.22}))
            love.graphics.rectangle("fill", bx, by, 60, 32, 4, 4)
            love.graphics.setColor(isSel and {1, 1, 1} or {0.3, 0.35, 0.4})
            love.graphics.rectangle("line", bx, by, 60, 32, 4, 4)
            
            drawShadowText(pos, bx, by + 8, 1, 1, 1, 0.95, "center", 60)
        end
        
        -- 3. Archetype Select
        drawShadowText("STARTING ARCHETYPE:", 90, 295, 0.8, 0.8, 0.8, 0.95)
        
        local hoverL = checkHover(90, 320, 30, 32)
        love.graphics.setColor(hoverL and C_BLUE or {0.15, 0.18, 0.22})
        love.graphics.rectangle("fill", 90, 320, 30, 32, 4, 4)
        drawShadowText("←", 90, 326, 1, 1, 1, 1.1, "center", 30)
        
        love.graphics.setColor(0.1, 0.12, 0.15)
        love.graphics.rectangle("fill", 130, 320, 200, 32, 4, 4)
        drawShadowText(self.creatorArchetype, 130, 328, 1, 0.84, 0, 1.0, "center", 200)
        
        local hoverR = checkHover(340, 320, 30, 32)
        love.graphics.setColor(hoverR and C_BLUE or {0.15, 0.18, 0.22})
        love.graphics.rectangle("fill", 340, 320, 30, 32, 4, 4)
        drawShadowText("→", 340, 326, 1, 1, 1, 1.1, "center", 30)
        
        local details = archetypeDetails[self.creatorArchetype] or { desc = "Provides bonuses." }
        drawShadowText("BONUS: " .. details.desc, 90, 365, 0.0, 0.76, 1.0, 0.85, "left", 380)
        
        -- Action buttons
        local hoverConf = checkHover(90, 410, 240, 40)
        love.graphics.setColor(hoverConf and {0.0, 0.8, 0.4} or {0.0, 0.6, 0.3})
        love.graphics.rectangle("fill", 90, 410, 240, 40, 6, 6)
        drawShadowText("CONFIRM & START", 90, 420, 1, 1, 1, 1.1, "center", 240)
        
        if self.firstTimePrompt then
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", 345, 410, 125, 40, 6, 6)
            drawShadowText("CREATION REQ", 345, 420, 0.6, 0.6, 0.6, 0.9, "center", 125)
        else
            local hoverCan = checkHover(345, 410, 125, 40)
            love.graphics.setColor(hoverCan and {0.9, 0.3, 0.3} or {0.7, 0.2, 0.2})
            love.graphics.rectangle("fill", 345, 410, 125, 40, 6, 6)
            drawShadowText("CANCEL", 345, 420, 1, 1, 1, 1.1, "center", 125)
        end
        
        -- Tutorial Guide Panel (Right Side)
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", 520, 80, 380, 390, 8, 8)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 520, 80, 380, 390, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText("MYPLAYER STARTER GUIDE", 520, 105, 0.0, 0.76, 1.0, 1.25, "center", 380)
        
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf("Design your custom franchise superstar! Your player slots into your roster as a core card:", 545, 140, 330, "left", 0, 0.88, 0.88)
        
        love.graphics.setColor(1.0, 0.84, 0.0)
        love.graphics.printf("POSITION ROLES:", 545, 195, 330, "left", 0, 0.88, 0.88)
        
        love.graphics.setColor(0.85, 0.85, 0.85)
        local bulletY = 220
        local bullets = {
            { pos = "QB", desc = "Pass plays. Triggers pass multipliers." },
            { pos = "RB", desc = "Ground runs. Buffs run yardage chips." },
            { pos = "TE", desc = "Security blanket. Yields short pass chips." },
            { pos = "WR", desc = "Deep target. High risk/high mult potential." }
        }
        for _, b in ipairs(bullets) do
            love.graphics.setColor(0.0, 0.76, 1.0)
            love.graphics.print(b.pos .. ":", 545, bulletY, 0, 0.85, 0.85)
            love.graphics.setColor(0.85, 0.85, 0.85)
            love.graphics.print(b.desc, 580, bulletY, 0, 0.85, 0.85)
            bulletY = bulletY + 22
        end
        
        love.graphics.setColor(1.0, 0.6, 0.0)
        love.graphics.printf("PROGRESSION & SKILL TREE:", 545, 320, 330, "left", 0, 0.88, 0.88)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Earn XP through milestones to level up OVR. Use Class Points on the Skill Tree to unlock powerful gameplay modifiers!", 545, 345, 330 / 0.85, "left", 0, 0.85, 0.85)
        
        love.graphics.setColor(0.4, 0.75, 1.0)
        love.graphics.printf("Your player's custom helmet/visor style will render directly in card art and on the field!", 545, 415, 330 / 0.82, "center", 0, 0.82, 0.82)
        
        return
    end
    
    drawShadowText("CAREER LEGEND: MYPLAYER HUB", 60, 25, 1, 0.84, 0, 2.0)
    
    for _, t in ipairs(self.tabs) do
        local isSelected = (self.tab == t.id)
        local hover = checkHover(t.x, t.y, t.w, t.h)
        
        love.graphics.setColor(isSelected and C_BLUE or (hover and {0.3, 0.4, 0.5} or {0.2, 0.25, 0.3}))
        love.graphics.rectangle("fill", t.x, t.y, t.w, t.h, 6, 6)
        drawShadowText(t.name, t.x, t.y + 10, 1, 1, 1, 1.1, "center", t.w)
    end
    
    love.graphics.setColor(C_AMBER)
    love.graphics.rectangle("fill", self.treeBtn.x, self.treeBtn.y, self.treeBtn.w, self.treeBtn.h, 6, 6)
    drawShadowText(self.treeBtn.name, self.treeBtn.x, self.treeBtn.y + 10, 1, 1, 1, 1.1, "center", self.treeBtn.w)
    
    if self.tab == "OVERVIEW" then
        -- Bio Panel
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", 60, 140, 260, 290, 8, 8)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 60, 140, 260, 290, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText(MyPlayerProfile.name, 75, 155, 1, 1, 1, 1.5)
        
        -- Bio details
        drawShadowText("Position: " .. MyPlayerProfile.position, 75, 195, 0.8, 0.8, 0.8, 1.1)
        
        local canChange = (MyPlayerProfile.classPoints >= 5)
        local hoverChange = checkHover(185, 192, 120, 22)
        love.graphics.setColor(canChange and (hoverChange and {0.0, 0.76, 1.0} or C_AMBER) or {0.2, 0.22, 0.25})
        love.graphics.rectangle("fill", 185, 192, 120, 22, 4, 4)
        love.graphics.setColor(canChange and {1, 1, 1} or {0.4, 0.4, 0.4})
        drawShadowText("CHANGE (5 CP)", 185, 196, canChange and 1 or 0.5, canChange and 1 or 0.5, canChange and 1 or 0.5, 0.75, "center", 120)
        
        drawShadowText("Archetype: " .. (MyPlayerProfile.archetypeTitle or "Gunslinger"), 75, 225, 1, 0.8, 0.2, 1.1)
        
        -- Gear Customization Controls
        drawShadowText("GEAR CUSTOMIZATION:", 75, 265, 1, 0.84, 0, 1.0)
        drawShadowText("[Click] Helmet: " .. (MyPlayerProfile.helmetStyle or "Modern"), 75, 295, 0.8, 0.9, 1, 1.0)
        drawShadowText("[Click] Visor Tint: " .. (MyPlayerProfile.visorTint or "Clear"), 75, 325, 0.8, 0.9, 1, 1.0)
        drawShadowText("[Click] Gear Tape: " .. (MyPlayerProfile.gearTape or "Wrist"), 75, 355, 0.8, 0.9, 1, 1.0)
        
        -- Create New Player Button
        local hoverReset = checkHover(75, 390, 230, 30)
        love.graphics.setColor(hoverReset and {0.8, 0.2, 0.2} or {0.6, 0.15, 0.15})
        love.graphics.rectangle("fill", 75, 390, 230, 30, 4, 4)
        drawShadowText("CREATE NEW PLAYER", 75, 396, 1, 1, 1, 0.9, "center", 230)
        
        -- Center Gauge
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", 340, 140, 280, 290, 8, 8)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 340, 140, 280, 290, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText("OVR RATING", 340, 160, 1, 1, 1, 1.6, "center", 280)
        drawShadowText(tostring(MyPlayerProfile.ovr), 340, 200, 0.2, 0.8, 1, 4.5, "center", 280)
        
        drawShadowText("XP TO NEXT SP:", 340, 320, 1, 1, 1, 1.0, "center", 280)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 360, 345, 240, 18, 9, 9)
        local xpPct = math.min(1, MyPlayerProfile.xp / MyPlayerProfile.xpToNext)
        love.graphics.setColor(C_AMBER)
        love.graphics.rectangle("fill", 360, 345, 240 * xpPct, 18, 9, 9)
        drawShadowText(MyPlayerProfile.xp .. " / " .. MyPlayerProfile.xpToNext, 340, 375, 1, 1, 1, 0.9, "center", 280)
        
        -- Right Gear Preview
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", 640, 140, 260, 290, 8, 8)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 640, 140, 260, 290, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText("GEAR PREVIEW", 640, 155, 1, 0.84, 0, 1.2, "center", 260)
        
        -- Draw custom helmet & visor silhouette
        local AssetManager = require("src.engine.asset_manager")
        local previewX, previewY = 710, 185
        local previewW, previewH = 120, 160
        love.graphics.setColor(0.06, 0.08, 0.12)
        love.graphics.rectangle("fill", previewX, previewY, previewW, previewH, 6, 6)
        AssetManager.drawPlayerPortrait(previewX, previewY, previewW, previewH, MyPlayerProfile.name, MyPlayerProfile.position, true, true)
        
        drawShadowText("Helmet: " .. MyPlayerProfile.helmetStyle, 640, 360, 1, 1, 1, 0.95, "center", 260)
        drawShadowText("Visor: " .. MyPlayerProfile.visorTint, 640, 380, 1, 1, 1, 0.95, "center", 260)
        drawShadowText("Tape: " .. MyPlayerProfile.gearTape, 640, 400, 1, 1, 1, 0.95, "center", 260)
        
    elseif self.tab == "QUESTS" then
        love.graphics.setColor(C_SLATE_CONTAINER)
        love.graphics.rectangle("fill", 60, 140, 840, 290, 8, 8)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 60, 140, 840, 290, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText("CAREER STATS & SUPER BOWL MILESTONES", 80, 160, 1, 0.84, 0, 1.4)
        drawShadowText("• Total Career Yards: " .. MyPlayerProfile.totalYards, 80, 210, 0.8, 0.9, 1, 1.1)
        drawShadowText("• Total Career Touchdowns: " .. MyPlayerProfile.totalTouchdowns, 80, 245, 0.8, 0.9, 1, 1.1)
        drawShadowText("• Super Bowl Rings Won: " .. (MyPlayerProfile.superBowlRings or 0), 80, 280, 1, 0.84, 0, 1.1)
    end
    
    love.graphics.setColor(self.backBtn.color)
    love.graphics.rectangle("fill", self.backBtn.x, self.backBtn.y, self.backBtn.w, self.backBtn.h, 6, 6)
    drawShadowText(self.backBtn.name, self.backBtn.x, self.backBtn.y + 10, 1, 1, 1, 1.1, "center", self.backBtn.w)
end

function StateMyPlayer:mousepressed(x, y, button)
    if button == 1 then
        if self.creatorActive then
            -- Click Name box
            if checkHover(90, 170, 280, 35) then
                self.focusedField = "name"
                SoundManager.playSFX("click")
                return
            else
                self.focusedField = nil
            end
            
            -- Click Position buttons
            local positions = {"QB", "RB", "TE", "WR"}
            for idx, pos in ipairs(positions) do
                if checkHover(90 + (idx - 1) * 70, 245, 60, 32) then
                    self.creatorPosition = pos
                    self.creatorArchetype = posArchetypes[pos][1]
                    SoundManager.playSFX("click")
                    return
                end
            end
            
            -- Click Archetype Left arrow
            if checkHover(90, 320, 30, 32) then
                local archs = posArchetypes[self.creatorPosition]
                local curIdx = 1
                for idx, a in ipairs(archs) do
                    if a == self.creatorArchetype then curIdx = idx end
                end
                self.creatorArchetype = archs[curIdx == 1 and #archs or curIdx - 1]
                SoundManager.playSFX("click")
                return
            end
            
            -- Click Archetype Right arrow
            if checkHover(340, 320, 30, 32) then
                local archs = posArchetypes[self.creatorPosition]
                local curIdx = 1
                for idx, a in ipairs(archs) do
                    if a == self.creatorArchetype then curIdx = idx end
                end
                self.creatorArchetype = archs[curIdx == #archs and 1 or curIdx + 1]
                SoundManager.playSFX("click")
                return
            end
            
            -- Click Confirm & Reset
            if checkHover(90, 410, 240, 40) then
                if self.creatorName == "" or self.creatorName:match("^%s*$") then
                    self.creatorName = "Rookie"
                end
                
                local details = archetypeDetails[self.creatorArchetype] or { chip = 10, mult = 2.0, desc = "Provides team bonus." }
                MyPlayerProfile.isCreated = true
                MyPlayerProfile.name = self.creatorName
                MyPlayerProfile.position = self.creatorPosition
                MyPlayerProfile.archetypeTitle = self.creatorArchetype
                MyPlayerProfile.baseChips = details.chip
                MyPlayerProfile.baseMult = details.mult
                MyPlayerProfile.abilityDesc = details.desc
                
                -- Reset career progress
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
                
                self.creatorActive = false
                self.firstTimePrompt = false
                SoundManager.playSFX("touchdown")
                return
            end
            
            -- Click Cancel
            if not self.firstTimePrompt and checkHover(345, 410, 125, 40) then
                self.creatorActive = false
                SoundManager.playSFX("click")
                return
            end
            return
        end
        
        -- Non-creator clicks
        if checkHover(self.backBtn.x, self.backBtn.y, self.backBtn.w, self.backBtn.h) then
            SoundManager.playSFX("click")
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
            return
        end
        if checkHover(self.treeBtn.x, self.treeBtn.y, self.treeBtn.w, self.treeBtn.h) then
            SoundManager.playSFX("click")
            local StateMyPlayerTree = require("src.states.state_myplayer_tree")
            StateManager.switch(StateMyPlayerTree)
            return
        end
        for _, t in ipairs(self.tabs) do
            if checkHover(t.x, t.y, t.w, t.h) then
                self.tab = t.id
                SoundManager.playSFX("click")
                return
            end
        end
        
        if self.tab == "OVERVIEW" then
            -- Change position button click
            if checkHover(185, 192, 120, 22) then
                self:changePositionClass()
                return
            end
            
            -- Create New Player Button click
            if checkHover(75, 390, 230, 30) then
                self.creatorActive = true
                self.creatorName = MyPlayerProfile.name or "Rookie"
                self.creatorPosition = MyPlayerProfile.position or "QB"
                self.creatorArchetype = MyPlayerProfile.archetypeTitle or "Gunslinger"
                self.focusedField = "name"
                SoundManager.playSFX("click")
                return
            end
            
            -- Helmet Style click
            if checkHover(75, 295, 200, 25) then
                local styles = {"Classic", "Modern", "Speed"}
                local curIdx = 1
                for i, s in ipairs(styles) do
                    if s == MyPlayerProfile.helmetStyle then curIdx = i end
                end
                MyPlayerProfile.helmetStyle = styles[(curIdx % #styles) + 1]
                MyPlayerProfile.save()
                SoundManager.playSFX("click")
            end
            
            -- Visor Tint click
            if checkHover(75, 325, 200, 25) then
                local tints = {"Clear", "Dark", "Gold"}
                local curIdx = 1
                for i, t in ipairs(tints) do
                    if t == MyPlayerProfile.visorTint then curIdx = i end
                end
                MyPlayerProfile.visorTint = tints[(curIdx % #tints) + 1]
                MyPlayerProfile.save()
                SoundManager.playSFX("click")
            end
            
            -- Gear Tape click
            if checkHover(75, 355, 200, 25) then
                local tapes = {"None", "Wrist", "Elbow"}
                local curIdx = 1
                for i, t in ipairs(tapes) do
                    if t == MyPlayerProfile.gearTape then curIdx = i end
                end
                MyPlayerProfile.gearTape = tapes[(curIdx % #tapes) + 1]
                MyPlayerProfile.save()
                SoundManager.playSFX("click")
            end
        end
    end
end

function StateMyPlayer:keypressed(key)
    if self.creatorActive then
        if key == "escape" then
            if not self.firstTimePrompt then
                self.creatorActive = false
                SoundManager.playSFX("click")
            end
            return
        elseif key == "backspace" then
            self.creatorName = self.creatorName:sub(1, -2)
            SoundManager.playSFX("click")
            return
        elseif key == "space" then
            if #self.creatorName < 15 then
                self.creatorName = self.creatorName .. " "
                SoundManager.playSFX("click")
            end
            return
        elseif #key == 1 and #self.creatorName < 15 then
            if key:match("[%w%-]") then
                local char = key
                if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                    char = char:upper()
                end
                self.creatorName = self.creatorName .. char
                SoundManager.playSFX("click")
            end
            return
        end
    else
        if key == "escape" then
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
        end
    end
end

function StateMyPlayer:changePositionClass()
    if MyPlayerProfile.classPoints < 5 then return end
    
    -- Refund spent nodes
    local skillTreeNodes = require("src.data.skill_tree_nodes")
    local refund = 0
    for _, nodeId in ipairs(MyPlayerProfile.unlockedNodes or {}) do
        for _, n in ipairs(skillTreeNodes.list) do
            if n.id == nodeId then
                refund = refund + n.cost
                break
            end
        end
    end
    
    -- Cycle Position
    local positions = {"QB", "RB", "TE", "WR"}
    local nextIdx = 1
    for idx, pos in ipairs(positions) do
        if pos == MyPlayerProfile.position then
            nextIdx = (idx % #positions) + 1
            break
        end
    end
    local newPos = positions[nextIdx]
    
    -- Default archetypes
    local posArchetypes = {
        QB = {"Gunslinger", "Scrambler", "Field General"},
        RB = {"Power Back", "Elusive", "Receiving"},
        TE = {"Blocking TE", "Security Blanket", "Vertical Threat"},
        WR = {"Deep Threat", "Route Runner", "Possession"}
    }
    local newArch = posArchetypes[newPos][1]
    
    local archetypeDetails = {
        Gunslinger = { chip = 15, mult = 2.5, desc = "+15 Chips on pass play cards" },
        Scrambler = { chip = 20, mult = 1.8, desc = "+20 Chips on run play cards" },
        ["Field General"] = { chip = 10, mult = 3.0, desc = "+3.0x Mult on all pass cards" },
        ["Power Back"] = { chip = 25, mult = 1.5, desc = "+25 Chips on inside run plays" },
        Elusive = { chip = 12, mult = 2.8, desc = "+2.8x Mult on outside run plays" },
        Receiving = { chip = 15, mult = 2.0, desc = "+15 Chips on screen play cards" },
        ["Blocking TE"] = { chip = 20, mult = 1.5, desc = "+20 Chips on run plays" },
        ["Security Blanket"] = { chip = 15, mult = 2.2, desc = "+15 Chips on short pass plays" },
        ["Vertical Threat"] = { chip = 10, mult = 3.0, desc = "+3.0x Mult on deep pass plays" },
        ["Deep Threat"] = { chip = 10, mult = 3.5, desc = "+3.5x Mult on deep pass plays" },
        ["Route Runner"] = { chip = 20, mult = 2.0, desc = "+20 Chips on medium passes" },
        Possession = { chip = 15, mult = 2.5, desc = "+15 Chips / +2.5x Mult on 3rd down" }
    }
    
    local details = archetypeDetails[newArch]
    MyPlayerProfile.classPoints = MyPlayerProfile.classPoints + refund - 5
    MyPlayerProfile.position = newPos
    MyPlayerProfile.archetypeTitle = newArch
    MyPlayerProfile.unlockedNodes = {}
    if details then
        MyPlayerProfile.baseChips = details.chip
        MyPlayerProfile.baseMult = details.mult
        MyPlayerProfile.abilityDesc = details.desc
    end
    
    MyPlayerProfile.save()
    SoundManager.playSFX("touchdown")
end

return StateMyPlayer
