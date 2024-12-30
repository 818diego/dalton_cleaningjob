local locales = {
    en = json.decode(LoadResourceFile(GetCurrentResourceName(), 'locales/en.json')),
    es = json.decode(LoadResourceFile(GetCurrentResourceName(), 'locales/es.json'))
}

local function translate(lang, key, params)
    local text = locales[lang][key] or key
    if params then
        for k, v in pairs(params) do
            text = text:gsub('{' .. k .. '}', v)
        end
    end
    return text
end

RegisterNetEvent('cleaningjob:payPlayer')
AddEventHandler('cleaningjob:payPlayer', function(amount)
    local src = source
    local xPlayer = exports.qbx_core:GetSource(src)
    local lang = Config.Language
    -- add money to player
    exports.ox_inventory:AddItem(src, 'money', amount)

    TriggerClientEvent('ox_lib:notify', src, {
        title = translate(lang, 'job_title'),
        description = translate(lang, 'payment_received', { amount = amount }),
        type = 'success'
    })
end)
