-- src/engine/steam_manager.lua
local SteamManager = {}

SteamManager.initialized = false
SteamManager.steam = nil

function SteamManager.init()
    local ok, luasteam = pcall(require, "luasteam")

    if ok then
        SteamManager.steam = luasteam
        SteamManager.is_mock = false
        SteamManager.initialized = SteamManager.steam.init()
        print("[STEAM] Steamworks API successfully initialized!")
    else
        -- Fallback mode for local dev & headless bot simulations
        SteamManager.is_mock = true
        SteamManager.initialized = true -- treat as initialized so calls don't crash
        print("[SteamManager] luasteam binaries not found. Running in Mock Mode.")
    end
end

function SteamManager.update()
    if SteamManager.initialized and SteamManager.steam then
        SteamManager.steam.runCallbacks()
    end
end

function SteamManager.unlockAchievement(achId)
    if SteamManager.is_mock then
        print("[STEAM MOCK] Achievement unlocked: " .. achId)
        return
    end
    
    if SteamManager.initialized and SteamManager.steam then
        local userStats = SteamManager.steam.userStats
        if userStats then
            userStats.setAchievement(achId)
            userStats.storeStats()
            print("[STEAM] Achievement unlocked: " .. achId)
        end
    end
end

function SteamManager.syncCloudSave(filename, content)
    if SteamManager.is_mock then
        print("[STEAM MOCK] Cloud save synced: " .. filename)
        return
    end
    
    if SteamManager.initialized and SteamManager.steam then
        local remoteStorage = SteamManager.steam.remoteStorage
        if remoteStorage then
            remoteStorage.fileWrite(filename, content)
            print("[STEAM] Cloud save synced: " .. filename)
        end
    end
end

function SteamManager.shutdown()
    if SteamManager.initialized and SteamManager.steam then
        SteamManager.steam.shutdown()
    end
end

return SteamManager
