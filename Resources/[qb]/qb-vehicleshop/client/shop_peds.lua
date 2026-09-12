--[[
    新設ショップの販売員ペド配置（2026-09-09）
    Big House Storage Inc.（マッスル/クーペ専門店）と
    Sanders Motorcycles（バイク専門店）に、静止ペドを1体ずつ配置します。

    2026-09-12 修正：
    以前はリソース起動と同時に CreatePed へ config の Z 値をそのまま渡していたため、
    Z 値が実際の地面より高いショップではペドが空中に浮いたままになっていました
    （接地処理が一切入っていなかった）。
    現在は「プレイヤーが近づいて地形コリジョンが読み込まれ、地面の高さが確定してから」
    生成します。Z 値が多少ずれていても地面に立ちます。
--]]

local ShopPeds = {
    {
        model = 'a_m_y_business_01',
        coords = vector4(-512.83, -2199.54, 6.39, 319.92), -- Big House Storage Inc.（マッスル/クーペ専門店）
    },
    {
        model = 'a_m_y_business_01',
        coords = vector4(306.39, -1163.21, 29.29, 299.41), -- Sanders Motorcycles（バイク専門店）
    },
}

local SPAWN_DISTANCE = 100.0 -- この距離まで近づいたら生成を試みる（コリジョンが読み込まれる距離）
local MAX_GROUND_DIFF = 10.0 -- config の Z からこの範囲内の地面のみ採用する（屋根などへの誤吸着を防ぐ）
local MAX_TRIES = 120        -- 地面高さの取得試行上限。超えたら config の Z をそのまま使う

-- 指定座標の地面の高さを返す。取得できなければ nil。
local function resolveGroundZ(coords)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    for _, offset in ipairs({ 2.0, 15.0 }) do
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + offset, false)
        if found and math.abs(groundZ - coords.z) <= MAX_GROUND_DIFF then
            return groundZ
        end
    end
    return nil
end

local function spawnShopPed(pedInfo)
    local coords = pedInfo.coords

    -- プレイヤーが近づくまで待つ（遠いとコリジョンが読み込まれず地面高さが取れない）
    while true do
        local pcoords = GetEntityCoords(PlayerPedId())
        if #(pcoords - vector3(coords.x, coords.y, coords.z)) < SPAWN_DISTANCE then break end
        Wait(2000)
    end

    -- 地面の高さが確定するまで待つ
    local groundZ = nil
    local tries = 0
    while not groundZ and tries < MAX_TRIES do
        groundZ = resolveGroundZ(coords)
        if not groundZ then
            tries = tries + 1
            Wait(250)
        end
    end
    local spawnZ = groundZ or coords.z

    local hash = GetHashKey(pedInfo.model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(hash) then return end

    local ped = CreatePed(4, hash, coords.x, coords.y, spawnZ, coords.w, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    SetModelAsNoLongerNeeded(hash)
end

CreateThread(function()
    for _, pedInfo in ipairs(ShopPeds) do
        CreateThread(function()
            spawnShopPed(pedInfo)
        end)
    end
end)

--[[
    補足：
    - モデル 'a_m_y_business_01'（スーツ姿の男性NPC）を仮で選んでいます。
      見た目を変えたい場合はこの2箇所のモデル名だけ書き換えてください。
    - このペドは会話・購入処理には一切関与しません（見た目だけの演出用）。
    - ペドはプレイヤーが約100m以内に近づいた時点で1回だけ生成されます（それより遠いと
      そもそも描画されないため、体感上の違いはありません）。
--]]
