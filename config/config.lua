Config = {}

-- Payment
Config.PaymentMin = 5   -- Minimum payment per cleaned car
Config.PaymentMax = 30  -- Maximum payment per cleaned car
Config.BonusMin = 50    -- Minimum bonus for every 10 cars
Config.BonusMax = 300   -- Maximum bonus for every 10 cars
Config.CarsToClean = 10 -- Number of cars for additional bonus

Config.JobNPC = {
    model = 's_m_y_garbage',                -- NPC model
    coords = vec3(-348.76, -772.78, 33.97), -- Coordinates
    heading = 270.0                         -- Heading
}

Config.JobBlip = {
    enabled = true,        -- Show blip or not
    sprite = 318,          -- Blip icon (see: https://docs.fivem.net/docs/game-references/blips/)
    color = 2,             -- Blip color (see: https://docs.fivem.net/docs/game-references/blips/)
    scale = 0.8,           -- Blip size
    label = "Car Cleaning" -- Name shown on the map
}

Config.VehicleDistance = 3.0 -- Distance to activate interaction

Config.Language = 'en'       -- Default language ('en' for English, 'es' for Spanish)

Config.WorkClothes = {
    male = {
        ['tshirt_1'] = 15,
        ['tshirt_2'] = 0,
        ['torso_1'] = 65,
        ['torso_2'] = 0,
        ['arms'] = 0,
        ['pants_1'] = 38,
        ['pants_2'] = 0,
        ['shoes_1'] = 12,
        ['shoes_2'] = 0,
        ['chain_1'] = 0,
        ['chain_2'] = 0
    },
    female = {
        ['tshirt_1'] = 15,
        ['tshirt_2'] = 0,
        ['torso_1'] = 59,
        ['torso_2'] = 0,
        ['arms'] = 0,
        ['pants_1'] = 38,
        ['pants_2'] = 0,
        ['shoes_1'] = 12,
        ['shoes_2'] = 0,
        ['chain_1'] = 0,
        ['chain_2'] = 0
    }
}
