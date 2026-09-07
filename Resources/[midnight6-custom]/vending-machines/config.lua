-- vending-machines / config.lua (2026-09-07 AO依頼で新規作成)
--
-- GTA V標準の自動販売機プロップに ox_target のInteractionを付与するための設定。
--
-- ■ 座標指定は不要
--   ox_target の addModel() は「そのモデルのエンティティすべて」に一括でTargetを
--   付与するため、マップ上に何台あっても(調査済みの258台を含め)自動的に対象になる。
--   MLO内やDLC内に配置された同モデルの自販機も同じく対象になる。
--
-- ■ 品揃え・価格の正本は ox_inventory/data/shops.lua 側
--   ここでは「どのモデルにどのShopを紐づけるか」だけを定義する。
--   商品を増減したい場合は shops.lua の該当エントリを編集すること。
--
-- ■ 自販機を追加したくなったら
--   下の Config.Machines に { shop = ..., label = ..., icon = ..., models = { ... } }
--   を1ブロック足し、shops.lua に同名のShop定義を作るだけでよい。

Config = {}

Config.Distance = 2.0 -- Interactionが出る距離(m)

Config.Machines = {
    {
        -- eCola / Sprunk / ウォーター / ドリンク冷蔵庫
        shop   = 'VendingMachineDrinks',
        label  = 'ドリンクを購入する',
        icon   = 'fas fa-bottle-water',
        models = {
            `prop_vend_soda_01`,   -- eCola
            `prop_vend_soda_02`,   -- Sprunk
            `prop_vend_water_01`,  -- ウォーター
            `prop_vend_fridge01`,  -- ドリンク冷蔵庫
        },
    },
    {
        -- スナック自販機(通常版 / チューニングショップ版)
        shop   = 'VendingMachineSnacks',
        label  = 'スナックを購入する',
        icon   = 'fas fa-cookie-bite',
        models = {
            `prop_vend_snak_01`,
            `prop_vend_snak_01_tu`,
        },
    },
    {
        -- コーヒー自販機(モデル名の綴りは "coffe" で正しい。GTA V側の表記ゆれ)
        shop   = 'VendingMachineCoffee',
        label  = 'コーヒーを購入する',
        icon   = 'fas fa-mug-hot',
        models = {
            `prop_vend_coffe_01`,
        },
    },
    {
        -- バーガー自販機
        shop   = 'VendingMachineBurger',
        label  = 'バーガーを購入する',
        icon   = 'fas fa-burger',
        models = {
            `prop_vend_burger_01`,
        },
    },
    {
        -- タバコ自販機(2026-09-06に作成した cigarette-vending をここへ統合)
        shop   = 'CigaretteVendingMachine',
        label  = 'タバコを購入する',
        icon   = 'fas fa-smoking',
        models = {
            `prop_vend_fags_01`,
        },
    },

    -- 【未対応】prop_vend_condom_01 (コンドーム自販機)
    --   ox_inventory/data/items.lua に 'condom' に相当するアイテムが存在しないため、
    --   今回は対象外にしている。アイテムを追加したらここと shops.lua に足せば動く。
}
