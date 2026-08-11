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
    love.window.setTitle("Chain Gain")
    
    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo("assets/icon.png") then
        local ok, iconData = pcall(love.image.newImageData, "assets/icon.png")
        if ok and iconData then
            love.window.setIcon(iconData)
        end
    end
    
    love.graphics.setDefaultFilter("linear", "linear")
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
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
        local FranchiseTeams = require("src.data.franchise_teams")
        local archetypes = {
            { id = "west_coast", name = "West Coast" },
            { id = "air_coryell", name = "Air Coryell" },
            { id = "erhardt_perkins", name = "Erhardt-Perkins" },
            { id = "spread", name = "Spread" }
        }
        local stakes = { "white", "red", "gold", "obsidian" }
        
        print("\n=== STARTING FULL MATRIX HEADLESS SIMULATION ===")
        local totalCombos = #FranchiseTeams * #archetypes * #stakes
        local currentCombo = 0
        local globalStats = { runs = 0, wins = 0, losses = 0, fieldGoals = 0, fumbles = 0, interceptions = 0, trueTurnovers = 0 }
        local dimTeams = {}
        local dimSchemes = {}
        local dimStakes = {}
        
        for _, team in ipairs(FranchiseTeams) do
            dimTeams[team.id] = { runs = 0, wins = 0, losses = 0, fieldGoals = 0, fumbles = 0, interceptions = 0, trueTurnovers = 0 }
            for _, arch in ipairs(archetypes) do
                if not dimSchemes[arch.id] then
                    dimSchemes[arch.id] = { runs = 0, wins = 0, losses = 0, fieldGoals = 0, fumbles = 0, interceptions = 0, trueTurnovers = 0 }
                end
                for _, stake in ipairs(stakes) do
                    if not dimStakes[stake] then
                        dimStakes[stake] = { runs = 0, wins = 0, losses = 0, fieldGoals = 0, fumbles = 0, interceptions = 0, trueTurnovers = 0 }
                    end
                    
                    currentCombo = currentCombo + 1
                    BotRunner.testConfig = { team = team, archetype = arch, stakeTier = stake }
                    
                    local runsToSim = 10
                    local summary = BotRunner.runHeadlessSimulation(runsToSim)
                    
                    -- Aggregate Global
                    globalStats.runs = globalStats.runs + summary.totalRuns
                    globalStats.wins = globalStats.wins + summary.wins
                    globalStats.losses = globalStats.losses + summary.losses
                    globalStats.fieldGoals = globalStats.fieldGoals + (summary.fieldGoals or 0)
                    globalStats.fumbles = globalStats.fumbles + (summary.fumbles or 0)
                    globalStats.interceptions = globalStats.interceptions + (summary.interceptions or 0)
                    globalStats.trueTurnovers = globalStats.trueTurnovers + (summary.trueTurnovers or 0)
                    
                    -- Aggregate Team
                    dimTeams[team.id].runs = dimTeams[team.id].runs + summary.totalRuns
                    dimTeams[team.id].wins = dimTeams[team.id].wins + summary.wins
                    dimTeams[team.id].losses = dimTeams[team.id].losses + summary.losses
                    dimTeams[team.id].fieldGoals = dimTeams[team.id].fieldGoals + (summary.fieldGoals or 0)
                    dimTeams[team.id].fumbles = dimTeams[team.id].fumbles + (summary.fumbles or 0)
                    dimTeams[team.id].interceptions = dimTeams[team.id].interceptions + (summary.interceptions or 0)
                    dimTeams[team.id].trueTurnovers = dimTeams[team.id].trueTurnovers + (summary.trueTurnovers or 0)
                    
                    -- Aggregate Scheme
                    dimSchemes[arch.id].runs = dimSchemes[arch.id].runs + summary.totalRuns
                    dimSchemes[arch.id].wins = dimSchemes[arch.id].wins + summary.wins
                    dimSchemes[arch.id].losses = dimSchemes[arch.id].losses + summary.losses
                    dimSchemes[arch.id].fieldGoals = dimSchemes[arch.id].fieldGoals + (summary.fieldGoals or 0)
                    dimSchemes[arch.id].fumbles = dimSchemes[arch.id].fumbles + (summary.fumbles or 0)
                    dimSchemes[arch.id].interceptions = dimSchemes[arch.id].interceptions + (summary.interceptions or 0)
                    dimSchemes[arch.id].trueTurnovers = dimSchemes[arch.id].trueTurnovers + (summary.trueTurnovers or 0)
                    
                    -- Aggregate Stake
                    dimStakes[stake].runs = dimStakes[stake].runs + summary.totalRuns
                    dimStakes[stake].wins = dimStakes[stake].wins + summary.wins
                    dimStakes[stake].losses = dimStakes[stake].losses + summary.losses
                    dimStakes[stake].fieldGoals = dimStakes[stake].fieldGoals + (summary.fieldGoals or 0)
                    dimStakes[stake].fumbles = dimStakes[stake].fumbles + (summary.fumbles or 0)
                    dimStakes[stake].interceptions = dimStakes[stake].interceptions + (summary.interceptions or 0)
                    dimStakes[stake].trueTurnovers = dimStakes[stake].trueTurnovers + (summary.trueTurnovers or 0)
                end
            end
        end
        
        local winRate = math.floor((globalStats.wins / math.max(1, globalStats.runs)) * 100)
        local trueTurnoverRate = math.floor((globalStats.trueTurnovers / math.max(1, globalStats.runs)) * 100)
        
        local fullOutput = {
            global = globalStats,
            teams = dimTeams,
            schemes = dimSchemes,
            stakes = dimStakes
        }
        
        local SaveManager = require("src.engine.save_manager")
        SaveManager.writeTelemetryLog("playtest_summary.json", fullOutput)
        
        print("\n--- MATRIX TELEMETRY RESULTS ---")
        print(string.format("Tested %d Combinations (%d Total Runs)", totalCombos, globalStats.runs))
        print("Touchdowns (Wins): " .. globalStats.wins)
        print("Field Goals: " .. globalStats.fieldGoals)
        print("Turnovers on Downs: " .. (globalStats.losses - globalStats.trueTurnovers))
        print("Fumbles/Picks: " .. (globalStats.fumbles + globalStats.interceptions))
        print("True Turnovers (Lost Drive): " .. globalStats.trueTurnovers)
        print("Overall Touchdown Rate: " .. winRate .. "%")
        print("True Turnover Rate: " .. trueTurnoverRate .. "%")
        print("==================================\n")
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

function love.textinput(t)
    if StateManager.textinput then
        StateManager.textinput(t)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    local winW, winH = love.graphics.getDimensions()
    StateManager.mousepressed(x / (winW / 960), y / (winH / 540), button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    if StateManager.mousereleased then
        local winW, winH = love.graphics.getDimensions()
        StateManager.mousereleased(x / (winW / 960), y / (winH / 540), button, istouch, presses)
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
