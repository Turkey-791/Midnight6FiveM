-- ============================================================
-- [新機能 / 自動ドア] Config.AutoDoors に登録された各ドアを、
-- 権限のあるプレイヤーが近づくと自動で開き(ロック解除)、
-- 離れると自動で閉じる(ロック)ようにする処理です。
--
-- 実装方式は、このサーバーに既に導入されている qb-doorlock と
-- 同じ仕組み(AddDoorToSystem / DoorSystemSetDoorState)を利用して
-- います。qb-doorlock自体は変更していません(完全に独立した処理)。
--
-- Config.AutoDoorDebug = true の間は、開閉のたびにF8コンソールへ
-- ログを出力します。動作確認が終わったら false にしてください。
-- ============================================================

print('^5[qb-mechanicjob]^7 zz_autodoor.lua / client/autodoor.lua loaded OK (v1)') -- [動作確認用・一時] リソース起動時に必ず1回出るログ

Config.AutoDoorDebug = true

local autoDoorStates = {} -- [index] = true(開) / false(閉) / nil(未登録・圏外)

local function IsAuthorizedForAutoDoor(door)
    if not door.authorizedJobs then return true end
    if not PlayerData or not PlayerData.job then return false end
    local minGrade = door.authorizedJobs[PlayerData.job.name]
    if minGrade == nil then return false end
    local grade = PlayerData.job.grade and PlayerData.job.grade.level or 0
    return grade >= minGrade
end

CreateThread(function()
    if not Config.AutoDoors or #Config.AutoDoors == 0 then return end

    while true do
        Wait(500)
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)

        for i, door in ipairs(Config.AutoDoors) do
            local doorHash = ('qb_mechanicjob_autodoor_%d'):format(i)
            local dist = #(pedCoords - door.objCoords)

            if dist <= (door.closeDistance or 8.0) then
                local obj = GetClosestObjectOfType(
                    door.objCoords.x, door.objCoords.y, door.objCoords.z,
                    5.0, door.objName, false, false, false
                )

                if obj and obj ~= 0 then
                    if not IsDoorRegisteredWithSystem(doorHash) then
                        AddDoorToSystem(doorHash, door.objName, door.objCoords.x, door.objCoords.y, door.objCoords.z, false, false, false)
                    end

                    local shouldOpen = dist <= (door.openDistance or 5.0) and IsAuthorizedForAutoDoor(door)

                    if shouldOpen and autoDoorStates[i] ~= true then
                        DoorSystemSetDoorState(doorHash, 0, false, false) -- 0 = 解錠(開く)
                        autoDoorStates[i] = true
                        if Config.AutoDoorDebug then
                            print(('^2[autodoor]^7 %s (%s) を開きました (dist=%.2f)'):format(door.shop or doorHash, door.objName, dist))
                        end
                    elseif not shouldOpen and autoDoorStates[i] ~= false then
                        DoorSystemSetDoorState(doorHash, 1, false, false) -- 1 = 施錠(閉じる)
                        autoDoorStates[i] = false
                        if Config.AutoDoorDebug then
                            print(('^1[autodoor]^7 %s (%s) を閉じました (dist=%.2f, authorized=%s)'):format(
                                door.shop or doorHash, door.objName, dist, tostring(IsAuthorizedForAutoDoor(door))
                            ))
                        end
                    end
                end
            elseif autoDoorStates[i] ~= nil then
                -- 圏外に出たら登録解除(常時ロード状態にしない)
                if IsDoorRegisteredWithSystem(doorHash) then
                    RemoveDoorFromSystem(doorHash)
                end
                autoDoorStates[i] = nil
                if Config.AutoDoorDebug then
                    print(('^3[autodoor]^7 %s (%s) の圏外に出たため登録解除しました'):format(door.shop or doorHash, door.objName))
                end
            end
        end
    end
end)
