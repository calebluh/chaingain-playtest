-- src/engine/physics_utils.lua
local PhysicsUtils = {}

-- Simple linear interpolation
function PhysicsUtils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Second Order Dynamics (Damped Harmonic Oscillator)
-- Good for bouncy, springy UI animations.
function PhysicsUtils.spring(current, target, velocity, dt, f, z, r)
    -- f: natural frequency (speed)
    -- z: damping coefficient (1 = critical, <1 = underdamped/bouncy, >1 = overdamped)
    -- r: initial response
    
    local k1 = z / (math.pi * f)
    local k2 = 1 / ((2 * math.pi * f) * (2 * math.pi * f))
    
    -- ensure stability
    local k2_stable = math.max(k2, 1.1 * (dt*dt/4 + dt*k1/2))
    
    local newCurrent = current + dt * velocity
    local newVelocity = velocity + dt * (target - current - k1*velocity) / k2_stable
    
    return newCurrent, newVelocity
end

return PhysicsUtils
