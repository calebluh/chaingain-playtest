-- src/engine/sound_manager.lua
local SoundManager = {}

local sfxCache = {}
local currentMusic = nil

function SoundManager.init()
    sfxCache = {}
    
    -- Generate procedural fallback sound data if audio files aren't in assets/
    SoundManager.generateFallbackSFX()
end

function SoundManager.generateFallbackSFX()
    -- Generate simple synthetic sound effects using love.sound.newSoundData if supported
    if not (love.sound and love.sound.newSoundData) then return end
    
    local sampleRate = 44100
    
    -- 1. Whistle SFX (high pitch dual tone)
    local length = math.floor(sampleRate * 0.25)
    local sdWhistle = love.sound.newSoundData(length, sampleRate, 16, 1)
    for i = 0, length - 1 do
        local t = i / sampleRate
        local sample = (math.sin(2 * math.pi * 2800 * t) + math.sin(2 * math.pi * 2850 * t)) * 0.25
        local env = math.sin(math.pi * (i / length))
        sdWhistle:setSample(i, sample * env)
    end
    sfxCache["whistle"] = love.audio.newSource(sdWhistle, "static")
    
    -- 2. Click SFX (short burst)
    length = math.floor(sampleRate * 0.04)
    local sdClick = love.sound.newSoundData(length, sampleRate, 16, 1)
    for i = 0, length - 1 do
        local t = i / sampleRate
        local sample = (math.random() * 2 - 1) * (1 - (i / length)) * 0.3
        sdClick:setSample(i, sample)
    end
    sfxCache["click"] = love.audio.newSource(sdClick, "static")
    
    -- 3. Tackle Impact SFX (low noise thud)
    length = math.floor(sampleRate * 0.3)
    local sdTackle = love.sound.newSoundData(length, sampleRate, 16, 1)
    for i = 0, length - 1 do
        local t = i / sampleRate
        local freq = 120 * (1 - t/0.3)
        local noise = (math.random() * 2 - 1) * 0.4
        local tone = math.sin(2 * math.pi * freq * t) * 0.5
        local env = math.pow(1 - (i / length), 2)
        sdTackle:setSample(i, (noise + tone) * env)
    end
    sfxCache["tackle"] = love.audio.newSource(sdTackle, "static")
    
    -- 4. Touchdown Fanfare SFX (rising arpeggio)
    length = math.floor(sampleRate * 0.6)
    local sdTD = love.sound.newSoundData(length, sampleRate, 16, 1)
    for i = 0, length - 1 do
        local t = i / sampleRate
        local freq = 440
        if t > 0.4 then freq = 880
        elseif t > 0.25 then freq = 660
        elseif t > 0.12 then freq = 554.37 end
        local sample = math.sin(2 * math.pi * freq * t) * 0.3
        local env = math.sin(math.pi * (i / length))
        sdTD:setSample(i, sample * env)
    end
    sfxCache["touchdown"] = love.audio.newSource(sdTD, "static")
    
    -- 5. Coin SFX (two quick high chimes)
    length = math.floor(sampleRate * 0.2)
    local sdCoin = love.sound.newSoundData(length, sampleRate, 16, 1)
    for i = 0, length - 1 do
        local t = i / sampleRate
        local freq = (t < 0.08) and 987.77 or 1318.51
        local sample = math.sin(2 * math.pi * freq * t) * 0.35
        local env = math.pow(1 - (i / length), 1.5)
        sdCoin:setSample(i, sample * env)
    end
    sfxCache["coin"] = love.audio.newSource(sdCoin, "static")
    
    -- 6. Slam SFX (heavy bass drop)
    length = math.floor(sampleRate * 0.4)
    local sdSlam = love.sound.newSoundData(length, sampleRate, 16, 1)
    for i = 0, length - 1 do
        local t = i / sampleRate
        local freq = 150 * math.exp(-t * 10)
        local sample = math.sin(2 * math.pi * freq * t) * 0.8
        local env = math.pow(1 - (i / length), 2)
        sdSlam:setSample(i, sample * env)
    end
    sfxCache["slam"] = love.audio.newSource(sdSlam, "static")
end

function SoundManager.playSFX(name, pitch)
    -- Check custom audio file first
    local customPath = "assets/audio/sfx/" .. name .. ".ogg"
    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(customPath) then
        local ok, src = pcall(love.audio.newSource, customPath, "static")
        if ok and src then
            src:setVolume(_G.CONFIG_SFX_VOLUME or 0.8)
            src:setPitch(pitch or 1.0)
            src:play()
            return
        end
    end
    
    -- Fallback synthetic SFX
    if sfxCache[name] then
        sfxCache[name]:stop()
        sfxCache[name]:setVolume(_G.CONFIG_SFX_VOLUME or 0.8)
        sfxCache[name]:setPitch(pitch or 1.0)
        sfxCache[name]:play()
    end
end

function SoundManager.playMusic(trackName)
    local path = "assets/audio/music/" .. trackName .. ".ogg"
    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(path) then
        if currentMusic then currentMusic:stop() end
        local ok, src = pcall(love.audio.newSource, path, "stream")
        if ok and src then
            currentMusic = src
            currentMusic:setLooping(true)
            currentMusic:setVolume(_G.CONFIG_MUSIC_VOLUME or 0.5)
            currentMusic:play()
        end
    end
end

return SoundManager
