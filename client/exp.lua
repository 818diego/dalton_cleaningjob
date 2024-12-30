local config = require('config/config')

-- Returns player data from server
--- @param type any
local function GetPlayerData(type)
    return lib.callback.await('dalton_cleaning:getplayerdata', false, type)
end

-- Register export(s)
exports('GetPlayerData', GetPlayerData)
