-- src/states/state_myplayer.lua
local StateManager = require("src.states.state_manager")
local MyPlayerProfile = require("src.data.myplayer_profile")
local PlayerVisualProfile = require("src.data.player_visual_profile")
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

function StateMyPlayer:enter()
    self.tab = "BODY"
    self.tabs = {
        { id = "BODY", name = "BODY & FACE", x = 60, y = 70, w = 150, h = 36 },
        { id = "HELMET", name = "HELMET & VISOR", x = 220, y = 70, w = 150, h = 36 },
        { id = "JERSEY", name = "JERSEY & NUMBER", x = 380, y = 70, w = 150, h = 36 },
        { id = "GEAR", name = "GEAR & CLEATS", x = 540, y = 70, w = 150, h = 36 },
        { id = "STATS", name = "MILESTONES", x = 700, y = 70, w = 150, h = 36 }
    }
    
    self.backBtn = { x = 60, y = 475, w = 160, h = 42, name = "MAIN MENU", color = {0.8, 0.2, 0.2} }
    self.treeBtn = { x = 740, y = 475, w = 160, h = 42, name = "SKILL TREE", color = C_AMBER }
    self.randBtn = { x = 240, y = 475, w = 160, h = 42, name = "RANDOMISE", color = C_BLUE }
    
    self.creatorName = MyPlayerProfile.name or "Rookie"
    self.creatorPosition = MyPlayerProfile.position or "QB"
    self.focusedField = nil
    
    -- Camera for dynamic AAA locker room framing
    self.camScale = 8.0
    self.targetCamScale = 8.0
    self.camY = 290
    self.targetCamY = 290
end

function StateMyPlayer:exit()
    MyPlayerProfile.save()
end

function StateMyPlayer:update(dt)
    -- AAA Camera Lerping
    if self.tab == "HELMET" then
        self.targetCamScale = 14.0
        self.targetCamY = 380
    elseif self.tab == "GEAR" then
        self.targetCamScale = 9.0
        self.targetCamY = 190
    else
        self.targetCamScale = 8.0
        self.targetCamY = 290
    end
    
    self.camScale = self.camScale + (self.targetCamScale - self.camScale) * 8 * dt
    self.camY = self.camY + (self.targetCamY - self.camY) * 8 * dt
end

function StateMyPlayer:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    drawShadowText("CHARACTER CUSTOMIZATION & MYPLAYER HUB", 60, 20, 1, 0.84, 0, 1.8)
    
    -- Render Tab Bar
    for _, t in ipairs(self.tabs) do
        local isSelected = (self.tab == t.id)
        local hover = checkHover(t.x, t.y, t.w, t.h)
        love.graphics.setColor(isSelected and C_BLUE or (hover and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
        love.graphics.rectangle("fill", t.x, t.y, t.w, t.h, 6, 6)
        drawShadowText(t.name, t.x, t.y + 10, 1, 1, 1, 0.95, "center", t.w)
    end
    
    -- LEFT PANEL: 3D Locker Room Preview Box
    love.graphics.setColor(0.08, 0.09, 0.11)
    love.graphics.rectangle("fill", 60, 120, 260, 340, 8, 8)
    
    -- Draw Locker details inside clip
    love.graphics.setScissor(60, 120, 260, 340)
    
    -- Floor
    love.graphics.setColor(0.12, 0.13, 0.15)
    love.graphics.polygon("fill", 60, 420, 320, 420, 280, 460, 100, 460)
    -- Lockers
    love.graphics.setColor(0.15, 0.16, 0.18)
    for i=0, 2 do
        love.graphics.rectangle("line", 75 + i*75, 140, 65, 260, 4, 4)
    end
    -- Neon Logo
    local time = love.timer.getTime()
    love.graphics.setColor(0.0, 0.76, 1.0, 0.3 + 0.1 * math.sin(time*4))
    drawShadowText("CHAIN GAIN", 190, 180, 0, 0.76, 1.0, 1.3, "center", 200)
    
    -- Character Portrait Preview
    local AssetManager = require("src.engine.asset_manager")
    AssetManager.drawRetroPlayer(190, self.camY, PlayerVisualProfile.primaryColor or {0.13, 0.34, 0.13}, {0.9, 0.9, 0.9}, PlayerVisualProfile.shellColor or {0.07, 0.13, 0.27}, 0, 0, true, time, false, true, self.camScale)
    
    love.graphics.setScissor()
    
    love.graphics.setColor(C_NEON_BORDER)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 60, 120, 260, 340, 8, 8)
    love.graphics.setLineWidth(1)
    
    drawShadowText("OVR: " .. (MyPlayerProfile.ovr or 70) .. "  |  POSITION: " .. self.creatorPosition, 70, 415, 1, 0.84, 0, 0.95, "center", 240)
    
    -- RIGHT PANEL: Tab Content Container
    love.graphics.setColor(C_SLATE_CONTAINER)
    love.graphics.rectangle("fill", 340, 120, 560, 340, 8, 8)
    love.graphics.setColor(0.22, 0.26, 0.34)
    love.graphics.rectangle("line", 340, 120, 560, 340, 8, 8)
    
    if self.tab == "BODY" then
        drawShadowText("BODY & FACE CUSTOMIZATION", 360, 140, 1, 0.84, 0, 1.3)
        
        -- Name Input Field
        drawShadowText("PLAYER NAME:", 360, 185, 0.8, 0.8, 0.8, 0.9)
        local isNameFocused = (self.focusedField == "name")
        love.graphics.setColor(isNameFocused and {0, 0.76, 1} or {0.18, 0.22, 0.28})
        love.graphics.rectangle("fill", 500, 180, 240, 30, 6, 6)
        drawShadowText(self.creatorName == "" and "Enter Name..." or self.creatorName, 510, 186, 1, 1, 1, 0.95)
        
        -- Archetype Build
        drawShadowText("BODY BUILD:", 360, 230, 0.8, 0.8, 0.8, 0.9)
        for i, arch in ipairs(PlayerVisualProfile.archetypeOptions) do
            local bx = 500 + (i - 1) * 80
            local isSel = (PlayerVisualProfile.archetype == arch)
            local h = checkHover(bx, 225, 75, 30)
            love.graphics.setColor(isSel and C_BLUE or (h and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
            love.graphics.rectangle("fill", bx, 225, 75, 30, 5, 5)
            drawShadowText(arch:upper(), bx, 232, 1, 1, 1, 0.85, "center", 75)
        end
        
        -- Skin Tone Palette
        drawShadowText("SKIN TONE:", 360, 280, 0.8, 0.8, 0.8, 0.9)
        for i, st in ipairs(PlayerVisualProfile.skinTones) do
            local sx = 500 + (i - 1) * 32
            local isSel = (PlayerVisualProfile.skinTone == i)
            love.graphics.setColor(st)
            love.graphics.circle("fill", sx, 288, isSel and 12 or 9)
            if isSel then
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("line", sx, 288, 13)
            end
        end
        
        -- Eye Black Style
        drawShadowText("EYE BLACK:", 360, 330, 0.8, 0.8, 0.8, 0.9)
        for i, eb in ipairs(PlayerVisualProfile.eyeBlackOptions) do
            local ebx = 500 + (i - 1) * 80
            local isSel = (PlayerVisualProfile.eyeBlack == eb)
            local h = checkHover(ebx, 325, 75, 30)
            love.graphics.setColor(isSel and C_BLUE or (h and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
            love.graphics.rectangle("fill", ebx, 325, 75, 30, 5, 5)
            drawShadowText(eb:upper(), ebx, 332, 1, 1, 1, 0.8, "center", 75)
        end

    elseif self.tab == "HELMET" then
        drawShadowText("HELMET & VISOR GEAR", 360, 140, 1, 0.84, 0, 1.3)
        
        -- Helmet Style
        drawShadowText("HELMET MODEL:", 360, 185, 0.8, 0.8, 0.8, 0.9)
        for i, hStyle in ipairs(PlayerVisualProfile.helmetOptions) do
            local hx = 500 + (i - 1) * 85
            local isSel = (PlayerVisualProfile.helmetStyle == hStyle)
            local h = checkHover(hx, 180, 80, 30)
            love.graphics.setColor(isSel and C_BLUE or (h and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
            love.graphics.rectangle("fill", hx, 180, 80, 30, 5, 5)
            drawShadowText(hStyle:upper(), hx, 187, 1, 1, 1, 0.8, "center", 80)
        end
        
        -- Visor Style
        drawShadowText("VISOR TINT:", 360, 235, 0.8, 0.8, 0.8, 0.9)
        for i, vStyle in ipairs(PlayerVisualProfile.visorOptions) do
            local vx = 500 + (i - 1) * 85
            local isSel = (PlayerVisualProfile.visor == vStyle)
            local h = checkHover(vx, 230, 80, 30)
            love.graphics.setColor(isSel and C_BLUE or (h and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
            love.graphics.rectangle("fill", vx, 230, 80, 30, 5, 5)
            drawShadowText(vStyle:upper(), vx, 237, 1, 1, 1, 0.8, "center", 80)
        end

    elseif self.tab == "JERSEY" then
        drawShadowText("JERSEY & UNIFORM STYLE", 360, 140, 1, 0.84, 0, 1.3)
        
        -- Jersey Cut
        drawShadowText("JERSEY CUT:", 360, 185, 0.8, 0.8, 0.8, 0.9)
        for i, jCut in ipairs(PlayerVisualProfile.jerseyCutOptions) do
            local jcx = 500 + (i - 1) * 90
            local isSel = (PlayerVisualProfile.jerseyCut == jCut)
            local h = checkHover(jcx, 180, 85, 30)
            love.graphics.setColor(isSel and C_BLUE or (h and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
            love.graphics.rectangle("fill", jcx, 180, 85, 30, 5, 5)
            drawShadowText(jCut:upper(), jcx, 187, 1, 1, 1, 0.8, "center", 85)
        end
        
        -- Jersey Number
        drawShadowText("JERSEY NUMBER:", 360, 235, 0.8, 0.8, 0.8, 0.9)
        local hoverMinus = checkHover(490, 230, 25, 25)
        love.graphics.setColor(hoverMinus and {0.8, 0.2, 0.2} or {0.6, 0.2, 0.2})
        love.graphics.rectangle("fill", 490, 230, 25, 25, 4, 4)
        drawShadowText("-", 490, 232, 1, 1, 1, 1.2, "center", 25)
        
        local isJerseyFocused = (self.focusedField == "jersey")
        love.graphics.setColor(isJerseyFocused and {0, 0.76, 1} or {0.18, 0.22, 0.28})
        love.graphics.rectangle("fill", 525, 230, 40, 25, 4, 4)
        drawShadowText(tostring(PlayerVisualProfile.jerseyNumber), 525, 232, 1, 0.84, 0, 1.2, "center", 40)
        
        local hoverPlus = checkHover(575, 230, 25, 25)
        love.graphics.setColor(hoverPlus and {0.2, 0.8, 0.2} or {0.2, 0.6, 0.2})
        love.graphics.rectangle("fill", 575, 230, 25, 25, 4, 4)
        drawShadowText("+", 575, 232, 1, 1, 1, 1.2, "center", 25)

    elseif self.tab == "GEAR" then
        drawShadowText("EQUIPMENT & ACCESSORIES", 360, 140, 1, 0.84, 0, 1.3)
        
        -- Arm Gear
        drawShadowText("SLEEVES:", 360, 185, 0.8, 0.8, 0.8, 0.9)
        for i, ag in ipairs(PlayerVisualProfile.armGearOptions) do
            local agx = 480 + (i - 1) * 75
            local isSel = (PlayerVisualProfile.armGear == ag)
            local h = checkHover(agx, 180, 70, 30)
            love.graphics.setColor(isSel and C_BLUE or (h and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
            love.graphics.rectangle("fill", agx, 180, 70, 30, 5, 5)
            drawShadowText(ag:upper(), agx, 187, 1, 1, 1, 0.65, "center", 70)
        end
        
        -- Hand Gear
        drawShadowText("GLOVES:", 360, 225, 0.8, 0.8, 0.8, 0.9)
        for i, hg in ipairs(PlayerVisualProfile.handGearOptions) do
            local hgx = 480 + (i - 1) * 75
            local isSel = (PlayerVisualProfile.handGear == hg)
            local h = checkHover(hgx, 220, 70, 30)
            love.graphics.setColor(isSel and C_BLUE or (h and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
            love.graphics.rectangle("fill", hgx, 220, 70, 30, 5, 5)
            drawShadowText(hg:upper(), hgx, 227, 1, 1, 1, 0.7, "center", 70)
        end
        
        -- Calf Sleeves
        drawShadowText("CALF SLVS:", 360, 265, 0.8, 0.8, 0.8, 0.9)
        for i, cs in ipairs(PlayerVisualProfile.calfSleeveOptions) do
            local csx = 480 + (i - 1) * 75
            local isSel = (PlayerVisualProfile.calfSleeves == cs)
            local h = checkHover(csx, 260, 70, 30)
            love.graphics.setColor(isSel and C_BLUE or (h and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
            love.graphics.rectangle("fill", csx, 260, 70, 30, 5, 5)
            drawShadowText(cs:upper(), csx, 267, 1, 1, 1, 0.65, "center", 70)
        end
        
        -- Cleats
        drawShadowText("CLEATS:", 360, 305, 0.8, 0.8, 0.8, 0.9)
        for i, cl in ipairs(PlayerVisualProfile.cleatsOptions) do
            local clx = 480 + (i - 1) * 75
            local isSel = (PlayerVisualProfile.cleats == cl)
            local h = checkHover(clx, 300, 70, 30)
            love.graphics.setColor(isSel and C_BLUE or (h and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
            love.graphics.rectangle("fill", clx, 300, 70, 30, 5, 5)
            drawShadowText(cl:upper(), clx, 307, 1, 1, 1, 0.7, "center", 70)
        end
        
        -- Toggles (Tattoos, Mouthguard)
        local hTat = checkHover(360, 345, 150, 30)
        love.graphics.setColor(PlayerVisualProfile.tattoos and C_BLUE or (hTat and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
        love.graphics.rectangle("fill", 360, 345, 150, 30, 5, 5)
        drawShadowText("TATTOOS", 360, 352, 1, 1, 1, 0.8, "center", 150)
        
        local hasMg = (PlayerVisualProfile.mouthguardColor ~= false)
        local hMg = checkHover(530, 345, 150, 30)
        love.graphics.setColor(hasMg and C_BLUE or (hMg and {0.3, 0.4, 0.5} or {0.18, 0.22, 0.28}))
        love.graphics.rectangle("fill", 530, 345, 150, 30, 5, 5)
        drawShadowText("MOUTHGUARD", 530, 352, 1, 1, 1, 0.8, "center", 150)

    elseif self.tab == "STATS" then
        drawShadowText("CAREER MILESTONES & STATS", 360, 140, 1, 0.84, 0, 1.3)
        
        drawShadowText("TOTAL YARDS: " .. (MyPlayerProfile.totalYards or 0), 360, 185, 1, 1, 1, 1.1)
        drawShadowText("TOUCHDOWNS: " .. (MyPlayerProfile.totalTouchdowns or 0), 360, 220, 1, 1, 1, 1.1)
        drawShadowText("SUPER BOWL RINGS: 🏆 " .. (MyPlayerProfile.superBowlRings or 0), 360, 255, 1, 0.84, 0, 1.1)
        drawShadowText("SEASONS PLAYED: " .. (MyPlayerProfile.seasonsPlayed or 0) .. " / " .. (MyPlayerProfile.maxSeasons or 10), 360, 290, 0.8, 0.8, 0.8, 1.1)
        drawShadowText("DEVELOPMENT TRAIT: " .. (MyPlayerProfile.devTrait or "Normal"), 360, 325, 0.0, 0.76, 1.0, 1.1)
    end
    
    -- BOTTOM BUTTON BAR
    local hBack = checkHover(self.backBtn.x, self.backBtn.y, self.backBtn.w, self.backBtn.h)
    love.graphics.setColor(hBack and {1, 0.3, 0.3} or self.backBtn.color)
    love.graphics.rectangle("fill", self.backBtn.x, self.backBtn.y, self.backBtn.w, self.backBtn.h, 6, 6)
    drawShadowText(self.backBtn.name, self.backBtn.x, self.backBtn.y + 12, 1, 1, 1, 1.0, "center", self.backBtn.w)
    
    local hRand = checkHover(self.randBtn.x, self.randBtn.y, self.randBtn.w, self.randBtn.h)
    love.graphics.setColor(hRand and {0.0, 0.76, 1.0} or self.randBtn.color)
    love.graphics.rectangle("fill", self.randBtn.x, self.randBtn.y, self.randBtn.w, self.randBtn.h, 6, 6)
    drawShadowText(self.randBtn.name, self.randBtn.x, self.randBtn.y + 12, 1, 1, 1, 1.0, "center", self.randBtn.w)
    
    local hTree = checkHover(self.treeBtn.x, self.treeBtn.y, self.treeBtn.w, self.treeBtn.h)
    love.graphics.setColor(hTree and {1, 0.84, 0} or self.treeBtn.color)
    love.graphics.rectangle("fill", self.treeBtn.x, self.treeBtn.y, self.treeBtn.w, self.treeBtn.h, 6, 6)
    drawShadowText(self.treeBtn.name, self.treeBtn.x, self.treeBtn.y + 12, 1, 1, 1, 1.0, "center", self.treeBtn.w)
end

function StateMyPlayer:mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        -- Check Tab Clicks
        for _, t in ipairs(self.tabs) do
            if checkHover(t.x, t.y, t.w, t.h) then
                self.tab = t.id
                SoundManager.playSFX("click")
                return
            end
        end
        
        -- Tab Specific Controls
        if self.tab == "BODY" then
            for i, arch in ipairs(PlayerVisualProfile.archetypeOptions) do
                local bx = 500 + (i - 1) * 80
                if checkHover(bx, 225, 75, 30) then
                    PlayerVisualProfile.archetype = arch
                    SoundManager.playSFX("click")
                end
            end
            for i, eb in ipairs(PlayerVisualProfile.eyeBlackOptions) do
                local ebx = 500 + (i - 1) * 80
                if checkHover(ebx, 325, 75, 30) then
                    PlayerVisualProfile.eyeBlack = eb
                    SoundManager.playSFX("click")
                end
            end
            for i = 1, #PlayerVisualProfile.skinTones do
                local sx = 500 + (i - 1) * 32
                local dx = x - sx
                local dy = y - 288
                if dx*dx + dy*dy <= 14*14 then
                    PlayerVisualProfile.skinTone = i
                    SoundManager.playSFX("click")
                end
            end
            if checkHover(500, 180, 240, 30) then
                self.focusedField = "name"
            else
                self.focusedField = nil
            end
        elseif self.tab == "HELMET" then
            for i, hStyle in ipairs(PlayerVisualProfile.helmetOptions) do
                local hx = 500 + (i - 1) * 85
                if checkHover(hx, 180, 80, 30) then
                    PlayerVisualProfile.helmetStyle = hStyle
                    SoundManager.playSFX("click")
                end
            end
            for i, vStyle in ipairs(PlayerVisualProfile.visorOptions) do
                local vx = 500 + (i - 1) * 85
                if checkHover(vx, 230, 80, 30) then
                    PlayerVisualProfile.visor = vStyle
                    SoundManager.playSFX("click")
                end
            end
        elseif self.tab == "JERSEY" then
            for i, jCut in ipairs(PlayerVisualProfile.jerseyCutOptions) do
                local jcx = 500 + (i - 1) * 90
                if checkHover(jcx, 180, 85, 30) then
                    PlayerVisualProfile.jerseyCut = jCut
                    SoundManager.playSFX("click")
                end
            end
            if checkHover(490, 230, 25, 25) then
                PlayerVisualProfile.jerseyNumber = tonumber(PlayerVisualProfile.jerseyNumber) or 12
                PlayerVisualProfile.jerseyNumber = math.max(0, PlayerVisualProfile.jerseyNumber - 1)
                SoundManager.playSFX("click")
            elseif checkHover(575, 230, 25, 25) then
                PlayerVisualProfile.jerseyNumber = tonumber(PlayerVisualProfile.jerseyNumber) or 12
                PlayerVisualProfile.jerseyNumber = math.min(99, PlayerVisualProfile.jerseyNumber + 1)
                SoundManager.playSFX("click")
            elseif checkHover(525, 230, 40, 25) then
                self.focusedField = "jersey"
                PlayerVisualProfile.jerseyNumber = ""
                SoundManager.playSFX("click")
            else
                if self.focusedField == "jersey" then
                    self.focusedField = nil
                    if PlayerVisualProfile.jerseyNumber == "" then PlayerVisualProfile.jerseyNumber = 12 end
                end
            end
        elseif self.tab == "GEAR" then
            for i, ag in ipairs(PlayerVisualProfile.armGearOptions) do
                local agx = 480 + (i - 1) * 75
                if checkHover(agx, 180, 70, 30) then
                    PlayerVisualProfile.armGear = ag
                    SoundManager.playSFX("click")
                end
            end
            for i, hg in ipairs(PlayerVisualProfile.handGearOptions) do
                local hgx = 480 + (i - 1) * 75
                if checkHover(hgx, 220, 70, 30) then
                    PlayerVisualProfile.handGear = hg
                    SoundManager.playSFX("click")
                end
            end
            for i, cs in ipairs(PlayerVisualProfile.calfSleeveOptions) do
                local csx = 480 + (i - 1) * 75
                if checkHover(csx, 260, 70, 30) then
                    PlayerVisualProfile.calfSleeves = cs
                    SoundManager.playSFX("click")
                end
            end
            for i, cl in ipairs(PlayerVisualProfile.cleatsOptions) do
                local clx = 480 + (i - 1) * 75
                if checkHover(clx, 300, 70, 30) then
                    PlayerVisualProfile.cleats = cl
                    SoundManager.playSFX("click")
                end
            end
            if checkHover(360, 345, 150, 30) then
                PlayerVisualProfile.tattoos = not PlayerVisualProfile.tattoos
                SoundManager.playSFX("click")
            end
            if checkHover(530, 345, 150, 30) then
                if PlayerVisualProfile.mouthguardColor == false then
                    PlayerVisualProfile.mouthguardColor = {1, 1, 1}
                else
                    PlayerVisualProfile.mouthguardColor = false
                end
                SoundManager.playSFX("click")
            end
        end
        
        -- Action Buttons
        if checkHover(self.backBtn.x, self.backBtn.y, self.backBtn.w, self.backBtn.h) then
            SoundManager.playSFX("click")
            MyPlayerProfile.name = self.creatorName
            MyPlayerProfile.save()
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
            return
        end
        
        if checkHover(self.randBtn.x, self.randBtn.y, self.randBtn.w, self.randBtn.h) then
            SoundManager.playSFX("coin")
            PlayerVisualProfile.randomize()
            return
        end
        
        if checkHover(self.treeBtn.x, self.treeBtn.y, self.treeBtn.w, self.treeBtn.h) then
            SoundManager.playSFX("click")
            local StateMyPlayerTree = require("src.states.state_myplayer_tree")
            StateManager.switch(StateMyPlayerTree)
            return
        end
    end
end

function StateMyPlayer:textinput(t)
    if self.focusedField == "name" then
        if #self.creatorName < 15 then
            self.creatorName = self.creatorName .. t
        end
    elseif self.focusedField == "jersey" then
        if t:match("%d") then
            local str = tostring(PlayerVisualProfile.jerseyNumber)
            if #str < 2 then
                PlayerVisualProfile.jerseyNumber = tonumber(str .. t)
            end
        end
    end
end

function StateMyPlayer:keypressed(key)
    if self.focusedField == "name" then
        if key == "backspace" then
            self.creatorName = self.creatorName:sub(1, -2)
        elseif key == "return" then
            self.focusedField = nil
        end
    elseif self.focusedField == "jersey" then
        if key == "backspace" then
            local str = tostring(PlayerVisualProfile.jerseyNumber)
            if #str > 1 then
                PlayerVisualProfile.jerseyNumber = tonumber(str:sub(1, -2))
            else
                PlayerVisualProfile.jerseyNumber = ""
            end
        elseif key == "return" then
            self.focusedField = nil
            if PlayerVisualProfile.jerseyNumber == "" then PlayerVisualProfile.jerseyNumber = 12 end
        end
    end
end

return StateMyPlayer
