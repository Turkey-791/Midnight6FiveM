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
