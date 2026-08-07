-- src/data/badges.lua

return {
    {
        id = "sticky_gloves",
        name = "Sticky Gloves",
        type = "Equipment",
        cost = 4,
        description = "Receiver Badge: +3 Base Yards on all Catch & Pass plays.",
        evaluate = function(gameState, playCard, chips, mult)
            if playCard and playCard.type:match("Pass") then
                return chips + 3, mult
            end
            return chips, mult
        end
    },
    {
        id = "speed_cleats",
        name = "Speed Cleats",
        type = "Equipment",
        cost = 4,
        description = "Speed Badge: +0.3x MTM on Outside Run & Deep Pass plays.",
        evaluate = function(gameState, playCard, chips, mult)
            if playCard and (playCard.type == "Run" or playCard.type == "Deep Pass") then
                return chips, mult + 0.3
            end
            return chips, mult
        end
    },
    {
        id = "pancake_block",
        name = "Pancake Block",
        type = "Equipment",
        cost = 5,
        description = "OL/TE Badge: Play Action plays ignore Defensive Blitz debuffs.",
        evaluate = function(gameState, playCard, chips, mult)
            if playCard and playCard.type == "Play Action" then
                return chips + 2, mult + 0.2
            end
            return chips, mult
        end
    },
    {
        id = "captains_badge",
        name = "Captain's C",
        type = "Equipment",
        cost = 5,
        description = "Locker Room Badge: Grants adjacent roster cards +2 Base Yards.",
        evaluate = function(gameState, playCard, chips, mult)
            return chips + 2, mult
        end
    }
}
