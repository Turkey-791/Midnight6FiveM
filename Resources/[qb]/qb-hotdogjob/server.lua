local QBCore = exports['qb-core']:GetCoreObject({ 'Functions', 'Commands' })
local Bail = {}

-- Money Authority fix (2026-08-29): 実店舗在庫(hotdog)はox_inventory等の実アイテムとして存在しないため、
-- サーバー側でcitizenid単位の「在庫state」を新設し、Sellイベントの amount / price を完全にサーバー権威にする。
local HotdogStock = {}

local function ResetHotdogStock(citizenid)
    HotdogStock[citizenid] = { exotic = 0, rare = 0, common = 0 }
end

-- client.lua の UpdateLevel() と同じ閾値をサーバー側でも用いる(クライアント申告のConfig.MyLevelは信用しない)。
local function GetHotdogLevel(Player)
    local rep = Player.GetRep('hotdog')
    if rep >= 1 and rep < 50 then
        return 1
    elseif rep >= 50 and rep < 100 then
        return 2
    elseif rep >= 100 and rep < 200 then
        return 3
    elseif rep >= 200 then
        return 4
    end
    return 1
end

-- Callbacks

QBCore.Functions.CreateCallback('qb-hotdogjob:server:HasMoney', function(source, cb)
    local Player = exports['qb-core']:GetPlayer(source)

    if Player.PlayerData.money.bank >= Config.StandDeposit then
        Player.RemoveMoney('bank', Config.StandDeposit, 'hot dog deposit')
        Bail[Player.PlayerData.citizenid] = true
        -- Money Authority fix (2026-08-29): 新しく勤務を開始するタイミングでサーバー側在庫をリセットする(クライアントのConfig.Stock初期化と対応)。
        ResetHotdogStock(Player.PlayerData.citizenid)
        cb(true)
    else
        Bail[Player.PlayerData.citizenid] = false
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('qb-hotdogjob:server:BringBack', function(source, cb)
    local Player = exports['qb-core']:GetPlayer(source)

    if Bail[Player.PlayerData.citizenid] then
        Player.AddMoney('bank', Config.StandDeposit, 'hot dog deposit')
        -- Money Authority fix (2026-08-29): 勤務終了(屋台返却)時にサーバー側在庫も破棄する(クライアントのCurrent=0リセットと対応)。
        ResetHotdogStock(Player.PlayerData.citizenid)
        cb(true)
    else
        cb(false)
    end
end)

-- Events

-- Money Authority fix (2026-08-29): amount/priceのクライアント申告値は使用しない。
-- quality(識別子)と希望amountのみをクライアントから受け取り、実在庫からの差し引き数量とpriceはサーバーが決定する。
RegisterNetEvent('qb-hotdogjob:server:Sell', function(coords, quality, requestedAmount)
    local src = source
    local pCoords = GetEntityCoords(GetPlayerPed(src))
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    if #(pCoords - coords) > 4 then
        exports['qb-core']:ExploitBan(src, 'hotdog job')
        return
    end
    if quality ~= 'exotic' and quality ~= 'rare' and quality ~= 'common' then return end
    local citizenid = Player.PlayerData.citizenid
    local stock = HotdogStock[citizenid]
    if not stock or not stock[quality] or stock[quality] <= 0 then return end
    local amount = tonumber(requestedAmount)
    if not amount or amount <= 0 then return end
    if amount > stock[quality] then amount = stock[quality] end
    local level = GetHotdogLevel(Player)
    local priceRange = Config.Stock[quality].Price[level]
    local price = math.random(priceRange.min, priceRange.max)
    stock[quality] = stock[quality] - amount
    Player.AddMoney('cash', amount * price, 'sold hotdog')
end)

RegisterNetEvent('qb-hotdogjob:server:UpdateReputation', function(quality)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return end
    -- Money Authority fix (2026-08-29): 不正な quality 文字列で以降のConfig.Stock[quality]参照が
    -- nilエラーにならないよう検証する(既存の仕様上、この3種以外は元々レップも付与されない)。
    if quality ~= 'exotic' and quality ~= 'rare' and quality ~= 'common' then return end
    if quality == 'exotic' then
        if Player.GetRep('hotdog') + 3 > Config.MaxReputation then
            Player.AddRep('hotdog', Config.MaxReputation - Player.GetRep('hotdog'))
        else
            Player.AddRep('hotdog', 3)
        end
    elseif quality == 'rare' then
        if Player.GetRep('hotdog') + 2 > Config.MaxReputation then
            Player.AddRep('hotdog', Config.MaxReputation - Player.GetRep('hotdog'))
        else
            Player.AddRep('hotdog', 2)
        end
    elseif quality == 'common' then
        if Player.GetRep('hotdog') + 1 > Config.MaxReputation then
            Player.AddRep('hotdog', Config.MaxReputation - Player.GetRep('hotdog'))
        else
            Player.AddRep('hotdog', 1)
        end
    end

    -- Money Authority fix (2026-08-29): 実際に販売可能な在庫(HotdogStock)への加算はサーバー側で独自に抽選する。
    -- クライアント側のLuckyAmount表示(UI文言)とは一致しないことがあるが、Stage 1のpawnshop/drugs角売りと同様の許容差。
    local citizenid = Player.PlayerData.citizenid
    if not HotdogStock[citizenid] then ResetHotdogStock(citizenid) end
    local level = GetHotdogLevel(Player)
    local addAmount = 1
    if level > 1 then
        local Luck = math.random(1, 2)
        local LuckyNumber = math.random(1, 2)
        if Luck == LuckyNumber then
            addAmount = math.random(1, level)
        end
    end
    local maxForLevel = Config.Stock[quality].Max[level]
    local newCurrent = HotdogStock[citizenid][quality] + addAmount
    if newCurrent > maxForLevel then newCurrent = maxForLevel end
    HotdogStock[citizenid][quality] = newCurrent

    TriggerClientEvent('qb-hotdogjob:client:UpdateReputation', src, Player.PlayerData.metadata['rep'])
end)

-- Money Authority fix (2026-08-29): ログアウト時にサーバー側在庫を破棄する。
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        HotdogStock[Player.PlayerData.citizenid] = nil
    end
end)

-- Commands

QBCore.Commands.Add('removestand', Lang:t('info.command'), {}, false, function(source, _)
    TriggerClientEvent('qb-hotdogjob:staff:DeletStand', source)
end, 'admin')
