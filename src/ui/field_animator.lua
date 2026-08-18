-- src/ui/field_animator.lua
local PhysicsUtils = require("src.engine.physics_utils")
local GameStateData = require("src.engine.game_state")
local FieldAnimator = {}

local FIELD_WIDTH = 500
local FIELD_HEIGHT = 200
local FIELD_X = 480 - FIELD_WIDTH / 2
local FIELD_Y = 80

local C_BORDER = { 0.1, 0.1, 0.1 }
local C_TURF = { 94 / 255, 172 / 255, 68 / 255 }
local C_TURF_DARK = { 80 / 255, 149 / 255, 59 / 255 }
local C_LOS = { 0.1, 0.4, 0.8, 0.9 }
local C_FIRST = { 1.0, 0.85, 0.1, 0.9 }

FieldAnimator.active = false
FieldAnimator.completed = true
FieldAnimator.timer = 0
FieldAnimator.duration = 1.5

FieldAnimator.playType = "Run"
FieldAnimator.yardsGained = 0
FieldAnimator.yardLine = 25
FieldAnimator.distanceToFirst = 1



FieldAnimator.ball = { x = 0, y = 0, targetX = 0, targetY = 0, scale = 1, z = 0, carrier = nil }
FieldAnimator.offense = {}
FieldAnimator.defense = {}
FieldAnimator.dustParticles = {}

FieldAnimator.cameraX = 0
FieldAnimator.targetCameraX = 0

local YARD_PX = 10 -- pixels per yard

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
        if t < 0.25 then
            FieldAnimator.ball.carrier = qb
        elseif t < 0.9 then
            FieldAnimator.ball.carrier = nil
            local throwT = (t - 0.25) / 0.65
            if FieldAnimator.isIntercepted then
                local db1
                for _, d in ipairs(FieldAnimator.defense) do if d.role == "DB1" then db1 = d; break end end
                local targetX = db1 and db1.x or wr1.targetX
                local targetY = db1 and db1.y or wr1.targetY
                FieldAnimator.ball.x = PhysicsUtils.lerp(qb.x, targetX, throwT)
                FieldAnimator.ball.y = PhysicsUtils.lerp(qb.y, targetY, throwT)
            else
                FieldAnimator.ball.x = PhysicsUtils.lerp(qb.x, wr1.targetX, throwT)
                FieldAnimator.ball.y = PhysicsUtils.lerp(qb.y, wr1.targetY, throwT)
            end
            FieldAnimator.ball.z = math.sin(throwT * math.pi) * 40
        else
            if FieldAnimator.isIntercepted then
                local db1
                for _, d in ipairs(FieldAnimator.defense) do if d.role == "DB1" then db1 = d; break end end
                FieldAnimator.ball.carrier = db1
            else
                FieldAnimator.ball.carrier = wr1
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
    if not FieldAnimator.active then return end
    
    local weatherType = GameStateData.weather or "clear"
    local t = math.min(1.0, FieldAnimator.timer / FieldAnimator.duration)
    
    love.graphics.push()
    
    -- Draw outer dark border
    love.graphics.setColor(C_BORDER)
    love.graphics.rectangle("fill", FIELD_X - 4, FIELD_Y - 4, FIELD_WIDTH + 8, FIELD_HEIGHT + 8)
    
    -- Set viewport scissor (scaled by 2x to match canvas resolution)
    love.graphics.setScissor(FIELD_X * 2, FIELD_Y * 2, FIELD_WIDTH * 2, FIELD_HEIGHT * 2)
    
    -- Apply Viewport Translation: Maps absolute X coordinates to the scissor area!
    love.graphics.translate(FIELD_X - FieldAnimator.cameraX, 0)
    
    -- 1. Turf Base Colors (Stripe alternating pattern)
    -- Light turf
    love.graphics.setColor(C_TURF)
    love.graphics.rectangle("fill", 100, FIELD_Y, 1000, FIELD_HEIGHT)
    
    -- Alternating dark green stripes every 10 yards (100 px wide, drawn at odd 10-yard intervals)
    love.graphics.setColor(C_TURF_DARK)
    for yard = 0, 90, 20 do
        local sx = 100 + (yard + 10) * YARD_PX
        love.graphics.rectangle("fill", sx, FIELD_Y, 10 * YARD_PX, FIELD_HEIGHT)
    end
    
    -- 2. Endzones
    local activeTeam = GameStateData.config and GameStateData.config.team
    local homeJersey = activeTeam and activeTeam.primaryColor or {0.12, 0.18, 0.35}
    local homeSec = activeTeam and activeTeam.secondaryColor or {1.0, 0.84, 0.0}
    local homeName = activeTeam and activeTeam.name:upper() or "HOME"
    
    -- Left Endzone (Own Team)
    love.graphics.setColor(homeJersey[1]*0.8, homeJersey[2]*0.8, homeJersey[3]*0.8, 0.95)
    love.graphics.rectangle("fill", 0, FIELD_Y, 100, FIELD_HEIGHT)
    love.graphics.setColor(homeSec[1], homeSec[2], homeSec[3], 0.25)
    love.graphics.setLineWidth(10)
    for i = -30, FIELD_HEIGHT + 30, 30 do
        love.graphics.line(10, FIELD_Y + i, 80, FIELD_Y + i + 30)
    end
    love.graphics.setLineWidth(1)
    
    -- Left Endzone Goal Line
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.rectangle("fill", 100, FIELD_Y, 3, FIELD_HEIGHT)
    
    -- Left Endzone Text (Team Name)
    love.graphics.push()
    love.graphics.translate(50, FIELD_Y + FIELD_HEIGHT/2)
    love.graphics.rotate(-math.pi/2)
    love.graphics.setColor(homeSec[1], homeSec[2], homeSec[3], 0.9)
    local font = love.graphics.getFont()
    local textW = font and font:getWidth(homeName) or 40
    love.graphics.print(homeName, -textW/2, -8, 0, 1.2, 1.2)
    love.graphics.pop()
    
    -- Right Endzone (Opponent)
    love.graphics.setColor(0.65, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", 1100, FIELD_Y, 100, FIELD_HEIGHT)
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.setLineWidth(10)
    for i = -30, FIELD_HEIGHT + 30, 30 do
        love.graphics.line(1110, FIELD_Y + i, 1180, FIELD_Y + i + 30)
    end
    love.graphics.setLineWidth(1)
    
    -- Right Endzone Goal Line
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.rectangle("fill", 1100, FIELD_Y, 3, FIELD_HEIGHT)
    
    -- Right Endzone Text "TOUCHDOWN"
    love.graphics.push()
    love.graphics.translate(1150, FIELD_Y + FIELD_HEIGHT/2)
    love.graphics.rotate(-math.pi/2)
    love.graphics.setColor(1.0, 0.84, 0.0, 0.8)
    local touchdownW = font and font:getWidth("TOUCHDOWN") or 80
    love.graphics.print("TOUCHDOWN", -touchdownW/2, -8, 0, 1.2, 1.2)
    love.graphics.pop()
    
    -- Field Logo
    love.graphics.setColor(1, 1, 1, 0.08)
    local font = love.graphics.getFont()
    local logoW = font and font:getWidth("CHAIN GAIN") or 100
    love.graphics.print("CHAIN GAIN", 600 - logoW * 2, FIELD_Y + FIELD_HEIGHT/2 - 20, 0, 4.0, 4.0)

    -- 3. Sidelines & Hash Marks
    love.graphics.setColor(1, 1, 1, 0.9)
    -- Top Sideline
    love.graphics.rectangle("fill", 100, FIELD_Y + 15, 1000, 3)
    -- Bottom Sideline
    love.graphics.rectangle("fill", 100, FIELD_Y + FIELD_HEIGHT - 18, 1000, 3)
    
    -- Pixel Sideline Crowd/Bench
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("fill", 100, FIELD_Y - 5, 1000, 20)
    for px = 100, 1100, 15 do
        love.graphics.setColor(math.random(), math.random(), math.random(), 0.8)
        love.graphics.rectangle("fill", px, FIELD_Y - 2, 4, 6)
        love.graphics.rectangle("fill", px+5, FIELD_Y + 4, 4, 6)
    end
    
    -- Hash Marks
    love.graphics.setColor(1, 1, 1, 0.5)
    for yard = 1, 99 do
        if yard % 5 ~= 0 then
            local hx = 100 + yard * YARD_PX
            love.graphics.line(hx, FIELD_Y + 18, hx, FIELD_Y + 22)
            love.graphics.line(hx, FIELD_Y + FIELD_HEIGHT - 25, hx, FIELD_Y + FIELD_HEIGHT - 21)
        end
    end
    
    -- 4. Yard Lines & Numbers
    for yard = 10, 90, 10 do
        local lx = 100 + yard * YARD_PX
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setLineWidth(2)
        drawDashedLine(lx, FIELD_Y + 15, lx, FIELD_Y + FIELD_HEIGHT - 18, 6, 4)
        love.graphics.setLineWidth(1)
        
        -- Display yard number (10, 20, 30, 40, 50, 40, 30, 20, 10)
        local displayNum = yard > 50 and (100 - yard) or yard
        love.graphics.setColor(1, 1, 1, 0.6)
        
        -- Directional arrow text
        local numStr = tostring(displayNum)
        if yard < 50 then numStr = numStr .. " >"
        elseif yard > 50 then numStr = "< " .. numStr
        end
        
        -- Draw top yard number
        love.graphics.print(numStr, lx - 12, FIELD_Y + 30, 0, 1.2, 1.2)
        -- Draw bottom yard number
        love.graphics.print(numStr, lx - 12, FIELD_Y + FIELD_HEIGHT - 45, 0, 1.2, 1.2)
    end
    
    -- 5. Rain Ripple Splashes
    if weatherType == "rain" then
        for i = 1, 8 do
            local rx = 100 + (i * 123 + math.sin(i * 123.45 + love.timer.getTime() * 0.5) * 50) % 1000
            local ry = FIELD_Y + 20 + (i * 28 + love.timer.getTime() * 8) % (FIELD_HEIGHT - 40)
            local rRadius = ((love.timer.getTime() * 1.5 + i * 0.15) % 1.0) * 12
            local rAlpha = 1.0 - (rRadius / 12)
            love.graphics.setColor(0.6, 0.8, 1.0, rAlpha * 0.25)
            love.graphics.ellipse("line", rx, ry, rRadius, rRadius * 0.4)
        end
    end
    
    -- 6. Line of Scrimmage & First Down Line
    local losX = (FieldAnimator.yardLine + 10) * YARD_PX
    love.graphics.setColor(C_LOS)
    love.graphics.setLineWidth(2)
    love.graphics.line(losX, FIELD_Y + 15, losX, FIELD_Y + FIELD_HEIGHT - 18)
    
    local firstX = losX + FieldAnimator.distanceToFirst * YARD_PX
    love.graphics.setColor(C_FIRST)
    love.graphics.setLineWidth(2)
    love.graphics.line(firstX, FIELD_Y + 15, firstX, FIELD_Y + FIELD_HEIGHT - 18)
    
    -- Target Spot Line (Neon Green Dotted Line)
    if FieldAnimator.yardsGained > 0 and not FieldAnimator.isIntercepted then
        local targetGainX = losX + FieldAnimator.yardsGained * YARD_PX
        love.graphics.setColor(0.0, 0.9, 0.4, 0.6)
        love.graphics.setLineWidth(2)
        local steps = 12
        for i = 0, steps do
            if i % 2 == 0 then
                local y1 = FIELD_Y + 15 + i * (FIELD_HEIGHT - 33) / steps
                local y2 = FIELD_Y + 15 + (i + 1) * (FIELD_HEIGHT - 33) / steps
                love.graphics.line(targetGainX, y1, targetGainX, y2)
            end
        end
    end
    love.graphics.setLineWidth(1)
    
    -- 7. Defensive Zone Coverages before snap
    if t < 0.22 then
        love.graphics.setColor(1.0, 0.2, 0.2, 0.08)
        for _, def in ipairs(FieldAnimator.defense) do
            local zoneRadius = def.role:match("DB") and 65 or 45
            love.graphics.circle("fill", def.x, def.y, zoneRadius)
            love.graphics.setColor(1.0, 0.2, 0.2, 0.3)
            love.graphics.circle("line", def.x, def.y, zoneRadius)
            love.graphics.setColor(1.0, 0.2, 0.2, 0.08)
        end
    end
    
    -- 8. Angled Routes
    if FieldAnimator.playType:match("Pass") then
        local pulseAlpha = 0.4 + 0.5 * (math.sin(love.timer.getTime() * 8) + 1) / 2
        for _, p in ipairs(FieldAnimator.offense) do
            if p.breakX and p.targetX then
                love.graphics.setColor(1, 1, 1, 0.8 * pulseAlpha)
                love.graphics.setLineWidth(3)
                love.graphics.line(p.startX, p.startY, p.breakX, p.breakY)
                love.graphics.line(p.breakX, p.breakY, p.targetX, p.targetY)
                
                love.graphics.setColor(0, 0.9, 0.2, 0.8 * pulseAlpha)
                love.graphics.setLineWidth(1.5)
                love.graphics.line(p.startX, p.startY, p.breakX, p.breakY)
                love.graphics.line(p.breakX, p.breakY, p.targetX, p.targetY)
                love.graphics.circle("fill", p.targetX, p.targetY, 4)
            end
        end
        love.graphics.setLineWidth(1)
    end
    
    -- 9. Dotted Pass Path while ball is in the air
    if FieldAnimator.playType:match("Pass") and t > 0.25 and t < 0.9 then
        local qb, wr1
        for _, p in ipairs(FieldAnimator.offense) do
            if p.role == "QB" then qb = p
            elseif p.role == "WR1" then wr1 = p end
        end
        if qb and wr1 then
            love.graphics.setColor(0.1, 0.8, 1.0, 0.45)
            love.graphics.setLineWidth(2)
            local steps = 15
            for i = 0, steps do
                local pt = i / steps
                local px = PhysicsUtils.lerp(qb.x, wr1.targetX, pt)
                local py = PhysicsUtils.lerp(qb.y, wr1.targetY, pt)
                if i % 2 == 0 then
                    love.graphics.circle("fill", px, py, 2.5)
                end
            end
            love.graphics.setLineWidth(1)
        end
    end
    
    -- 10. Dust / Snow Particles
    for _, dp in ipairs(FieldAnimator.dustParticles) do
        if dp.isSnow then
            love.graphics.setColor(1.0, 1.0, 1.0, 0.85)
            love.graphics.circle("fill", dp.x, dp.y, 3 * (dp.life / 0.4))
        else
            love.graphics.setColor(0.8, 0.7, 0.5, 0.6)
            love.graphics.circle("fill", dp.x, dp.y, 2 * (dp.life / 0.4))
        end
    end
    
    -- 11. Draw Goalposts
    love.graphics.setColor(0.9, 0.8, 0.1)
    love.graphics.setLineWidth(3)
    -- Left Goalpost (drawn at absolute X = 0)
    love.graphics.line(0, FIELD_Y + FIELD_HEIGHT/2 - 20, 0, FIELD_Y + FIELD_HEIGHT/2 + 20)
    love.graphics.line(0, FIELD_Y + FIELD_HEIGHT/2, 20, FIELD_Y + FIELD_HEIGHT/2)
    -- Right Goalpost (drawn at absolute X = 1200)
    love.graphics.line(1200, FIELD_Y + FIELD_HEIGHT/2 - 20, 1200, FIELD_Y + FIELD_HEIGHT/2 + 20)
    love.graphics.line(1200, FIELD_Y + FIELD_HEIGHT/2, 1180, FIELD_Y + FIELD_HEIGHT/2)
    love.graphics.setLineWidth(1)
    
    -- 12. Draw Defense Players (Retro Bowl Pixel Art Style!)
    local defJersey = {0.85, 0.15, 0.15}
    local defHelmet = {0.95, 0.95, 0.95}
    local defPants = {0.95, 0.95, 0.95}
    local AssetManager = require("src.engine.asset_manager")
    for _, p in ipairs(FieldAnimator.defense) do
        local isTackled = FieldAnimator.completed and (FieldAnimator.ball.carrier == p)
        AssetManager.drawRetroPlayer(p.x, p.y, defJersey, defPants, defHelmet, p.vx, p.vy, false, love.timer.getTime(), isTackled, p.profile)
    end
    
    -- 13. Draw Offense Players (Retro Bowl Pixel Art Style!)
    local activeTeam = GameStateData.config and GameStateData.config.team
    local PlayerVisualProfile = require("src.data.player_visual_profile")
    local offJersey = (activeTeam and activeTeam.primaryColor) or PlayerVisualProfile.primaryColor or {0.13, 0.34, 0.13}
    local offHelmet = (activeTeam and activeTeam.secondaryColor) or PlayerVisualProfile.shellColor or {1.0, 0.84, 0.0}
    local offPants = {0.95, 0.95, 0.95}
    
    for _, p in ipairs(FieldAnimator.offense) do
        local isTackled = FieldAnimator.completed and (FieldAnimator.ball.carrier == p)
        AssetManager.drawRetroPlayer(p.x, p.y, offJersey, offPants, offHelmet, p.vx, p.vy, true, love.timer.getTime(), isTackled, p.profile)
    end
    
    -- 14. Draw Ball
    local bx, by, bz = FieldAnimator.ball.x, FieldAnimator.ball.y, FieldAnimator.ball.z
    local shadowScale = math.max(0.2, 1.0 - (bz / 40))
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.ellipse("fill", bx, by + 12, 6 * shadowScale, 2 * shadowScale)
    
    -- Ball Comet Trail
    if bz > 10 then
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.line(bx - 12, by - bz + 4, bx, by - bz)
        love.graphics.setColor(0.9, 0.8, 0.2, 0.4)
        love.graphics.line(bx - 16, by - bz + 6, bx, by - bz)
    end
    
    local ballImg = AssetManager.getImage("sprites/football.png")
    if ballImg then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ballImg, bx - 10, by - bz - 8, 0, 20 / ballImg:getWidth(), 16 / ballImg:getHeight())
    else
        love.graphics.setColor(0.48, 0.22, 0.05)
        love.graphics.ellipse("fill", bx, by - bz, 6, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(bx - 2, by - bz, bx + 2, by - bz)
    end
    
    -- 15. Draw BOOM! Tackle burst graphic
    if FieldAnimator.completed and FieldAnimator.timer < FieldAnimator.duration + 0.6 then
        local progress = (FieldAnimator.timer - FieldAnimator.duration) / 0.6
        local starAlpha = 1.0 - progress
        
        love.graphics.setColor(1, 0.84, 0, starAlpha)
        love.graphics.push()
        love.graphics.translate(bx, by)
        love.graphics.rotate(love.timer.getTime() * 8)
        local points = {}
        local count = 10
        for i = 1, count do
            local r = (i % 2 == 0) and 18 or 9
            local angle = (i / count) * math.pi * 2
            table.insert(points, r * math.cos(angle))
            table.insert(points, r * math.sin(angle))
        end
        love.graphics.polygon("fill", points)
        love.graphics.pop()
        
        love.graphics.setColor(0, 0, 0, starAlpha)
        love.graphics.print("BOOM!", bx - 21, by - 26, 0, 1.25, 1.25)
        love.graphics.setColor(1, 0.2, 0.2, starAlpha)
        love.graphics.print("BOOM!", bx - 22, by - 27, 0, 1.25, 1.25)
    end
    
    love.graphics.setScissor()
    love.graphics.pop()
end

return FieldAnimator
