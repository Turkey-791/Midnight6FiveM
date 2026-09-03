local QBCore = exports['qb-core']:GetCoreObject({ 'Functions', 'Commands' })
local sharedItems = exports['qb-core']:GetShared('Items')
local vehicleComponents = {}
local drivingDistance = {}
local tunedVehicles = {}
local nitrousVehicles = {}

-- Functions

function Trim(plate)
    return (string.gsub(plate, '^%s*(.-)%s*$', '%1'))
end

local function IsVehicleOwned(plate)
    local result = MySQL.scalar.await('SELECT 1 from player_vehicles WHERE plate = ?', { plate })
    if result then return true end
    return false
end

local function StartParticles(coords, netId, color)
    for _, playerId in ipairs(GetPlayers()) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(coords - playerCoords)
        if distance < 10 then
            Player(playerId).state:set('paint_particles', true, false)
            TriggerClientEvent('qb-mechanicjob:client:startParticles', playerId, netId, color)
        end
    end
end

local function StopParticles()
    for _, playerId in ipairs(GetPlayers()) do
        if Player(playerId).state.paint_particles then
            Player(playerId).state:set('paint_particles', false, false)
            TriggerClientEvent('qb-mechanicjob:client:stopParticles', playerId)
        end
    end
end

local function LerpColor(colorFrom, colorTo, fraction)
    return {
        r = colorFrom.r + (colorTo.r - colorFrom.r) * fraction,
        g = colorFrom.g + (colorTo.g - colorFrom.g) * fraction,
        b = colorFrom.b + (colorTo.b - colorFrom.b) * fraction
    }
end

local function TransitionVehicleColor(vehicle, section, currentColor, targetColor, duration)
    local startTime = GetGameTimer()
    local endTime = startTime + duration
    while GetGameTimer() <= endTime do
        local currentTime = GetGameTimer()
        local fraction = (currentTime - startTime) / duration
        local newColor = LerpColor(currentColor, targetColor, fraction)
        if section == 'primary' then
            SetVehicleCustomPrimaryColour(vehicle, math.floor(newColor.r), math.floor(newColor.g), math.floor(newColor.b))
        elseif section == 'secondary' then
            SetVehicleCustomSecondaryColour(vehicle, math.floor(newColor.r), math.floor(newColor.g), math.floor(newColor.b))
        end
        Wait(0)
    end
end

-- Callbacks

QBCore.Functions.CreateCallback('qb-mechanicjob:server:getnitrousVehicles', function(_, cb)
    cb(nitrousVehicles)
end)

QBCore.Functions.CreateCallback('qb-mechanicjob:server:checkTune', function(_, cb, plate)
    if not tunedVehicles[plate] then cb(false) end
    cb(tunedVehicles[plate])
end)

QBCore.Functions.CreateCallback('qb-mechanicjob:server:getVehicleStatus', function(_, cb, plate)
    if not vehicleComponents[plate] then cb(false) end
    cb(vehicleComponents[plate])
end)

QBCore.Functions.CreateCallback('qb-mechanicjob:server:hasPermission', function(source, cb)
    if QBCore.Functions.HasPermission(source, { 'god', 'admin', 'command' }) then
        cb(true)
    else
        cb(false)
    end
end)

-- Events

RegisterNetEvent('qb-mechanicjob:server:stash', function(data)
    local src = source
    local shopName = data.job
    if not Config.Shops[shopName] then return end
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    if Config.Shops[shopName].managed and Player.PlayerData.job.name ~= shopName then return end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local stashCoords = Config.Shops[shopName].stash
    if #(playerCoords - stashCoords) < 2.5 then
        local stashName = shopName .. '_stash'
        exports['qb-inventory']:OpenInventory(src, stashName, {
            maxweight = 4000000,
            slots = 100,
        })
    end
end)

RegisterNetEvent('qb-mechanicjob:server:sprayVehicleCustom', function(netId, section, type, color)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 then return end
    local vehicleCoords = GetEntityCoords(vehicle)
    FreezeEntityPosition(vehicle, true)
    StartParticles(vehicleCoords, netId, color)

    -- [Phase1 fix / P1-1] 「本当にカスタムRGBが設定されている場合」だけ現在色を取得する。
    -- GTA Vのnativeには標準カラーIndexをRGBへ変換する手段が無いため、
    -- 標準カラーから遷移する場合は正しい開始色を作れない(白などを適当にfallbackさせない)。
    -- また、旧実装は塗装タイプ定数(metallic=0/matte=12/chrome=120)を
    -- SetVehicleColoursの標準カラーIndexとして誤用していたため、この呼び出しは撤去した。
    local currentColor
    if section == 'primary' then
        if GetIsVehiclePrimaryColourCustom(vehicle) then
            local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
            if r and g and b then
                currentColor = { r = r, g = g, b = b }
            end
        end
    elseif section == 'secondary' then
        if GetIsVehicleSecondaryColourCustom(vehicle) then
            local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
            if r and g and b then
                currentColor = { r = r, g = g, b = b }
            end
        end
    end

    if currentColor then
        -- 現在色(カスタムRGB)が判明している場合のみ、なめらかにフェードさせる
        TransitionVehicleColor(vehicle, section, currentColor, color, Config.PaintTime * 1000)
    else
        -- 現在色が不明(標準カラーからの変更)な場合は、誤った色を経由させず即時に目的の色を適用する
        Wait(Config.PaintTime * 1000)
        if section == 'primary' then
            SetVehicleCustomPrimaryColour(vehicle, color.r, color.g, color.b)
        elseif section == 'secondary' then
            SetVehicleCustomSecondaryColour(vehicle, color.r, color.g, color.b)
        end
    end

    StopParticles()
    FreezeEntityPosition(vehicle, false)
end)

RegisterNetEvent('qb-mechanicjob:server:sprayVehicle', function(netId, primary, secondary, pearlescent, wheel, colors)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local vehicleCoords = GetEntityCoords(vehicle)
    FreezeEntityPosition(vehicle, true)

    if colors.primary then
        StartParticles(vehicleCoords, netId, colors.primary)
        Wait(Config.PaintTime * 1000)
        -- local _, colorSecondary = GetVehicleColours(vehicle)
        -- ClearVehicleCustomPrimaryColour(vehicle) -- does not exist yet
        -- SetVehicleColours(vehicle, tonumber(primary), colorSecondary)
        TriggerClientEvent('qb-mechanicjob:client:vehicleSetColors', -1, netId, 'primary', primary)
        StopParticles()
    end

    if colors.secondary then
        StartParticles(vehicleCoords, netId, colors.secondary)
        Wait(Config.PaintTime * 1000)
        -- local colorPrimary, _ = GetVehicleColours(vehicle)
        -- ClearVehicleCustomSecondaryColour(vehicle) -- does not exist yet
        -- SetVehicleColours(vehicle, colorPrimary, tonumber(secondary))
        TriggerClientEvent('qb-mechanicjob:client:vehicleSetColors', -1, netId, 'secondary', secondary)
        StopParticles()
    end

    if colors.pearlescent then
        StartParticles(vehicleCoords, netId, colors.pearlescent)
        Wait(Config.PaintTime * 1000)
        -- local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle) -- does not exist yet
        -- SetVehicleExtraColours(vehicle, tonumber(pearlescent) or pearlescentColor, tonumber(wheel) or wheelColor) -- does not exist yet
        TriggerClientEvent('qb-mechanicjob:client:vehicleSetColors', -1, netId, 'pearlescent', pearlescent)
        StopParticles()
    end

    if colors.wheel then
        StartParticles(vehicleCoords, netId, colors.wheel)
        Wait(Config.PaintTime * 1000)
        -- local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle) -- does not exist yet
        -- SetVehicleExtraColours(vehicle, tonumber(pearlescent) or pearlescentColor, tonumber(wheel) or wheelColor) -- does not exist yet
        TriggerClientEvent('qb-mechanicjob:client:vehicleSetColors', -1, netId, 'wheel', wheel)
        StopParticles()
    end

    FreezeEntityPosition(vehicle, false)
end)

RegisterNetEvent('qb-mechanicjob:server:syncNitrous', function(plate, hasnitro, level)
    if not nitrousVehicles[plate] then
        nitrousVehicles[plate] = { hasnitro = hasnitro, level = level }
    else
        nitrousVehicles[plate].hasnitro = hasnitro
        nitrousVehicles[plate].level = level
    end
end)

RegisterNetEvent('qb-mechanicjob:server:syncNitrousFlames', function(netId, toggle)
    TriggerClientEvent('qb-mechanicjob:client:syncNitrousFlames', -1, netId, toggle)
end)

RegisterNetEvent('qb-mechanicjob:server:tuneStatus', function(plate)
    if not tunedVehicles[plate] then
        tunedVehicles[plate] = true
    end
end)

RegisterNetEvent('qb-mechanicjob:server:SaveVehicleProps', function(vehicleProps)
    if IsVehicleOwned(vehicleProps.plate) then
        MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(vehicleProps), vehicleProps.plate })
    end
end)

RegisterNetEvent('qb-mechanicjob:server:repairVehicleComponent', function(plate, component)
    if plate and component then
        if not vehicleComponents[plate] then return end
        if vehicleComponents[plate][component] then
            vehicleComponents[plate][component] = 100
        end
    end
end)

RegisterNetEvent('qb-mechanicjob:server:updateVehicleComponents', function(plate, componentData)
    if plate and componentData then
        vehicleComponents[plate] = componentData
    end
    local isOwned = IsVehicleOwned(plate)
    if isOwned then MySQL.update('UPDATE player_vehicles SET status = ? WHERE plate = ?', { json.encode(vehicleComponents[plate]), plate }) end
end)

RegisterNetEvent('qb-mechanicjob:server:updateDrivingDistance', function(plate, distance)
    if plate and distance then
        if drivingDistance[plate] then
            drivingDistance[plate] = drivingDistance[plate] + distance
        else
            drivingDistance[plate] = distance
        end
    end
    local isOwned = IsVehicleOwned(plate)
    if isOwned then MySQL.update('UPDATE player_vehicles SET drivingdistance = drivingdistance + ? WHERE plate = ?', { drivingDistance[plate], plate }) end
end)

RegisterNetEvent('qb-mechanicjob:server:removeItem', function(part, amount)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    if not amount then amount = 1 end
    if not exports['qb-inventory']:RemoveItem(src, part, amount, false, 'qb-mechanicjob:server:removeItem') then DropPlayer(src, 'qb-mechanicjob:server:removeItem') end
    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[part], 'remove')
end)

-- Items

local performanceParts = {
    'veh_armor',
    'veh_brakes',
    'veh_engine',
    'veh_suspension',
    'veh_transmission',
    'veh_turbo',
}

for i = 1, #performanceParts do
    QBCore.Functions.CreateUseableItem(performanceParts[i], function(source, item)
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player then return end
        if Config.RequireJob and Player.PlayerData.job.type ~= 'mechanic' then return end
        TriggerClientEvent('qb-mechanicjob:client:installPart', source, item.name)
    end)
end

local cosmeticParts = {
    'veh_interior',
    'veh_exterior',
    'veh_wheels',
    'veh_neons',
    'veh_xenons',
    'veh_tint',
    'veh_plates',
}

for i = 1, #cosmeticParts do
    QBCore.Functions.CreateUseableItem(cosmeticParts[i], function(source, item)
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player then return end
        if Config.RequireJob and Player.PlayerData.job.type ~= 'mechanic' then return end
        TriggerClientEvent('qb-mechanicjob:client:installCosmetic', source, item.name)
    end)
end

QBCore.Functions.CreateUseableItem('veh_toolbox', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Config.RequireJob and Player.PlayerData.job.type ~= 'mechanic' then return end
    TriggerClientEvent('qb-mechanicjob:client:PartsMenu', source)
end)

QBCore.Functions.CreateUseableItem('tunerlaptop', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Config.RequireJob and Player.PlayerData.job.type ~= 'mechanic' then return end
    TriggerClientEvent('qb-mechanicjob:client:openChip', source)
end)

QBCore.Functions.CreateUseableItem('nitrous', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Config.RequireJob and Player.PlayerData.job.type ~= 'mechanic' then return end
    TriggerClientEvent('qb-mechanicjob:client:installNitrous', source)
end)

QBCore.Functions.CreateUseableItem('tirerepairkit', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    TriggerClientEvent('qb-mechanicjob:client:repairTire', source)
end)

QBCore.Functions.CreateUseableItem('repairkit', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    TriggerClientEvent('qb-mechanicjob:client:repairVehicle', source)
end)

QBCore.Functions.CreateUseableItem('advancedrepairkit', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    TriggerClientEvent('qb-mechanicjob:client:repairVehicleFull', source)
end)

QBCore.Functions.CreateUseableItem('cleaningkit', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    TriggerClientEvent('qb-mechanicjob:client:cleanVehicle', source)
end)

-- Commands

QBCore.Commands.Add('fix', 'Repair your vehicle (Admin Only)', {}, false, function(source)
    local ped = GetPlayerPed(source)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle then return end
    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then return end
    local trimmedPlate = Trim(plate)
    if vehicleComponents[trimmedPlate] then
        for k in pairs(vehicleComponents[trimmedPlate]) do
            vehicleComponents[trimmedPlate][k] = 100
        end
    end
    TriggerClientEvent('qb-mechanicjob:client:fixEverything', source)
end, 'admin')
