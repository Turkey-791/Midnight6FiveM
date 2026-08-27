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

-- Legacy 'ItemBox' pickup/use notification popup.
--
-- The real qb-inventory rendered this via its own NUI page
-- (SendNUIMessage({action = 'itemBox', ...}) -> html/js's itemBox
-- handler). This shim resource has no NUI page of its own, so that
-- HTML/JS no longer exists to receive the message - meaning every
-- resource that still fires this event (audit found ~46 across the
-- server: qb-crafting, qb-drugs, robbery/casino/job resources, etc.)
-- got items correctly but the "+/-N item" popup silently never
-- appeared. This reproduces that notification using ox_lib's
-- lib.notify, which this resource already depends on, instead of
-- reintroducing a separate NUI popup system.
--
-- itemData is always a QBCore.Shared.Items[...] entry (fields like
-- .label/.image), never a raw ox_inventory slot, so no QB/ox shape
-- conversion is needed here. amount is optional - most callers omit it.
local function ShowItemBox(itemData, boxType, amount)
    if not itemData then return end

    local qty = tonumber(amount)
    local label = itemData.label or itemData.name or 'Item'
    local title = qty and ('%s%d %s'):format(boxType == 'remove' and '-' or '+', qty, label)
        or ('%s %s'):format(boxType == 'remove' and '-' or '+', label)

    lib.notify({
        title = title,
        type = boxType == 'remove' and 'error' or 'success',
        icon = 'box-open',
    })
end

RegisterNetEvent('qb-inventory:client:ItemBox', ShowItemBox)
RegisterNetEvent('inventory:client:ItemBox', ShowItemBox)
