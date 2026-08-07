-- test_bot.lua
love = {
    filesystem = {
        write = function(filename, data)
            local f = io.open("f:/Projects/BalatroFB/" .. filename, "w")
            if f then f:write(data); f:close() end
        end,
        getInfo = function() return nil end
    },
    window = { setMode = function() end, setTitle = function() end },
    graphics = { setDefaultFilter = function() end, newCanvas = function() end },
    mouse = { getPosition = function() return 0, 0 end }
}

local BotRunner = require("src.engine.bot_runner")
local logs = BotRunner.runHeadlessSimulation(1000)

local jsonStr = string.format('{\n  "totalRuns": %d,\n  "wins": %d,\n  "losses": %d,\n  "crashes": %d,\n  "winRatePct": %d,\n  "avgYardsPerPlay": %d\n}',
    logs.totalRuns, logs.wins, logs.losses, #logs.crashes, logs.winRatePct, logs.avgYardsPerPlay)

local f = io.open("f:/Projects/BalatroFB/playtest_summary.json", "w")
if f then
    f:write(jsonStr)
    f:close()
    print("SUCCESSFULLY_WRITTEN_PLAYTEST_SUMMARY_JSON")
end
