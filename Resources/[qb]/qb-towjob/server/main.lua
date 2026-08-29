local QBCore = exports['qb-core']:GetCoreObject()
local PaymentTax = 15
local Bail = {}
-- Money Authority fix (2026-08-28): サーバー側で実際の納車完了数を追跡するためのテーブル(citizenid単位)
local TowDropoffCount = {}

RegisterNetEvent('qb-tow:server:DoBail', function(bool, vehInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if bool then
        if Player.PlayerData.money.cash >= Config.BailPrice then
            Bail[Player.PlayerData.citizenid] = Config.BailPrice
            Player.Functions.RemoveMoney('cash', Config.BailPrice, 'tow-paid-bail')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_cash', { value = Config.BailPrice }), 'success')
            TriggerClientEvent('qb-tow:client:SpawnVehicle', src, vehInfo)
        elseif Player.PlayerData.money.bank >= Config.BailPrice then
            Bail[Player.PlayerData.citizenid] = Config.BailPrice
            Player.Functions.RemoveMoney('bank', Config.BailPrice, 'tow-paid-bail')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_bank', { value = Config.BailPrice }), 'success')
            TriggerClientEvent('qb-tow:client:SpawnVehicle', src, vehInfo)
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_deposit', { value = Config.BailPrice }), 'error')
        end
    else
        if Bail[Player.PlayerData.citizenid] ~= nil then
            Player.Functions.AddMoney('bank', Bail[Player.PlayerData.citizenid], 'tow-bail-paid')
            Bail[Player.PlayerData.citizenid] = nil
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.refund_to_cash', { value = Config.BailPrice }), 'success')
        end
    end
end)

RegisterNetEvent('qb-tow:server:nano', function(vehNetID)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local targetVehicle = NetworkGetEntityFromNetworkId(vehNetID)
    if not Player then return end
    local playerPed = GetPlayerPed(src)
    local playerVehicle = GetVehiclePedIsIn(playerPed, true)
    local playerVehicleCoords = GetEntityCoords(playerVehicle)
    local targetVehicleCoords = GetEntityCoords(targetVehicle)
    local dist = #(playerVehicleCoords - targetVehicleCoords)
    if Player.PlayerData.job.name ~= 'tow' or dist > 11.0 then
        return DropPlayer(src, Lang:t('info.skick'))
    end
    local chance = math.random(1, 100)
    if chance < 26 then
        exports['qb-inventory']:AddItem(src, 'cryptostick', 1, false, false, 'qb-tow:server:nano')
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items['cryptostick'], 'add')
    end
end)

-- Money Authority fix (2026-08-28): 個々の納車完了をサーバー側で検知・カウントする。
-- deliverVehicle()(client/main.lua)から都度呼ばれる。qb-garbagejobのRoutes[citizenid]方式と同じ考え方。
RegisterNetEvent('qb-tow:server:VehicleDelivered', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= 'tow' then return end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - Config.Locations['dropoff'].coords) > 35.0 then
        return
    end
    local citizenid = Player.PlayerData.citizenid
    TowDropoffCount[citizenid] = (TowDropoffCount[citizenid] or 0) + 1
end)

RegisterNetEvent('qb-tow:server:11101110', function(drops)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    if Player.PlayerData.job.name ~= 'tow' or #(playerCoords - vector3(Config.Locations['main'].coords.x, Config.Locations['main'].coords.y, Config.Locations['main'].coords.z)) > 6.0 then
        return DropPlayer(src, Lang:t('info.skick'))
    end
    -- Money Authority fix (2026-08-28): drops引数(クライアント申告値)は使用しない。
    -- server:VehicleDelivered で積み上げたサーバー側カウントのみを正とする。
    local citizenid = Player.PlayerData.citizenid
    drops = TowDropoffCount[citizenid] or 0
    if drops <= 0 then return end
    local bonus = 0
    local DropPrice = math.random(150, 170)
    if drops > 5 then
        bonus = math.ceil((DropPrice / 10) * 5)
    elseif drops > 10 then
        bonus = math.ceil((DropPrice / 10) * 7)
    elseif drops > 15 then
        bonus = math.ceil((DropPrice / 10) * 10)
    elseif drops > 20 then
        bonus = math.ceil((DropPrice / 10) * 12)
    end
    local price = (DropPrice * drops) + bonus
    local taxAmount = math.ceil((price / 100) * PaymentTax)
    local payment = price - taxAmount
    Player.Functions.AddMoney('bank', payment, 'tow-salary')
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.you_earned', { value = payment }), 'success')
    TowDropoffCount[citizenid] = 0
end)

-- Money Authority fix (2026-08-28): ログアウト時にサーバー側カウントを破棄し、次回ログイン時に持ち越さない。
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        TowDropoffCount[Player.PlayerData.citizenid] = nil
    end
end)

QBCore.Commands.Add('npc', Lang:t('info.toggle_npc'), {}, false, function(source)
    TriggerClientEvent('jobs:client:ToggleNpc', source)
end)

QBCore.Commands.Add('tow', Lang:t('info.tow'), {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.job.name == 'tow' or Player.PlayerData.job.name == 'mechanic' then
        TriggerClientEvent('qb-tow:client:TowVehicle', source)
    end
end)
