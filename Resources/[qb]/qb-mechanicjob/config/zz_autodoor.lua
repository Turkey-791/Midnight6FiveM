-- ============================================================
-- [新機能 / 自動ドア] Config.AutoDoors
--
-- 「近づくと自動で開き、離れると閉まる」ドアの一覧です。
-- 現状はBennysの塗装ブース手前のドアのみ登録しています。
-- 他の店舗(mechanic/mechanic2/mechanic3/beeker)でも同様に
-- 自動で開かないドアが見つかった場合は、同じ形式で項目を
-- 追加するだけで対応できます(client/autodoor.lua側の変更は不要)。
--
-- 各項目のフィールド:
--   shop           : どの店舗向けかの管理用メモ(処理では未使用)
--   objName        : ドアのオブジェクトモデル名
--   objCoords      : ドアの座標 (vector3)
--   openDistance   : この距離以内に「authorizedJobsに該当する」
--                    プレイヤーが来ると開く
--   closeDistance  : この距離より離れると閉じる(openDistanceより
--                    大きい値にして、境界付近でのチャタリング=
--                    開閉の連続反転を防止しています)
--   authorizedJobs : { [ジョブ名] = 必要な最低グレード } の形式。
--                    該当しないプレイヤーには開きません。
-- ============================================================

Config.AutoDoors = {
    {
        shop = 'bennys', -- Bennys 塗装ブース手前のドア (/finddoor調査で特定)
        objName = 'v_ilev_fib_door1',
        objCoords = vector3(-205.22, -1328.03, 31.04),
        openDistance = 5.0,
        closeDistance = 8.0,
        authorizedJobs = { bennys = 0 }, -- [修正] Bennysの雇用主ジョブは'bennys'(mechanicとは別ジョブ)
    },
}
