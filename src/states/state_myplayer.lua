-- src/states/state_myplayer.lua
-- Retro Bowl-Style Player Editor with Spotlight Stage
local StateManager = require("src.states.state_manager")
local MyPlayerProfile = require("src.data.myplayer_profile")
local PlayerVisualProfile = require("src.data.player_visual_profile")
local SoundManager = require("src.engine.sound_manager")
local AssetManager = require("src.engine.asset_manager")

local StateMyPlayer = {}

local C_BG = {0.06, 0.08, 0.12}
local C_PANEL = {0.10, 0.12, 0.16}
local C_HIGHLIGHT = {0.18, 0.65, 0.15}
local C_NEON_CYAN = {0.0, 0.76, 1.0}
local C_GOLD = {1.0, 0.84, 0.0}
local C_WHITE = {1, 1, 1}
local C_DIM = {0.5, 0.5, 0.55}
local C_RED = {0.8, 0.2, 0.2}

local function checkHover(hx, hy, hw, hh)
    local mx, my = love.mouse.getPosition()
    return mx >= hx and mx <= (hx + hw) and my >= hy and my <= (hy + hh)
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

-- Draw a blocky segment stat bar (4 segments)
local function drawSegmentBar(label, value, x, y)
    local maxSeg = 4
    local filled = math.floor((value / 99) * maxSeg + 0.5)
    drawShadowText(label, x, y, 0.7, 0.7, 0.7, 0.9)
    for s = 1, maxSeg do
        if s <= filled then
            love.graphics.setColor(C_HIGHLIGHT)
        else
            love.graphics.setColor(0.2, 0.22, 0.25)
        end
        love.graphics.rectangle("fill", x + 36 + (s - 1) * 14, y + 2, 11, 10)
    end
end

-- Editor row option definitions
local function buildEditorRows()
    return {
        { label = "JERSEY NO", field = "jerseyNumber", type = "number", min = 0, max = 99 },
        { label = "POSITION", field = "_position", type = "cycle", options = {"QB", "RB", "WR", "TE"} },
        { label = "FACEMASK", field = "facemask", type = "cycle", options = PlayerVisualProfile.facemaskOptions },
        { label = "VISOR", field = "visor", type = "cycle", options = PlayerVisualProfile.visorOptions },
        { label = "HELMET CLR", field = "shellColor", type = "color" },
        { label = "EARRINGS", field = "earrings", type = "cycle", options = PlayerVisualProfile.earringOptions },
        { label = "JERSEY CLR", field = "primaryColor", type = "color" },
        { label = "GLOVES", field = "handGear", type = "cycle", options = PlayerVisualProfile.handGearOptions },
        { label = "GLOVE CLR", field = "handGearColor", type = "cycle", options = PlayerVisualProfile.handGearColorOptions },
        { label = "HAIR", field = "hairStyle", type = "cycle", options = PlayerVisualProfile.hairStyleOptions },
        { label = "HAIR CLR", field = "hairColor", type = "haircolor" },
        { label = "SKIN TONE", field = "skinTone", type = "number", min = 1, max = 8 },
        { label = "EYE BLACK", field = "eyeBlack", type = "cycle", options = PlayerVisualProfile.eyeBlackOptions },
        { label = "BUILD", field = "archetype", type = "cycle", options = PlayerVisualProfile.archetypeOptions },
        { label = "SLEEVES", field = "armGear", type = "cycle", options = PlayerVisualProfile.armGearOptions },
        { label = "CALF SLVS", field = "calfSleeves", type = "cycle", options = PlayerVisualProfile.calfSleeveOptions },
        { label = "CLEATS", field = "cleats", type = "cycle", options = PlayerVisualProfile.cleatsOptions },
    }
end

function StateMyPlayer:enter()
    self.rows = buildEditorRows()
    self.selectedRow = 1
    self.scrollOffset = 0
    self.maxVisibleRows = 11
    
    self.creatorName = MyPlayerProfile.name or "Rookie"
    self.creatorPosition = MyPlayerProfile.position or "QB"
    self.focusedField = nil
    
    -- Camera for dynamic locker room framing
    self.camScale = 10.0
    self.targetCamScale = 10.0
    self.camY = 310
    self.targetCamY = 310
    
    love.keyboard.setTextInput(false)
end

function StateMyPlayer:exit()
    MyPlayerProfile.save()
end

function StateMyPlayer:update(dt)
    self.camScale = self.camScale + (self.targetCamScale - self.camScale) * 8 * dt
    self.camY = self.camY + (self.targetCamY - self.camY) * 8 * dt
end

local function getFieldValue(field)
    if field == "_position" then
        return MyPlayerProfile.position or "QB"
    end
    return PlayerVisualProfile[field]
end

local function setFieldValue(field, val)
    if field == "_position" then
        MyPlayerProfile.position = val
        return
    end
    PlayerVisualProfile[field] = val
end

local function cycleOption(options, current, dir)
    local idx = 1
    for i, v in ipairs(options) do
        if v == current then idx = i; break end
    end
    idx = idx + dir
    if idx < 1 then idx = #options end
    if idx > #options then idx = 1 end
    return options[idx]
end

function StateMyPlayer:draw()
    -- Background
    love.graphics.setColor(C_BG)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Title
    drawShadowText("Player Editor", 0, 12, 1, 1, 1, 1.8, "center", 960)
    
    -- ═══════════════════════════════════════════════════════════════
    -- LEFT PANEL: Bust Portrait + Name + Stats (0-260)
    -- ═══════════════════════════════════════════════════════════════
    local bustX, bustY, bustW, bustH = 20, 55, 220, 200
    love.graphics.setColor(0.08, 0.1, 0.14)
    love.graphics.rectangle("fill", bustX, bustY, bustW, bustH, 6, 6)
    
    -- Bust portrait background gradient
    love.graphics.setColor(0.15, 0.08, 0.18, 0.6)
    love.graphics.rectangle("fill", bustX, bustY, bustW, bustH * 0.5, 6, 6)
    
    -- Draw bust portrait (using clipping to keep it in the box)
    local teamColors = { primary = PlayerVisualProfile.primaryColor, secondary = PlayerVisualProfile.shellColor }
    if _G.GameStateData and _G.GameStateData.config and _G.GameStateData.config.team then
        teamColors.primary = _G.GameStateData.config.team.primaryColor or teamColors.primary
        teamColors.secondary = _G.GameStateData.config.team.secondaryColor or teamColors.secondary
    end
    
    love.graphics.setScissor(bustX, bustY, bustW, bustH)
    AssetManager.drawModularPlayer(
        bustX + bustW / 2, bustY + bustH + 40,
        12.0, PlayerVisualProfile, teamColors
    )
    love.graphics.setScissor()
    
    love.graphics.setColor(C_NEON_CYAN[1], C_NEON_CYAN[2], C_NEON_CYAN[3], 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bustX, bustY, bustW, bustH, 6, 6)
    love.graphics.setLineWidth(1)
    
    -- Player name (editable)
    local nameY = bustY + bustH + 8
    drawShadowText(self.creatorName:upper(), bustX, nameY, 1, 1, 1, 1.3)
    
    -- OVR + Position
    drawShadowText("OVR: " .. (MyPlayerProfile.ovr or 70) .. "  |  " .. self.creatorPosition, bustX, nameY + 22, C_GOLD[1], C_GOLD[2], C_GOLD[3], 0.95)
    
    -- Stat bars
    local statY = nameY + 48
    local stats = {
        {"SKL", MyPlayerProfile.ovr or 70},
        {"STR", 75}, {"SPD", 82}, {"STM", 78}, {"AGI", 80}, {"INJ", 90}
    }
    for i, s in ipairs(stats) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        drawSegmentBar(s[1], s[2], bustX + col * 110, statY + row * 22)
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- CENTER: Full-Body Spotlight Stage (260-620)
    -- ═══════════════════════════════════════════════════════════════
    local stageX, stageY, stageW, stageH = 260, 55, 340, 420
    love.graphics.setColor(0.04, 0.05, 0.08)
    love.graphics.rectangle("fill", stageX, stageY, stageW, stageH, 8, 8)
    
    -- Spotlight cone (triangle gradient effect)
    love.graphics.setColor(1, 1, 1, 0.04)
    love.graphics.polygon("fill",
        stageX + stageW/2 - 20, stageY,
        stageX + stageW/2 + 20, stageY,
        stageX + stageW/2 + 80, stageY + stageH,
        stageX + stageW/2 - 80, stageY + stageH
    )
    love.graphics.setColor(1, 1, 1, 0.02)
    love.graphics.polygon("fill",
        stageX + stageW/2 - 10, stageY,
        stageX + stageW/2 + 10, stageY,
        stageX + stageW/2 + 50, stageY + stageH,
        stageX + stageW/2 - 50, stageY + stageH
    )
    
    -- Floor / pedestal
    love.graphics.setColor(0.12, 0.14, 0.18)
    love.graphics.ellipse("fill", stageX + stageW/2, stageY + stageH - 40, 60, 12)
    love.graphics.setColor(0.18, 0.2, 0.25)
    love.graphics.ellipse("fill", stageX + stageW/2, stageY + stageH - 40, 50, 8)
    
    -- Full body player sprite
    local time = love.timer.getTime()
    AssetManager.drawModularPlayer(
        stageX + stageW/2, self.camY,
        self.camScale * 0.8, PlayerVisualProfile, teamColors,
        true, time, false
    )
    
    love.graphics.setColor(C_NEON_CYAN[1], C_NEON_CYAN[2], C_NEON_CYAN[3], 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", stageX, stageY, stageW, stageH, 8, 8)
    
    -- ═══════════════════════════════════════════════════════════════
    -- RIGHT PANEL: Customization Controls (620-940)
    -- ═══════════════════════════════════════════════════════════════
    local panelX, panelY, panelW = 620, 55, 320
    love.graphics.setColor(C_PANEL)
    love.graphics.rectangle("fill", panelX, panelY, panelW, 420, 6, 6)
    
    local rowH = 34
    local visStart = self.scrollOffset + 1
    local visEnd = math.min(#self.rows, self.scrollOffset + self.maxVisibleRows)
    
    for vi = visStart, visEnd do
        local row = self.rows[vi]
        local ry = panelY + 8 + (vi - visStart) * rowH
        local isSel = (vi == self.selectedRow)
        
        -- Selection highlight
        if isSel then
            love.graphics.setColor(C_HIGHLIGHT[1], C_HIGHLIGHT[2], C_HIGHLIGHT[3], 0.25)
            love.graphics.rectangle("fill", panelX + 4, ry - 2, panelW - 8, rowH - 2, 4, 4)
            love.graphics.setColor(C_HIGHLIGHT)
            love.graphics.rectangle("fill", panelX + 4, ry - 2, 3, rowH - 2)
        end
        
        -- Label
        drawShadowText(row.label, panelX + 14, ry + 6, 0.8, 0.8, 0.8, 0.9)
        
        -- Value display
        local val = getFieldValue(row.field)
        local valStr = ""
        
        if row.type == "number" then
            valStr = tostring(val)
        elseif row.type == "cycle" then
            if type(val) == "number" then
                valStr = tostring(val)
            else
                valStr = tostring(val):upper()
            end
        elseif row.type == "color" then
            -- Draw color swatch
            local c = val or {1, 1, 1}
            love.graphics.setColor(c)
            love.graphics.rectangle("fill", panelX + panelW - 44, ry + 4, 24, 18, 3, 3)
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.rectangle("line", panelX + panelW - 44, ry + 4, 24, 18, 3, 3)
        elseif row.type == "haircolor" then
            local c = val or {0.1, 0.1, 0.1}
            love.graphics.setColor(c)
            love.graphics.rectangle("fill", panelX + panelW - 44, ry + 4, 24, 18, 3, 3)
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.rectangle("line", panelX + panelW - 44, ry + 4, 24, 18, 3, 3)
        end
        
        if row.type ~= "color" and row.type ~= "haircolor" then
            -- Draw arrows + value text
            local arrowColor = isSel and C_HIGHLIGHT or C_DIM
            drawShadowText("<", panelX + panelW - 95, ry + 4, arrowColor[1], arrowColor[2], arrowColor[3], 1.1)
            drawShadowText(valStr, panelX + panelW - 75, ry + 6, 1, 1, 1, 0.95, "center", 50)
            drawShadowText(">", panelX + panelW - 20, ry + 4, arrowColor[1], arrowColor[2], arrowColor[3], 1.1)
        else
            drawShadowText("<", panelX + panelW - 75, ry + 4, isSel and C_HIGHLIGHT or C_DIM, 1.1)
            drawShadowText(">", panelX + panelW - 14, ry + 4, isSel and C_HIGHLIGHT or C_DIM, 1.1)
        end
    end
    
    -- Scroll indicator
    if #self.rows > self.maxVisibleRows then
        local scrollPct = self.scrollOffset / (#self.rows - self.maxVisibleRows)
        local barH = 420 - 16
        local thumbH = math.max(20, barH * (self.maxVisibleRows / #self.rows))
        love.graphics.setColor(0.25, 0.28, 0.32)
        love.graphics.rectangle("fill", panelX + panelW - 6, panelY + 8, 4, barH, 2, 2)
        love.graphics.setColor(C_HIGHLIGHT)
        love.graphics.rectangle("fill", panelX + panelW - 6, panelY + 8 + scrollPct * (barH - thumbH), 4, thumbH, 2, 2)
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- BOTTOM BAR: Controls
    -- ═══════════════════════════════════════════════════════════════
    love.graphics.setColor(0.08, 0.1, 0.14)
    love.graphics.rectangle("fill", 0, 490, 960, 50)
    
    -- Back button
    local hBack = checkHover(20, 498, 120, 32)
    love.graphics.setColor(hBack and {1, 0.3, 0.3} or C_RED)
    love.graphics.rectangle("fill", 20, 498, 120, 32, 5, 5)
    drawShadowText("B  back", 20, 505, 1, 1, 1, 0.95, "center", 120)
    
    -- Randomize
    local hRand = checkHover(420, 498, 120, 32)
    love.graphics.setColor(hRand and {0.0, 0.9, 1.0} or C_NEON_CYAN)
    love.graphics.rectangle("fill", 420, 498, 120, 32, 5, 5)
    drawShadowText("RANDOMISE", 420, 505, 0, 0, 0, 0.95, "center", 120)
    
    -- Skill Tree
    local hTree = checkHover(820, 498, 120, 32)
    love.graphics.setColor(hTree and {1, 0.9, 0.0} or C_GOLD)
    love.graphics.rectangle("fill", 820, 498, 120, 32, 5, 5)
    drawShadowText("SKILL TREE", 820, 505, 0, 0, 0, 0.95, "center", 120)
end

function StateMyPlayer:adjustRow(dir)
    local row = self.rows[self.selectedRow]
    if not row then return end
    local val = getFieldValue(row.field)
    
    if row.type == "number" then
        val = (tonumber(val) or row.min) + dir
        if val < row.min then val = row.max end
        if val > row.max then val = row.min end
        setFieldValue(row.field, val)
    elseif row.type == "cycle" then
        setFieldValue(row.field, cycleOption(row.options, val, dir))
    elseif row.type == "color" then
        local palette = PlayerVisualProfile.colorPalette
        local idx = 1
        for i, c in ipairs(palette) do
            if c[1] == val[1] and c[2] == val[2] and c[3] == val[3] then idx = i; break end
        end
        idx = idx + dir
        if idx < 1 then idx = #palette end
        if idx > #palette then idx = 1 end
        setFieldValue(row.field, palette[idx])
    elseif row.type == "haircolor" then
        local palette = PlayerVisualProfile.hairColorPalette
        local idx = 1
        for i, c in ipairs(palette) do
            if c[1] == val[1] and c[2] == val[2] and c[3] == val[3] then idx = i; break end
        end
        idx = idx + dir
        if idx < 1 then idx = #palette end
        if idx > #palette then idx = 1 end
        setFieldValue(row.field, palette[idx])
    end
    SoundManager.playSFX("click")
end

function StateMyPlayer:keypressed(key)
    if key == "up" then
        self.selectedRow = math.max(1, self.selectedRow - 1)
        if self.selectedRow <= self.scrollOffset then
            self.scrollOffset = self.selectedRow - 1
        end
        SoundManager.playSFX("click")
    elseif key == "down" then
        self.selectedRow = math.min(#self.rows, self.selectedRow + 1)
        if self.selectedRow > self.scrollOffset + self.maxVisibleRows then
            self.scrollOffset = self.selectedRow - self.maxVisibleRows
        end
        SoundManager.playSFX("click")
    elseif key == "left" then
        self:adjustRow(-1)
    elseif key == "right" then
        self:adjustRow(1)
    elseif key == "escape" then
        MyPlayerProfile.name = self.creatorName
        MyPlayerProfile.save()
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    elseif key == "r" then
        PlayerVisualProfile.randomize()
        SoundManager.playSFX("coin")
    end
end

function StateMyPlayer:mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Bottom buttons
    if checkHover(20, 498, 120, 32) then
        MyPlayerProfile.name = self.creatorName
        MyPlayerProfile.save()
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
        SoundManager.playSFX("click")
        return
    end
    if checkHover(420, 498, 120, 32) then
        PlayerVisualProfile.randomize()
        SoundManager.playSFX("coin")
        return
    end
    if checkHover(820, 498, 120, 32) then
        SoundManager.playSFX("click")
        local StateMyPlayerTree = require("src.states.state_myplayer_tree")
        StateManager.switch(StateMyPlayerTree)
        return
    end
    
    -- Right panel row clicks
    local panelX, panelY = 620, 55
    local panelW = 320
    local rowH = 34
    local visStart = self.scrollOffset + 1
    local visEnd = math.min(#self.rows, self.scrollOffset + self.maxVisibleRows)
    
    for vi = visStart, visEnd do
        local ry = panelY + 8 + (vi - visStart) * rowH
        if x >= panelX and x <= panelX + panelW and y >= ry and y <= ry + rowH then
            self.selectedRow = vi
            -- Precise left/right arrow click hitboxes
            if x >= panelX + panelW - 110 and x <= panelX + panelW - 60 then
                self:adjustRow(-1)
            elseif x >= panelX + panelW - 55 and x <= panelX + panelW then
                self:adjustRow(1)
            else
                SoundManager.playSFX("click")
            end
            return
        end
    end
end

function StateMyPlayer:wheelmoved(wx, wy)
    if wy > 0 then
        self.scrollOffset = math.max(0, self.scrollOffset - 1)
    elseif wy < 0 then
        self.scrollOffset = math.min(#self.rows - self.maxVisibleRows, self.scrollOffset + 1)
    end
end

function StateMyPlayer:textinput(t)
    if self.focusedField == "name" then
        if #self.creatorName < 15 then
            self.creatorName = self.creatorName .. t
            MyPlayerProfile.name = self.creatorName
        end
    end
end

return StateMyPlayer
