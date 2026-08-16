RegisterCommand('testwanted', function()
    local player = PlayerId()

    SetMaxWantedLevel(5)
    SetDispatchCopsForPlayer(player, true)

    EnableDispatchService(1, true)

    SetPlayerWantedLevel(player, 3, false)
    SetPlayerWantedLevelNow(player, false)

    print('[test-police] Wanted level = ' .. GetPlayerWantedLevel(player))
end, false)

RegisterCommand('clearwanted', function()
    local player = PlayerId()

    ClearPlayerWantedLevel(player)
    SetDispatchCopsForPlayer(player, false)
    EnableDispatchService(1, false)
    SetMaxWantedLevel(0)

    print('[test-police] Wanted cleared')
end, false)