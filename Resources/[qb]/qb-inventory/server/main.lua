-- qb-inventory compatibility shim -> routes calls to ox_inventory
--
-- This resource is intentionally named 'qb-inventory' so that any existing
-- resource calling exports['qb-inventory']:FunctionName(...) keeps working
-- WITHOUT modification. The actual inventory logic and data all live in
-- ox_inventory; this file just translates calls and return shapes.
--
-- Phase 1 covers: AddItem, RemoveItem, HasItem, GetItemByName, GetItemsByName
-- (these cover ~87% of all exports['qb-inventory'] calls found across the
-- resources checked on 2026-08-17)

local ox_inventory = exports.ox_inventory
local QBCore = exports['qb-core']:GetCoreObject()

--- Converts an ox_inventory slot table into a qb-inventory shaped item table,
--- since calling code expects fields like .amount and .info, not .count/.metadata
local function toQbItem(slotData)
    if not slotData then return nil end

    return {
        name = slotData.name,
        amount = slotData.count,
        info = slotData.metadata or {},
        type = slotData.type or 'item',
        slot = slotData.slot,
        label = slotData.label,
    }
end

-- qb signature: AddItem(identifier, item, amount, slot, info, reason)
local function AddItem(identifier, item, amount, slot, info, reason)
    amount = amount or 1
    return ox_inventory:AddItem(identifier, item, amount, (info and info ~= false) and info or nil, (slot and slot ~= false) and slot or nil)
end
exports('AddItem', AddItem)

-- qb signature: RemoveItem(identifier, item, amount, slot, reason)
local function RemoveItem(identifier, item, amount, slot, reason)
    amount = amount or 1
    return ox_inventory:RemoveItem(identifier, item, amount, nil, (slot and slot ~= false) and slot or nil)
end
exports('RemoveItem', RemoveItem)

-- qb signature: HasItem(source, items, amount)
-- items can be: a string (single item), an array of item names, or a
-- {itemName = requiredAmount} table
local function HasItem(source, items, amount)
    if type(items) == 'table' then
        local isArray = table.type(items) == 'array'

        if isArray then
            for _, item in pairs(items) do
                local count = tonumber(ox_inventory:Search(source, 'count', item)) or 0
                if count < (amount or 1) then return false end
            end
            return true
        else
            for item, reqAmount in pairs(items) do
                local count = tonumber(ox_inventory:Search(source, 'count', item)) or 0
                if count < reqAmount then return false end
            end
            return true
        end
    else
        local count = tonumber(ox_inventory:Search(source, 'count', items)) or 0
        return count >= (amount or 1)
    end
end
exports('HasItem', HasItem)

-- Exposed via ox_lib callback so the client-side shim (client/main.lua) can
-- reuse the same server-authoritative check, rather than trusting the
-- client's local (and possibly stale/mismatched-shape) copy of PlayerData.items
lib.callback.register('qb-inventory-shim:hasItem', function(source, items, amount)
    return HasItem(source, items, amount)
end)

-- qb signature: GetItemByName(source, item) -> returns a single item table or nil
local function GetItemByName(source, item)
    local result = ox_inventory:Search(source, 'slots', item)

    if result and result[1] then
        return toQbItem(result[1])
    end

    return nil
end
exports('GetItemByName', GetItemByName)

-- qb signature: GetItemsByName(source, item) -> returns an array of item tables
local function GetItemsByName(source, item)
    local result = ox_inventory:Search(source, 'slots', item)
    local items = {}

    if result then
        for _, slotData in pairs(result) do
            items[#items + 1] = toQbItem(slotData)
        end
    end

    return items
end
exports('GetItemsByName', GetItemsByName)

-- qb-core calls this directly during character load (qb-core/server/player.lua)
-- whenever a resource named 'qb-inventory' exists. ox_inventory manages its
-- own loading/saving independently and will overwrite this shortly after via
-- server.syncInventory in the ox bridge, so returning an empty table here
-- just prevents a load-blocking error; it is not the real source of truth.
local function LoadInventory(source, citizenid)
    return {}
end
exports('LoadInventory', LoadInventory)

-- qb-core calls this on every player save (QBCore.Player.Save, both the
-- online variant with just a source, and an offline variant that passes
-- PlayerData + true). ox_inventory saves its own data independently on its
-- own schedule, so this is intentionally a no-op - it only exists to
-- prevent a "no such export" error from qb-core's save routine.
local function SaveInventory(source, offline)
    return true
end
exports('SaveInventory', SaveInventory)

-- qb-core's QBCore.Functions.UseItem(source, item) calls this when an item
-- is used through a legacy code path (not through the ox_inventory UI,
-- which already handles item use via the ox bridge's server.UseItem).
-- This replicates qb-core's own usable-item registry lookup.
local function UseItem(source, itemName)
    local itemData = QBCore.Functions.CanUseItem(itemName)
    if type(itemData) == 'table' and itemData.func then
        itemData.func(source)
    end
end
exports('UseItem', UseItem)

-- ============================================================
-- Phase 2: OpenInventory, OpenInventoryById, CreateShop, OpenShop,
-- CreateInventory (the remaining ~13% of calls, added 2026-08-17)
-- ============================================================

-- qb signature: OpenInventory(source, identifier, data)
-- identifier is the stash name (nil to open the player's own inventory).
-- data may contain .label, .maxweight, .slots
local function OpenInventory(source, identifier, data)
    if not identifier then
        return ox_inventory:forceOpenInventory(source, 'player', source)
    end

    if type(identifier) ~= 'string' then
        return
    end

    ox_inventory:RegisterStash(
        identifier,
        (data and data.label) or identifier,
        (data and data.slots) or 50,
        (data and data.maxweight) or 4000000
    )

    return ox_inventory:forceOpenInventory(source, 'stash', identifier)
end
exports('OpenInventory', OpenInventory)

-- qb signature: OpenInventoryById(source, targetId)
local function OpenInventoryById(source, targetId)
    return ox_inventory:forceOpenInventory(source, 'player', tonumber(targetId))
end
exports('OpenInventoryById', OpenInventoryById)

-- qb signature: CreateShop(shopData)
-- shopData = { name, label, slots, coords, items = {{name, price, amount}, ...} }
-- Note: physical world placement (blips/markers/targets) is handled by the
-- calling resource itself (e.g. qb-shops), not by the inventory system, so
-- only the shop's registration/pricing data needs to be converted here.
local function CreateShop(shopData)
    if not shopData or not shopData.name then return end

    local inventory = {}

    for _, product in pairs(shopData.items or {}) do
        inventory[#inventory + 1] = {
            name = product.name,
            price = product.price,
            count = product.amount or product.count or 100,
        }
    end

    ox_inventory:RegisterShop(shopData.name, {
        name = shopData.label or shopData.name,
        inventory = inventory,
    })
end
exports('CreateShop', CreateShop)

-- qb signature: OpenShop(source, name)
-- Unlike stashes/players (which the server can push open via
-- forceOpenInventory), shops in ox_inventory are opened by the CLIENT
-- itself calling client.openInventory('shop', ...), which then awaits a
-- server callback (ox_inventory:openShop, registered by ox_inventory
-- itself). So instead of pushing from the server, we tell this player's
-- client to open it, and ox_inventory's own client/server code handles
-- the rest.
local function OpenShop(source, name)
    TriggerClientEvent('qb-inventory-shim:openShop', source, name)
end
exports('OpenShop', OpenShop)

-- qb signature: CreateInventory(identifier, data)
-- Registers a stash without opening it (used to pre-create stashes ahead of time)
local function CreateInventory(identifier, data)
    if not identifier then return end

    ox_inventory:RegisterStash(
        identifier,
        (data and data.label) or identifier,
        (data and data.slots) or 50,
        (data and data.maxweight) or 4000000
    )
end
exports('CreateInventory', CreateInventory)

-- ============================================================
-- Player.Functions.XXX(...) method patching
--
-- Separately from the exports() calls above, the REAL qb-inventory also
-- patches 7 methods directly onto the Player object via
-- QBCore.Functions.AddPlayerMethod: AddItem, RemoveItem, GetItemBySlot,
-- GetItemByName, GetItemsByName, ClearInventory, SetInventory. These are
-- called as e.g. Player.Functions.GetItemByName(...) - a completely
-- different call style from exports['qb-inventory']:GetItemByName(...),
-- and several other resources (e.g. qb-phone's HasPhone check) use this
-- style instead of exports. We reuse the same underlying functions defined
-- above wherever possible.
-- ============================================================

-- qb signature: GetItemBySlot(source, slot) -> item table or nil
local function GetItemBySlot(source, slot)
    local result = ox_inventory:GetSlot(source, slot)
    return toQbItem(result)
end
exports('GetItemBySlot', GetItemBySlot)

-- qb signature: ClearInventory(source, filterItems)
-- filterItems (qb) is a list of item names to KEEP; everything else is
-- cleared. ox_inventory's Clear(inv, keep) takes the same "keep" concept.
local function ClearInventory(source, filterItems)
    ox_inventory:ClearInventory(source, filterItems)
end
exports('ClearInventory', ClearInventory)

local function registerPlayerMethods(source)
    QBCore.Functions.AddPlayerMethod(source, 'AddItem', function(item, amount, slot, info, reason)
        return AddItem(source, item, amount, slot, info, reason)
    end)

    QBCore.Functions.AddPlayerMethod(source, 'RemoveItem', function(item, amount, slot, reason)
        return RemoveItem(source, item, amount, slot, reason)
    end)

    QBCore.Functions.AddPlayerMethod(source, 'GetItemBySlot', function(slot)
        return GetItemBySlot(source, slot)
    end)

    QBCore.Functions.AddPlayerMethod(source, 'GetItemByName', function(item)
        return GetItemByName(source, item)
    end)

    QBCore.Functions.AddPlayerMethod(source, 'GetItemsByName', function(item)
        return GetItemsByName(source, item)
    end)

    QBCore.Functions.AddPlayerMethod(source, 'ClearInventory', function(filterItems)
        ClearInventory(source, filterItems)
    end)

    -- ox_inventory is the single source of truth for item data, so this
    -- specific method is intentionally a no-op (see qb-weapons note
    -- elsewhere) - it exists only to prevent a "nil value" crash for code
    -- that calls Player.Functions.SetInventory(...) directly.
    QBCore.Functions.AddPlayerMethod(source, 'SetInventory', function(items) end)
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    registerPlayerMethods(Player.PlayerData.source)
end)

CreateThread(function()
    Wait(1000)
    local players = QBCore.Functions.GetQBPlayers()
    for src in pairs(players) do
        registerPlayerMethods(src)
    end
end)

print('^2[qb-inventory shim] Loaded - routing legacy calls to ox_inventory^7')
