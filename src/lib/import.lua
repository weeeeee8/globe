local IMPORT_CACHE = {}

local function import(asset)
    if IMPORT_CACHE[asset] then
        return IMPORT_CACHE[asset]
    end

    if asset:find("rbxassetid://") then
        local e = game:GetObjects(asset)[1]
        IMPORT_CACHE[asset] = e
        return e
    else
        local src = loadstring(
            game:HttpGet('https://raw.githubusercontent.com/weeeeee8/globe/main/src' .. asset .. '.lua')
        )()
        IMPORT_CACHE[asset] = src
        return src
    end
end

return import