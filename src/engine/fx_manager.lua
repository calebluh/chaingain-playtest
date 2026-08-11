-- src/engine/fx_manager.lua
local PhysicsUtils = require("src.engine.physics_utils")
local FxManager = {}

local floatingTexts = {}
local particles = {}
local weatherParticles = {}

function FxManager.init()
    floatingTexts = {}
    particles = {}
    weatherParticles = {}
    
    for i = 1, 60 do
        table.insert(weatherParticles, {
            x = math.random(0, 960),
            y = math.random(0, 540),
            speedY = math.random(60, 180),
            speedX = math.random(-20, 20),
            size = math.random(2, 5)
        })
    end
end

function FxManager.clear()
    floatingTexts = {}
    particles = {}
end

function FxManager.addFloatingText(text, x, y, r, g, b, scale)
    table.insert(floatingTexts, {
        text = text,
        x = x,
        y = y,
        vy = -40,
        r = r or 1,
        g = g or 1,
        b = b or 1,
        scaleTarget = scale or 1.5,
        scale = 0.1,
        scaleVelocity = 0,
        alpha = 1.0,
        life = 1.2
    })
end

function FxManager.addBurstParticles(x, y, count, r, g, b)
    count = count or 20
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 200)
        table.insert(particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = math.random(3, 7),
            r = r or 1,
            g = g or 0.84,
            b = b or 0,
            alpha = 1.0,
            life = math.random(0.5, 1.2)
        })
    end
end

function FxManager.update(dt, weatherType)
    for i = #floatingTexts, 1, -1 do
        local ft = floatingTexts[i]
        ft.life = ft.life - dt
        ft.y = ft.y + ft.vy * dt
        ft.scale, ft.scaleVelocity = PhysicsUtils.spring(ft.scale, ft.scaleTarget, ft.scaleVelocity, dt, 5, 0.4, 0)
        ft.alpha = math.max(0, ft.life / 1.2)
        if ft.life <= 0 then
            table.remove(floatingTexts, i)
        end
    end
    
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 200 * dt
        p.alpha = math.max(0, p.life)
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
    
    for _, wp in ipairs(weatherParticles) do
        wp.y = wp.y + wp.speedY * dt
        wp.x = wp.x + wp.speedX * dt
        if wp.y > 540 then
            wp.y = -10
            wp.x = math.random(0, 960)
        end
    end
end

function FxManager.draw(weatherType)
    if weatherType == "snow" then
        love.graphics.setColor(1, 1, 1, 0.7)
        for _, wp in ipairs(weatherParticles) do
            love.graphics.circle("fill", wp.x, wp.y, wp.size)
        end
    elseif weatherType == "rain" then
        love.graphics.setColor(0.6, 0.8, 1.0, 0.5)
        for _, wp in ipairs(weatherParticles) do
            love.graphics.line(wp.x, wp.y, wp.x - 3, wp.y + 12)
        end
    end

    for _, p in ipairs(particles) do
        love.graphics.setColor(p.r, p.g, p.b, p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    for _, ft in ipairs(floatingTexts) do
        love.graphics.setColor(0, 0, 0, ft.alpha * 0.8)
        love.graphics.print(ft.text, ft.x + 2, ft.y + 2, 0, ft.scale, ft.scale)
        
        love.graphics.setColor(ft.r, ft.g, ft.b, ft.alpha)
        love.graphics.print(ft.text, ft.x, ft.y, 0, ft.scale, ft.scale)
    end
end

function FxManager.triggerCelebrationFireworks()
    local colors = {
        {1.0, 0.84, 0.0},
        {0.0, 0.76, 1.0},
        {1.0, 0.30, 0.30},
        {0.2, 0.85, 0.40},
        {0.8, 0.40, 1.0}
    }
    for burst = 1, 5 do
        local bx = math.random(150, 810)
        local by = math.random(80, 300)
        local col = colors[math.random(#colors)]
        FxManager.addBurstParticles(bx, by, 35, col[1], col[2], col[3])
    end
end

return FxManager
