local QBCore = exports['qb-core']:GetCoreObject()

print('[moneywash] client.lua loaded')

CreateThread(function()
    Wait(2000)

    print('[moneywash] creating BoxZone')
    print(('[moneywash] coords = %.2f %.2f %.2f'):format(
        Config.Location.coords.x,
        Config.Location.coords.y,
        Config.Location.coords.z
    ))

    exports['qb-target']:AddBoxZone(
        'MoneyWash',
        Config.Location.coords,
        Config.Location.length,
        Config.Location.width,
        {
            name = 'MoneyWash',
            heading = Config.Location.heading,
            debugPoly = true,
            minZ = Config.Location.minZ,
            maxZ = Config.Location.maxZ,
        },
        {
            options = {
                {
                    type = 'client',
                    event = 'qb-moneywash:client:wash',
                    icon = 'fas fa-money-bill-wave',
                    label = 'マーク付き紙幣を洗浄する',
                }
            },
            distance = Config.Location.distance
        }
    )

    print('[moneywash] AddBoxZone finished')
end)

RegisterNetEvent('qb-moneywash:client:wash', function()
    print('[moneywash] target selected')
    TriggerServerEvent('qb-moneywash:server:wash')
end)

-- 座標確認用マーカー
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - Config.Location.coords)

        if dist < 100.0 then
            sleep = 0

            DrawMarker(
                1,
                Config.Location.coords.x,
                Config.Location.coords.y,
                Config.Location.coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                2.0, 2.0, 1.0,
                255, 255, 255, 150,
                false, false, 2, false, nil, nil, false
            )
        end

        Wait(sleep)
    end
end)