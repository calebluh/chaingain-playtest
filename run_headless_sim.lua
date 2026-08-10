-- f:/Projects/BalatroFB/run_headless_sim.lua
-- Driver script to run headless bot simulations for all combinations of Teams, Schemes, and Stakes

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
        mouse = { getPosition = function() return 0, 0 end },
        timer = { getDelta = function() return 0 end }
    }
    
    local BotRunner = require("src.engine.bot_runner")
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
    
    for _, team in ipairs(FranchiseTeams) do
        for _, arch in ipairs(archetypes) do
            for _, stake in ipairs(stakes) do
                currentCombo = currentCombo + 1
                
                BotRunner.testConfig = { team = team, archetype = arch, stakeTier = stake }
                
                local runsToSim = 10
                local summary = BotRunner.runHeadlessSimulation(runsToSim)
                
                globalStats.runs = globalStats.runs + summary.totalRuns
                globalStats.wins = globalStats.wins + summary.wins
                globalStats.losses = globalStats.losses + summary.losses
                globalStats.fieldGoals = globalStats.fieldGoals + (summary.fieldGoals or 0)
                globalStats.fumbles = globalStats.fumbles + (summary.fumbles or 0)
                globalStats.interceptions = globalStats.interceptions + (summary.interceptions or 0)
                globalStats.trueTurnovers = globalStats.trueTurnovers + (summary.trueTurnovers or 0)
            end
        end
    end
    
    print("\n--- MATRIX TELEMETRY RESULTS ---")
    print(string.format("Tested %d Combinations (%d Total Runs)", totalCombos, globalStats.runs))
    print("Touchdowns (Wins): " .. globalStats.wins)
    print("Field Goals: " .. globalStats.fieldGoals)
    print("Turnovers on Downs: " .. (globalStats.losses - globalStats.trueTurnovers))
    print("Fumbles/Picks: " .. (globalStats.fumbles + globalStats.interceptions))
    print("True Turnovers (Lost Drive): " .. globalStats.trueTurnovers)
    
    local winRate = math.floor((globalStats.wins / math.max(1, globalStats.runs)) * 100)
    local trueTurnoverRate = math.floor((globalStats.trueTurnovers / math.max(1, globalStats.runs)) * 100)
    
    print("Overall Touchdown Rate: " .. winRate .. "%")
    print("True Turnover Rate: " .. trueTurnoverRate .. "%")
    print("==================================\n")
end)

if not ok then
    print("Simulation Error: " .. tostring(err))
end
