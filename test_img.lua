local status, err = pcall(function()
    require("love.image")
    local imgData = love.image.newImageData("assets/sprites/player_home.png")
    local w, h = imgData:getDimensions()
    print("Dimensions: " .. w .. "x" .. h)
    
    local startTime = os.clock()
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local r, g, b, a = imgData:getPixel(x, y)
            -- simulate basic operations
            local max = math.max(r, g, b)
        end
    end
    print("Time taken: " .. (os.clock() - startTime))
end)
if not status then print("Error: " .. err) end
