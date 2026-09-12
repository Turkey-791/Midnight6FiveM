-- ao_clothing / client/casino_ped.lua
-- カジノ内のブティック(試着室があるエリア)のレジに立つ店員PEDを出す。
--
-- なぜ ao_clothing が出すのか:
--   illenium-appearance にも店舗PEDを出す仕組みはある (client/target/target.lua の
--   CreatePedAtCoords) が、あれは Config.UseTarget = true のときだけ読み込まれる。
--   UseTarget を true にすると全30店舗が ALT照準方式に変わってしまうので採用しない。
--   v3_casino に足す手もあるが、服屋の都合で他リソースを増改築したくないため
--   ao_clothing 側に閉じ込める。
--
-- このPEDはあくまで「ここが服屋だ」という目印で、当たり判定も会話もつけていない。
-- 買う操作は illenium 側の [E] ゾーン (shared/config.lua の Config.Stores[16]) にあり、
-- そのゾーンの中心をこのPEDと同じ座標にしてあるので、プレイヤーから見ると
-- 「店員のところまで行って [E] で買う」という動きになる。

local spawnedPed = nil

local function spawnCasinoShopPed()
    local cfg = Config.CasinoShopPed
    if not cfg or not cfg.enabled then return end

    local model = cfg.model
    if type(model) == 'string' then model = joaat(model) end

    if not IsModelInCdimage(model) or not IsModelValid(model) then
        print(('[ao_clothing] PEDモデル %s が見つからないので、カジノ店員は出しません')
            :format(tostring(cfg.model)))
        return
    end

    RequestModel(model)
    local waited = 0
    while not HasModelLoaded(model) do
        Wait(50)
        waited = waited + 50
        if waited >= 10000 then
            print(('[ao_clothing] PEDモデル %s の読み込みが10秒で終わらなかったので、カジノ店員は出しません')
                :format(tostring(cfg.model)))
            return
        end
    end

    local c = cfg.coords
    -- z - 1.0 の理由:
    --   実機で測った座標はプレイヤーの中心の高さ。CreatePed も中心指定なので、
    --   測った値をそのまま渡すと1mほど宙に浮く。
    --   v3_casino が売り子PEDに使っている minusOne = true (qb-target/peds.lua で z-1.0)
    --   と同じ補正で、同じ床 (z=-49.44) で実績のある値。
    local ped = CreatePed(0, model, c.x, c.y, c.z - 1.0, c.w, false, false)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(ped) then
        print('[ao_clothing] カジノ店員PEDの生成に失敗しました')
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedCanPlayAmbientAnims(ped, true)
    if cfg.scenario then
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    end

    spawnedPed = ped
end

CreateThread(function()
    -- セッション開始前に CreatePed すると失敗することがあるので待つ。
    -- 待ちきれなくても最後は一度だけ試す (無限ループにはしない)。
    local waited = 0
    while not NetworkIsSessionStarted() and waited < 30000 do
        Wait(500)
        waited = waited + 500
    end
    Wait(1000)
    spawnCasinoShopPed()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if spawnedPed and DoesEntityExist(spawnedPed) then
        DeletePed(spawnedPed)
    end
    spawnedPed = nil
end)
