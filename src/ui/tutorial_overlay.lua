-- src/ui/tutorial_overlay.lua
local AssetManager = require("src.engine.asset_manager")
local SoundManager = require("src.engine.sound_manager")
local SaveManager = require("src.engine.save_manager")

local TutorialOverlay = {}

TutorialOverlay.active = false
TutorialOverlay.step = 1
TutorialOverlay.charIndex = 0
TutorialOverlay.typeTimer = 0

TutorialOverlay.dialogue = {
    { title = "HEAD COACH MADDEN", text = "WELCOME TO THE SIDELINE, COACH! Let's go over game plan basics before your first drive." },
    { title = "CALLING PLAYS", text = "Select a Play Card from your hand. Run Plays offer safe yards, while Pass Plays build huge Momentum multipliers!" },
    { title = "ROSTER SYNERGIES", text = "Your active Roster Players trigger automatically! QBs, WRs, and RBs add bonus Yards & Momentum on their plays." },
    { title = "THE TARGET SCORE", text = "Gain yards and score Touchdowns to hit the Target Score before you run out of Drives!" },
    { title = "FRONT OFFICE SHOP", text = "Between games, visit the Shop to buy Booster Packs, train your Roster Players, and upgrade your Playbook." },
    { title = "GAME TIME!", text = "You're ready, Coach! Press [SPACE] or click anywhere to begin your run. Good luck!" }
}

function TutorialOverlay.start()
    TutorialOverlay.active = true
    TutorialOverlay.step = 1
    TutorialOverlay.charIndex = 0
    TutorialOverlay.typeTimer = 0
end

function TutorialOverlay.nextStep()
    SoundManager.playSFX("click")
    if TutorialOverlay.step < #TutorialOverlay.dialogue then
        TutorialOverlay.step = TutorialOverlay.step + 1
        TutorialOverlay.charIndex = 0
        TutorialOverlay.typeTimer = 0
    else
        TutorialOverlay.active = false
        SaveManager.data.hasCompletedTutorial = true
        SaveManager.save()
    end
end

function TutorialOverlay.update(dt)
    if not TutorialOverlay.active then return end
    
    local current = TutorialOverlay.dialogue[TutorialOverlay.step]
    if current and TutorialOverlay.charIndex < #current.text then
        TutorialOverlay.typeTimer = TutorialOverlay.typeTimer + dt
        if TutorialOverlay.typeTimer >= 0.025 then
            TutorialOverlay.typeTimer = 0
            TutorialOverlay.charIndex = TutorialOverlay.charIndex + 1
            if TutorialOverlay.charIndex % 3 == 0 then
                SoundManager.playSFX("click")
            end
        end
    end
end

function TutorialOverlay.draw()
    if not TutorialOverlay.active then return end
    
    local current = TutorialOverlay.dialogue[TutorialOverlay.step]
    if not current then return end
    
    -- Backdrop Dim
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    -- Coach Box Container
    local bx, by, bw, bh = 80, 360, 800, 150
    love.graphics.setColor(0.1, 0.14, 0.2, 0.96)
    love.graphics.rectangle("fill", bx, by, bw, bh, 10, 10)
    love.graphics.setColor(1.0, 0.84, 0.0, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", bx, by, bw, bh, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- Coach Portrait Box (Left)
    love.graphics.setColor(0.18, 0.25, 0.35, 1)
    love.graphics.rectangle("fill", bx + 15, by + 15, 120, 120, 6, 6)
    love.graphics.setColor(0.0, 0.76, 1.0, 0.8)
    love.graphics.rectangle("line", bx + 15, by + 15, 120, 120, 6, 6)
    
    -- Coach Retro Sprite Avatar
    AssetManager.drawRetroPlayer(bx + 75, by + 110, {0.9, 0.2, 0.2}, {0.9, 0.9, 0.9}, {0.1, 0.1, 0.1}, 0, 0, true, 0, false, false, 4)
    
    -- Dialogue Header Title
    love.graphics.setColor(1.0, 0.84, 0.0, 1)
    love.graphics.print(current.title, bx + 150, by + 18, 0, 1.2, 1.2)
    
    -- Dialogue Typewriter Text
    local dispText = current.text:sub(1, TutorialOverlay.charIndex)
    love.graphics.setColor(0.95, 0.95, 0.95, 1)
    love.graphics.printf(dispText, bx + 150, by + 45, bw - 170, "left", 0, 1.0, 1.0)
    
    -- Footer Click Prompt
    local isDone = (TutorialOverlay.charIndex >= #current.text)
    local promptText = isDone and "[CLICK OR PRESS SPACE TO CONTINUE >]" or "[TYPING...]"
    love.graphics.setColor(isDone and {0.0, 0.76, 1.0} or {0.6, 0.6, 0.6})
    love.graphics.printf(promptText, bx + 150, by + 118, bw - 170, "right", 0, 0.85, 0.85)
end

function TutorialOverlay.keypressed(key)
    if not TutorialOverlay.active then return end
    if key == "space" or key == "return" or key == "enter" then
        TutorialOverlay.nextStep()
    end
end

function TutorialOverlay.mousepressed(x, y, button)
    if not TutorialOverlay.active then return end
    if button == 1 then
        TutorialOverlay.nextStep()
    end
end

return TutorialOverlay
