-- main.lua
local StateManager = require("src.states.state_manager")
local StateMenu = require("src.states.state_menu")
local AssetManager = require("src.engine.asset_manager")
local SoundManager = require("src.engine.sound_manager")
local FxManager = require("src.engine.fx_manager")
local SaveManager = require("src.engine.save_manager")
local SteamManager = require("src.engine.steam_manager")
local Loc = require("src.engine.loc_manager")
local BotRunner = require("src.engine.bot_runner")

local crtShader
local mainCanvas
local time = 0

local shakeIntensity = 0
local shakeDuration = 0
local shakeTimer = 0

local hitStopTimer = 0

function love.load(arg)
    -- Copy icon from artifacts if it exists
    local sourcePath = "C:/Users/caleb/.gemini/antigravity-ide/brain/805280e1-4677-4396-8435-a3d908f93326/icon_1786114119555.png"
    local destPath = "assets/icon.png"
    local sf = io.open(sourcePath, "rb")
    if sf then
        local df = io.open(destPath, "wb")
        if df then
            df:write(sf:read("*all"))
            df:close()
        end
        sf:close()
    end

    love.window.setMode(1920, 1080, {fullscreen = true, vsync = true})
    love.window.setTitle("Drive or Die")
    
    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo("assets/icon.png") then
        local ok, iconData = pcall(love.image.newImageData, "assets/icon.png")
        if ok and iconData then
            love.window.setIcon(iconData)
        end
    end
    
    love.graphics.setDefaultFilter("linear", "linear")
    math.randomseed(os.time())
    
    AssetManager.init()
    SoundManager.init()
    FxManager.init()
    SaveManager.init()
    Loc.init("en")
    
    local isHeadless = false
    if arg then
        for i = 1, #arg do
            if tostring(arg[i]):find("headless") then isHeadless = true end
        end
    end
    
    if isHeadless then
        local logs = BotRunner.runHeadlessSimulation(1000)
        local jsonStr = string.format('{\n  "totalRuns": %d,\n  "wins": %d,\n  "losses": %d,\n  "crashes": %d,\n  "winRatePct": %d,\n  "avgYardsPerPlay": %d\n}',
            logs.totalRuns, logs.wins, logs.losses, #logs.crashes, logs.winRatePct, logs.avgYardsPerPlay)
            
        local f = io.open("f:/Projects/BalatroFB/playtest_summary.json", "w")
        if f then f:write(jsonStr); f:close() end
        love.filesystem.write("playtest_summary.json", jsonStr)
        print("[BOT] Headless Simulation exported to playtest_summary.json!")
        love.event.quit()
        return
    end
    
    if love.filesystem.getInfo("src/shaders/crt_shader.glsl") then
        local shaderCode = love.filesystem.read("src/shaders/crt_shader.glsl")
        crtShader = love.graphics.newShader(shaderCode)
    end
    
    mainCanvas = love.graphics.newCanvas(1920, 1080)

    local oldGetPosition = love.mouse.getPosition
    love.mouse.getPosition = function()
        local winW, winH = love.graphics.getDimensions()
        local mx, my = oldGetPosition()
        return mx / (winW / 960), my / (winH / 540)
    end
    
    StateManager.init(StateMenu)
end

function _G.triggerScreenShake(intensity, duration)
    shakeIntensity = (intensity or 10) * (_G.CONFIG_SCREENSHAKE or 1.0)
    shakeDuration = duration or 0.4
    shakeTimer = duration or 0.4
end

function _G.triggerHitStop(duration)
    hitStopTimer = duration or 0.1
end

function love.update(dt)
    time = time + dt
    if crtShader and crtShader:hasUniform("time") then
        crtShader:send("time", time)
    end
    if crtShader and crtShader:hasUniform("screen_size") then
        crtShader:send("screen_size", {1920, 1080})
    end
    if crtShader and crtShader:hasUniform("shake_intensity") then
        local currentShake = 0
        if shakeTimer > 0 then
            local progress = shakeTimer / shakeDuration
            currentShake = shakeIntensity * progress
        end
        crtShader:send("shake_intensity", currentShake)
    end
    
    if shakeTimer > 0 then
        shakeTimer = shakeTimer - dt
    end
    
    if hitStopTimer > 0 then
        hitStopTimer = hitStopTimer - dt
        -- Allow sound to play, but halt game logic
        return
    end
    
    SteamManager.update()
    FxManager.update(dt)
    BotRunner.updateVisualAutoPlay(dt)
    StateManager.update(dt)
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas(mainCanvas)
    love.graphics.clear(0, 0, 0, 1)
    
    love.graphics.push()
    love.graphics.scale(2, 2)
    
    if shakeTimer > 0 then
        local progress = shakeTimer / shakeDuration
        local currentShake = shakeIntensity * progress
        local dx = (math.random() * 2 - 1) * currentShake
        local dy = (math.random() * 2 - 1) * currentShake
        love.graphics.translate(dx, dy)
    end
    
    StateManager.draw()
    FxManager.draw()
    
    if BotRunner.visualAutoPlay then
        love.graphics.setColor(1, 0.2, 0.2, 0.85)
        love.graphics.rectangle("fill", 300, 10, 360, 30, 6, 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("🤖 VISUAL AUTO-PLAYTEST MODE [F9]", 300, 18, 360, "center")
    end
    
    love.graphics.pop()
    love.graphics.setCanvas()
    
    love.graphics.setColor(1, 1, 1, 1)
    if _G.CONFIG_ENABLE_CRT and crtShader then
        love.graphics.setShader(crtShader)
    end
    local winW, winH = love.graphics.getDimensions()
    love.graphics.draw(mainCanvas, 0, 0, 0, winW / 1920, winH / 1080)
    love.graphics.setShader()
    
    if _G.CONFIG_SHOW_FPS then
        love.graphics.setColor(0, 1, 0.4, 0.95)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 15, 15, 0, 1.5, 1.5)
    end
end

function love.focus(f)
    if _G.CONFIG_MUTE_ON_FOCUS_LOST then
        if f then
            love.audio.setVolume(1.0)
        else
            love.audio.setVolume(0.0)
        end
    end
end

function love.keypressed(key)
    if key == "f9" then
        BotRunner.visualAutoPlay = not BotRunner.visualAutoPlay
        SoundManager.playSFX("coin")
        print("[BOT] Visual Auto-Play toggled: " .. tostring(BotRunner.visualAutoPlay))
        return
    end
    StateManager.keypressed(key)
end

function love.mousepressed(x, y, button, istouch, presses)
    StateManager.mousepressed(x / 2, y / 2, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    if StateManager.mousereleased then
        StateManager.mousereleased(x / 2, y / 2, button, istouch, presses)
    end
end

function love.wheelmoved(x, y)
    StateManager.wheelmoved(x, y)
end

function love.gamepadpressed(joystick, button)
    if button == "dpleft" then StateManager.keypressed("left")
    elseif button == "dpright" then StateManager.keypressed("right")
    elseif button == "dpup" then StateManager.keypressed("up")
    elseif button == "dpdown" then StateManager.keypressed("down")
    elseif button == "a" then StateManager.keypressed("space")
    elseif button == "b" then StateManager.keypressed("escape")
    elseif button == "x" then StateManager.keypressed("1")
    elseif button == "y" then StateManager.keypressed("q")
    end
end

function love.quit()
    SteamManager.shutdown()
end

return love
