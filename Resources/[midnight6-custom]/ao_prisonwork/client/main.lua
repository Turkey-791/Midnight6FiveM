-- ao_prisonwork / client/main.lua
--
-- qb-prison の刑務作業を置き換えるクライアント側。
--
-- qb-prison との連携:
--   ・収監判定 … qb-prison の export('IsInJail') を使う。
--                 export が無い場合は qb-core の metadata['injail'] にフォールバックする
--                 (qb-prison の更新をデプロイし忘れても作業自体は動くようにするため)
--   ・減刑/延長 … qb-prison に追加したフック
--                   prison:client:ReduceJailTime / prison:client:AddJailTime
--                 を叩く。こちらは代替手段が無い。
--                 qb-prison の jailTime はクライアントのグローバル変数で、毎分の
--                 カウントダウンスレッドが metadata を上書きするため、外部から
--                 metadata だけ書き換えても最大60秒で巻き戻るため。
--
--   → フックが無い状態で起動した場合は、コンソールとチャットに警告を出す。
--     黙って何も起きない状態にはしない。

local QBCore = exports['qb-core']:GetCoreObject()

local running    = false
local jobState   = {}   -- [jobIndex] = { locIndex, blip, point, busy }
local lastPunish = {}   -- [kind] = GetGameTimer()
local marksOn    = false
local hooksOk    = nil  -- qb-prison 側のフックが存在するか(起動時に判定)

-- ───────────────────────────────────────────────────────────
-- helpers
-- ───────────────────────────────────────────────────────────

--- qb-prison の export が生きているか
local function HasPrisonExport()
    local ok = pcall(function() return exports['qb-prison']:IsInJail() end)
    return ok
end

--- 収監中か。qb-prison の export を優先し、無ければ metadata を読む
local function IsInJail()
    local ok, res = pcall(function() return exports['qb-prison']:IsInJail() end)
    if ok then return res == true end

    local pd = QBCore.Functions.GetPlayerData()
    return pd and pd.metadata and (tonumber(pd.metadata['injail']) or 0) > 0
end

--- 残り刑期(単位)。取れなければ metadata から
local function GetJailTime()
    local ok, res = pcall(function() return exports['qb-prison']:GetJailTime() end)
    if ok then return tonumber(res) or 0 end

    local pd = QBCore.Functions.GetPlayerData()
    return pd and pd.metadata and (tonumber(pd.metadata['injail']) or 0) or 0
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
-- 起動時セルフチェック
-- ───────────────────────────────────────────────────────────
-- qb-prison の更新が実機に反映されていない場合、以前は「マーカーは見えるが
-- 何も起きない」という無言の失敗になっていた。ここで必ず気づけるようにする。

CreateThread(function()
    Wait(5000)
    hooksOk = HasPrisonExport()
    if hooksOk then
        print('^2[ao_prisonwork]^7 qb-prison のフックを確認しました。')
    else
        print('^1[ao_prisonwork] qb-prison の export(IsInJail/GetJailTime) が見つかりません。^7')
        print('^1  → qb-prison の fxmanifest.lua と client/main.lua が実機に反映されていない可能性があります。^7')
        print('^1  → 減刑と刑期延長は動作しません(収監判定は metadata にフォールバックします)。^7')
        TriggerEvent('chat:addMessage', {
            color = { 255, 80, 80 },
            multiline = true,
            args = { 'ao_prisonwork', 'qb-prison のフックが見つかりません。減刑と刑期延長は動きません(qb-prison の更新が未反映の可能性)。' }
        })
    end
end)

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
        duration     = duration,
        label        = job.label .. '中...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = job.anim.dict, clip = job.anim.clip, flag = job.anim.flag },
    }
    if job.prop then
        opts.prop = { model = job.prop.model, bone = job.prop.bone, pos = job.prop.pos, rot = job.prop.rot }
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
        if hooksOk == false then
            Notify('減刑の処理ができない(qb-prison の更新が未反映)', 'error')
        else
            TriggerEvent('prison:client:ReduceJailTime', cut)
        end
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

    local point = lib.points.new({ coords = coords, distance = 2.5 })

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

-- ───────────────────────────────────────────────────────────
-- 作業地点のワールドマーカー
-- ───────────────────────────────────────────────────────────
-- ブリップだけだと、建物の中や他のブリップ(独房・受付)と重なったときに
-- どこへ行けばいいのか分からない。実際に地面へマーカーを出す。
--
-- 文字は SetTextFont(1) を使う。font 4 では日本語が豆腐(□□□□)になることが
-- 2026-09-09 の実機確認で確定しているため([[midnight6-jp-tofu-audit]])。

CreateThread(function()
    while true do
        local sleep = 500
        if running then
            local pcoords = GetEntityCoords(cache.ped)
            for i, job in ipairs(Config.Jobs) do
                local state = jobState[i]
                if state and not state.busy then
                    local c = job.locations[state.locIndex]
                    if c then
                        local dist = #(pcoords - c)
                        if dist < Config.MarkerDistance then
                            sleep = 0
                            local col = job.markerColour or { 120, 180, 255 }
                            DrawMarker(1, c.x, c.y, c.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                0.7, 0.7, 0.5, col[1], col[2], col[3], 110,
                                false, false, 2, false, nil, nil, false)
                            if dist < 15.0 then
                                local onScreen, sx, sy = World3dToScreen2d(c.x, c.y, c.z + 0.8)
                                if onScreen then
                                    SetTextScale(0.32, 0.32)
                                    SetTextFont(1)
                                    SetTextCentre(true)
                                    SetTextColour(255, 255, 255, 215)
                                    SetTextOutline()
                                    BeginTextCommandDisplayText('STRING')
                                    AddTextComponentSubstringPlayerName(job.label)
                                    EndTextCommandDisplayText(sx, sy)
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

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
    if hooksOk == false then
        Notify('刑期を延長できない(qb-prison の更新が未反映)', 'error')
        return
    end
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

    -- 未知のモデルを殴ったときに、その場でモデル名を出せるようにしておく
    -- (看守 ped のモデルを実機で特定するため。Config.MarkCommand のときだけ)
    if Config.MarkCommand and not IsPedAPlayer(victim) then
        print(('^3[ao_prisonwork]^7 殴った ped model = %s (看守判定=%s)')
            :format(GetEntityModel(victim), tostring(IsGuardModel(victim))))
    end

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
-- 残り刑期の確認(誰でも使える)
-- ───────────────────────────────────────────────────────────
-- qb-prison は刑期が 0 になっても自動では出所せず、面会所(受付)の NPC で
-- チェックアウトする必要がある。それが分かりにくいのでコマンドを足しておく。

RegisterCommand('prisontime', function()
    if not IsInJail() then
        Notify('収監されていない', 'inform')
        return
    end
    local t = GetJailTime()
    if t > 0 then
        Notify(('残りの刑期: %d(1 ≒ 実時間1分)'):format(t), 'inform')
    else
        Notify('刑期は終了している。面会所(受付)の職員でチェックアウトすること', 'success')
    end
end, false)

-- ───────────────────────────────────────────────────────────
-- 実機確認用コマンド(Config.MarkCommand = true のときだけ登録)
-- ───────────────────────────────────────────────────────────
-- どれも実行した本人にしか影響せず、ゲームの挙動は変えない。
-- 確認が終わったら Config.MarkCommand = false に戻すこと。

if Config.MarkCommand then

    -- /prisonwork_status … 連携状態を1画面で確認する
    RegisterCommand('prisonwork_status', function()
        local pd = QBCore.Functions.GetPlayerData()
        local meta = pd and pd.metadata and pd.metadata['injail'] or 'nil'
        local pts = 0
        for _, s in pairs(jobState) do if s.point then pts = pts + 1 end end
        local msg = ('qb-prison export=%s | metadata.injail=%s | IsInJail=%s | 作業中=%s | ポイント数=%d')
            :format(tostring(HasPrisonExport()), tostring(meta), tostring(IsInJail()), tostring(running), pts)
        print('^3[ao_prisonwork]^7 ' .. msg)
        lib.notify({ type = 'inform', duration = 12000, description = msg })
    end, false)

    -- /prisonwork_ped … 目の前の ped のモデルを表示する(看守モデルの特定用)
    RegisterCommand('prisonwork_ped', function()
        local ped = cache.ped
        local coords = GetEntityCoords(ped)
        local found, best, bestDist = false, nil, 6.0
        for _, target in ipairs(GetGamePool('CPed')) do
            if target ~= ped and DoesEntityExist(target) and not IsPedAPlayer(target) then
                local d = #(GetEntityCoords(target) - coords)
                if d < bestDist then bestDist = d; best = target; found = true end
            end
        end

        if not found then
            Notify('近くに NPC がいない', 'error')
            return
        end
        local model = GetEntityModel(best)
        local msg = ('最寄りNPC: model=%s / pedType=%d / 距離=%.1fm / 看守判定=%s')
            :format(model, GetPedType(best), bestDist, tostring(IsGuardModel(best)))
        print('^3[ao_prisonwork]^7 ' .. msg)
        lib.notify({ type = 'inform', duration = 15000, description = msg })
    end, false)

    -- /prisonwork_here <job> … 今いる場所を作業地点の候補として記録する
    --   例: /prisonwork_here cook
    --   記録先: ao_prisonwork/captured_coords.txt (サーバー側に書き出す)
    RegisterCommand('prisonwork_here', function(_, args)
        local jobId = args[1]
        if not jobId then
            Notify('使い方: /prisonwork_here <janitor|cook|electrician>', 'error')
            return
        end
        local c = GetEntityCoords(cache.ped)
        local h = GetEntityHeading(cache.ped)
        TriggerServerEvent('ao_prisonwork:server:CaptureCoord', jobId, c.x, c.y, c.z, h)
        Notify(('記録: %s  vec3(%.2f, %.2f, %.2f)'):format(jobId, c.x, c.y, c.z), 'success')
    end, false)

    -- /prisonwork_marks … 設定済みの全地点にマーカーを出す
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
                Wait(0)
            else
                Wait(500)
            end
        end
    end)
end
