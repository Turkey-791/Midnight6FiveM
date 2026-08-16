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

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerStatus(values)
    for name, value in pairs(values) do
        if value > 100 or value < -100 then
            value = value * 0.0001
        end

        local currentValue = client.player:get(name) or 0
        client.player:setr(name, lib.math.clamp(currentValue + value, 0, 100))
    end
end