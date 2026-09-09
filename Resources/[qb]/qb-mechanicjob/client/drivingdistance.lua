local vehicle, plate
local vehicleComponents = {}
local drivingDistance = {}
local componentFailed = {}    -- [バランス調整 2026-09-09] 摩耗パーツの故障エフェクトを「閾値を下回った瞬間」の1回だけ発動させるためのフラグ
                               -- (以前は閾値以下である限りランダム判定に当たる度に何度も発動し、連鎖的に大破していた)
local lastDamagedTier = {}    -- [バランス調整 2026-09-09] 距離ダメージの各階層(tier)につき1回だけダメージを適用するためのフラグ
                               -- (以前は同じ距離帯にいる間、毎フレーム減算され続け、階層をまたいだ瞬間に耐久が一瞬で0になっていた)
local currentDamageMult = 1.0 -- 車両価格に応じたダメージ倍率(高額車ほど小さくなる。1.0=ボーナス無し)

-- Function

local function GetPriceDamageMultiplier(veh)
    if not Config.UseDurabilityTiers then return 1.0 end
    local vehInfo = QBCore.Shared.VehicleHashes[GetEntityModel(veh)]
    local price = vehInfo and vehInfo.price or Config.DurabilityBasePrice
    if not price or price <= Config.DurabilityBasePrice then return 1.0 end
    local ratio = (price - Config.DurabilityBasePrice) / (Config.DurabilityLuxuryPrice - Config.DurabilityBasePrice)
    if ratio > 1.0 then ratio = 1.0 end
    return 1.0 - (ratio * Config.DurabilityMaxReduction)
end

local function InitializeVehicleComponents()
    if not Config.UseWearableParts then return end
    vehicleComponents[plate] = {}
    componentFailed[plate] = {}
    for part, data in pairs(Config.WearableParts) do
        vehicleComponents[plate][part] = data.maxValue
    end
end

local function ApplyComponentEffect(component) -- add custom effects here for each component in config
    if component == 'radiator' then
        local engineHealth = GetVehicleEngineHealth(vehicle)
        SetVehicleEngineHealth(vehicle, engineHealth - 20) -- [バランス調整 2026-09-09] 50から緩和。1回きりの大ダメージで「理不尽」に感じにくくする
    elseif component == 'axle' then
        for i = 0, 360 do
            Wait(15)
            SetVehicleSteeringScale(vehicle, i)
        end
    elseif component == 'brakes' then
        SetVehicleHandbrake(vehicle, true)
        Wait(5000)
        SetVehicleHandbrake(vehicle, false)
    elseif component == 'clutch' then
        SetVehicleEngineOn(vehicle, false, false, true)
        SetVehicleUndriveable(vehicle, true)
        Wait(5000)
        SetVehicleEngineOn(vehicle, true, false, true)
        SetVehicleUndriveable(vehicle, false)
    elseif component == 'fuel' then
        local fuel = exports[Config.FuelResource]:GetFuel(vehicle)
        exports[Config.FuelResource]:SetFuel(vehicle, fuel - 10)
    end
end

local function DamageRandomComponent()
    if not Config.UseWearableParts then return end
    local componentKeys = {}
    for component, _ in pairs(Config.WearableParts) do
        componentKeys[#componentKeys + 1] = component
    end
    local componentToDamage = componentKeys[math.random(#componentKeys)]
    local damageAmount = Config.WearablePartsDamage * currentDamageMult
    vehicleComponents[plate][componentToDamage] = math.max(0, vehicleComponents[plate][componentToDamage] - damageAmount)
    if vehicleComponents[plate][componentToDamage] <= Config.DamageThreshold then
        -- [バランス調整 2026-09-09] 閾値を下回った瞬間の1回だけ発動(以前は毎回のランダム判定で何度も再発動していた)
        if not componentFailed[plate] then componentFailed[plate] = {} end
        if not componentFailed[plate][componentToDamage] then
            componentFailed[plate][componentToDamage] = true
            ApplyComponentEffect(componentToDamage)
        end
    end
end

local function GetDamageTier(distance)
    for tierIndex, tier in ipairs(Config.MinimalMetersForDamage) do
        if distance >= tier.min and distance < tier.max then
            return tierIndex, tier.damage
        end
    end
    return nil, 0
end

local function ApplyDamageBasedOnDistance(distance)
    if not Config.UseDistanceDamage then return end
    local tierIndex, damage = GetDamageTier(distance)
    if not tierIndex then return end
    -- [バランス調整 2026-09-09 / 重大バグ修正] 以前はこの関数が同じ距離帯にいる間、毎フレーム(Wait(0)ループ)
    -- 呼ばれ続けており、5000m地点を超えた瞬間からエンジン耐久が1秒足らずで0まで落ちていた(「いきなり耐久が0になる」不具合の主因)。
    -- 各距離帯につき1回だけダメージを適用するよう修正。
    if lastDamagedTier[plate] == tierIndex then return end
    lastDamagedTier[plate] = tierIndex
    local engineHealth = GetVehicleEngineHealth(vehicle)
    SetVehicleEngineHealth(vehicle, engineHealth - (damage * currentDamageMult))
end

local function TrackDistance()
    CreateThread(function()
        while true do
            Wait(0)
            if not vehicle then break end

            local ped = PlayerPedId()
            local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped
            local speed = GetEntitySpeed(vehicle)

            if isDriver then
                if plate and speed > 5 then
                    if not drivingDistance[plate] then
                        drivingDistance[plate] = { distance = 0, lastCoords = GetEntityCoords(vehicle) }
                        InitializeVehicleComponents()
                    else
                        local newCoords = GetEntityCoords(vehicle)
                        local distance = #(drivingDistance[plate].lastCoords - newCoords)
                        if distance < 5 then
                            drivingDistance[plate].distance = drivingDistance[plate].distance + distance
                            drivingDistance[plate].lastCoords = newCoords
                            -- Engine damage
                            local accumulatedDistance = drivingDistance[plate].distance
                            if accumulatedDistance >= Config.MinimalMetersForDamage[1].min then
                                ApplyDamageBasedOnDistance(accumulatedDistance)
                            end
                            -- Parts Damage
                            local randomNumber = math.random(1, 1000)
                            if randomNumber <= Config.WearablePartsChance then
                                DamageRandomComponent()
                            end
                        end
                    end
                end
            else
                if drivingDistance[plate] then
                    TriggerServerEvent('qb-mechanicjob:server:updateDrivingDistance', plate, drivingDistance[plate].distance)
                    TriggerServerEvent('qb-mechanicjob:server:updateVehicleComponents', plate, vehicleComponents[plate])
                end
                plate = nil
                vehicle = nil
                break
            end
        end
    end)
end

-- Handler

AddEventHandler('gameEventTriggered', function(event)
    if event == 'CEventNetworkPlayerEnteredVehicle' then
        if not Config.UseDistance then return end
        vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        local originalPlate = GetVehicleNumberPlateText(vehicle)
        if not originalPlate then return end
        plate = Trim(originalPlate)
        local vehicleClass = GetVehicleClass(vehicle)
        if Config.IgnoreClasses[vehicleClass] then return end
        currentDamageMult = GetPriceDamageMultiplier(vehicle)
        TrackDistance()
    end
end)

RegisterNetEvent('qb-mechanicjob:client:syncRepairedComponent', function(repairedPlate, component)
    -- [バランス調整 2026-09-09] リペアキット/ツールボックス修理の直後でも、運転中の耐久トラッキングに即時反映させる
    -- (以前はサーバー側の値だけリセットされ、そのまま運転を続けて降車すると古い低い値で上書きされてしまっていた)
    if vehicleComponents[repairedPlate] and Config.WearableParts[component] then
        vehicleComponents[repairedPlate][component] = Config.WearableParts[component].maxValue
    end
    if componentFailed[repairedPlate] then
        componentFailed[repairedPlate][component] = false
    end
end)
