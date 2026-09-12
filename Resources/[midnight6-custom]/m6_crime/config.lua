Config = {}

-- ============================================================================
-- m6_crime — Midnight6 犯罪共通窓口
--   ・すべての犯罪の入口を1箇所に集約する
--   ・事件台帳(時効つき)を持つ
--   ・AI警察(rde_aipd_m6)への出力を1箇所にまとめる
--   ・プレイヤー警察の人数に応じた AI 出動台数の倍率を配信する
-- ============================================================================

Config.Debug = GetConvar('m6_crime_debug', 'false') == 'true'

-- AI警察リソース名(フォークしたRDE)
Config.AiPoliceResource = 'rde_aipd_m6'

-- ============================================================================
-- プレイヤー警察の人数 → AI 出動台数の倍率
--   0 = AI を出動させない / 1.0 = 通常の台数
--   ここが「警察が増えたらAIは減る」の本体。数値は運用しながらAOが決める。
-- ============================================================================

Config.PoliceJobs      = { 'police', 'sheriff' }  -- 人数に数える職業
Config.CountOnlyOnDuty = true                     -- 勤務中のみ数える

Config.PoliceFactor = {
    [0] = 1.0,
    [1] = 0.5,
    [2] = 0.25,
    [3] = 0.0,
}
Config.PoliceFactorDefault = 0.0   -- 表にない人数(4人以上)

-- ============================================================================
-- 犯罪種別
--   level  : AI警察に渡す手配レベル(1〜5)。nil ならAI警察へは渡さない
--   statute: 時効(秒)。nil なら時効なし(永久に残る)
--   alert  : プレイヤー警察へ通報するか
--   label  : 通報・台帳の表示名
-- ※ RDE 側が自分で検知する犯罪(発砲・暴行など)は RDE の Config.CrimeTypes が
--    手配レベルを決める。ここに書くのは「外部MOD由来の犯罪」と時効の設定。
-- ============================================================================

Config.CrimeTypes = {
    STORE_ROBBERY      = { level = 2, statute = 3 * 3600, alert = true,  label = 'コンビニ強盗' },
    BANK_ROBBERY_SMALL = { level = 3, statute = 6 * 3600, alert = true,  label = '銀行強盗(フリーカ)' },
    BANK_ROBBERY_BIG   = { level = 4, statute = 12 * 3600, alert = true, label = '銀行強盗(大型)' },
    TRUCK_ROBBERY      = { level = 3, statute = 6 * 3600, alert = true,  label = '現金輸送車強盗' },
    GENERIC_ALERT      = { level = nil, statute = 1 * 3600, alert = false, label = '通報' },

    -- RDE が検知した犯罪は種別名がそのまま来る(MURDER / SHOOTING / VEHICLE_THEFT ...)
    MURDER             = { level = nil, statute = 24 * 3600, alert = false, label = '殺人' },
    MURDER_COP         = { level = nil, statute = 48 * 3600, alert = false, label = '警官殺害' },
    ASSAULT            = { level = nil, statute = 2 * 3600,  alert = false, label = '暴行' },
    ASSAULT_COP        = { level = nil, statute = 6 * 3600,  alert = false, label = '警官暴行' },
    SHOOTING           = { level = nil, statute = 4 * 3600,  alert = false, label = '発砲' },
    BRANDISHING        = { level = nil, statute = 1 * 3600,  alert = false, label = '武器の誇示' },
    VEHICLE_THEFT      = { level = nil, statute = 3 * 3600,  alert = false, label = '車両盗難' },
    RECKLESS_DRIVING   = { level = nil, statute = 1 * 3600,  alert = false, label = '危険運転' },
    SPEEDING           = { level = nil, statute = 1 * 3600,  alert = false, label = '速度超過' },
    HIT_AND_RUN        = { level = nil, statute = 3 * 3600,  alert = false, label = 'ひき逃げ' },
    BURGLARY           = { level = nil, statute = 3 * 3600,  alert = false, label = '空き巣' },
    VANDALISM          = { level = nil, statute = 1 * 3600,  alert = false, label = '器物損壊' },
    DRUG_POSSESSION    = { level = nil, statute = 2 * 3600,  alert = false, label = '薬物所持' },
}

Config.DefaultStatute = 2 * 3600   -- 種別表にない犯罪の時効(秒)

-- ============================================================================
-- 時効の扱い
-- ============================================================================

Config.Statute = {
    -- 逮捕されたら、その人の未解決事件の時効を止めるか(服役で清算)
    stopOnArrest      = true,
    -- 逮捕時に未解決事件を「服役済み」にするか。false なら「逮捕」で止めるだけ
    settleOnArrest    = true,
    -- 新しい犯罪を犯したとき、未解決事件の時効を延長するか
    extendOnNewCrime  = false,
    -- 延長する場合の秒数
    extendSeconds     = 1800,
    -- 死亡で時効が進むか(false にすると死亡中は止まる。現状は常に進む)
    -- ※ 実装は「発生時刻 + 時効秒」で判定する方式なので、止める場合は別途対応が必要
    countWhileOffline = true,
}

-- ============================================================================
-- 重複除去
--   同じ犯人・同じ種別・この秒数以内の通報は1件にまとめる
-- ============================================================================

Config.Dedupe = {
    windowSeconds = 20,
}

-- ============================================================================
-- 既存MODからの取り込み
-- ============================================================================

Config.Connectors = {
    storeRobbery = true,   -- qb-storerobbery
    bankRobbery  = true,   -- qb-bankrobbery
    truckRobbery = true,   -- qb-truckrobbery
    -- police:server:policeAlert を拾う(宝石店・空き巣・ドラッグ・車両キーなど)
    -- 送信元が警察職のときは中継なので無視する
    genericPoliceAlert = true,
}
