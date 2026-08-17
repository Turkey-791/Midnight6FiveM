assert(lib.checkDependency('qb-core', '1.0.0'), 'qb-core is required')
local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'
local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('QBCore:Server:OnPlayerUnload', server.playerDropped)

RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source, job)
    local inventory = Inventory(source)
    if not inventory then return end
    inventory.player.groups[job.name] = job.grade.level
end)

RegisterNetEvent('QBCore:Server:OnGangUpdate', function(source, gang)
    local inventory = Inventory(source)
    if not inventory then return end
    inventory.player.groups[gang.name] = gang.grade.level
end)

-- Paired with client.setPlayerStatus in the bridge's client.lua. ox_inventory
-- item status effects (hunger/thirst/stress from eating, drinking, etc.)
-- only update an ox_lib statebag by default, which qb-hud does not read.
-- This applies the same delta to qb-core's own metadata so the HUD bars
-- actually move.
RegisterNetEvent('ox-qb-bridge:updateStatus', function(deltas)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    for name, delta in pairs(deltas) do
        local current = Player.PlayerData.metadata[name] or 100
        local newValue = math.max(0, math.min(100, current + delta))
        Player.Functions.SetMetaData(name, newValue)
    end

    -- SetMetaData alone updates the underlying data, but qb-hud does not
    -- watch PlayerData.metadata reactively - it only redraws hunger/thirst
    -- when it receives this specific client event (normally sent by
    -- qb-core's own QBCore:UpdatePlayer decay loop). Without this, eating
    -- or drinking correctly changes the data but the HUD bar visibly does
    -- nothing until the next natural decay tick.
    if deltas.hunger or deltas.thirst then
        TriggerClientEvent('hud:client:UpdateNeeds', source, Player.PlayerData.metadata['hunger'], Player.PlayerData.metadata['thirst'])
    end
end)

local function setupPlayer(PlayerData)
    PlayerData.identifier = PlayerData.citizenid
    PlayerData.name = ('%s %s'):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname)

    -- server.setPlayerInventory (ox_inventory's own code) auto-syncs
    -- immediately after creating the inventory. For any character that
    -- doesn't yet have a 'money' item matching their qb-core cash (e.g. a
    -- brand new character), that auto-sync sees 0 money items and WIPES
    -- PlayerData.money to match (a real ox_inventory behavior, not a bug
    -- we can patch there). We save the original values here so we can
    -- correctly backfill afterward using the true starting amount, not the
    -- already-zeroed one.
    local originalMoney = table.clone(PlayerData.money)

    server.setPlayerInventory(PlayerData)

    local accounts = Inventory.GetAccountItemCounts(PlayerData.source)
    if not accounts then return end
    for account in pairs(accounts) do
        local playerAccount = account == 'money' and 'cash' or account
        Inventory.SetItem(PlayerData.source, account, originalMoney[playerAccount])
    end
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    setupPlayer(Player.PlayerData)
end)

SetTimeout(500, function()
    local players = QBCore.Functions.GetQBPlayers()
    for _, Player in pairs(players) do
        setupPlayer(Player.PlayerData)
    end
end)

function server.UseItem(source, itemName, data)
    local usableItem = QBCore.Functions.CanUseItem(itemName)
    return usableItem and usableItem.func and usableItem.func(source, data)
end

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
    local Player = QBCore.Functions.GetPlayer(player.source)
    local groups = {}
    if Player then
        groups[Player.PlayerData.job.name] = Player.PlayerData.job.grade.level
        groups[Player.PlayerData.gang.name] = Player.PlayerData.gang.grade.level
    end
    return {
        source = player.source,
        name = ('%s %s'):format(player.charinfo.firstname, player.charinfo.lastname),
        groups = groups,
        sex = player.charinfo.gender,
        dateofbirth = player.charinfo.birthdate,
    }
end

-- Converts ox_inventory's slot table (keyed by slot, .count/.metadata shaped)
-- back into qb-core's item shape (.amount/.info), so that resources reading
-- Player.PlayerData.items directly (bypassing exports entirely - e.g.
-- qb-hud, qb-vineyard, qb-crafting, qb-pawnshop, qb-houses, qb-prison,
-- qb-smallresources) see a shape they understand, instead of silently
-- getting nil fields. This does NOT make those resources' writes back to
-- PlayerData.items persist into ox_inventory - that remains a known gap
-- (see qb-weapons, which both reads AND writes ammo/durability this way).
local function toQbShape(oxItems)
    local items = {}

    for slot, data in pairs(oxItems) do
        local itemInfo = QBCore.Shared.Items[data.name]

        if itemInfo then
            items[slot] = {
                name = itemInfo.name,
                amount = data.count,
                info = data.metadata or {},
                label = itemInfo.label,
                description = itemInfo.description or '',
                weight = itemInfo.weight,
                type = itemInfo.type,
                unique = itemInfo.unique,
                useable = itemInfo.useable,
                image = itemInfo.image,
                shouldClose = itemInfo.shouldClose,
                slot = data.slot,
                combinable = itemInfo.combinable,
            }
        end
    end

    return items
end

---@diagnostic disable-next-line: duplicate-set-field
function server.syncInventory(inv)
    local accounts = Inventory.GetAccountItemCounts(inv)
    if not accounts then return end

    local Player = QBCore.Functions.GetPlayer(inv.id)
    if not Player then return end
    Player.Functions.SetPlayerData('items', toQbShape(inv.items))
end

-- Money sync is handled on a fixed interval instead of per-event: relying
-- on every single AddItem/RemoveItem call to trigger a correct sync proved
-- unreliable in practice (root cause not conclusively found). Polling every
-- few seconds guarantees cash eventually matches the 'money' item count
-- regardless of which specific event path is taken.
CreateThread(function()
    while true do
        Wait(3000)

        local players = QBCore.Functions.GetQBPlayers()
        for _, Player in pairs(players) do
            local inv = Inventory(Player.PlayerData.source)
            if inv then
                local accounts = Inventory.GetAccountItemCounts(inv)
                if accounts then
                    for account, amount in pairs(accounts) do
                        account = account == 'money' and 'cash' or account
                        if Player.Functions.GetMoney(account) ~= amount then
                            Player.Functions.SetMoney(account, amount, ('Sync %s with inventory'):format(account))
                        end
                    end
                end
            end
        end
    end
end)

---@diagnostic disable-next-line: duplicate-set-field
function server.hasLicense(inv, license)
    local Player = QBCore.Functions.GetPlayer(inv.id)
    return Player and Player.PlayerData.metadata.licences[license]
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense(inv, license)
    local Player = QBCore.Functions.GetPlayer(inv.id)
    if not Player then return end

    if Player.PlayerData.metadata.licences[license.name] then
        return false, 'already_have'
    elseif Inventory.GetItem(inv, 'money', false, true) < license.price then
        return false, 'can_not_afford'
    end

    Inventory.RemoveItem(inv, 'money', license.price)
    Player.PlayerData.metadata.licences[license.name] = true
    Player.Functions.SetMetaData('licences', Player.PlayerData.metadata.licences)

    return true, 'have_purchased'
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss(playerId, group, grade)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return false end
    if Player.PlayerData.job.name == group then
        return Player.PlayerData.job.isboss
    elseif Player.PlayerData.gang.name == group then
        return Player.PlayerData.gang.isboss
    end
    return false
end

---@param entityId number
---@return number | string
---@diagnostic disable-next-line: duplicate-set-field
function server.getOwnedVehicleId(entityId)
    return GetVehicleNumberPlateText(entityId)
end

-- Converts a player's OLD qb-inventory formatted DB data (array of
-- {name, amount, info, type, slot}) into ox_inventory's expected shape the
-- FIRST time that player logs in after the migration. This does not run
-- again once ox_inventory has saved their inventory in its own format.
---@diagnostic disable-next-line: duplicate-set-field
function server.convertInventory(source, data)
    local inventory = {}
    local totalWeight = 0
    local ostime = os.time()

    if type(data) == 'table' then
        for _, v in pairs(data) do
            local itemName = v.name
            local slot = tonumber(v.slot)
            local count = tonumber(v.amount) or 1

            if itemName and slot then
                local item = Items(itemName)

                if item then
                    local metadata = Items.CheckMetadata(v.info or {}, item, itemName, ostime)
                    local weight = Inventory.SlotWeight(item, { count = count, metadata = metadata })
                    totalWeight = totalWeight + weight

                    inventory[slot] = {
                        name = item.name,
                        label = item.label,
                        weight = weight,
                        slot = slot,
                        count = count,
                        description = item.description,
                        metadata = metadata,
                        stack = item.stack,
                        close = item.close,
                    }
                end
            end
        end
    end

    return inventory, totalWeight
end