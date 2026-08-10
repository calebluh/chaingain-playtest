-- src/ui/rpo_minigame.lua
local RPOMinigame = {}

RPOMinigame.active = false
RPOMinigame.needle = 0.0     -- Position 0.0 to 1.0
RPOMinigame.speed = 2.2      -- Sweep speed
RPOMinigame.direction = 1
RPOMinigame.greenZone = { start = 0.65, stop = 0.75 }
RPOMinigame.yellowZone = { start = 0.50, stop = 0.85 }

function RPOMinigame.start(callback)
    RPOMinigame.active = true
    RPOMinigame.needle = 0.0
    RPOMinigame.direction = 1
    RPOMinigame.callback = callback
end

function RPOMinigame.update(dt)
    if not RPOMinigame.active then return end

    RPOMinigame.needle = RPOMinigame.needle + (RPOMinigame.speed * RPOMinigame.direction * dt)
    if RPOMinigame.needle >= 1.0 then
        RPOMinigame.needle = 1.0
        RPOMinigame.direction = -1
    elseif RPOMinigame.needle <= 0.0 then
        RPOMinigame.needle = 0.0
        RPOMinigame.direction = 1
    end
end

function RPOMinigame.keypressed(key)
    if not RPOMinigame.active then return end

    if key == "space" or key == "return" then
        RPOMinigame.active = false
        local val = RPOMinigame.needle
        
        if val >= RPOMinigame.greenZone.start and val <= RPOMinigame.greenZone.stop then
            RPOMinigame.callback("PERFECT")
        elseif val >= RPOMinigame.yellowZone.start and val <= RPOMinigame.yellowZone.stop then
            RPOMinigame.callback("GOOD")
        else
            RPOMinigame.callback("MISS")
        end
    end
end

function RPOMinigame.draw()
    if not RPOMinigame.active then return end

    local x, y, w, h = 340, 520, 280, 24
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    -- Yellow Zone
    love.graphics.setColor(0.9, 0.8, 0.2, 0.8)
    love.graphics.rectangle("fill", x + (w * RPOMinigame.yellowZone.start), y, w * (RPOMinigame.yellowZone.stop - RPOMinigame.yellowZone.start), h)

    -- Green Zone
    love.graphics.setColor(0.2, 0.8, 0.3, 0.9)
    love.graphics.rectangle("fill", x + (w * RPOMinigame.greenZone.start), y, w * (RPOMinigame.greenZone.stop - RPOMinigame.greenZone.start), h)

    -- Needle
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", x + (w * RPOMinigame.needle) - 2, y - 4, 4, h + 8)

    love.graphics.print("PRESS [SPACE] ON THE READ!", x + 50, y - 22)
end

return RPOMinigame
