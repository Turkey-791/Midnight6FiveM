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
    -- 2026-09-09 経済設計: 基準単価を$150〜170から$530〜570へ引き上げ(基準時給$3,000/hに対し、
    -- トラック運転手より上の「高め」枠として設定)。
    -- 同時に、この下のelseifチェーンのバグを修正した。従来は`drops > 5`が真になった時点で
    -- 以降のelseifに到達できず、6台搬送しても20台搬送しても常に最も低いボーナス率(5%)しか
    -- 適用されていなかった(10/15/20台用の高ボーナスが実質デッドコード化していた)。
    -- 閾値の高い方から判定する順序に直し、複数台こなすほど正しく高いボーナス率が適用されるようにした。
    -- 2026-09-10 経済設計: 基準時給$7,500/hへの移行に伴い$530〜570から約2.85倍に引き上げ。
    -- 牽引対象車41箇所、デポ(471,-1311)から平均約3,400m。往復6.8km×道路係数1.35を60km/hで
    -- 走行し、フック/解除に2.5分。1件あたり約11.7分 → 5.1件/h。
    -- 旧$550では税15%引き後で実効約$2,520/hしかなく、全合法ジョブ中で最も低かった。
    -- ※この倍率は全ジョブ中で最大(×2.85)。実効時給の推定は移動時間の仮定に依存するため、
    --   他ジョブより誤差が大きい可能性がある。高すぎると感じた場合はここを最初に下げる。
    local DropPrice = math.random(1560, 1620)
    if drops > 20 then
        bonus = math.ceil((DropPrice / 10) * 12)
    elseif drops > 15 then
        bonus = math.ceil((DropPrice / 10) * 10)
    elseif drops > 10 then
        bonus = math.ceil((DropPrice / 10) * 7)
    elseif drops > 5 then
        bonus = math.ceil((DropPrice / 10) * 5)
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
