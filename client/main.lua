local Locales = require('client/locales')
local cleanedCars = 0      -- Cars cleaned in current job
local totalCleanedCars = 0 -- Total cars cleaned
local currentJob = false   -- Current job state
local jobNPC = nil         -- Job NPC entity
local cleanedVehicles = {} -- Cleaned vehicles List
local totalPayment = 0     -- Total payment for current job
local savedClothes = {}    -- Saved clothes for player
local wasInJob = false     -- Was player in job before death
local bucketEntity = nil   -- entity of the bucket
local bucketProp = nil     -- Bucket prop entity
local currentLang = Config.Language
Locales.LoadLocale(currentLang)
local BUCKET_STATE = {
    NOT_PLACED = 1,
    PLACED = 2
}
local SPONGE_STATE = {
    DRY = 1,
    WET = 2
}
local bucketState = BUCKET_STATE.NOT_PLACED
local spongeState = SPONGE_STATE.DRY
local hasBucket = false

-- Threads
CreateThread(function()
    RequestModel(Config.JobNPC.model)
    while not HasModelLoaded(Config.JobNPC.model) do
        Wait(0)
    end
    -- create job NPC
    jobNPC = CreatePed(4, Config.JobNPC.model, Config.JobNPC.coords.x, Config.JobNPC.coords.y,
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
    updateJobTarget()
end)

CreateThread(function()
    while true do
        Wait(25)
        if hasBucket and bucketState == BUCKET_STATE.NOT_PLACED and IsControlJustReleased(0, 38) then     -- 'E' key
            placeBucket()
        elseif not hasBucket and bucketState == BUCKET_STATE.PLACED and IsControlJustReleased(0, 38) then -- 'E' key
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
function startCleaningJob()
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
    local gender = GetEntityModel(playerPed) == `mp_m_freemode_01` and "male" or "female"
    local clothes = Config.WorkClothes[gender]
    -- Save Clothes
    originalClothes = {
        GetPedDrawableVariation(playerPed, 8),
        GetPedTextureVariation(playerPed, 8),
        GetPedDrawableVariation(playerPed, 11),
        GetPedTextureVariation(playerPed, 11),
        GetPedDrawableVariation(playerPed, 3),
        GetPedDrawableVariation(playerPed, 4),
        GetPedTextureVariation(playerPed, 4),
        GetPedDrawableVariation(playerPed, 6),
        GetPedTextureVariation(playerPed, 6),
        GetPedDrawableVariation(playerPed, 7),
        GetPedTextureVariation(playerPed, 7)
    }
    -- Change Clothes for job
    SetPedComponentVariation(playerPed, 8, clothes.tshirt_1, clothes.tshirt_2, 2)
    SetPedComponentVariation(playerPed, 11, clothes.torso_1, clothes.torso_2, 2)
    SetPedComponentVariation(playerPed, 3, clothes.arms, 0, 2)
    SetPedComponentVariation(playerPed, 4, clothes.pants_1, clothes.pants_2, 2)
    SetPedComponentVariation(playerPed, 6, clothes.shoes_1, clothes.shoes_2, 2)
    SetPedComponentVariation(playerPed, 7, clothes.chain_1, clothes.chain_2, 2)

    currentJob = true
    cleanedCars = 0
    totalPayment = 0
    cleanedVehicles = {}
    bucketState = BUCKET_STATE.NOT_PLACED -- Reset bucket state
    spongeState = SPONGE_STATE.DRY        -- Reset sponge state
    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('take_bucket'),
        type = 'inform',
        duration = 6000
    })
    updateVehicleTarget()
    updateContextMenu()
end

function placeBucket()
    if bucketState == BUCKET_STATE.PLACED then
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

    bucketState = BUCKET_STATE.PLACED
    hasBucket = false

    -- Animation for placing the bucket
    Wait(2000)
    ClearPedTasks(playerPed)
    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('bucket_placed'),
        type = 'success',
        duration = 6000
    })
    updateBucketTarget()
    updateContextMenu()
    updateVehicleTarget()
end

function endCleaningJob(isForced)
    if not currentJob then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('no_active_job'),
            type = 'error',
            duration = 6000
        })
        return
    end

    if hasBucket then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('return_bucket_first'),
            type = 'warning',
            duration = 6000
        })
        return
    end

    local playerPed = PlayerPedId()
    SetPedComponentVariation(playerPed, 8, originalClothes[1], originalClothes[2], 2)   -- T-shirt
    SetPedComponentVariation(playerPed, 11, originalClothes[3], originalClothes[4], 2)  -- Torso
    SetPedComponentVariation(playerPed, 3, originalClothes[5], 0, 2)                    -- Arms
    SetPedComponentVariation(playerPed, 4, originalClothes[6], originalClothes[7], 2)   -- Pants
    SetPedComponentVariation(playerPed, 6, originalClothes[8], originalClothes[9], 2)   -- Shoes
    SetPedComponentVariation(playerPed, 7, originalClothes[10], originalClothes[11], 2) -- Chain

    if not isForced then
        if cleanedCars > 0 then
            local bonus = cleanedCars >= Config.CarsToClean and math.random(Config.BonusMin, Config.BonusMax) or 0
            totalPayment = totalPayment + bonus
            lib.notify({
                title = Locales._U('job_title'),
                description = bonus > 0 and Locales._U('end_job_bonus', { count = cleanedCars, bonus = bonus }) or
                    Locales._U('end_job_no_bonus', { count = cleanedCars }),
                type = 'success',
                duration = 6000
            })
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
    -- Reset values
    currentJob = false
    cleanedCars = 0
    totalPayment = 0
    cleanedVehicles = {}
    hasBucket = false
    totalCleanedCars = 0
    updateJobInitialTarget()
    updateInitialContextMenu()
    lib.hideContext()
    updateVehicleTarget()
end

function updateJobTarget()
    exports.ox_target:removeLocalEntity(jobNPC, { 'cleaning_menu' })

    local options = {
        {
            name = 'cleaning_menu',
            label = Locales._U('talk_gerardo'),
            icon = 'fas fa-user',
            onSelect = function()
                lib.showContext('cleaning_job_menu')
            end
        }
    }
    exports.ox_target:addLocalEntity(jobNPC, options)
end

function updateVehicleTarget()
    exports.ox_target:removeGlobalVehicle({ 'cleanVehicle' })
    if currentJob and bucketState == BUCKET_STATE.PLACED and spongeState == SPONGE_STATE.WET then
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
                    cleanVehicle(data.entity)
                end
            }
        }, Config.VehicleDistance)
    end
end

function updateBucketTarget()
    if bucketState == BUCKET_STATE.PLACED and bucketEntity then
        exports.ox_target:addLocalEntity(bucketEntity, {
            {
                name = 'wetSponge',
                label = Locales._U('wet_sponge'),
                icon = 'fas fa-tint',
                onSelect = function()
                    wetSponge()
                end
            },
            {
                name = 'pickUpBucket',
                label = Locales._U('pick_up_bucket'),
                icon = 'fas fa-hand-paper',
                onSelect = function()
                    pickUpBucket()
                end
            }
        })
    end
end

function updateJobInitialTarget()
    exports.ox_target:removeLocalEntity(jobNPC, { 'cleaning_menu', 'cleaning_active_menu' })

    exports.ox_target:addLocalEntity(jobNPC, {
        {
            name = 'cleaning_menu',
            label = Locales._U('talk_gerardo'),
            icon = 'fas fa-user',
            onSelect = function()
                lib.showContext('cleaning_job_menu')
            end
        }
    })
end

function updateJobActiveTarget()
    exports.ox_target:removeLocalEntity(jobNPC, { 'cleaning_menu', 'cleaning_active_menu' })

    exports.ox_target:addLocalEntity(jobNPC, {
        {
            name = 'cleaning_active_menu',
            label = Locales._U('cleaning_menu_label'),
            icon = 'fas fa-broom',
            onSelect = function()
                lib.showContext('cleaning_active_menu')
            end
        }
    })
end

local function GetExperienceProgress()
    local playerData = exports['dalton_cleaningjob']:GetPlayerData()
    if not playerData then
        return 1, 0, 0,
            0 -- Default to level 1 with 0% progress, 0 total cleaned cars, and 0 remaining exp if playerData is nil
    end
    local currentExp = playerData.exp or 0
    local currentLevel = playerData.level or 1
    local totalCleanedCars = playerData.cleaning_total or 0
    local nextLevelExp = Config.experience[currentLevel + 1] or Config.experience[currentLevel]
    local progress = (currentExp / nextLevelExp) * 100
    local remainingExp = nextLevelExp - currentExp
    return currentLevel, progress, totalCleanedCars, remainingExp
end

local function AddExperience(amount)
    local playerData = exports['dalton_cleaningjob']:GetPlayerData('exp')
    local currentExp = playerData or 0
    local newExp = currentExp + amount
    TriggerServerEvent('dalton_cleaningjob:addPlayerData', 'exp', amount) -- Add experience to player for cleaning
    TriggerServerEvent('dalton_cleaningjob:addPlayerData', 'cleaning_total', 1) -- Increment total cleaned cars
    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('exp_gained', { amount = amount }),
        type = 'success',
        duration = 6000
    })
    updateContextMenu()
end

function updateContextMenu()
    local currentLevel, progress, totalCleanedCars, remainingExp = GetExperienceProgress()
    local nextLevelExp = Config.experience[currentLevel + 1] or Config.experience[currentLevel]
    local expTitle = string.format(Locales._U('job_experience'), currentLevel, #Config.experience)
    local expDesc = string.format(Locales._U('job_exp_desc'), nextLevelExp - remainingExp, nextLevelExp, currentLevel + 1)
    lib.registerContext({
        id = 'cleaning_active_menu',
        title = Locales._U('active_job_title'),
        options = {
            {
                title = Locales._U('end_job'),
                icon = 'fas fa-stop',
                description = Locales._U('end_job_desc'),
                onSelect = function()
                    endCleaningJob(false)
                    updateJobInitialTarget()
                    lib.showContext('cleaning_job_menu')
                end,
                disabled = hasBucket
            },
            {
                title = hasBucket and Locales._U('return_bucket') or Locales._U('take_bucket'),
                icon = 'fas fa-hand-paper',
                description = hasBucket and Locales._U('return_bucket_desc') or Locales._U('take_bucket_desc'),
                onSelect = function()
                    if hasBucket then
                        returnBucket()
                    else
                        takeBucket()
                    end
                    lib.showContext('cleaning_active_menu')
                end
            },
            {
                title = expTitle,
                icon = 'fas fa-chart-line',
                description = expDesc,
                progress = progress,
                colorScheme = '#FEFE86',
                disabled = true
            },
            {
                title = Locales._U('job_total_cleanings', { total = totalCleanedCars }),
                icon = 'fas fa-car',
                disabled = true
            },
            {
                title = Locales._U('exit_menu'),
                icon = 'fas fa-times',
                onSelect = function()
                    lib.hideContext()
                end
            }
        }
    })
end

function updateInitialContextMenu()
    local currentLevel, progress, totalCleanedCars, remainingExp = GetExperienceProgress()
    local nextLevelExp = Config.experience[currentLevel + 1] or Config.experience[currentLevel]
    local expTitle = string.format(Locales._U('job_experience'), currentLevel, #Config.experience)
    local expDesc = string.format(Locales._U('job_exp_desc'), nextLevelExp - remainingExp, nextLevelExp, currentLevel + 1)
    lib.registerContext({
        id = 'cleaning_job_menu',
        title = Locales._U('job_menu_title'),
        options = {
            {
                title = Locales._U('start_job'),
                icon = 'fas fa-play',
                description = Locales._U('start_job_desc'),
                onSelect = function()
                    startCleaningJob()
                    updateJobActiveTarget()
                    lib.showContext('cleaning_active_menu')
                end
            },
            {
                title = expTitle,
                icon = 'fas fa-chart-line',
                description = expDesc,
                progress = progress,
                colorScheme = '#FEFE86',
                disabled = true
            },
            {
                title = Locales._U('job_total_cleanings', { total = totalCleanedCars }),
                icon = 'fas fa-car',
                disabled = true
            },
            {
                title = Locales._U('exit_menu'),
                icon = 'fas fa-times',
                onSelect = function()
                    lib.hideContext()
                end
            }
        }
    })
end

function takeBucket()
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
    updateContextMenu()
    updateVehicleTarget()
end

function pickUpBucket()
    if bucketState == BUCKET_STATE.NOT_PLACED then
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
    bucketState = BUCKET_STATE.NOT_PLACED
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

    -- Load animation
    RequestAnimDict('anim@mp_snowball')
    while not HasAnimDictLoaded('anim@mp_snowball') do
        Wait(10)
    end
    -- Play animation
    TaskPlayAnim(playerPed, 'anim@mp_snowball', 'pickup_snowball', 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(playerPed)

    hasBucket = true
    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('bucket_picked_up'),
        type = 'success',
        duration = 6000
    })
    updateContextMenu()
end

function wetSponge()
    if bucketState == BUCKET_STATE.NOT_PLACED then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('no_bucket'),
            type = 'error',
            duration = 6000
        })
        return
    end
    -- Verify distance between player and bucket
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
    -- Load animation
    RequestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
    while not HasAnimDictLoaded('anim@amb@clubhouse@tutorial@bkr_tut_ig3@') do
        Wait(10)
    end
    -- Play animation
    TaskPlayAnim(playerPed, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, -8.0, -1, 1,
        0, false, false, false)
    Wait(2000)
    ClearPedTasks(playerPed)
    -- Wet the sponge after cleaning
    spongeState = SPONGE_STATE.WET
    lib.notify({
        title = Locales._U('job_title'),
        description = Locales._U('sponge_wetted'),
        type = 'success',
        duration = 6000
    })
    updateVehicleTarget()
end

function isVehicleDirty(vehicle)
    local dirtLevel = GetVehicleDirtLevel(vehicle)
    return dirtLevel > 0.5
end

function ensureEntityControl(entity)
    if not NetworkHasControlOfEntity(entity) then
        NetworkRequestControlOfEntity(entity)
        local timeout = 0
        while not NetworkHasControlOfEntity(entity) and timeout < 500 do
            Wait(10)
            timeout = timeout + 10
        end
    end
end

function cleanVehicle(vehicle)
    if not currentJob then
        lib.notify({ title = Locales._U('job_title'), description = Locales._U('start_job_first'), type = 'error', duration = 6000 })
        return
    end

    if spongeState == SPONGE_STATE.DRY then
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

    if not isVehicleDirty(vehicle) then
        lib.notify({ title = Locales._U('job_title'), description = Locales._U('vehicle_already_clean'), type = 'warning', duration = 6000 })
        return
    end
    ensureEntityControl(vehicle)

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
        duration = 10000,
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
        local playerData = exports['dalton_cleaningjob']:GetPlayerData()
        local level = playerData.level or 1
        local percentageIncrease = (level - 1) * 0.05
        totalPayment = totalPayment + (payment * (1 + percentageIncrease))
        cleanedCars = cleanedCars + 1
        totalCleanedCars = totalCleanedCars + 1
        spongeState = SPONGE_STATE.DRY

        local randomExp = math.random(0, 25)
        TriggerServerEvent('cleaningjob:cleanedVehicle', payment, randomExp)

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

function returnBucket()
    if not hasBucket then
        lib.notify({
            title = Locales._U('job_title'),
            description = Locales._U('no_bucket_to_return'),
            type = 'error',
            duration = 6000
        })
        return
    end
    -- Remove bucket entity from ground
    if bucketState == BUCKET_STATE.PLACED and bucketEntity then
        DeleteEntity(bucketEntity)
        bucketState = BUCKET_STATE.NOT_PLACED
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
    updateContextMenu() -- Update context menu to allow ending the job
end

-- Events
AddEventHandler('playerDropped', function(reason)
    if currentJob then
        wasInJob = true                -- Mark to player was in job before disconnect
        savedClothes = originalClothes -- Save clothes for player
        endCleaningJob(true)           -- End job
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

-- Target Global
exports.ox_target:addLocalEntity(jobNPC, {
    {
        name = 'cleaning_menu',
        label = Locales._U('menu_label'),
        icon = 'fas fa-broom',
        onSelect = function()
            lib.showContext('cleaning_job_menu')
        end
    }
})

-- Context Menu ox_lib active job
lib.registerContext({
    id = 'cleaning_active_menu',
    title = Locales._U('active_job_title'),
    options = {
        {
            title = Locales._U('end_job'),
            icon = 'fas fa-stop',
            description = Locales._U('end_job_desc'),
            onSelect = function()
                endCleaningJob(false)
                updateJobInitialTarget()
                lib.showContext('cleaning_job_menu')
            end,
            disabled = hasBucket -- Not allow to end job if has the bucket
        },
        {
            title = hasBucket and Locales._U('return_bucket') or Locales._U('take_bucket'),
            icon = 'fas fa-hand-paper',
            description = hasBucket and Locales._U('return_bucket_desc') or Locales._U('take_bucket_desc'),
            onSelect = function()
                if hasBucket then
                    returnBucket()
                else
                    takeBucket()
                end
                lib.showContext('cleaning_active_menu')
            end
        },
        {
            title = Locales._U('exit_menu'),
            icon = 'fas fa-times',
            onSelect = function()
                lib.hideContext()
            end
        }
    }
})
-- Register initial context menu
updateInitialContextMenu()