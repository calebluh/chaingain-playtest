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
    local globalWins = 0
    local globalLosses = 0
    local totalRuns = 0
    
    for _, team in ipairs(FranchiseTeams) do
        for _, arch in ipairs(archetypes) do
            for _, stake in ipairs(stakes) do
                currentCombo = currentCombo + 1
                
                -- We patch BotRunner.runHeadlessSimulation to test this specific config
                BotRunner.testConfig = {
                    team = team,
                    archetype = arch,
                    stakeTier = stake
                }
                
                local runsToSim = 10
                local summary = BotRunner.runHeadlessSimulation(runsToSim)
                
                globalWins = globalWins + summary.wins
                globalLosses = globalLosses + summary.losses
                totalRuns = totalRuns + runsToSim
            end
        end
    end
    
    print("\n--- MATRIX TELEMETRY RESULTS ---")
    print(string.format("Tested %d Combinations (%d Total Runs)", totalCombos, totalRuns))
    print("Wins (Touchdowns): " .. globalWins)
    print("Losses (Turnovers): " .. globalLosses)
    print("Overall Win Rate: " .. math.floor((globalWins / math.max(1, totalRuns)) * 100) .. "%")
    print("==================================\n")
end)

if not ok then
    print("Simulation Error: " .. tostring(err))
end
