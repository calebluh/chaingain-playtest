-- src/ui/commentary_ticker.lua
local CommentaryTicker = {}

CommentaryTicker.messages = {
    "WELCOME TO CHAIN GAIN FOOTBALL • ALL EYES ON THE GRIDIRON TODAY!",
    "MARCUS VANCE SHOWING INCREDIBLE ACCURACY IN THE SHORT PASSING GAME!",
    "DEFENSIVE BLITZ PRESSURE IS HEATING UP ACROSS ALL-PRO STAKES!",
    "MADDEN RATINGS UNLOCKED: CHECK OUT YOUR ROSTER PLAYERS IN THE SHOP!"
}
CommentaryTicker.currentText = CommentaryTicker.messages[1]
CommentaryTicker.scrollX = 960

function CommentaryTicker.setPlayCallout(callerName, playType, yardsGained)
    if yardsGained >= 40 then
        CommentaryTicker.currentText = string.format("🚨 UNBELIEVABLE BREAKAWAY! %s CRUSHES A %d-YARD %s GAIN!", callerName:upper(), yardsGained, playType:upper())
    elseif yardsGained >= 20 then
        CommentaryTicker.currentText = string.format("⚡ HUGE PLAY! %s SCAMPIES FOR %d YARDS ON THE %s!", callerName:upper(), yardsGained, playType:upper())
    elseif yardsGained < 0 then
        CommentaryTicker.currentText = string.format("💥 DEFENSE STUFFS THE PLAY! %s LOSS OF %d YARDS!", playType:upper(), math.abs(yardsGained))
    else
        CommentaryTicker.currentText = string.format("🏈 %s GAINS %d YARDS ON THE %s!", callerName:upper(), yardsGained, playType:upper())
    end
    CommentaryTicker.scrollX = 960
end

function CommentaryTicker.update(dt)
    CommentaryTicker.scrollX = CommentaryTicker.scrollX - 90 * dt
    if CommentaryTicker.scrollX < -800 then
        CommentaryTicker.scrollX = 960
        local idx = math.random(#CommentaryTicker.messages)
        CommentaryTicker.currentText = CommentaryTicker.messages[idx]
    end
end

function CommentaryTicker.draw()
    -- Bottom Commentary Ticker Bar
    love.graphics.setColor(0.06, 0.08, 0.12, 0.9)
    love.graphics.rectangle("fill", 0, 520, 960, 20)
    love.graphics.setColor(1.0, 0.84, 0.0, 0.9)
    love.graphics.rectangle("fill", 0, 520, 60, 20)
    
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("TICKER", 6, 523, 0, 0.8, 0.8)
    
    love.graphics.setColor(0.0, 0.76, 1.0, 1)
    love.graphics.print(CommentaryTicker.currentText, CommentaryTicker.scrollX, 523, 0, 0.85, 0.85)
end

return CommentaryTicker
