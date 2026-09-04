local Plates = {}

local function IsVehicleOwned(plate)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    return result
end

-- Callbacks

QBCore.Functions.CreateCallback('police:GetImpoundedVehicles', function(_, cb)
    local vehicles = {}
    MySQL.query('SELECT * FROM player_vehicles WHERE state = ?', { 2 }, function(result)
        if result[1] then
            vehicles = result
        end
        cb(vehicles)
    end)
end)

QBCore.Functions.CreateCallback('police:server:IsPlateFlagged', function(_, cb, plate)
    local retval = false
    if Plates and Plates[plate] then
        if Plates[plate].isflagged then
            retval = true
        end
    end
    cb(retval)
end)

-- Events

RegisterNetEvent('heli:server:spotlight', function(state)
    local serverID = source
    TriggerClientEvent('heli:client:spotlight', -1, serverID, state)
end)

RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel)
    local src = source
    price = price and price or 0
    if IsVehicleOwned(plate) then
        if not fullImpound then
            MySQL.query('UPDATE player_vehicles SET state = ?, depotprice = ?, body = ?, engine = ?, fuel = ? WHERE plate = ?', { 0, price, body, engine, fuel, plate })
            TriggerClientEvent('QBCore:Notify', src, Lang:t('info.vehicle_taken_depot', { price = price }))
        else
            MySQL.query('UPDATE player_vehicles SET state = ?, body = ?, engine = ?, fuel = ? WHERE plate = ?', { 2, body, engine, fuel, plate })
            TriggerClientEvent('QBCore:Notify', src, Lang:t('info.vehicle_seized'))
        end
    end
end)

RegisterNetEvent('police:server:TakeOutImpound', function(plate, garage)
    local src = source
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = Config.Locations['impound'][garage]
    if #(playerCoords - targetCoords) > 10.0 then return DropPlayer(src, 'Attempted exploit abuse') end
    MySQL.update('UPDATE player_vehicles SET state = ? WHERE plate = ?', { 0, plate })
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.impound_vehicle_removed'), 'success')
end)

-- 2026-09-03 BUG-05修正: 完全差し押さえ(state=2)された車両が所有者から永久に失われる問題への対応。
-- 既存のTakeOutImpound(警察官専用、officerの元へ車両をspawnする処理)は流用せず、
-- 所有者本人が手数料を払って自分のガレージへ回収できる専用の新規経路を追加する。
-- state=2は「引き取り待ち」を意味するだけであり、「永久没収」の概念は導入しない。
QBCore.Functions.CreateCallback('qb-policejob:server:GetMyFullImpoundedVehicles', function(source, cb)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return cb({}) end
    local vehicles = {}
    MySQL.query('SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?', { Player.PlayerData.citizenid, 2 }, function(result)
        if result and result[1] then
            vehicles = result
        end
        cb(vehicles)
    end)
end)

RegisterNetEvent('qb-policejob:server:ReturnFullImpoundedVehicle', function(plate)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    -- 1. 所有者・stateをサーバー側で必ず確認する(クライアントの申告は信用しない)
    local vehicle = MySQL.single.await('SELECT citizenid, state, garage FROM player_vehicles WHERE plate = ?', { plate })
    if not vehicle or vehicle.citizenid ~= citizenid or vehicle.state ~= 2 then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.full_impound_not_found'), 'error')
        return
    end

    -- 2. 返還手数料の支払い(現金優先、次に銀行。既存のqb-garages:server:PayDepotPriceと同じ優先順)
    local fee = Config.FullImpoundReturnFee or 0
    local cashBalance = Player.PlayerData.money['cash']
    local bankBalance = Player.PlayerData.money['bank']
    local paidFrom = 'none'
    if fee > 0 then
        if cashBalance >= fee then
            Player.RemoveMoney('cash', fee, 'full-impound-return')
            paidFrom = 'cash'
        elseif bankBalance >= fee then
            Player.RemoveMoney('bank', fee, 'full-impound-return')
            paidFrom = 'bank'
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.full_impound_not_enough_money', { fee = fee }), 'error')
            return
        end
    end

    -- 3. state=2条件付きUPDATE(二重返還・競合を防止)。mods/engine/body/fuel/plate/citizenidは一切変更しない。
    -- garage列も変更しない(最後に有効だったガレージのまま=通常のqb-garages出庫フローに合流する)。
    local result = MySQL.update.await('UPDATE player_vehicles SET state = 1, depotprice = 0 WHERE plate = ? AND citizenid = ? AND state = 2', { plate, citizenid })

    if not result or result == 0 then
        -- 4. 更新できなかった場合(既に他の経路で返還済み等の競合)は必ず全額返金する
        if paidFrom == 'cash' then
            Player.AddMoney('cash', fee, 'full-impound-return-refund')
        elseif paidFrom == 'bank' then
            Player.AddMoney('bank', fee, 'full-impound-return-refund')
        end
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.full_impound_conflict'), 'error')
        return
    end

    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.full_impound_returned', { fee = fee }), 'success')
end)

RegisterNetEvent('police:server:FlaggedPlateTriggered', function(coords, plate)
    for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
        if Player then
            if (Player.PlayerData.job.name == 'police' and Player.PlayerData.job.onduty) then
                local veh_plate = plate:upper()
                local message = Lang:t('info.flagged_vehicle_radar', { plate = veh_plate })
                TriggerClientEvent('police:client:policeAlert', Player.PlayerData.source, coords, message)
            end
        end
    end
end)

-- Commands

QBCore.Commands.Add('flagplate', Lang:t('commands.flagplate'), { { name = 'plate', help = Lang:t('info.plate_number') }, { name = 'reason', help = Lang:t('info.flag_reason') } }, true, function(source, args)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
        local reason = {}
        for i = 2, #args, 1 do
            reason[#reason + 1] = args[i]
        end
        Plates[args[1]:upper()] = {
            isflagged = true,
            reason = table.concat(reason, ' ')
        }
        TriggerClientEvent('QBCore:Notify', src, Lang:t('info.vehicle_flagged', { vehicle = args[1]:upper(), reason = table.concat(reason, ' ') }))
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
    end
end)

QBCore.Commands.Add('unflagplate', Lang:t('commands.unflagplate'), { { name = 'plate', help = Lang:t('info.plate_number') } }, true, function(source, args)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
        if Plates and Plates[args[1]:upper()] then
            if Plates[args[1]:upper()].isflagged then
                Plates[args[1]:upper()].isflagged = false
                TriggerClientEvent('QBCore:Notify', src, Lang:t('info.unflag_vehicle', { vehicle = args[1]:upper() }))
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehicle_not_flag'), 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehicle_not_flag'), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
    end
end)

QBCore.Commands.Add('plateinfo', Lang:t('commands.plateinfo'), { { name = 'plate', help = Lang:t('info.plate_number') } }, true, function(source, args)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
        if Plates and Plates[args[1]:upper()] then
            if Plates[args[1]:upper()].isflagged then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('success.vehicle_flagged', { plate = args[1]:upper(), reason = Plates[args[1]:upper()].reason }), 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehicle_not_flag'), 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehicle_not_flag'), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.on_duty_police_only'), 'error')
    end
end)
