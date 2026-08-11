-- src/ui/touchdown_replay.lua
-- Cinematic Touchdown Replay Overlay: full-screen gold banner, confetti, flash
local TDReplay = {}

TDReplay.active   = false
TDReplay.timer    = 0
TDReplay.DURATION = 3.2
TDReplay.playerName   = ""
TDReplay.totalPoints  = 0
TDReplay.targetPoints = 0
TDReplay.phase     = 0   -- 0=flash 1=slide-in 2=hold 3=fadeout
TDReplay.flashAlpha = 0
TDReplay.bannerY   = -120
TDReplay.bannerVY  = 0
TDReplay.onComplete = nil

local confetti = {}
local CONF_COLORS = {
    {1.0,0.84,0.0},{0.0,0.76,1.0},{1.0,0.3,0.3},
    {0.2,0.85,0.4},{0.8,0.4,1.0},{1,1,1}
}

local function spawnConfetti()
    confetti = {}
    for _ = 1, 80 do
        table.insert(confetti, {
            x  = math.random(0, 960),
            y  = math.random(-200, 0),
            vx = math.random(-60, 60),
            vy = math.random(80, 250),
            rot = math.random() * math.pi * 2,
            rotSpeed = (math.random() - 0.5) * 8,
            w  = math.random(6, 14),
            h  = math.random(4, 8),
            color = CONF_COLORS[math.random(#CONF_COLORS)],
            alpha = 1.0
        })
    end
end

function TDReplay.trigger(pName, yds, pts, tPts, cb)
    TDReplay.active       = true
    TDReplay.timer        = 0
    TDReplay.phase        = 0
    TDReplay.playerName   = pName or "CHAIN GAIN!"
    TDReplay.totalPoints  = pts  or 0
    TDReplay.targetPoints = tPts or 0
    TDReplay.flashAlpha   = 1.0
    TDReplay.bannerY      = -120
    TDReplay.bannerVY     = 0
    TDReplay.onComplete   = cb
    spawnConfetti()
end

function TDReplay.update(dt)
    if not TDReplay.active then return end
    TDReplay.timer = TDReplay.timer + dt

    -- confetti physics
    for _, c in ipairs(confetti) do
        c.x   = c.x + c.vx * dt
        c.y   = c.y + c.vy * dt
        c.rot = c.rot + c.rotSpeed * dt
        c.vy  = c.vy + 60 * dt
        if TDReplay.timer > 2.0 then
            c.alpha = math.max(0, c.alpha - dt * 1.5)
        end
    end

    if TDReplay.phase == 0 then
        -- white flash fades out
        TDReplay.flashAlpha = math.max(0, TDReplay.flashAlpha - dt * 4)
        if TDReplay.flashAlpha <= 0 then TDReplay.phase = 1 end

    elseif TDReplay.phase == 1 then
        -- spring banner slide-in
        local tY  = 170
        local sp  = (tY - TDReplay.bannerY) * 18
        TDReplay.bannerVY = TDReplay.bannerVY + sp * dt - TDReplay.bannerVY * 7 * dt
        TDReplay.bannerY  = TDReplay.bannerY  + TDReplay.bannerVY * dt
        if math.abs(TDReplay.bannerY - tY) < 3 then
            TDReplay.bannerY = tY
            TDReplay.phase = 2
        end

    elseif TDReplay.phase == 2 then
        if TDReplay.timer > 2.5 then TDReplay.phase = 3 end

    elseif TDReplay.phase == 3 then
        if TDReplay.timer > TDReplay.DURATION then
            TDReplay.active = false
            if TDReplay.onComplete then TDReplay.onComplete() end
        end
    end
end

function TDReplay.draw()
    if not TDReplay.active then return end
    local t  = TDReplay.timer
    local fo = (TDReplay.phase == 3) and math.max(0, 1 - (t - 2.5) * 3) or 1.0

    -- dim overlay
    love.graphics.setColor(0, 0, 0, 0.72 * fo)
    love.graphics.rectangle("fill", 0, 0, 960, 540)

    -- white flash
    if TDReplay.flashAlpha > 0 then
        love.graphics.setColor(1, 1, 1, TDReplay.flashAlpha)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
    end

    -- confetti
    for _, c in ipairs(confetti) do
        love.graphics.setColor(c.color[1], c.color[2], c.color[3], c.alpha * fo)
        love.graphics.push()
        love.graphics.translate(c.x, c.y)
        love.graphics.rotate(c.rot)
        love.graphics.rectangle("fill", -c.w/2, -c.h/2, c.w, c.h)
        love.graphics.pop()
    end

    if TDReplay.phase >= 1 then
        local bY    = TDReplay.bannerY
        local pulse = (math.sin(t * 6) * 0.5 + 0.5) * 0.4 + 0.2

        -- gold glow halo
        love.graphics.setColor(1.0, 0.84, 0.0, pulse * fo)
        love.graphics.rectangle("fill", 60, bY - 10, 840, 200, 16, 16)

        -- dark banner bg
        love.graphics.setColor(0.06, 0.08, 0.12, 0.97 * fo)
        love.graphics.rectangle("fill", 70, bY, 820, 180, 12, 12)

        -- gold border
        love.graphics.setColor(1.0, 0.84, 0.0, fo)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", 70, bY, 820, 180, 12, 12)
        love.graphics.setLineWidth(1)

        -- TOUCHDOWN! headline
        local sc = 3.2 + math.sin(t * 4) * 0.08
        love.graphics.setColor(0, 0, 0, fo * 0.9)
        love.graphics.printf("TOUCHDOWN!", 72, bY + 14, 820, "center", 0, sc, sc)
        love.graphics.setColor(1.0, 0.84, 0.0, fo)
        love.graphics.printf("TOUCHDOWN!", 70, bY + 12, 820, "center", 0, sc, sc)

        -- player name
        love.graphics.setColor(0, 0, 0, fo * 0.8)
        love.graphics.printf(TDReplay.playerName:upper(), 71, bY + 86, 820, "center", 0, 1.5, 1.5)
        love.graphics.setColor(1, 1, 1, fo)
        love.graphics.printf(TDReplay.playerName:upper(), 70, bY + 84, 820, "center", 0, 1.5, 1.5)

        -- score info
        local info = string.format("+7 PTS  |  SCORE: %d / %d  |  CLICK TO CONTINUE",
            TDReplay.totalPoints, TDReplay.targetPoints)
        love.graphics.setColor(0.0, 0.76, 1.0, fo * 0.9)
        love.graphics.printf(info, 70, bY + 142, 820, "center", 0, 0.9, 0.9)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function TDReplay.mousepressed()
    if TDReplay.active and TDReplay.timer > 0.4 then
        TDReplay.active = false
        if TDReplay.onComplete then TDReplay.onComplete() end
    end
end

return TDReplay
