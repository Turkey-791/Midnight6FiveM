local QBCore = exports['qb-core']:GetCoreObject({ 'Functions' })
local sharedItems = exports['qb-core']:GetShared('Items')

-- [2026-09-03 追加] ワイン醸造の180秒待機をサーバー側でも検証するための
-- 開始時刻記録テーブル(citizenid単位)。クライアント側のタイマー
-- (client.lua の winetimer)はUI表示用として残すが、報酬・アイテム付与の
-- 可否はこちらのサーバー側経過時間で判定する。
local WineBrewStarted = {}

-- ============================================================
-- [2026-09-04 追加] ジョブ受注(入社) -- 建物入口(ドア)でのEキー受注
--
-- 遵守事項:
--   - 距離はサーバー側でも検証する(クライアントのPolyZone判定だけに頼らない)
--   - 既にvineyard jobの場合は何もしない(二重受注防止)
-- ============================================================
RegisterNetEvent('qb-vineyard:server:applyJob', function()
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end

    if Player.PlayerData.job.name == 'vineyard' then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.already_employed'), 'error')
        return
    end

    local ped = GetPlayerPed(src)
    local pcoords = GetEntityCoords(ped)
    local doorCoords = Config.JobDoor.coords
    if #(pcoords - doorCoords) > Config.JobDoor.radius then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.too_far_to_apply'), 'error')
        return
    end

    Player.Functions.SetJob('vineyard', 0)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.job_applied'), 'success')
end)

RegisterNetEvent('qb-vineyard:server:getGrapes', function()
    local Player = exports['qb-core']:GetPlayer(source)
    -- [2026-09-03 追加] job認証(サーバー側)
    if not Player or Player.PlayerData.job.name ~= 'vineyard' then
        if Player then
            TriggerClientEvent('QBCore:Notify', source, Lang:t('error.invalid_job'), 'error')
        end
        return
    end
    local amount = math.random(Config.GrapeAmount.min, Config.GrapeAmount.max)
    exports['qb-inventory']:AddItem(source, 'grape', amount, false, false, 'qb-vineyard:server:getGrapes')
    TriggerClientEvent('qb-inventory:client:ItemBox', source, sharedItems['grape'], 'add')
end)

QBCore.Functions.CreateCallback('qb-vineyard:server:loadIngredients', function(source, cb)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    -- [2026-09-03 追加] job認証(サーバー側)。callbackのため、既存の呼び出し元
    -- (client.lua)が期待する戻り値(false)を返してから終了する。
    if not Player or Player.PlayerData.job.name ~= 'vineyard' then
        if Player then
            TriggerClientEvent('QBCore:Notify', source, Lang:t('error.invalid_job'), 'error')
        end
        cb(false)
        return
    end
    local grape = Player.GetItemByName('grapejuice')
    if Player.PlayerData.items ~= nil then
        if grape ~= nil then
            if grape.amount >= 23 then
                exports['qb-inventory']:RemoveItem(src, 'grapejuice', 23, false, 'qb-vineyard:server:loadIngredients')
                TriggerClientEvent('qb-inventory:client:ItemBox', source, sharedItems['grapejuice'], 'remove')
                -- [2026-09-03 追加] ワイン醸造開始時刻をサーバー側で記録(180秒検証用)
                WineBrewStarted[Player.PlayerData.citizenid] = os.time()
                cb(true)
            else
                TriggerClientEvent('QBCore:Notify', source, Lang:t('error.invalid_items'), 'error')
                cb(false)
            end
        else
            TriggerClientEvent('QBCore:Notify', source, Lang:t('error.invalid_items'), 'error')
            cb(false)
        end
    else
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.no_items'), 'error')
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('qb-vineyard:server:grapeJuice', function(source, cb)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    -- [2026-09-03 追加] job認証(サーバー側)
    if not Player or Player.PlayerData.job.name ~= 'vineyard' then
        if Player then
            TriggerClientEvent('QBCore:Notify', source, Lang:t('error.invalid_job'), 'error')
        end
        cb(false)
        return
    end
    local grape = Player.GetItemByName('grape')
    if Player.PlayerData.items ~= nil then
        if grape ~= nil then
            if grape.amount >= 16 then
                exports['qb-inventory']:RemoveItem(src, 'grape', 16, false, 'qb-vineyard:server:grapeJuice')
                TriggerClientEvent('qb-inventory:client:ItemBox', source, sharedItems['grape'], 'remove')
                cb(true)
            else
                TriggerClientEvent('QBCore:Notify', source, Lang:t('error.invalid_items'), 'error')
                cb(false)
            end
        else
            TriggerClientEvent('QBCore:Notify', source, Lang:t('error.invalid_items'), 'error')
            cb(false)
        end
    else
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.no_items'), 'error')
        cb(false)
    end
end)

RegisterNetEvent('qb-vineyard:server:receiveWine', function()
    local src = tonumber(source)
    local Player = exports['qb-core']:GetPlayer(src)
    -- [2026-09-03 追加] job認証(サーバー側)
    if not Player or Player.PlayerData.job.name ~= 'vineyard' then
        if Player then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_job'), 'error')
        end
        return
    end

    -- [2026-09-03 追加] 180秒経過のサーバー側検証。クライアントの
    -- winetimerは信用せず、loadIngredients時に記録した開始時刻からの
    -- 実経過時間のみで判定する。
    local citizenid = Player.PlayerData.citizenid
    local startedAt = WineBrewStarted[citizenid]
    if not startedAt or (os.time() - startedAt) < Config.wineTimer then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.wine_not_ready'), 'error')
        return
    end
    WineBrewStarted[citizenid] = nil

    local amount = math.random(Config.WineAmount.min, Config.WineAmount.max)
    exports['qb-inventory']:AddItem(src, 'wine', amount, false, false, 'qb-vineyard:server:receiveWine')
    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems['wine'], 'add')
end)

RegisterNetEvent('qb-vineyard:server:receiveGrapeJuice', function()
    local src = tonumber(source)
    local Player = exports['qb-core']:GetPlayer(src)
    -- [2026-09-03 追加] job認証(サーバー側)
    if not Player or Player.PlayerData.job.name ~= 'vineyard' then
        if Player then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_job'), 'error')
        end
        return
    end
    local amount = math.random(Config.GrapeJuiceAmount.min, Config.GrapeJuiceAmount.max)
    exports['qb-inventory']:AddItem(src, 'grapejuice', amount, false, false, 'qb-vineyard:server:receiveGrapeJuice')
    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems['grapejuice'], 'add')
end)

-- ============================================================
-- [2026-09-03 追加] wine納品(換金)処理 -- 作業報酬システム
--
-- 遵守事項:
--   - 報酬額は Config.WineSellPrice のみを参照する(数値を直書きしない)
--   - 数量はサーバー側で実在庫を確認し、クライアントからは受け取らない
--   - 固定単位(wine 1個)で処理する
--   - RemoveItemの成功を確認してからAddMoneyする(先払い禁止)
--   - job認証はサーバー側で行う
--   - 作業報酬のため、on-duty時のみ実行可能とする
-- ============================================================
RegisterNetEvent('qb-vineyard:server:sellWine', function()
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= 'vineyard' then
        if Player then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_job'), 'error')
        end
        return
    end

    if not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_on_duty'), 'error')
        return
    end

    local ped = GetPlayerPed(src)
    local pcoords = GetEntityCoords(ped)
    local sellCoords = Config.Vineyard.wine.coords
    if #(pcoords - sellCoords) > Config.WineSellRadius then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.too_far_to_sell'), 'error')
        return
    end

    local wine = Player.Functions.GetItemByName('wine')
    if not wine or wine.amount < 1 then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_wine'), 'error')
        return
    end

    local removed = Player.Functions.RemoveItem('wine', 1, false, 'qb-vineyard:server:sellWine')
    if not removed then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_wine'), 'error')
        return
    end
    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems['wine'], 'remove')

    Player.Functions.AddMoney('cash', Config.WineSellPrice, 'qb-vineyard:server:sellWine')
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.wine_sold', { value = Config.WineSellPrice }), 'success')
end)

-- [2026-09-03 追加] ログアウト時に未完了のワイン醸造記録を破棄する
-- (qb-towjob の TowDropoffCount クリア処理と同じ考え方)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        WineBrewStarted[Player.PlayerData.citizenid] = nil
    end
end)
