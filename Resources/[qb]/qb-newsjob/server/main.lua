local QBCore = exports['qb-core']:GetCoreObject({ 'Functions', 'Commands' })

-- [2026-09-03 追加] 取材案件の進行状況をcitizenid単位で管理する。
-- エントリが無い = available、エントリがある = in_progress。
-- 支給が完了した時点でエントリを削除するため、completedという状態は
-- 「支給直後に即座にavailableへ戻る」という形で表現している。
local ActiveAssignment = {}

RegisterNetEvent('qb-newsjob:server:addVehicleItems', function(plate)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= 'reporter' then return end
    if not exports['qb-vehiclekeys']:HasKeys(src, plate) then return end

    exports['qb-inventory']:CreateInventory('trunk-' .. plate)

    for slot, item in pairs(Config.VehicleItems) do
        exports['qb-inventory']:AddItem('trunk-' .. plate, item.name, item.amount, slot, item.info, 'qb-newsjob:vehicleItems')
    end
end)

if Config.UseableItems then
    QBCore.Functions.CreateUseableItem('newscam', function(source)
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player or Player.PlayerData.job.name ~= 'reporter' then return end

        TriggerClientEvent('Cam:ToggleCam', source)
    end)

    QBCore.Functions.CreateUseableItem('newsmic', function(source)
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player or Player.PlayerData.job.name ~= 'reporter' then return end

        TriggerClientEvent('Mic:ToggleMic', source)
    end)

    QBCore.Functions.CreateUseableItem('newsbmic', function(source)
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player or Player.PlayerData.job.name ~= 'reporter' then return end

        TriggerClientEvent('Mic:ToggleBMic', source)
    end)
else
    QBCore.Commands.Add('newscam', 'Grab a news camera', {}, false, function(source, _)
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player or Player.PlayerData.job.name ~= 'reporter' then return end

        TriggerClientEvent('Cam:ToggleCam', source)
    end)

    QBCore.Commands.Add('newsmic', 'Grab a news microphone', {}, false, function(source, _)
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player or Player.PlayerData.job.name ~= 'reporter' then return end

        TriggerClientEvent('Mic:ToggleMic', source)
    end)

    QBCore.Commands.Add('newsbmic', 'Grab a Boom microphone', {}, false, function(source, _)
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player or Player.PlayerData.job.name ~= 'reporter' then return end

        TriggerClientEvent('Mic:ToggleBMic', source)
    end)
end

-- ============================================================
-- [2026-09-03 追加] 取材案件システム(作業報酬)
--
-- 流れ: /newsassignment で案件開始 -> 現地(client側)で撮影Progressbar ->
--       完了要求(completeAssignment) -> サーバー側で job・on-duty・
--       案件の有無・現在地との距離を確認してから報酬を支給する。
--
-- 遵守事項:
--   - 報酬額は Config.NewsReward のみを参照する(数値を直書きしない)
--   - カメラのON/OFFそのものは報酬トリガーにしない(既存のCam:ToggleCam等とは無関係)
--   - 同一案件について完了要求を複数回送っても二重に報酬が出ないようにする
--   - job認証・on-duty確認はサーバー側で行う
--   - 完了地点はサーバー側で実座標から検証する(クライアント申告値は使わない)
-- ============================================================

QBCore.Commands.Add('newsassignment', 'Request a news assignment', {}, false, function(source, _)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= 'reporter' then
        return
    end
    if not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_on_duty'), 'error')
        return
    end

    local citizenid = Player.PlayerData.citizenid
    if ActiveAssignment[citizenid] then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.assignment_in_progress'), 'error')
        return
    end

    if not Config.NewsLocations or #Config.NewsLocations == 0 then return end

    local locationIndex = math.random(#Config.NewsLocations)
    local location = Config.NewsLocations[locationIndex]

    ActiveAssignment[citizenid] = {
        coords = location.coords,
        label = location.label,
    }

    TriggerClientEvent('qb-newsjob:client:setAssignment', src, location)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.assignment_started', { label = location.label }), 'success')
end)

RegisterNetEvent('qb-newsjob:server:completeAssignment', function()
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= 'reporter' then
        return
    end
    if not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_on_duty'), 'error')
        return
    end

    local citizenid = Player.PlayerData.citizenid
    local assignment = ActiveAssignment[citizenid]
    if not assignment then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_assignment'), 'error')
        return
    end

    local ped = GetPlayerPed(src)
    local pcoords = GetEntityCoords(ped)
    local target = assignment.coords
    if #(pcoords - target) > Config.NewsReportRadius then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.too_far_from_assignment'), 'error')
        return
    end

    -- [2026-09-03] 二重報酬防止: 全ての確認を通過した直後、支給の直前に
    -- 即座にエントリを削除する。このハンドラ内にWait等の待機処理は無いため、
    -- この呼び出しが完了するまで同一プレイヤーからの2回目の要求が
    -- 割り込むことはない(FiveMのイベントハンドラはyieldしない限り
    -- 単一スレッドで最後まで実行される)。
    ActiveAssignment[citizenid] = nil

    Player.Functions.AddMoney('cash', Config.NewsReward, 'qb-newsjob:server:completeAssignment')
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.assignment_completed', { value = Config.NewsReward }), 'success')
    TriggerClientEvent('qb-newsjob:client:clearAssignment', src)
end)

-- [2026-09-03 追加] ログアウト時に進行中の取材案件を破棄する
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        ActiveAssignment[Player.PlayerData.citizenid] = nil
    end
end)
