local oxmysql = exports.oxmysql

RegisterNetEvent('cleaningjob:payPlayer')
AddEventHandler('cleaningjob:payPlayer', function(amount)
    local src = source
    local xPlayer = exports.qbx_core:GetSource(src)
    -- add money to player
    exports.ox_inventory:AddItem(src, 'money', amount)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Trabajo de limpieza',
        description = string.format('¡Recibiste $%d por limpiar autos!', amount),
        type = 'success'
    })
end)

