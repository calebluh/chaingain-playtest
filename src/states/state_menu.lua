-- src/states/state_menu.lua
local StateManager = require("src.states.state_manager")
local SoundManager = require("src.engine.sound_manager")
local SaveManager = require("src.engine.save_manager")
local GameStateData = require("src.engine.game_state")
local DeckManager = require("src.engine.deck_manager")
local Loc = require("src.engine.loc_manager")

local StateMenu = {}

local C_SLATE_CONTAINER = {0.129, 0.149, 0.192} -- #212631
local C_NEON_BORDER = {0.0, 0.76, 1.0} -- #00C3FF
local C_BLUE = {0.0, 0.58, 1.0} -- #0094FF
local C_AMBER = {1.0, 0.6, 0.0} -- #FF9900
local C_RED = {1.0, 0.3, 0.3} -- #FF4D4D
local C_GREEN = {0.18, 0.72, 0.45} -- #2EB872
local C_CYAN = {0.0, 0.76, 1.0} -- #00C3FF
local C_GOLD = {1.0, 0.84, 0.0}

local function checkHover(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end

local function drawShadowText(text, x, y, r, g, b, scale, align, limit)
    scale = scale or 1
    love.graphics.setColor(0, 0, 0, 0.95)
    if align and limit then
        love.graphics.printf(text, x + 1, y + 1, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x + 1, y + 1, 0, scale, scale)
    end
    
    love.graphics.setColor(r or 1, g or 1, b or 1, 1)
    if align and limit then
        love.graphics.printf(text, x, y, limit / scale, align, 0, scale, scale)
    else
        love.graphics.print(text, x, y, 0, scale, scale)
    end
end

local function drawChunkyPillButton(btn)
    local hover = checkHover(btn.x, btn.y, btn.w, btn.h)
    
    if hover and not btn.wasHovered then
        SoundManager.playSFX("click", 1.1)
    end
    btn.wasHovered = hover
    
    local drawX, drawY, drawW, drawH = btn.x, btn.y, btn.w, btn.h
    local txtScale = 1.1
    
    if hover then
        drawX = drawX - math.floor(btn.w * 0.025)
        drawY = drawY - math.floor(btn.h * 0.025)
        drawW = math.floor(drawW * 1.05)
        drawH = math.floor(drawH * 1.05)
        txtScale = 1.15
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
    end
    
    love.graphics.setColor(0.06, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", drawX, drawY + 4, drawW, drawH, 8, 8)
    
    love.graphics.setColor(btn.color)
    love.graphics.rectangle("fill", drawX, drawY, drawW, drawH, 8, 8)
    
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("fill", drawX, drawY, drawW, drawH * 0.4, 8, 8)
    
    drawShadowText(btn.name, drawX, drawY + (drawH/2) - 10, 1, 1, 1, txtScale, "center", drawW)
end

function StateMenu:enter()
    self.time = 0
    self.activeModal = nil
    self.hasSaveRun = SaveManager.hasActiveRun()
    self.modalBackBtn = {id="MODAL_BACK", name="BACK", color=C_RED, x=420, y=430, w=120, h=38, wasHovered = false}
    
    self:rebuildButtons()
    SoundManager.playMusic("menu_theme")
end

function StateMenu:rebuildButtons()
    self.buttons = {}
    if self.hasSaveRun then
        table.insert(self.buttons, { id = "CONTINUE", name = "CONTINUE SEASON", color = C_GOLD, x = 30, y = 440, w = 150, h = 50, wasHovered = false })
        table.insert(self.buttons, { id = "PLAY", name = Loc.get("PLAY_NOW"), color = C_BLUE, x = 190, y = 440, w = 150, h = 50, wasHovered = false })
        table.insert(self.buttons, { id = "CAREER", name = Loc.get("MYPLAYER"), color = C_BLUE, x = 350, y = 440, w = 140, h = 50, wasHovered = false })
        table.insert(self.buttons, { id = "PROFILE", name = "PROFILE " .. SaveManager.activeProfileIndex, color = C_AMBER, x = 500, y = 440, w = 130, h = 50, wasHovered = false })
        table.insert(self.buttons, { id = "COLLECTION", name = Loc.get("COLLECTION"), color = C_GREEN, x = 640, y = 440, w = 140, h = 50, wasHovered = false })
        table.insert(self.buttons, { id = "OPTIONS", name = Loc.get("OPTIONS"), color = C_CYAN, x = 790, y = 440, w = 130, h = 50, wasHovered = false })
    else
        table.insert(self.buttons, { id = "PLAY", name = Loc.get("PLAY_NOW"), color = C_BLUE, x = 40, y = 440, w = 170, h = 50, wasHovered = false })
        table.insert(self.buttons, { id = "CAREER", name = Loc.get("MYPLAYER"), color = C_BLUE, x = 220, y = 440, w = 170, h = 50, wasHovered = false })
        table.insert(self.buttons, { id = "PROFILE", name = "PROFILE " .. SaveManager.activeProfileIndex, color = C_AMBER, x = 400, y = 440, w = 150, h = 50, wasHovered = false })
        table.insert(self.buttons, { id = "COLLECTION", name = Loc.get("COLLECTION"), color = C_GREEN, x = 560, y = 440, w = 160, h = 50, wasHovered = false })
        table.insert(self.buttons, { id = "OPTIONS", name = Loc.get("OPTIONS"), color = C_CYAN, x = 730, y = 440, w = 150, h = 50, wasHovered = false })
    end
end

function StateMenu:exit()
end

function StateMenu:update(dt)
    self.time = self.time + dt
end

function StateMenu:draw()
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    
    local glowPulse = (math.sin(self.time * 2.0) + 1) * 0.05 + 0.12
    love.graphics.setColor(0.0, 0.58, 1.0, glowPulse)
    love.graphics.circle("fill", 150, 100, 180)
    love.graphics.setColor(1.0, 0.84, 0.0, glowPulse * 0.8)
    love.graphics.circle("fill", 810, 100, 180)
    
    love.graphics.push()
    love.graphics.translate(480, 270)
    love.graphics.rotate(math.sin(self.time * 0.15) * 0.03)
    love.graphics.translate(-480, -270)
    
    love.graphics.setColor(0.12, 0.18, 0.25, 0.3)
    for i=0, 20 do
        local yPos = (i * 40 + self.time * 15) % 600
        love.graphics.line(0, yPos, 960, yPos)
    end
    love.graphics.pop()
    
    -- Rebranded Commercial Title
    drawShadowText("AUDIBLE", 480 - 150, 75, 1, 1, 1, 4.4, "center", 300)
    drawShadowText("GRIDIRON TACTICS", 480 - 200, 145, 0.0, 0.76, 1.0, 2.4, "center", 400)
    
    local hs = SaveManager.data.highScoreYards or 0
    local td = SaveManager.data.totalTouchdowns or 0
    drawShadowText(string.format("ACTIVE PROFILE: %s | HIGH SCORE: %d YDS | TDS: %d", SaveManager.data.profileName or "Profile 1", hs, td), 480 - 300, 215, 0.8, 0.8, 0.8, 1.1, "center", 600)
    
    for _, btn in ipairs(self.buttons) do
        drawChunkyPillButton(btn)
    end
    

end

function StateMenu:mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        SoundManager.playSFX("click")

        
        for _, btn in ipairs(self.buttons) do
            if checkHover(btn.x, btn.y, btn.w, btn.h) then
                if btn.id == "PROFILE" then
                    local nextIdx = (SaveManager.activeProfileIndex % 5) + 1
                    SaveManager.switchProfile(nextIdx)
                    self.hasSaveRun = SaveManager.hasActiveRun()
                    self:rebuildButtons()
                elseif btn.id == "CONTINUE" then
                    local ok = SaveManager.loadActiveRunIntoState(GameStateData)
                    if ok then
                        if GameStateData.inShop then
                            local StateShop = require("src.states.state_shop")
                            StateManager.switch(StateShop)
                        else
                            DeckManager.drawHand()
                            local StateGame = require("src.states.state_game")
                            StateManager.switch(StateGame)
                        end
                    end
                elseif btn.id == "OPTIONS" then
                    local StateSettings = require("src.states.state_settings")
                    StateManager.switch(StateSettings)
                elseif btn.id == "SKILLS" then
                    local StateMyPlayerTree = require("src.states.state_myplayer_tree")
                    StateManager.switch(StateMyPlayerTree)
                elseif btn.id == "COLLECTION" then
                    local StateCollections = require("src.states.state_collections")
                    StateManager.switch(StateCollections)
                elseif btn.id == "PLAY" then
                    local StateModeSelect = require("src.states.state_mode_select")
                    StateManager.switch(StateModeSelect)
                elseif btn.id == "CAREER" then
                    local StateMyPlayer = require("src.states.state_myplayer")
                    StateManager.switch(StateMyPlayer)
                end
            end
        end
    end
end

function StateMenu:keypressed(key)
    if self.activeModal and key == "escape" then
        self.activeModal = nil
    end
end

return StateMenu
