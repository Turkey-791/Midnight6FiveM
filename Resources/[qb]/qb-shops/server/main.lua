local Bail = {}
-- Money Authority fix (2026-08-28): サーバー側で実際の配送完了数を追跡するためのテーブル(citizenid単位)
local TruckerDropsCount = {}

-- Functions

local function checkTable(inputValue, requiredValue)
    if type(inputValue) == 'table' and type(requiredValue) == 'table' then
        for _, v in ipairs(requiredValue) do
            if inputValue[v] then return true end
        end
    elseif type(requiredValue) == 'table' then
        for _, v in ipairs(requiredValue) do
            if v == inputValue then return true end
        end
    elseif type(inputValue) == 'string' and type(requiredValue) == 'string' then
        return inputValue == requiredValue
    elseif type(inputValue) == 'table' and type(requiredValue) == 'string' then
        return inputValue[requiredValue] == true
    elseif type(inputValue) == 'string' and type(requiredValue) == 'table' then
        for _, v in ipairs(requiredValue) do
            if v == inputValue then return true end
        end
    end

    return false
end

local function saveShopInv(shop, products)
    local shopinv = {}
    shopinv[shop] = {}
    shopinv[shop].products = products
    SaveResourceFile(GetCurrentResourceName(), Config.ShopsInvJsonFile, json.encode(shopinv), -1)
end

local function deliveryPay(source, shop)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return false end
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local deliverCoords = Config.Locations[shop].delivery
    local distance = #(playerCoords - vector3(deliverCoords.x, deliverCoords.y, deliverCoords.z))
    if distance > 10 then return false end
    Player.AddMoney('bank', Config.DeliveryPrice, 'qb-shops:deliveryPay')
    if math.random(100) <= 10 then exports['qb-inventory']:AddItem(source, Config.RewardItem, 1, false, false, 'qb-shops:deliveryPay') end
    return true
end

-- Events

-- Deliveries

RegisterNetEvent('qb-shops:server:RestockShopItems', function(shop)
    local src = source
    if not shop then return end
    if not Config.Locations[shop] then return end
    -- Money Authority fix (2026-08-28): deliveryPay()が実際に支払いを行った(=サーバー側の距離検証を通過した)
    -- 場合のみ、PaySlip用の完了カウントを積み上げる。
    if deliveryPay(src, shop) then
        local Player = exports['qb-core']:GetPlayer(src)
        if Player then
            local citizenid = Player.PlayerData.citizenid
            TruckerDropsCount[citizenid] = (TruckerDropsCount[citizenid] or 0) + 1
        end
    end
    if not Config.Locations[shop].useStock then return end
    local randAmount = math.random(10, 50)
    for k in pairs(Config.Locations[shop].products) do Config.Locations[shop].products[k].amount += randAmount end
    saveShopInv(shop, Config.Locations[shop].products)
    TriggerClientEvent('qb-shops:client:SetShopItems', -1, shop, Config.Locations[shop].products)
end)

RegisterNetEvent('qb-shops:server:UpdateShopItems', function(shop, itemData, amount) -- called from inventory
    if not shop or not itemData or not amount then return end
    if not Config.Locations[shop] then return end
    if not Config.Locations[shop].useStock then return end
    Config.Locations[shop].products[itemData.slot].amount -= amount
    if Config.Locations[shop].products[itemData.slot].amount < 0 then
        Config.Locations[shop].products[itemData.slot].amount = 0
    end
    saveShopInv(shop, Config.Locations[shop].products)
    TriggerClientEvent('qb-shops:client:SetShopItems', -1, shop, Config.Locations[shop].products)
end)

RegisterNetEvent('qb-shops:server:DoBail', function(bool)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if bool then
        if Player.RemoveMoney('cash', Config.TruckDeposit, 'tow-received-bail') then
            Bail[Player.PlayerData.citizenid] = Config.TruckDeposit
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_cash', { value = Config.TruckDeposit }), 'success')
            TriggerClientEvent('qb-shops:client:SpawnVehicle', src)
        elseif Player.RemoveMoney('bank', Config.TruckDeposit, 'tow-received-bail') then
            Bail[Player.PlayerData.citizenid] = Config.TruckDeposit
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.paid_with_bank', { value = Config.TruckDeposit }), 'success')
            TriggerClientEvent('qb-shops:client:SpawnVehicle', src)
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_deposit', { value = Config.TruckDeposit }), 'error')
        end
    else
        if Bail[Player.PlayerData.citizenid] then
            Player.AddMoney('cash', Bail[Player.PlayerData.citizenid], 'trucker-bail-paid')
            Bail[Player.PlayerData.citizenid] = nil
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.refund_to_cash', { value = Config.TruckDeposit }), 'success')
        end
    end
end)

RegisterNetEvent('qb-shops:server:PaySlip', function(drops)
    local src = source
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local coords = Config.DeliveryLocations['main'].coords
    local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
    if distance > 10 then return end
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    -- Money Authority fix (2026-08-28): drops引数(クライアント申告値)は使用しない。
    -- RestockShopItems時にサーバー側で積み上げたカウントのみを正とする。
    local citizenid = Player.PlayerData.citizenid
    local completedDrops = TruckerDropsCount[citizenid] or 0
    if completedDrops <= 0 then return end
    local payment = Config.DeliveryPrice * completedDrops
    Player.AddMoney('bank', payment, 'trucker-salary')
    Player.AddRep('delivery', completedDrops)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.you_earned', { value = payment }), 'success')
    TruckerDropsCount[citizenid] = 0
end)

-- Money Authority fix (2026-08-28): ログアウト時にサーバー側カウントを破棄する。
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        TruckerDropsCount[Player.PlayerData.citizenid] = nil
    end
end)

-- Opening shops

RegisterNetEvent('qb-shops:server:openShop', function(data)
    local src = source
    local shopName = data.shop
    local shopData = Config.Locations[shopName]
    if not shopData then return end
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    local playerData = Player.PlayerData
    local products = shopData.products
    local items = {}

    if shopData.useStock then
        local shopInvJson = json.decode(LoadResourceFile(GetCurrentResourceName(), Config.ShopsInvJsonFile))
        if shopInvJson[shopName] then
            for k, v in pairs(shopInvJson[shopName].products) do
                if products[k] then
                    products[k].amount = v.amount
                end
            end
        end
    end

    for i = 1, #products do
        local curProduct = products[i]
        local addProduct = true

        if curProduct.requiredGrade and playerData.job.grade.level < curProduct.requiredGrade then
            addProduct = false
        end

        if addProduct and curProduct.requiredJob and not checkTable(playerData.job.name, curProduct.requiredJob) then
            addProduct = false
        end

        if addProduct and curProduct.requiredGang and not checkTable(playerData.gang.name, curProduct.requiredGang) then
            addProduct = false
        end

        if addProduct and curProduct.requiredLicense and not checkTable(playerData.metadata['licences'], curProduct.requiredLicense) then
            addProduct = false
        end

        if addProduct then
            curProduct.slot = #items + 1
            items[#items + 1] = curProduct
        end
    end

    exports['qb-inventory']:CreateShop({
        name = shopName,
        label = shopData.label,
        slots = shopData.slots,
        coords = shopData.coords,
        items = items,
    })
    exports['qb-inventory']:OpenShop(src, shopName)
end)
