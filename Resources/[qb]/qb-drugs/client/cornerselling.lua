local StolenDrugs = {}

local function getAvailableDrugs(source)
    local AvailableDrugs = {}
    local Player = exports['qb-core']:GetPlayer(source)

    if not Player then return nil end

    for k in pairs(Config.DrugsPrice) do
        local item = Player.GetItemByName(k)

        if item then
            AvailableDrugs[#AvailableDrugs + 1] = {
                item = item.name,
                amount = item.amount,
                label = sharedItems[item.name]['label']
            }
        end
    end
    return table.type(AvailableDrugs) ~= 'empty' and AvailableDrugs or nil
end

QBCore.Functions.CreateCallback('qb-drugs:server:cornerselling:getAvailableDrugs', function(source, cb)
    cb(getAvailableDrugs(source))
end)

RegisterNetEvent('qb-drugs:server:giveStealItems', function(drugType, amount)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player or StolenDrugs == {} then return end
    for k, v in pairs(StolenDrugs) do
        if drugType == v.item and amount == v.amount then
            exports['qb-inventory']:AddItem(src, drugType, amount, false, false, 'qb-drugs:server:giveStealItems')
            table.remove(StolenDrugs, k)
        end
    end
end)

RegisterNetEvent('qb-drugs:server:sellCornerDrugs', function(drugType, amount, price)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    local availableDrugs = getAvailableDrugs(src)
    if not availableDrugs or not Player then return end
    local item = availableDrugs[drugType].item
    local hasItem = Player.GetItemByName(item)
    if hasItem.amount >= amount then
        -- Money Authority fix (2026-08-28): 単価はサーバー側で再抽選する(クライアントのprice引数は使用しない)。
        -- クライアント版(client/cornerselling.lua)と同じ抽選ロジック(ScamChance込み)をそのまま再現している。
        local ddata = Config.DrugsPrice[item]
        local scamChance = math.random(1, 100)
        local serverPrice
        if ddata and scamChance <= Config.ScamChance then
            serverPrice = math.random(3, 10) * amount
        elseif ddata then
            serverPrice = math.random(ddata.min, ddata.max) * amount
        else
            serverPrice = 0
        end

        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.offer_accepted'), 'success')
        exports['qb-inventory']:RemoveItem(src, item, amount, false, 'qb-drugs:server:sellCornerDrugs')
        Player.AddMoney('cash', serverPrice, 'qb-drugs:server:sellCornerDrugs')
        TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[item], 'remove')
        TriggerClientEvent('qb-drugs:client:refreshAvailableDrugs', src, getAvailableDrugs(src))
    else
        TriggerClientEvent('qb-drugs:client:cornerselling', src)
    end
end)

RegisterNetEvent('qb-drugs:server:robCornerDrugs', function(drugType, amount)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    local availableDrugs = getAvailableDrugs(src)
    if not availableDrugs or not Player then return end
    local item = availableDrugs[drugType].item
    exports['qb-inventory']:RemoveItem(src, item, amount, false, 'qb-drugs:server:robCornerDrugs')
    table.insert(StolenDrugs, { item = item, amount = amount })
    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[item], 'remove')
    TriggerClientEvent('qb-drugs:client:refreshAvailableDrugs', src, getAvailableDrugs(src))
end)
