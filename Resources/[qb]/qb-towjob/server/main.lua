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
            Bail[Player.PlayerData.citizenid] = { deposit = Config.TruckerJobTruckDeposit, plate = nil, netId = nil } -- 2026-09-06: プレート/netIdも追跡できるようテーブル化
            Player.Functions.RemoveMoney('cash', Config.TruckerJobTruckDeposit, 'tow-received-bail')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_cash', { value = Config.TruckerJobTruckDeposit }), 'success')
            TriggerClientEvent('qb-trucker:client:SpawnVehicle', src, vehInfo)
        elseif Player.PlayerData.money.bank >= Config.TruckerJobTruckDeposit then
            Bail[Player.PlayerData.citizenid] = { deposit = Config.TruckerJobTruckDeposit, plate = nil, netId = nil }
            Player.Functions.RemoveMoney('bank', Config.TruckerJobTruckDeposit, 'tow-received-bail')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_bank', { value = Config.TruckerJobTruckDeposit }), 'success')
            TriggerClientEvent('qb-trucker:client:SpawnVehicle', src, vehInfo)
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_deposit', { value = Config.TruckerJobTruckDeposit }), 'error')
        end
    else
        local info = Bail[Player.PlayerData.citizenid]
        if info then
            Player.Functions.AddMoney('cash', info.deposit, 'trucker-bail-paid')
            -- 2026-09-06 新設: 正規返却時に、貸出し時に付与したキーの永続保存(qb-vehiclekeys)を確実に剥奪する。
            -- これを行っていなかったため、返却済み・ログアウト後もそのトラックの鍵を持ち続けてしまっていた。
            if info.plate then
                pcall(function() exports['qb-vehiclekeys']:RemoveKeys(src, info.plate) end)
            end
            Bail[Player.PlayerData.citizenid] = nil
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.refund_to_cash', { value = info.deposit }), 'success')
        end
    end
end)

RegisterNetEvent('qb-trucker:server:RegisterActiveVehicle', function(plate, netId)
    -- 2026-09-06 新設: 借用中車両のプレート/netIdをBailに記録しておき、大破時・ログアウト時の
    -- キー剥奪や車両削除に使えるようにする。
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local info = Bail[Player.PlayerData.citizenid]
    if info then
        info.plate = plate
        info.netId = netId
    end
end)

RegisterNetEvent('qb-trucker:server:EndVehicleRental', function(applyFine)
    -- 2026-09-06 新設: 大破・Job変更など、正規の返却フロー以外でレンタルが終わった場合の処理。
    -- 保証金は没収したまま(返金しない)。applyFine=trueの場合のみ、大破に対する追加の罰金
    -- (Config.TruckerJobDestroyedFine、銀行口座から徴収)を科す。
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local info = Bail[citizenid]
    if not info then return end
    Bail[citizenid] = nil

    if info.plate then
        pcall(function() exports['qb-vehiclekeys']:RemoveKeys(src, info.plate) end)
    end

    if applyFine then
        local removed = Player.Functions.RemoveMoney('bank', Config.TruckerJobDestroyedFine, 'trucker-vehicle-destroyed')
        if removed then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehicle_destroyed_fine', { value = Config.TruckerJobDestroyedFine }), 'error')
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehicle_destroyed_no_fine'), 'error')
        end
    end
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    -- 2026-09-06 新設: ログアウト・切断時に借用中のトラックが残っている場合、鍵の永続保存を
    -- 剥奪し、車両も削除する(保証金は没収のまま、罰金は科さない)。以前はここで一切処理されず、
    -- 放置されたトラックの鍵をプレイヤーが持ち続け、再ログイン後もそのトラックに乗れてしまっていた。
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local info = Bail[citizenid]
    if not info then return end
    Bail[citizenid] = nil

    if info.plate then
        pcall(function() exports['qb-vehiclekeys']:RemoveKeys(src, info.plate) end)
    end
    if info.netId then
        local veh = NetworkGetEntityFromNetworkId(info.netId)
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            DeleteEntity(veh)
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
