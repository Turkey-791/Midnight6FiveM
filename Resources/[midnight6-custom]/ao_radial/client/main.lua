-- ============================================================================
-- ao_radial — ox_lib Radial メニュー (Midnight6 / 2026-09-11)
--
-- 【役割分担】
--   ao_radial      : ラジアルメニューの「UI」だけを担当する
--   qb-radialmenu  : ドア開閉 / 座席移動 / エクストラ / 服装トグル / トランク /
--                    ストレッチャー などの「実処理」を持つロジック置き場として残す
--
--   ★ qb-radialmenu を停止するとハンドラごと消えるため、停止してはいけない。
--     最終切替時は qb-radialmenu 側のキーマッピングを無効化するだけにする。
--
-- 【車外の車両操作について】
--   ox_target が標準機能(client/defaults.lua)で6枚のドア・ボンネット・トランクの
--   ターゲット操作を addGlobalVehicle 済み。かつ乗車中は無効(cache.vehicle 判定)。
--   したがって ao_radial の車両メニューは「乗車中のみ」表示する。
--
-- 【項目定義】
--   radial_items.lua は qb-radialmenu/config.lua からの自動生成物。
--   イベント名76件・39種が元と完全一致、keepOpen 29件も一致することを確認済み。
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject({ 'Functions' })
local Data = AoRadialData

local PlayerData = QBCore.Functions.GetPlayerData()

local ROOT_EMERGENCY = 'ao_emergency'
local ROOT_JOB       = 'ao_jobinteractions'
local ROOT_VEHICLE   = 'ao_vehicle'

local state = {
    base      = false,   -- 市民 / 一般 を追加済みか
    jobMenu    = nil,    -- 現在追加している Work のサブメニューID
    vehicle    = false,  -- 車両項目を追加済みか
    emergency  = false,  -- 緊急ボタンのみの状態か
}

local SEAT_LABELS = {
    [1] = '運転席',
    [2] = '助手席',
    [3] = '後部左座席',
    [4] = '後部右座席',
}
local SEAT_OTHER = '他の座席'

-- ---------------------------------------------------------------------------
-- データ定義 → ox_lib RadialItem
--
-- ★重要: qb-radialmenu は選択時に TriggerEvent(event, 項目テーブル) を呼び、
--   ハンドラ側が data.id / data.title を読む(ドア番号・エクストラ番号・座席index・
--   服装部位)。ox_lib の onSelect は項目を渡さないため、ここで同じ形の
--   テーブルを再構成して渡す。
-- ---------------------------------------------------------------------------
local function toRadialItem(def)
    local item = { id = def.id, label = def.label, icon = def.icon }

    if def.menu then
        item.menu = def.menu
        return item
    end

    if def.keepOpen then item.keepOpen = true end

    if not def.event then return item end

    local ev, ty = def.event, def.etype or 'client'
    local payload = { id = def.id, title = def.label }

    if ty == 'server' then
        item.onSelect = function() TriggerServerEvent(ev, payload) end
    elseif ty == 'command' then
        item.onSelect = function() ExecuteCommand(ev) end
    elseif ty == 'qbcommand' then
        item.onSelect = function() TriggerServerEvent('QBCore:CallCommand', ev, payload) end
    else
        item.onSelect = function() TriggerEvent(ev, payload) end
    end

    return item
end

local function buildItems(defs)
    local items = {}
    for i = 1, #defs do items[i] = toRadialItem(defs[i]) end
    return items
end

-- 静的サブメニューをすべて登録する(表示制御はルート項目の add/remove で行う)
local function registerStaticMenus()
    for menuId, defs in pairs(Data.menus) do
        lib.registerRadial({ id = menuId, items = buildItems(defs) })
    end
end

-- ---------------------------------------------------------------------------
-- ルート項目の出し入れ
-- ---------------------------------------------------------------------------
local function addBase()
    if state.base then return end
    local items = {}
    for i = 1, #Data.root do
        local d = Data.root[i]
        items[i] = { id = d.id, label = d.label, icon = d.icon, menu = d.menu }
    end
    lib.addRadialItem(items)
    state.base = true
end

local function removeBase()
    if not state.base then return end
    for i = 1, #Data.root do
        lib.removeRadialItem(Data.root[i].id)
    end
    state.base = false
end

-- Work メニュー ------------------------------------------------------------
-- ★ 2026-09-07 の Midnight6 独自修正の役割をここで引き継ぐ。
--   SetJob は 'job' キーだけで飛んでくるため、'all' を待っていると転職後に
--   リログするまで Work メニューが古いままになる。job 更新イベントで必ず作り直す。
local function refreshJobMenu()
    local job = PlayerData and PlayerData.job
    local key = job and job.name

    -- qb-radialmenu と同じ判定: job.type == 'leo' は police 扱い
    if job and job.type == 'leo' then key = 'police' end

    local menuId = (job and job.onduty) and key and Data.jobs[key] or nil

    if state.jobMenu == menuId then return end

    if state.jobMenu then
        lib.removeRadialItem(ROOT_JOB)
        state.jobMenu = nil
    end

    if menuId then
        lib.addRadialItem({
            id = ROOT_JOB,
            label = 'Work',
            icon = 'briefcase',
            menu = menuId,
        })
        state.jobMenu = menuId
    end
end

-- 車両メニュー(乗車中のみ) --------------------------------------------------
local function buildVehicleMenu(vehicle)
    local items = {
        { id = 'vehicledoors', label = '車両ドア', icon = 'car-side', menu = 'ao_vehicledoors' },
        { id = 'vehicleextras', label = '車両エクストラ', icon = 'star', menu = 'ao_vehicleextras' },
    }

    -- 座席は車種ごとに数が違うため、乗車のたびに作り直す
    local seats = {}
    local amount = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    for i = 1, amount do
        local label = SEAT_LABELS[i] or SEAT_OTHER
        local seatIndex = i - 2 -- qb-radialmenu と同じ変換(1→-1 が運転席)
        seats[#seats + 1] = {
            id = 'seat' .. i,
            label = label,
            icon = 'caret-up',
            keepOpen = true,
            onSelect = function()
                TriggerEvent('qb-radialmenu:client:ChangeSeat', { id = seatIndex, title = label })
            end,
        }
    end
    lib.registerRadial({ id = 'ao_vehicleseats', items = seats })
    items[#items + 1] = { id = 'vehicleseats', label = '車両座席', icon = 'chair', menu = 'ao_vehicleseats' }

    -- ひっくり返っているときだけ出す(qb-radialmenu と同条件)
    if not IsVehicleOnAllWheels(vehicle) then
        items[#items + 1] = {
            id = 'vehicle-flip',
            label = '車両をひっくり返す',
            icon = 'car-burst',
            onSelect = function() TriggerEvent('qb-radialmenu:flipVehicle') end,
        }
    end

    lib.registerRadial({ id = ROOT_VEHICLE, items = items })
end

local function addVehicle(vehicle)
    buildVehicleMenu(vehicle)
    if state.vehicle then return end
    lib.addRadialItem({ id = 'vehicle', label = 'Vehicle', icon = 'car', menu = ROOT_VEHICLE })
    state.vehicle = true
end

local function removeVehicle()
    if not state.vehicle then return end
    lib.removeRadialItem('vehicle')
    state.vehicle = false
end

-- 死亡・ラストスタンド -----------------------------------------------------
local function isDowned()
    local md = PlayerData and PlayerData.metadata
    return md and (md['isdead'] or md['inlaststand']) or false
end

local function isPoliceOrEMS()
    local job = PlayerData and PlayerData.job
    if not job then return false end
    return job.name == 'police' or job.type == 'leo' or job.name == 'ambulance'
end

-- qb-radialmenu と同じ挙動:
--   倒れている警察/EMS  → 緊急ボタンのみ
--   倒れている一般市民  → ラジアル自体を開けない
--   それ以外            → 通常表示
local function refreshDownedState()
    local downed = isDowned()

    if downed and isPoliceOrEMS() then
        lib.disableRadial(false)
        if not state.emergency then
            removeBase(); removeVehicle()
            if state.jobMenu then lib.removeRadialItem(ROOT_JOB); state.jobMenu = nil end
            lib.addRadialItem({
                id = ROOT_EMERGENCY,
                label = '緊急ボタン',
                icon = 'circle-exclamation',
                onSelect = function() TriggerEvent('police:client:SendPoliceEmergencyAlert') end,
            })
            state.emergency = true
        end
        return
    end

    if state.emergency then
        lib.removeRadialItem(ROOT_EMERGENCY)
        state.emergency = false
    end

    if downed then
        lib.disableRadial(true)
        return
    end

    lib.disableRadial(false)
    addBase()
    refreshJobMenu()
end

-- ---------------------------------------------------------------------------
-- イベント
-- ---------------------------------------------------------------------------
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    registerStaticMenus()
    refreshDownedState()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    lib.clearRadialItems()
    state.base, state.jobMenu, state.vehicle, state.emergency = false, nil, false, false
end)

RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    -- ★独自修正の引き継ぎ: 'job' キー単体で飛んでくるケースを取りこぼさない
    if key == 'job' then
        PlayerData.job = val
        refreshDownedState()
        return
    end
    if key == 'metadata' then
        PlayerData.metadata = val
        refreshDownedState()
        return
    end
    if key ~= 'all' then return end
    PlayerData = val
    refreshDownedState()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
    refreshJobMenu()
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onduty)
    if PlayerData and PlayerData.job then PlayerData.job.onduty = onduty end
    refreshJobMenu()
end)

-- 乗降の検知(ox_lib の cache を使う。ポーリングなし)
lib.onCache('vehicle', function(vehicle)
    if vehicle then
        addVehicle(vehicle)
    else
        removeVehicle()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    lib.clearRadialItems()
end)

-- リソース単体再起動時にも確実に表示されるよう、読み込み時に一度組み立てる
CreateThread(function()
    registerStaticMenus()
    if LocalPlayer.state.isLoggedIn then
        PlayerData = QBCore.Functions.GetPlayerData()
        refreshDownedState()
        if cache.vehicle then addVehicle(cache.vehicle) end
    end
end)
