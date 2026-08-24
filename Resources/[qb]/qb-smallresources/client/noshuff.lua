-- NOTE:
-- disableShuffle を false にすると、プレイヤーが車両に乗ると自動で運転席に座るようになります。
-- disableShuffle を true にすると、プレイヤーが車両に乗ると自動で運転席に座ることを防ぎます。
-- (2026.08.23 potato)
local disableShuffle = true

RegisterNetEvent('QBCore:Client:EnteredVehicle', function(data)
    local ped = PlayerPedId()
    while IsPedInAnyVehicle(ped, false) do
        local sleep = 100
        if disableShuffle and GetPedInVehicleSeat(data.vehicle, 0) == ped and GetIsTaskActive(ped, 165) then
            sleep = 0
            SetPedIntoVehicle(ped, data.vehicle, 0)
            SetPedConfigFlag(ped, 184, true)
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('SeatShuffle', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        disableShuffle = false
        SetPedConfigFlag(ped, 184, false)
        Wait(3000)
        disableShuffle = true
    else
        CancelEvent()
    end
end)

RegisterCommand('shuff', function()
    TriggerEvent('SeatShuffle')
end, false)

--- 座席移動コマンドをキーバインドに登録 (2026.08.23 potato)
RegisterKeyMapping('shuff', '座席を移動する', 'keyboard', 'G')