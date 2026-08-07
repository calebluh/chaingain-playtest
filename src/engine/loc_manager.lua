-- src/engine/loc_manager.lua

local Loc = {}

Loc.currentLanguage = "en"
Loc.dictionary = {}

function Loc.init(lang)
    Loc.currentLanguage = lang or "en"
    local status, dict = pcall(require, "src.data.locales." .. Loc.currentLanguage)
    if status and dict then
        Loc.dictionary = dict
    else
        Loc.dictionary = require("src.data.locales.en")
    end
end

function Loc.get(key, params)
    local str = Loc.dictionary[key] or key
    if params then
        if type(params) == "table" then
            str = string.format(str, unpack(params))
        else
            str = string.format(str, params)
        end
    end
    return str
end

Loc.init("en")

return Loc
