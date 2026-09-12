---@diagnostic disable: undefined-global
-- ════════════════════════════════════════════════════════════════
-- m6_crime | CONNECTORS
--   既存の犯罪MODを「無改造」で取り込む層。
--   FiveM は同じイベント名に複数リソースがハンドラを登録できるので、
--   相手のサーバーイベントをこちらでも受けるだけで接続できる。
--
--   重要(実コードで確認済み):
--     ・qb-storerobbery / qb-bankrobbery / qb-truckrobbery の callCops は
--       「犯人のクライアント」から送られる → source = 犯人
--     ・police:server:policeAlert は送信元がまちまち。
--         宝石店・空き巣・ドラッグ・車両キー → 犯人
--         コンビニ強盗・銀行強盗           → 通報を受けた警官(中継)
--       そのため、送信元が警察職なら無視する。
-- ════════════════════════════════════════════════════════════════

local QBCore = exports['qb-core']:GetCoreObject()

local function Debug(...)
    if Config.Debug then print('^3[m6_crime|conn]^7', ...) end
end

local function PlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

-- 犯人が本当にその現場にいたかの簡易チェック(通常プレイ範囲の抜け道対策)
local function NearEnough(src, coords, maxDist)
    if not coords then return true end
    local pc = PlayerCoords(src)
    if not pc then return false end
    local c = vector3(coords.x or coords[1] or 0.0, coords.y or coords[2] or 0.0, coords.z or coords[3] or 0.0)
    return #(pc - c) <= (maxDist or 100.0)
end

local function IsPolicePlayer(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    local job = Player.PlayerData.job
    return job and (job.type == 'leo') or false
end

-- ── コンビニ強盗 ──────────────────────────────────────────────
if Config.Connectors.storeRobbery then
    RegisterNetEvent('qb-storerobbery:server:callCops', function(_type, _safe, _streetLabel, coords)
        local src = source
        if not NearEnough(src, coords, 120.0) then
            Debug(('storeRobbery: src=%d が現場から離れているため無視'):format(src))
            return
        end
        exports['m6_crime']:Report(src, 'STORE_ROBBERY', coords, {
            sourceMod = 'qb-storerobbery',
            witnessed = true,
        })
    end)
end

-- ── 銀行強盗 ──────────────────────────────────────────────────
if Config.Connectors.bankRobbery then
    RegisterNetEvent('qb-bankrobbery:server:callCops', function(robType, _bank, coords)
        local src = source
        if not NearEnough(src, coords, 150.0) then return end
        local crime = (robType == 'small') and 'BANK_ROBBERY_SMALL' or 'BANK_ROBBERY_BIG'
        exports['m6_crime']:Report(src, crime, coords, {
            sourceMod = 'qb-bankrobbery',
            witnessed = true,
        })
    end)
end

-- ── 現金輸送車強盗 ────────────────────────────────────────────
if Config.Connectors.truckRobbery then
    RegisterNetEvent('qb-armoredtruckheist:server:callCops', function(_streetLabel, coords)
        local src = source
        if not NearEnough(src, coords, 200.0) then return end
        exports['m6_crime']:Report(src, 'TRUCK_ROBBERY', coords, {
            sourceMod = 'qb-truckrobbery',
            witnessed = true,
        })
    end)
end

-- ── その他の通報(宝石店・空き巣・ドラッグ・車両キー) ─────────
-- 犯罪の種類が文面からしか分からないため、既定では手配レベルを付けず
-- 台帳への記録だけを行う。種別を分けたい場合は、各MODの発火箇所に
-- exports['m6_crime']:Report(...) を1行足すのが確実。
if Config.Connectors.genericPoliceAlert then
    RegisterNetEvent('police:server:policeAlert', function(_text)
        local src = source
        if not src or src == 0 then return end
        if IsPolicePlayer(src) then
            -- 警官からの中継(コンビニ・銀行)なので無視
            return
        end
        exports['m6_crime']:Report(src, 'GENERIC_ALERT', PlayerCoords(src), {
            sourceMod = 'police:server:policeAlert',
            witnessed = true,
            meta = { text = tostring(_text) },
        })
    end)
end

-- ════════════════════════════════════════════════════════════════
-- プレイヤー警察の拘束・逮捕に AI 警察を追従させる
--   ・手錠をかけられた犯人に AI 警察が撃ち続けるのを防ぐ
--   ・qb-policejob 経由の収監も事件台帳に記録する
-- ════════════════════════════════════════════════════════════════

-- 手錠(qb-policejob/server/main.lua 177: source = 拘束された本人)
RegisterNetEvent('police:server:SetHandcuffStatus', function(isHandcuffed)
    local src = source
    if not isHandcuffed then return end
    -- 手配を解除すると、RDE 側の状態同期でAI警官が撤収する
    local ok, err = pcall(function()
        exports[Config.AiPoliceResource]:SetWantedLevel(src, 0, 'Cuffed by police')
    end)
    if ok then
        Debug(('手錠: src=%d の手配を解除しAI警察を撤収'):format(src))
    else
        print(('^1[m6_crime]^7 手錠時の手配解除に失敗: %s'):format(tostring(err)))
    end
end)

-- qb-policejob の収監(server/interactions.lua 128: source = 警官, playerId = 収監される側)
RegisterNetEvent('police:server:JailPlayer', function(playerId, time)
    local officer = source
    local targetId = tonumber(playerId)
    if not targetId then return end
    if not IsPolicePlayer(officer) then return end   -- 警官以外からの発火は無視

    pcall(function()
        exports[Config.AiPoliceResource]:SetWantedLevel(targetId, 0, 'Arrested by player police')
    end)
    -- RDE を通らない収監なので、ここで台帳へ通知する
    TriggerEvent('m6_crime:server:arrested', targetId, tonumber(time) or 0, 'player_police_qb')
    Debug(('プレイヤー警察による収監: target=%d time=%s'):format(targetId, tostring(time)))
end)
