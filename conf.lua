-- conf.lua
function love.conf(t)
    t.identity = "ChainGain"
    t.window.width = 960
    t.window.height = 540
    t.window.title = "Chain Gain"
    t.console = true
end

-- Global Configs: Chalkboard Arcadia (CRT default OFF for maximum crispness)
_G.CONFIG_ENABLE_CRT = false
