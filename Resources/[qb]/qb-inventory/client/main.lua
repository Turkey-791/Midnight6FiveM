-- qb-inventory compatibility shim (client-side)
--
-- qb-core's client/functions.lua calls exports['qb-inventory']:HasItem(items, amount)
-- directly (without a source, since it's checking the local player).
-- We forward this to the server, which checks via ox_inventory's own data
-- (the authoritative source), rather than relying on qb-core's local
-- PlayerData.items copy, which may not match ox_inventory's item shape.

local function HasItem(items, amount)
    return lib.callback.await('qb-inventory-shim:hasItem', false, items, amount)
end
exports('HasItem', HasItem)

-- Triggered by the server-side OpenShop shim (server/main.lua). Shops in
-- ox_inventory must be opened by the client itself, not pushed from the
-- server, so this just calls ox_inventory's own client export on this
-- player's behalf.
RegisterNetEvent('qb-inventory-shim:openShop', function(shopName)
    exports.ox_inventory:openInventory('shop', { type = shopName })
end)
