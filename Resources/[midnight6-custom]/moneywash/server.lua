local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('qb-moneywash:server:wash', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    -- サーバー側でも洗浄場所との距離を確認
    -- クライアントからイベントだけ直接実行される対策
    local ped = GetPlayerPed(src)

    if ped == 0 then
        return
    end

    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - Config.Location.coords)

    if distance > 5.0 then
        print(('[qb-moneywash] %s tried to wash money outside wash location'):format(src))
        return
    end

    -- markedbills をすべて取得
    local items = Player.Functions.GetItemsByName('markedbills')

    if not items or #items == 0 then
        TriggerClientEvent(
            'QBCore:Notify',
            src,
            'マーク付き紙幣を持っていません',
            'error'
        )
        return
    end

    local totalWorth = 0
    local validItems = {}

    -- 各 markedbills の worth を確認
    for _, item in pairs(items) do
        local worth = 0

        if item.info and item.info.worth then
            worth = tonumber(item.info.worth) or 0
        end

        if worth > 0 then
            local amount = item.amount or 1

            totalWorth = totalWorth + (worth * amount)

            validItems[#validItems + 1] = {
                slot = item.slot,
                amount = amount
            }
        end
    end

    if totalWorth <= 0 then
        TriggerClientEvent(
            'QBCore:Notify',
            src,
            'この紙幣には価値が設定されていません',
            'error'
        )
        return
    end

    -- まず markedbills を削除
    for _, item in pairs(validItems) do
        local removed = exports['qb-inventory']:RemoveItem(
            src,
            'markedbills',
            item.amount,
            item.slot,
            'qb-moneywash:wash'
        )

        if not removed then
            TriggerClientEvent(
                'QBCore:Notify',
                src,
                '紙幣の処理に失敗しました',
                'error'
            )
            return
        end
    end

    -- 手数料計算
    local fee = math.floor(totalWorth * Config.Fee)
    local payout = totalWorth - fee

    -- 現金として付与
    Player.Functions.AddMoney(
        'cash',
        payout,
        'money-wash'
    )

    TriggerClientEvent(
        'QBCore:Notify',
        src,
        ('洗浄完了: $%s（手数料 $%s）'):format(
            payout,
            fee
        ),
        'success'
    )

    print(
        ('[qb-moneywash] %s washed $%s -> $%s cash')
        :format(src, totalWorth, payout)
    )
end)