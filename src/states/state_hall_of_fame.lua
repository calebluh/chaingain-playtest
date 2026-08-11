-- src/states/state_hall_of_fame.lua
local StateManager = require("src.states.state_manager")
local SaveManager  = require("src.engine.save_manager")
local SoundManager = require("src.engine.sound_manager")

local StateHallOfFame = {}

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

function StateHallOfFame:enter()
    self.selectedTab = 1  -- 1 = Trophies, 2 = Run History
    self.time = 0
end

function StateHallOfFame:update(dt)
    self.time = self.time + dt
end

function StateHallOfFame:draw()
    love.graphics.setColor(0.08, 0.1, 0.14)
    love.graphics.rectangle("fill", 0, 0, 960, 540)

    -- Background glow
    local p = (math.sin(self.time * 1.5) + 1) * 0.04 + 0.08
    love.graphics.setColor(1.0, 0.84, 0.0, p)
    love.graphics.circle("fill", 480, 270, 360)

    -- Main Container
    love.graphics.setColor(0.12, 0.15, 0.2)
    love.graphics.rectangle("fill", 55, 35, 850, 470, 10, 10)
    love.graphics.setColor(1.0, 0.84, 0.0, 0.9)
    love.graphics.setLineWidth(2.5)
    love.graphics.rectangle("line", 55, 35, 850, 470, 10, 10)
    love.graphics.setLineWidth(1)

    -- Header Title
    love.graphics.setColor(1.0, 0.84, 0.0)
    love.graphics.printf("🏆 CHAIN GAIN HALL OF FAME 🏆", 55, 50, 850, "center", 0, 1.6, 1.6)

    -- Tab Buttons
    local tabs = {"TROPHIES", "RUN HISTORY"}
    for i, tab in ipairs(tabs) do
        local tx = 80 + (i-1) * 200
        local isActive = (self.selectedTab == i)
        local mx, my = love.mouse.getPosition()
        local hover = mx >= tx and mx <= tx+180 and my >= 96 and my <= 120
        love.graphics.setColor(isActive and {1.0,0.84,0.0} or (hover and {0.3,0.35,0.45} or {0.18,0.22,0.3}))
        love.graphics.rectangle("fill", tx, 96, 180, 24, 4, 4)
        love.graphics.setColor(isActive and {0,0,0} or {1,1,1})
        love.graphics.printf(tab, tx, 100, 180, "center", 0, 0.85, 0.85)
    end

    local sd = SaveManager.data or {}
    local rings     = sd.superBowlRings or 0
    local tdCount   = sd.touchdownCount or 0
    local highYards = sd.highYards      or 0

    -- Stats Row
    love.graphics.setColor(0.16, 0.2, 0.28, 1)
    love.graphics.rectangle("fill", 80, 128, 790, 56, 6, 6)
    love.graphics.setColor(0.0, 0.76, 1.0, 0.7)
    love.graphics.rectangle("line", 80, 128, 790, 56, 6, 6)

    love.graphics.setColor(1,1,1,1)
    love.graphics.print("💍 RINGS: " .. rings, 105, 142, 0, 1.05, 1.05)
    love.graphics.print("🏈 CAREER TDs: " .. tdCount, 305, 142, 0, 1.05, 1.05)
    love.graphics.print("⚡ LONGEST PLAY: " .. highYards .. " YDS", 530, 142, 0, 1.05, 1.05)
    local legend = rings >= 5 and "GOAT" or (rings >= 1 and "CHAMP" or "CONTENDER")
    love.graphics.setColor(1.0, 0.84, 0.0, 1)
    love.graphics.print("STATUS: " .. legend, 740, 142, 0, 1.0, 1.0)

    -- ── Tab: TROPHIES ─────────────────────────────────────────────
    if self.selectedTab == 1 then
        local trophies = {
            { name = "ROOKIE BOWL",      desc = "Won First Game",     icon = "🥉", unlocked = tdCount  >= 1 },
            { name = "LOMBARDI TROPHY",  desc = "Super Bowl Champ",   icon = "🏆", unlocked = rings    >= 1 },
            { name = "DYNASTY RING",     desc = "3x Super Bowls",     icon = "💍", unlocked = rings    >= 3 },
            { name = "CENTURY CLUB",     desc = "50+ Yd Single Play", icon = "⚡", unlocked = highYards>= 50 },
            { name = "GOAT STATUS",      desc = "5x Super Bowls",     icon = "🐐", unlocked = rings    >= 5 },
            { name = "TOUCHDOWN KING",   desc = "100+ Career TDs",    icon = "👑", unlocked = tdCount  >= 100 },
        }

        for i, tr in ipairs(trophies) do
            local col = (i-1) % 3
            local row = math.floor((i-1) / 3)
            local tx = 95 + col * 260
            local ty = 200 + row * 140
            love.graphics.setColor(tr.unlocked and {0.2,0.25,0.35} or {0.1,0.12,0.16})
            love.graphics.rectangle("fill", tx, ty, 240, 120, 6, 6)
            love.graphics.setColor(tr.unlocked and {1.0,0.84,0.0} or {0.3,0.3,0.3})
            love.graphics.rectangle("line", tx, ty, 240, 120, 6, 6)

            love.graphics.printf(tr.unlocked and tr.icon or "🔒", tx, ty + 14, 240, "center", 0, 2.0, 2.0)
            love.graphics.setColor(tr.unlocked and {1,1,1} or {0.45,0.45,0.45})
            love.graphics.printf(tr.name, tx+5, ty + 76, 230, "center", 0, 0.85, 0.85)
            love.graphics.setColor(tr.unlocked and {0.0,0.76,1.0} or {0.35,0.35,0.35})
            love.graphics.printf(tr.desc, tx+5, ty + 96, 230, "center", 0, 0.72, 0.72)
        end

    -- ── Tab: RUN HISTORY ──────────────────────────────────────────
    elseif self.selectedTab == 2 then
        local history = (sd.runHistory) or {}

        if #history == 0 then
            love.graphics.setColor(0.5,0.5,0.6,1)
            love.graphics.printf("No seasons played yet. Get out there, Coach!", 80, 280, 790, "center", 0, 1.2, 1.2)
        else
            drawShadowText("SEASON", 105, 208, 1.0, 0.84, 0.0, 0.85)
            drawShadowText("ANTE REACHED", 260, 208, 1.0, 0.84, 0.0, 0.85)
            drawShadowText("TOTAL YARDS", 470, 208, 1.0, 0.84, 0.0, 0.85)
            drawShadowText("DATE", 700, 208, 1.0, 0.84, 0.0, 0.85)

            for i, run in ipairs(history) do
                local ry = 224 + (i-1) * 24
                love.graphics.setColor(i % 2 == 0 and {0.15,0.18,0.24} or {0.12,0.15,0.2})
                love.graphics.rectangle("fill", 85, ry, 780, 22)
                local anteLabel = "Ante " .. (run.ante or "?")
                local gradeColor = (run.ante or 1) >= 7 and {1.0,0.84,0.0} or ((run.ante or 1) >= 4 and {0.2,0.85,0.4} or {0.8,0.8,0.8})
                drawShadowText("#" .. i, 105, ry + 3, 0.8, 0.8, 0.8, 0.82)
                drawShadowText(anteLabel, 260, ry + 3, gradeColor[1], gradeColor[2], gradeColor[3], 0.82)
                drawShadowText((run.yards or 0) .. " YDS", 470, ry + 3, 0.0, 0.76, 1.0, 0.82)
                drawShadowText(run.date or "—", 700, ry + 3, 0.7, 0.75, 0.8, 0.82)
            end
        end
    end

    -- Back Button
    local mx, my = love.mouse.getPosition()
    local hoverBack = (mx >= 80 and mx <= 210 and my >= 458 and my <= 492)
    love.graphics.setColor(hoverBack and {0.9,0.3,0.3} or {0.7,0.2,0.2})
    love.graphics.rectangle("fill", 80, 458, 130, 34, 6, 6)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("BACK", 80, 467, 130, "center")
end

function StateHallOfFame:mousepressed(x, y, button)
    if button == 1 then
        -- Tab switching
        for i = 1, 2 do
            local tx = 80 + (i-1) * 200
            if x >= tx and x <= tx+180 and y >= 96 and y <= 120 then
                self.selectedTab = i
                SoundManager.playSFX("click")
                return
            end
        end
        -- Back button
        if x >= 80 and x <= 210 and y >= 458 and y <= 492 then
            SoundManager.playSFX("click")
            local StateMenu = require("src.states.state_menu")
            StateManager.switch(StateMenu)
        end
    end
end

function StateHallOfFame:keypressed(key)
    if key == "escape" then
        SoundManager.playSFX("click")
        local StateMenu = require("src.states.state_menu")
        StateManager.switch(StateMenu)
    elseif key == "tab" then
        self.selectedTab = (self.selectedTab % 2) + 1
    end
end


return StateHallOfFame
