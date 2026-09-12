Config = {}

Config.PawnLocation = {
    [1] = {
        coords = vector3(412.34, 314.81, 103.13),
        length = 1.5,
        width = 1.8,
        heading = 207.0,
        debugPoly = false,
        minZ = 100.97,
        maxZ = 105.42,
        distance = 3.0
    },
}

Config.BankMoney = false -- Set to true if you want the money to go into the players bank
Config.UseTimes = false  -- Set to false if you want the pawnshop open 24/7
Config.TimeOpen = 7      -- Opening Time
Config.TimeClosed = 17   -- Closing Time
Config.SendMeltingEmail = true

Config.UseTarget = GetConvar('UseTarget', 'false') == 'true'

-- 2026-09-10 経済設計 v4: 「重量」と「人数割り」を織り込んだ改定。
--
-- v3 からの変更理由(2点):
--  (1) 重量の見積もりが甘かった。Pacific 実行中の実際の積載は
--        drill 8.0kg + thermite 0.5kg + カービン 3.1kg + ライフル弾100発 0.4kg + 装甲等 1.0kg
--        = 13.0kg  → 積載上限30kgに対して残り17.0kg
--      goldbar は7kgなので 1往復で2本しか運べない(ドリルを金庫に置いても3本)。
--      Pacific の金庫34本を運び出すには徒歩17往復が必要。しかも金庫はZ=101.68、
--      入口はZ=106.28で地下にあり、往復のたびに昇降が発生する。警察対応中にこれをやる。
--      v3 は「トランクが328kgあるから重量は制約にならない」と評価していたが、
--      制約が効くのは金庫から車までの徒歩区間であり、そこが本当のコストだった。
--  (2) 人数割りを考慮していなかった。Pacific は4人必要なので、総額が同じなら
--      1人あたりの取り分はソロの宝石店より少なくなる。多人数必須のコンテンツほど
--      総額を上げないと、1人あたりで見たときにソロ犯罪に負ける。
--
-- ■ 1人あたりの取り分で並べた結果(改定後)
--     宝石店 (1人)  $45,900 / 人   合法 6.1 時間分
--     Fleeca (2人)  $50,190 / 人   合法 6.7 時間分
--     Paleto (3人)  $54,967 / 人   合法 7.3 時間分
--     Pacific(4人)  $64,000 / 人   合法 8.5 時間分  (金塊16本=2往復×4人の現実的な想定)
--     Pacific(4人)  $79,750 / 人   合法10.6 時間分  (金塊34本=完全制圧、17往復)
--   必要人数と難度が上がるほど1人あたりの取り分も増える形になっている。
--   Pacific は完全制圧すると1.25倍になり、運び出す手間に見合った差がつく。
--
-- ■ goldbar は「銀行金庫からしか出ない」ようにした
--   1.5kgのネックレスを溶かすと7kgの金塊が出るのは物理的にもおかしく、かつ goldbar の
--   単価を上げると宝石店の産出額まで連動して膨らむ。そこで宝飾品の溶解産物から goldbar を
--   全廃した(下の MeltingItems 参照)。これで goldbar は金庫報酬だけに効くようになり、
--   宝石店・住宅侵入とは独立して調整できる。
--
-- ■ 直接売却は溶解後価値の約75%(溶解は所要9秒で実質ノーコストのため)
--     goldchain     → 溶解不可                     直接 $1,600 (溶解ルートが無いぶん高め)
--     diamond_ring  → diamond×1        = $1,100    直接 $825   (75%)
--     rolex         → diamond×1 + kit×1= $1,100+   直接 $860   (78%)
--     tenkgoldchain → diamond×4        = $4,400    直接 $3,300 (75%)
--
-- ■ 電子機器(tablet/iphone/samsungphone/laptop)は住宅侵入の主要産出物。$600 据え置き。
--
-- ■ 今後の調整ノブ
--   goldbar  → Pacific / Paleto / Fleeca の金庫報酬にのみ効く
--   diamond  → 宝石店 / 住宅侵入 / 銀行のロレックス報酬に効く
--   AI警察・NPC通報MOD 導入後に検挙率が上がったら、この2つで調整する。
--
Config.PawnItems = {
    [1] = {
        item = 'goldchain',
        price = 1600
    },
    [2] = {
        item = 'diamond_ring',
        price = 825
    },
    [3] = {
        item = 'rolex',
        price = 860
    },
    [4] = {
        item = 'tenkgoldchain',
        price = 3300
    },
    [5] = {
        item = 'tablet',
        price = 600
    },
    [6] = {
        item = 'iphone',
        price = 600
    },
    [7] = {
        item = 'samsungphone',
        price = 600
    },
    [8] = {
        item = 'laptop',
        price = 600
    },
    -- 2026-09-10 新規追加: 換金先が存在しなかった溶解生成物
    [9] = {
        item = 'goldbar',
        price = 6700
    },
    [10] = {
        item = 'diamond',
        price = 1100
    }
}

-- 2026-09-10 v4: goldbar は「銀行金庫からしか出ない」ようにした。
-- 1.5kg のネックレスを溶かすと 7kg の金の延べ棒が出てくるのは物理的にもおかしく、
-- かつ goldbar の単価を上げると宝石店の産出額まで連動して膨らんでしまうため、
-- 宝飾品の溶解産物から goldbar を全て除いた。
--   goldchain     : 溶解不可(直接売却のみ)。そのぶん直接売却価格を $1,600 に引き上げ
--   diamond_ring  : diamond×1
--   rolex         : diamond×1 + electronickit×1
--   tenkgoldchain : diamond×4  (旧: diamond×5 + goldbar×1)
-- これにより goldbar の単価は Pacific / Paleto / Fleeca の金庫報酬だけに効き、
-- 宝石店・住宅侵入の金額とは独立して調整できるようになった。
Config.MeltingItems = { -- meltTime is amount of time in minutes per item
    [1] = {
        item = 'diamond_ring',
        rewards = {
            [1] = {
                item = 'diamond',
                amount = 1
            }
        },
        meltTime = 0.15
    },
    [2] = {
        item = 'rolex',
        rewards = {
            [1] = {
                item = 'diamond',
                amount = 1
            },
            [2] = {
                item = 'electronickit',
                amount = 1
            }
        },
        meltTime = 0.15
    },
    [3] = {
        item = 'tenkgoldchain',
        rewards = {
            [1] = {
                item = 'diamond',
                amount = 4
            }
        },
        meltTime = 0.15
    },
}
