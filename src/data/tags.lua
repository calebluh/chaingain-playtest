-- src/data/tags.lua

return {
    {
        id = "tag_economy",
        name = "Economy Bonus",
        description = "Instantly gain +$15 Cap Space.",
        apply = function(gameState)
            gameState.capCash = (gameState.capCash or 0) + 15
        end
    },
    {
        id = "tag_arcana",
        name = "Adjustments Perk",
        description = "Gain 2 random Sideline Adjustments.",
        apply = function(gameState)
            local ConsumablesData = require("src.data.consumables")
            for i=1, 2 do
                if #gameState.consumables < gameState.maxConsumables then
                    local c = ConsumablesData[math.random(#ConsumablesData)]
                    gameState.addConsumable(c)
                end
            end
        end
    },
    {
        id = "tag_voucher",
        name = "Staff Upgrade Asset",
        description = "Next Staff Upgrade in the shop is FREE.",
        apply = function(gameState)
            gameState.freeVoucher = true
        end
    },
    {
        id = "tag_scout",
        name = "Mega Scouting Perk",
        description = "Immediately open a free Mega Scout Pack.",
        apply = function(gameState)
            local StateManager = require("src.states.state_manager")
            local StatePackOpening = require("src.states.state_pack_opening")
            StatePackOpening.packType = "MEGA"
            StateManager.switch(StatePackOpening)
            return true -- Return true to indicate we are switching states immediately
        end
    }
}
