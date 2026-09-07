-- vending-machines / client.lua (2026-09-07 AO依頼で新規作成)
--
-- Config.Machines の定義に従って、GTA V標準の自動販売機モデルに
-- ox_target の Interaction を登録し、選択時に ox_inventory の既存Shop UIを開く。
--
-- 実装方針(2026-09-06の cigarette-vending と同じ):
--   - ox_inventory本体 / ox_target本体 / qb-core本体は一切変更していない。
--   - inventory:target convar も false のまま変更していない。グローバルに
--     ox_inventory の全Shop/Craftingの挙動を変えてしまうため。
--     そのため ox_inventory 本体の modules/shops/client.lua の model分岐には頼らず、
--     このリソースから直接 ox_target:addModel() を呼んでいる。
--   - 品揃え・価格は ox_inventory/data/shops.lua が正本。ここでは扱わない。

CreateThread(function()
    for _, machine in ipairs(Config.Machines) do
        exports.ox_target:addModel(machine.models, {
            {
                name     = 'vending_' .. machine.shop,
                icon     = machine.icon,
                label    = machine.label,
                distance = Config.Distance,
                onSelect = function()
                    exports.ox_inventory:openInventory('shop', { type = machine.shop })
                end,
            },
        })
    end
end)

-- リソース停止時にTargetを剥がす(再起動時の二重登録防止)
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, machine in ipairs(Config.Machines) do
        exports.ox_target:removeModel(machine.models, 'vending_' .. machine.shop)
    end
end)
