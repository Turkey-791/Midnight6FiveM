-- ao_prisonwork / server/main.lua
--
-- 刑務作業の報酬(素材・賃金)の付与と、所内犯罪ログ。
--
-- 刑期そのものは qb-prison のクライアント側グローバル変数で管理されているため、
-- ここでは触らない(触っても毎分のカウントダウンスレッドに上書きされる)。
-- 刑期の増減は必ずクライアントの
--   prison:client:ReduceJailTime / prison:client:AddJailTime
-- を経由すること。

local QBCore = exports['qb-core']:GetCoreObject()

-- 収監1回につきスマホを1個までにするためのフラグ
local phoneGiven = {}

local function Debug(...)
    if Config.Debug then
        print('^3[ao_prisonwork]^7 ' .. string.format(...))
    end
end

local function GetJob(jobId)
    for _, job in ipairs(Config.Jobs) do
        if job.id == jobId then return job end
    end
    return nil
end

local function IsJailed(Player)
    return (tonumber(Player.PlayerData.metadata['injail']) or 0) > 0
end

-- 作業完了。素材と賃金をここで付与する。
RegisterNetEvent('ao_prisonwork:server:WorkDone', function(jobId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = GetJob(jobId)
    if not job then
        Debug('未知の job id: %s (src=%d)', tostring(jobId), src)
        return
    end

    -- 収監中でなければ何も渡さない
    if not IsJailed(Player) then
        Debug('収監中でないため報酬なし: src=%d job=%s', src, jobId)
        return
    end

    -- 素材
    if job.material and job.material.chance and job.material.chance > 0 then
        if math.random(100) <= job.material.chance then
            local entry = Config.Materials[math.random(1, #Config.Materials)]
            if entry then
                local amount = math.random(entry.min, entry.max)
                exports.ox_inventory:AddItem(src, entry.item, amount)
                Debug('素材付与: src=%d %s x%d', src, entry.item, amount)
            end
        end
    end

    -- 賃金(既定は 0 = 無効。犯罪収益設計と突き合わせるまで支給しない)
    if job.pay and job.pay > 0 then
        Player.Functions.AddMoney('cash', job.pay, 'ao_prisonwork:' .. jobId)
    end

    -- スマホ(収監1回につき1個まで)
    if (Config.PhoneChance or 0) > 0 and not phoneGiven[src] then
        if math.random(100) <= Config.PhoneChance then
            if exports.ox_inventory:AddItem(src, Config.PhoneItem or 'phone', 1) then
                phoneGiven[src] = true
                Debug('スマホ付与: src=%d', src)
            end
        end
    end
end)

-- 出所・切断でスマホのフラグを戻す
AddEventHandler('playerDropped', function()
    phoneGiven[source] = nil
end)

RegisterNetEvent('prison:server:SetJailStatus', function(jailTime)
    if (tonumber(jailTime) or 0) <= 0 then
        phoneGiven[source] = nil
    end
end)

-- 所内犯罪のログ。刑期の加算はクライアント側で済んでいるので、ここは記録だけ。
RegisterNetEvent('ao_prisonwork:server:LogPunish', function(kind, units)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not IsJailed(Player) then return end

    print(('^1[ao_prisonwork]^7 所内犯罪: %s (%s) → 刑期 +%s')
        :format(GetPlayerName(src) or src, tostring(kind), tostring(units)))
end)

-- ───────────────────────────────────────────────────────────
-- 座標採取(/prisonwork_here)
-- ───────────────────────────────────────────────────────────
-- 実機で良い位置に立って /prisonwork_here cook のように実行すると、
-- リソース直下の captured_coords.txt に追記される。
-- 本番の挙動には影響しない。採取が終わったらファイルごと消してよい。

RegisterNetEvent('ao_prisonwork:server:CaptureCoord', function(jobId, x, y, z, h)
    local src = source
    if not Config.MarkCommand then return end

    local name = 'captured_coords.txt'
    local old = LoadResourceFile(GetCurrentResourceName(), name) or
        '-- ao_prisonwork 座標採取ログ\n-- config.lua の locations にそのまま貼れる形式\n'
    local line = ('            vec3(%.2f, %.2f, %.2f),   -- %s  (heading %.1f / by %s / %s)\n')
        :format(x, y, z, jobId, h, GetPlayerName(src) or src, os.date('%Y-%m-%d %H:%M:%S'))
    SaveResourceFile(GetCurrentResourceName(), name, old .. line, -1)
    print(('^2[ao_prisonwork]^7 座標を記録: %s vec3(%.2f, %.2f, %.2f)'):format(jobId, x, y, z))
end)
