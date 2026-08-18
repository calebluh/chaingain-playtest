-- src/data/vouchers.lua

return {
    {
        id = "analytics_dept",
        name = "Analytics Dept",
        cost = 10,
        description = "See Defensive Scheme hints before calling your play.",
        apply = function(gameState) gameState.hasAnalyticsDept = true end
    },
    {
        id = "salary_cap_inflation",
        name = "Cap Inflation",
        cost = 10,
        description = "Earn +$2 Cap Space bonus at the end of every drive.",
        apply = function(gameState) gameState.bonusDriveCash = (gameState.bonusDriveCash or 0) + 2 end
    },
    {
        id = "no_huddle_master",
        name = "No-Huddle Master",
        cost = 10,
        description = "Draw +1 extra Play Card into your hand on every drive.",
        apply = function(gameState) 
            local DeckManager = require("src.engine.deck_manager")
            DeckManager.handSize = (DeckManager.handSize or 5) + 1 
        end
    },
    {
        id = "scouting_network",
        name = "Scouting Network",
        cost = 10,
        description = "Shop rerolls cost $1 Cap Space instead of $2.",
        apply = function(gameState) gameState.rerollCost = 1 end
    },
    {
        id = "booster_budget",
        name = "Booster Club",
        cost = 10,
        description = "All Shop items cost $1 less Cap Space.",
        apply = function(gameState) gameState.shopDiscount = 1 end
    },
    {
        id = "audible_overdrive",
        name = "Audible Overdrive",
        cost = 10,
        description = "Gain +2 extra Audibles per drive.",
        apply = function(gameState) gameState.bonusAudibles = (gameState.bonusAudibles or 0) + 2 end
    },
    {
        id = "red_zone_specialist",
        name = "Red Zone Package",
        cost = 10,
        description = "Completely ignores the Red Zone 70% yard resistance penalty.",
        apply = function(gameState) gameState.ignoreRedZonePenalty = true end
    },
    {
        id = "veteran_leadership",
        name = "Veteran Leadership",
        cost = 10,
        description = "All owned Roster Player cards gain +2 Base Yards.",
        apply = function(gameState) gameState.globalRosterChips = (gameState.globalRosterChips or 0) + 2 end
    },
    {
        id = "franchise_tag",
        name = "Franchise Tag",
        cost = 10,
        description = "Allows equipping 1 extra FLEX slot.",
        apply = function(gameState)
            if gameState.rosterSlots and gameState.rosterSlots.FLEX then
                gameState.rosterSlots.FLEX.max = gameState.rosterSlots.FLEX.max + 1
            end
        end
    },
    {
        id = "clutch_kicker",
        name = "Clutch Kicker",
        cost = 10,
        description = "Kicking Field Goals awards +4 Points instead of +3 Points.",
        apply = function(gameState) gameState.fieldGoalValue = 4 end
    },
    {
        id = "halftime_adjuster",
        name = "Halftime Adjuster",
        cost = 10,
        description = "Restores +1 Drive if you are trailing in points in the 3rd drive.",
        apply = function(gameState) gameState.hasHalftimeAdjuster = true end
    },
    {
        id = "dynasty_mode",
        name = "Dynasty Mode",
        cost = 10,
        description = "Touchdown payout is increased by +$4 Cap Space.",
        apply = function(gameState) gameState.touchdownBonusCash = (gameState.touchdownBonusCash or 0) + 4 end
    },
    -- ── 3 NEW VOUCHERS (v2.0 Update) ────────────────────────────────
    {
        id = "draft_day_trade",
        name = "Draft Day Trade",
        cost = 10,
        description = "All Play Card packs bought in the Shop cost $2 less Cap Space.",
        apply = function(gameState)
            gameState.playPackDiscount = (gameState.playPackDiscount or 0) + 2
        end
    },
    {
        id = "clutch_gene",
        name = "Clutch Gene",
        cost = 10,
        description = "On 4th Down plays, all cards gain +5 bonus Base Yards.",
        apply = function(gameState)
            gameState.clutchGenePerk = true
        end
    },
    {
        id = "film_room",
        name = "Film Room",
        cost = 10,
        description = "At the start of each game, reveals the full Defensive Scheme description.",
        apply = function(gameState)
            gameState.hasFilmRoom = true
        end
    }
}
