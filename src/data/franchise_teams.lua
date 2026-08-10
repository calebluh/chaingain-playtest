-- src/data/franchise_teams.lua

return {
    {
        id = "KC",
        name = "Kansas City Red Kingdom",
        city = "Kansas City",
        perk = "+1 Extra Audible per drive & +$2 Starting Cash.",
        primaryColor = {0.85, 0.15, 0.15},
        secondaryColor = {1.0, 0.84, 0.0},
        weather = "clear",
        bonusCash = 2,
        bonusAudibles = 1
    },
    {
        id = "MIA",
        name = "Miami Wave",
        city = "Miami",
        perk = "+2 Base Yards on all Run & Short Pass plays.",
        primaryColor = {0.0, 0.75, 0.75},
        secondaryColor = {1.0, 0.45, 0.2},
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
        secondaryColor = {1.0, 0.84, 0.0},
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
        name = "Dallas Lone Stars",
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
    },
    {
        id = "BAL",
        name = "Baltimore Ravens",
        city = "Baltimore",
        perk = "+4 Base Yards on Power Runs & Heavy Schemes.",
        primaryColor = {0.3, 0.1, 0.5},
        secondaryColor = {0.9, 0.75, 0.2},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "CIN",
        name = "Cincinnati Stripes",
        city = "Cincinnati",
        perk = "+2.0 MTM Boost on Deep Vertical Passes.",
        primaryColor = {0.95, 0.4, 0.1},
        secondaryColor = {0.1, 0.1, 0.1},
        weather = "clear",
        multBonus = 0.5
    },
    {
        id = "CLE",
        name = "Cleveland Browns",
        city = "Cleveland",
        perk = "Muddy Weather! +3 Base Yards on Inside Zone Runs.",
        primaryColor = {0.4, 0.2, 0.1},
        secondaryColor = {0.95, 0.4, 0.1},
        weather = "rain",
        passBonus = 1
    },
    {
        id = "PIT",
        name = "Pittsburgh Iron",
        city = "Pittsburgh",
        perk = "+1.0 MTM on critical 3rd & 4th Down attempts.",
        primaryColor = {0.1, 0.1, 0.1},
        secondaryColor = {1.0, 0.84, 0.0},
        weather = "clear",
        multBonus = 0.4
    },
    {
        id = "HOU",
        name = "Houston Orbit",
        city = "Houston",
        perk = "+2 Base Yards on RPO & Screen plays.",
        primaryColor = {0.05, 0.15, 0.3},
        secondaryColor = {0.8, 0.1, 0.15},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "IND",
        name = "Indy Horseshoes",
        city = "Indianapolis",
        perk = "+1 Extra Audible on every drive.",
        primaryColor = {0.0, 0.25, 0.65},
        secondaryColor = {1.0, 1.0, 1.0},
        weather = "clear",
        bonusAudibles = 1
    },
    {
        id = "JAX",
        name = "Jacksonville Predators",
        city = "Jacksonville",
        perk = "+3 Base Yards on Jet Sweeps & Reverses.",
        primaryColor = {0.0, 0.5, 0.5},
        secondaryColor = {0.85, 0.7, 0.2},
        weather = "clear",
        passBonus = 1
    },
    {
        id = "TEN",
        name = "Tennessee Titans",
        city = "Nashville",
        perk = "+4 Base Yards on Ground & Pound Runs.",
        primaryColor = {0.3, 0.55, 0.85},
        secondaryColor = {0.85, 0.15, 0.15},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "DEN",
        name = "Denver Mile High",
        city = "Denver",
        perk = "High Altitude! +1.5 MTM in Red Zone plays.",
        primaryColor = {0.95, 0.35, 0.1},
        secondaryColor = {0.05, 0.15, 0.35},
        weather = "clear",
        multBonus = 0.5
    },
    {
        id = "LAC",
        name = "LA Lightning",
        city = "Los Angeles",
        perk = "+3 Base Yards on Medium Out & Dig Routes.",
        primaryColor = {0.2, 0.7, 1.0},
        secondaryColor = {1.0, 0.84, 0.0},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "NE",
        name = "New England Dynasty",
        city = "Foxborough",
        perk = "+1 Audible & +$2 Drive payout bonus.",
        primaryColor = {0.05, 0.15, 0.3},
        secondaryColor = {0.8, 0.1, 0.15},
        weather = "snow",
        bonusAudibles = 1,
        bonusCash = 2
    },
    {
        id = "NYJ",
        name = "New York Jets",
        city = "East Rutherford",
        perk = "+2 Base Yards on Short Crossing routes.",
        primaryColor = {0.08, 0.35, 0.2},
        secondaryColor = {1.0, 1.0, 1.0},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "NYG",
        name = "New York Giants",
        city = "East Rutherford",
        perk = "+3 Base Yards on Play Action Flood concepts.",
        primaryColor = {0.05, 0.2, 0.55},
        secondaryColor = {0.85, 0.15, 0.15},
        weather = "clear",
        playActionBonus = 3
    },
    {
        id = "WAS",
        name = "Washington Commanders",
        city = "Landover",
        perk = "+2 Base Yards on Counter & Trap runs.",
        primaryColor = {0.5, 0.1, 0.15},
        secondaryColor = {0.9, 0.75, 0.2},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "CHI",
        name = "Chicago Monsters",
        city = "Chicago",
        perk = "Snow Weather! +4 Base Yards on QB Runs.",
        primaryColor = {0.05, 0.12, 0.25},
        secondaryColor = {0.9, 0.35, 0.1},
        weather = "snow",
        passBonus = 2
    },
    {
        id = "DET",
        name = "Detroit Pride",
        city = "Detroit",
        perk = "+1.0 MTM on all 4th Down conversions.",
        primaryColor = {0.0, 0.45, 0.8},
        secondaryColor = {0.75, 0.75, 0.75},
        weather = "clear",
        multBonus = 0.4
    },
    {
        id = "MIN",
        name = "Minnesota Vikings",
        city = "Minneapolis",
        perk = "+3 Base Yards on Deep Crosser routes.",
        primaryColor = {0.35, 0.15, 0.55},
        secondaryColor = {1.0, 0.84, 0.0},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "ATL",
        name = "Atlanta Falcons",
        city = "Atlanta",
        perk = "+2.0 MTM on Go & Deep Fly routes.",
        primaryColor = {0.75, 0.1, 0.15},
        secondaryColor = {0.1, 0.1, 0.1},
        weather = "clear",
        multBonus = 0.5
    },
    {
        id = "CAR",
        name = "Carolina Panthers",
        city = "Charlotte",
        perk = "+3 Base Yards on QB & RB Option Runs.",
        primaryColor = {0.1, 0.1, 0.1},
        secondaryColor = {0.0, 0.6, 0.9},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "NO",
        name = "New Orleans Saints",
        city = "New Orleans",
        perk = "+2 Base Yards on Quick Slants & Screens.",
        primaryColor = {0.8, 0.7, 0.3},
        secondaryColor = {0.1, 0.1, 0.1},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "TB",
        name = "Tampa Bay Buccaneers",
        city = "Tampa",
        perk = "+3 Base Yards on Tight End Seam routes.",
        primaryColor = {0.75, 0.12, 0.15},
        secondaryColor = {0.45, 0.45, 0.45},
        weather = "clear",
        passBonus = 2
    },
    {
        id = "ARI",
        name = "Arizona Desert",
        city = "Glendale",
        perk = "+2.0 MTM on 4-WR Spread Passing formations.",
        primaryColor = {0.7, 0.1, 0.15},
        secondaryColor = {1.0, 1.0, 1.0},
        weather = "clear",
        multBonus = 0.5
    },
    {
        id = "LAR",
        name = "LA Rams",
        city = "Los Angeles",
        perk = "+3 Base Yards on Wide Zone & Bootleg passes.",
        primaryColor = {0.0, 0.35, 0.85},
        secondaryColor = {1.0, 0.84, 0.0},
        weather = "clear",
        playActionBonus = 3
    },
    {
        id = "SEA",
        name = "Seattle Emerald",
        city = "Seattle",
        perk = "Rain Weather! Crowd noise yields +0.5 MTM on all plays.",
        primaryColor = {0.05, 0.15, 0.3},
        secondaryColor = {0.4, 0.85, 0.1},
        weather = "rain",
        multBonus = 0.5
    }
}
