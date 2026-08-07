-- src/data/franchise_teams.lua

return {
    {
        id = "KC",
        name = "Kansas City Dynasty",
        city = "Kansas City",
        perk = "+1 Extra Audible per drive. Dynasty Championship heritage.",
        primaryColor = {0.85, 0.15, 0.15},
        secondaryColor = {1, 0.84, 0},
        weather = "clear",
        bonusCash = 2,
        bonusAudibles = 1
    },
    {
        id = "MIA",
        name = "Miami Speed Demons",
        city = "Miami",
        perk = "+2 Base Yards on all Run & Short Pass plays.",
        primaryColor = {0.0, 0.75, 0.75},
        secondaryColor = {1, 0.45, 0.2},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "BUF",
        name = "Buffalo Blizzard",
        city = "Buffalo",
        perk = "Snow Stadium Weather! +0.5 MTM on all plays.",
        primaryColor = {0.0, 0.35, 0.85},
        secondaryColor = {0.85, 0.15, 0.15},
        weather = "snow",
        multBonus = 0.5
    },
    {
        id = "GB",
        name = "Green Bay Tundra",
        city = "Green Bay",
        perk = "Frozen Stadium Weather! Extra TE Roster Slot.",
        primaryColor = {0.1, 0.35, 0.2},
        secondaryColor = {1, 0.84, 0},
        weather = "snow",
        extraTESlot = true
    },
    {
        id = "PHI",
        name = "Philly Eagles",
        city = "Philadelphia",
        perk = "+$3 Cap Space bonus on every Touchdown.",
        primaryColor = {0.0, 0.4, 0.3},
        secondaryColor = {0.7, 0.75, 0.8},
        weather = "clear",
        touchdownBonusCash = 3
    },
    {
        id = "SF",
        name = "San Francisco Gold",
        city = "San Francisco",
        perk = "+3 Base Yards on all Play Action plays.",
        primaryColor = {0.75, 0.12, 0.15},
        secondaryColor = {0.9, 0.75, 0.2},
        weather = "rain",
        playActionBonus = 3
    },
    {
        id = "DAL",
        name = "Dallas Stars",
        city = "Dallas",
        perk = "Star Quarterback starts at 99 OVR.",
        primaryColor = {0.05, 0.18, 0.35},
        secondaryColor = {0.85, 0.85, 0.9},
        weather = "clear",
        superstarQB = true
    },
    {
        id = "VEGAS",
        name = "Vegas High Rollers",
        city = "Las Vegas",
        perk = "Start run with +$10 bonus Cap Space.",
        primaryColor = {0.1, 0.1, 0.1},
        secondaryColor = {0.9, 0.75, 0.2},
        weather = "clear",
        bonusCash = 10
    }
}
