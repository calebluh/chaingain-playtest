-- src/data/defensive_blinds.lua
-- DEFENSIVE SCHEMES: Standard = Pro-level defenses, Boss = All-Time Legendary Defenses

return {
    -- STANDARD DEFENSES (Pro-Level Schemes)
    {
        id = "cover_3",
        name = "Cover 3 Zone",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_cover3.png",
        description = "-50% Momentum on Deep Pass plays",
        evaluate = function(playType, chips, mult)
            if playType == "Deep Pass" then
                return chips, math.max(1, mult * 0.5)
            end
            return chips, mult
        end
    },
    {
        id = "blitz_heavy",
        name = "All-Out Blitz",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_blitz.png",
        description = "-3 Base Yards on Play Action plays",
        evaluate = function(playType, chips, mult)
            if playType == "Play Action" then
                return math.max(0, chips - 3), mult
            end
            return chips, mult
        end
    },
    {
        id = "stuffed_box",
        name = "Loaded Box Front",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "-50% Momentum on Run plays",
        evaluate = function(playType, chips, mult)
            if playType == "Run" then
                return chips, math.max(1, mult * 0.5)
            end
            return chips, mult
        end
    },
    {
        id = "cover_2_shell",
        name = "Tampa 2 Shell",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_cover2.png",
        description = "-40% Momentum on Medium & Deep Passes",
        evaluate = function(playType, chips, mult)
            if playType == "Medium Pass" or playType == "Deep Pass" then
                return chips, math.max(1, mult * 0.6)
            end
            return chips, mult
        end
    },
    {
        id = "weather_rain",
        name = "Monsoon Conditions",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_weather_rain.png",
        description = "-25% Momentum on ALL Pass plays",
        evaluate = function(playType, chips, mult)
            if playType ~= "Run" then
                return chips, math.max(1, mult * 0.75)
            end
            return chips, mult
        end
    },

    -- ALL-TIME LEGENDARY DEFENSES (Boss Tier)
    {
        id = "legion_of_boom",
        name = "Legion of Boom",
        type = "boss",
        tier = "All-Time Defense",
        icon = "def_boss_lob.png",
        description = "SEA '13: Deep Passes yield -50% Momentum",
        evaluate = function(playType, chips, mult)
            if playType == "Deep Pass" then
                return chips, math.max(0.5, mult * 0.5)
            end
            return chips, mult
        end
    },
    {
        id = "goal_line_stand",
        name = "The Steel Curtain",
        type = "boss",
        tier = "All-Time Defense",
        icon = "def_boss_curtain.png",
        description = "PIT '75: Run Plays are capped at 2 Yards!",
        evaluate = function(playType, chips, mult)
            if playType == "Run" then
                return math.min(chips, 2), math.min(mult, 1.0)
            end
            return chips, mult
        end
    },
    {
        id = "no_fly_zone",
        name = "No-Fly Zone",
        type = "boss",
        tier = "All-Time Defense",
        icon = "def_boss_nfz.png",
        description = "DEN '15: Deep Passes gain 0 Yards!",
        evaluate = function(playType, chips, mult)
            if playType == "Deep Pass" or playType == "Hail Mary" then
                return 0, 0.1
            end
            return chips, mult
        end
    },
    {
        id = "ironclad_front",
        name = "The '85 Bears",
        type = "boss",
        tier = "All-Time Defense",
        icon = "def_boss_85bears.png",
        description = "CHI '85: Run plays gain 0 Base Yards!",
        evaluate = function(playType, chips, mult)
            if playType == "Run" then
                return 0, mult
            end
            return chips, mult
        end
    },
    {
        id = "purple_people_eaters",
        name = "Purple People Eaters",
        type = "boss",
        tier = "All-Time Defense",
        icon = "def_boss_ppe.png",
        description = "MIN '69: Sack Chance increased by 30%!",
        evaluate = function(playType, chips, mult)
            if playType:match("Pass") or playType == "Play Action" then
                if math.random() < 0.3 then
                    return -5, 1.0
                end
            end
            return chips, mult
        end
    },
    {
        id = "fearsome_foursome",
        name = "Fearsome Foursome",
        type = "boss",
        tier = "All-Time Defense",
        icon = "def_boss_ff.png",
        description = "LA '67: Play Action & Short Passes capped at 3 YDS",
        evaluate = function(playType, chips, mult)
            if playType == "Play Action" or playType == "Short Pass" then
                return math.min(chips, 3), math.min(mult, 1.2)
            end
            return chips, mult
        end
    },

    -- ── 10 NEW STANDARD BLINDS ──────────────────────────────────────
    {
        id = "nickel_zone",
        name = "Nickel Zone Defense",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "-35% Momentum on Short Passes",
        evaluate = function(playType, chips, mult)
            if playType == "Short Pass" then
                return chips, math.max(1, mult * 0.65)
            end
            return chips, mult
        end
    },
    {
        id = "press_man",
        name = "Press Man Coverage",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "All Pass plays lose 4 Base Yards",
        evaluate = function(playType, chips, mult)
            if playType:match("Pass") or playType == "Play Action" then
                return math.max(0, chips - 4), mult
            end
            return chips, mult
        end
    },
    {
        id = "cover_4_quarters",
        name = "Cover 4 Quarters",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "Deep Pass & Hail Mary Momentum capped at 1.5x",
        evaluate = function(playType, chips, mult)
            if playType == "Deep Pass" or playType == "Hail Mary" then
                return chips, math.min(mult, 1.5)
            end
            return chips, mult
        end
    },
    {
        id = "zone_blitz",
        name = "Zone Blitz Confusion",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "30% chance any play loses 5 Base Yards",
        evaluate = function(playType, chips, mult)
            if math.random() < 0.30 then
                return math.max(0, chips - 5), mult
            end
            return chips, mult
        end
    },
    {
        id = "dime_package",
        name = "Dime Package",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "Run Plays gain +3 Base Yards but Pass Momentum -40%",
        evaluate = function(playType, chips, mult)
            if playType == "Run" then
                return chips + 3, mult
            elseif playType:match("Pass") then
                return chips, math.max(1, mult * 0.6)
            end
            return chips, mult
        end
    },
    {
        id = "bear_front",
        name = "46 Bear Front",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "Run Plays -6 Base Yards. Pass Plays unaffected.",
        evaluate = function(playType, chips, mult)
            if playType == "Run" then
                return math.max(0, chips - 6), mult
            end
            return chips, mult
        end
    },
    {
        id = "soft_zone",
        name = "Soft Zone Coverage",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "Run & Short Pass +2 YDS. Deep Pass -50% MTM.",
        evaluate = function(playType, chips, mult)
            if playType == "Run" or playType == "Short Pass" then
                return chips + 2, mult
            elseif playType == "Deep Pass" then
                return chips, math.max(1, mult * 0.5)
            end
            return chips, mult
        end
    },
    {
        id = "spy_coverage",
        name = "QB Spy Coverage",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "Play Action loses -5 YDS. Other plays unaffected.",
        evaluate = function(playType, chips, mult)
            if playType == "Play Action" then
                return math.max(0, chips - 5), mult
            end
            return chips, mult
        end
    },
    {
        id = "cover_0_blitz",
        name = "Cover 0 All-Out Blitz",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "Extreme pressure: 20% sack chance on ALL pass plays",
        evaluate = function(playType, chips, mult)
            if playType:match("Pass") or playType == "Play Action" then
                if math.random() < 0.20 then
                    return -8, 1.0
                end
            end
            return chips, mult
        end
    },
    {
        id = "goal_line_defense",
        name = "Goal Line Jumbo",
        type = "standard",
        tier = "Pro Defense",
        icon = "def_standard.png",
        description = "All plays capped at 5 Base Yards. Extra tough in red zone.",
        evaluate = function(playType, chips, mult)
            return math.min(chips, 5), mult
        end
    },

    -- ── 2 NEW LEGENDARY BOSS DEFENSES ───────────────────────────────
    {
        id = "doomsday_defense",
        name = "Doomsday Defense",
        type = "boss",
        tier = "All-Time Defense",
        icon = "def_boss_doomsday.png",
        description = "DAL '71: ALL plays lose 30% Base Yards. Brutal.",
        evaluate = function(playType, chips, mult)
            return math.floor(chips * 0.7), mult
        end
    },
    {
        id = "undefeated_72",
        name = "The '72 Dolphins",
        type = "boss",
        tier = "All-Time Defense",
        icon = "def_boss_72dolphins.png",
        description = "MIA '72: Short Pass & Run capped at 4 YDS. The Perfect Defense.",
        evaluate = function(playType, chips, mult)
            if playType == "Short Pass" or playType == "Run" then
                return math.min(chips, 4), mult
            end
            return chips, mult
        end
    }
}

