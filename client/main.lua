local Locales = require('client/locales')
local cleanedCars = 0      -- Cars cleaned in current job
local totalCleanedCars = 0 -- Total cars cleaned
local currentJob = false
local jobNPC = nil         -- Job NPC entity
local cleanedVehicles = {} -- Cleaned vehicles List
local totalPayment = 0     -- Total payment for current job
local savedClothes = {}    -- Saved clothes for player
local wasInJob = false     -- Was player in job before death
local bucketPlaced = false -- state of the bucket
local bucketEntity = nil   -- entity of the bucket
local isWetted = false     -- state of the sponge
local hasBucket = false    -- state of the bucket
local bucketProp = nil     -- Bucket prop entity
local currentLang = Config.Language
Locales.LoadLocale(currentLang)

-- Threads
CreateThread(function()
    RequestModel(GetHashKey(Config.JobNPC.model))
    while not HasModelLoaded(GetHashKey(Config.JobNPC.model)) do
        Wait(0)
    end

    -- create job NPC
    jobNPC = CreatePed(4, GetHashKey(Config.JobNPC.model), Config.JobNPC.coords.x, Config.JobNPC.coords.y,
        Config.JobNPC.coords.z - 1.0, Config.JobNPC.heading, false, true)
    SetEntityInvincible(jobNPC, true)
    FreezeEntityPosition(jobNPC, true)
    SetBlockingOfNonTemporaryEvents(jobNPC, true)

    -- create blip
    if Config.JobBlip.enabled then
        local blip = AddBlipForCoord(Config.JobNPC.coords.x, Config.JobNPC.coords.y, Config.JobNPC.coords.z)
        SetBlipSprite(blip, Config.JobBlip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.JobBlip.scale)
        SetBlipColour(blip, Config.JobBlip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.JobBlip.label)
        EndTextCommandSetBlipName(blip)
    end

    UpdateJobTarget()
end)

CreateThread(function()
    while true do
        Wait(25)
        if hasBucket and not bucketPlaced and IsControlJustReleased(0, 38) then     -- 'E' key
            PlaceBucket()
        elseif not hasBucket and bucketPlaced and IsControlJustReleased(0, 38) then -- 'E' key
            lib.notify({
                title = Locales._U('job_title'),
                description = Locales._U('press_e_to_pickup'),
                type = 'inform',
                duration = 6000
            })
        end
    end
end)

-- Functions for job
function UpdateJobTarget()
    exports.ox_target:removeLocalEntity(jobNPC, { 'startCleaning', 'endCleaning' })

    local options = {}

    -- Start job
    if not currentJob then
        table.insert(options, {
            name = 'startCleaning',
            label = Locales._U('start_job'),
            icon = 'fas fa-broom',
            onSelect = function()
                StartCleaningJob()
                UpdateJobTarget()
            end
        })
    end

    -- End job
    if currentJob then
        table.insert(options, {
            name = 'endCleaning',
            label = Locales._U('end_job'),
            icon = 'fas fa-handshake',
            onSelect = function()
                EndCleaningJob()
                UpdateJobTarget()
            end
        })
    end

    exports.ox_target:addLocalEntity(jobNPC, options)
end

function TakeBucket()
    if hasBucket then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('already_have_bucket'),
            type = 'warning',
            duration = 6000
        })
        return
    end

    hasBucket = true

    -- Attach bucket prop to player
    local playerPed = PlayerPedId()
    local propModel = `ba_prop_battle_ice_bucket`
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do
        Wait(10)
    end

    bucketProp = CreateObject(propModel, 0, 0, 0, true, true, true)
    AttachEntityToEntity(bucketProp, playerPed, GetPedBoneIndex(playerPed, 57005), 0.37, 0.01, -0.05, 0.0, 280.0, 53.0,
        true, true, false, true, 1, true)

    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('bucket_taken'),
        type = 'success',
        duration = 6000
    })
end

function StartCleaningJob()
    if currentJob then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('already_started'),
            type = 'inform',
            duration = 6000
        })
        return
    end

    local playerPed = PlayerPedId()
    local gender = GetEntityModel(playerPed) == GetHashKey("mp_m_freemode_01") and "male" or "female"
    local clothes = Config.WorkClothes[gender]

    -- Guardar ropa actual
    originalClothes = {
        tshirt_1 = GetPedDrawableVariation(playerPed, 8),
        tshirt_2 = GetPedTextureVariation(playerPed, 8),
        torso_1 = GetPedDrawableVariation(playerPed, 11),
        torso_2 = GetPedTextureVariation(playerPed, 11),
        arms = GetPedDrawableVariation(playerPed, 3),
        pants_1 = GetPedDrawableVariation(playerPed, 4),
        pants_2 = GetPedTextureVariation(playerPed, 4),
        shoes_1 = GetPedDrawableVariation(playerPed, 6),
        shoes_2 = GetPedTextureVariation(playerPed, 6),
        chain_1 = GetPedDrawableVariation(playerPed, 7),
        chain_2 = GetPedTextureVariation(playerPed, 7)
    }

    -- Cambiar a ropa de trabajo
    SetPedComponentVariation(playerPed, 8, clothes['tshirt_1'], clothes['tshirt_2'], 2)
    SetPedComponentVariation(playerPed, 11, clothes['torso_1'], clothes['torso_2'], 2)
    SetPedComponentVariation(playerPed, 3, clothes['arms'], 0, 2)
    SetPedComponentVariation(playerPed, 4, clothes['pants_1'], clothes['pants_2'], 2)
    SetPedComponentVariation(playerPed, 6, clothes['shoes_1'], clothes['shoes_2'], 2)
    SetPedComponentVariation(playerPed, 7, clothes['chain_1'], clothes['chain_2'], 2)

    currentJob = true
    cleanedCars = 0
    totalPayment = 0
    cleanedVehicles = {}
    bucketPlaced = false -- Reinicia el estado de la cubeta
    isWetted = false     -- Reinicia el estado de la esponja

    -- Take bucket
    TakeBucket()

    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('place_bucket'),
        type = 'inform',
        duration = 6000
    })

    UpdateVehicleTarget()
end

function PlaceBucket()
    if bucketPlaced then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('bucket_already_placed'),
            type = 'warning',
            duration = 6000
        })
        return
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    -- Remove bucket prop from player
    DetachEntity(bucketProp, true, false)
    DeleteEntity(bucketProp)
    bucketProp = nil

    -- Create bucket entity on ground
    RequestModel(`ba_prop_battle_ice_bucket`)
    while not HasModelLoaded(`ba_prop_battle_ice_bucket`) do
        Wait(10)
    end

    bucketEntity = CreateObject(`ba_prop_battle_ice_bucket`, coords.x, coords.y, coords.z - 1.0, true, true, true)
    PlaceObjectOnGroundProperly(bucketEntity)
    FreezeEntityPosition(bucketEntity, true)

    bucketPlaced = true
    hasBucket = false

    -- Animation for placing the bucket
    TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
    Wait(2000)
    ClearPedTasks(playerPed)

    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('bucket_placed'),
        type = 'success',
        duration = 6000
    })

    UpdateBucketTarget()
end

function PickUpBucket()
    if not bucketPlaced then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('no_bucket_to_pickup'),
            type = 'error',
            duration = 6000
        })
        return
    end

    -- Remove bucket entity from ground
    DeleteEntity(bucketEntity)
    bucketPlaced = false
    bucketEntity = nil

    -- Attach bucket prop to player
    local playerPed = PlayerPedId()
    local propModel = `ba_prop_battle_ice_bucket`
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do
        Wait(10)
    end

    bucketProp = CreateObject(propModel, 0, 0, 0, true, true, true)
    AttachEntityToEntity(bucketProp, playerPed, GetPedBoneIndex(playerPed, 57005), 0.37, 0.01, -0.05, 0.0, 280.0, 53.0,
        true, true, false, true, 1, true)

    hasBucket = true
    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('bucket_picked_up'),
        type = 'success',
        duration = 6000
    })
end

function WetSponge()
    if not bucketPlaced then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('no_bucket'),
            type = 'error',
            duration = 6000
        })
        return
    end

    -- Verifica si el jugador está cerca de la cubeta
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local bucketCoords = GetEntityCoords(bucketEntity)
    local distance = #(playerCoords - bucketCoords)

    if distance > 2.0 then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('too_far_bucket'),
            type = 'error',
            duration = 6000
        })
        return
    end

    -- Mojar la esponja
    isWetted = true
    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('sponge_wetted'),
        type = 'success',
        duration = 6000
    })
end

function EndCleaningJob(isForced)
    if not currentJob then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('no_active_job'),
            type = 'error',
            duration = 6000
        })
        return
    end

    local playerPed = PlayerPedId()
    SetPedComponentVariation(playerPed, 8, originalClothes['tshirt_1'], originalClothes['tshirt_2'], 2) -- Camiseta
    SetPedComponentVariation(playerPed, 11, originalClothes['torso_1'], originalClothes['torso_2'], 2)  -- Torso
    SetPedComponentVariation(playerPed, 3, originalClothes['arms'], 0, 2)                               -- Brazos
    SetPedComponentVariation(playerPed, 4, originalClothes['pants_1'], originalClothes['pants_2'], 2)   -- Pantalones
    SetPedComponentVariation(playerPed, 6, originalClothes['shoes_1'], originalClothes['shoes_2'], 2)   -- Zapatos
    SetPedComponentVariation(playerPed, 7, originalClothes['chain_1'], originalClothes['chain_2'], 2)   -- Cadena

    if not isForced then
        if cleanedCars > 0 then
            if cleanedCars >= Config.CarsToClean then
                local bonus = math.random(Config.BonusMin, Config.BonusMax)
                totalPayment = totalPayment + bonus
                lib.notify({
                    title = Locales._U('job_title'),
                    description = Locales._U('end_job_bonus', { count = cleanedCars, bonus = bonus }),
                    type = 'success',
                    duration = 6000
                })
            else
                lib.notify({
                    title = Locales._U('job_title'),
                    description = Locales._U('end_job_no_bonus', { count = cleanedCars }),
                    type = 'success',
                    duration = 6000
                })
            end
            TriggerServerEvent('cleaningjob:payPlayer', totalPayment)
        else
            lib.notify({
                title = Locales._U('job_title'),
                description = Locales._U('no_vehicles_cleaned'),
                type = 'error',
                duration = 6000
            })
        end
    else
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('disconnected_job'),
            type = 'warning',
            duration = 6000
        })
    end

    -- Remove bucket prop if still attached
    if bucketProp then
        DetachEntity(bucketProp, true, false)
        DeleteEntity(bucketProp)
        bucketProp = nil
    end

    -- restart values
    currentJob = false
    cleanedCars = 0
    totalPayment = 0
    cleanedVehicles = {}
    hasBucket = false -- Reset bucket state
    UpdateVehicleTarget()
end

function IsVehicleDirty(vehicle)
    local dirtLevel = GetVehicleDirtLevel(vehicle)
    return dirtLevel > 0.5
end

function EnsureEntityControl(entity)
    if not NetworkHasControlOfEntity(entity) then
        NetworkRequestControlOfEntity(entity)
        local timeout = 0
        while not NetworkHasControlOfEntity(entity) and timeout < 500 do
            Wait(10)
            timeout = timeout + 10
        end
    end
end

function CleanVehicle(vehicle)
    if not currentJob then
        lib.notify({ title = Locales._U('job_title'), description = Locales._U('start_job_first'), type = 'error', duration = 6000 })
        return
    end

    if not isWetted then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('sponge_dry'),
            type = 'error',
            duration = 6000
        })
        return
    end

    local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)
    if cleanedVehicles[vehicleId] then
        lib.notify({ title = Locales._U('job_title'), description = Locales._U('vehicle_already_clean'), type = 'warning', duration = 6000 })
        return
    end

    if IsEntityDead(vehicle) then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('vehicle_exploded'),
            type = 'warning',
            duration = 6000
        })
        return
    end

    if not IsVehicleDirty(vehicle) then
        lib.notify({ title = Locales._U('job_title'), description = Locales._U('vehicle_already_clean'), type = 'warning', duration = 6000 })
        return
    end

    EnsureEntityControl(vehicle)

    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true) -- Freeze player for dont move while cleaning

    -- loading prop for animation cleaning
    local propModel = `prop_sponge_01`
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do
        Wait(10)
    end

    local prop = CreateObject(propModel, 0, 0, 0, true, true, true)
    AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, 57005), 0.12, 0.0, 0.0, 0.0, 270.0, 0.0, true, true,
        false, true, 1, true)

    local success = lib.progressCircle({
        duration = 5000, -- Tiempo reducido por cada parte
        label = Locales._U('cleaning_vehicle'),
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            combat = true
        },
        anim = {
            dict = 'amb@world_human_maid_clean@base',
            clip = 'base'
        }
    })
    if success then
        SetVehicleDirtLevel(vehicle, 0.0) -- Clean view
        cleanedVehicles[vehicleId] = true -- Mark as cleaned

        local payment = math.random(Config.PaymentMin, Config.PaymentMax)
        totalPayment = totalPayment + payment
        cleanedCars = cleanedCars + 1
        totalCleanedCars = totalCleanedCars + 1

        -- Secar la esponja después de limpiar
        isWetted = false

        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('vehicle_cleaned',
                { current = cleanedCars, target = Config.CarsToClean, total = totalCleanedCars }),
            type = 'inform',
            duration = 6000
        })
    end

    -- remove propId
    DetachEntity(prop, true, false)
    DeleteEntity(prop)
    SetModelAsNoLongerNeeded(propModel)

    FreezeEntityPosition(playerPed, false) -- Unfreeze player
end

function UpdateVehicleTarget()
    exports.ox_target:removeGlobalVehicle({ 'cleanVehicle' })

    if currentJob then
        exports.ox_target:addGlobalVehicle({
            {
                name = 'cleanVehicle',
                label = Locales._U('clean_vehicle'),
                icon = 'fas fa-soap',
                distance = Config.VehicleDistance,
                canInteract = function(entity, distance, data)
                    return IsVehicleStopped(entity)
                end,
                onSelect = function(data)
                    CleanVehicle(data.entity)
                end
            }
        }, Config.VehicleDistance)
    end
end

function UpdateBucketTarget()
    if bucketPlaced and bucketEntity then
        exports.ox_target:addLocalEntity(bucketEntity, {
            {
                name = 'wetSponge',
                label = Locales._U('wet_sponge'),
                icon = 'fas fa-tint',
                onSelect = function()
                    WetSponge()
                end
            },
            {
                name = 'pickUpBucket',
                label = Locales._U('pick_up_bucket'),
                icon = 'fas fa-hand-paper',
                onSelect = function()
                    PickUpBucket()
                end
            }
        })
    end
end

function ReturnBucket()
    if not hasBucket then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('no_bucket_to_return'),
            type = 'error',
            duration = 6000
        })
        return
    end

    -- Elimina el objeto cubeta si estaba en el suelo
    if bucketPlaced and bucketEntity then
        DeleteEntity(bucketEntity)
        bucketPlaced = false
        bucketEntity = nil
    end

    -- Remove bucket prop if still attached
    if bucketProp then
        DetachEntity(bucketProp, true, false)
        DeleteEntity(bucketProp)
        bucketProp = nil
    end

    hasBucket = false
    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('bucket_returned'),
        type = 'success',
        duration = 6000
    })
end

-- Events
AddEventHandler('playerDropped', function(reason)
    if currentJob then
        wasInJob = true                -- Mark to player was in job before disconnect
        savedClothes = originalClothes -- Save clothes for player
        EndCleaningJob(true)           -- End job
    end
end)

AddEventHandler('playerSpawned', function()
    if wasInJob then
        local playerPed = PlayerPedId()
        SetPedComponentVariation(playerPed, 8, savedClothes['tshirt_1'], savedClothes['tshirt_2'], 2)
        SetPedComponentVariation(playerPed, 11, savedClothes['torso_1'], savedClothes['torso_2'], 2)
        SetPedComponentVariation(playerPed, 3, savedClothes['arms'], 0, 2)
        SetPedComponentVariation(playerPed, 4, savedClothes['pants_1'], savedClothes['pants_2'], 2)
        SetPedComponentVariation(playerPed, 6, savedClothes['shoes_1'], savedClothes['shoes_2'], 2)
        SetPedComponentVariation(playerPed, 7, savedClothes['chain_1'], savedClothes['chain_2'], 2)

        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('disconnected_job'),
            type = 'warning',
            duration = 6000
        })

        wasInJob = false
        savedClothes = {}
    end
end)
