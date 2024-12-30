-- Ensure proper seeding of math.random()
math.randomseed(os.time())
-- Initialize table to store player data
local cache = {}

-- Auto-inject SQL if needed
local sql = LoadResourceFile(GetCurrentResourceName(), 'dalton_cleaning.sql')
if sql then MySQL.query(sql) end

-- Function to get player identifier
local function GetIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    return identifiers[1] -- Assuming the first identifier is the one we need
end

-- Function to get player name
local function GetName(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
end

-- Insert new player into database
--- @param source number
local function InsertPlayer(source)
    if not source then return end
    local identifier = GetIdentifier(source)
    if not identifier then return end
    local query = [[
        INSERT INTO `dalton_cleaning`
        (identifier, name, level, exp, cleaning_total)
        VALUES (?, ?, ?, ?, ?)
    ]]
    MySQL.insert(query, { identifier, GetName(source), 1, 0, 0 })
    cache[identifier] = {
        identifier = identifier,
        name = GetName(source),
        level = 1,
        exp = 0,
        cleaning_total = 0
    }
    return cache[identifier]
end

-- Returns player data from dalton_cleaning table
---@param source number
---@param type string|nil
local function GetPlayerData(source, type)
    if not source then return end
    local identifier = GetIdentifier(source)
    if not identifier then return end
    local data = cache[identifier]
    if not data then
        local query = [[ SELECT * FROM `dalton_cleaning` WHERE `identifier` = ? ]]
        local player = MySQL.query.await(query, { identifier })
        if player and #player > 0 then
            data = player[1]
            cache[identifier] = data
        else
            data = InsertPlayer(source)
            if not data then
                return
            end
        end
    end
    if type then
        return data[type]
    end
    return data
end

-- Modify player data
--- @param source number
--- @param dataType string
--- @param amount number
local function AddPlayerData(source, dataType, amount)
    if not source or not amount or not dataType or type(amount) ~= 'number' or type(dataType) ~= 'string' then return end
    if amount <= 0 then return end
    local identifier = GetIdentifier(source)
    local data = identifier and GetPlayerData(source)
    if not identifier or not data then return end
    if dataType == 'exp' then
        local newExp = data.exp + amount
        while Config.experience[data.level + 1] and newExp >= Config.experience[data.level + 1] do
            data.level = data.level + 1
            data.level = data.level + 1
        end
        if data.level > #Config.experience then
            data.level = #Config.experience
        end
        cache[identifier].level = data.level
        cache[identifier].exp = newExp
    elseif dataType == 'cleaning_total' then
        cache[identifier].cleaning_total = (cache[identifier].cleaning_total or 0) + amount
    else
        cache[identifier][dataType] = (cache[identifier][dataType] or 0) + amount
    end
end

-- Save player data to database
--- @param identifier string
local function SavePlayerData(identifier)
    if not identifier then return end
    local data = cache[identifier]
    if not data then return end
    local query = [[
        UPDATE `dalton_cleaning`
        SET `level` = ?, `exp` = ?, `cleaning_total` = ?
        WHERE `identifier` = ?
    ]]
    MySQL.update(query, { data.level, data.exp, data.cleaning_total, identifier })
    if cache[identifier] then cache[identifier] = nil end
end

-- Fetch the top players by xp
--- @return table
local function GetTopPlayers()
    local query = [[
        SELECT name, level, exp, cleaning_total
        FROM `dalton_cleaning`
        ORDER BY exp DESC
        LIMIT 10
    ]]
    local result = MySQL.query.await(query)
    local players = {}
    if result and #result > 0 then
        for _, player in ipairs(result) do
            players[#players + 1] = {
                name = player.name or 'Unknown',
                level = player.level or 1,
                exp = player.exp or 0,
                cleaning_total = player.cleaning_total or 0
            }
        end
    end
    return players
end

-- Register a callback for client-side requests
lib.callback.register('dalton_cleaning:gettopplayers', function()
    return GetTopPlayers()
end)

-- Callback used to return players data from dalton_cleaning
--- @param source number
--- @param type string|nil
lib.callback.register('dalton_cleaning:getplayerdata', function(source, type)
    return GetPlayerData(source, type)
end)

-- Event handler to update database for all players in cache on resource stop
--- @param resourceName string
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for identifier, _ in pairs(cache) do
        SavePlayerData(identifier)
    end
end)

-- Event handler to save all players data on server restart/shutdown
AddEventHandler('txAdmin:events:serverShuttingDown', function()
    for identifier, _ in pairs(cache) do
        SavePlayerData(identifier)
    end
end)

-- Event handler to update database with a single players data upon disconnect
AddEventHandler('playerDropped', function()
    if not source then return end
    local source = source
    local identifier = GetIdentifier(source)
    if not identifier then return end
    SavePlayerData(identifier)
end)

-- Define a translate function for server-side localization
local function translate(lang, key, params)
    local file = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. lang .. '.json')
    if file then
        local Lang = json.decode(file)
        local text = Lang[key] or key
        if params then
            for k, v in pairs(params) do
                text = text:gsub('{' .. k .. '}', v)
            end
        end
        return text
    else
        return key
    end
end

RegisterNetEvent('cleaningjob:cleanedVehicle')
AddEventHandler('cleaningjob:cleanedVehicle', function(payment, randomExp)
    local src = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    -- Add experience points and increment total cleaned cars
    AddPlayerData(src, 'exp', randomExp)
    AddPlayerData(src, 'cleaning_total', 1)

    -- Notify the player
    TriggerClientEvent('ox_lib:notify', src, {
        title = translate(Config.Language, 'job_title'),
        description = translate(Config.Language, 'exp_gained', { amount = randomExp }),
        type = 'success'
    })
end)

-- Register export(s)
exports('GetPlayerData', GetPlayerData) -- returns player data from dalton_cleaning table (params: source, type) (type param optional)
exports('AddPlayerData', AddPlayerData) -- edit player data in dalton_cleaning table (params: source, type, amount)

