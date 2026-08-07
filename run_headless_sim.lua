-- f:/Projects/BalatroFB/run_headless_sim.lua
-- Driver script to run 1,000 headless bot simulations

local ok, err = pcall(function()
    love = {
        filesystem = {
            write = function(filename, data)
                local f = io.open(filename, "w")
                if f then f:write(data); f:close() end
            end,
            getInfo = function(f) return nil end
        },
        window = { setMode = function() end, setTitle = function() end },
        graphics = { setDefaultFilter = function() end, newCanvas = function() end },
        mouse = { getPosition = function() return 0, 0 end }
    }
    
    local BotRunner = require("src.engine.bot_runner")
    local summary = BotRunner.runHeadlessSimulation(1000)
    print("\nTelemetry Results Summary:")
    print("Total Runs: " .. summary.totalRuns)
    print("Wins (Touchdowns): " .. summary.wins)
    print("Losses (Turnovers): " .. summary.losses)
    print("Crashes: " .. #summary.crashes)
    print("Win Rate: " .. summary.winRatePct .. "%")
    print("Avg Yards Per Play: " .. summary.avgYardsPerPlay)
end)

if not ok then
    print("Simulation Error: " .. tostring(err))
end
