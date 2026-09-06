-- cigarette-vending (2026-09-06 AO依頼で新規作成)
--
-- GTA V標準アセット prop_vend_fags_01 (タバコ自動販売機、Model Hash 73774428) に
-- ox_target で「タバコを購入する」Interactionを追加する。
--
-- 実装方針(調査レポート smoking_vending_machine_investigation_2026-09-05.md /
-- smoking_feature_investigation_2026-09-05.md 参照):
--   - Model単位でTargetを登録する(exports.ox_target:addModel)。座標を1台ずつ
--     登録する必要はなく、マップ上のprop_vend_fags_01すべてに自動的に付与される。
--   - ox_inventory本体・ox_target本体・qb-core本体は一切変更していない。
--   - inventory:target convarもfalseのまま変更していない(グローバルにox_inventoryの
--     全Shop/Craftingの挙動を変えてしまうため)。そのため、ox_inventory本体の
--     Shopモジュール(modules/shops/client.lua)のmodel分岐には頼らず、
--     このリソースから直接ox_target:addModel()を呼び、選択時に
--     exports.ox_inventory:openInventory('shop', {...}) で既存のShop UIを開く形にした。
--   - 商品定義(品揃え・価格)自体は ox_inventory/data/shops.lua の
--     CigaretteVendingMachine エントリを正本として使う(ここでは重複定義しない)。

CreateThread(function()
    exports.ox_target:addModel({ `prop_vend_fags_01` }, {
        {
            name = 'cigarette_vending_buy',
            icon = 'fas fa-shopping-basket',
            label = 'タバコを購入する',
            distance = 2.0,
            onSelect = function()
                exports.ox_inventory:openInventory('shop', { type = 'CigaretteVendingMachine' })
            end,
        },
    })
end)
