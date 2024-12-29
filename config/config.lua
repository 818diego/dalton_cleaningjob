Config = {}

-- Pago
Config.PaymentMin = 5   -- Pago mínimo por auto limpiado
Config.PaymentMax = 30  -- Pago máximo por auto limpiado
Config.BonusMin = 50    -- Bono mínimo por cada 10 autos
Config.BonusMax = 300   -- Bono máximo por cada 10 autos
Config.CarsToClean = 10 -- Número de autos para bono adicional

Config.JobNPC = {
    model = 's_m_y_garbage',               -- Modelo del NPC
    coords = vec3(-348.76, -772.78, 33.97), -- Coordenadas
    heading = 270.0                        -- Dirección
}

Config.JobBlip = {
    enabled = true,         -- Mostrar o no el blip
    sprite = 318,           -- Icono del blip (ver: https://docs.fivem.net/docs/game-references/blips/)
    color = 2,              -- Color del blip (ver: https://docs.fivem.net/docs/game-references/blips/)
    scale = 0.8,            -- Tamaño del blip
    label = "Limpia Autos" -- Nombre que se mostrará en el mapa
}

Config.VehicleDistance = 3.0 -- Distancia para activar la interacción

Config.WorkClothes = {
    male = {
        ['tshirt_1'] = 15, ['tshirt_2'] = 0,
        ['torso_1'] = 65, ['torso_2'] = 0,
        ['arms'] = 0,
        ['pants_1'] = 38, ['pants_2'] = 0,
        ['shoes_1'] = 12, ['shoes_2'] = 0,
        ['chain_1'] = 0, ['chain_2'] = 0
    },
    female = {
        ['tshirt_1'] = 15, ['tshirt_2'] = 0,
        ['torso_1'] = 59, ['torso_2'] = 0,
        ['arms'] = 0,
        ['pants_1'] = 38, ['pants_2'] = 0,
        ['shoes_1'] = 12, ['shoes_2'] = 0,
        ['chain_1'] = 0, ['chain_2'] = 0
    }
}
