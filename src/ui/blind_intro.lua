-- src/ui/blind_intro.lua
-- Opponent Trash Talk intro overlay — shown at game start for 2-3s
-- Each blind has a unique personality taunt + counter hint
local SoundManager = require("src.engine.sound_manager")

local BlindIntro = {}

BlindIntro.active = false
BlindIntro.timer  = 0
BlindIntro.DURATION = 3.0
BlindIntro.blind  = nil
BlindIntro.alpha  = 0
BlindIntro.slideX = -500

-- Trash talk lines per blind id
local TAUNTS = {
    -- Standard
    cover_3         = { "You think you can air it out against us?", "Your receivers are COVERED. Deal with it." },
    blitz_heavy     = { "We're bringing everybody. EVERYBODY.", "Good luck getting that play action off, coach." },
    stuffed_box     = { "The run game? Dead on arrival.", "Your RB better have wheels. He's gonna need 'em." },
    cover_2_shell   = { "Tampa 2. Perfect. Clean. Unbreakable.", "Throw short, throw often — you'll still lose." },
    weather_rain    = { "Beautiful day for football. If you like fumbles.", "Rain makes everything slippery. Especially your chances." },
    prevent         = { "Sit back. Relax. We've got all day.", "Good things come to those who wait. We're waiting." },
    nickel_zone     = { "Five in coverage. Good luck finding a gap.", "Your slot receiver is going to have a long day." },
    press_man       = { "Face to face. No help over the top.", "Let's see how good your receivers really are." },
    cover_4_quarters= { "Four deep. You'd need a missile to beat us.", "Short gains are all you're getting today." },
    zone_blitz      = { "Is it a blitz? Is it coverage? You'll never know.", "Confusion is our best defender." },
    dime_package    = { "Six DBs. One quarterback. Do the math.", "We came to pick you off, coach." },
    bear_front      = { "The line is loaded. The box is stuffed.", "You're going to need more than a run play today." },
    -- Boss
    legion_of_boom  = { "Beast Mode can't save you here.", "We've ended careers. Yours is next." },
    goal_line_stand = { "The Curtain descends.", "Not one yard. Not one." },
    no_fly_zone     = { "The sky is closed today, friend.", "Denver doesn't allow deep balls. Not now. Not ever." },
    ironclad_front  = { "The '85 Bears don't lose.", "Sweetness couldn't run on us. You can't either." },
    purple_people_eaters = { "Purple reigns. You're about to kneel.", "Your QB is getting introduced to the ground." },
    fearsome_foursome    = { "Four defensive ends. One quarterback. Simple math.", "LA doesn't mess around, coach." },
    _default        = { "Get ready to take an L.", "This isn't your game. It's ours." }
}

local function getRandomTaunt(blindId)
    local lines = TAUNTS[blindId] or TAUNTS._default
    return lines[math.random(#lines)]
end

function BlindIntro.trigger(blind)
    if not blind then return end
    BlindIntro.active  = true
    BlindIntro.timer   = 0
    BlindIntro.blind   = blind
    BlindIntro.alpha   = 0
    BlindIntro.slideX  = -500
    BlindIntro.taunt   = getRandomTaunt(blind.id)
    SoundManager.playSFX("whistle")
end

function BlindIntro.update(dt)
    if not BlindIntro.active then return end
    BlindIntro.timer = BlindIntro.timer + dt

    -- Fade + slide in
    if BlindIntro.timer < 0.4 then
        local p = BlindIntro.timer / 0.4
        BlindIntro.alpha  = p
        BlindIntro.slideX = -500 + 500 * p * p * (3 - 2 * p) -- smooth step
    elseif BlindIntro.timer < BlindIntro.DURATION - 0.5 then
        BlindIntro.alpha  = 1.0
        BlindIntro.slideX = 0
    else
        local p = (BlindIntro.timer - (BlindIntro.DURATION - 0.5)) / 0.5
        BlindIntro.alpha  = math.max(0, 1 - p)
    end

    if BlindIntro.timer >= BlindIntro.DURATION then
        BlindIntro.active = false
    end
end

function BlindIntro.draw()
    if not BlindIntro.active then return end
    local b = BlindIntro.blind
    if not b then return end

    local a  = BlindIntro.alpha
    local sx = BlindIntro.slideX
    local px, py, pw, ph = 30 + sx, 12, 560, 100

    -- Panel bg
    love.graphics.setColor(0.08, 0.1, 0.15, 0.96 * a)
    love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)

    -- Coloured left stripe (red for boss, slate for standard)
    local stripeColor = (b.type == "boss") and {1.0, 0.2, 0.2} or {0.0, 0.76, 1.0}
    love.graphics.setColor(stripeColor[1], stripeColor[2], stripeColor[3], a)
    love.graphics.rectangle("fill", px, py, 6, ph, 8, 8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 8, 8)
    love.graphics.setLineWidth(1)

    -- Tier tag
    local tierLabel = (b.type == "boss") and "🔥 BOSS DEFENSE" or "⚡ PRO DEFENSE"
    love.graphics.setColor(stripeColor[1], stripeColor[2], stripeColor[3], a)
    love.graphics.print(tierLabel, px + 16, py + 8, 0, 0.8, 0.8)

    -- Defense name
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.print(b.name:upper(), px + 16, py + 24, 0, 1.3, 1.3)

    -- Trash talk quote
    love.graphics.setColor(0.85, 0.85, 0.85, a * 0.9)
    love.graphics.printf('"' .. BlindIntro.taunt .. '"', px + 16, py + 56, pw - 24, "left", 0, 0.9, 0.9)

    -- Counter-Strategy Hint Footer
    love.graphics.setColor(0.1, 0.15, 0.22, a)
    love.graphics.rectangle("fill", px + 6, py + ph - 24, pw - 12, 20, 4, 4)
    love.graphics.setColor(1.0, 0.84, 0.0, a * 0.9)
    love.graphics.print("COACH'S TIP: ", px + 12, py + ph - 21, 0, 0.75, 0.75)
    
    local hintStr = "Build high momentum chains and exploit synergies."
    if b.id == "cover_3" then hintStr = "Focus on Run plays and Short Passes."
    elseif b.id == "cover_2_shell" then hintStr = "Exploit the deep middle with Long Passes."
    elseif b.id == "blitz_heavy" then hintStr = "Use Play Action and Screen passes to bypass the rush."
    elseif b.id == "stuffed_box" then hintStr = "Air it out. The run game is dead here."
    elseif b.id == "weather_rain" then hintStr = "Rely on safe, short yardage plays."
    elseif b.id == "press_man" then hintStr = "Use Run plays. Passing base yards are nerfed."
    elseif b.id == "nickel_zone" then hintStr = "Avoid short passes. Lean on the run game."
    elseif b.id == "cover_4_quarters" then hintStr = "Deep passes are capped. Dink and dunk your way down."
    elseif b.id == "zone_blitz" then hintStr = "RNG penalty applies to all plays. Use safe, high-yardage options."
    elseif b.id == "dime_package" then hintStr = "Run plays get +3 base yards. Exploit the light box."
    elseif b.id == "bear_front" then hintStr = "Run plays are severely punished. Pass the ball."
    elseif b.id == "soft_zone" then hintStr = "Deep passes lose momentum. Run or throw short."
    elseif b.id == "spy_coverage" then hintStr = "Play Action loses yards. Standard passing is safe."
    elseif b.id == "cover_0_blitz" then hintStr = "20% sack chance on passes! Run the ball to be safe."
    elseif b.id == "goal_line_defense" or b.id == "goal_line_stand" then hintStr = "All plays capped at low yards. You need high Momentum multipliers."
    elseif b.id == "doomsday_defense" then hintStr = "Brutal -30% yard penalty on everything. Maximize synergies."
    elseif b.id == "undefeated_72" then hintStr = "Short Pass and Run are capped. You MUST throw deep."
    elseif b.id == "fearsome_foursome" then hintStr = "Play Action and Short Pass are capped. Run or throw deep."
    end
    
    love.graphics.setColor(0.9, 0.9, 0.9, a * 0.9)
    love.graphics.print(hintStr, px + 85, py + ph - 21, 0, 0.75, 0.75)

    love.graphics.setColor(1, 1, 1, 1)
end

return BlindIntro
