-- src/engine/deck_manager.lua
local PlayCard = require("src.entities.play_card")

local DeckManager = {}

DeckManager.playbook = {}
DeckManager.drawPile = {}
DeckManager.discardPile = {}
DeckManager.hand = {}
DeckManager.handSize = 5

function DeckManager.init()
    DeckManager.playbook = {}
    DeckManager.drawPile = {}
    DeckManager.discardPile = {}
    DeckManager.hand = {}
    DeckManager.handSize = 5
    
    DeckManager.buildDefaultPlaybook()
    DeckManager.shuffle()
end

function DeckManager.buildDefaultPlaybook()
    local defaultPlays = {
        {name="HB Dive", type="Run", chips=3, mult=1.2},
        {name="HB Stretch", type="Run", chips=4, mult=1.3},
        {name="Inside Zone", type="Run", chips=4, mult=1.25},
        {name="Quick Slant", type="Short Pass", chips=6, mult=1.5},
        {name="Drag Route", type="Short Pass", chips=5, mult=1.4},
        {name="Mesh", type="Short Pass", chips=7, mult=1.35},
        {name="Dig Route", type="Medium Pass", chips=10, mult=1.7},
        {name="Out Route", type="Medium Pass", chips=9, mult=1.65},
        {name="Four Verticals", type="Deep Pass", chips=16, mult=2.2},
        {name="PA Crossers", type="Play Action", chips=12, mult=2.1},
    }
    
    -- Add 2 of each to get to 20
    for _, play in ipairs(defaultPlays) do
        table.insert(DeckManager.playbook, PlayCard.new(play.name, play.type, play.chips, play.mult))
        table.insert(DeckManager.playbook, PlayCard.new(play.name, play.type, play.chips, play.mult))
    end
end

function DeckManager.shuffle()
    DeckManager.drawPile = {}
    for _, card in ipairs(DeckManager.playbook or {}) do
        table.insert(DeckManager.drawPile, card)
    end
    DeckManager.discardPile = {}
    
    -- Fisher-Yates shuffle
    for i = #DeckManager.drawPile, 2, -1 do
        local j = math.random(i)
        DeckManager.drawPile[i], DeckManager.drawPile[j] = DeckManager.drawPile[j], DeckManager.drawPile[i]
    end
end

function DeckManager.drawHand()
    if not DeckManager.playbook or #DeckManager.playbook == 0 then
        DeckManager.init()
    end
    
    DeckManager.hand = DeckManager.hand or {}
    DeckManager.discardPile = DeckManager.discardPile or {}
    DeckManager.drawPile = DeckManager.drawPile or {}
    
    -- discard remaining hand
    while #DeckManager.hand > 0 do
        table.insert(DeckManager.discardPile, table.remove(DeckManager.hand))
    end
    
    for i = 1, (DeckManager.handSize or 5) do
        if #DeckManager.drawPile == 0 then
            if #DeckManager.discardPile > 0 then
                for _, card in ipairs(DeckManager.discardPile) do
                    table.insert(DeckManager.drawPile, card)
                end
                DeckManager.discardPile = {}
                for i2 = #DeckManager.drawPile, 2, -1 do
                    local j = math.random(i2)
                    DeckManager.drawPile[i2], DeckManager.drawPile[j] = DeckManager.drawPile[j], DeckManager.drawPile[i2]
                end
            else
                break
            end
        end
        local card = table.remove(DeckManager.drawPile)
        if card then
            card.selected = false
            table.insert(DeckManager.hand, card)
        end
    end
end

function DeckManager.discardSelected()
    DeckManager.hand = DeckManager.hand or {}
    DeckManager.discardPile = DeckManager.discardPile or {}
    DeckManager.drawPile = DeckManager.drawPile or {}
    
    local kept = {}
    local discardedCount = 0
    for _, card in ipairs(DeckManager.hand) do
        if card.selected then
            card.selected = false
            table.insert(DeckManager.discardPile, card)
            discardedCount = discardedCount + 1
        else
            table.insert(kept, card)
        end
    end
    
    DeckManager.hand = kept
    DeckManager.fillHand()
    return discardedCount
end

function DeckManager.discardPlay(playCard)
    DeckManager.hand = DeckManager.hand or {}
    DeckManager.discardPile = DeckManager.discardPile or {}
    
    local kept = {}
    for _, card in ipairs(DeckManager.hand) do
        if card == playCard then
            table.insert(DeckManager.discardPile, card)
        else
            table.insert(kept, card)
        end
    end
    DeckManager.hand = kept
end

function DeckManager.fillHand()
    if not DeckManager.playbook or #DeckManager.playbook == 0 then
        DeckManager.init()
    end
    
    DeckManager.hand = DeckManager.hand or {}
    DeckManager.discardPile = DeckManager.discardPile or {}
    DeckManager.drawPile = DeckManager.drawPile or {}
    
    while #DeckManager.hand < (DeckManager.handSize or 5) do
        if #DeckManager.drawPile == 0 then
            if #DeckManager.discardPile > 0 then
                for _, card in ipairs(DeckManager.discardPile) do
                    table.insert(DeckManager.drawPile, card)
                end
                DeckManager.discardPile = {}
                for i2 = #DeckManager.drawPile, 2, -1 do
                    local j = math.random(i2)
                    DeckManager.drawPile[i2], DeckManager.drawPile[j] = DeckManager.drawPile[j], DeckManager.drawPile[i2]
                end
            else
                break
            end
        end
        local card = table.remove(DeckManager.drawPile)
        if card then
            card.selected = false
            table.insert(DeckManager.hand, card)
        end
    end
end

function DeckManager.upgradePlayType(playType, chipIncrease, multIncrease)
    for _, card in ipairs(DeckManager.playbook or {}) do
        if card.type == playType then
            card:upgrade(chipIncrease, multIncrease)
        end
    end
end

function DeckManager.destroyCard(playCard)
    -- Remove from everywhere
    local function removeFromList(list)
        for i = #list, 1, -1 do
            if list[i] == playCard then
                table.remove(list, i)
            end
        end
    end
    removeFromList(DeckManager.playbook)
    removeFromList(DeckManager.drawPile)
    removeFromList(DeckManager.discardPile)
    removeFromList(DeckManager.hand)
end

return DeckManager
