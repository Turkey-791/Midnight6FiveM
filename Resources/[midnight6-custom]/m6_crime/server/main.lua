---@diagnostic disable: undefined-global
-- ════════════════════════════════════════════════════════════════
-- m6_crime | SERVER
--   ① 犯罪の共通窓口(Report)
--   ② 事件台帳(m6_crime_incidents)と時効
--   ③ AI警察(rde_aipd_m6)への出力
--   ④ プレイヤー警察の人数 → AI出動台数の倍率を配信
--   ⑤ プレイヤー警察への通報
-- ════════════════════════════════════════════════════════════════

local QBCore = exports['qb-core']:GetCoreObject()

local function Debug(...)
    if Config.Debug then print('^3[m6_crime]^7', ...) end
end

-- ════════════════════════════════════════════════════════════════
-- DB
-- ════════════════════════════════════════════════════════════════

local dbReady = false

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `m6_crime_incidents` (
            `id`          INT(11) NOT NULL AUTO_INCREMENT,
            `citizenid`   VARCHAR(50) NOT NULL,
            `crime_type`  VARCHAR(64) NOT NULL,
            `label`       VARCHAR(64) DEFAULT NULL,
            `status`      VARCHAR(24) NOT NULL DEFAULT 'open',
            `source_mod`  VARCHAR(64) DEFAULT NULL,
            `witnessed`   TINYINT(1) NOT NULL DEFAULT 0,
            `x` FLOAT DEFAULT NULL,
            `y` FLOAT DEFAULT NULL,
            `z` FLOAT DEFAULT NULL,
            `meta`        LONGTEXT DEFAULT NULL,
            `created_at`  DATETIME NOT NULL,
            `expires_at`  DATETIME DEFAULT NULL,
            `closed_at`   DATETIME DEFAULT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_status` (`status`),
            INDEX `idx_expires` (`expires_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function()
        dbReady = true
        print('^2[m6_crime]^7 事件台帳テーブル準備完了')
    end)
end)

-- ════════════════════════════════════════════════════════════════
-- ヘルパー
-- ════════════════════════════════════════════════════════════════

local function GetCitizenId(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

local function IsPoliceSource(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    local job = Player.PlayerData.job
    if not job then return false end
    for _, name in ipairs(Config.PoliceJobs) do
        if job.name == name or job.type == name then
            if Config.CountOnlyOnDuty then return job.onduty == true end
            return true
        end
    end
    return false
end

local function CrimeCfg(crimeType)
    return Config.CrimeTypes[crimeType] or {}
end

-- 重複除去: 同じ犯人・同じ種別・一定秒数以内
local recent = {}

local function IsDuplicate(src, crimeType)
    local key = tostring(src) .. '|' .. tostring(crimeType)
    local now = os.time()
    local last = recent[key]
    recent[key] = now
    return last and (now - last) < (Config.Dedupe.windowSeconds or 20)
end

AddEventHandler('playerDropped', function()
    local src = source
    for key in pairs(recent) do
        if key:sub(1, #tostring(src) + 1) == tostring(src) .. '|' then recent[key] = nil end
    end
end)

-- ════════════════════════════════════════════════════════════════
-- プレイヤー警察への通報
-- ════════════════════════════════════════════════════════════════

local function AlertPolice(label, coords)
    if not coords then return end
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job and v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
            local src = v.PlayerData.source
            TriggerClientEvent('qb-phone:client:addPoliceAlert', src, {
                title = label,
                coords = { x = coords.x, y = coords.y, z = coords.z },
                description = label,
            })
            TriggerClientEvent('police:client:policeAlert', src, coords, label)
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 事件台帳
-- ════════════════════════════════════════════════════════════════

local function InsertIncident(citizenid, crimeType, coords, meta, sourceMod, witnessed)
    if not dbReady or not citizenid then return end
    local cfg      = CrimeCfg(crimeType)
    local statute  = cfg.statute or Config.DefaultStatute
    local expires  = statute and (os.time() + statute) or nil

    MySQL.insert([[
        INSERT INTO m6_crime_incidents
            (citizenid, crime_type, label, status, source_mod, witnessed, x, y, z, meta, created_at, expires_at)
        VALUES (?, ?, ?, 'open', ?, ?, ?, ?, ?, ?, NOW(), ?)
    ]], {
        citizenid, crimeType, cfg.label or crimeType, sourceMod or 'unknown',
        witnessed and 1 or 0,
        coords and coords.x or nil, coords and coords.y or nil, coords and coords.z or nil,
        meta and json.encode(meta) or nil,
        expires and os.date('%Y-%m-%d %H:%M:%S', expires) or nil,
    }, function(id)
        Debug(('事件を記録: #%s %s (%s) 時効=%s'):format(tostring(id), crimeType, citizenid, tostring(statute)))
    end)
end

-- 逮捕された: その人の未解決事件を清算する
local function SettleIncidents(citizenid, newStatus)
    if not dbReady or not citizenid then return end
    MySQL.update([[
        UPDATE m6_crime_incidents
        SET status = ?, closed_at = NOW(), expires_at = NULL
        WHERE citizenid = ? AND status = 'open'
    ]], { newStatus, citizenid }, function(affected)
        Debug(('事件清算: %s 件 → %s (%s)'):format(tostring(affected), newStatus, citizenid))
    end)
end

-- 時効チェック(1分ごと)
CreateThread(function()
    while true do
        Wait(60000)
        if dbReady then
            MySQL.update([[
                UPDATE m6_crime_incidents
                SET status = 'expired', closed_at = NOW()
                WHERE status = 'open' AND expires_at IS NOT NULL AND expires_at <= NOW()
            ]], {}, function(affected)
                if affected and affected > 0 then
                    Debug(('時効成立: %d 件'):format(affected))
                end
            end)
        end
    end
end)

-- ════════════════════════════════════════════════════════════════
-- 共通窓口
--   すべての犯罪はここを通す。
--   exports['m6_crime']:Report(offenderSrc, crimeType, coords, opts)
--     opts = { sourceMod = 'qb-storerobbery', witnessed = true, skipAi = false, level = 3 }
-- ════════════════════════════════════════════════════════════════

local function Report(offenderSrc, crimeType, coords, opts)
    offenderSrc = tonumber(offenderSrc)
    if not offenderSrc or offenderSrc == 0 then return false end
    if not crimeType then return false end
    opts = opts or {}

    if IsDuplicate(offenderSrc, crimeType) then
        Debug(('重複のため無視: %s (src=%d)'):format(crimeType, offenderSrc))
        return false
    end

    local citizenid = GetCitizenId(offenderSrc)
    if not citizenid then return false end

    local cfg = CrimeCfg(crimeType)

    -- ① 台帳へ
    InsertIncident(citizenid, crimeType, coords, opts.meta, opts.sourceMod, opts.witnessed)

    -- ② 未解決事件の時効を延長する設定なら延長
    if Config.Statute.extendOnNewCrime and dbReady then
        MySQL.update([[
            UPDATE m6_crime_incidents
            SET expires_at = DATE_ADD(expires_at, INTERVAL ? SECOND)
            WHERE citizenid = ? AND status = 'open' AND expires_at IS NOT NULL
        ]], { Config.Statute.extendSeconds or 1800, citizenid })
    end

    -- ③ プレイヤー警察へ通報
    if cfg.alert and coords then
        AlertPolice(cfg.label or crimeType, coords)
    end

    -- ④ AI警察へ
    local level = opts.level or cfg.level
    if level and not opts.skipAi then
        local ok, err = pcall(function()
            exports[Config.AiPoliceResource]:SetWantedLevel(offenderSrc, level, cfg.label or crimeType)
        end)
        if not ok then
            print(('^1[m6_crime]^7 AI警察への手配に失敗: %s'):format(tostring(err)))
        end
    end

    Debug(('Report: src=%d %s level=%s mod=%s'):format(
        offenderSrc, crimeType, tostring(level), tostring(opts.sourceMod)))
    return true
end

exports('Report', Report)

-- ════════════════════════════════════════════════════════════════
-- RDE からのフック
-- ════════════════════════════════════════════════════════════════

-- RDE が犯罪を検知した(目撃されたかどうかを問わず)
AddEventHandler('m6_crime:server:crime', function(src, crimeType, data)
    if GetInvokingResource() ~= Config.AiPoliceResource then return end
    local citizenid = GetCitizenId(src)
    if not citizenid then return end
    if IsDuplicate(src, crimeType) then return end
    InsertIncident(citizenid, crimeType, data and data.coords, data, Config.AiPoliceResource,
        data and data.witnessed)
end)

-- 逮捕された(AI警察・プレイヤー警察・管理者コマンドのすべてがここを通る)
AddEventHandler('m6_crime:server:arrested', function(src, jailUnits, reason)
    local citizenid = GetCitizenId(src)
    if not citizenid then return end
    Debug(('逮捕: src=%d units=%s reason=%s'):format(src, tostring(jailUnits), tostring(reason)))
    if Config.Statute.stopOnArrest then
        SettleIncidents(citizenid, Config.Statute.settleOnArrest and 'served' or 'arrested')
    end
end)

-- 出所した
AddEventHandler('m6_crime:server:released', function(src)
    local citizenid = GetCitizenId(src)
    if not citizenid then return end
    Debug(('出所: %s'):format(citizenid))
end)

-- 捕縛処理の途中で切断された(通常プレイの範囲での抜け道対策)
AddEventHandler('m6_crime:server:captureAborted', function(src, jailTime)
    local citizenid = GetCitizenId(src)
    if not citizenid then return end
    if not dbReady then return end
    MySQL.update([[
        UPDATE m6_crime_incidents
        SET status = 'fled_disconnect'
        WHERE citizenid = ? AND status = 'open'
    ]], { citizenid })
    Debug(('捕縛前に切断: %s (刑期 %s 秒相当は未執行)'):format(citizenid, tostring(jailTime)))
end)

-- ════════════════════════════════════════════════════════════════
-- プレイヤー警察の人数 → AI 出動台数の倍率
-- ════════════════════════════════════════════════════════════════

local lastFactor = nil

local function CountPolice()
    local count = 0
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        local job = v and v.PlayerData and v.PlayerData.job
        if job then
            for _, name in ipairs(Config.PoliceJobs) do
                if job.name == name or job.type == name then
                    if (not Config.CountOnlyOnDuty) or job.onduty then
                        count = count + 1
                    end
                    break
                end
            end
        end
    end
    return count
end

local function BroadcastFactor(force)
    local count  = CountPolice()
    local factor = Config.PoliceFactor[count]
    if factor == nil then factor = Config.PoliceFactorDefault or 0.0 end
    if force or factor ~= lastFactor then
        lastFactor = factor
        TriggerClientEvent('m6_crime:client:policeFactor', -1, factor)
        print(('^2[m6_crime]^7 勤務中の警察 %d 人 → AI出動倍率 %.2f'):format(count, factor))
    end
end

exports('GetPoliceFactor', function() return lastFactor end)
exports('GetPoliceCount',  CountPolice)

AddEventHandler('QBCore:Server:PlayerLoaded',  function() SetTimeout(1000, BroadcastFactor) end)
AddEventHandler('QBCore:Server:OnJobUpdate',   function() SetTimeout(500,  BroadcastFactor) end)
AddEventHandler('playerDropped',               function() SetTimeout(500,  BroadcastFactor) end)
RegisterNetEvent('QBCore:ToggleDuty',          function() SetTimeout(500,  BroadcastFactor) end)

-- 保険: 60秒ごとに再計算(イベントを取りこぼしても必ず追いつく)
CreateThread(function()
    Wait(10000)
    BroadcastFactor(true)
    while true do
        Wait(60000)
        BroadcastFactor(false)
    end
end)

-- 新しく入ってきたプレイヤーへ現在値を配る
AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(15000, function()
        if GetPlayerName(src) and lastFactor then
            TriggerClientEvent('m6_crime:client:policeFactor', src, lastFactor)
        end
    end)
end)

-- ════════════════════════════════════════════════════════════════
-- 参照用 export(将来の捜査・前科システム向け)
-- ════════════════════════════════════════════════════════════════

exports('GetIncidents', function(citizenid, status, limit)
    if not dbReady or not citizenid then return {} end
    return MySQL.query.await([[
        SELECT * FROM m6_crime_incidents
        WHERE citizenid = ? AND (? IS NULL OR status = ?)
        ORDER BY created_at DESC LIMIT ?
    ]], { citizenid, status, status, limit or 50 })
end)

exports('GetOpenIncidentCount', function(citizenid)
    if not dbReady or not citizenid then return 0 end
    local res = MySQL.scalar.await([[
        SELECT COUNT(*) FROM m6_crime_incidents WHERE citizenid = ? AND status = 'open'
    ]], { citizenid })
    return res or 0
end)

-- ════════════════════════════════════════════════════════════════
-- 管理用コマンド
-- ════════════════════════════════════════════════════════════════

lib.addCommand('m6crimes', {
    help = '対象の未解決事件を表示',
    params = { { name = 'target', type = 'playerId' } },
    restricted = 'group.admin'
}, function(source, args)
    local citizenid = GetCitizenId(args.target)
    if not citizenid then return end
    local rows = exports['m6_crime']:GetIncidents(citizenid, 'open', 20)
    lib.notify(source, {
        type = 'inform', duration = 8000,
        description = ('未解決事件: %d 件 (%s)'):format(rows and #rows or 0, citizenid)
    })
    for _, r in ipairs(rows or {}) do
        print(('[m6_crime] #%d %s %s 発生=%s 時効=%s'):format(
            r.id, r.crime_type, r.label or '', tostring(r.created_at), tostring(r.expires_at)))
    end
end)

lib.addCommand('m6police', { help = '現在の警察人数とAI倍率を表示', restricted = 'group.admin' },
function(source)
    lib.notify(source, {
        type = 'inform',
        description = ('勤務中の警察 %d 人 / AI倍率 %.2f'):format(CountPolice(), lastFactor or 1.0)
    })
end)
