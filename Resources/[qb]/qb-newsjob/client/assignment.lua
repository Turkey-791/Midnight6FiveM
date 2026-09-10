-- [2026-09-03 追加] 取材案件(作業報酬)のクライアント側処理。
-- 既存のカメラ/マイク/車両スポーン機能(client/main.lua, spawner.lua,
-- camera.lua)には一切手を加えず、独立したファイルとして追加する。

local currentAssignment = nil
local assignmentBlip = nil
local reporting = false
-- [2026-09-07 追加] Config.NewsLocationsの座標は実機未確認の仮座標だったため、
-- 3D距離(#(pos-coords))で判定していると、Zがズレている時に至近距離まで
-- 近づいても30m/2.5mの閾値を超えたと判定され、マーカーもEプロンプトも
-- 一切表示されない不具合が起きていた。対策として出現判定は水平(2D)距離
-- のみで行うように変更した(これは現在も有効)。
--
-- [2026-09-07 追加後、同日撤去] マーカーの見た目の高さを、近づいた時点で
-- GetGroundZFor_3dCoord(真上から下向きにレイを飛ばして最初に当たった
-- 面の高さを取得する関数)で補正する処理を一時的に追加していたが、
-- ミッションロウ署受付前(屋内・頭上に別フロア/屋根がある座標)では
-- レイが天井や屋根に先に当たってしまい、マーカーが実際の受付ではなく
-- 屋上に出現するという新たな不具合を引き起こしていた
-- (受付前 Z=30.69 に対し、この補正で屋上 Z=43.69 相当の高さに
-- 書き換えられてしまっていた)。
-- 現在は全5地点とも実機で/coords確認済みの正確な座標になっているため、
-- この地面補正処理自体を撤去し、config.luaのZ座標をそのまま使う。

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
    -- [JP] qb_locale が en 以外のときは日本語対応フォント(1)を使う。en のときは従来通り font 4。
    if GetConvar('qb_locale', 'en') == 'en' then
        SetTextFont(4)
    else
        SetTextFont(1)
    end
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
            -- [2026-09-07 追加] 出現判定は水平(2D)距離のみで行う(Zのズレの影響を受けない)
            local dist = #(vector2(pos.x, pos.y) - vector2(coords.x, coords.y))
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
