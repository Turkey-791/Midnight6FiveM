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
                local count = ox_inventory:Search(source, 'count', item)
                if not count or count < (amount or 1) then return false end
            end
            return true
        else
            for item, reqAmount in pairs(items) do
                local count = ox_inventory:Search(source, 'count', item)
                if not count or count < reqAmount then return false end
            end
            return true
        end
    else
        local count = ox_inventory:Search(source, 'count', items)
        return count ~= nil and count >= (amount or 1)
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
    local QBCore = exports['qb-core']:GetCoreObject()
    local itemData = QBCore.Functions.CanUseItem(itemName)
    if type(itemData) == 'table' and itemData.func then
        itemData.func(source)
    end
end
exports('UseItem', UseItem)

print('^2[qb-inventory shim] Loaded - routing legacy calls to ox_inventory^7')
