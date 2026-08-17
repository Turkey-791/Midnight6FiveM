RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    client.onLogout()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    local groups = PlayerData.groups or {}
    groups[job.name] = job.grade.level
    client.setPlayerData('groups', groups)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    local groups = PlayerData.groups or {}
    groups[gang.name] = gang.grade.level
    client.setPlayerData('groups', groups)
end)

-- Names ox_inventory uses for status effects (item.client.status) that
-- correspond to qb-core's own metadata fields. Anything not in this list
-- (e.g. a custom status name) is only written to the ox_lib statebag, same
-- as before.
local qbMetadataStatus = {
    hunger = true,
    thirst = true,
    stress = true,
}

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerStatus(values)
    local qbDeltas = nil

    for name, value in pairs(values) do
        if value > 100 or value < -100 then
            value = value * 0.0001
        end

        local currentValue = client.player:get(name) or 0
        client.player:setr(name, lib.math.clamp(currentValue + value, 0, 100))

        -- ox_lib's statebag above is NOT what qb-hud reads for the on-screen
        -- hunger/thirst/stress bars - qb-hud reads Player.PlayerData.metadata
        -- directly. Without this, eating/drinking items visually does
        -- nothing on the HUD even though the item's effect did technically
        -- apply somewhere.
        if qbMetadataStatus[name] then
            qbDeltas = qbDeltas or {}
            qbDeltas[name] = value
        end
    end

    if qbDeltas then
        TriggerServerEvent('ox-qb-bridge:updateStatus', qbDeltas)
    end
end