local QBCore = exports['qb-core']:GetCoreObject({ 'Functions' })
local sharedItems = exports['qb-core']:GetShared('Items')
local robberyBusy = false

-- 2026-09-10 報酬消失バグの修正
--
-- 【問題】このファイルの AddItem 呼び出し14箇所は、いずれも戻り値を見ていなかった。
-- qb-inventory は ox_inventory へのシムで、その AddItem は先頭で CanCarryItem を呼び、
-- 持てない場合は「これ以上は重くて持てません。」と通知して false を返す。
-- このときアイテムは一切生成されない。
--
-- さらに CanCarryItem はスタック全体を一括で判定するため、
-- 金塊が12本出て2本しか持てない状況では「2本もらえる」のではなく「0本」になる。
-- ロッカーは別イベント(setLockerState)で既に isOpened = true にされているので
-- 再度ドリルすることもできず、報酬は完全に消滅していた。
--
-- Pacific の場合、装備込み(drill 8kg + thermite + 武器 + 弾)で運べるのは金塊2本。
-- 出現数は tier3 で1〜7本、tier2 で1〜18本、tier1 で1〜25本だったため、
-- 約79%の確率で0本になっていた。金庫5個を全て開けても期待値は約1.5本しかなかった。
--
-- 【修正】持てる分だけインベントリに入れ、残りは足元にドロップする。
-- 仲間が拾って運べるので「運び屋」のRPが成立し、拾い遅れれば警察に押収されるという
-- リスクも生まれる。ドロップはサーバー再起動で消える点だけ注意。
local function GiveOrDrop(src, itemName, amount, info)
    amount = tonumber(amount) or 1
    if amount < 1 then return end

    local metadata = (info and info ~= false) and info or nil

    -- 持てる最大数を求める(スタック一括判定のため、上から減らして探す)
    local carry = 0
    for n = amount, 1, -1 do
        if exports.ox_inventory:CanCarryItem(src, itemName, n, metadata) then
            carry = n
            break
        end
    end

    if carry > 0 then
        exports['qb-inventory']:AddItem(src, itemName, carry, false, info, 'qb-bankrobbery:server:recieveItem')
        TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems[itemName], 'add')
    end

    local rest = amount - carry
    if rest > 0 then
        local label = (sharedItems[itemName] and sharedItems[itemName].label) or itemName
        exports.ox_inventory:CustomDrop('Loot', { { itemName, rest, metadata } }, GetEntityCoords(GetPlayerPed(src)))
        TriggerClientEvent('QBCore:Notify', src,
            ('持ちきれない %s %d個を足元に置いた'):format(label, rest), 'primary')
    end
end
local timeOut = false

-- Functions

--- This will convert a table's keys into an array
--- @param tbl table
--- @return array
local function TableKeysToArray(tbl)
    local array = {}
    for k in pairs(tbl) do
        array[#array + 1] = k
    end
    return array
end

--- This will loop over the given table to check if the power stations in the table have been hit
--- @param toLoop table
--- @return boolean
local function TableLoopStations(toLoop)
    local hits = 0
    for _, station in pairs(toLoop) do
        if type(station) == 'table' then
            local hits2 = 0
            for _, station2 in pairs(station) do
                if Config.PowerStations[station2].hit then hits2 += 1 end
                if hits2 == #station then return true end
            end
        else
            if Config.PowerStations[station].hit then hits += 1 end
            if hits == #toLoop then return true end
        end
    end
    return false
end

--- This will check what stations have been hit and update them accordingly
--- @return nil
local function CheckStationHits()
    local policeHits = {}
    local bankHits = {}

    for k, v in pairs(Config.CameraHits) do
        local allStationsHitPolice = false
        local allStationsHitBank = false
        if type(v.type) == 'table' then
            for _, cameraType in pairs(v.type) do
                if cameraType == 'police' then
                    if type(v.stationsToHitPolice) == 'table' then
                        allStationsHitPolice = TableLoopStations(v.stationsToHitPolice)
                    else
                        allStationsHitPolice = Config.PowerStations[v.stationsToHitPolice].hit
                    end
                elseif cameraType == 'bank' then
                    if type(v.stationsToHitBank) == 'table' then
                        allStationsHitBank = TableLoopStations(v.stationsToHitBank)
                    else
                        allStationsHitBank = Config.PowerStations[v.stationsToHitBank].hit
                    end
                end
            end
        else
            if v.type == 'police' then
                if type(v.stationsToHitPolice) == 'table' then
                    allStationsHitPolice = TableLoopStations(v.stationsToHitPolice)
                else
                    allStationsHitPolice = Config.PowerStations[v.stationsToHitPolice].hit
                end
            elseif v.type == 'bank' then
                if type(v.stationsToHitBank) == 'table' then
                    allStationsHitBank = TableLoopStations(v.stationsToHitBank)
                else
                    allStationsHitBank = Config.PowerStations[v.stationsToHitBank].hit
                end
            end
        end

        if allStationsHitPolice then
            policeHits[k] = true
        end

        if allStationsHitBank then
            bankHits[k] = true
        end
    end

    policeHits = TableKeysToArray(policeHits)
    bankHits = TableKeysToArray(bankHits)

    -- table.type checks if it's empty as well, if it's empty it will return the type 'empty' instead of 'array'
    if table.type(policeHits) == 'array' then Config.OnPoliceCameraHit(policeHits) end
    if table.type(bankHits) == 'array' then TriggerClientEvent('qb-bankrobbery:client:BankSecurity', -1, bankHits, false) end
end

--- This will do a quick check to see if all stations have been hit
--- @return boolean
local function AllStationsHit()
    local hit = 0
    for k in pairs(Config.PowerStations) do
        if Config.PowerStations[k].hit then
            hit += 1
        end
    end
    return hit >= Config.HitsNeeded
end

--- This will check if the given coords are in the area of the given distance of a powerstation
--- @param coords vector3
--- @param dist number
--- @return boolean
local function IsNearPowerStation(coords, dist)
    for _, v in pairs(Config.PowerStations) do
        if #(coords - v.coords) < dist then
            return true
        end
    end
    return false
end

-- Events

RegisterNetEvent('qb-bankrobbery:server:setBankState', function(bankId)
    if robberyBusy then return end
    if bankId == 'paleto' then
        if Config.BigBanks['paleto']['isOpened'] or #(GetEntityCoords(GetPlayerPed(source)) - Config.BigBanks['paleto']['coords']) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:setBankState', extraInfo = ' (paleto) ', source = source }))
        end
        Config.BigBanks['paleto']['isOpened'] = true
        TriggerEvent('qb-bankrobbery:server:setTimeout')
    elseif bankId == 'pacific' then
        if Config.BigBanks['pacific']['isOpened'] or #(GetEntityCoords(GetPlayerPed(source)) - Config.BigBanks['pacific']['coords'][2]) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:setBankState', extraInfo = ' (pacific) ', source = source }))
        end
        Config.BigBanks['pacific']['isOpened'] = true
        TriggerEvent('qb-bankrobbery:server:setTimeout')
    else
        if Config.SmallBanks[bankId]['isOpened'] or #(GetEntityCoords(GetPlayerPed(source)) - Config.SmallBanks[bankId]['coords']) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:setBankState', extraInfo = ' (smallbank ' .. bankId .. ') ', source = source }))
        end
        Config.SmallBanks[bankId]['isOpened'] = true
        TriggerEvent('qb-bankrobbery:server:SetSmallBankTimeout', bankId)
    end
    TriggerClientEvent('qb-bankrobbery:client:setBankState', -1, bankId)
    robberyBusy = true
    Config.OnRobberyStart(bankId)
end)

RegisterNetEvent('qb-bankrobbery:server:setLockerState', function(bankId, lockerId, state, bool)
    local bankType = Config.BigBanks[bankId] and 'BigBanks' or 'SmallBanks'
    local extraInfo = (' (%s' .. bankId .. ') '):format(bankType == 'SmallBanks' and 'smallbank' or '')
    if #(GetEntityCoords(GetPlayerPed(source)) - Config[bankType][bankId]['lockers'][lockerId]['coords']) > 2.5 then
        return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:setLockerState', extraInfo = extraInfo, source = source }))
    end
    Config[bankType][bankId]['lockers'][lockerId][state] = bool
    TriggerClientEvent('qb-bankrobbery:client:setLockerState', -1, bankId, lockerId, state, bool)
end)

RegisterNetEvent('qb-bankrobbery:server:recieveItem', function(type, bankId, lockerId)
    local src = source
    local ply = exports['qb-core']:GetPlayer(src)
    if not ply then return end
    if type == 'small' then
        if #(GetEntityCoords(GetPlayerPed(src)) - Config.SmallBanks[bankId]['lockers'][lockerId]['coords']) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:receiveItem', extraInfo = ' (smallbank ' .. bankId .. ') ', source = source }))
        end
        local itemType = math.random(#Config.RewardTypes)
        local WeaponChance = math.random(1, 50)
        local odd1 = math.random(1, 50)
        local tierChance = math.random(1, 100)
        local tier
        if tierChance < 50 then tier = 1 elseif tierChance >= 50 and tierChance < 80 then tier = 2 elseif tierChance >= 80 and tierChance < 95 then tier = 3 else tier = 4 end
        if WeaponChance ~= odd1 then
            if tier ~= 4 then
                if Config.RewardTypes[itemType].type == 'item' then
                    local item = Config.LockerRewards['tier' .. tier][math.random(#Config.LockerRewards['tier' .. tier])]
                    local itemAmount = math.random(item.minAmount, item.maxAmount)
                    GiveOrDrop(src, item.item, itemAmount, false)
                elseif Config.RewardTypes[itemType].type == 'money' then
                    -- 2026-09-10 経済設計: $2,300〜3,200 → $5,700〜7,900
                    -- Fleeca は2人想定。1人あたりの取り分を約$50,000(合法6.7時間分)に合わせた。
                    -- 総額 約$100,400 = 現金$51,680 + goldchain20本$32,000
                    --                  + rolex→diamond12個$13,200 + goldbar1本$3,500
                    -- (現金は洗浄手数料20%を引いた後の手取りで計算している)
                    local info = {
                        worth = math.random(5700, 7900)
                    }
                    GiveOrDrop(src, 'markedbills', math.random(2, 3), info)
                end
            else
                GiveOrDrop(src, 'security_card_01', 1, false)
            end
        else
            GiveOrDrop(src, 'weapon_stungun', 1, false)
        end
    elseif type == 'paleto' then
        if #(GetEntityCoords(GetPlayerPed(source)) - Config.BigBanks['paleto']['lockers'][lockerId]['coords']) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:receiveItem', extraInfo = ' (paleto) ', source = source }))
        end
        local itemType = math.random(#Config.RewardTypes)
        local tierChance = math.random(1, 100)
        local WeaponChance = math.random(1, 10)
        local odd1 = math.random(1, 10)
        local tier
        if tierChance < 25 then tier = 1 elseif tierChance >= 25 and tierChance < 70 then tier = 2 elseif tierChance >= 70 and tierChance < 95 then tier = 3 else tier = 4 end
        if WeaponChance ~= odd1 then
            if tier ~= 4 then
                if Config.RewardTypes[itemType].type == 'item' then
                    local item = Config.LockerRewardsPaleto['tier' .. tier][math.random(#Config.LockerRewardsPaleto['tier' .. tier])]
                    local itemAmount = math.random(item.minAmount, item.maxAmount)
                    GiveOrDrop(src, item.item, itemAmount, false)
                elseif Config.RewardTypes[itemType].type == 'money' then
                    -- 2026-09-10 経済設計: $4,000〜6,000 → $10,500〜16,000
                    -- Paleto は3人想定。1人あたりの取り分を約$55,000(合法7.3時間分)に合わせた。
                    -- 総額 約$164,900 = 現金$100,700 + goldchain15本$24,000
                    --                  + rolex→diamond27個$29,700 + goldbar3本$10,500
                    local info = {
                        worth = math.random(10500, 16000)
                    }
                    GiveOrDrop(src, 'markedbills', math.random(1, 4), info)
                end
            else
                GiveOrDrop(src, 'security_card_02', 1, false)
            end
        else
            GiveOrDrop(src, 'weapon_vintagepistol', 1, false)
        end
    -- 2026-09-10 経済設計: Pacific の markedbills worth ($19,000〜21,000) は据え置き。
    -- Pacific の総額は goldbar(7kg、装備込みだと1往復2本)の本数で決まる設計にしてあるため、
    -- 現金側を触ると「運び出す手間」と収益の対応が崩れる。
    -- 4人×2往復=16本で約$256,000、完全制圧34本で約$319,000。
    elseif type == 'pacific' then
        if #(GetEntityCoords(GetPlayerPed(source)) - Config.BigBanks['pacific']['lockers'][lockerId]['coords']) > 2.5 then
            return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:receiveItem', extraInfo = ' (pacific) ', source = source }))
        end
        local itemType = math.random(#Config.RewardTypes)
        local WeaponChance = math.random(1, 100)
        local odd1 = math.random(1, 100)
        local odd2 = math.random(1, 100)
        local tierChance = math.random(1, 100)
        local tier
        if tierChance < 10 then tier = 1 elseif tierChance >= 25 and tierChance < 50 then tier = 2 elseif tierChance >= 50 and tierChance < 95 then tier = 3 else tier = 4 end
        if WeaponChance ~= odd1 or WeaponChance ~= odd2 then
            if tier ~= 4 then
                if Config.RewardTypes[itemType].type == 'item' then
                    local item = Config.LockerRewardsPacific['tier' .. tier][math.random(#Config.LockerRewardsPacific['tier' .. tier])]
                    local maxAmount
                    -- 2026-09-10 経済設計: 出現数を 1〜7 / 1〜18 / 1〜25本 から絞った。
                    -- 装備込みで運べるのは金塊2本なので、旧設定では約79%が0本になっていた。
                    -- 金庫5個で合計 約18本(=125kg)。4人で2〜3往復して運び出す想定。
                    local minAmount
                    if tier == 3 then minAmount, maxAmount = 2, 4
                    elseif tier == 2 then minAmount, maxAmount = 3, 5
                    else minAmount, maxAmount = 4, 6 end
                    local itemAmount = math.random(minAmount, maxAmount)
                    GiveOrDrop(src, item.item, itemAmount, false)
                elseif Config.RewardTypes[itemType].type == 'money' then
                    local info = {
                        worth = math.random(19000, 21000)
                    }
                    GiveOrDrop(src, 'markedbills', math.random(1, 4), info)
                end
            else
                local info = {
                    worth = math.random(19000, 21000)
                }
                GiveOrDrop(src, 'markedbills', math.random(1, 4), info)
                info = {
                    crypto = math.random(1, 3)
                }
                GiveOrDrop(src, 'cryptostick', 1, info)
            end
        else
            local chance = math.random(1, 2)
            local odd = math.random(1, 2)
            if chance == odd then
                GiveOrDrop(src, 'weapon_microsmg', 1, false)
            else
                GiveOrDrop(src, 'weapon_minismg', 1, false)
            end
        end
    end
end)

AddEventHandler('qb-bankrobbery:server:setTimeout', function()
    if robberyBusy or timeOut then return end
    timeOut = true
    CreateThread(function()
        SetTimeout(60000 * 90, function()
            for k in pairs(Config.BigBanks['pacific']['lockers']) do
                Config.BigBanks['pacific']['lockers'][k]['isBusy'] = false
                Config.BigBanks['pacific']['lockers'][k]['isOpened'] = false
            end
            for k in pairs(Config.BigBanks['paleto']['lockers']) do
                Config.BigBanks['paleto']['lockers'][k]['isBusy'] = false
                Config.BigBanks['paleto']['lockers'][k]['isOpened'] = false
            end
            TriggerClientEvent('qb-bankrobbery:client:ClearTimeoutDoors', -1)
            Config.BigBanks['paleto']['isOpened'] = false
            Config.BigBanks['pacific']['isOpened'] = false
            timeOut = false
            robberyBusy = false
            Config.OnRobberyTimeoutEnd('paleto')
            Config.OnRobberyTimeoutEnd('pacific')
        end)
    end)
end)

AddEventHandler('qb-bankrobbery:server:SetSmallBankTimeout', function(bankId)
    if robberyBusy or timeOut then return end
    timeOut = true
    CreateThread(function()
        SetTimeout(60000 * 30, function()
            for k in pairs(Config.SmallBanks[bankId]['lockers']) do
                Config.SmallBanks[bankId]['lockers'][k]['isOpened'] = false
                Config.SmallBanks[bankId]['lockers'][k]['isBusy'] = false
            end
            TriggerClientEvent('qb-bankrobbery:client:ResetFleecaLockers', -1, bankId)
            timeOut = false
            robberyBusy = false
            Config.OnRobberyTimeoutEnd(bankId)
        end)
    end)
end)

RegisterNetEvent('qb-bankrobbery:server:callCops', function(type, bank, coords)
    if type == 'small' then
        if not Config.SmallBanks[bank]['alarm'] then
            return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:callCops', extraInfo = ' (smallbank ' .. bank .. ') ', source = source }))
        end
    elseif type == 'paleto' then
        if not Config.BigBanks['paleto']['alarm'] then
            return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:callCops', extraInfo = ' (paleto) ', source = source }))
        end
    elseif type == 'pacific' then
        if not Config.BigBanks['pacific']['alarm'] then
            return error(Lang:t('error.event_trigger_wrong', { event = 'qb-bankrobbery:server:callCops', extraInfo = ' (pacific) ', source = source }))
        end
    end
    TriggerClientEvent('qb-bankrobbery:client:robberyCall', -1, type, coords)
end)

RegisterNetEvent('qb-bankrobbery:server:SetStationStatus', function(key, isHit)
    Config.PowerStations[key].hit = isHit
    TriggerClientEvent('qb-bankrobbery:client:SetStationStatus', -1, key, isHit)
    if AllStationsHit() then
        exports['qb-weathersync']:setBlackout(true)
        TriggerClientEvent('qb-bankrobbery:client:disableAllBankSecurity', -1)
        Config.OnBlackout(true)
        CreateThread(function()
            SetTimeout(60000 * Config.BlackoutTimer, function()
                exports['qb-weathersync']:setBlackout(false)
                TriggerClientEvent('qb-bankrobbery:client:enableAllBankSecurity', -1)
                Config.OnBlackout(false)
            end)
        end)
    else
        CheckStationHits()
    end
end)

RegisterNetEvent('qb-bankrobbery:server:removeElectronicKit', function()
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    exports['qb-inventory']:RemoveItem(src, 'electronickit', 1, false, 'qb-bankrobbery:server:removeElectronicKit')
    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems['electronickit'], 'remove')
    exports['qb-inventory']:RemoveItem(src, 'trojan_usb', 1, false, 'qb-bankrobbery:server:removeElectronicKit')
    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems['trojan_usb'], 'remove')
end)

RegisterNetEvent('qb-bankrobbery:server:removeBankCard', function(number)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    exports['qb-inventory']:RemoveItem(src, 'security_card_' .. number, 1, false, 'qb-bankrobbery:server:removeBankCard')
    TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItems['security_card_' .. number], 'remove')
end)

RegisterNetEvent('thermite:StartServerFire', function(coords, maxChildren, isGasFire)
    local src = source
    local ped = GetPlayerPed(src)
    local coords2 = GetEntityCoords(ped)
    local thermiteCoords = Config.BigBanks['pacific'].thermite[1].coords
    local thermite2Coords = Config.BigBanks['pacific'].thermite[2].coords
    local thermite3Coords = Config.BigBanks['paleto'].thermite[1].coords
    if #(coords2 - thermiteCoords) < 10 or #(coords2 - thermite2Coords) < 10 or #(coords2 - thermite3Coords) < 10 or IsNearPowerStation(coords2, 10) then
        TriggerClientEvent('thermite:StartFire', -1, coords, maxChildren, isGasFire)
    end
end)

RegisterNetEvent('thermite:StopFires', function()
    TriggerClientEvent('thermite:StopFires', -1)
end)

-- Callbacks

QBCore.Functions.CreateCallback('qb-bankrobbery:server:isRobberyActive', function(_, cb)
    cb(robberyBusy)
end)

QBCore.Functions.CreateCallback('qb-bankrobbery:server:GetConfig', function(_, cb)
    cb(Config.PowerStations, Config.BigBanks, Config.SmallBanks)
end)

QBCore.Functions.CreateCallback('thermite:server:check', function(source, cb)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return cb(false) end
    if exports['qb-inventory']:RemoveItem(source, 'thermite', 1, false, 'thermite:server:check') then
        TriggerClientEvent('qb-inventory:client:ItemBox', source, sharedItems['thermite'], 'remove')
        cb(true)
    else
        cb(false)
    end
end)

-- Items

QBCore.Functions.CreateUseableItem('thermite', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not exports['qb-inventory']:GetItemByName(source, 'thermite') then return end
    if exports['qb-inventory']:GetItemByName(source, 'lighter') then
        TriggerClientEvent('thermite:UseThermite', source)
    else
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.missing_ignition_source'), 'error')
    end
end)

QBCore.Functions.CreateUseableItem('security_card_01', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not exports['qb-inventory']:GetItemByName(source, 'security_card_01') then return end
    TriggerClientEvent('qb-bankrobbery:UseBankcardA', source)
end)

QBCore.Functions.CreateUseableItem('security_card_02', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not exports['qb-inventory']:GetItemByName(source, 'security_card_02') then return end
    TriggerClientEvent('qb-bankrobbery:UseBankcardB', source)
end)

QBCore.Functions.CreateUseableItem('electronickit', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not exports['qb-inventory']:GetItemByName(source, 'electronickit') then return end
    TriggerClientEvent('electronickit:UseElectronickit', source)
end)
