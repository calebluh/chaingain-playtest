-- src/data/consumables.lua

return {
    {
        id = "bribe_ref",
        name = "Bribe Referee",
        type = "Consumable",
        cost = 4,
        description = "Instantly grants +2 Extra Downs for the current drive.",
        use = function(gameState)
            gameState.down = math.max(1, gameState.down - 2)
            return "Referee calls a penalty fallback! +2 Downs granted!"
        end
    },
    {
        id = "no_huddle",
        name = "No-Huddle Offense",
        type = "Consumable",
        cost = 3,
        description = "Instantly redraws a fresh hand of 5 Play Cards without using a down.",
        use = function(gameState)
            local DeckManager = require("src.engine.deck_manager")
            DeckManager.drawHand()
            return "No-Huddle called! Redrew a fresh hand of plays."
        end
    },
    {
        id = "sticky_gloves",
        name = "Sticky Gloves",
        type = "Consumable",
        cost = 4,
        description = "Permanently adds +2 Base Yards to all Short Pass & Medium Pass plays.",
        use = function(gameState)
            local DeckManager = require("src.engine.deck_manager")
            DeckManager.upgradePlayType("Short Pass", 2, 0.2)
            DeckManager.upgradePlayType("Medium Pass", 2, 0.2)
            return "Receivers equipped with Sticky Gloves! (+2 YDS on Pass plays)"
        end
    },
    {
        id = "audible_overdrive",
        name = "Audible Overdrive",
        type = "Consumable",
        cost = 3,
        description = "Instantly adds +3 Audibles for the current drive.",
        use = function(gameState)
            gameState.audiblesRemaining = gameState.audiblesRemaining + 3
            return "Coaching staff dialed in! +3 Audibles added."
        end
    },
    {
        id = "red_zone_special",
        name = "Red Zone Special",
        type = "Consumable",
        cost = 5,
        description = "Grants +2.5 Drive Momentum on the next play.",
        use = function(gameState)
            gameState.tempMultBoost = (gameState.tempMultBoost or 0) + 2.5
            return "Red Zone Special activated! +2.5 MTM on next play."
        end
    },
    {
        id = "enhancement_glass",
        name = "High-Octane Spikes",
        type = "Consumable",
        cost = 4,
        description = "Enhances 1 random Play Card in hand to High-Octane (x2.0 MTM, 25% chance to bench card after play).",
        use = function(gameState)
            local DeckManager = require("src.engine.deck_manager")
            if #DeckManager.hand > 0 then
                local card = DeckManager.hand[math.random(#DeckManager.hand)]
                card.enhancement = "Glass"
                return card.type .. " enhanced to High-Octane!"
            end
            return "No cards in hand to enhance!"
        end
    },
    {
        id = "enhancement_steel",
        name = "Reinforced Pads",
        type = "Consumable",
        cost = 4,
        description = "Enhances 1 random Play Card in hand to Reinforced (+1.5 MTM passively while held).",
        use = function(gameState)
            local DeckManager = require("src.engine.deck_manager")
            if #DeckManager.hand > 0 then
                local card = DeckManager.hand[math.random(#DeckManager.hand)]
                card.enhancement = "Steel"
                return card.type .. " enhanced to Reinforced!"
            end
            return "No cards in hand to enhance!"
        end
    },
    {
        id = "enhancement_gold",
        name = "Sponsor Decal",
        type = "Consumable",
        cost = 4,
        description = "Enhances 1 random Play Card in hand to Franchise Gold (+$3 Cash if held at end of drive).",
        use = function(gameState)
            local DeckManager = require("src.engine.deck_manager")
            if #DeckManager.hand > 0 then
                local card = DeckManager.hand[math.random(#DeckManager.hand)]
                card.enhancement = "Gold"
                return card.type .. " enhanced to Franchise Gold!"
            end
            return "No cards in hand to enhance!"
        end
    },
    {
        id = "enhancement_stone",
        name = "Chunky Studs",
        type = "Consumable",
        cost = 4,
        description = "Enhances 1 random Play Card in hand to Heavy Stud (+8 Base YDS, but 0 MTM).",
        use = function(gameState)
            local DeckManager = require("src.engine.deck_manager")
            if #DeckManager.hand > 0 then
                local card = DeckManager.hand[math.random(#DeckManager.hand)]
                card.enhancement = "Stone"
                return card.type .. " enhanced to Heavy Stud!"
            end
            return "No cards in hand to enhance!"
        end
    },
    {
        id = "seal_red",
        name = "Red Helmet Decal",
        type = "Consumable",
        cost = 5,
        description = "Adds a RED DECAL to 1 random Play Card in hand (Card Retriggers 1 extra time).",
        use = function(gameState)
            local DeckManager = require("src.engine.deck_manager")
            if #DeckManager.hand > 0 then
                local card = DeckManager.hand[math.random(#DeckManager.hand)]
                card.seal = "Red"
                return card.type .. " gained a RED HELMET DECAL!"
            end
            return "No cards in hand to decal!"
        end
    },
    {
        id = "seal_gold",
        name = "Gold Helmet Decal",
        type = "Consumable",
        cost = 5,
        description = "Adds a GOLD DECAL to 1 random Play Card in hand (Earn +$3 when played).",
        use = function(gameState)
            local DeckManager = require("src.engine.deck_manager")
            if #DeckManager.hand > 0 then
                local card = DeckManager.hand[math.random(#DeckManager.hand)]
                card.seal = "Gold"
                return card.type .. " gained a GOLD HELMET DECAL!"
            end
            return "No cards in hand to decal!"
        end
    },
    {
        id = "seal_blue",
        name = "Blue Helmet Decal",
        type = "Consumable",
        cost = 5,
        description = "Adds a BLUE DECAL to 1 random Play Card (Generates Adjustments if held at end of drive).",
        use = function(gameState)
            local DeckManager = require("src.engine.deck_manager")
            if #DeckManager.hand > 0 then
                local card = DeckManager.hand[math.random(#DeckManager.hand)]
                card.seal = "Blue"
                return card.type .. " gained a BLUE HELMET DECAL!"
            end
            return "No cards in hand to decal!"
        end
    },
    -- ── 5 NEW CONSUMABLES (v2.0 Update) ──────────────────────────────
    {
        id = "coaches_challenge",
        name = "Coach's Challenge",
        type = "Consumable",
        cost = 5,
        description = "Completely negates all Turnover Risk on the very next play you call.",
        use = function(gameState)
            gameState.turnoverImmunityNextPlay = true
            return "Challenge thrown! No turnovers on your next play!"
        end
    },
    {
        id = "trick_play",
        name = "Trick Play",
        type = "Consumable",
        cost = 4,
        description = "Next play card gains +12 Base Yards and +1.5 MTM, then it's burned from the playbook.",
        use = function(gameState)
            gameState.trickPlayNextCard = true
            return "Trick Play dialed in! Next call gets +12 YDS & +1.5 MTM!"
        end
    },
    {
        id = "two_minute_drill",
        name = "Two-Minute Drill",
        type = "Consumable",
        cost = 3,
        description = "Instantly resets the Play Clock to its maximum value for this drive.",
        use = function(gameState)
            gameState.playClock = gameState.maxPlayClock
            return "Two-Minute Drill! Play clock reset to " .. math.floor(gameState.maxPlayClock) .. " seconds!"
        end
    },
    {
        id = "momentum_shift",
        name = "Momentum Shift",
        type = "Consumable",
        cost = 4,
        description = "Convert 30 Stadium Pulse energy into +3.0 temporary Drive Momentum.",
        use = function(gameState)
            local StadiumPulse = require("src.engine.stadium_pulse")
            if StadiumPulse.pulse >= 30 then
                StadiumPulse.pulse = StadiumPulse.pulse - 30
                gameState.tempMultBoost = (gameState.tempMultBoost or 0) + 3.0
                return "MOMENTUM SHIFT! -30 Pulse → +3.0 MTM on next play!"
            else
                return "Not enough crowd energy! Need 30+ Pulse."
            end
        end
    },
    {
        id = "film_study",
        name = "Film Study",
        type = "Consumable",
        cost = 3,
        description = "Reveals which play type scores bonus yards against the current Defense.",
        use = function(gameState)
            local DefenseManager = require("src.engine.defense_manager")
            local FxManager = require("src.engine.fx_manager")
            if DefenseManager.currentPlay then
                local counter = DefenseManager.currentPlay.counter or "Run"
                FxManager.addFloatingText("FILM STUDY: " .. counter:upper() .. " IS THE COUNTER PLAY!", 480, 200, 0.2, 0.8, 1, 1.4)
                return "Film Study complete! " .. counter .. " beats their coverage!"
            end
            return "Nothing to study yet!"
        end
    }
}
