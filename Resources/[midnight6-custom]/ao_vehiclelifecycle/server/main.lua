-- ============================================================================
-- ao_vehiclelifecycle / server
-- Phase G-1: サーバー権威の巡回ループ + 損傷スナップショット保存。
--            デポ送りは行わず、対象になった車をログに出すだけ(ドライラン)。
--
-- 既存リソースには一切変更を加えていない。このリソースを止めれば元の挙動に戻る。
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()
local sharedVehicles = exports['qb-core']:GetShared('Vehicles')

local OwnedPlates = {}   -- [plate] = { id, citizenid, model, class }
local Tracked     = {}   -- [plate] = { entity, wreckedSince, emptySince, reported, lastEng, lastBody }

local NativeOK = { health = nil, dead = nil, allVehicles = nil }

-- ---------------------------------------------------------------- utilities

local function log(fmt, ...)
    if not Config.Debug then return end
    print(('[ao_vlc] ' .. fmt):format(...))
end

local function warn(fmt, ...)
    print(('[ao_vlc] ^3WARN^7 ' .. fmt):format(...))
end

--- プレートの表記ゆれを吸収する。GetVehicleNumberPlateText は8文字に空白padされる。
local function normPlate(plate)
    if not plate then return nil end
    plate = plate:gsub('^%s*(.-)%s*$', '%1'):upper()
    if plate == '' then return nil end
    return plate
end

-- ------------------------------------------------- ネイティブ可用性の自己診断

--- サーバー側で車両の健康度ネイティブが使えるかを、実際の車両1台で1度だけ判定する。
--- 使えない場合は検知を行わず、その旨を明示してログに出す(黙って壊れないようにする)。
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
            warn('この場合はクライアントからの定期報告に切り替える必要があります。')
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
    local next_ = {}
    local count = 0

    for _, row in ipairs(rows or {}) do
        local plate = normPlate(row.plate)
        if plate then
            local shared = sharedVehicles[row.vehicle]
            local category = shared and shared.category or nil
            next_[plate] = {
                id        = row.id,
                citizenid = row.citizenid,
                model     = row.vehicle,
                class     = (category and Config.ClassOf[category]) or 'land',
            }
            count = count + 1
        end
    end

    OwnedPlates = next_
    log('所有車両プレートを %d 件読み込みました', count)
end

--- いま誰かが乗っている車両のエンティティ集合。
--- 車側から探すのではなくプレイヤー側から引く(サーバーで確実に動き、12人規模なら走査コストは無い)。
local function buildOccupiedSet()
    local occupied = {}
    for _, src in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            local veh = GetVehiclePedIsIn(ped)
            if veh and veh ~= 0 then
                occupied[veh] = true
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

    local fee = math.floor(price * rate)
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

    local e = math.ceil(eng)
    local b = math.ceil(body)

    -- 毎周期DBを叩かないよう、意味のある変化があったときだけ書く
    if state.lastEng and state.lastBody
        and math.abs(e - state.lastEng) < Config.SnapshotMinDelta
        and math.abs(b - state.lastBody) < Config.SnapshotMinDelta then
        return
    end

    state.lastEng, state.lastBody = e, b
    MySQL.update('UPDATE player_vehicles SET engine = ?, body = ? WHERE plate = ? AND state = 0',
        { e, b, plate })
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
    local row = MySQL.single.await('SELECT state FROM player_vehicles WHERE plate = ?', { plate })
    if not row then
        Tracked[plate] = nil
        return
    end
    if tonumber(row.state) ~= 0 then
        -- 出庫中ではない = ガレージ or 差し押さえ。追跡から外す。
        Tracked[plate] = nil
        return
    end

    local fee, price, rate, count = computeDepotPrice(owned, reason)
    state.reported = true

    if Config.EnableDepot then
        -- Phase G-2 で実装する。G-1では到達しない。
        warn('EnableDepot は true ですが、デポ送りの実処理は G-2 で実装します。何も行いません。')
        return
    end

    print(('[ao_vlc] ^3[DRY-RUN]^7 デポ送り対象: plate=%s model=%s class=%s / 理由=%s 経過=%d分(猶予%d分) / 過去%d回 → レート%.0f%% 価格$%s 請求$%s%s')
        :format(plate, owned.model, owned.class, reason,
                math.floor(elapsed / 60), math.floor(limit / 60),
                count, rate * 100, price, fee,
                state.entity and '' or ' [車体は既にワールドから消失]'))
end

-- ------------------------------------------------------------------ 巡回本体

local function scan()
    local now = os.time()
    local occupied = buildOccupiedSet()
    local seen = {}

    local vehicles
    local ok, res = pcall(GetAllVehicles)
    if not ok or type(res) ~= 'table' then
        if NativeOK.allVehicles == nil then
            NativeOK.allVehicles = false
            warn('サーバー側 GetAllVehicles() が使えません。巡回できないためG-1は機能しません。')
        end
        return
    end
    if NativeOK.allVehicles == nil then
        NativeOK.allVehicles = true
        log('^2OK^7 サーバー側 GetAllVehicles() が利用可能です')
    end
    vehicles = res

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

            local wrecked = (eng ~= nil) and (eng <= 0.0 or body <= 0.0)

            if wrecked then
                state.emptySince = nil
                state.wreckedSince = state.wreckedSince or now
            else
                state.wreckedSince = nil
                if occupied[veh] then
                    state.emptySince = nil
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
    print('[ao_vlc]  ao_vehiclelifecycle Phase G-1 起動')
    print('[ao_vlc]  デポ送り: ' .. (Config.EnableDepot and '有効' or '^3ドライラン(ログのみ)^7'))
    print('[ao_vlc]  損傷スナップショット: ' .. (Config.SaveSnapshots and '有効' or '無効'))
    print('[ao_vlc]  巡回間隔: ' .. Config.ScanInterval .. '秒')
    for _, class in ipairs({ 'land', 'air', 'sea' }) do
        local g = Config.Grace[class]
        print(('[ao_vlc]  猶予 %-4s: 大破%d分 / 無人%d分 (離脱後%d分)')
            :format(class, g.wrecked // 60, g.empty // 60, g.emptyOffline // 60))
    end
    print('[ao_vlc] ========================================================')

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

--- 現在の追跡状況をその場で確認するための管理者コマンド。
QBCore.Commands.Add('vlcstatus', '車両ライフサイクルの追跡状況を表示 (admin)', {}, false, function(source)
    local src = source
    local now = os.time()
    local lines = {}

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

    local header = ('[ao_vlc] 追跡中 %d 台 / 所有プレート %d 件 / 健康度ネイティブ %s')
        :format(#lines, (function() local c = 0 for _ in pairs(OwnedPlates) do c = c + 1 end return c end)(),
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
