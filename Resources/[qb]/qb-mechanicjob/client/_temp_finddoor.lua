-- ============================================================
-- [TEMP DEBUG / 調査用・一時ファイル]
-- Bennysの塗装ブース手前にある「自動で開かないドア」の
-- モデルハッシュ/座標を特定するための一時的な調査コマンドです。
-- 恒久的な機能ではありません。特定が終わり次第、このファイル
-- (client/_temp_finddoor.lua) を削除してください。
--
-- 使い方:
--   1. ゲーム内でドアのすぐ手前(できるだけ近く)に立つ
--   2. チャット欄で /finddoor と入力して実行
--   3. F8キーでコンソールを開き、出力された一覧を確認
--      (距離が近い順に、モデルハッシュ・座標が表示されます)
--   4. その内容をそのままコピーして報告してください
-- ============================================================

RegisterCommand('finddoor', function()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local objectPool = GetGamePool('CObject')

    local found = {}
    for i = 1, #objectPool do
        local obj = objectPool[i]
        local objCoords = GetEntityCoords(obj)
        local dist = #(pedCoords - objCoords)
        if dist <= 25.0 then
            found[#found + 1] = {
                model = GetEntityModel(obj),
                dist = dist,
                coords = objCoords,
                heading = GetEntityHeading(obj)
            }
        end
    end

    table.sort(found, function(a, b) return a.dist < b.dist end)

    print('^3[finddoor]^7 -------- 近くのオブジェクト一覧 (自分の座標: ' ..
        string.format('%.2f, %.2f, %.2f', pedCoords.x, pedCoords.y, pedCoords.z) .. ') --------')

    local max = math.min(#found, 25)
    if max == 0 then
        print('^1[finddoor]^7 半径25m以内にオブジェクトが見つかりませんでした。')
    end

    for i = 1, max do
        local f = found[i]
        print(string.format(
            '^3[finddoor]^7 %2d. dist=%.2fm  model=%s  coords=%.2f, %.2f, %.2f  heading=%.1f',
            i, f.dist, f.model, f.coords.x, f.coords.y, f.coords.z, f.heading
        ))
    end

    print('^3[finddoor]^7 -------- 以上 --------')
    TriggerEvent('chat:addMessage', {
        color = { 255, 200, 0 },
        multiline = true,
        args = { 'finddoor', 'F8コンソールに近くのオブジェクト一覧(最大25件)を出力しました。' }
    })
end, false)

-- ============================================================
-- [TEMP DEBUG] /lookdoor
-- 画面中央(カメラの視線方向)にレイを飛ばして、今まさに見ている
-- オブジェクトを直接特定するコマンドです。ドアの正面に立ち、
-- 画面中央にドアを捉えた状態で実行してください。
-- ============================================================

local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local dx = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x))
    local dy = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x))
    local dz = math.sin(adjustedRotation.x)
    return vector3(dx, dy, dz)
end

RegisterCommand('lookdoor', function()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = RotationToDirection(camRot)
    local destination = camCoords + direction * 30.0

    local rayHandle = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        destination.x, destination.y, destination.z,
        -1, PlayerPedId(), 0
    )
    local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

    if hit == 1 and entityHit ~= 0 then
        local model = GetEntityModel(entityHit)
        local coords = GetEntityCoords(entityHit)
        local heading = GetEntityHeading(entityHit)
        local entType = GetEntityType(entityHit) -- 1=ped, 2=vehicle, 3=object
        print(string.format(
            '^2[lookdoor]^7 HIT! entityType=%d(1=ped/2=vehicle/3=object) model=%s coords=%.2f, %.2f, %.2f heading=%.1f',
            entType, model, coords.x, coords.y, coords.z, heading
        ))
        TriggerEvent('chat:addMessage', {
            color = { 0, 255, 0 },
            multiline = true,
            args = { 'lookdoor', string.format('model=%s coords=%.2f,%.2f,%.2f (F8コンソールに詳細)', model, coords.x, coords.y, coords.z) }
        })
    else
        print('^1[lookdoor]^7 30m以内で何にもヒットしませんでした。画面中央にドアを捉えて、ドアに向かってもう少し近づいてから再度実行してください。')
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            args = { 'lookdoor', '何もヒットしませんでした。ドアを画面中央に捉えて再実行してください。' }
        })
    end
end, false)

-- ============================================================
-- [TEMP DEBUG] /findspraydoor
-- Benny's Paint Booth調査指示書 Phase 2 対応。
-- 既知の候補モデルを、Bennysのpaint座標を中心に半径30mで
-- ピンポイント検索します(プレイヤーの立ち位置に依存しません)。
-- あわせて、同じ範囲内の全オブジェクトも列挙します。
-- ============================================================

RegisterCommand('findspraydoor', function()
    local origin = vector3(-202.42, -1322.16, 31.29) -- Config.Shops.bennys.paint
    local radius = 30.0

    local candidates = {
        { label = 'v_ilev_spraydoor (Cfx.re報告: 塗装ブースドア)', name = 'v_ilev_spraydoor' },
        { label = 'lr_prop_supermod_door_01 (Cfx.re報告: モータースポーツドア)', name = 'lr_prop_supermod_door_01' },
        { label = 'v_ilev_carmod3door (LS Customs系スプレールームドアの可能性)', name = 'v_ilev_carmod3door' },
    }

    print('^3[findspraydoor]^7 ======== 候補モデルのピンポイント検索 (中心: paint座標, 半径30m) ========')
    for _, c in ipairs(candidates) do
        local modelHash = GetHashKey(c.name)
        local obj = GetClosestObjectOfType(origin.x, origin.y, origin.z, radius, modelHash, false, false, false)
        if obj and obj ~= 0 then
            local coords = GetEntityCoords(obj)
            local heading = GetEntityHeading(obj)
            local dist = #(origin - coords)
            print(string.format(
                '^2[findspraydoor]^7 FOUND: %s / hash=%d / coords=%.2f,%.2f,%.2f / heading=%.1f / dist_from_paint=%.2f / entity=%s',
                c.label, modelHash, coords.x, coords.y, coords.z, heading, dist, tostring(obj)
            ))
        else
            print(string.format('^1[findspraydoor]^7 NOT FOUND: %s / hash=%d (半径30m以内に無し)', c.label, modelHash))
        end
    end

    print('^3[findspraydoor]^7 ======== 周辺オブジェクト一覧 (paint座標から30m以内、距離順) ========')
    local objectPool = GetGamePool('CObject')
    local found = {}
    for i = 1, #objectPool do
        local obj = objectPool[i]
        local objCoords = GetEntityCoords(obj)
        local dist = #(origin - objCoords)
        if dist <= radius then
            found[#found + 1] = { model = GetEntityModel(obj), dist = dist, coords = objCoords, heading = GetEntityHeading(obj) }
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)
    for i = 1, #found do
        local f = found[i]
        print(string.format(
            '^3[findspraydoor]^7 %2d. dist_from_paint=%.2fm  model=%s  coords=%.2f, %.2f, %.2f  heading=%.1f',
            i, f.dist, f.model, f.coords.x, f.coords.y, f.coords.z, f.heading
        ))
    end
    print(string.format('^3[findspraydoor]^7 合計 %d 件 (半径%.0fm以内)', #found, radius))
    print('^3[findspraydoor]^7 ======== 検索終了 ========')
end, false)
