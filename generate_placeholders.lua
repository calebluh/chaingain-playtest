-- generate_placeholders.lua
-- Drop this file into your ChainGain folder and require it in main.lua temporarily, OR run it as a standalone script.
-- To run it standalone, you can just temporarily replace main.lua's love.load with: `require("generate_placeholders")` and it will generate everything and quit.

local function generateImage(path, w, h, text, bgColor, textColor)
    local canvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    
    -- Draw border
    love.graphics.setColor(textColor[1], textColor[2], textColor[3], 0.5)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", 2, 2, w-4, h-4)
    
    -- Draw text
    love.graphics.setColor(textColor)
    local font = love.graphics.setNewFont(math.floor(w / 15))
    
    local lines = {}
    for word in text:gmatch("%S+") do table.insert(lines, word) end
    local dispText = table.concat(lines, "\n")
    
    local fontHeight = font:getHeight() * #lines
    love.graphics.printf(dispText, 0, h/2 - fontHeight/2, w, "center")
    
    love.graphics.setCanvas()
    
    -- Encode and save using standard IO to bypass Love2D's save directory restriction
    local imgData = canvas:newImageData()
    local fileData = imgData:encode("png")
    
    -- Ensure directory exists (basic fallback, assumes assets/images/ exists)
    os.execute('mkdir "' .. path:match("(.*[/\\])") .. '" 2>nul')
    
    local f = io.open(path, "wb")
    if f then
        f:write(fileData:getString())
        f:close()
        print("Generated: " .. path)
    else
        print("Failed to save: " .. path)
    end
end

local function generateAll()
    print("Starting batch template generation...")
    
    -- 1. Play Cards (512x640)
    local cards = {
        "card_hb_dive", "card_hb_stretch", "card_inside_zone", "card_quick_slant",
        "card_drag_route", "card_mesh", "card_dig_route", "card_out_route",
        "card_four_verticals", "card_pa_crossers", "card_hail_mary", "card_flea_flicker",
        "card_screen_pass", "card_field_goal"
    }
    for _, name in ipairs(cards) do
        generateImage("assets/images/cards/" .. name .. ".png", 512, 640, name:upper():gsub("_", " "), {0.1, 0.2, 0.4}, {0.8, 0.9, 1.0})
    end
    
    -- 2. Defensive Blinds (256x256)
    local blinds = {
        "blind_standard", "blind_blitz", "blind_cover2", "blind_goal_line",
        "blind_weather_rain", "blind_boss_championship"
    }
    for _, name in ipairs(blinds) do
        generateImage("assets/images/blinds/" .. name .. ".png", 256, 256, name:upper():gsub("_", " "), {0.4, 0.1, 0.1}, {1.0, 0.8, 0.8})
    end
    
    -- 3. Stadiums (1920x1080)
    local stadiums = {
        "stadium_default", "stadium_snow", "stadium_dome"
    }
    for _, name in ipairs(stadiums) do
        generateImage("assets/images/stadiums/" .. name .. ".png", 1920, 1080, name:upper():gsub("_", " "), {0.1, 0.3, 0.1}, {1.0, 1.0, 1.0})
    end
    
    -- 4. UI Elements
    generateImage("assets/images/ui/ui_logo.png", 1024, 512, "CHAIN GAIN LOGO", {0.1, 0.1, 0.1, 0.5}, {1, 0.8, 0})
    generateImage("assets/images/ui/ui_cap_coin.png", 128, 128, "COIN", {0.8, 0.6, 0}, {1, 1, 1})
    generateImage("assets/images/ui/ui_audible_icon.png", 128, 128, "AUDIBLE", {0.8, 0.2, 0.2}, {1, 1, 1})
    generateImage("assets/images/ui/ui_down_marker.png", 128, 128, "DOWN", {0.2, 0.2, 0.2}, {1, 0.5, 0})
    
    print("Batch generation complete!")
end

return generateAll
