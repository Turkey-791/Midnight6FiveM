-- [2026-09-03 追加] 取材案件(作業報酬)のクライアント側処理。
-- 既存のカメラ/マイク/車両スポーン機能(client/main.lua, spawner.lua,
-- camera.lua)には一切手を加えず、独立したファイルとして追加する。

local currentAssignment = nil
local assignmentBlip = nil
local reporting = false

local function ClearAssignmentBlip()
    if assignmentBlip and DoesBlipExist(assignmentBlip) then
        RemoveBlip(assignmentBlip)
    end
    assignmentBlip = nil
end

RegisterNetEvent('qb-newsjob:client:setAssignment', function(location)
    currentAssignment = location
    ClearAssignmentBlip()
    assignmentBlip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
    SetBlipSprite(assignmentBlip, 249)
    SetBlipScale(assignmentBlip, 0.9)
    SetBlipColour(assignmentBlip, 5)
    SetBlipAsShortRange(assignmentBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(location.label or Lang:t('text.assignment_blip'))
    EndTextCommandSetBlipName(assignmentBlip)
end)

RegisterNetEvent('qb-newsjob:client:clearAssignment', function()
    currentAssignment = nil
    reporting = false
    ClearAssignmentBlip()
end)

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        local sleep = 1000
        if currentAssignment and PlayerJob and PlayerJob.name == 'reporter' and not reporting then
            local coords = currentAssignment.coords
            local pos = GetEntityCoords(PlayerPedId())
            local dist = #(pos - vector3(coords.x, coords.y, coords.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(2, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.4, 235, 158, 46, 200, false, false, false, true, false, false, false)
                if dist < 2.5 then
                    DrawText3D(coords.x, coords.y, coords.z + 1.0, Lang:t('task.start_report'))
                    if IsControlJustPressed(0, 38) then
                        reporting = true
                        QBCore.Functions.Progressbar('news_report', Lang:t('progress.reporting'), math.random(Config.NewsReportTime.min, Config.NewsReportTime.max), false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {}, {}, {}, function() -- Done
                            reporting = false
                            TriggerServerEvent('qb-newsjob:server:completeAssignment')
                        end, function() -- Cancel
                            reporting = false
                            QBCore.Functions.Notify(Lang:t('task.cancel_task'), 'error')
                        end)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
