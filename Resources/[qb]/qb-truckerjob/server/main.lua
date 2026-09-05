local QBCore = exports['qb-core']:GetCoreObject()
local Bail = {}

RegisterNetEvent('qb-trucker:server:DoBail', function(bool, vehInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if bool then
        -- 2026-09-05 Trucker二重貸出し修正: 既に保証金支払い済み(Bail保持中)の状態で
        -- 新規貸出しリクエストが来た場合は拒否する。これにより、ゾーンの多重登録など
        -- 何らかの理由でこのイベントが連続発火しても、保証金の二重請求や
        -- 既存トラックの意図しない差し替えが発生しなくなる。保証金の金額・報酬計算式など
        -- 既存の値は一切変更していない。
        if Bail[Player.PlayerData.citizenid] then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehicle_already_out'), 'error')
            return
        end
        if Player.PlayerData.money.cash >= Config.TruckerJobTruckDeposit then
            Bail[Player.PlayerData.citizenid] = Config.TruckerJobTruckDeposit
            Player.Functions.RemoveMoney('cash', Config.TruckerJobTruckDeposit, 'tow-received-bail')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_cash', { value = Config.TruckerJobTruckDeposit }), 'success')
            TriggerClientEvent('qb-trucker:client:SpawnVehicle', src, vehInfo)
        elseif Player.PlayerData.money.bank >= Config.TruckerJobTruckDeposit then
            Bail[Player.PlayerData.citizenid] = Config.TruckerJobTruckDeposit
            Player.Functions.RemoveMoney('bank', Config.TruckerJobTruckDeposit, 'tow-received-bail')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_bank', { value = Config.TruckerJobTruckDeposit }), 'success')
            TriggerClientEvent('qb-trucker:client:SpawnVehicle', src, vehInfo)
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_deposit', { value = Config.TruckerJobTruckDeposit }), 'error')
        end
    else
        if Bail[Player.PlayerData.citizenid] then
            Player.Functions.AddMoney('cash', Bail[Player.PlayerData.citizenid], 'trucker-bail-paid')
            Bail[Player.PlayerData.citizenid] = nil
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.refund_to_cash', { value = Config.TruckerJobTruckDeposit }), 'success')
        end
    end
end)

RegisterNetEvent('qb-trucker:server:01101110', function(drops)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= 'trucker' then return end
    drops = tonumber(drops)
    if not drops then return end
    drops = math.floor(drops)
    if drops < 1 then return end
    if drops > Config.TruckerJobMaxDrops then
        drops = Config.TruckerJobMaxDrops
    end
    local bonus = 0

    if drops >= 5 then
        if Config.TruckerJobBonus < 0 then Config.TruckerJobBonus = 0 end
        bonus = (math.ceil(Config.TruckerJobDropPrice / 100) * Config.TruckerJobBonus) * drops
    end
    local payment = (Config.TruckerJobDropPrice * drops + bonus)
    payment = payment - (math.ceil(payment / 100) * Config.TruckerJobPaymentTax)
    Player.Functions.AddJobReputation(drops)
    Player.Functions.AddMoney('bank', payment, 'trucker-salary')
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.you_earned', { value = payment }), 'success')
end)

RegisterNetEvent('qb-trucker:server:nano', function()
    local chance = math.random(1, 100)
    if chance > 26 then return end
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    xPlayer.Functions.AddItem('cryptostick', 1, false)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['cryptostick'], 'add')
end)
