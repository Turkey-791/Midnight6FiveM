-- ============================================================================
-- ao_vehiclelifecycle / server
-- Phase G-2: サーバー権威の巡回で「大破」「放置」を検知し、実際にデポ送りにする。
--            サーバー再起動時の未回収車も処理する(搭乗中だった車は無料で格納)。
--
-- デポ送りの状態遷移は qb-policejob の /depot と完全に同一(state=0 + depotprice>0)。
-- そのため回収UI・引き取り場所は qb-garages の既存のものがそのまま使える。
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()
local sharedVehicles = exports['qb-core']:GetShared('Vehicles')

local OwnedPlates   = {}  -- [plate] = { id, citizenid, model, class }
local Tracked       = {}  -- [plate] = { entity, wreckedSince, emptySince, reported, lastEng, lastBody }
local PendingOccupy = {}  -- [vehicleId] = { cid, ts }  -- 次のflushでDBへ

local NativeOK = { health = nil, allVehicles = nil }

-- ---------------------------------------------------------------- utilities

local function log(fmt, ...)
    if not Config.Debug then return end
    print(('[ao_vlc] ' .. fmt):format(...))
end

local function warn(fmt, ...)
    print(('[ao_vlc] ^3WARN^7 ' .. fmt):format(...))
end

local function comma(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local out = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    return (out:gsub('^,', ''))
end

--- プレートの表記ゆれを吸収する。GetVehicleNumberPlateText は8文字に空白padされる。
local function normPlate(plate)
    if not plate then return nil end
    plate = plate:gsub('^%s*(.-)%s*$', '%1'):upper()
    if plate == '' then return nil end
    return plate
end

local function classOfModel(model)
    local shared = sharedVehicles[model]
    local category = shared and shared.category or nil
    return (category and Config.ClassOf[category]) or 'land'
end

-- ------------------------------------------------- ネイティブ可用性の自己診断

local function readHealth(veh)
    if NativeOK.health == false then return nil, nil end

    local ok, eng, body = pcall(function()
        return GetVehicleEngineHealth(veh), GetVehicleBodyHealth(veh)
    end)

    if not ok or type(eng) ~= 'number' or type(body) ~= 'number' then
        if NativeOK.health == nil then
            NativeOK.health = false
            warn('サーバー側の GetVehicleEngineHealth / GetVehicleBodyHealth が使えません。')
            warn('大破検知と損傷スナップショットは無効です(放置検知は引き続き動作します)。')
        end
        return nil, nil
    end

    if NativeOK.health == nil then
        NativeOK.health = true
        log('^2OK^7 サーバー側の車両健康度ネイティブが利用可能です (engine=%.1f body=%.1f)', eng, body)
    end
    return eng, body
end

-- --------------------------------------------------------- キャッシュの構築

local function refreshPlateCache()
    local rows = MySQL.query.await('SELECT id, plate, citizenid, vehicle FROM player_vehicles')
    local next_, count = {}, 0

    for _, row in ipairs(rows or {}) do
        local plate = normPlate(row.plate)
        if plate then
            next_[plate] = {
                id        = row.id,
                citizenid = row.citizenid,
                model     = row.vehicle,
                class     = classOfModel(row.vehicle),
            }
            count = count + 1
        end
    end

    OwnedPlates = next_
    log('所有車両プレートを %d 件読み込みました', count)
end

--- いま誰かが乗っている車両。値は搭乗者のcitizenid(取れないときは true)。
--- 車側から探すのではなくプレイヤー側から引く(サーバーで確実に動き、12人規模なら走査コストは無い)。
local function buildOccupiedSet()
    local occupied = {}
    for _, src in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            local veh = GetVehiclePedIsIn(ped)
            if veh and veh ~= 0 then
                local Player = QBCore.Functions.GetPlayer(tonumber(src))
                occupied[veh] = (Player and Player.PlayerData.citizenid) or true
            end
        end
    end
    return occupied
end

local function isOwnerOnline(citizenid)
    return QBCore.Functions.GetPlayerByCitizenId(citizenid) ~= nil
end

-- ------------------------------------------------------------------ 料金計算

--- その車が過去に何回デポ送りになったかを引く。
--- キーは plate ではなく player_vehicles.id。中古車売買でプレートが使い回されても
--- 前オーナーの事故歴を引き継がないようにするため。
local function getDepotCount(vehicleId)
    if not vehicleId then return 0 end
    local n = MySQL.scalar.await('SELECT count FROM ao_depot_history WHERE vehicle_id = ?', { vehicleId })
    return tonumber(n) or 0
end

local function computeDepotPrice(owned, reason)
    local shared = sharedVehicles[owned.model]
    local price = (shared and tonumber(shared.price)) or Config.DepotFallbackPrice

    local ladder = Config.DepotRate[reason]
    local count  = getDepotCount(owned.id)
    local rate   = ladder[math.min(count + 1, #ladder)]

    -- math.floor だと浮動小数点の誤差で1円下振れすることがあるため四捨五入する
    local fee = math.floor(price * rate + 0.5)
    local min = Config.DepotMin[reason] or 0
    if fee < min then fee = min end

    return fee, price, rate, count
end

-- ------------------------------------------------------------ スナップショット

--- engine / body のみをサーバー権威で保存する。
--- fuel と mods はクライアント側でしか取得できないため、ここでは触らない。
--- state = 0(出庫中)の行だけを更新し、既にガレージに入っている車の保存値を壊さない。
local function saveSnapshot(plate, state, eng, body)
    if not Config.SaveSnapshots then return end

    -- マイナス値をそのまま保存すると、デポから復元した直後に再び大破と判定され、
    -- 10分後にまたデポ送りになる無限ループに陥る。下限で止める。
    local e = math.max(Config.SaveEngineFloor, math.ceil(eng))
    local b = math.max(Config.SaveBodyFloor, math.ceil(body))

    if state.lastEng and state.lastBody
        and math.abs(e - state.lastEng) < Config.SnapshotMinDelta
        and math.abs(b - state.lastBody) < Config.SnapshotMinDelta then
        return
    end

    state.lastEng, state.lastBody = e, b
    MySQL.update('UPDATE player_vehicles SET engine = ?, body = ? WHERE plate = ? AND state = 0',
        { e, b, plate })
end

-- ---------------------------------------------------------------- デポ送り

local REASON_LABEL = { destroyed = '大破', abandoned = '放置' }

--- 実際にデポへ送る。
--- state=0 のままDBの depotprice を立てるだけ(警察の /depot と同じ状態遷移)。
--- 条件付きUPDATEなので、同時にガレージへ預けられた等の競合では何も起きない。
local function sendToDepot(plate, owned, reason, state)
    local fee, price, rate, count = computeDepotPrice(owned, reason)

    local eng, body
    if state and state.entity and DoesEntityExist(state.entity) then
        eng, body = readHealth(state.entity)
    end

    local affected
    if eng then
        affected = MySQL.update.await(
            'UPDATE player_vehicles SET state = 0, depotprice = ?, engine = ?, body = ? WHERE plate = ? AND citizenid = ? AND state = 0 AND COALESCE(depotprice, 0) = 0',
            { fee,
              math.max(Config.SaveEngineFloor, math.ceil(eng)),
              math.max(Config.SaveBodyFloor, math.ceil(body)),
              plate, owned.citizenid })
    else
        affected = MySQL.update.await(
            'UPDATE player_vehicles SET state = 0, depotprice = ? WHERE plate = ? AND citizenid = ? AND state = 0 AND COALESCE(depotprice, 0) = 0',
            { fee, plate, owned.citizenid })
    end

    if not affected or affected == 0 then
        -- 競合(既にガレージへ預けられた・押収された等)。料金は課さない。
        if state then state.reported = nil end
        Tracked[plate] = nil
        log('デポ送りを見送り(競合): plate=%s', plate)
        return false
    end

    -- 回数を1つ進める。キーは player_vehicles.id。
    MySQL.update(
        'INSERT INTO ao_depot_history (vehicle_id, count, last_at) VALUES (?, 1, ?) ' ..
        'ON DUPLICATE KEY UPDATE count = count + 1, last_at = VALUES(last_at)',
        { owned.id, os.time() })

    if state and state.entity and DoesEntityExist(state.entity) then
        DeleteEntity(state.entity)
    end

    Tracked[plate] = nil

    if Config.NotifyOwner then
        local Player = QBCore.Functions.GetPlayerByCitizenId(owned.citizenid)
        if Player then
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source,
                ('%sした車両(%s)がデポに移送されました。引き取りには $%s かかります')
                    :format(REASON_LABEL[reason] or reason, plate, comma(fee)),
                'error', 12000)
        end
    end

    print(('[ao_vlc] ^1[DEPOT]^7 %s → デポ送り: plate=%s model=%s class=%s / %d回目 レート%.0f%% 価格$%s 請求$%s')
        :format(REASON_LABEL[reason] or reason, plate, owned.model, owned.class,
                count + 1, rate * 100, comma(price), comma(fee)))
    return true
end

-- ---------------------------------------------------------------- 状態の評価

local function evaluate(plate, owned, state, now)
    local grace = Config.Grace[owned.class] or Config.Grace.land
    local reason, elapsed, limit

    if state.wreckedSince then
        reason  = 'destroyed'
        elapsed = now - state.wreckedSince
        limit   = grace.wrecked
    elseif state.emptySince then
        reason  = 'abandoned'
        elapsed = now - state.emptySince
        limit   = isOwnerOnline(owned.citizenid) and grace.empty or grace.emptyOffline
    else
        state.reported = nil
        return
    end

    if elapsed < limit then return end
    if state.reported then return end

    -- 猶予を超えた時点で初めてDBを引く(毎周期は引かない)。
    -- ガレージに預けられた・既に押収された車を誤って対象にしないための確認。
    local row = MySQL.single.await('SELECT state, depotprice FROM player_vehicles WHERE plate = ?', { plate })
    if not row or tonumber(row.state) ~= 0 then
        Tracked[plate] = nil
        return
    end
    -- 既にデポ送り済み(警察の /depot 分も含む)なら二重に請求しない。
    -- 車体の削除に失敗した場合などに、同じ車を繰り返し課金してしまうのを防ぐ。
    if (tonumber(row.depotprice) or 0) > 0 then
        Tracked[plate] = nil
        return
    end

    state.reported = true

    if Config.EnableDepot then
        sendToDepot(plate, owned, reason, state)
        return
    end

    local fee, price, rate, count = computeDepotPrice(owned, reason)
    print(('[ao_vlc] ^3[DRY-RUN]^7 デポ送り対象: plate=%s model=%s class=%s / 理由=%s 経過=%d分(猶予%d分) / 過去%d回 → レート%.0f%% 価格$%s 請求$%s%s')
        :format(plate, owned.model, owned.class, reason,
                elapsed // 60, limit // 60,
                count, rate * 100, comma(price), comma(fee),
                state.entity and '' or ' [車体は既にワールドから消失]'))
end

-- ------------------------------------------------------------------ 巡回本体

local function flushOccupancy(now)
    for vehId, o in pairs(PendingOccupy) do
        MySQL.update(
            'INSERT INTO ao_vlc_occupancy (vehicle_id, occupant_cid, occupied_at) VALUES (?, ?, ?) ' ..
            'ON DUPLICATE KEY UPDATE occupant_cid = VALUES(occupant_cid), occupied_at = VALUES(occupied_at)',
            { vehId, o.cid, o.ts })
    end
    PendingOccupy = {}

    MySQL.update('INSERT INTO ao_vlc_meta (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)',
        { 'last_tick', now })
end

local function scan()
    local now = os.time()
    local occupied = buildOccupiedSet()
    local seen = {}

    local ok, vehicles = pcall(GetAllVehicles)
    if not ok or type(vehicles) ~= 'table' then
        if NativeOK.allVehicles == nil then
            NativeOK.allVehicles = false
            warn('サーバー側 GetAllVehicles() が使えません。巡回できません。')
        end
        return
    end
    if NativeOK.allVehicles == nil then
        NativeOK.allVehicles = true
        log('^2OK^7 サーバー側 GetAllVehicles() が利用可能です')
    end

    for _, veh in ipairs(vehicles) do
        -- 所有車がワールドに出ていなくても診断結果が分かるよう、
        -- 最初に見つかった車両(NPC車でもよい)で健康度ネイティブの可用性を1度だけ判定する。
        if NativeOK.health == nil then readHealth(veh) end

        local plate = normPlate(GetVehicleNumberPlateText(veh))
        local owned = plate and OwnedPlates[plate] or nil

        if owned then
            seen[plate] = true

            local state = Tracked[plate]
            if not state then
                state = {}
                Tracked[plate] = state
            end
            state.entity = veh

            local eng, body = readHealth(veh)
            if eng then saveSnapshot(plate, state, eng, body) end

            -- 「負の値 = 実際に壊された」で判定する。engine がちょうど0の車
            -- (デポから復元した修理待ちの車など)を再び大破扱いしないため。
            local wrecked = (eng ~= nil) and (eng < Config.WreckedEngine or body <= 0.0)
            local occ = occupied[veh]

            if wrecked then
                state.emptySince = nil
                state.wreckedSince = state.wreckedSince or now
            else
                state.wreckedSince = nil
                if occ then
                    state.emptySince = nil
                    -- 再起動時の救済判定に使うため、搭乗の事実を残す
                    PendingOccupy[owned.id] = { cid = (occ ~= true) and occ or nil, ts = now }
                else
                    state.emptySince = state.emptySince or now
                end
            end

            evaluate(plate, owned, state, now)
        end
    end

    -- ワールドから消えた追跡対象の扱い。
    -- 爆発した残骸が猶予の途中で自然消滅することがあるため、消えた=追跡終了にはしない。
    -- 無人として計測を続け、猶予を過ぎたら通常どおり評価する。
    -- (ガレージに預けた場合も消えるが、evaluate() 内の state 確認で除外される)
    for plate, state in pairs(Tracked) do
        if not seen[plate] then
            local owned = OwnedPlates[plate]
            if not owned then
                Tracked[plate] = nil
            else
                state.entity = nil
                if not state.wreckedSince then
                    state.emptySince = state.emptySince or now
                end
                evaluate(plate, owned, state, now)
            end
        end
    end

    flushOccupancy(now)
end

-- -------------------------------------------------- サーバー再起動時の処理

--- 再起動時に残っていた state=0 の車を処理する。
--- 停止直前に搭乗していた車(かつ搭乗者がオーナー本人)は無料でガレージへ。
--- それ以外はデポ送り(放置と同レート)。
local function handleRestart()
    if not Config.HandleRestart then return end

    -- 誤爆防止: サーバー起動直後でなければ何もしない。
    -- 稼働中の restart ao_vehiclelifecycle で全車がデポ送りになるのを防ぐ。
    local uptime = GetGameTimer() / 1000
    if uptime > Config.RestartSweepMaxUptime then
        log('再起動処理はスキップします(サーバー稼働時間 %d秒 > %d秒。リソース単体の再起動と判断)',
            math.floor(uptime), Config.RestartSweepMaxUptime)
        return
    end

    local lastTick = tonumber(MySQL.scalar.await('SELECT v FROM ao_vlc_meta WHERE k = ?', { 'last_tick' })) or 0

    -- 初回導入時は搭乗履歴が存在しないため、判定材料が無いまま全車が課金対象になってしまう。
    -- 誰も損をしないよう、この一度だけは従来どおり無料でガレージへ戻す。
    if lastTick == 0 then
        local n = MySQL.update.await(
            'UPDATE player_vehicles SET state = 1 WHERE state = 0 AND COALESCE(depotprice, 0) = 0')
        MySQL.update('INSERT INTO ao_vlc_meta (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)',
            { 'last_tick', os.time() })
        print(('[ao_vlc] 再起動処理: 搭乗履歴がまだ無いため、今回は従来どおり %d台 を無料でガレージへ戻しました(初回のみ)')
            :format(n or 0))
        return
    end

    local rows = MySQL.query.await([[
        SELECT pv.id, pv.plate, pv.citizenid, pv.vehicle,
               o.occupant_cid, o.occupied_at
          FROM player_vehicles pv
     LEFT JOIN ao_vlc_occupancy o ON o.vehicle_id = pv.id
         WHERE pv.state = 0
           AND COALESCE(pv.depotprice, 0) = 0
    ]])

    local rescued, depoted = 0, 0

    for _, row in ipairs(rows or {}) do
        local owned = {
            id        = row.id,
            citizenid = row.citizenid,
            model     = row.vehicle,
            class     = classOfModel(row.vehicle),
        }

        local wasOccupied = false
        if lastTick > 0 and tonumber(row.occupied_at or 0) > 0 then
            if tonumber(row.occupied_at) >= (lastTick - Config.RestartOccupiedWindow) then
                wasOccupied = (not Config.RestartRescueRequiresOwner)
                    or (row.occupant_cid ~= nil and row.occupant_cid == row.citizenid)
            end
        end

        if wasOccupied then
            -- 普通に運転していただけの車。料金は取らずガレージへ戻す。
            local n = MySQL.update.await(
                'UPDATE player_vehicles SET state = 1 WHERE id = ? AND state = 0', { row.id })
            if n and n > 0 then rescued = rescued + 1 end
        else
            local fee = computeDepotPrice(owned, 'abandoned')
            local n = MySQL.update.await(
                'UPDATE player_vehicles SET state = 0, depotprice = ? WHERE id = ? AND state = 0 AND COALESCE(depotprice, 0) = 0',
                { fee, row.id })
            if n and n > 0 then
                depoted = depoted + 1
                MySQL.update(
                    'INSERT INTO ao_depot_history (vehicle_id, count, last_at) VALUES (?, 1, ?) ' ..
                    'ON DUPLICATE KEY UPDATE count = count + 1, last_at = VALUES(last_at)',
                    { row.id, os.time() })
            end
        end
    end

    -- 前回セッションの搭乗記録は使い終わったので破棄する
    MySQL.update.await('DELETE FROM ao_vlc_occupancy')

    print(('[ao_vlc] 再起動処理: 無料で格納 %d台 / デポ送り %d台 (対象 %d台)')
        :format(rescued, depoted, #(rows or {})))
end

-- -------------------------------------------------------------------- 起動

CreateThread(function()
    Wait(3000)

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ao_depot_history` (
            `vehicle_id` INT NOT NULL PRIMARY KEY,
            `count`      INT NOT NULL DEFAULT 0,
            `last_at`    INT NOT NULL DEFAULT 0
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ao_vlc_occupancy` (
            `vehicle_id`   INT NOT NULL PRIMARY KEY,
            `occupant_cid` VARCHAR(50) NULL,
            `occupied_at`  INT NOT NULL DEFAULT 0
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ao_vlc_meta` (
            `k` VARCHAR(32) NOT NULL PRIMARY KEY,
            `v` INT NOT NULL DEFAULT 0
        )
    ]])

    -- 2026-09-09: G-2初期版がマイナスのengine値をそのまま保存していたため、
    -- デポから復元した車が即座に再び大破判定される状態のデータが残っている。
    -- 一度だけ正規化する(冪等なので毎起動走っても害はない)。
    local fixedE = MySQL.update.await('UPDATE player_vehicles SET engine = ? WHERE engine < ?',
        { Config.SaveEngineFloor, Config.SaveEngineFloor })
    local fixedB = MySQL.update.await('UPDATE player_vehicles SET body = ? WHERE body < ?',
        { Config.SaveBodyFloor, Config.SaveBodyFloor })
    if (fixedE or 0) > 0 or (fixedB or 0) > 0 then
        log('マイナス値になっていた損傷値を正規化しました (engine %d件 / body %d件)', fixedE or 0, fixedB or 0)
    end

    -- 廃車・ローン差し押さえ・中古車売買で残った孤児行を掃除する
    local removed = MySQL.update.await([[
        DELETE FROM ao_depot_history
         WHERE vehicle_id NOT IN (SELECT id FROM player_vehicles)
    ]])
    if removed and removed > 0 then
        log('ao_depot_history の孤児行を %d 件削除しました', removed)
    end

    refreshPlateCache()

    print('[ao_vlc] ========================================================')
    print('[ao_vlc]  ao_vehiclelifecycle Phase G-2 起動')
    print('[ao_vlc]  デポ送り: ' .. (Config.EnableDepot and '^1有効^7' or '^3ドライラン(ログのみ)^7'))
    print('[ao_vlc]  損傷スナップショット: ' .. (Config.SaveSnapshots and '有効' or '無効'))
    print('[ao_vlc]  巡回間隔: ' .. Config.ScanInterval .. '秒')
    for _, class in ipairs({ 'land', 'air', 'sea' }) do
        local g = Config.Grace[class]
        print(('[ao_vlc]  猶予 %-4s: 大破%d分 / 無人%d分 (離脱後%d分)')
            :format(class, g.wrecked // 60, g.empty // 60, g.emptyOffline // 60))
    end
    print('[ao_vlc] ========================================================')

    handleRestart()

    CreateThread(function()
        while true do
            Wait(Config.PlateCacheRefresh * 1000)
            refreshPlateCache()
        end
    end)

    while true do
        local ok, err = pcall(scan)
        if not ok then
            warn('巡回中にエラー: %s', tostring(err))
        end
        Wait(Config.ScanInterval * 1000)
    end
end)

-- ------------------------------------------------------------------ 確認用

QBCore.Commands.Add('vlcstatus', '車両ライフサイクルの追跡状況を表示 (admin)', {}, false, function(source)
    local src = source
    local now = os.time()
    local lines, owned_n = {}, 0

    for _ in pairs(OwnedPlates) do owned_n = owned_n + 1 end

    for plate, state in pairs(Tracked) do
        local owned = OwnedPlates[plate]
        if owned then
            local phase, since
            if state.wreckedSince then
                phase, since = '大破', now - state.wreckedSince
            elseif state.emptySince then
                phase, since = '無人', now - state.emptySince
            else
                phase, since = '乗車中', 0
            end
            lines[#lines + 1] = ('%s (%s/%s) %s %d秒%s')
                :format(plate, owned.model, owned.class, phase, since,
                        state.entity and '' or ' [消失]')
        end
    end

    local header = ('[ao_vlc] 追跡中 %d台 / 所有プレート %d件 / デポ送り %s / 健康度ネイティブ %s')
        :format(#lines, owned_n,
                Config.EnableDepot and '有効' or 'ドライラン',
                tostring(NativeOK.health))

    if src == 0 then
        print(header)
        for _, l in ipairs(lines) do print('  ' .. l) end
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'ao_vlc', header } })
        for _, l in ipairs(lines) do
            TriggerClientEvent('chat:addMessage', src, { args = { 'ao_vlc', l } })
        end
    end
end, 'admin')

-- ==========================================================================
-- デポ引き取り時の「修理込み」オプション
-- 一般プレイヤーは advancedrepairkit を買えない(販売5店舗すべてに requiredJob あり)ため、
-- メカニック職がオフラインだとエンジンの死んだ車を動かす手段が無くなる。その救済。
-- ==========================================================================

local function isNearDepot(src)
    if not Config.VerifyDepotDistance then return true end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    for _, p in ipairs(Config.DepotPoints or {}) do
        if #(coords - vector3(p.x, p.y, p.z)) <= (Config.DepotRadius or 20.0) then
            return true
        end
    end
    return false
end

--- mods(完全プロパティJSON)から損傷情報を取り除く。
--- qb-garages の出庫時は SetVehicleProperties(mods) → doCarDamage(stats, props) の順で
--- 適用されるため、mods 側の損傷も消さないと修理したことにならない。
local function clearDamageFromMods(modsJson)
    if not modsJson then return nil end
    local ok, props = pcall(json.decode, modsJson)
    if not ok or type(props) ~= 'table' then return nil end

    props.engineHealth   = 1000.0
    props.bodyHealth     = 1000.0
    props.tankHealth     = 1000.0
    props.dirtLevel      = 0.0
    props.doorStatus     = nil
    props.tireBurstState = nil
    props.windowStatus   = nil
    props.tireHealth     = nil

    local ok2, encoded = pcall(json.encode, props)
    if not ok2 then return nil end
    return encoded
end

RegisterNetEvent('ao_vehiclelifecycle:server:payDepotWithRepair', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Config.DepotRepairEnabled then return end

    local plate = normPlate(data and data.plate)
    if not plate then return end

    if not isNearDepot(src) then
        TriggerClientEvent('QBCore:Notify', src, 'デポから離れすぎています', 'error')
        return
    end

    -- 料金はクライアントの申告を一切信用せず、必ずDBから引く
    local row = MySQL.single.await(
        'SELECT citizenid, state, depotprice, fuel, mods FROM player_vehicles WHERE plate = ?', { plate })
    if not row or row.citizenid ~= Player.PlayerData.citizenid then return end
    if tonumber(row.state) ~= 0 then return end

    local depotPrice = tonumber(row.depotprice) or 0
    if depotPrice <= 0 then return end

    local repairFee = Config.DepotRepairFee or 0
    local total     = depotPrice + repairFee

    local paidFrom
    if Player.PlayerData.money['cash'] >= total then
        Player.Functions.RemoveMoney('cash', total, 'depot-with-repair')
        paidFrom = 'cash'
    elseif Player.PlayerData.money['bank'] >= total then
        Player.Functions.RemoveMoney('bank', total, 'depot-with-repair')
        paidFrom = 'bank'
    else
        TriggerClientEvent('QBCore:Notify', src,
            ('所持金が足りません(引き取り $%s ＋ 修理 $%s = $%s)')
                :format(comma(depotPrice), comma(repairFee), comma(total)), 'error')
        return
    end

    local newMods = clearDamageFromMods(row.mods)

    -- 条件付きUPDATE。二重引き取り・競合時は0件になる。
    local affected
    if newMods then
        affected = MySQL.update.await(
            'UPDATE player_vehicles SET depotprice = 0, engine = 1000, body = 1000, mods = ? ' ..
            'WHERE plate = ? AND citizenid = ? AND state = 0 AND COALESCE(depotprice, 0) > 0',
            { newMods, plate, Player.PlayerData.citizenid })
    else
        affected = MySQL.update.await(
            'UPDATE player_vehicles SET depotprice = 0, engine = 1000, body = 1000 ' ..
            'WHERE plate = ? AND citizenid = ? AND state = 0 AND COALESCE(depotprice, 0) > 0',
            { plate, Player.PlayerData.citizenid })
    end

    if not affected or affected == 0 then
        -- 競合(既に別経路で引き取られた等)。取った分は必ず全額返す。
        Player.Functions.AddMoney(paidFrom, total, 'depot-with-repair-refund')
        TriggerClientEvent('QBCore:Notify', src, '引き取りに失敗しました。料金は返金されています', 'error')
        return
    end

    Tracked[plate] = nil

    -- 出庫時に適用される損傷値も修理後のものに差し替えて渡す。
    -- (NUIが一覧を作った時点の古い値がそのまま使われるのを防ぐ)
    data.depotPrice = 0
    data.stats = {
        fuel   = tonumber(row.fuel) or 100,
        engine = 1000,
        body   = 1000,
    }

    TriggerClientEvent('QBCore:Notify', src,
        ('修理込みで引き取りました($%s)'):format(comma(total)), 'success')
    TriggerClientEvent('qb-garages:client:takeOutGarage', src, data)

    log('修理込み引き取り: plate=%s 引き取り$%s + 修理$%s = $%s (%s払い)',
        plate, comma(depotPrice), comma(repairFee), comma(total), paidFrom)
end)
