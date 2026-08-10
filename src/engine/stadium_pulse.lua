-- src/engine/stadium_pulse.lua
-- Stadium Pulse: A crowd momentum meter (0-100) that buffs/penalises based on play performance.
-- Contextual scaling adjusts starting pulse and decay rates based on match context.

local FxManager = require("src.engine.fx_manager")
local SoundManager = require("src.engine.sound_manager")

local StadiumPulse = {}

StadiumPulse.pulse = 30
StadiumPulse.displayPulse = 30
StadiumPulse.activeDecayRate = 1.0
StadiumPulse.matchContext = nil
StadiumPulse.lastTierName = "Quiet"
StadiumPulse.tierFlashTimer = 0

-- ─── Tier Definitions ───────────────────────────────────────────
local tiers = {
    { name = "Dead",      min = 0,  max = 15, chips = -2,  mult = -0.5, clockBonus = 0,  color = {0.3, 0.3, 0.5} },
    { name = "Quiet",     min = 16, max = 35, chips = 0,   mult = 0,    clockBonus = 0,  color = {0.4, 0.45, 0.6} },
    { name = "Engaged",   min = 36, max = 55, chips = 2,   mult = 0,    clockBonus = 0,  color = {0.2, 0.7, 0.4} },
    { name = "Loud",      min = 56, max = 75, chips = 2,   mult = 0.5,  clockBonus = 0,  color = {1.0, 0.6, 0.0} },
    { name = "DEAFENING", min = 76, max = 100, chips = 4,  mult = 1.0,  clockBonus = 3,  color = {1.0, 0.15, 0.15} }
}

-- ─── Init (simple — starts at Quiet tier) ───────────────────────
function StadiumPulse.init()
    StadiumPulse.pulse = 30
    StadiumPulse.displayPulse = 30
    StadiumPulse.activeDecayRate = 1.0
    StadiumPulse.matchContext = nil
    StadiumPulse.lastTierName = "Quiet"
    StadiumPulse.tierFlashTimer = 0
end

-- ─── Init With Context (home/away, rival, playoff) ──────────────
function StadiumPulse.initWithContext(matchContext)
    -- matchContext: { isAway = bool, isRival = bool, isPlayoff = bool }
    local basePulse = 30
    local decayRate = 1.0

    if matchContext and matchContext.isAway then
        basePulse = basePulse + 15
        decayRate = decayRate + 0.2
    end

    if matchContext and matchContext.isRival then
        basePulse = basePulse + (matchContext.isAway and 20 or 10)
        decayRate = decayRate + (matchContext.isAway and 0.2 or -0.1)
    end

    if matchContext and matchContext.isPlayoff then
        basePulse = basePulse + 25
        decayRate = decayRate + (matchContext.isAway and 0.3 or -0.2)
    end

    StadiumPulse.pulse = math.min(100, basePulse)
    StadiumPulse.displayPulse = StadiumPulse.pulse
    StadiumPulse.activeDecayRate = decayRate
    StadiumPulse.matchContext = matchContext
    StadiumPulse.lastTierName = StadiumPulse.getTierName()
    StadiumPulse.tierFlashTimer = 0
end

-- ─── Modify Pulse ───────────────────────────────────────────────
function StadiumPulse.addPulse(amount)
    local oldTier = StadiumPulse.getTierName()
    StadiumPulse.pulse = math.max(0, math.min(100, StadiumPulse.pulse + amount))
    local newTier = StadiumPulse.getTierName()

    if newTier ~= oldTier then
        StadiumPulse.tierFlashTimer = 1.2
        StadiumPulse.lastTierName = newTier

        if newTier == "DEAFENING" then
            FxManager.addFloatingText("CROWD IS DEAFENING!", 480, 130, 1.0, 0.15, 0.15, 2.0)
            FxManager.addBurstParticles(20, 270, 25, 1.0, 0.4, 0.0)
            SoundManager.playSFX("touchdown")
            if _G.triggerScreenShake then _G.triggerScreenShake(8, 0.3) end
        elseif newTier == "Dead" then
            FxManager.addFloatingText("CROWD GOES SILENT...", 480, 130, 0.4, 0.4, 0.6, 1.6)
        end
    end
end

-- ─── Passive Drain (called from updatePlayClock) ────────────────
function StadiumPulse.update(dt)
    local baseDrain = 2 * (StadiumPulse.activeDecayRate or 1.0)
    StadiumPulse.pulse = math.max(0, StadiumPulse.pulse - baseDrain * dt)

    -- Smooth display lerp
    StadiumPulse.displayPulse = StadiumPulse.displayPulse + (StadiumPulse.pulse - StadiumPulse.displayPulse) * math.min(1.0, 6 * dt)

    if StadiumPulse.tierFlashTimer > 0 then
        StadiumPulse.tierFlashTimer = StadiumPulse.tierFlashTimer - dt
    end
end

-- ─── Tier Queries ───────────────────────────────────────────────
function StadiumPulse.getTier()
    local p = math.floor(StadiumPulse.pulse)
    for _, tier in ipairs(tiers) do
        if p >= tier.min and p <= tier.max then
            return tier
        end
    end
    return tiers[1]
end

function StadiumPulse.getTierName()
    return StadiumPulse.getTier().name
end

function StadiumPulse.getBonuses()
    local tier = StadiumPulse.getTier()
    return { chips = tier.chips, mult = tier.mult, clockBonus = tier.clockBonus }
end

-- ─── Draw (Vertical Pulse Bar) ──────────────────────────────────
function StadiumPulse.draw(x, y)
    local barW = 14
    local barH = 280
    local t = love.timer.getTime()
    local tier = StadiumPulse.getTier()
    local pct = math.max(0, math.min(1, StadiumPulse.displayPulse / 100))

    -- Background shadow
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x + 1, y + 1, barW, barH, 4, 4)

    -- Bar background (dark slate)
    love.graphics.setColor(0.08, 0.1, 0.14, 0.95)
    love.graphics.rectangle("fill", x, y, barW, barH, 4, 4)

    -- Fill gradient: cold blue (bottom) → amber → red (top)
    local fillH = barH * pct
    local fillY = y + barH - fillH

    if fillH > 0 then
        -- Draw fill in 4-pixel vertical slices for gradient effect
        local slices = math.max(1, math.floor(fillH / 3))
        for i = 0, slices - 1 do
            local sliceY = fillY + i * (fillH / slices)
            local sliceH = fillH / slices
            local slicePct = 1.0 - (i / slices) -- 1.0 at top, 0.0 at bottom

            local r, g, b
            if slicePct > 0.7 then
                -- Red zone
                local pulse_glow = 0.15 + math.sin(t * 6) * 0.1
                r, g, b = 1.0, pulse_glow, 0.0
            elseif slicePct > 0.4 then
                -- Amber zone
                r, g, b = 1.0, 0.55, 0.0
            else
                -- Blue zone
                r, g, b = 0.1, 0.5, 0.9
            end

            love.graphics.setColor(r, g, b, 0.9)
            love.graphics.rectangle("fill", x + 2, sliceY, barW - 4, sliceH + 1)
        end
    end

    -- Neon border (color matches tier)
    local bc = tier.color
    local borderAlpha = 0.8
    if StadiumPulse.tierFlashTimer > 0 then
        borderAlpha = 0.5 + 0.5 * math.sin(t * 16)
    end
    love.graphics.setColor(bc[1], bc[2], bc[3], borderAlpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, barW, barH, 4, 4)
    love.graphics.setLineWidth(1)

    -- Tier tick marks
    for _, ti in ipairs(tiers) do
        if ti.min > 0 then
            local tickY = y + barH - (barH * (ti.min / 100))
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.line(x, tickY, x + barW, tickY)
        end
    end

    -- Tier label (rotated, beside bar)
    love.graphics.push()
    love.graphics.translate(x + barW + 4, y + barH - fillH)
    love.graphics.rotate(-math.pi / 2)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(tier.name:upper(), 1, 1, 0, 0.7, 0.7)
    love.graphics.setColor(bc[1], bc[2], bc[3], 1)
    love.graphics.print(tier.name:upper(), 0, 0, 0, 0.7, 0.7)
    love.graphics.pop()

    -- Pulse percentage text at bottom
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.printf(tostring(math.floor(StadiumPulse.pulse)), x, y + barH + 3, barW, "center", 0, 0.7, 0.7)

    -- DEAFENING: emit particle sparks from bar top
    if tier.name == "DEAFENING" then
        if math.random() < 0.3 then
            FxManager.addBurstParticles(x + barW / 2, fillY, 2, 1.0, 0.4 + math.random() * 0.4, 0.0)
        end
    end
end

return StadiumPulse
