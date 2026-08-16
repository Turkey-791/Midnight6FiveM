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

local function setupPlayer(PlayerData)
    PlayerData.identifier = PlayerData.citizenid
    PlayerData.name = ('%s %s'):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname)
    server.setPlayerInventory(PlayerData)

    local accounts = Inventory.GetAccountItemCounts(PlayerData.source)
    if not accounts then return end
    for account in pairs(accounts) do
        local playerAccount = account == 'money' and 'cash' or account
        Inventory.SetItem(PlayerData.source, account, PlayerData.money[playerAccount])
    end
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    print('^2[DEBUG] PlayerLoaded event fired for source: ' .. tostring(Player.PlayerData.source) .. '^7')
    setupPlayer(Player.PlayerData)
end)

SetTimeout(500, function()
    local players = QBCore.Functions.GetQBPlayers()
    for _, Player in pairs(players) do
        setupPlayer(Player.PlayerData)
    end
end)

function server.UseItem(source, itemName, data)
    local itemData = QBCore.Shared.Items[itemName]
    return itemData and itemData.func and itemData.func(source, data)
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

---@diagnostic disable-next-line: duplicate-set-field
function server.syncInventory(inv)
    local accounts = Inventory.GetAccountItemCounts(inv)
    if not accounts then return end

    local Player = QBCore.Functions.GetPlayer(inv.id)
    if not Player then return end
    Player.Functions.SetPlayerData('items', inv.items)

    for account, amount in pairs(accounts) do
        account = account == 'money' and 'cash' or account
        if Player.Functions.GetMoney(account) ~= amount then
            Player.Functions.SetMoney(account, amount, ('Sync %s with inventory'):format(account))
        end
    end
end

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