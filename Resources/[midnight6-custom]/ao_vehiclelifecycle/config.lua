Config = {}

-- ===========================================================================
-- Phase G-2: デポ送りを実際に行う。
-- 元のドライラン動作に戻したい場合は Config.EnableDepot を false にする。
-- ===========================================================================
Config.EnableDepot    = true   -- false でドライラン(ログのみ)に戻る
Config.SaveSnapshots  = true   -- engine/body をサーバー権威でDBに保存するか
Config.NotifyOwner    = true   -- デポ送りをオーナーがオンラインなら通知する
Config.Debug          = true   -- コンソールへの詳細ログ

Config.ScanInterval      = 30   -- 巡回間隔(秒)
Config.PlateCacheRefresh = 300  -- 所有プレート一覧をDBから読み直す間隔(秒)
Config.SnapshotMinDelta  = 50   -- engine/body がこの値以上変化したときだけDBに書く

-- 大破の判定と、DBに保存する下限値。
-- GTAのengine healthは破壊されると -4000 まで下がるが、その値をそのままDBに保存して
-- デポから復元すると「復元直後にまた大破と判定される」無限ループになるため、
-- 保存時は0未満に落とさない。判定は「負の値=実際に壊された」で行う。
--   engine = 0 … エンジンは始動しない(修理が必要)。ただし大破とは判定されない。
Config.WreckedEngine   = 0.0  -- これ未満なら大破
Config.SaveEngineFloor = 0    -- DBに保存するengineの下限
Config.SaveBodyFloor   = 1    -- DBに保存するbodyの下限

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

-- --------------------------------------------------------------------------
-- サーバー再起動時の扱い
-- --------------------------------------------------------------------------
-- 再起動時に残っていた state=0(出庫中)の車は原則デポ送りにする。
-- ただし「再起動の瞬間に普通に運転していただけの車」からは料金を取らない。
Config.HandleRestart              = true
Config.RestartRescueRequiresOwner = true -- 救済条件: 最後の搭乗者がオーナー本人であること
Config.RestartOccupiedWindow      = 120  -- 停止直前この秒数以内に搭乗していたら「搭乗中だった」とみなす

-- 誤爆防止: サーバー起動からこの秒数以内に開始した場合だけ再起動処理を走らせる。
-- これが無いと、稼働中に restart ao_vehiclelifecycle しただけで
-- 出庫中の全車両がデポ送りになってしまう。
Config.RestartSweepMaxUptime = 120


-- --------------------------------------------------------------------------
-- デポ引き取り時の「修理込み」オプション
-- --------------------------------------------------------------------------
-- 一般プレイヤーは advancedrepairkit を買えない(販売5店舗すべてに requiredJob あり)ため、
-- メカニック職がオフラインだとエンジンの死んだ車を直す手段が無い。
-- そのため、デポでの引き取り時に修理込みを選べるようにする。
Config.DepotRepairEnabled = true
-- 2026-09-10 経済設計: 収入基準を$3,000/hから$7,500/hへ引き上げたため、固定額のシンクを
-- 2.5倍にして相対的な重さを維持する。ここを据え置くと支出が実質2.5分の1になりインフレする。
-- (車両価格に連動するシンク、たとえばデポ引き取り料の%指定は自動追従するので変更不要)
Config.DepotRepairFee     = 25000  -- 一律固定額。引き取り料金に上乗せされる。

-- 引き取りは実際にデポにいる時だけ許可する(不正防止)。
Config.VerifyDepotDistance = true
Config.DepotRadius         = 20.0
Config.DepotPoints = {  -- qb-garages/config.lua の type='depot' な takeVehicle 座標
    { x =   401.76, y = -1632.57, z = 29.29 },  -- Depot Lot(車)
    { x = -1270.01, y = -3377.53, z = 14.33 },  -- Air Depot(航空機)
    { x =  -742.95, y = -1407.58, z =  5.50 },  -- LSYMC Depot(船)
    { x =  2334.42, y =  3118.62, z = 48.20 },  -- Big Rig Depot(大型)
}
