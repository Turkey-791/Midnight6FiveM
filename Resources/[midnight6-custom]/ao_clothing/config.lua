-- ao_clothing 設定
-- 店舗ごとの「取扱タグ」と「ティアの窓」を定義する。
-- 実際の商品データは data/catalog.lua(build_catalog.py が生成)にある。
--
-- タグ語彙(catalog.lua と一致していること):
--   basic street luxury formal sport beach work outdoor biker military
--   casino casino_only mask novelty utility accessory_luxury always
--
-- always タグは「装着なし(None)」を意味し、ティアや取扱タグに関係なく
-- 全店で必ず購入可能になる。これが無いと「マスクを外せない店」ができてしまう。

Config = {}

-- true にすると起動時に店舗ごとの品揃え点数をコンソールに出す
Config.Debug = false

-- スロットID対応(参考)
--   components: 1=マスク 3=腕/手袋 4=パンツ 5=バッグ 6=靴 7=アクセ 8=インナー 10=デカール 11=トップス
--   props:      0=帽子 1=眼鏡 2=耳 6=時計 7=ブレス
-- slots を nil にすると全スロットを扱う。指定するとそのスロットだけの専門店になる。

-- 構造的なスロット: 店舗で絞らない
-- 腕(component 3)は「袖と手袋」で、トップスと対で決まる。ここを店舗で絞ると
-- 「Tシャツを買ったのに袖が長いまま」といった不整合が直せなくなる。
-- 実データ上も腕には basic タグの商品が1点も無く、絞ると多くの店で0点になってしまう。
Config.UnfilteredComponents = { [3] = true }
Config.UnfilteredProps      = {}

Config.StoreProfiles = {

    -- ===== 新規キャラクター作成(仮想店舗) =====
    ['_starter'] = {
        label   = '初期衣装',
        tags    = { 'basic' },
        tierMin = 1, tierMax = 1,
    },

    -- ===== 安価帯 (Binco / Discount Store の内装) =====
    ['general_low'] = {
        label   = '一般衣料品店(安)',
        tags    = { 'basic', 'novelty' },
        tierMin = 1, tierMax = 2,
    },
    ['sport_low'] = {
        label   = 'スポーツ用品店(安)',
        tags    = { 'sport', 'beach' },
        tierMin = 1, tierMax = 2,
    },
    ['work_low'] = {
        label   = 'ワークウェア(安)',
        tags    = { 'work', 'utility' },
        tierMin = 1, tierMax = 3,
    },
    ['outdoor_low'] = {
        label   = 'アウトドア・防寒(安)',
        tags    = { 'outdoor' },
        tierMin = 1, tierMax = 2,
    },
    ['street'] = {
        label   = 'ストリート / HIPHOP',
        tags    = { 'street' },
        tierMin = 2, tierMax = 3,
    },
    ['biker'] = {
        label   = 'バイカー / レザー',
        tags    = { 'biker' },
        tierMin = 2, tierMax = 4,
    },
    ['military'] = {
        label   = 'ミリタリー / タクティカル',
        tags    = { 'military' },
        tierMin = 2, tierMax = 4,
    },

    -- ===== 中価格帯 (Sub Urban の内装) =====
    -- 注意: work / outdoor のタグはデータ上ほぼ単一ティアに固まっており(work と utility は
    -- ほぼ全部 T3、outdoor はほぼ全部 T2)、ティア窓で「安い版/中価格版」を分離できない。
    -- そのため #1 と #10、#9 と #12 は品揃えが同一になる。2026-09-12 に AO が
    -- 「重複を許容する」と判断済み。バグではないので直さないこと。
    ['sport_mid'] = {
        label   = 'スポーツ・ビーチ',
        tags    = { 'sport', 'beach' },
        tierMin = 2, tierMax = 3,
    },
    ['work_mid'] = {
        label   = 'ワークウェア',
        tags    = { 'work', 'utility' },
        tierMin = 3, tierMax = 4,
    },
    ['outdoor_mid'] = {
        label   = 'アウトドア',
        tags    = { 'outdoor' },
        tierMin = 2, tierMax = 3,
    },
    ['general_mid'] = {
        label   = '一般衣料品店',
        tags    = { 'basic' },
        tierMin = 2, tierMax = 3,
    },

    -- ===== 高級帯 (Ponsonbys の内装) =====
    ['luxury_formal'] = {
        label   = '高級ブティック(フォーマル)',
        tags    = { 'formal' },
        tierMin = 4, tierMax = 5,
    },
    ['luxury_casual'] = {
        label   = '高級ブティック(カジュアル)',
        tags    = { 'luxury' },
        tierMin = 4, tierMax = 5,
    },
    ['luxury_accessory'] = {
        label   = '高級アクセサリー',
        tags    = { 'accessory_luxury' },
        tierMin = 4, tierMax = 5,
        slots   = {
            components = { [5] = true, [6] = true, [7] = true },            -- バッグ・靴・アクセ
            props      = { [0] = true, [1] = true, [2] = true, [6] = true, [7] = true },
        },
    },

    -- ===== 専門店 =====
    ['mask'] = {
        label   = 'マスク専門店',
        tags    = { 'mask' },
        tierMin = 1, tierMax = 6,
        slots   = {
            components = { [1] = true },
            props      = {},
        },
    },
    ['casino'] = {
        label   = 'カジノ ギフトショップ',
        tags    = { 'casino', 'casino_only', 'formal' },
        tierMin = 4, tierMax = 6,
    },
}

-- illenium-appearance の Config.Stores のインデックス → 上のプロファイルID
-- (2026-09-11 時点で Config.Stores[1..15] が clothing、[16..22] barber、[23..28] tattoo、[29] surgeon)
Config.IlleniumStoreMap = {
    [1]  = 'work_low',          -- Grapeseed          / Discount Store
    [2]  = 'luxury_formal',     -- Rockford Hills     / Ponsonbys
    [3]  = 'sport_mid',         -- Del Perro          / Sub Urban
    [4]  = 'general_low',       -- (未特定)           / Binco
    [5]  = 'luxury_casual',     -- Burton             / Ponsonbys
    [6]  = 'street',            -- Strawberry         / Discount Store
    [7]  = 'sport_low',         -- (未特定)           / Binco
    [8]  = 'luxury_accessory',  -- Morningwood        / Ponsonbys
    [9]  = 'outdoor_low',       -- Paleto Bay         / Discount Store
    [10] = 'work_mid',          -- Harmony            / Sub Urban
    [11] = 'biker',             -- Sandy Shores       / Discount Store
    [12] = 'outdoor_mid',       -- Chumash            / Sub Urban
    [13] = 'military',          -- Great Chaparral    / Discount Store
    [14] = 'mask',              -- Vespucci Beach     / Vespucci Movie Masks
    [15] = 'general_mid',       -- Hawick Ave / Alta  / Sub Urban
}
