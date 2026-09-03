RegisterCommand('testwanted', function()
    local player = PlayerId()

    SetMaxWantedLevel(5)

    SetPlayerWantedLevel(player, 3, false)
    SetPlayerWantedLevelNow(player, false)

    print('[test-police] max wanted enabled')
    print('[test-police] wanted = ' .. GetPlayerWantedLevel(player))
end, true)
RegisterCommand('clearwanted', function()
    local player = PlayerId()

    ClearPlayerWantedLevel(player)
    SetDispatchCopsForPlayer(player, false)
    EnableDispatchService(1, false)
    SetMaxWantedLevel(0)

    print('[test-police] Wanted cleared')
end, true)