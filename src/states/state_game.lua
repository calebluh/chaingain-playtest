-- src/states/state_game.lua
local GameStateData = require("src.engine.game_state")
local DeckManager = require("src.engine.deck_manager")
local DefenseManager = require("src.engine.defense_manager")
local PlayerCard = require("src.entities.player_card")
local CardRender = require("src.ui.card_render")
local ScoringEvaluator = require("src.engine.scoring_evaluator")
local FieldAnimator = require("src.ui.field_animator")
local StadiumPulse = require("src.engine.stadium_pulse")
local StateManager = require("src.states.state_manager")
local PhysicsUtils = require("src.engine.physics_utils")
local AssetManager = require("src.engine.asset_manager")
local SoundManager = require("src.engine.sound_manager")
local FxManager = require("src.engine.fx_manager")
local SaveManager = require("src.engine.save_manager")
local Loc = require("src.engine.loc_manager")
local SettingsData = require("src.data.settings_data")
local RPOMinigame = require("src.ui.rpo_minigame")
local TDReplay   = require("src.ui.touchdown_replay")
local BlindIntro = require("src.ui.blind_intro")

local StateGame = {}

local C_SLATE_CONTAINER = {0.129, 0.149, 0.192} -- #212631
local C_BORDER_NORMAL = {0.227, 0.259, 0.322} -- #3A4252
local C_NEON_BORDER = {0.0, 0.76, 1.0} -- #00C3FF
local C_NEON_ACCENT = {1.0, 0.84, 0.0} -- #FFD700
local C_CHIP_BLUE = {0.0, 0.58, 1.0} -- #0094FF
local C_MULT_RED = {1.0, 0.3, 0.3} -- #FF4D4D

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

local function drawNeonPanel(x, y, w, h, borderColor)
    love.graphics.setColor(C_SLATE_CONTAINER)
    love.graphics.rectangle("fill", x, y, w, h, 6, 6)
    
    love.graphics.setColor(borderColor or C_NEON_BORDER)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", x, y, w, h, 6, 6)
    love.graphics.setLineWidth(1)
end

function StateGame:enter()
    self.selectedPlayIndex = nil
    self.draggingCardIndex = nil
    self.dragLastX = 0
    self.time = 0
    self.paused = false
    self.showPlaybookModal = false
    self.hoveredRosterPlayer = nil
    self.justSelectedThisClick = false
    self.show4thDownPrompt = false
    self.was4thDown = false
    self.crowdRoarTimer = 0
    self.playbookShelfY = 545  -- start hidden (off-screen below)
    self.targetShelfY = 545
    
    FieldAnimator.startPlay("Run", 0, GameStateData.yardLine or 25, GameStateData.distance or 10, false, false)
    FieldAnimator.active = false
    
    if #DeckManager.hand == 0 then
        DeckManager.drawHand()
    end

    -- Ensure visual state for play cards is initialized so draw() won't error
    do
        local N = #DeckManager.hand
        local CARD_W = 128
        local gap = (N > 1) and math.max(8, math.min(52, (860 - N * CARD_W) / (N - 1))) or 0
        local startX = 480 - ((N - 1) * (CARD_W + gap)) / 2
        for i, card in ipairs(DeckManager.hand) do
            local targetX = startX + (i - 1) * (CARD_W + gap)
            local targetY = 430
            card.xOffset = card.xOffset or targetX
            card.yOffset = card.yOffset or targetY
            card.rot = card.rot or 0
            card.scale = card.scale or 1.0
            card.xVelocity = card.xVelocity or 0
            card.yVelocity = card.yVelocity or 0
            card.rotVelocity = card.rotVelocity or 0
            card.scaleVelocity = card.scaleVelocity or 0
        end
    end
    
    SoundManager.playMusic("gameplay_theme")
    
    -- Fire opponent trash-talk intro
    if DefenseManager.activeBlind then
        BlindIntro.trigger(DefenseManager.activeBlind)
    end
    
    local TutorialOverlay = require("src.ui.tutorial_overlay")
    if SaveManager.data and not SaveManager.data.hasCompletedTutorial then
        TutorialOverlay.start()
    end
end

function StateGame:exit()
end

function StateGame:update(dt)
    local CommentaryTicker = require("src.ui.commentary_ticker")
    CommentaryTicker.update(dt)

    local TutorialOverlay = require("src.ui.tutorial_overlay")
    TutorialOverlay.update(dt)
    if TutorialOverlay.active then return end

    -- TD Replay blocks all input/updates while active
    TDReplay.update(dt)
    if TDReplay.active then return end

    BlindIntro.update(dt)

    -- Dynamic crowd roar based on StadiumPulse tier
    self.crowdRoarTimer = (self.crowdRoarTimer or 0) - dt
    if self.crowdRoarTimer <= 0 then
        local pulse = StadiumPulse.pulse or 30
        if pulse >= 76 then
            SoundManager.playSFX("touchdown", 0.4 + math.random() * 0.1)
            self.crowdRoarTimer = 4.0
        elseif pulse >= 56 then
            SoundManager.playSFX("coin", 0.6)
            self.crowdRoarTimer = 6.0
        else
            self.crowdRoarTimer = 8.0
        end
    end

    if StateManager.isOverlayOpen() or self.showPlaybookModal then return end
    
    RPOMinigame.update(dt)
    if RPOMinigame.active then return end
    
    self.time = self.time + dt
    local weatherType = GameStateData.weather or "clear"
    FxManager.update(dt, weatherType)
    
    if FieldAnimator.active or ScoringEvaluator.active then
        self.targetShelfY = 540
    else
        self.targetShelfY = 380
    end
    self.playbookShelfY = PhysicsUtils.lerp(self.playbookShelfY, self.targetShelfY, 10 * dt)
    
    GameStateData.updatePlayClock(dt)
    ScoringEvaluator.update(dt)
    
    -- Handle Status Transitions when play animations complete
    if not ScoringEvaluator.active and not FieldAnimator.active then
        if GameStateData.status == "TOUCHDOWN" or GameStateData.status == "DRIVE_COMPLETE" then
            if GameStateData.drivesRemaining > 0 and GameStateData.currentPoints < GameStateData.targetPoints then
                GameStateData.startDrive()
                DeckManager.drawHand()
            elseif GameStateData.currentPoints >= GameStateData.targetPoints then
                GameStateData.status = "GAME_WON"
            else
                GameStateData.status = "GAME_LOST"
            end
        elseif GameStateData.status == "DRIVE_LOST" then
            if GameStateData.drivesRemaining > 0 then
                GameStateData.startDrive()
                DeckManager.drawHand()
            else
                GameStateData.status = "GAME_LOST"
            end
        elseif GameStateData.status == "GAME_WON" then
            if GameStateData.ante > 8 and not GameStateData.isEndless then
                GameStateData.status = "RUN_WON_PROMPT"
            else
                local StateShop = require("src.states.state_shop")
                StateManager.switch(StateShop)
            end
        elseif GameStateData.status == "GAME_LOST" or GameStateData.status == "TURNOVER" then
            -- Save run history entry
            local runData = {
                touchdownsThisRun = SaveManager.data and SaveManager.data.touchdownCount or 0,
                totalYardsGained  = GameStateData.totalYardsGained or 0,
                anteReached       = GameStateData.ante or 1,
                weeksPlayed       = GameStateData.gameWeek or 1,
                bestPlayName      = GameStateData.lastPlayResult and GameStateData.lastPlayResult:sub(1,24) or "N/A",
                bestPlayYards     = GameStateData.totalYardsGained or 0,
                didWin            = false,
            }
            -- Append to run history (last 10)
            local sd = SaveManager.data
            if sd then
                sd.runHistory = sd.runHistory or {}
                table.insert(sd.runHistory, 1, {
                    ante = runData.anteReached,
                    yards = runData.totalYardsGained,
                    date = os.date and os.date("%m/%d") or "TODAY"
                })
                if #sd.runHistory > 10 then
                    table.remove(sd.runHistory, 11)
                end
                SaveManager.save()
            end
            local StateSeasonReport = require("src.states.state_season_report")
            StateSeasonReport.data = runData
            StateManager.switch(StateSeasonReport)
        end
    end
    
    if GameStateData.down == 4 and GameStateData.status == "PLAYING" then
        if not self.was4thDown then
            self.show4thDownPrompt = true
            self.was4thDown = true
        end
    else
        self.was4thDown = false
        self.show4thDownPrompt = false
    end

    if self.selectedPlayIndex and self.selectedPlayIndex > #DeckManager.hand then
        self.selectedPlayIndex = nil
    end

    -- Madden-style play-call tray: visible when it's time to pick, hidden during animation
    local shouldShowCards = (GameStateData.status == "PLAYING")
        and not FieldAnimator.active
        and not ScoringEvaluator.active

    self.targetShelfY = shouldShowCards and 335 or 545
    -- Smooth lerp toward target (speed=8 → opens/closes in ~0.2s)
    self.playbookShelfY = self.playbookShelfY
        + (self.targetShelfY - self.playbookShelfY) * math.min(1, dt * 8)

    local mx, my = love.mouse.getPosition()
    local N = #DeckManager.hand
    local CARD_W = 280
    local CARD_H = 160
    local gap = 30
    local startX = 480 - ((N - 1) * (CARD_W + gap)) / 2
    local TRAY_BASE_Y = self.playbookShelfY + 85  -- cards float inside the shelf
    
    for i, card in ipairs(DeckManager.hand) do
        local targetX = startX + (i - 1) * (CARD_W + gap)
        local targetY = TRAY_BASE_Y
        
        local isHovered = (mx >= targetX - CARD_W/2 and mx <= targetX + CARD_W/2
            and my >= targetY - CARD_H/2 and my <= targetY + CARD_H/2)
        card.isHovered = isHovered
        
        if card.update then card:update(dt, isHovered, mx - targetX) end
        
        if i == self.selectedPlayIndex then
            targetY = TRAY_BASE_Y - 20
        elseif isHovered then
            targetY = TRAY_BASE_Y - 10
        end
        
        card.xOffset = card.xOffset or targetX
        card.yOffset = card.yOffset or targetY
        card.scale = card.scale or 1.0
        
        card.xVelocity = card.xVelocity or 0
        card.yVelocity = card.yVelocity or 0
        card.scaleVelocity = card.scaleVelocity or 0
        
        local targetScale = (i == self.selectedPlayIndex) and 1.05 or 1.0
        
        card.xOffset, card.xVelocity = PhysicsUtils.spring(card.xOffset, targetX, card.xVelocity, dt, 6, 0.9, 0)
        card.yOffset, card.yVelocity = PhysicsUtils.spring(card.yOffset, targetY, card.yVelocity, dt, 6, 0.9, 0)
        card.scale, card.scaleVelocity = PhysicsUtils.spring(card.scale, targetScale, card.scaleVelocity, dt, 6, 0.9, 0)
        card.rot = 0
    end
    
    self.dragLastX = mx
end

function StateGame:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Draw 2.5D Paper Mario Angled Field
    local FieldAnimator = require("src.ui.field_animator")
    FieldAnimator.draw()
    
    local weatherType = GameStateData.weather or "clear"
    FxManager.draw(weatherType)

    -- ── Card Tray Shelf Background (slides with playbookShelfY) ────────────────────
    -- Drawn BEFORE the HUD panels so the shelf never bleeds over the score bar.
    -- When tray is hidden (playbookShelfY≥540) nothing is drawn here.
    if self.playbookShelfY < 538 then
        love.graphics.setColor(0.05, 0.06, 0.09, 0.95)
        love.graphics.rectangle("fill", 0, self.playbookShelfY, 960, 540 - self.playbookShelfY + 10)
        -- Accent top edge line
        love.graphics.setColor(0.0, 0.76, 1.0, math.min(1, (538 - self.playbookShelfY) / 60))
        love.graphics.setLineWidth(2)
        love.graphics.line(0, self.playbookShelfY + 2, 960, self.playbookShelfY + 2)
        love.graphics.setLineWidth(1)
        -- Subtle tray label
        love.graphics.setColor(0.3, 0.35, 0.45, 0.6)
        love.graphics.printf("PLAYBOOK", 0, self.playbookShelfY + 5, 960, "center", 0, 0.72, 0.72)
    end

    local previewChips = 0
    local previewMult = 0
    
    if ScoringEvaluator.active then
        previewChips = math.floor(ScoringEvaluator.displayedChips)
        previewMult = ScoringEvaluator.displayedMult
    else
        local activeCard = DeckManager.hand[self.selectedPlayIndex]
        if activeCard then
            previewChips = activeCard.baseChips
            previewMult = activeCard.baseMult
            
            local rosterChips = 0
            local rosterMult = 0
            if GameStateData.rosterSlots then
                for posName, posData in pairs(GameStateData.rosterSlots) do
                    for _, player in ipairs(posData.cards) do
                        local chipBonus, multBonus = player:evaluatePlay(activeCard, GameStateData)
                        rosterChips = rosterChips + chipBonus
                        rosterMult = rosterMult + multBonus
                    end
                end
            end
            
            previewChips = previewChips + rosterChips
            previewMult = previewMult + rosterMult + (GameStateData.tempMultBoost or 0)
            previewChips, previewMult = DefenseManager.evaluatePlay(activeCard.type, previewChips, previewMult)
            previewMult = math.max(0.1, previewMult)
        end
    end

    local function drawHDPanel(px, py, pw, ph, colorOverride, innerColor)
        love.graphics.setColor(innerColor or {0.18, 0.22, 0.28, 0.95})
        love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)
        
        -- Top gradient highlight
        love.graphics.setColor(1, 1, 1, 0.08)
        love.graphics.rectangle("fill", px, py, pw, ph/2, 8, 8)
        
        love.graphics.setColor(colorOverride or {0.3, 0.35, 0.45, 1})
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", px, py, pw, ph, 8, 8)
        love.graphics.setLineWidth(1)
    end

    local panelY = 8
    
    -- 1. OPPONENT DEFENSE (Width: 190)
    drawHDPanel(12, panelY, 190, 68)
    drawShadowText("OPPONENT DEFENSE", 12, panelY + 6, 0.8, 0.8, 0.8, 0.85, "center", 190)
    -- Shield Icon Placeholder
    love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
    love.graphics.polygon("fill", 25, panelY + 30, 45, panelY + 30, 45, panelY + 45, 35, panelY + 55, 25, panelY + 45)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    love.graphics.polygon("fill", 35, panelY + 30, 45, panelY + 30, 45, panelY + 45, 35, panelY + 55)
    
    local tierStr = "DIFFICULTY: " .. (GameStateData.stakeTier or "white"):upper()
    if DefenseManager.activeBlind then
        drawShadowText(tierStr, 50, panelY + 28, 0.7, 0.7, 0.7, 0.7, "left")
        drawShadowText(DefenseManager.activeBlind.name, 50, panelY + 42, 1, 1, 1, 0.85, "left")
    end

    -- 2. YARDS & MULTIPLIER (Width: 260) (Moved left to fill space)
    drawHDPanel(210, panelY, 260, 68, {0.3, 0.45, 0.6})
    
    -- Blue Yards Pill
    love.graphics.setColor(0.2, 0.4, 0.7, 1)
    love.graphics.rectangle("fill", 218, panelY + 10, 100, 48, 8, 8)
    love.graphics.setColor(0.4, 0.6, 0.9, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 218, panelY + 10, 100, 48, 8, 8)
    love.graphics.setLineWidth(1)
    drawShadowText(tostring(previewChips) .. " YDS", 218, panelY + 24, 1, 1, 1, 1.2, "center", 100)
    
    -- Red X
    drawShadowText("X", 327, panelY + 24, 1, 0.3, 0.3, 1.2, "center", 20)
    
    -- Red Multiplier Pill (with Momentum / Fire glow)
    local streak = GameStateData.momentumStreak or 0
    local isFire = streak >= 3
    local isHeat = streak == 2
    
    local multBgColor = {0.7, 0.2, 0.2, 1}
    local multBorderColor = {0.9, 0.4, 0.4, 1}
    if isFire then
        local pulse = 0.5 + 0.5 * math.sin(self.time * 8)
        multBgColor = {0.85, 0.25 + pulse * 0.15, 0.0, 1}
        multBorderColor = {1.0, 0.84, 0.2, 1}
    elseif isHeat then
        multBgColor = {0.75, 0.35, 0.1, 1}
        multBorderColor = {1.0, 0.7, 0.3, 1}
    end
    
    love.graphics.setColor(multBgColor)
    love.graphics.rectangle("fill", 358, panelY + 10, 104, 48, 8, 8)
    love.graphics.setColor(multBorderColor)
    love.graphics.setLineWidth(isFire and 2.5 or 2)
    love.graphics.rectangle("line", 358, panelY + 10, 104, 48, 8, 8)
    love.graphics.setLineWidth(1)
    
    drawShadowText(string.format("x%.1f MTM", previewMult), 358, panelY + 18, 1, 1, 1, 1.1, "center", 104)
    if isFire then
        drawShadowText("🔥 ON FIRE!", 358, panelY + 36, 1.0, 0.84, 0.0, 0.75, "center", 104)
    elseif isHeat then
        drawShadowText("⚡ HEATING UP", 358, panelY + 36, 1.0, 0.8, 0.3, 0.75, "center", 104)
    else
        drawShadowText(string.format("x%.1f MTM", previewMult), 358, panelY + 36, 1, 1, 1, 0.7, "center", 104)
    end

    -- 3. ADJUSTMENTS (Width: 140) (Moved left to fill space)
    drawHDPanel(480, panelY, 140, 68, {1.0, 0.84, 0.0, 1})
    drawShadowText("ADJUST", 480, panelY + 4, 1, 0.84, 0, 0.85, "center", 140)
    for ci = 1, GameStateData.maxConsumables do
        local cx = 488 + (ci - 1) * 64
        local cy = panelY + 20
        local item = GameStateData.consumables[ci]
        love.graphics.setColor(item and {0.8, 0.3, 0.1} or {0.18, 0.22, 0.28})
        love.graphics.rectangle("fill", cx, cy, 58, 42, 6, 6)
        love.graphics.setColor({0.3, 0.35, 0.45})
        love.graphics.rectangle("line", cx, cy, 58, 42, 6, 6)
        if item then
            drawShadowText(item.name:sub(1, 7), cx + 2, cy + 14, 1, 1, 1, 0.75, "center", 54)
        else
            drawShadowText("[EMPTY]", cx + 2, cy + 24, 0.5, 0.5, 0.5, 0.75, "center", 54)
        end
    end

    -- 4. SCORE & CLOCK BOTTOM FOOTER
    -- White/Grey Bar Background
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.rectangle("fill", 0, 505, 960, 35)
    
    -- Bottom Footer Team Backgrounds
    love.graphics.setColor(0.06, 0.24, 0.15) -- Home Team Color (Eagles-esque)
    love.graphics.rectangle("fill", 150, 505, 120, 35)
    love.graphics.setColor(0.12, 0.18, 0.3) -- Away Team Color
    love.graphics.rectangle("fill", 450, 505, 120, 35)
    
    -- Footer Scores
    drawShadowText("CG", 160, 513, 1, 1, 1, 1.2)
    drawShadowText(tostring(GameStateData.currentPoints), 235, 513, 1, 1, 1, 1.2)
    
    drawShadowText("OPP", 460, 513, 1, 1, 1, 1.2)
    drawShadowText(tostring(GameStateData.targetPoints), 535, 513, 1, 1, 1, 1.2)
    
    -- Footer Clock
    local clockSecs = math.max(0, math.ceil(GameStateData.playClock))
    local clockStr = string.format("4th  0:%02d", clockSecs)
    drawShadowText(clockStr, 650, 513, 0.1, 0.1, 0.1, 1.2)
    
    -- Footer Down & Distance
    local downSuffix = {"st", "nd", "rd", "th"}
    local ddStr = GameStateData.down .. downSuffix[math.min(4, GameStateData.down)] .. " & " .. GameStateData.distance
    drawShadowText(ddStr, 800, 513, 0.1, 0.1, 0.1, 1.2)


    -- 6. SPEED TOGGLE (Width: 36)
    local hoverSpeed = checkHover(927, panelY, 36, 68)
    local speedStr = string.format("%.0fx", SettingsData.gameSpeed or 1.0)
    drawHDPanel(927, panelY, 36, 68, hoverSpeed and {1.0, 0.84, 0.0, 1} or {0.3, 0.35, 0.45, 1})
    drawShadowText("0", 927, panelY + 12, 1, 0.84, 0, 0.9, "center", 36)
    drawShadowText(speedStr, 927, panelY + 38, 1, 1, 1, 0.9, "center", 36)

    -- Progress Bar (Turf Field + Team Branded End Zones)
    local activeTeam = GameStateData.config and GameStateData.config.team
    local teamColor = activeTeam and activeTeam.primaryColor or {0.18, 0.72, 0.45}
    local teamSecColor = activeTeam and activeTeam.secondaryColor or {1.0, 0.84, 0.0}
    
    love.graphics.setColor(0.08, 0.1, 0.14, 0.9)
    love.graphics.rectangle("fill", 12, 82, 915, 18, 4, 4)
    
    -- End Zone (Right 10% Team Accent Stripe)
    love.graphics.setColor(teamSecColor[1]*0.7, teamSecColor[2]*0.7, teamSecColor[3]*0.7, 0.85)
    love.graphics.rectangle("fill", 12 + 915 * 0.9, 82, 915 * 0.1, 18, 0, 4)
    
    local pct = math.min(1.0, GameStateData.yardLine / 100)
    love.graphics.setColor(teamColor[1], teamColor[2], teamColor[3], 1)
    love.graphics.rectangle("fill", 12, 82, 915 * pct, 18, 4, 4)
    
    love.graphics.setColor(1, 0.84, 0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(12 + 915 * 0.65, 82, 12 + 915 * 0.65, 100)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(C_NEON_BORDER)
    love.graphics.rectangle("line", 12, 82, 915, 18, 4, 4)
    
    local ydsToEndZone = math.max(0, 100 - GameStateData.yardLine)
    drawShadowText("FIELD POSITION: " .. ballStr .. " (" .. ydsToEndZone .. " YDS TO END ZONE)", 12, 84, 1, 1, 1, 0.85, "center", 915)

    -- Stadium Pulse Meter
    StadiumPulse.draw(935, 10)

    -- Removed inline roster rendering to free up field view; moved to modal.
    -- 4th Down Decision Tree
    if self.show4thDownPrompt and GameStateData.status == "PLAYING" then
        love.graphics.setColor(0.12, 0.15, 0.22, 0.95)
        love.graphics.rectangle("fill", 160, 232, 640, 45, 8, 8)
        love.graphics.setColor(C_NEON_ACCENT)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 160, 232, 640, 45, 8, 8)
        love.graphics.setLineWidth(1)
        
        drawShadowText("4TH DOWN DECISION:", 170, 244, 1, 0.84, 0, 1.1)
        
        local isPlayHover = checkHover(340, 240, 140, 30)
        love.graphics.setColor(isPlayHover and {0.0, 0.76, 1.0} or C_CHIP_BLUE)
        love.graphics.rectangle("fill", 340, 240, 140, 30, 6, 6)
        drawShadowText("GO FOR IT", 340, 248, 1, 1, 1, 0.9, "center", 140)
        
        local canFG = GameStateData.yardLine >= 65
        local isFgHover = canFG and checkHover(490, 240, 150, 30)
        love.graphics.setColor(canFG and (isFgHover and {0.0, 0.76, 1.0} or C_NEON_ACCENT) or {0.2, 0.2, 0.2})
        love.graphics.rectangle("fill", 490, 240, 150, 30, 6, 6)
        drawShadowText(canFG and "KICK FG (+3 PTS)" or "FG OUT OF RANGE", 490, 248, canFG and 1 or 0.5, canFG and 1 or 0.5, canFG and 1 or 0.5, 0.85, "center", 150)
        
        local isPuntHover = checkHover(650, 240, 140, 30)
        love.graphics.setColor(isPuntHover and {0.0, 0.76, 1.0} or C_BORDER_NORMAL)
        love.graphics.rectangle("fill", 650, 240, 140, 30, 6, 6)
        drawShadowText("PUNT BALL", 650, 248, 1, 1, 1, 0.9, "center", 140)
    end

    -- (Playbook slide-up shelf background is now replaced by the permanent tray shelf drawn above)


    -- Play Cards (Wide Madden-style panels)
    self.hoveredPlayCard = nil
    local mx, my = love.mouse.getPosition()
    local CARD_W_DRAW = 280
    local CARD_H_DRAW = 160
    for i, card in ipairs(DeckManager.hand) do
        local isHover = mx >= card.xOffset - CARD_W_DRAW/2 and mx <= card.xOffset + CARD_W_DRAW/2
            and my >= card.yOffset - CARD_H_DRAW/2 and my <= card.yOffset + CARD_H_DRAW/2
        if isHover then
            self.hoveredPlayCard = card
        end
        
        love.graphics.push()
        love.graphics.translate(card.xOffset, card.yOffset)
        love.graphics.scale(card.scale or 1.0, card.scale or 1.0)
        
        CardRender.drawPlayCard(0, 0, card, i == self.selectedPlayIndex, self.time)
        
        love.graphics.pop()
    end

    -- 1st/2nd/3rd Down Call Play Button (if card selected)
    if GameStateData.down < 4 and GameStateData.status == "PLAYING" and self.selectedPlayIndex then
        local playCard = DeckManager.hand[self.selectedPlayIndex]
        local ScoringEvaluator = require("src.engine.scoring_evaluator")
        local risk, riskType = ScoringEvaluator.calculateTurnoverRisk(playCard, GameStateData)
        
        local isPlayHover = checkHover(380, 240, 200, 30)
        local buttonColor = C_CHIP_BLUE
        local neonColor = C_NEON_BORDER
        if risk > 0 then
            buttonColor = isPlayHover and {1.0, 0.45, 0.0} or {0.85, 0.3, 0.0}
            neonColor = {1.0, 0.7, 0.0}
        else
            buttonColor = isPlayHover and {0.0, 0.76, 1.0} or C_CHIP_BLUE
        end
        
        love.graphics.setColor(buttonColor)
        love.graphics.rectangle("fill", 380, 240, 200, 30, 6, 6)
        love.graphics.setColor(neonColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 380, 240, 200, 30, 6, 6)
        love.graphics.setLineWidth(1)
        
        local buttonText = "CALL PLAY"
        if risk > 0 then
            buttonText = string.format("CALL PLAY (%s: %d%%)", riskType, risk)
        end
        drawShadowText(buttonText, 380, 248, 1, 1, 1, 0.85, "center", 200)
    end

    -- Hover Tooltip
    if self.hoveredRosterPlayer then
        CardRender.drawTooltip(mx, my, self.hoveredRosterPlayer)
    elseif self.hoveredPlayCard then
        CardRender.drawTooltip(mx, my, self.hoveredPlayCard)
    end
    
    -- RPOMinigame is drawn below
    
    RPOMinigame.draw()

    -- Status Banners & Navigation (slide with tray so they hide during play animation)
    if GameStateData.status == "PLAYING" then
        local trayOpen = self.playbookShelfY < 520
        -- Defensive tell and controls hint — only show when tray is visible
        if trayOpen then
            local hintY = self.playbookShelfY + 150
            if DefenseManager.currentPlay then
                drawShadowText("DEFENSIVE TELL: " .. DefenseManager.currentPlay.hint, 20, hintY, 0.8, 1, 0.8, 1.1)
                hintY = hintY + 17
            end
            drawShadowText("[Click/Drag]: Call Play | [Right-Click]: Flip Card | [Q]: Audible | [ESC]: Pause", 20, hintY + 10, 1, 1, 1, 0.85)
            
            local btnY = self.playbookShelfY + 140
            local isPlaybookHover = checkHover(800, btnY, 145, 28)
            love.graphics.setColor(isPlaybookHover and {0.0, 0.76, 1.0} or {0.129, 0.149, 0.192})
            love.graphics.rectangle("fill", 800, btnY, 145, 28, 6, 6)
            love.graphics.setColor(C_NEON_BORDER)
            love.graphics.setLineWidth(1.5)
            love.graphics.rectangle("line", 800, btnY, 145, 28, 6, 6)
            love.graphics.setLineWidth(1)
            
            local isRosterHover = checkHover(645, btnY, 145, 28)
            love.graphics.setColor(isRosterHover and {0.0, 0.76, 1.0} or {0.129, 0.149, 0.192})
            love.graphics.rectangle("fill", 645, btnY, 145, 28, 6, 6)
            love.graphics.setColor(C_NEON_BORDER)
            love.graphics.setLineWidth(1.5)
            love.graphics.rectangle("line", 645, btnY, 145, 28, 6, 6)
            love.graphics.setLineWidth(1)
            drawShadowText("VIEW ROSTER", 645, btnY + 8, 1, 1, 1, 0.85, "center", 145)
            
            local totalCards = #DeckManager.playbook
            local drawCount = #DeckManager.drawPile
            local btnText = string.format("PLAYBOOK (%d/%d)", drawCount, totalCards)
            drawShadowText(btnText, 800, btnY + 8, 1, 1, 1, 0.85, "center", 145)
        end
    elseif GameStateData.status == "TOUCHDOWN" then
        drawShadowText("DRIVE COMPLETED! PRESS [SPACE] TO VISIT FRONT OFFICE SHOP", 480, 290, 1, 0.84, 0, 1.3, "center", 920)
    elseif GameStateData.status == "GAME_WON" then
        drawShadowText("GAME WON! TARGET REACHED! PRESS [SPACE] FOR NEXT WEEK", 480, 290, 0.2, 0.8, 0.4, 1.3, "center", 920)
    elseif GameStateData.status == "TURNOVER" then
        drawShadowText("OUT OF DRIVES! PRESS [R] TO RESTART SEASON RUN", 480, 290, 1, 0.2, 0.2, 1.3, "center", 920)
    end
    
    -- In-Game Playbook & Roster Overlay Modals
    if self.showRosterModal then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        
        love.graphics.setColor(0.08, 0.1, 0.12, 0.98)
        love.graphics.rectangle("fill", 40, 20, 880, 500, 10, 10)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2.5)
        love.graphics.rectangle("line", 40, 20, 880, 500, 10, 10)
        love.graphics.setLineWidth(1)
        
        drawShadowText("YOUR TEAM ROSTER", 60, 35, 1, 0.84, 0, 1.4)
        drawShadowText("(CLICK ANYWHERE OUTSIDE TO CLOSE)", 60, 65, 0.6, 0.6, 0.6, 0.9)
        
        local drawOrder = {"QB", "RB", "WR1", "WR2", "FLEX"}
        local totalSlots = 0
        if GameStateData.rosterSlots then
            for _, pos in ipairs(drawOrder) do
                if GameStateData.rosterSlots[pos] then
                    totalSlots = totalSlots + GameStateData.rosterSlots[pos].max
                end
            end
        end
        
        local startXRoster = 480 - ((totalSlots - 1) * 110) / 2
        local currentSlotIdx = 0
        self.hoveredRosterPlayer = nil
        local mx, my = love.mouse.getPosition()
        
        if GameStateData.rosterSlots then
            for _, pos in ipairs(drawOrder) do
                local posData = GameStateData.rosterSlots[pos]
                if posData then
                    for i = 1, posData.max do
                        local rx = startXRoster + currentSlotIdx * 110
                        local ry = 250
                        local isRosterHover = (mx >= rx - 45 and mx <= rx + 45 and my >= ry - 55 and my <= ry + 55)
                        
                        local player = posData.cards[i]
                        if player then
                            if isRosterHover then self.hoveredRosterPlayer = player end
                            CardRender.drawPlayerCard(rx, ry, player, isRosterHover, love.timer.getDelta())
                        else
                            love.graphics.push()
                            love.graphics.translate(rx, ry)
                            love.graphics.setColor(C_SLATE_CONTAINER)
                            love.graphics.rectangle("fill", -50, -55, 100, 110, 6, 6)
                            love.graphics.setColor(C_BORDER_NORMAL)
                            love.graphics.rectangle("line", -50, -55, 100, 110, 6, 6)
                            local label = (posData.max > 1) and (pos .. " " .. i) or pos
                            drawShadowText("[" .. label .. "]", -50, -5, 0.5, 0.5, 0.5, 1.0, "center", 100)
                            love.graphics.pop()
                        end
                        currentSlotIdx = currentSlotIdx + 1
                    end
                end
            end
        end
        
        if self.hoveredRosterPlayer then
            CardRender.drawTooltip(mx, my, self.hoveredRosterPlayer)
        end
        
        -- Draw close button
        local isCloseHover = checkHover(420, 480, 120, 32)
        love.graphics.setColor(isCloseHover and {0.9, 0.3, 0.3} or {0.7, 0.2, 0.2})
        love.graphics.rectangle("fill", 420, 480, 120, 32, 6, 6)
        drawShadowText("CLOSE", 420, 488, 1, 1, 1, 0.85, "center", 120)
    end
    
    if self.showPlaybookModal then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        
        love.graphics.setColor(0.08, 0.1, 0.12, 0.98)
        love.graphics.rectangle("fill", 40, 20, 880, 500, 10, 10)
        love.graphics.setColor(C_NEON_BORDER)
        love.graphics.setLineWidth(2.5)
        love.graphics.rectangle("line", 40, 20, 880, 500, 10, 10)
        love.graphics.setLineWidth(1)
        
        drawShadowText("YOUR PLAYBOOK (DECK STATUS)", 60, 35, 1, 0.84, 0, 1.4)
        
        -- Legend
        love.graphics.setColor(0.0, 0.58, 1.0)
        love.graphics.circle("fill", 500, 46, 5)
        drawShadowText("DECK", 510, 38, 0.7, 0.8, 0.9, 0.85)
        
        love.graphics.setColor(0.2, 0.8, 0.4)
        love.graphics.circle("fill", 600, 46, 5)
        drawShadowText("HAND", 610, 38, 0.7, 0.8, 0.9, 0.85)
        
        love.graphics.setColor(0.85, 0.3, 0.3)
        love.graphics.circle("fill", 700, 46, 5)
        drawShadowText("DISCARD", 710, 38, 0.7, 0.8, 0.9, 0.85)
        
        self.hoveredPlaybookCard = nil
        
        local mx, my = love.mouse.getPosition()
        for i, card in ipairs(DeckManager.playbook or {}) do
            local col = (i - 1) % 8
            local row = math.floor((i - 1) / 8)
            local cx = 100 + col * 108
            local cy = 135 + row * 155
            
            love.graphics.push()
            love.graphics.translate(cx, cy)
            love.graphics.scale(0.68, 0.68)
            CardRender.drawPlayCard(0, 0, card, false, self.time)
            love.graphics.pop()
            
            -- Check Status
            local status = "DECK"
            local statusColor = {0.0, 0.58, 1.0}
            for _, hc in ipairs(DeckManager.hand or {}) do
                if hc == card then status = "HAND"; statusColor = {0.2, 0.8, 0.4} end
            end
            for _, dc in ipairs(DeckManager.discardPile or {}) do
                if dc == card then status = "DISCARD"; statusColor = {0.85, 0.3, 0.3} end
            end
            
            love.graphics.setColor(statusColor)
            love.graphics.rectangle("fill", cx - 40, cy + 64, 80, 16, 4, 4)
            drawShadowText(status, cx - 40, cy + 66, 1, 1, 1, 0.75, "center", 80)
            
            local isHover = mx >= cx - 44 and mx <= cx + 44 and my >= cy - 60 and my <= cy + 60
            if isHover then
                self.hoveredPlaybookCard = card
            end
        end
        
        -- Draw close button
        local isCloseHover = checkHover(420, 480, 120, 32)
        love.graphics.setColor(isCloseHover and {0.9, 0.3, 0.3} or {0.7, 0.2, 0.2})
        love.graphics.rectangle("fill", 420, 480, 120, 32, 6, 6)
        drawShadowText("CLOSE", 420, 488, 1, 1, 1, 0.85, "center", 120)
    end

    if self.showPlaybookModal and self.hoveredPlaybookCard then
        local mx, my = love.mouse.getPosition()
        CardRender.drawTooltip(mx, my, self.hoveredPlaybookCard)
    end

    local CommentaryTicker = require("src.ui.commentary_ticker")
    CommentaryTicker.draw()

    local TutorialOverlay = require("src.ui.tutorial_overlay")
    TutorialOverlay.draw()

    -- TD Replay and Blind Intro overlays (drawn last, on top of everything)
    BlindIntro.draw()
    TDReplay.draw()

    -- Run Won Prompt Overlay
    if GameStateData.status == "RUN_WON_PROMPT" then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        
        drawShadowText("CHAMPIONSHIP WON!", 480, 200, 1.0, 0.84, 0.0, 2.0, "center")
        drawShadowText("You have completed the run. Choose your path:", 480, 260, 1, 1, 1, 1.0, "center")
        
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.rectangle("fill", 300, 320, 360, 40, 8, 8)
        drawShadowText("[ENTER] CLAIM VICTORY", 480, 330, 1, 1, 1, 1.2, "center")
        
        love.graphics.setColor(0.8, 0.2, 0.8)
        love.graphics.rectangle("fill", 300, 380, 360, 40, 8, 8)
        drawShadowText("[SPACE] ENTER ENDLESS MODE", 480, 390, 1, 1, 1, 1.2, "center")
    end
end

function StateGame:mousepressed(x, y, button, istouch, presses)
    -- TD Replay consumes all clicks while active
    if TDReplay.active then
        TDReplay.mousepressed()
        return
    end

    local TutorialOverlay = require("src.ui.tutorial_overlay")
    if TutorialOverlay.active then
        TutorialOverlay.mousepressed(x, y, button)
        return
    end

    if ScoringEvaluator.active then return end

    if self.showPlaybookModal and button == 1 then
        if checkHover(420, 480, 120, 32) then
            self.showPlaybookModal = false
            SoundManager.playSFX("click")
        elseif x < 40 or x > 920 or y < 20 or y > 520 then
            self.showPlaybookModal = false
            SoundManager.playSFX("click")
        end
        return
    end

    if self.showRosterModal and button == 1 then
        if checkHover(420, 480, 120, 32) then
            self.showRosterModal = false
            SoundManager.playSFX("click")
        elseif x < 40 or x > 920 or y < 20 or y > 520 then
            self.showRosterModal = false
            SoundManager.playSFX("click")
        end
        return
    end

    if GameStateData.status == "PLAYING" and not StateManager.isOverlayOpen() then
        if button == 1 and checkHover(886, 8, 36, 68) then
            local currentSpeed = SettingsData.gameSpeed or 1.0
            SettingsData.gameSpeed = (currentSpeed == 1.0) and 2.0 or ((currentSpeed == 2.0) and 4.0 or 1.0)
            SoundManager.playSFX("click")
            return
        end
        if button == 1 and checkHover(925, 8, 23, 68) then
            local PauseOverlay = require("src.ui.pause_overlay")
            StateManager.openOverlay(PauseOverlay)
            SoundManager.playSFX("click")
            return
        end
        local btnY = self.playbookShelfY + 140
        if button == 1 and checkHover(800, btnY, 145, 28) then
            self.showPlaybookModal = true
            SoundManager.playSFX("click")
            return
        end
        if button == 1 and checkHover(645, btnY, 145, 28) then
            self.showRosterModal = true
            SoundManager.playSFX("click")
            return
        end
        if button == 1 then
            if self.show4thDownPrompt then
                if checkHover(340, 240, 140, 30) then
                    self.show4thDownPrompt = false
                    SoundManager.playSFX("click")
                    return
                elseif checkHover(490, 240, 150, 30) and GameStateData.yardLine >= 65 then
                    self.show4thDownPrompt = false
                    SoundManager.playSFX("click")
                    self:dealSpecialTeams("Kick")
                    return
                elseif checkHover(650, 240, 140, 30) then
                    self.show4thDownPrompt = false
                    SoundManager.playSFX("click")
                    self:dealSpecialTeams("Punt")
                    return
                end
                return
            elseif GameStateData.down < 4 and self.selectedPlayIndex then
                if checkHover(380, 240, 200, 30) then
                    self:callPlay()
                    return
                end
            end
            
            for ci = 1, GameStateData.maxConsumables do
                local cx = 610 + (ci - 1) * 58
                local cy = 8 + 20
                if checkHover(cx, cy, 52, 42) and GameStateData.consumables[ci] then
                    local msg = GameStateData.useConsumable(ci)
                    SoundManager.playSFX("coin")
                    FxManager.addFloatingText(msg, 480, 250, 1, 0.84, 0, 1.3)
                    return
                end
            end

            local clickedCardIdx = nil
            for i, c in ipairs(DeckManager.hand) do
                if checkHover(c.xOffset - 140, c.yOffset - 80, 280, 160) then
                    clickedCardIdx = i
                    break
                end
            end
            
            if clickedCardIdx then
                if self.selectedPlayIndex == clickedCardIdx then
                    self:callPlay()
                else
                    self.selectedPlayIndex = clickedCardIdx
                    self.draggingCardIndex = clickedCardIdx
                    self.dragStartX = x
                    self.dragStartY = y
                    self.justSelectedThisClick = true
                    SoundManager.playSFX("click")
                end
            else
                self.selectedPlayIndex = nil
            end
        elseif button == 2 then
            if self.hoveredRosterPlayer then
                self.hoveredRosterPlayer.isFlipped = not self.hoveredRosterPlayer.isFlipped
                SoundManager.playSFX("click")
            end
        end
    end
end

function StateGame:mousereleased(x, y, button, istouch, presses)
    if button == 1 and self.draggingCardIndex then
        local dragDist = 0
        if self.dragStartX and self.dragStartY then
            local dx = x - self.dragStartX
            local dy = y - self.dragStartY
            dragDist = math.sqrt(dx*dx + dy*dy)
        end
        
        -- Drag card above the tray boundary (Y=335) to call the play
        if y < 320 then
            self.selectedPlayIndex = self.draggingCardIndex
            self:callPlay()
        elseif dragDist < 8 and not self.justSelectedThisClick and self.draggingCardIndex == self.selectedPlayIndex then
            self:callPlay()
        end
        self.draggingCardIndex = nil
        self.justSelectedThisClick = false
    end
end

function StateGame:callPlay()
    if self.selectedPlayIndex and #DeckManager.hand > 0 and not ScoringEvaluator.active then
        local playCard = table.remove(DeckManager.hand, self.selectedPlayIndex)
        self.selectedPlayIndex = nil
        
        if SettingsData.rpoMinigameEnabled and playCard.type == "Play Action" then
            RPOMinigame.start(function(result)
                if result == "PERFECT" then
                    playCard.baseChips = playCard.baseChips + 5
                    playCard.baseMult = playCard.baseMult * 1.5
                    FxManager.addFloatingText("PERFECT READ! +5 YDS x1.5 MTM", 480, 200, 0.2, 0.8, 0.3, 1.8)
                    SoundManager.playSFX("touchdown")
                elseif result == "GOOD" then
                    FxManager.addFloatingText("GOOD READ!", 480, 200, 0.9, 0.8, 0.2, 1.2)
                else
                    playCard.baseChips = playCard.baseChips - 8
                    FxManager.addFloatingText("MISSED READ! SACKED!", 480, 200, 1.0, 0.2, 0.2, 1.8)
                    SoundManager.playSFX("tackle")
                end
                self:executePlaycard(playCard)
            end)
        else
            self:executePlaycard(playCard)
        end
    end
end

function StateGame:executePlaycard(playCard)
    if _G.triggerScreenShake then _G.triggerScreenShake(14, 0.25) end
    FxManager.addBurstParticles(480, 320, 35, 0.0, 0.76, 1.0)
    SoundManager.playSFX("tackle")
    
    if playCard.type == "Kick" then
        GameStateData.kickFieldGoal()
    elseif playCard.type == "Punt" then
        GameStateData.puntBall()
    else
        local ScoringEvaluator = require("src.engine.scoring_evaluator")
        local risk, riskType = ScoringEvaluator.calculateTurnoverRisk(playCard, GameStateData)
        local isTurnover = false
        if risk > 0 and math.random(1, 100) <= risk then
            isTurnover = true
        end
        
        GameStateData.executePlay(playCard, isTurnover, riskType)
        DeckManager.discardPlay(playCard)
        DeckManager.fillHand()
    end
end

function StateGame:dealSpecialTeams(mode)
    local DeckManager = require("src.engine.deck_manager")
    while #DeckManager.hand > 0 do
        table.insert(DeckManager.discardPile, table.remove(DeckManager.hand))
    end
    
    local PlayCard = require("src.entities.play_card")
    if mode == "Kick" then
        local fgCard = PlayCard.new("Field Goal Kick", "Kick", 0, 0)
        local fakeFgCard = PlayCard.new("Fake Field Goal", "Play Action", 12, 1.5)
        table.insert(DeckManager.hand, fgCard)
        table.insert(DeckManager.hand, fakeFgCard)
    elseif mode == "Punt" then
        local puntCard = PlayCard.new("Punt Ball", "Punt", 0, 0)
        local fakePuntCard = PlayCard.new("Fake Punt", "Run", 8, 1.2)
        table.insert(DeckManager.hand, puntCard)
        table.insert(DeckManager.hand, fakePuntCard)
    end
    
    self.selectedPlayIndex = nil
end

function StateGame:keypressed(key)
    local TutorialOverlay = require("src.ui.tutorial_overlay")
    if TutorialOverlay.active then
        TutorialOverlay.keypressed(key)
        return
    end

    if RPOMinigame.active then
        RPOMinigame.keypressed(key)
        return
    end

    local FieldAnimator = require("src.ui.field_animator")
    if FieldAnimator.active and FieldAnimator.keypressed(key) then
        return
    end

    if self.showRosterModal then
        if key == "escape" or key == "space" or key == "return" or key == "enter" then
            self.showRosterModal = false
            SoundManager.playSFX("click")
        end
        return
    end

    if self.showPlaybookModal then
        if key == "escape" or key == "space" or key == "return" or key == "enter" then
            self.showPlaybookModal = false
            SoundManager.playSFX("click")
        end
        return
    end

    -- [ESC]: Pause (open pause overlay)
    if key == "escape" then
        local PauseOverlay = require("src.ui.pause_overlay")
        StateManager.openOverlay(PauseOverlay)
        return
    end

    if GameStateData.status == "PLAYING" and not ScoringEvaluator.active then
        if key == "1" and GameStateData.consumables[1] then
            local msg = GameStateData.useConsumable(1)
            SoundManager.playSFX("coin")
            FxManager.addFloatingText(msg, 480, 250, 1, 0.84, 0, 1.3)
        elseif key == "2" and GameStateData.consumables[2] then
            local msg = GameStateData.useConsumable(2)
            SoundManager.playSFX("coin")
            FxManager.addFloatingText(msg, 480, 250, 1, 0.84, 0, 1.3)
        elseif key == "left" or key == "a" then
            if self.selectedPlayIndex then
                self.selectedPlayIndex = math.max(1, self.selectedPlayIndex - 1)
            else
                self.selectedPlayIndex = #DeckManager.hand
            end
            SoundManager.playSFX("click")
        elseif key == "right" or key == "d" then
            if self.selectedPlayIndex then
                self.selectedPlayIndex = math.min(#DeckManager.hand, self.selectedPlayIndex + 1)
            else
                self.selectedPlayIndex = 1
            end
            SoundManager.playSFX("click")
        elseif key == "return" or key == "space" or key == "enter" then
            self:callPlay()
        elseif key == "q" then
            if self.selectedPlayIndex and GameStateData.audiblesRemaining > 0 and #DeckManager.hand > 0 then
                SoundManager.playSFX("click")
                local playCard = table.remove(DeckManager.hand, self.selectedPlayIndex)
                DeckManager.discardPlay(playCard)
                GameStateData.audiblesRemaining = GameStateData.audiblesRemaining - 1
                DeckManager.fillHand()
                self.selectedPlayIndex = nil
                FxManager.addFloatingText("AUDIBLE!", 480, 260, 1, 0.84, 0, 1.5)
            end
        end
    elseif GameStateData.status == "RUN_WON_PROMPT" then
        if key == "return" or key == "enter" then
            SoundManager.playSFX("touchdown")
            -- Mark Mastery
            local SaveManager = require("src.engine.save_manager")
            for _, card in ipairs(DeckManager.playbook or {}) do
                SaveManager.markCardMastered(card.name)
            end
            
            -- Transition to Season Report as a win
            local runData = {
                touchdownsThisRun = SaveManager.data and SaveManager.data.touchdownCount or 0,
                totalYardsGained  = GameStateData.totalYardsGained or 0,
                anteReached       = GameStateData.ante or 1,
                weeksPlayed       = GameStateData.gameWeek or 1,
                bestPlayName      = GameStateData.lastPlayResult and GameStateData.lastPlayResult:sub(1,24) or "N/A",
                bestPlayYards     = GameStateData.totalYardsGained or 0,
                didWin            = true,
            }
            local sd = SaveManager.data
            if sd then
                sd.runHistory = sd.runHistory or {}
                table.insert(sd.runHistory, 1, {
                    ante = runData.anteReached,
                    yards = runData.totalYardsGained,
                    date = os.date and os.date("%m/%d") or "TODAY",
                    win = true
                })
                if #sd.runHistory > 10 then table.remove(sd.runHistory, 11) end
                SaveManager.save()
            end
            local StateSeasonReport = require("src.states.state_season_report")
            StateSeasonReport.data = runData
            StateManager.switch(StateSeasonReport)
        elseif key == "space" then
            SoundManager.playSFX("click")
            GameStateData.isEndless = true
            local StateShop = require("src.states.state_shop")
            StateManager.switch(StateShop)
        end
    elseif key == "space" and (GameStateData.status == "TOUCHDOWN" or GameStateData.status == "GAME_WON") then
         local StateShop = require("src.states.state_shop")
         StateManager.switch(StateShop)
    elseif key == "r" and GameStateData.status == "TURNOVER" then
        if _G.GAME_MODE == "roguelite" then
            local MyPlayerProfile = require("src.data.myplayer_profile")
            MyPlayerProfile.seasonsPlayed = MyPlayerProfile.seasonsPlayed + 1
            if MyPlayerProfile.seasonsPlayed >= MyPlayerProfile.maxSeasons then
                MyPlayerProfile.retire()
            else
                MyPlayerProfile.save()
            end
        end
        SaveManager.clearActiveRun()
        GameStateData.init(GameStateData.config)
        DeckManager.drawHand()
    end
end

return StateGame
