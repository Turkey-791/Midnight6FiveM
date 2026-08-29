local sharedItems = exports['qb-core']:GetShared('Items')

-- Money Authority fix (2026-08-29): 乗車開始時刻をcitizenid単位でサーバー側に記録し、
-- NpcPay支払い時に「経過時間から導ける現実的な運賃上限」でクライアント申告のpaymentをクランプする。
local TripStart = {}
-- 上限計算に使う想定最高巡航速度(m/s)。GTA車両でも十分速い前提の余裕あるバッファ値。
local MaxFareSpeedMps = 45.0
-- クランプ計算に掛ける安全バッファ倍率(タイマー粒度・NUI往復等の誤差を吸収するため)。
local MaxFareBufferMultiplier = 1.3
-- TripStartが取得できない場合(通信ロス・イベント未経由の直接呼び出し等)に許容する最低限のフロア額。
local MaxFareFloor = 50

function NearTaxi(src)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    for _, v in pairs(Config.NPCLocations.DeliverLocations) do
        local dist = #(coords - vector3(v.x, v.y, v.z))
        if dist < 20 then
            return true
        end
    end
end

-- Money Authority fix (2026-08-29): NPC乗車開始をクライアントから受け取り、citizenid単位で開始時刻を記録する。
RegisterNetEvent('qb-taxi:server:NpcTripStarted', function()
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= Config.jobRequired then return end
    TripStart[Player.PlayerData.citizenid] = GetGameTimer()
end)

RegisterNetEvent('qb-taxi:server:NpcPay', function(payment, hasReceivedBonus)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if Player.PlayerData.job.name == Config.jobRequired then
        if NearTaxi(src) then
            -- Money Authority fix (2026-08-29): クライアント申告のpayment(meterData.currentFare)は、
            -- 乗車開始からの経過時間より導ける現実的な運賃上限でクランプする。
            -- ボーナス/チップ等の既存計算式そのものは変更しない(下の payment への加算処理はそのまま)。
            local citizenid = Player.PlayerData.citizenid
            local startedAt = TripStart[citizenid]
            local elapsedMs = startedAt and (GetGameTimer() - startedAt) or 0
            if elapsedMs < 0 then elapsedMs = 0 end
            local elapsedSeconds = elapsedMs / 1000
            local maxDistanceMiles = (elapsedSeconds * MaxFareSpeedMps) / 1609.34
            local maxFare = (maxDistanceMiles * Config.Meter['defaultPrice']) + Config.Meter['startingPrice']
            maxFare = math.ceil(maxFare * MaxFareBufferMultiplier)
            if maxFare < MaxFareFloor then maxFare = MaxFareFloor end
            if payment > maxFare then payment = maxFare end
            TripStart[citizenid] = nil
            local randomAmount = math.random(1, 5)
            local r1, r2 = math.random(1, 5), math.random(1, 5)
            if randomAmount == r1 or randomAmount == r2 then payment = payment + math.random(10, 20) end

            if Config.Advanced.Bonus.Enabled then
                local tipAmount = math.floor(payment * Config.Advanced.Bonus.Percentage / 100)

                payment += tipAmount
                if hasReceivedBonus then
                    TriggerClientEvent('QBCore:Notify', src, string.format(Lang:t('info.tip_received'), tipAmount), 'primary', 5000)
                else
                    TriggerClientEvent('QBCore:Notify', src, Lang:t('info.tip_not_received'), 'primary', 5000)
                end
            end

            if Config.Management then
                exports['Renewed-Banking']:addAccountMoney('taxi', payment)
            else
                Player.AddMoney('cash', payment, 'Taxi payout')
            end

            local chance = math.random(1, 100)
            if chance < 26 then
                exports['qb-inventory']:AddItem(src, Config.Rewards, 1, false, false, 'qb-taxi:server:NpcPay')
                TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[Config.Rewards], 'add')
            end
        else
            DropPlayer(src, 'Attempting To Exploit')
        end
    else
        DropPlayer(src, 'Attempting To Exploit')
    end
end)

-- Money Authority fix (2026-08-29): ログアウト時にサーバー側の乗車開始記録を破棄する。
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        TripStart[Player.PlayerData.citizenid] = nil
    end
end)
