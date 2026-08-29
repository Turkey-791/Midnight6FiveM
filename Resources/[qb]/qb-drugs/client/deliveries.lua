QBCore = exports['qb-core']:GetCoreObject({ 'Functions', 'Commands' })
sharedItems = exports['qb-core']:GetShared('Items')
-- Money Authority fix (2026-08-28): giveDeliveryItems時にサーバー側で記録した正規の配達内容(citizenid単位)。
-- successDelivery ではこの記録のみを正とし、クライアントが送るdeliveryData.itemData.payout等は使用しない。
local ActiveDeliveries = {}

-- Functions
exports('GetDealers', function()
    return Config.Dealers
end)

-- Callbacks
QBCore.Functions.CreateCallback('qb-drugs:server:RequestConfig', function(_, cb)
    cb(Config.Dealers)
end)

-- Events
RegisterNetEvent('qb-drugs:server:updateDealerItems', function(itemData, amount, dealer)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    if Config.Dealers[dealer]['products'][itemData.slot].amount - 1 >= 0 then
        Config.Dealers[dealer]['products'][itemData.slot].amount = Config.Dealers[dealer]['products'][itemData.slot].amount - amount
        TriggerClientEvent('qb-drugs:client:setDealerItems', -1, itemData, amount, dealer)
    else
        exports['qb-inventory']:RemoveItem(src, itemData.name, amount, false, 'qb-drugs:server:updateDealerItems')
        Player.AddMoney('cash', amount * Config.Dealers[dealer]['products'][itemData.slot].price, 'qb-drugs:server:updateDealerItems')
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.item_unavailable'), 'error')
    end
end)

RegisterNetEvent('qb-drugs:server:giveDeliveryItems', function(deliveryData)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    local deliveryDef = Config.DeliveryItems[deliveryData.item]
    if not deliveryDef then return end
    local item = deliveryDef.item
    if not item then return end
    local amount = tonumber(deliveryData.amount)
    if not amount or amount <= 0 then return end
    exports['qb-inventory']:AddItem(src, item, amount, false, false, 'qb-drugs:server:giveDeliveryItems')
    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[item], 'add')

    -- Money Authority fix (2026-08-28): この時点でサーバーが確認した配達内容(itemKey・amount)を記録する。
    ActiveDeliveries[Player.PlayerData.citizenid] = {
        itemKey = deliveryData.item,
        amount = amount,
    }
end)

RegisterNetEvent('qb-drugs:server:successDelivery', function(deliveryData, inTime)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end

    -- Money Authority fix (2026-08-28): giveDeliveryItems時にサーバーが記録した内容のみを正とする。
    -- deliveryData.item / deliveryData.amount / deliveryData.itemData.payout(クライアント値)は使用しない。
    local record = ActiveDeliveries[Player.PlayerData.citizenid]
    if not record then return end
    local deliveryDef = Config.DeliveryItems[record.itemKey]
    if not deliveryDef then
        ActiveDeliveries[Player.PlayerData.citizenid] = nil
        return
    end

    local item = deliveryDef.item
    local itemAmount = record.amount
    local payout = deliveryDef.payout * itemAmount
    local copsOnline = QBCore.Functions.GetDutyCount('police')
    local invItem = Player.GetItemByName(item)
    if inTime then
        if invItem and invItem.amount >= itemAmount then -- on time correct amount
            exports['qb-inventory']:RemoveItem(src, item, itemAmount, false, 'qb-drugs:server:successDelivery')
            if copsOnline > 0 then
                local copModifier = copsOnline * Config.PoliceDeliveryModifier
                if Config.UseMarkedBills then
                    local info = { worth = math.floor(payout * copModifier) }
                    exports['qb-inventory']:AddItem(src, 'markedbills', 1, false, info, 'qb-drugs:server:successDelivery')
                else
                    Player.AddMoney('cash', math.floor(payout * copModifier), 'qb-drugs:server:successDelivery')
                end
            else
                if Config.UseMarkedBills then
                    local info = { worth = payout }
                    exports['qb-inventory']:AddItem(src, 'markedbills', 1, false, info, 'qb-drugs:server:successDelivery')
                else
                    Player.AddMoney('cash', payout, 'qb-drugs:server:successDelivery')
                end
            end
            TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[item], 'remove')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.order_delivered'), 'success')
            SetTimeout(math.random(5000, 10000), function()
                TriggerClientEvent('qb-drugs:client:sendDeliveryMail', src, 'perfect', deliveryData)
                Player.AddRep('dealer', Config.DeliveryRepGain)
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.order_not_right'), 'error') -- on time incorrect amount
            if invItem then
                local newItemAmount = invItem.amount
                local modifiedPayout = deliveryDef.payout * newItemAmount
                exports['qb-inventory']:RemoveItem(src, item, newItemAmount, false, 'qb-drugs:server:successDelivery')
                TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[item], 'remove')
                Player.AddMoney('cash', math.floor(modifiedPayout / Config.WrongAmountFee), 'qb-drugs:server:successDelivery')
            end
            SetTimeout(math.random(5000, 10000), function()
                TriggerClientEvent('qb-drugs:client:sendDeliveryMail', src, 'bad', deliveryData)
                Player.RemoveRep('dealer', Config.DeliveryRepLoss)
            end)
        end
    else
        if invItem and invItem.amount >= itemAmount then -- late correct amount
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.too_late'), 'error')
            exports['qb-inventory']:RemoveItem(src, item, itemAmount, false, 'qb-drugs:server:successDelivery')
            Player.AddMoney('cash', math.floor(payout / Config.OverdueDeliveryFee), 'qb-drugs:server:successDelivery')
            TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[item], 'remove')
            SetTimeout(math.random(5000, 10000), function()
                TriggerClientEvent('qb-drugs:client:sendDeliveryMail', src, 'late', deliveryData)
                Player.RemoveRep('dealer', Config.DeliveryRepLoss)
            end)
        else
            if invItem then -- late incorrect amount
                local newItemAmount = invItem.amount
                local modifiedPayout = deliveryDef.payout * newItemAmount
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.too_late'), 'error')
                exports['qb-inventory']:RemoveItem(src, item, itemAmount, false, 'qb-drugs:server:successDelivery')
                Player.AddMoney('cash', math.floor(modifiedPayout / Config.OverdueDeliveryFee), 'qb-drugs:server:successDelivery')
                TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[item], 'remove')
                SetTimeout(math.random(5000, 10000), function()
                    TriggerClientEvent('qb-drugs:client:sendDeliveryMail', src, 'late', deliveryData)
                    Player.RemoveRep('dealer', Config.DeliveryRepLoss)
                end)
            end
        end
    end

    -- Money Authority fix (2026-08-28): このデリバリー記録は使い切ったので破棄する(再送による二重支払い防止)。
    ActiveDeliveries[Player.PlayerData.citizenid] = nil
end)

-- Money Authority fix (2026-08-28): ログアウト時に未完了の配達記録を破棄する。
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        ActiveDeliveries[Player.PlayerData.citizenid] = nil
    end
end)

RegisterNetEvent('qb-drugs:server:dealerShop', function(currentDealer)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local dealerData = Config.Dealers[currentDealer]
    if not dealerData then return end
    local dist = #(playerCoords - vector3(dealerData.coords.x, dealerData.coords.y, dealerData.coords.z))
    if dist > 5.0 then return end
    local curRep = Player.GetRep('dealer')
    local repItems = {}
    for k in pairs(dealerData.products) do
        if curRep >= dealerData['products'][k].minrep then
            repItems[#repItems + 1] = dealerData['products'][k]
        end
    end
    exports['qb-inventory']:CreateShop({
        name = dealerData.name,
        label = dealerData.name,
        slots = #repItems,
        coords = dealerData.coords,
        items = repItems,
    })
    exports['qb-inventory']:OpenShop(src, dealerData.name)
end)

-- Commands

QBCore.Commands.Add('newdealer', Lang:t('info.newdealer_command_desc'), { {
    name = Lang:t('info.newdealer_command_help1_name'),
    help = Lang:t('info.newdealer_command_help1_help')
}, {
    name = Lang:t('info.newdealer_command_help2_name'),
    help = Lang:t('info.newdealer_command_help2_help')
}, {
    name = Lang:t('info.newdealer_command_help3_name'),
    help = Lang:t('info.newdealer_command_help3_help')
} }, true, function(source, args)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local dealerName = args[1]
    local minTime = tonumber(args[2])
    local maxTime = tonumber(args[3])
    local time = json.encode({ min = minTime, max = maxTime })
    local pos = json.encode({ x = coords.x, y = coords.y, z = coords.z })
    local result = MySQL.scalar.await('SELECT name FROM dealers WHERE name = ?', { dealerName })
    if result then return TriggerClientEvent('QBCore:Notify', source, Lang:t('error.dealer_already_exists'), 'error') end
    MySQL.insert('INSERT INTO dealers (name, coords, time, createdby) VALUES (?, ?, ?, ?)', { dealerName, pos, time, Player.PlayerData.citizenid }, function()
        Config.Dealers[dealerName] = {
            ['name'] = dealerName,
            ['coords'] = {
                ['x'] = coords.x,
                ['y'] = coords.y,
                ['z'] = coords.z
            },
            ['time'] = {
                ['min'] = minTime,
                ['max'] = maxTime
            },
            ['products'] = Config.Products
        }
        TriggerClientEvent('qb-drugs:client:RefreshDealers', -1, Config.Dealers)
    end)
end, 'admin')

QBCore.Commands.Add('deletedealer', Lang:t('info.deletedealer_command_desc'), { {
    name = Lang:t('info.deletedealer_command_help1_name'),
    help = Lang:t('info.deletedealer_command_help1_help')
} }, true, function(source, args)
    local dealerName = args[1]
    local result = MySQL.scalar.await('SELECT * FROM dealers WHERE name = ?', { dealerName })
    if result then
        MySQL.query('DELETE FROM dealers WHERE name = ?', { dealerName })
        Config.Dealers[dealerName] = nil
        TriggerClientEvent('qb-drugs:client:RefreshDealers', -1, Config.Dealers)
        TriggerClientEvent('QBCore:Notify', source, Lang:t('success.dealer_deleted', { dealerName = dealerName }), 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.dealer_not_exists_command', { dealerName = dealerName }), 'error')
    end
end, 'admin')

QBCore.Commands.Add('dealers', Lang:t('info.dealers_command_desc'), {}, false, function(source, _)
    local DealersText = ''
    if Config.Dealers ~= nil and next(Config.Dealers) ~= nil then
        for _, v in pairs(Config.Dealers) do
            DealersText = DealersText .. Lang:t('info.list_dealers_name_prefix') .. v['name'] .. '<br>'
        end
        TriggerClientEvent('chat:addMessage', source, {
            template = '<div class="chat-message advert"><div class="chat-message-body"><strong>' .. Lang:t('info.list_dealers_title') .. '</strong><br><br> ' .. DealersText .. '</div></div>',
            args = {}
        })
    else
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.no_dealers'), 'error')
    end
end, 'admin')

QBCore.Commands.Add('dealergoto', Lang:t('info.dealergoto_command_desc'), { {
    name = Lang:t('info.dealergoto_command_help1_name'),
    help = Lang:t('info.dealergoto_command_help1_help')
} }, true, function(source, args)
    local DealerName = tostring(args[1])
    if Config.Dealers[DealerName] then
        local ped = GetPlayerPed(source)
        SetEntityCoords(ped, Config.Dealers[DealerName]['coords']['x'], Config.Dealers[DealerName]['coords']['y'], Config.Dealers[DealerName]['coords']['z'])
        TriggerClientEvent('QBCore:Notify', source, Lang:t('success.teleported_to_dealer', { dealerName = DealerName }), 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.dealer_not_exists'), 'error')
    end
end, 'admin')

CreateThread(function()
    Wait(500)
    local dealers = MySQL.query.await('SELECT * FROM dealers', {})
    if dealers[1] then
        for _, v in pairs(dealers) do
            local coords = json.decode(v.coords)
            local time = json.decode(v.time)

            Config.Dealers[v.name] = {
                ['name'] = v.name,
                ['coords'] = {
                    ['x'] = coords.x,
                    ['y'] = coords.y,
                    ['z'] = coords.z
                },
                ['time'] = {
                    ['min'] = time.min,
                    ['max'] = time.max
                },
                ['products'] = Config.Products
            }
        end
    end
    TriggerClientEvent('qb-drugs:client:RefreshDealers', -1, Config.Dealers)
end)
