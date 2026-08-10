-- src/data/roster_players_expanded.lua
local PlayerCard = require("src.entities.player_card")

-- chip = Base Yards bonus (realistic: 1-10 YDS)
-- mult = Drive Momentum bonus (realistic: 0.1-0.9 MTM)
local rosterCatalog = {
    -- Quarterbacks (12)
    { name = "Marcus Vance", pos = "QB", rarity = "X-Factor", ovr = 96, chip = 0, mult = 0.0, tag = "SCALING QB", desc = "Permanently gains +1 YDS every time you play a Pass.", ability = function(self, playCard, gameState, c, m)
        self.passesThrown = self.passesThrown or 0
        if playCard.type:match("Pass") then self.passesThrown = self.passesThrown + 1 end
        return c + self.passesThrown, m
    end},
    { name = "Jalen Mercer", pos = "QB", rarity = "X-Factor", ovr = 98, chip = 0, mult = 0.0, tag = "CLUTCH GOD", desc = "x3.0 MTM if you have 0 Drives Remaining.", ability = function(self, playCard, gameState, c, m)
        if gameState.drivesRemaining == 0 then return c, m * 3.0 end
        return c, m
    end},
    { name = "Trevor Sterling", pos = "QB", rarity = "X-Factor", ovr = 94, chip = 0, mult = 0.0, tag = "DUAL THREAT QB", desc = "x2.0 MTM on Play Action, +5 YDS on Runs.", ability = function(self, playCard, gameState, c, m)
        if playCard.type == "Play Action" then return c, m * 2.0
        elseif playCard.type == "Run" then return c + 5, m end
        return c, m
    end},
    { name = "Ceedee Thorne", pos = "QB", rarity = "X-Factor", ovr = 92, chip = 0, mult = 0.0, tag = "DEEP BALLER", desc = "Permanently gains +0.2 MTM every time you play a Deep Pass.", ability = function(self, playCard, gameState, c, m)
        self.deepPasses = self.deepPasses or 0
        if playCard.type == "Deep Pass" then self.deepPasses = self.deepPasses + 1 end
        return c, m + (self.deepPasses * 0.2)
    end},
    { name = "Micah Cross", pos = "QB", rarity = "Gold", ovr = 88, chip = 2, mult = 0.4, tag = "FIELD GENERAL", desc = "+2 YDS on Medium & Short Passes" },
    { name = "Justin Drake", pos = "QB", rarity = "Gold", ovr = 86, chip = 2, mult = 0.3, tag = "TACTICIAN QB", desc = "+1 Audible per drive, +2 YDS" },
    { name = "Derrick Kane", pos = "QB", rarity = "Gold", ovr = 84, chip = 2, mult = 0.25, tag = "FIELD GENERAL", desc = "+2 YDS on Short Passes" },
    { name = "Patrick Steele", pos = "QB", rarity = "Gold", ovr = 85, chip = 2, mult = 0.3, tag = "GUNSLINGER QB", desc = "+0.3 MTM on 1st Down plays" },
    { name = "Ja'Marr Holt", pos = "QB", rarity = "Silver", ovr = 78, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Play Action plays" },
    { name = "Davante Knox", pos = "QB", rarity = "Silver", ovr = 79, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Quick Slants" },
    { name = "A.J. Stryker", pos = "QB", rarity = "Silver", ovr = 77, chip = 1, mult = 0.2, tag = "STARTER", desc = "+0.2 MTM on 4th Down plays" },
    { name = "Lamar Rivers", pos = "QB", rarity = "Silver", ovr = 76, chip = 1, mult = 0.15, tag = "STARTER", desc = "+1 YDS on Short Passes" },
    
    -- Running Backs (15)
    { name = "Buster Iron", pos = "RB", rarity = "X-Factor", ovr = 96, chip = 0, mult = 0.0, tag = "MOMENTUM RB", desc = "x2.0 MTM if you played a Run on the previous down.", ability = function(self, playCard, gameState, c, m)
        if gameState.lastPlayResult and gameState.lastPlayResult:match("Run") then return c, m * 2.0 end
        return c, m
    end},
    { name = "Rex Thunder", pos = "RB", rarity = "X-Factor", ovr = 94, chip = 0, mult = 0.0, tag = "WORKHORSE", desc = "Permanently gains +1 YDS every time you play a Run.", ability = function(self, playCard, gameState, c, m)
        self.runsCalled = self.runsCalled or 0
        if playCard.type == "Run" then self.runsCalled = self.runsCalled + 1 end
        return c + self.runsCalled, m
    end},
    { name = "Colt Savage", pos = "RB", rarity = "X-Factor", ovr = 98, chip = 0, mult = 0.0, tag = "SCREEN KING", desc = "x2.5 MTM on Short Passes if you have 3+ Drives left.", ability = function(self, playCard, gameState, c, m)
        if playCard.type == "Short Pass" and gameState.drivesRemaining >= 3 then return c, m * 2.5 end
        return c, m
    end},
    { name = "Brock Surge", pos = "RB", rarity = "Gold", ovr = 89, chip = 3, mult = 0.35, tag = "WRECKING BALL RB", desc = "+3 YDS on Inside Runs" },
    { name = "Duke Blitz", pos = "RB", rarity = "Gold", ovr = 87, chip = 3, mult = 0.3, tag = "WRECKING BALL RB", desc = "+3 YDS on 1st & 2nd Down Runs" },
    { name = "Zack Striker", pos = "RB", rarity = "Gold", ovr = 86, chip = 2, mult = 0.35, tag = "ELUSIVE RB", desc = "+0.35 MTM on Jet Sweeps" },
    { name = "Tyson Hammer", pos = "RB", rarity = "Gold", ovr = 88, chip = 3, mult = 0.3, tag = "WRECKING BALL RB", desc = "+3 YDS on Run plays" },
    { name = "Jaxson Speed", pos = "RB", rarity = "Gold", ovr = 85, chip = 2, mult = 0.25, tag = "RECEIVING RB", desc = "+2 YDS on Screens" },
    { name = "Leo Voltage", pos = "RB", rarity = "Gold", ovr = 84, chip = 2, mult = 0.25, tag = "ELUSIVE RB", desc = "+0.25 MTM on Outside Runs" },
    { name = "Knox Cannon", pos = "RB", rarity = "Silver", ovr = 79, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Inside Zone" },
    { name = "Dash Miller", pos = "RB", rarity = "Silver", ovr = 78, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on HB Stretch" },
    { name = "Chase Ryno", pos = "RB", rarity = "Silver", ovr = 77, chip = 1, mult = 0.15, tag = "STARTER", desc = "+1 YDS on Run plays" },
    { name = "Blaze Flint", pos = "RB", rarity = "Silver", ovr = 76, chip = 1, mult = 0.15, tag = "STARTER", desc = "+0.15 MTM on Screen Passes" },
    { name = "Stone Vance", pos = "RB", rarity = "Silver", ovr = 75, chip = 1, mult = 0.1, tag = "STARTER", desc = "+1 YDS on HB Dive" },
    { name = "Cliff Walker", pos = "RB", rarity = "Silver", ovr = 74, chip = 1, mult = 0.1, tag = "STARTER", desc = "+1 YDS on Run plays" },

    -- Wide Receivers (20)
    { name = "Flash Gordon", pos = "WR", rarity = "X-Factor", ovr = 99, chip = 0, mult = 0.0, tag = "SPEEDSTER", desc = "Gains +5 YDS for every Audible remaining.", ability = function(self, playCard, gameState, c, m)
        return c + (gameState.audiblesRemaining * 5), m
    end},
    { name = "Sonic Star", pos = "WR", rarity = "X-Factor", ovr = 98, chip = 0, mult = 0.0, tag = "DEEP THREAT WR", desc = "x1.5 MTM for every Deep Pass played this game.", ability = function(self, playCard, gameState, c, m)
        self.deepTotal = self.deepTotal or 0
        if playCard.type == "Deep Pass" then self.deepTotal = self.deepTotal + 1 end
        return c, m * (1.0 + (self.deepTotal * 0.5))
    end},
    { name = "Chase Skylark", pos = "WR", rarity = "X-Factor", ovr = 96, chip = 0, mult = 0.0, tag = "SLOT DEMON WR", desc = "+8 YDS if your hand contains a Screen.", ability = function(self, playCard, gameState, c, m)
        local hasScreen = false
        local DeckManager = require("src.engine.deck_manager")
        for _, handCard in ipairs(DeckManager.hand or {}) do
            if handCard.name == "Screen Pass" then hasScreen = true end
        end
        if hasScreen then return c + 8, m end
        return c, m
    end},
    { name = "Zane Apex", pos = "WR", rarity = "X-Factor", ovr = 95, chip = 0, mult = 0.0, tag = "ENDZONE THREAT", desc = "x3.0 MTM if in the Red Zone (Yard Line >= 80).", ability = function(self, playCard, gameState, c, m)
        if gameState.yardLine >= 80 then return c, m * 3.0 end
        return c, m
    end},
    { name = "Jet Talon", pos = "WR", rarity = "X-Factor", ovr = 94, chip = 0, mult = 0.0, tag = "RETRIGGER", desc = "Permanently gains +1 YDS and +0.1 MTM every 1st Down.", ability = function(self, playCard, gameState, c, m)
        self.firstDowns = self.firstDowns or 0
        if gameState.down == 1 then self.firstDowns = self.firstDowns + 1 end
        return c + self.firstDowns, m + (self.firstDowns * 0.1)
    end},
    { name = "Kip Dynamo", pos = "WR", rarity = "Gold", ovr = 89, chip = 3, mult = 0.4, tag = "SLOT DEMON WR", desc = "+3 YDS on 3rd Down Passes" },
    { name = "Orion Bolt", pos = "WR", rarity = "Gold", ovr = 88, chip = 3, mult = 0.4, tag = "PLAYMAKER WR", desc = "+3 YDS on Red Zone plays" },
    { name = "Kaden Cross", pos = "WR", rarity = "Gold", ovr = 87, chip = 2, mult = 0.35, tag = "PLAYMAKER WR", desc = "+2 YDS on Medium Passes" },
    { name = "Dax Maverick", pos = "WR", rarity = "Gold", ovr = 86, chip = 2, mult = 0.35, tag = "PLAYMAKER WR", desc = "+2 YDS on Quick Slants" },
    { name = "Pax Viper", pos = "WR", rarity = "Gold", ovr = 85, chip = 2, mult = 0.3, tag = "SLOT DEMON WR", desc = "+2 YDS on Short Passes" },
    { name = "Ryder Flare", pos = "WR", rarity = "Gold", ovr = 86, chip = 2, mult = 0.35, tag = "PLAYMAKER WR", desc = "+0.35 MTM on Play Action" },
    { name = "Trey Razor", pos = "WR", rarity = "Gold", ovr = 87, chip = 3, mult = 0.35, tag = "DEEP THREAT WR", desc = "+3 YDS on Deep Passes" },
    { name = "Finn Pulse", pos = "WR", rarity = "Silver", ovr = 79, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Pass plays" },
    { name = "Ty Echo", pos = "WR", rarity = "Silver", ovr = 78, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Deep Passes" },
    { name = "Cruz Orbit", pos = "WR", rarity = "Silver", ovr = 79, chip = 2, mult = 0.2, tag = "PLAYMAKER WR", desc = "+2 YDS on Jet Sweeps & Runs" },
    { name = "Nico Shift", pos = "WR", rarity = "Silver", ovr = 78, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Slot Routes" },
    { name = "Zander Spark", pos = "WR", rarity = "Silver", ovr = 77, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Out Routes" },
    { name = "Bodhi Jet", pos = "WR", rarity = "Silver", ovr = 76, chip = 1, mult = 0.15, tag = "STARTER", desc = "+1 YDS on Pass plays" },
    { name = "Vance Comet", pos = "WR", rarity = "Silver", ovr = 76, chip = 1, mult = 0.15, tag = "STARTER", desc = "+1 YDS on Curls" },
    { name = "Jett Nova", pos = "WR", rarity = "Silver", ovr = 75, chip = 1, mult = 0.1, tag = "STARTER", desc = "+1 YDS on Drag Routes" },

    -- Tight Ends (13)
    { name = "Titan Titan", pos = "TE", rarity = "X-Factor", ovr = 98, chip = 5, mult = 0.6, tag = "VERTICAL TE", desc = "+5 YDS, +0.6 MTM on all Pass plays" },
    { name = "Goliath Steel", pos = "TE", rarity = "X-Factor", ovr = 96, chip = 4, mult = 0.5, tag = "PANCAKE TE", desc = "+4 YDS on Run & Play Action plays" },
    { name = "Thor Hammer", pos = "TE", rarity = "Gold", ovr = 88, chip = 3, mult = 0.4, tag = "VERTICAL TE", desc = "+3 YDS on 3rd Down Passes" },
    { name = "Atlas Stone", pos = "TE", rarity = "Gold", ovr = 86, chip = 2, mult = 0.35, tag = "VERTICAL TE", desc = "+2 YDS on Red Zone plays" },
    { name = "Bruno Wall", pos = "TE", rarity = "Gold", ovr = 85, chip = 2, mult = 0.3, tag = "VERTICAL TE", desc = "+2 YDS on Medium Passes" },
    { name = "Knox Shield", pos = "TE", rarity = "Gold", ovr = 84, chip = 2, mult = 0.3, tag = "PANCAKE TE", desc = "+2 YDS on Run plays" },
    { name = "Baron Block", pos = "TE", rarity = "Silver", ovr = 79, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Short Passes" },
    { name = "Mason Rock", pos = "TE", rarity = "Silver", ovr = 78, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Play Action" },
    { name = "Brutus Slam", pos = "TE", rarity = "Silver", ovr = 77, chip = 1, mult = 0.2, tag = "STARTER", desc = "+1 YDS on Deep Passes" },
    { name = "Samson Gate", pos = "TE", rarity = "Silver", ovr = 77, chip = 1, mult = 0.15, tag = "STARTER", desc = "+1 YDS on Pass plays" },
    { name = "Mack Fortress", pos = "TE", rarity = "Silver", ovr = 76, chip = 1, mult = 0.1, tag = "STARTER", desc = "+1 YDS on Seam Routes" },
    { name = "Burl Mason", pos = "TE", rarity = "Silver", ovr = 75, chip = 1, mult = 0.1, tag = "STARTER", desc = "+1 YDS on Red Zone plays" },
    { name = "Clyde Tower", pos = "TE", rarity = "Silver", ovr = 74, chip = 1, mult = 0.1, tag = "STARTER", desc = "+1 YDS on Pass plays" },

    -- Defensive Linemen (DL)
    { name = "Tank Destroyer", pos = "DL", rarity = "X-Factor", ovr = 98, chip = 0, mult = 0.0, tag = "PASS RUSHER", desc = "Elite pass rusher. Target Score reduced by 1." },
    { name = "Sack Master", pos = "DL", rarity = "Gold", ovr = 87, chip = 0, mult = 0.0, tag = "EDGE", desc = "Solid pressure." },
    { name = "Rookie Edge", pos = "DL", rarity = "Silver", ovr = 75, chip = 0, mult = 0.0, tag = "ROTATIONAL", desc = "Basic DL." },

    -- Linebackers (LB)
    { name = "Ray Tackle", pos = "LB", rarity = "X-Factor", ovr = 99, chip = 0, mult = 0.0, tag = "RUN STOPPER", desc = "Elite run stopper. +10% Drive chance." },
    { name = "Bobby Blitz", pos = "LB", rarity = "Gold", ovr = 88, chip = 0, mult = 0.0, tag = "MIKE", desc = "Field general LB." },
    { name = "Rookie LB", pos = "LB", rarity = "Silver", ovr = 76, chip = 0, mult = 0.0, tag = "ROTATIONAL", desc = "Basic LB." },

    -- Defensive Backs (DB)
    { name = "Deion Pick", pos = "DB", rarity = "X-Factor", ovr = 99, chip = 0, mult = 0.0, tag = "BALL HAWK", desc = "Elite ball hawk. +5% Pick Six chance." },
    { name = "Island Corner", pos = "DB", rarity = "Gold", ovr = 86, chip = 0, mult = 0.0, tag = "SHUTDOWN", desc = "Locks down WRs." },
    { name = "Rookie DB", pos = "DB", rarity = "Silver", ovr = 74, chip = 0, mult = 0.0, tag = "ROTATIONAL", desc = "Basic DB." },

    -- Kickers (K)
    { name = "Golden Boot", pos = "K", rarity = "X-Factor", ovr = 98, chip = 0, mult = 0.0, tag = "CLUTCH", desc = "Automatic from anywhere." },
    { name = "Reliable Leg", pos = "K", rarity = "Gold", ovr = 85, chip = 0, mult = 0.0, tag = "KICKER", desc = "Solid kicker." },
    { name = "Rookie Kicker", pos = "K", rarity = "Silver", ovr = 72, chip = 0, mult = 0.0, tag = "KICKER", desc = "Basic Kicker." },
    
    -- Additional Fake/Predetermined QBs
    { name = "Gage Thunderbolt", pos = "QB", rarity = "Silver", ovr = 75, chip = 1, mult = 0.15, tag = "STARTER", desc = "Basic passing." },
    { name = "Orion Steele", pos = "QB", rarity = "Gold", ovr = 82, chip = 2, mult = 0.2, tag = "GUNSLINGER", desc = "Strong arm." },
    { name = "Dash Ironheart", pos = "QB", rarity = "X-Factor", ovr = 93, chip = 0, mult = 0.0, tag = "SCRAMBLER", desc = "x1.5 MTM on Runs." },
    { name = "Zephyr Cross", pos = "QB", rarity = "Silver", ovr = 78, chip = 1, mult = 0.1, tag = "STARTER", desc = "+1 YDS." },
    { name = "Ryker Stone", pos = "QB", rarity = "Gold", ovr = 87, chip = 2, mult = 0.25, tag = "FIELD GENERAL", desc = "+2 YDS on Short Passes." },
    { name = "Corbin Swift", pos = "QB", rarity = "Silver", ovr = 74, chip = 1, mult = 0.1, tag = "STARTER", desc = "+1 YDS." },
    { name = "Knox Voltage", pos = "QB", rarity = "Gold", ovr = 89, chip = 3, mult = 0.3, tag = "CLUTCH", desc = "Clutch player." },
    { name = "Dax Maverick", pos = "QB", rarity = "Silver", ovr = 73, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup QB." },
    { name = "Vance Storm", pos = "QB", rarity = "Gold", ovr = 81, chip = 2, mult = 0.2, tag = "STARTER", desc = "+2 YDS." },
    { name = "Jace Falcon", pos = "QB", rarity = "Silver", ovr = 71, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup QB." },

    -- Additional Fake/Predetermined RBs
    { name = "Boomer Vance", pos = "RB", rarity = "Silver", ovr = 76, chip = 1, mult = 0.1, tag = "POWER BACK", desc = "+1 YDS." },
    { name = "Jet Sterling", pos = "RB", rarity = "Gold", ovr = 85, chip = 2, mult = 0.25, tag = "SPEEDSTER", desc = "+2 YDS on Sweeps." },
    { name = "Brick Wall", pos = "RB", rarity = "X-Factor", ovr = 95, chip = 0, mult = 0.0, tag = "WRECKING BALL", desc = "+5 YDS on Inside Runs." },
    { name = "Zane Striker", pos = "RB", rarity = "Silver", ovr = 73, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup RB." },
    { name = "Colton Rush", pos = "RB", rarity = "Gold", ovr = 83, chip = 2, mult = 0.2, tag = "ELUSIVE", desc = "+2 YDS." },
    { name = "Drake Talon", pos = "RB", rarity = "Silver", ovr = 71, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup RB." },
    { name = "Rex Hazard", pos = "RB", rarity = "Gold", ovr = 88, chip = 3, mult = 0.3, tag = "POWER BACK", desc = "+3 YDS on Dives." },
    { name = "Flint Rider", pos = "RB", rarity = "Silver", ovr = 70, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup RB." },
    { name = "Mack Rhino", pos = "RB", rarity = "Gold", ovr = 80, chip = 2, mult = 0.2, tag = "STARTER", desc = "+2 YDS." },
    { name = "Jax Cannon", pos = "RB", rarity = "Silver", ovr = 68, chip = 1, mult = 0.1, tag = "STARTER", desc = "Practice Squad." },

    -- Additional Fake/Predetermined WRs
    { name = "Tyron Jet", pos = "WR", rarity = "Gold", ovr = 84, chip = 2, mult = 0.25, tag = "DEEP THREAT", desc = "+2 YDS." },
    { name = "Silas Hawk", pos = "WR", rarity = "Silver", ovr = 75, chip = 1, mult = 0.15, tag = "STARTER", desc = "+1 YDS." },
    { name = "Neo Blaze", pos = "WR", rarity = "X-Factor", ovr = 94, chip = 0, mult = 0.0, tag = "SLOT DEMON", desc = "x1.5 MTM on Quick Slants." },
    { name = "Deacon Frost", pos = "WR", rarity = "Gold", ovr = 81, chip = 2, mult = 0.2, tag = "POSSESSION", desc = "+2 YDS." },
    { name = "Blade Runner", pos = "WR", rarity = "Silver", ovr = 73, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup WR." },
    { name = "Cash Diamond", pos = "WR", rarity = "Gold", ovr = 86, chip = 3, mult = 0.3, tag = "PLAYMAKER", desc = "+3 YDS on Red Zone." },
    { name = "Titus Cross", pos = "WR", rarity = "Silver", ovr = 72, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup WR." },
    { name = "Zion Flash", pos = "WR", rarity = "Gold", ovr = 89, chip = 3, mult = 0.35, tag = "DEEP THREAT", desc = "+3 YDS on Deep Passes." },
    { name = "Axel Rose", pos = "WR", rarity = "Silver", ovr = 71, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup WR." },
    { name = "Kylo Swift", pos = "WR", rarity = "Gold", ovr = 80, chip = 2, mult = 0.2, tag = "STARTER", desc = "+2 YDS." },

    -- Additional Fake/Predetermined TEs
    { name = "Grover Shield", pos = "TE", rarity = "Gold", ovr = 82, chip = 2, mult = 0.25, tag = "PANCAKE TE", desc = "+2 YDS on Runs." },
    { name = "Diesel Iron", pos = "TE", rarity = "Silver", ovr = 75, chip = 1, mult = 0.1, tag = "STARTER", desc = "+1 YDS." },
    { name = "Hulk Smash", pos = "TE", rarity = "X-Factor", ovr = 93, chip = 0, mult = 0.0, tag = "BLOCKER", desc = "x1.5 MTM on Runs." },
    { name = "Cyrus Rock", pos = "TE", rarity = "Gold", ovr = 85, chip = 2, mult = 0.3, tag = "VERTICAL TE", desc = "+2 YDS on Medium Passes." },
    { name = "Talon Grip", pos = "TE", rarity = "Silver", ovr = 72, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup TE." },
    { name = "Brock Tower", pos = "TE", rarity = "Gold", ovr = 81, chip = 2, mult = 0.2, tag = "POSSESSION", desc = "+2 YDS." },
    { name = "Max Block", pos = "TE", rarity = "Silver", ovr = 70, chip = 1, mult = 0.1, tag = "STARTER", desc = "Backup TE." },

    -- Additional Defense / Special
    { name = "Thor Hammer", pos = "DL", rarity = "Gold", ovr = 89, chip = 0, mult = 0.0, tag = "RUN STOPPER", desc = "DL" },
    { name = "Viper Strike", pos = "LB", rarity = "X-Factor", ovr = 92, chip = 0, mult = 0.0, tag = "COVERAGE", desc = "LB" },
    { name = "Hawk Eye", pos = "DB", rarity = "Gold", ovr = 85, chip = 0, mult = 0.0, tag = "BALL HAWK", desc = "DB" },
    { name = "Legatron", pos = "K", rarity = "X-Factor", ovr = 95, chip = 0, mult = 0.0, tag = "CLUTCH", desc = "Kicker" }
}

local RosterPlayersExpanded = {}

function RosterPlayersExpanded.getAllPlayers()
    local all = {}
    for _, template in ipairs(rosterCatalog) do
        local player = PlayerCard.new(template.name, template.pos, template.rarity, template.mult, template.chip)
        player.overall = template.ovr
        player.archetypeTag = template.tag
        player.abilityDesc = template.desc
        player.ability = template.ability
        table.insert(all, player)
    end
    return all
end

function RosterPlayersExpanded.getRandomPlayer(posFilter)
    local filtered = {}
    for _, p in ipairs(rosterCatalog) do
        if not posFilter or p.pos == posFilter then
            table.insert(filtered, p)
        end
    end
    
    local template = filtered[math.random(#filtered)]
    
    local player = PlayerCard.new(template.name, template.pos, template.rarity, template.mult, template.chip)
    player.overall = template.ovr
    player.archetypeTag = template.tag
    player.abilityDesc = template.desc
    player.ability = template.ability
    
    return player
end

function RosterPlayersExpanded.getPlayerByName(name)
    local template = nil
    for _, p in ipairs(rosterCatalog) do
        if p.name == name then
            template = p
            break
        end
    end
    if not template then return nil end
    
    local player = PlayerCard.new(template.name, template.pos, template.rarity, template.mult, template.chip)
    player.overall = template.ovr
    player.archetypeTag = template.tag
    player.abilityDesc = template.desc
    player.ability = template.ability
    return player
end

return RosterPlayersExpanded
