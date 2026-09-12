-- ao_prisonwork / client/main.lua
--
-- qb-prison の刑務作業を置き換えるクライアント側。
--
-- qb-prison 本体には触れていない部分が多いので、依存の形をここに明記しておく:
--   ・収監状態は qb-prison が公開する export('IsInJail') / export('GetJailTime') を読む
--   ・減刑・刑期延長は qb-prison の
--       prison:client:ReduceJailTime / prison:client:AddJailTime
--     を叩く(どちらも qb-prison 側に追加したフック)
--   ・qb-prison の jailTime はクライアントのグローバル変数で、毎分のカウントダウン
--     スレッドが metadata を上書きする。外部リソースから metadata だけ書き換えても
--     最大60秒で巻き戻るため、必ず上記イベント経由で操作すること。

local running   = false
local jobState  = {}   -- [jobIndex] = { locIndex, blip, point, busy }
local lastPunish = {}  -- [kind] = GetGameTimer()
local marksOn   = false

-- ───────────────────────────────────────────────────────────
-- helpers
-- ───────────────────────────────────────────────────────────

local function IsInJail()
    local ok, res = pcall(function() return exports['qb-prison']:IsInJail() end)
    return ok and res == true
end

local function Notify(msg, kind)
    lib.notify({ type = kind or 'inform', description = msg })
end

local function PickNextLocation(job, current)
    local n = #job.locations
    if n <= 1 then return 1 end
    local nextIndex = math.random(1, n)
    local guard = 0
    while nextIndex == current and guard < 20 do
        nextIndex = math.random(1, n)
        guard = guard + 1
    end
    return nextIndex
end

-- ───────────────────────────────────────────────────────────
-- 作業本体
-- ───────────────────────────────────────────────────────────

local function DoWork(jobIndex)
    local job   = Config.Jobs[jobIndex]
    local state = jobState[jobIndex]
    if not job or not state or state.busy then return end
    if not IsInJail() then return end

    state.busy = true
    lib.hideTextUI()

    local duration = math.random(job.duration[1], job.duration[2])

    local opts = {
        duration = duration,
        label    = job.label .. '中...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = job.anim.dict, clip = job.anim.clip, flag = job.anim.flag },
    }
    if job.prop then
        opts.prop = {
            model = job.prop.model,
            bone  = job.prop.bone,
            pos   = job.prop.pos,
            rot   = job.prop.rot,
        }
    end

    local finished = lib.progressBar(opts)

    ClearPedTasks(cache.ped)
    state.busy = false

    if not finished then
        Notify('作業を中断した', 'error')
        return
    end

    -- 減刑抽選(職種ごとに確率と幅が違う)
    if math.random(100) <= job.reduce.chance then
        local cut = math.random(job.reduce.min, job.reduce.max)
        TriggerEvent('prison:client:ReduceJailTime', cut)
    end

    -- 素材と賃金はサーバー側で付与する
    TriggerServerEvent('ao_prisonwork:server:WorkDone', job.id)

    -- 次の作業地点へ
    state.locIndex = PickNextLocation(job, state.locIndex)
    ao_RefreshJobPoint(jobIndex)
end

-- ───────────────────────────────────────────────────────────
-- 作業地点(ox_lib points)とブリップ
-- ───────────────────────────────────────────────────────────

function ao_RefreshJobPoint(jobIndex)
    local job   = Config.Jobs[jobIndex]
    local state = jobState[jobIndex]
    if not job or not state then return end

    if state.point then
        state.point:remove()
        state.point = nil
    end
    if state.blip and DoesBlipExist(state.blip) then
        RemoveBlip(state.blip)
        state.blip = nil
    end
    if not running then return end

    local coords = job.locations[state.locIndex]
    if not coords then return end

    state.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(state.blip, 402)
    SetBlipDisplay(state.blip, 4)
    SetBlipScale(state.blip, 0.7)
    SetBlipAsShortRange(state.blip, true)
    SetBlipColour(state.blip, job.blipColour or 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(job.blipName)
    EndTextCommandSetBlipName(state.blip)

    local point = lib.points.new({ coords = coords, distance = 2.0 })

    function point:onEnter()
        if not state.busy and IsInJail() then
            lib.showTextUI(job.textui)
        end
    end

    function point:onExit()
        lib.hideTextUI()
    end

    function point:nearby()
        if state.busy or not IsInJail() then return end
        if IsControlJustReleased(0, 38) then
            DoWork(jobIndex)
        end
    end

    state.point = point
end

local function StartWork()
    if running then return end
    running = true
    for i, job in ipairs(Config.Jobs) do
        jobState[i] = { locIndex = math.random(1, #job.locations), blip = nil, point = nil, busy = false }
        ao_RefreshJobPoint(i)
    end

    local labels = {}
    for _, job in ipairs(Config.Jobs) do labels[#labels + 1] = job.label end
    Notify('刑務作業で減刑できる: ' .. table.concat(labels, ' / '), 'inform')
end

local function StopWork()
    running = false
    lib.hideTextUI()
    for i in pairs(jobState) do
        local state = jobState[i]
        if state.point then state.point:remove() end
        if state.blip and DoesBlipExist(state.blip) then RemoveBlip(state.blip) end
    end
    jobState = {}
end

-- 収監状態の監視。
-- qb-prison の退出経路が Leave / UnjailPerson / 脱獄 / ログアウトと複数あるため、
-- 個別のイベントを拾うのではなく状態をポーリングしている(2秒間隔)。
CreateThread(function()
    while true do
        Wait(2000)
        local jailed = IsInJail()
        if jailed and not running then
            StartWork()
        elseif not jailed and running then
            StopWork()
        end
    end
end)

-- ───────────────────────────────────────────────────────────
-- 所内犯罪のペナルティ(刑期延長)
-- ───────────────────────────────────────────────────────────
-- 手配レベルは付けない。rde_aipd_m6 の noWantedWhileJailed = true は変更していない。

local function IsGuardModel(ped)
    local model = GetEntityModel(ped)
    for _, hash in ipairs(Config.Punish.guardModels) do
        if model == hash then return true end
    end
    return false
end

local function Punish(kind, rule)
    if not rule or rule.units <= 0 then return end
    local now = GetGameTimer()
    if rule.cooldownMs > 0 and lastPunish[kind] and (now - lastPunish[kind]) < rule.cooldownMs then
        return
    end
    lastPunish[kind] = now
    TriggerEvent('prison:client:AddJailTime', rule.units)
    TriggerServerEvent('ao_prisonwork:server:LogPunish', kind, rule.units)
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if not Config.Punish.enabled then return end
    if not IsInJail() then return end

    local victim   = args[1]
    local attacker = args[2]
    local isFatal  = args[6]

    if attacker ~= cache.ped or victim == cache.ped then return end
    if not DoesEntityExist(victim) then return end

    local fatal = (isFatal == 1) or IsEntityDead(victim)

    if IsGuardModel(victim) then
        if fatal then
            Punish('guard_murder', Config.Punish.murder)
            Notify('刑務官を殺害した。刑期が大幅に延びた', 'error')
        else
            Punish('guard_assault', Config.Punish.assault)
            Notify('刑務官への暴行。刑期が延びた', 'error')
        end
        return
    end

    if IsPedAPlayer(victim) then
        if fatal and Config.Punish.inmateMurder.enabled then
            Punish('inmate_murder', Config.Punish.inmateMurder)
            Notify('所内で受刑者を殺害した。刑期が大幅に延びた', 'error')
        elseif (not fatal) and Config.Punish.inmateAssault.enabled then
            Punish('inmate_assault', Config.Punish.inmateAssault)
            Notify('所内での暴行。刑期が延びた', 'error')
        end
    end
end)

-- ───────────────────────────────────────────────────────────
-- 座標確認コマンド(実機で一度だけ歩いて確認するためのもの)
-- ───────────────────────────────────────────────────────────
-- 本番の挙動には一切影響しない。Config.MarkCommand = true のときだけ登録される。

if Config.MarkCommand then
    RegisterCommand('prisonwork_marks', function()
        marksOn = not marksOn
        Notify(marksOn and '作業地点マーカー: ON' or '作業地点マーカー: OFF', 'inform')
    end, false)

    CreateThread(function()
        while true do
            if marksOn then
                local marks = {}
                for _, job in ipairs(Config.Jobs) do
                    for i, c in ipairs(job.locations) do
                        marks[#marks + 1] = { coords = c, label = ('%s #%d'):format(job.id, i) }
                    end
                end
                if Config.CraftingBench then
                    marks[#marks + 1] = { coords = Config.CraftingBench, label = 'crafting bench' }
                end
                do
                    for _, m in ipairs(marks) do
                        local c = m.coords
                        DrawMarker(1, c.x, c.y, c.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            0.6, 0.6, 0.4, 120, 180, 255, 120, false, false, 2, false, nil, nil, false)
                        if #(GetEntityCoords(cache.ped) - c) < 12.0 then
                            local onScreen, sx, sy = World3dToScreen2d(c.x, c.y, c.z + 0.6)
                            if onScreen then
                                SetTextScale(0.3, 0.3)
                                SetTextFont(4)
                                SetTextCentre(true)
                                SetTextColour(255, 255, 255, 220)
                                BeginTextCommandDisplayText('STRING')
                                AddTextComponentSubstringPlayerName(m.label)
                                EndTextCommandDisplayText(sx, sy)
                            end
                        end
                    end
                end
                Wait(0)
            else
                Wait(500)
            end
        end
    end)
end
