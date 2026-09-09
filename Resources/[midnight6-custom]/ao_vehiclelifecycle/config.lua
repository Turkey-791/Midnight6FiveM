Config = {}

-- ===========================================================================
-- Phase G-1: 検知とログのみ。デポ送りは行わない。
-- Config.EnableDepot を true にすると G-2 の挙動(実際のデポ送り)になる。
-- ===========================================================================
Config.EnableDepot    = false  -- ★G-1では必ず false
Config.SaveSnapshots  = true   -- engine/body をサーバー権威でDBに保存するか
Config.Debug          = true   -- コンソールへの詳細ログ

Config.ScanInterval      = 30   -- 巡回間隔(秒)
Config.PlateCacheRefresh = 300  -- 所有プレート一覧をDBから読み直す間隔(秒)
Config.SnapshotMinDelta  = 50   -- engine/body がこの値以上変化したときだけDBに書く

-- 猶予時間(秒)。車格ごとに分ける。
--   wrecked      : 大破してからデポ送りまで
--   empty        : 無人のままデポ送りまで(オーナーがオンライン)
--   emptyOffline : 無人のままデポ送りまで(オーナーがオフライン)
Config.Grace = {
    land = { wrecked = 10 * 60, empty = 60 * 60,  emptyOffline = 5 * 60 },
    air  = { wrecked = 10 * 60, empty = 120 * 60, emptyOffline = 20 * 60 },
    sea  = { wrecked = 10 * 60, empty = 120 * 60, emptyOffline = 20 * 60 },
}

-- qb-core/shared/vehicles.lua の category から車格を決める。未定義は land 扱い。
Config.ClassOf = {
    helicopters = 'air',
    planes      = 'air',
    boats       = 'sea',
}

-- デポ引き取り料金。購入価格に対する割合。上限なし。
-- 添字は「その車が過去に何回デポ送りになったか + 1」。配列長を超えたら末尾で据え置き。
Config.DepotRate = {
    destroyed = { 0.15, 0.25, 0.40 },
    abandoned = { 0.05, 0.08, 0.12 },
}
Config.DepotMin           = { destroyed = 100, abandoned = 50 }
Config.DepotFallbackPrice = 1000  -- shared/vehicles.lua に price が無い車両の想定価格
