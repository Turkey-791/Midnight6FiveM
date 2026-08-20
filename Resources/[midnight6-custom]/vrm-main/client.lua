local voiceS = nil
local markerOn = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)

        local proximity = LocalPlayer.state.proximity

        if proximity and proximity.index then
            local newVoiceS = proximity.index

            if newVoiceS ~= voiceS then
                voiceS = newVoiceS
                markerSwitch()
            end
        end

        if markerOn then
            local coords = GetEntityCoords(PlayerPedId())
            Marker(Config.Type, coords.x, coords.y, coords.z, voiceS)
        end
    end
end)

function markerSwitch()
    markerOn = true

    Citizen.SetTimeout(1000, function()
        markerOn = false
    end)
end

function Marker(type, x, y, z, num)
    DrawMarker(
        type,
        x, y, z - Config.Height,
        0.0, 0.0, 0.0,
        0.0, 180.0, 0.0,
        Config.Range[num].size,
        Config.Range[num].size,
        2.0,
        Config.Range[num].r,
        Config.Range[num].g,
        Config.Range[num].b,
        Config.Range[num].a,
        false, true, 2,
        nil, nil, false
    )
end