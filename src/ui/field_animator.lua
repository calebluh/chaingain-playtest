-- src/ui/field_animator.lua
local PhysicsUtils = require("src.engine.physics_utils")
local GameStateData = require("src.engine.game_state")
local FieldAnimator = {}

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

local FIELD_WIDTH = 600
local FIELD_HEIGHT = 220
local FIELD_X = 480 - FIELD_WIDTH / 2
local FIELD_Y = 180

local C_BORDER = { 0.1, 0.1, 0.1 }
local C_TURF = { 94 / 255, 172 / 255, 68 / 255 }
local C_TURF_DARK = { 80 / 255, 149 / 255, 59 / 255 }
local C_LOS = { 0.1, 0.4, 0.8, 0.9 }
local C_FIRST = { 1.0, 0.85, 0.1, 0.9 }

FieldAnimator.active = false
FieldAnimator.completed = true
FieldAnimator.timer = 0
FieldAnimator.duration = 1.5
FieldAnimator.cadenceText = ""

FieldAnimator.playType = "Run"
FieldAnimator.yardsGained = 0
FieldAnimator.yardLine = 25
FieldAnimator.distanceToFirst = 1

FieldAnimator.ball = { x = 0, y = 0, targetX = 0, targetY = 0, scale = 1, z = 0, carrier = nil }
FieldAnimator.offense = {}
FieldAnimator.defense = {}
FieldAnimator.dustParticles = {}

FieldAnimator.skillCheckActive = false
FieldAnimator.skillCheckTimer = 0
FieldAnimator.skillCheckDuration = 0.8
FieldAnimator.skillCheckSuccess = nil
FieldAnimator.skillCheckTargetX = 0
FieldAnimator.skillCheckTargetY = 0
FieldAnimator.skillCheckType = ""
FieldAnimator.skillCheckTriggered = false

FieldAnimator.cameraX = 0
FieldAnimator.targetCameraX = 0

local YARD_PX = 10 -- pixels per yard

-- 2.5D Vertical "Madden" Perspective Projection Matrix
function FieldAnimator.to25D(worldX, worldY, worldZ)
    worldZ = worldZ or 0
    -- relX is yards downfield relative to the camera
    local relX = worldX - FieldAnimator.cameraX
    
    local screenCenterX = 480
    -- Line of scrimmage will be anchored near the bottom
    local screenBaseY = 400
    
    -- In the old system, worldY was 50 to 310 (center 180).
    local relY = worldY - 180
    
    -- Dist downfield. positive relX means moving towards opponent endzone (UP the screen)
    local distDownfield = relX
    
    -- Perspective: objects further downfield shrink, and horizontal spread narrows
    local perspectiveStr = math.clamp(1.0 - (distDownfield * 0.001), 0.35, 1.2)
    
    -- Screen X is the sideline position.
    -- Multiply by 2.5 to spread the 260 width (50 to 310) across the 960 screen
    local screenX = screenCenterX + (relY * 2.5) * perspectiveStr
    
    -- Screen Y goes UP as you go downfield.
    local screenY = screenBaseY - (distDownfield * 1.5) * perspectiveStr - worldZ * 1.1
    
    local scaleFactor = math.clamp(1.0 - (distDownfield * 0.0015), 0.45, 1.3)
    
    return screenX, screenY, scaleFactor
end

function FieldAnimator.startPlay(playType, yardsGained, yardLine, distanceToFirst, isIntercepted, isFumbled)
    FieldAnimator.active = true
    FieldAnimator.completed = false
    FieldAnimator.timer = 0
    FieldAnimator.duration = 2.8
    if playType:match("Pass") then FieldAnimator.duration = 3.6 end
    
    FieldAnimator.playType = playType
    FieldAnimator.yardsGained = yardsGained
    FieldAnimator.yardLine = yardLine
    FieldAnimator.distanceToFirst = distanceToFirst
    FieldAnimator.isIntercepted = isIntercepted
    FieldAnimator.isFumbled = isFumbled
    
    local losX = (yardLine + 10) * YARD_PX
    local midY = FIELD_Y + FIELD_HEIGHT / 2
    
    FieldAnimator.ball = { x = losX - 4 * YARD_PX, y = midY, targetX = losX - 4 * YARD_PX, targetY = midY, z = 0, carrier = nil }
    FieldAnimator.offense = {}
    FieldAnimator.defense = {}
    FieldAnimator.dustParticles = {}

    FieldAnimator.skillCheckActive = false
    FieldAnimator.skillCheckTimer = 0
    FieldAnimator.skillCheckSuccess = nil
    FieldAnimator.skillCheckTriggered = false

    -- Helper to cap coordinates inside the back line (1185px)
    local function capX(xVal)
        return math.min(1185, math.max(15, xVal))
    end

    -- 1. Create Offensive Linemen (OL) Center, Left Guard, Right Guard
    table.insert(FieldAnimator.offense, { role = "OL_C", x = losX - 1.5 * YARD_PX, y = midY, targetX = capX(losX - 0.5 * YARD_PX), targetY = midY })
    table.insert(FieldAnimator.offense, { role = "OL_L", x = losX - 1.5 * YARD_PX, y = midY - 18, targetX = capX(losX - 0.5 * YARD_PX), targetY = midY - 18 })
    table.insert(FieldAnimator.offense, { role = "OL_R", x = losX - 1.5 * YARD_PX, y = midY + 18, targetX = capX(losX - 0.5 * YARD_PX), targetY = midY + 18 })

    -- 2. Create Defensive Linemen (DL) Center, Left, Right
    table.insert(FieldAnimator.defense, { role = "DL_C", x = losX + 1 * YARD_PX, y = midY, targetX = capX(losX - 0.5 * YARD_PX), targetY = midY, speed = 15 })
    table.insert(FieldAnimator.defense, { role = "DL_L", x = losX + 1 * YARD_PX, y = midY - 18, targetX = capX(losX - 0.5 * YARD_PX), targetY = midY - 18, speed = 15 })
    table.insert(FieldAnimator.defense, { role = "DL_R", x = losX + 1 * YARD_PX, y = midY + 18, targetX = capX(losX - 0.5 * YARD_PX), targetY = midY + 18, speed = 15 })

    local function getPlayerProfile(posName)
        if GameStateData.rosterSlots and GameStateData.rosterSlots[posName] and GameStateData.rosterSlots[posName].cards[1] then
            local card = GameStateData.rosterSlots[posName].cards[1]
            if card.isMyPlayer then return true end
            return card.visualProfile
        end
        
        -- Fallback profile for empty slots
        return {
            skinTone = math.random(1, 8),
            visor = "clear",
            armGear = "none",
            calfSleeves = "none",
            tattoos = false,
            hairStyle = "none",
            archetype = "stocky"
        }
    end
    
    local function genDefProfile(isHeavy)
        return {
            skinTone = math.random(1, 8),
            visor = (math.random() > 0.9 and "dark" or "clear"),
            armGear = (math.random() > 0.7 and "right_sleeve" or "none"),
            calfSleeves = (math.random() > 0.7 and "black" or "none"),
            tattoos = (math.random() > 0.8),
            hairStyle = (math.random() > 0.7 and "dreads" or "none"),
            hairColor = { math.random(20,80)/100, math.random(10,40)/100, 0.1 },
            archetype = isHeavy and "heavy" or "lean",
            facemask = isHeavy and math.random(4, 6) or math.random(1, 5),
            earrings = (math.random() > 0.8 and math.random(1, 2) or 0),
            jerseyNumber = math.random(50, 99),
        }
    end

    -- 3. Create Quarterback (QB)
    local qb = { role = "QB", x = losX - 4 * YARD_PX, y = midY, targetX = capX(losX - 8 * YARD_PX), targetY = midY, profile = getPlayerProfile("QB") }
    table.insert(FieldAnimator.offense, qb)
    FieldAnimator.ball.carrier = qb

    if playType:match("Pass") then
        -- 4. Create Skill Players (Pass Play)
        local targetY1 = midY - 45 + math.random(-10, 10)
        local wr1 = { 
            role = "WR1", x = losX - 1 * YARD_PX, y = midY - 65,
            targetX = capX(losX + yardsGained * YARD_PX), targetY = targetY1,
            startX = losX - 1 * YARD_PX, startY = midY - 65,
            breakX = capX(losX + (yardsGained * 0.45) * YARD_PX), breakY = midY - 65,
            profile = getPlayerProfile("WR1")
        }
        table.insert(FieldAnimator.offense, wr1)
        
        local targetY2 = midY + 45 + math.random(-10, 10)
        local wr2 = { 
            role = "WR2", x = losX - 1 * YARD_PX, y = midY + 65,
            targetX = capX(losX + (yardsGained - 3) * YARD_PX), targetY = targetY2,
            startX = losX - 1 * YARD_PX, startY = midY + 65,
            breakX = capX(losX + ((yardsGained - 3) * 0.45) * YARD_PX), breakY = midY + 65,
            profile = getPlayerProfile("WR2")
        }
        table.insert(FieldAnimator.offense, wr2)

        local te = {
            role = "TE", x = losX - 1.5 * YARD_PX, y = midY + 30,
            targetX = capX(losX + (yardsGained * 0.7) * YARD_PX), targetY = midY + 15,
            startX = losX - 1.5 * YARD_PX, startY = midY + 30,
            breakX = capX(losX + (yardsGained * 0.3) * YARD_PX), breakY = midY + 30,
            profile = getPlayerProfile("FLEX")
        }
        table.insert(FieldAnimator.offense, te)

        local rb = { role = "RB", x = losX - 6 * YARD_PX, y = midY + 10, targetX = capX(losX - 4 * YARD_PX), targetY = midY + 35, profile = getPlayerProfile("RB") }
        table.insert(FieldAnimator.offense, rb)

        -- Dynamic Target Receiver Selection based on Play Type
        local receivers = { wr1, wr2, te }
        if playType == "Screen Pass" then
            receivers = { rb, te, wr2 }
        elseif playType == "Short Pass" or playType == "Quick Slant" then
            receivers = { wr2, te, wr1 }
        elseif playType == "Deep Pass" or playType == "Hail Mary" then
            receivers = { wr1, wr2 }
        end
        FieldAnimator.targetReceiver = receivers[math.random(#receivers)]

        -- 5. Create Defenders (Pass Play)
        table.insert(FieldAnimator.defense, { role = "DB1", x = losX + 6 * YARD_PX, y = midY - 65, targetX = wr1.targetX, targetY = wr1.targetY, speed = 44, profile = genDefProfile(false) })
        table.insert(FieldAnimator.defense, { role = "DB2", x = losX + 6 * YARD_PX, y = midY + 65, targetX = wr2.targetX, targetY = wr2.targetY, speed = 44, profile = genDefProfile(false) })
        table.insert(FieldAnimator.defense, { role = "DB3", x = losX + 12 * YARD_PX, y = midY, targetX = losX + 15 * YARD_PX, targetY = midY, speed = 40, profile = genDefProfile(false) })
        table.insert(FieldAnimator.defense, { role = "LB1", x = losX + 4 * YARD_PX, y = midY - 25, targetX = te.targetX, targetY = te.targetY, speed = 36, profile = genDefProfile(true) })
        table.insert(FieldAnimator.defense, { role = "LB2", x = losX + 4 * YARD_PX, y = midY + 25, targetX = rb.targetX, targetY = rb.targetY, speed = 36, profile = genDefProfile(true) })
    else
        -- Run Play
        local rbProfile = getPlayerProfile("RB")
        if not rbProfile then rbProfile = getPlayerProfile("FLEX") end
        local rb = { role = "RB", x = losX - 6 * YARD_PX, y = midY, targetX = capX(losX + yardsGained * YARD_PX), targetY = midY + math.random(-15, 15), profile = rbProfile }
        table.insert(FieldAnimator.offense, rb)

        table.insert(FieldAnimator.offense, { role = "WR1", x = losX - 1 * YARD_PX, y = midY - 65, targetX = capX(losX + (yardsGained * 0.8) * YARD_PX), targetY = midY - 45, profile = getPlayerProfile("WR1") })
        table.insert(FieldAnimator.offense, { role = "WR2", x = losX - 1 * YARD_PX, y = midY + 65, targetX = capX(losX + (yardsGained * 0.8) * YARD_PX), targetY = midY + 45, profile = getPlayerProfile("WR2") })
        table.insert(FieldAnimator.offense, { role = "TE", x = losX - 1.5 * YARD_PX, y = midY + 30, targetX = capX(losX + 3 * YARD_PX), targetY = midY + 20, profile = getPlayerProfile("FLEX") })

        table.insert(FieldAnimator.defense, { role = "LB1", x = losX + 4 * YARD_PX, y = midY - 25, speed = 48, profile = genDefProfile(true) })
        table.insert(FieldAnimator.defense, { role = "LB2", x = losX + 4 * YARD_PX, y = midY + 25, speed = 48, profile = genDefProfile(true) })
        table.insert(FieldAnimator.defense, { role = "DB1", x = losX + 7 * YARD_PX, y = midY - 55, speed = 45, profile = genDefProfile(false) })
        table.insert(FieldAnimator.defense, { role = "DB2", x = losX + 7 * YARD_PX, y = midY + 55, speed = 45, profile = genDefProfile(false) })
    end
    
    FieldAnimator.cameraX = FieldAnimator.ball.x - FIELD_WIDTH / 2
    FieldAnimator.cameraX = math.max(0, math.min(1200 - FIELD_WIDTH, FieldAnimator.cameraX))
    FieldAnimator.targetCameraX = FieldAnimator.cameraX
end

function FieldAnimator.update(dt)
    if not FieldAnimator.active then return end
    
    FieldAnimator.timer = FieldAnimator.timer + dt
    local t = math.min(1.0, FieldAnimator.timer / FieldAnimator.duration)
    
    -- Dynamic tackle contact check
    local carrier = FieldAnimator.ball.carrier
    if carrier and not FieldAnimator.completed then
        local isPlayActive = false
        if FieldAnimator.playType:match("Pass") then
            -- Passes: check for tackle after ball is caught (t >= 0.9)
            if t >= 0.9 then isPlayActive = true end
        else
            -- Runs: check for tackle after handoff (t >= 0.2)
            if t >= 0.2 then isPlayActive = true end
        end
        
        if isPlayActive then
            local losX = (FieldAnimator.yardLine + 10) * YARD_PX
            local canBeTackled = false
            if FieldAnimator.yardsGained <= 0 then
                canBeTackled = true
            else
                -- Positive gain: carrier can only be tackled once they reach their yardage gain zone (within 2.5 yards of target, or t >= 0.85)
                if carrier.x >= (losX + (FieldAnimator.yardsGained - 2.5) * YARD_PX) or t >= 0.85 then
                    canBeTackled = true
                end
            end
            
            if canBeTackled then
                local closestDef, minDist = nil, 999999
                for _, def in ipairs(FieldAnimator.defense) do
                    local dx = def.x - carrier.x
                    local dy = def.y - carrier.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < minDist then
                        minDist = dist
                        closestDef = def
                    end
                end
                
                -- Trigger physical tackle if defender makes contact and we are not past the goal line (1100px)
                if minDist <= 18 and carrier.x < 1100 then
                    FieldAnimator.completed = true
                    local FxManager = require("src.engine.fx_manager")
                    FxManager.addBurstParticles(FieldAnimator.ball.x, FieldAnimator.ball.y, 35, 1.0, 1.0, 1.0)
                    local SoundManager = require("src.engine.sound_manager")
                    SoundManager.playSFX("tackle")
                    if _G.triggerScreenShake then _G.triggerScreenShake(20, 0.4) end
                    if _G.triggerHitStop then _G.triggerHitStop(0.15) end
                    
                    -- Force timer to the end of the duration so it completes on the next update
                    FieldAnimator.timer = FieldAnimator.duration
                    t = 1.0
                end
            end
        end
    end
    
    if t >= 1.0 and not FieldAnimator.completed then
        FieldAnimator.completed = true
        local FxManager = require("src.engine.fx_manager")
        FxManager.addBurstParticles(FieldAnimator.ball.x, FieldAnimator.ball.y, 35, 1.0, 1.0, 1.0)
        local SoundManager = require("src.engine.sound_manager")
        SoundManager.playSFX("tackle")
        if _G.triggerScreenShake then _G.triggerScreenShake(20, 0.4) end
        if _G.triggerHitStop then _G.triggerHitStop(0.15) end
    end
    
    -- Update Dust & Snow Particles
    for i = #FieldAnimator.dustParticles, 1, -1 do
        local dp = FieldAnimator.dustParticles[i]
        dp.life = dp.life - dt
        dp.x = dp.x + dp.vx * dt
        dp.y = dp.y + dp.vy * dt
        if dp.life <= 0 then table.remove(FieldAnimator.dustParticles, i) end
    end
    
    -- Trigger Skill Check
    if not FieldAnimator.skillCheckTriggered and FieldAnimator.timer > 0.1 then
        FieldAnimator.skillCheckTriggered = true
        FieldAnimator.skillCheckActive = true
        FieldAnimator.skillCheckTimer = 0
        if FieldAnimator.playType:match("Pass") then
            FieldAnimator.skillCheckType = "THROW"
            FieldAnimator.skillCheckDuration = 0.8
        else
            FieldAnimator.skillCheckType = "JUKE"
            FieldAnimator.skillCheckDuration = 1.0
        end
    end
    
    if FieldAnimator.skillCheckActive then
        FieldAnimator.skillCheckTimer = FieldAnimator.skillCheckTimer + dt
        if FieldAnimator.skillCheckTimer > FieldAnimator.skillCheckDuration then
            FieldAnimator.skillCheckActive = false
            FieldAnimator.skillCheckSuccess = false
            local FxManager = require("src.engine.fx_manager")
            FxManager.addFloatingText("MISSED " .. FieldAnimator.skillCheckType, 480, 200, 1.0, 0.2, 0.2, 1.5)
        end
    end
    
    local losX = (FieldAnimator.yardLine + 10) * YARD_PX
    local midY = FIELD_Y + FIELD_HEIGHT / 2
    
    -- Resolve offensive key players
    local qb, wr1, wr2, rb, te
    for _, p in ipairs(FieldAnimator.offense) do
        if p.role == "QB" then qb = p
        elseif p.role == "WR1" then wr1 = p
        elseif p.role == "WR2" then wr2 = p
        elseif p.role == "RB" then rb = p
        elseif p.role == "TE" then te = p end
    end

    -- Update Offense AI
    for _, p in ipairs(FieldAnimator.offense) do
        local oldX, oldY = p.x, p.y
        p.vx, p.vy = 0, 0
        
        if p.role == "QB" then
            if FieldAnimator.playType:match("Pass") then
                local qbT = math.min(1.0, t * 5.0)
                p.x = PhysicsUtils.lerp(losX - 4 * YARD_PX, p.targetX, qbT)
                p.y = PhysicsUtils.lerp(midY, p.targetY, qbT)
            else
                local handoffT = math.min(1.0, t * 5.0)
                if handoffT < 1.0 then
                    p.x = PhysicsUtils.lerp(losX - 4 * YARD_PX, losX - 5 * YARD_PX, handoffT)
                else
                    p.x = losX - 5 * YARD_PX
                end
            end
        elseif p.role == "RB" then
            if FieldAnimator.playType:match("Pass") then
                local rbT = math.min(1.0, t * 1.5)
                p.x = PhysicsUtils.lerp(losX - 6 * YARD_PX, p.targetX, rbT)
                p.y = PhysicsUtils.lerp(midY + 10, p.targetY, rbT)
            else
                local handoffT = math.min(1.0, t * 5.0)
                if handoffT < 1.0 then
                    p.x = PhysicsUtils.lerp(losX - 6 * YARD_PX, losX - 5 * YARD_PX, handoffT)
                    p.y = PhysicsUtils.lerp(midY, midY, handoffT)
                else
                    local runT = (t - 0.2) / 0.8
                    p.x = PhysicsUtils.lerp(losX - 5 * YARD_PX, p.targetX, runT)
                    p.y = PhysicsUtils.lerp(midY, p.targetY, runT)
                end
            end
        elseif p.role == "WR1" or p.role == "WR2" or p.role == "TE" then
            if FieldAnimator.playType:match("Pass") then
                local wrT = t
                if wrT < 0.4 then
                    local bt = wrT / 0.4
                    p.x = PhysicsUtils.lerp(p.startX, p.breakX, bt)
                    p.y = PhysicsUtils.lerp(p.startY, p.breakY, bt)
                else
                    local ft = (wrT - 0.4) / 0.6
                    p.x = PhysicsUtils.lerp(p.breakX, p.targetX, ft)
                    p.y = PhysicsUtils.lerp(p.breakY, p.targetY, ft)
                end
            else
                local blockT = math.min(1.0, t * 1.5)
                local startX = (p.role == "TE") and (losX - 1.5 * YARD_PX) or (losX - 1 * YARD_PX)
                local startY = (p.role == "TE") and (midY + 30) or ((p.role == "WR1") and (midY - 65) or (midY + 65))
                p.x = PhysicsUtils.lerp(startX, p.targetX, blockT)
                p.y = PhysicsUtils.lerp(startY, p.targetY, blockT)
            end
        elseif p.role:match("OL") then
            local olT = math.min(1.0, t * 3.0)
            local startY = (p.role == "OL_C") and midY or ((p.role == "OL_L") and (midY - 18) or (midY + 18))
            p.x = PhysicsUtils.lerp(losX - 1.5 * YARD_PX, p.targetX, olT)
            p.y = startY
        end
        
        if dt > 0 then
            p.vx = (p.x - oldX) / dt
            p.vy = (p.y - oldY) / dt
        end

        if math.random() < 0.1 and math.sqrt(p.vx^2 + p.vy^2) > 10 then
            local isSnow = (GameStateData.weather == "snow")
            table.insert(FieldAnimator.dustParticles, { x = p.x, y = p.y + 6, vx = -p.vx * 0.2, vy = -p.vy * 0.2, life = 0.4, isSnow = isSnow })
        end
    end

    -- Ball Flight
    if FieldAnimator.playType:match("Pass") then
        local passTarget = FieldAnimator.targetReceiver or wr1
        if t < 0.25 then
            FieldAnimator.ball.carrier = qb
        elseif t < 0.9 then
            FieldAnimator.ball.carrier = nil
            local throwT = (t - 0.25) / 0.65
            if FieldAnimator.isIntercepted then
                local db1
                for _, d in ipairs(FieldAnimator.defense) do if d.role == "DB1" then db1 = d; break end end
                local targetX = db1 and db1.x or passTarget.targetX
                local targetY = db1 and db1.y or passTarget.targetY
                FieldAnimator.ball.x = PhysicsUtils.lerp(qb.x, targetX, throwT)
                FieldAnimator.ball.y = PhysicsUtils.lerp(qb.y, targetY, throwT)
            else
                FieldAnimator.ball.x = PhysicsUtils.lerp(qb.x, passTarget.targetX, throwT)
                FieldAnimator.ball.y = PhysicsUtils.lerp(qb.y, passTarget.targetY, throwT)
            end
            FieldAnimator.ball.z = math.sin(throwT * math.pi) * 40
        else
            if FieldAnimator.isIntercepted then
                local db1
                for _, d in ipairs(FieldAnimator.defense) do if d.role == "DB1" then db1 = d; break end end
                FieldAnimator.ball.carrier = db1
            else
                FieldAnimator.ball.carrier = passTarget
            end
            FieldAnimator.ball.z = 4
        end
    else
        local handoffT = math.min(1.0, t * 5.0)
        if handoffT < 1.0 then
            FieldAnimator.ball.carrier = qb
        else
            FieldAnimator.ball.carrier = rb
        end
    end

    -- Update Defense AI (Dynamic Pursuit & Coverages)
    local targetCarrier = FieldAnimator.ball.carrier
    for _, def in ipairs(FieldAnimator.defense) do
        local tx, ty = def.x, def.y
        
        if targetCarrier then
            if FieldAnimator.yardsGained > 0 and not FieldAnimator.isIntercepted then
                local trailOffset = (1.0 - math.min(1.0, t)) * 75
                tx = math.max(def.x - 10, targetCarrier.x - trailOffset)
                ty = targetCarrier.y
            else
                tx, ty = targetCarrier.x, targetCarrier.y
            end
        else
            local targetPlayer = nil
            if def.role == "DB1" then
                targetPlayer = wr1
            elseif def.role == "DB2" then
                targetPlayer = wr2
            elseif def.role == "LB1" then
                targetPlayer = te
            elseif def.role == "DB3" or def.role == "LB2" then
                targetPlayer = rb
            elseif def.role:match("DL") then
                targetPlayer = qb
            end
            
            if targetPlayer then
                tx, ty = targetPlayer.x, targetPlayer.y
            end
        end
        
        local dx = tx - def.x
        local dy = ty - def.y
        local dist = math.sqrt(dx*dx + dy*dy)
        local oldX, oldY = def.x, def.y
        
        -- Pursuit urgency scaling as play duration progresses (t >= 0.5)
        local urgencyMult = 1.0 + math.max(0, (t - 0.4) * 1.8)
        if t >= 0.85 and dist < 45 and targetCarrier then
            -- Snap tackle close-in at t >= 0.85
            def.x = PhysicsUtils.lerp(def.x, targetCarrier.x, 12 * dt)
            def.y = PhysicsUtils.lerp(def.y, targetCarrier.y, 12 * dt)
        elseif dist > 5 then
            def.vx = (dx/dist) * def.speed * urgencyMult
            def.vy = (dy/dist) * def.speed * urgencyMult
            if not targetCarrier and FieldAnimator.playType:match("Pass") and def.role:match("DB") then
                def.vx = def.vx * 1.15
            end
            def.x = def.x + def.vx * dt
            def.y = def.y + def.vy * dt
        else
            def.vx, def.vy = 0, 0
        end
        
        if math.random() < 0.1 and math.sqrt(def.vx^2 + def.vy^2) > 10 then
            local isSnow = (GameStateData.weather == "snow")
            table.insert(FieldAnimator.dustParticles, { x = def.x, y = def.y + 6, vx = -def.vx * 0.2, vy = -def.vy * 0.2, life = 0.4, isSnow = isSnow })
        end
    end

    -- Sync ball position to carrier
    if FieldAnimator.ball.carrier then
        FieldAnimator.ball.x = FieldAnimator.ball.carrier.x
        FieldAnimator.ball.y = FieldAnimator.ball.carrier.y
        if FieldAnimator.playType:match("Pass") and FieldAnimator.ball.carrier.role == "QB" then
            FieldAnimator.ball.z = 8
        elseif FieldAnimator.playType:match("Run") then
            FieldAnimator.ball.z = math.sin(t * 30) * 4
        else
            FieldAnimator.ball.z = 0
        end
    end

    -- Camera follow ball absolute coordinate
    FieldAnimator.targetCameraX = FieldAnimator.ball.x - FIELD_WIDTH / 2
    FieldAnimator.targetCameraX = math.max(0, math.min(1200 - FIELD_WIDTH, FieldAnimator.targetCameraX))
    
    local lerpFactor = math.min(1.0, 5.0 * dt)
    FieldAnimator.cameraX = FieldAnimator.cameraX + (FieldAnimator.targetCameraX - FieldAnimator.cameraX) * lerpFactor
end

function FieldAnimator.startTurnoverSequence(turnoverType)
    FieldAnimator.isTurnoverSequence = true
    FieldAnimator.turnoverType = turnoverType or "INT"
    FieldAnimator.turnoverTimer = 0
    FieldAnimator.turnoverDuration = 2.0
end

function FieldAnimator.updateTurnover(dt)
    if not FieldAnimator.isTurnoverSequence then return end
    FieldAnimator.turnoverTimer = FieldAnimator.turnoverTimer + dt
    if FieldAnimator.turnoverTimer >= FieldAnimator.turnoverDuration then
        FieldAnimator.isTurnoverSequence = false
    end
end

local function drawDashedLine(x1, y1, x2, y2, dashLength, gapLength)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx*dx + dy*dy)
    local numDashes = math.floor(dist / (dashLength + gapLength))
    local nx = dx / dist
    local ny = dy / dist
    for i = 0, numDashes do
        local startX = x1 + (i * (dashLength + gapLength)) * nx
        local startY = y1 + (i * (dashLength + gapLength)) * ny
        local endX = startX + dashLength * nx
        local endY = startY + dashLength * ny
        if i == numDashes then
            endX = x2
            endY = y2
        end
        love.graphics.line(startX, startY, endX, endY)
    end
end

function FieldAnimator.draw()
    local weatherType = GameStateData.weather or "clear"
    local t = math.min(1.0, FieldAnimator.timer / FieldAnimator.duration)
    
    love.graphics.push()
    
    -- 1. 2.5D Angled Turf Base
    love.graphics.setColor(C_TURF)
    love.graphics.rectangle("fill", 0, 50, 960, 430)
    
    -- Alternating 2.5D angled dark green turf stripes
    love.graphics.setColor(C_TURF_DARK)
    for yard = 0, 90, 20 do
        local worldX = 100 + (yard + 10) * YARD_PX
        local x1, y1 = FieldAnimator.to25D(worldX, 50, 0)
        local x2, y2 = FieldAnimator.to25D(worldX + 10 * YARD_PX, 50, 0)
        local x3, y3 = FieldAnimator.to25D(worldX + 10 * YARD_PX, 310, 0)
        local x4, y4 = FieldAnimator.to25D(worldX, 310, 0)
        love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
    end
    
    -- 2. Endzones & Goal Lines
    local activeTeam = GameStateData.config and GameStateData.config.team
    local homeJersey = activeTeam and activeTeam.primaryColor or {0.12, 0.18, 0.35}
    local homeSec = activeTeam and activeTeam.secondaryColor or {1.0, 0.84, 0.0}
    local homeName = activeTeam and activeTeam.name:upper() or "HOME"
    
    -- Left Endzone (Own Team)
    local ex1, ey1 = FieldAnimator.to25D(0, 50, 0)
    local ex2, ey2 = FieldAnimator.to25D(100, 50, 0)
    local ex3, ey3 = FieldAnimator.to25D(100, 310, 0)
    local ex4, ey4 = FieldAnimator.to25D(0, 310, 0)
    love.graphics.setColor(homeJersey[1]*0.8, homeJersey[2]*0.8, homeJersey[3]*0.8, 0.95)
    love.graphics.polygon("fill", ex1, ey1, ex2, ey2, ex3, ey3, ex4, ey4)
    
    -- Left Goal Line
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.line(ex2, ey2, ex3, ey3)
    
    -- Right Endzone (Opponent)
    local rx1, ry1 = FieldAnimator.to25D(1100, 50, 0)
    local rx2, ry2 = FieldAnimator.to25D(1200, 50, 0)
    local rx3, ry3 = FieldAnimator.to25D(1200, 310, 0)
    local rx4, ry4 = FieldAnimator.to25D(1100, 310, 0)
    love.graphics.setColor(0.65, 0.1, 0.15, 0.95)
    love.graphics.polygon("fill", rx1, ry1, rx2, ry2, rx3, ry3, rx4, ry4)
    
    -- Right Goal Line
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.line(rx1, ry1, rx4, ry4)
    love.graphics.setLineWidth(1)
    
    -- 3. 2.5D Sidelines & Hash Marks
    local st1, sty1 = FieldAnimator.to25D(100, 50, 0)
    local st2, sty2 = FieldAnimator.to25D(1100, 50, 0)
    local sb1, sby1 = FieldAnimator.to25D(100, 310, 0)
    local sb2, sby2 = FieldAnimator.to25D(1100, 310, 0)
    
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.line(st1, sty1, st2, sty2)
    love.graphics.line(sb1, sby1, sb2, sby2)

    -- Right Goal Line
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.line(rx1, ry1, rx4, ry4)
    love.graphics.setLineWidth(1)
    
    -- 3. Draw Endzone Pylons (Orange Rectangles)
    local function drawPylon(px, py, scale)
        love.graphics.setColor(1.0, 0.4, 0.0, 1.0)
        love.graphics.rectangle("fill", px - 2, py - 12 * scale, 4 * scale, 12 * scale, 1, 1)
        love.graphics.setColor(1.0, 0.6, 0.2, 1.0)
        love.graphics.rectangle("fill", px - 1, py - 11 * scale, 2 * scale, 10 * scale)
    end
    
    local _, _, s1 = FieldAnimator.to25D(100, 50, 0)
    local _, _, s2 = FieldAnimator.to25D(100, 310, 0)
    drawPylon(ex2, ey2, s1)
    drawPylon(ex3, ey3, s2)
    
    local _, _, s3 = FieldAnimator.to25D(1100, 50, 0)
    local _, _, s4 = FieldAnimator.to25D(1100, 310, 0)
    drawPylon(rx1, ry1, s3)
    drawPylon(rx4, ry4, s4)

    -- 4. 2.5D Yard Lines
    for yard = 10, 90, 10 do
        local worldX = 100 + yard * YARD_PX
        local yx1, yy1 = FieldAnimator.to25D(worldX, 50, 0)
        local yx2, yy2 = FieldAnimator.to25D(worldX, 310, 0)
        love.graphics.setColor(1, 1, 1, 0.85)
        love.graphics.setLineWidth(4)
        love.graphics.line(yx1, yy1, yx2, yy2)
        
        local displayNum = yard > 50 and (100 - yard) or yard
        -- Draw numbers horizontally on both sidelines
        local numScale = (1.0 - (worldX - FieldAnimator.cameraX) * 0.001)
        local fs = math.max(1, 2.0 * numScale)
        drawShadowText(tostring(displayNum), yx1 - 35, yy1 - 10, 1, 1, 1, 1.0, "right", 30, fs)
        drawShadowText(tostring(displayNum), yx2 + 5, yy2 - 10, 1, 1, 1, 1.0, "left", 30, fs)
    end
    love.graphics.setLineWidth(1)
    
    -- 5. Line of Scrimmage & First Down Markers (2.5D Lines)
    local losWorldX = (FieldAnimator.yardLine + 10) * YARD_PX
    local lx1, ly1 = FieldAnimator.to25D(losWorldX, 50, 0)
    local lx2, ly2 = FieldAnimator.to25D(losWorldX, 310, 0)
    love.graphics.setColor(C_LOS)
    love.graphics.setLineWidth(3)
    love.graphics.line(lx1, ly1, lx2, ly2)
    
    local firstWorldX = losWorldX + FieldAnimator.distanceToFirst * YARD_PX
    local fx1, fy1 = FieldAnimator.to25D(firstWorldX, 50, 0)
    local fx2, fy2 = FieldAnimator.to25D(firstWorldX, 310, 0)
    love.graphics.setColor(C_FIRST)
    love.graphics.setLineWidth(3)
    love.graphics.line(fx1, fy1, fx2, fy2)
    love.graphics.setLineWidth(1)
    
    -- 6. Render Queue for Upright 2.5D Paper Mario Cutout Entities with Y-Sorting!
    local AssetManager = require("src.engine.asset_manager")
    local PlayerVisualProfile = require("src.data.player_visual_profile")
    local offJersey = (activeTeam and activeTeam.primaryColor) or PlayerVisualProfile.primaryColor or {0.13, 0.34, 0.13}
    local offHelmet = (activeTeam and activeTeam.secondaryColor) or PlayerVisualProfile.shellColor or {1.0, 0.84, 0.0}
    local defJersey = {0.85, 0.15, 0.15}
    local defHelmet = {0.95, 0.95, 0.95}
    local defPants = {0.95, 0.95, 0.95}
    
    local renderQueue = {}
    
    -- Add Offense
    for _, p in ipairs(FieldAnimator.offense) do
        local sx, sy, sc = FieldAnimator.to25D(p.x, p.y, 0)
        table.insert(renderQueue, {
            type = "player",
            isOffense = true,
            x = p.x, y = p.y, z = 0,
            screenX = sx, screenY = sy, scale = sc * 2.0,
            vx = p.vx, vy = p.vy,
            profile = p.profile,
            role = p.role,
            isTackled = FieldAnimator.completed and (FieldAnimator.ball.carrier == p)
        })
    end
    
    -- Add Defense
    for _, p in ipairs(FieldAnimator.defense) do
        local sx, sy, sc = FieldAnimator.to25D(p.x, p.y, 0)
        table.insert(renderQueue, {
            type = "player",
            isOffense = false,
            x = p.x, y = p.y, z = 0,
            screenX = sx, screenY = sy, scale = sc * 2.0,
            vx = p.vx, vy = p.vy,
            profile = p.profile,
            role = p.role,
            isTackled = FieldAnimator.completed and (FieldAnimator.ball.carrier == p)
        })
    end
    
    -- Y-Depth Sorting: Draw players further up on screen first, so front players overlap correctly!
    table.sort(renderQueue, function(a, b) return a.screenY < b.screenY end)
    
    -- Draw Render Queue
    for _, entity in ipairs(renderQueue) do
        -- Flattened Cast Shadow on 2.5D Turf
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.ellipse("fill", entity.screenX, entity.screenY + 4, 18 * (entity.scale / 2.0), 6 * (entity.scale / 2.0))
        
        -- Upright Paper Cutout Sprite
        if entity.isOffense then
            love.graphics.setColor(1, 1, 1, 1)
            AssetManager.drawRetroPlayer(entity.screenX, entity.screenY - 12, offJersey, {0.95, 0.95, 0.95}, offHelmet, entity.vx, entity.vy, true, love.timer.getTime(), entity.isTackled, entity.profile, entity.scale)
        else
            -- Darken defense sprites to make them look distinct (facing away)
            love.graphics.setColor(0.6, 0.6, 0.6, 1)
            AssetManager.drawRetroPlayer(entity.screenX, entity.screenY - 12, defJersey, defPants, defHelmet, entity.vx, entity.vy, false, love.timer.getTime(), entity.isTackled, entity.profile, entity.scale)
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        -- QB Cadence Speech Bubble
        if entity.role == "QB" and FieldAnimator.cadenceText ~= "" then
            love.graphics.setColor(1, 1, 1, 0.95)
            love.graphics.rectangle("fill", entity.screenX - 30, entity.screenY - 60, 60, 22, 6, 6)
            love.graphics.setColor(0, 0.76, 1)
            love.graphics.rectangle("line", entity.screenX - 30, entity.screenY - 60, 60, 22, 6, 6)
            drawShadowText(FieldAnimator.cadenceText, entity.screenX - 30, entity.screenY - 55, 0, 0, 0, 0.9, "center", 60)
        end
    end
    
    -- 7. 2.5D Pigskin Football
    local bx, by, bz = FieldAnimator.ball.x, FieldAnimator.ball.y, FieldAnimator.ball.z
    local bsx, bsy, bsc = FieldAnimator.to25D(bx, by, bz)
    local shadowSx, shadowSy = FieldAnimator.to25D(bx, by, 0)
    
    -- Ball Shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.ellipse("fill", shadowSx, shadowSy + 2, 8 * bsc, 3 * bsc)
    
    -- Ball Sprite
    local ballImg = AssetManager.getImage("sprites/football.png")
    if ballImg then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ballImg, bsx - 6, bsy - 5, 0, (12 * bsc) / ballImg:getWidth(), (10 * bsc) / ballImg:getHeight())
    else
        love.graphics.setColor(0.48, 0.22, 0.05)
        love.graphics.ellipse("fill", bsx, bsy, 4 * bsc, 2.5 * bsc)
    end
    
    -- 8. Tackle BOOM! Graphic
    if FieldAnimator.completed and FieldAnimator.timer < FieldAnimator.duration + 0.6 then
        local progress = (FieldAnimator.timer - FieldAnimator.duration) / 0.6
        local starAlpha = 1.0 - progress
        love.graphics.setColor(1, 0.84, 0, starAlpha)
        love.graphics.print("BOOM!", bsx - 22, bsy - 27, 0, 1.3, 1.3)
    end
    
    -- 9. Timed Skill Check UI
    if FieldAnimator.skillCheckActive and FieldAnimator.ball.carrier then
        local targetX = bsx
        local targetY = bsy - 30
        
        local progress = FieldAnimator.skillCheckTimer / FieldAnimator.skillCheckDuration
        local outerRadius = 50 * (1.0 - progress) + 15
        local innerRadius = 15
        
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.circle("fill", targetX, targetY, innerRadius)
        
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", targetX, targetY, innerRadius)
        
        -- Color transitions from Red -> Yellow -> Green as it gets closer
        local r, g, b = 1, 0, 0
        if progress > 0.5 then
            r, g, b = 1, 1, 0
        end
        if progress > 0.85 then
            r, g, b = 0, 1, 0
        end
        
        love.graphics.setColor(r, g, b, 1)
        love.graphics.circle("line", targetX, targetY, outerRadius)
        love.graphics.setLineWidth(1)
        
        drawShadowText("PRESS [SPACE]", targetX - 100, targetY - 25, 1, 1, 1, 0.8, "center", 200)
        -- translate to offset center alignment manually since x is center
        -- actually drawShadowText doesn't auto-center unless limit is used at x. 
        -- If x is center, we need to pass x - limit/2
    end
    
    love.graphics.pop()
end

function FieldAnimator.keypressed(key)
    if FieldAnimator.skillCheckActive and key == "space" then
        FieldAnimator.skillCheckActive = false
        local progress = FieldAnimator.skillCheckTimer / FieldAnimator.skillCheckDuration
        local FxManager = require("src.engine.fx_manager")
        local SoundManager = require("src.engine.sound_manager")
        
        if progress >= 0.75 and progress <= 0.95 then
            FieldAnimator.skillCheckSuccess = true
            FieldAnimator.skillBonus = (FieldAnimator.skillBonus or 0) + 2
            FxManager.addFloatingText("PERFECT " .. FieldAnimator.skillCheckType .. "! +2 YDS", 480, 200, 0.2, 0.9, 0.2, 1.8)
            SoundManager.playSFX("coin")
        elseif progress >= 0.5 then
            FieldAnimator.skillCheckSuccess = true
            FieldAnimator.skillBonus = (FieldAnimator.skillBonus or 0) + 1
            FxManager.addFloatingText("GOOD " .. FieldAnimator.skillCheckType .. "! +1 YDS", 480, 200, 0.9, 0.9, 0.2, 1.4)
            SoundManager.playSFX("click")
        else
            FieldAnimator.skillCheckSuccess = false
            FxManager.addFloatingText("EARLY " .. FieldAnimator.skillCheckType .. "!", 480, 200, 0.9, 0.2, 0.2, 1.4)
            SoundManager.playSFX("tackle")
        end
        return true
    end
    return false
end

return FieldAnimator
