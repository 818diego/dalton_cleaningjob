Config = {}

-- Payment
Config.PaymentMin = 5   -- Minimum payment per cleaned car
Config.PaymentMax = 30  -- Maximum payment per cleaned car
Config.BonusMin = 50    -- Minimum bonus for every 10 cars
Config.BonusMax = 300   -- Maximum bonus for every 10 cars
Config.CarsToClean = 10 -- Number of cars for additional bonus

-- Job NPC configuration
Config.JobNPC = {
    model = 'a_m_y_vinewood_01',               -- NPC model
    coords = vec3(-826.82, -731.6, 28.05), -- Coordinates
    heading = 180.0                        -- Heading
}

-- Job blip configurations
Config.JobBlip = {
    enabled = true,            -- Show blip or not
    sprite = 672,              -- Blip icon (see: https://docs.fivem.net/docs/game-references/blips/)
    color = 25,                 -- Blip color (see: https://docs.fivem.net/docs/game-references/blips/)
    scale = 0.8,               -- Blip size
    label = "Car Cleaning Job" -- Name shown on the map
}

Config.VehicleDistance = 1.0 -- Distance to activate interaction

Config.Language = 'es'       -- Default language ('en' for English, 'es' for Spanish)

Config.WorkClothes = {       -- configured clothes for the jobs
    male = {
        ['tshirt_1'] = 15,   -- T-shirt model
        ['tshirt_2'] = 0,    -- T-shirt texture/variation
        ['torso_1'] = 65,    -- Torso model
        ['torso_2'] = 0,     -- Torso texture/variation
        ['arms'] = 0,        -- Arms model
        ['pants_1'] = 38,    -- Pants model
        ['pants_2'] = 0,     -- Pants texture/variation
        ['shoes_1'] = 12,    -- Shoes model
        ['shoes_2'] = 0,     -- Shoes texture/variation
        ['chain_1'] = 0,     -- Chain/Accessory model
        ['chain_2'] = 0      -- Chain/Accessory texture/variation
    },
    female = {
        ['tshirt_1'] = 15, -- T-shirt model
        ['tshirt_2'] = 0,  -- T-shirt texture/variation
        ['torso_1'] = 59,  -- Torso model
        ['torso_2'] = 0,   -- Torso texture/variation
        ['arms'] = 0,      -- Arms model
        ['pants_1'] = 38,  -- Pants model
        ['pants_2'] = 0,   -- Pants texture/variation
        ['shoes_1'] = 24,  -- Shoes model
        ['shoes_2'] = 0,   -- Shoes texture/variation
        ['chain_1'] = 0,   -- Chain/Accessory model
        ['chain_2'] = 0    -- Chain/Accessory texture/variation
    }
}
