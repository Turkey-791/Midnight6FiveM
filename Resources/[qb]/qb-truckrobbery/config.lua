Config = {}

Config.MissionMarker = vector3(960.71197509766, -215.51979064941, 76.2552947998)  -- place where is the marker with the mission
Config.DealerCoords = vector3(960.78, -216.25, 76.25)                             -- place where the NPC dealer stands
Config.VehicleSpawn = {                                                           -- below the coordinates for random vehicle responses
    vector3(-1327.479736328, -86.045326232910, 49.31),
    vector3(-2075.888183593, -233.73908996580, 21.10),
    vector3(-972.1781616210, -1530.9045410150, 4.890),
    vector3(798.18426513672, -1799.8173828125, 29.33),
    vector3(1247.0718994141, -344.65634155273, 69.08)
}
Config.DriverWeap = `WEAPON_MICROSMG` -- Weapon for truck driver to spawn with
Config.NavWeap = `WEAPON_MICROSMG`    -- Weapon for navigator to spawn with
Config.TimeToBlow = 30                -- bomb detonation time after planting, in seconds
Config.ActivePolice = 0               -- needed policemen to activate the mission
-- 2026-09-10 経済設計: 改定前は「報酬$250〜450 に対して起動コスト$500」で、
-- 成功しても期待値がマイナスになる状態だった(markedbills 1〜3個 × worth なので
-- 平均2個としても $700 前後、洗浄手数料20%を引くと $560。起動コスト$500を差し引くと
-- 実入りは $60 前後にしかならない)。武装したNPC警備(MICROSMG)がいて死亡リスクがあり、
-- 医療費と車両損失まで考えるとやるだけ損になるため、事実上の死にコンテンツだった。
--
-- 基準時給$7,500/h に対する中犯罪帯(1回$20,000〜35,000相当)には置かず、その下限寄りに
-- 設定している。理由は所要時間が短い(8分前後)ため、中犯罪帯の金額をそのまま入れると
-- 時給が跳ね上がるから。
--   markedbills 1〜3個(平均2個) × worth平均$5,500 = 粗 $11,000
--   → 洗浄手数料20%を引いて手取り $8,800
--   → クールダウン30分と合わせて 1サイクル約35分 → 実効 約$15,000/h(基準の2.0倍)
-- 武装NPC・警察通報・洗浄移動というリスクに対する倍率としてこの水準に置いた。
Config.Payout = {
    Min = 4500,                       -- Min reward payout (markedbills 1個あたりの額面)
    Max = 6500                        -- Max reward payout
}
-- 起動コストは「犯罪には元手がいる」というRP要素として維持する。改定後の報酬に対しては
-- ほぼ無視できる額なので、期待値マイナスの原因にはならない。不要なら 0 にしてよい。
Config.ActivationCost = 500           -- how much is the activation of the mission (clean from the bank)
Config.Currency = '$'
-- 2026-09-10 経済設計: 600秒(10分)から1800秒(30分)へ延長。報酬を約13倍にしたため、
-- 従来のCDのままだと実効時給が$32,000/h前後まで跳ね上がる。CDが実質的な収益上限装置になる。
-- なおこのタイマーは ActiveMission がグローバル変数のため、サーバー全体で共有される。
Config.ResetTimer = 1800              -- cooldown for mission in seconds
