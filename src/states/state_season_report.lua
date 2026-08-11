-- src/states/state_season_report.lua
-- Stylised End-of-Season Report Card — shareable summary screen
local StateManager = require("src.states.state_manager")
local SoundManager = require("src.engine.sound_manager")
local SaveManager  = require("src.engine.save_manager")
local FxManager    = require("src.engine.fx_manager")

local StateSeasonReport = {}

local C_GOLD  = {1.0, 0.84, 0.0}
local C_BLUE  = {0.0, 0.76, 1.0}
local C_RED   = {1.0, 0.3,  0.3}
local C_GREEN = {0.18,0.72, 0.45}
local C_DARK  = {0.06,0.08, 0.12}
local C_SLATE = {0.129,0.149,0.192}

local function drawShadowText(text, x, y, r, g, b, scale, align, limit)
    scale = scale or 1
    love.graphics.setColor(0, 0, 0, 0.9)
    if align and limit then
        love.graphics.printf(text, x+1, y+1, limit/scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x+1, y+1, 0, scale, scale)
    end
    love.graphics.setColor(r or 1, g or 1, b or 1, 1)
    if align and limit then
        love.graphics.printf(text, x, y, limit/scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x, y, 0, scale, scale)
    end
end

-- Grade system
local function calcGrade(pct)
    if pct >= 0.95 then return "S+", {1.0,0.84,0.0}
    elseif pct >= 0.85 then return "S",  {1.0,0.84,0.0}
    elseif pct >= 0.75 then return "A",  {0.2,0.85,0.4}
    elseif pct >= 0.60 then return "B",  {0.0,0.76,1.0}
    elseif pct >= 0.45 then return "C",  {0.8,0.8,0.8}
    elseif pct >= 0.30 then return "D",  {1.0,0.6,0.0}
    else return "F", {1.0,0.3,0.3} end
end

function StateSeasonReport:enter(data)
    self.data    = data or {}
    self.time    = 0
    self.animT   = 0
    self.visible = false

    -- Pull persistent stats from SaveManager
    local sd = SaveManager.data or {}
    self.rings     = sd.superBowlRings  or 0
    self.careerTDs = sd.touchdownCount  or 0
    self.highYards = sd.highYards       or 0

    -- Run data
    self.runTDs       = self.data.touchdownsThisRun or 0
    self.runYards     = self.data.totalYardsGained  or 0
    self.runAnte      = self.data.anteReached       or 1
    self.runWeeks     = self.data.weeksPlayed       or 0
    self.bestPlay     = self.data.bestPlayName      or "—"
    self.bestPlayYds  = self.data.bestPlayYards     or 0
    self.won          = self.data.didWin            or false

    -- Compute letter grade  (0..1 based on ante reached)
    local maxAnte = 8
    local scorePct = math.min(1.0, self.runAnte / maxAnte)
    self.grade, self.gradeColor = calcGrade(scorePct)

    FxManager.clear()
    if self.won then
        FxManager.triggerCelebrationFireworks()
    end

    -- back button
    self.backBtn = {x=380, y=490, w=200, h=38}

    SoundManager.playMusic("menu_theme")

    -- staggered reveal timer
    self.visible = false
    self.revealTimer = 0.4
end

function StateSeasonReport:update(dt)
    self.time = self.time + dt
    self.animT = math.min(1.0, self.animT + dt * 1.4)

    if self.revealTimer > 0 then
        self.revealTimer = self.revealTimer - dt
        if self.revealTimer <= 0 then
            self.visible = true
        end
    end
end

function StateSeasonReport:draw()
    -- Background
    love.graphics.setColor(C_DARK)
    love.graphics.rectangle("fill", 0, 0, 960, 540)

    -- Animated scanlines
    love.graphics.setColor(0.1, 0.15, 0.22, 0.25)
    for i = 0, 27 do
        local yy = (i * 24 + self.time * 12) % 560
        love.graphics.rectangle("fill", 0, yy, 960, 10)
    end

    if not self.visible then return end

    local anim = self.animT

    -- Main card panel
    local px, py, pw, ph = 50, 30, 860, 480
    love.graphics.setColor(C_SLATE)
    love.graphics.rectangle("fill", px, py, pw, ph, 12, 12)

    -- Border colour = win gold / loss red
    local borderCol = self.won and C_GOLD or C_RED
    love.graphics.setColor(borderCol)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", px, py, pw, ph, 12, 12)
    love.graphics.setLineWidth(1)

    -- Header stripe
    love.graphics.setColor(borderCol[1], borderCol[2], borderCol[3], 0.18)
    love.graphics.rectangle("fill", px, py, pw, 64, 12, 12)

    -- Title
    local headerText = self.won and "SEASON COMPLETE — CHAMPION!" or "SEASON OVER — BETTER LUCK NEXT TIME"
    drawShadowText(headerText, px, py + 18, borderCol[1], borderCol[2], borderCol[3], 1.3, "center", pw)

    -- Grade badge (right side)
    local gx, gy = px + pw - 110, py + 10
    love.graphics.setColor(self.gradeColor)
    love.graphics.rectangle("fill", gx, gy, 90, 90, 10, 10)
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.printf(self.grade, gx, gy + 14, 90, "center", 0, 3.5, 3.5)

    -- ── Stats columns ──────────────────────────────────────────────
    local col1x, col2x = px + 40, px + pw/2 + 20
    local rowY = py + 90

    local function statRow(label, value, col, color)
        local cx = (col == 1) and col1x or col2x
        local c = color or {1,1,1}
        drawShadowText(label, cx, rowY, 0.7, 0.75, 0.8, 0.85)
        drawShadowText(tostring(value), cx + 220, rowY, c[1], c[2], c[3], 1.0)
        rowY = rowY + 28
        if col == 2 then rowY = rowY end
    end

    -- This run
    drawShadowText("THIS SEASON", col1x, rowY, 1.0, 0.84, 0.0, 1.1)
    drawShadowText("CAREER RECORDS", col2x, rowY, 1.0, 0.84, 0.0, 1.1)
    rowY = rowY + 30

    drawShadowText("Ante Reached:", col1x, rowY, 0.7, 0.75, 0.8, 0.85)
    drawShadowText(tostring(self.runAnte) .. " / 8", col1x + 220, rowY, C_GOLD[1], C_GOLD[2], C_GOLD[3], 1.0)
    drawShadowText("Super Bowl Rings:", col2x, rowY, 0.7, 0.75, 0.8, 0.85)
    drawShadowText(string.rep("💍", math.min(self.rings, 8)), col2x + 220, rowY, C_GOLD[1], C_GOLD[2], C_GOLD[3], 1.0)
    rowY = rowY + 28

    drawShadowText("Touchdowns:", col1x, rowY, 0.7, 0.75, 0.8, 0.85)
    drawShadowText(tostring(self.runTDs), col1x + 220, rowY, C_GREEN[1], C_GREEN[2], C_GREEN[3], 1.0)
    drawShadowText("Career TDs:", col2x, rowY, 0.7, 0.75, 0.8, 0.85)
    drawShadowText(tostring(self.careerTDs), col2x + 220, rowY, C_GREEN[1], C_GREEN[2], C_GREEN[3], 1.0)
    rowY = rowY + 28

    drawShadowText("Total Yards:", col1x, rowY, 0.7, 0.75, 0.8, 0.85)
    drawShadowText(tostring(self.runYards) .. " YDS", col1x + 220, rowY, C_BLUE[1], C_BLUE[2], C_BLUE[3], 1.0)
    drawShadowText("Longest Play:", col2x, rowY, 0.7, 0.75, 0.8, 0.85)
    drawShadowText(tostring(self.highYards) .. " YDS", col2x + 220, rowY, C_BLUE[1], C_BLUE[2], C_BLUE[3], 1.0)
    rowY = rowY + 28

    drawShadowText("Best Play:", col1x, rowY, 0.7, 0.75, 0.8, 0.85)
    local bestPlayStr = self.bestPlay:sub(1,18) .. (self.bestPlayYds > 0 and (" +"..self.bestPlayYds.."YDS") or "")
    drawShadowText(bestPlayStr, col1x + 220, rowY, 1, 1, 1, 0.85)
    rowY = rowY + 36

    -- Divider
    love.graphics.setColor(0.25, 0.3, 0.4, 0.8)
    love.graphics.rectangle("fill", px + 30, rowY, pw - 60, 2)
    rowY = rowY + 14

    -- Legend status
    local legendText = (self.rings >= 5 and "DYNASTY GOAT 🐐") or (self.rings >= 1 and "CHAMPION 🏆") or "CONTENDER"
    drawShadowText("LEGEND STATUS: " .. legendText, px, rowY, C_GOLD[1], C_GOLD[2], C_GOLD[3], 1.15, "center", pw)

    -- ── Back button ──────────────────────────────────────────────
    local mx, my = love.mouse.getPosition()
    local bb = self.backBtn
    local hover = mx >= bb.x and mx <= bb.x+bb.w and my >= bb.y and my <= bb.y+bb.h
    love.graphics.setColor(hover and {0.0,0.76,1.0} or {0.18,0.22,0.3})
    love.graphics.rectangle("fill", bb.x, bb.y, bb.w, bb.h, 6, 6)
    love.graphics.setColor(C_BLUE)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", bb.x, bb.y, bb.w, bb.h, 6, 6)
    love.graphics.setLineWidth(1)
    drawShadowText("BACK TO MENU", bb.x, bb.y + 11, 1, 1, 1, 0.95, "center", bb.w)
end

function StateSeasonReport:mousepressed(x, y, button)
    if button == 1 then
        local bb = self.backBtn
        if x >= bb.x and x <= bb.x+bb.w and y >= bb.y and y <= bb.y+bb.h then
            SoundManager.playSFX("click")
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
        end
    end
end

function StateSeasonReport:keypressed(key)
    if key == "escape" or key == "return" or key == "space" then
        SoundManager.playSFX("click")
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    end
end

return StateSeasonReport
