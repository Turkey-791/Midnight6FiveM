-- Variables

local alcoholCount = 0
local healing, parachuteEquipped = false, false
local currVest, currVestTexture = nil, nil

-- Functions
RegisterNetEvent('QBCore:Client:UpdateObject', function()
    QBCore = exports['qb-core']:GetCoreObject()
end)

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

local function equipParachuteAnim()
    loadAnimDict('clothingshirt')
    TaskPlayAnim(PlayerPedId(), 'clothingshirt', 'try_shirt_positive_d', 8.0, 1.0, -1, 49, 0, false, false, false)
end

local function healOxy()
    if healing then return end

    healing = true

    local count = 9
    while count > 0 do
        Wait(1000)
        count -= 1
        SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + 6)
    end
    healing = false
end

local function trevorEffect()
    StartScreenEffect('DrugsTrevorClownsFightIn', 3.0, 0)
    Wait(3000)
    StartScreenEffect('DrugsTrevorClownsFight', 3.0, 0)
    Wait(3000)
    StartScreenEffect('DrugsTrevorClownsFightOut', 3.0, 0)
    StopScreenEffect('DrugsTrevorClownsFight')
    StopScreenEffect('DrugsTrevorClownsFightIn')
    StopScreenEffect('DrugsTrevorClownsFightOut')
end

local function methBagEffect()
    local startStamina = 8
    trevorEffect()
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
    while startStamina > 0 do
        Wait(1000)
        if math.random(5, 100) < 10 then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        startStamina = startStamina - 1
        if math.random(5, 100) < 51 then
            trevorEffect()
        end
    end
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end

local function ecstasyEffect()
    local startStamina = 30
    SetFlash(0, 0, 500, 7000, 500)
    while startStamina > 0 do
        Wait(1000)
        startStamina -= 1
        RestorePlayerStamina(PlayerId(), 1.0)
        if math.random(1, 100) < 51 then
            SetFlash(0, 0, 500, 7000, 500)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
        end
    end
    if IsPedRunning(PlayerPedId()) then
        SetPedToRagdoll(PlayerPedId(), math.random(1000, 3000), math.random(1000, 3000), 3, false, false, false)
    end
end

local function alienEffect()
    StartScreenEffect('DrugsMichaelAliensFightIn', 3.0, 0)
    Wait(math.random(5000, 8000))
    StartScreenEffect('DrugsMichaelAliensFight', 3.0, 0)
    Wait(math.random(5000, 8000))
    StartScreenEffect('DrugsMichaelAliensFightOut', 3.0, 0)
    StopScreenEffect('DrugsMichaelAliensFightIn')
    StopScreenEffect('DrugsMichaelAliensFight')
    StopScreenEffect('DrugsMichaelAliensFightOut')
end

local function crackBaggyEffect()
    local startStamina = 8
    local ped = PlayerPedId()
    alienEffect()
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.3)
    while startStamina > 0 do
        Wait(1000)
        if math.random(1, 100) < 10 then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        startStamina -= 1
        if math.random(1, 100) < 60 and IsPedRunning(ped) then
            SetPedToRagdoll(ped, math.random(1000, 2000), math.random(1000, 2000), 3, false, false, false)
        end
        if math.random(1, 100) < 51 then
            alienEffect()
        end
    end
    if IsPedRunning(ped) then
        SetPedToRagdoll(ped, math.random(1000, 3000), math.random(1000, 3000), 3, false, false, false)
    end
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end

local function cokeBaggyEffect()
    local startStamina = 20
    local ped = PlayerPedId()
    alienEffect()
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.1)
    while startStamina > 0 do
        Wait(1000)
        if math.random(1, 100) < 20 then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        startStamina -= 1
        if math.random(1, 100) < 10 and IsPedRunning(ped) then
            SetPedToRagdoll(ped, math.random(1000, 3000), math.random(1000, 3000), 3, false, false, false)
        end
        if math.random(1, 300) < 10 then
            alienEffect()
            Wait(math.random(3000, 6000))
        end
    end
    if IsPedRunning(ped) then
        SetPedToRagdoll(ped, math.random(1000, 3000), math.random(1000, 3000), 3, false, false, false)
    end
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end

-- Events

RegisterNetEvent('consumables:client:Eat', function(itemName)
    QBCore.Functions.Progressbar('eat_something', Lang:t('consumables.eat_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'mp_player_inteat@burger',
        anim = 'mp_player_int_eat_burger',
        flags = 49
    }, {
        model = 'prop_cs_burger_01',
        bone = 60309,
        coords = vec3(0.0, 0.0, -0.02),
        rotation = vec3(30, 0.0, 0.0),
    }, {}, function() -- Done
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'remove')
        TriggerServerEvent('consumables:server:addHunger', QBCore.Functions.GetPlayerData().metadata.hunger + Config.Consumables.eat[itemName])
        TriggerServerEvent('hud:server:RelieveStress', math.random(2, 4))
    end)
end)

RegisterNetEvent('consumables:client:Drink', function(itemName)
    QBCore.Functions.Progressbar('drink_something', Lang:t('consumables.drink_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'mp_player_intdrink',
        anim = 'loop_bottle',
        flags = 49
    }, {
        model = 'vw_prop_casino_water_bottle_01a',
        bone = 60309,
        coords = vec3(0.0, 0.0, -0.05),
        rotation = vec3(0.0, 0.0, -40),
    }, {}, function() -- Done
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'remove')
        TriggerServerEvent('consumables:server:addThirst', QBCore.Functions.GetPlayerData().metadata.thirst + Config.Consumables.drink[itemName])
    end)
end)

RegisterNetEvent('consumables:client:DrinkAlcohol', function(itemName)
    QBCore.Functions.Progressbar('drink_alcohol', Lang:t('consumables.liqour_progress'), math.random(3000, 6000), false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'mp_player_intdrink',
        anim = 'loop_bottle',
        flags = 49
    }, {
        model = 'prop_cs_beer_bot_40oz',
        bone = 60309,
        coords = vec3(0.0, 0.0, -0.05),
        rotation = vec3(0.0, 0.0, -40),
    }, {}, function() -- Done
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'remove')
        TriggerServerEvent('consumables:server:drinkAlcohol', itemName)
        TriggerServerEvent('consumables:server:addThirst', QBCore.Functions.GetPlayerData().metadata.thirst + Config.Consumables.alcohol[itemName])
        TriggerServerEvent('hud:server:RelieveStress', math.random(2, 4))
        alcoholCount += 1
        AlcoholLoop()
        if alcoholCount > 1 and alcoholCount < 4 then
            TriggerEvent('evidence:client:SetStatus', 'alcohol', 200)
        elseif alcoholCount >= 4 then
            TriggerEvent('evidence:client:SetStatus', 'heavyalcohol', 200)
        end
    end, function() -- Cancel
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:Custom', function(itemName)
    QBCore.Functions.TriggerCallback('consumables:itemdata', function(data)
        QBCore.Functions.Progressbar('custom_consumable', data.progress.label, data.progress.time, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true
        }, {
            animDict = data.animation.animDict,
            anim = data.animation.anim,
            flags = data.animation.flags
        }, {
            model = data.prop.model,
            bone = data.prop.bone,
            coords = data.prop.coords,
            rotation = data.prop.rotation
        }, {}, function() -- Done
            ClearPedTasks(PlayerPedId())
            TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'remove')
            if data.replenish.type then
                TriggerServerEvent('consumables:server:add' .. data.replenish.type, QBCore.Functions.GetPlayerData().metadata[string.lower(data.replenish.type)] + data.replenish.replenish)
            end
            if data.replenish.isAlcohol then
                alcoholCount += 1
                AlcoholLoop()
                if alcoholCount > 1 and alcoholCount < 4 then
                    TriggerEvent('evidence:client:SetStatus', 'alcohol', 200)
                elseif alcoholCount >= 4 then
                    TriggerEvent('evidence:client:SetStatus', 'heavyalcohol', 200)
                end
            end
            if data.replenish.event then
                TriggerEvent(data.replenish.event)
            end
        end)
    end, itemName)
end)

RegisterNetEvent('consumables:client:Cokebaggy', function()
    local ped = PlayerPedId()
    QBCore.Functions.Progressbar('snort_coke', Lang:t('consumables.coke_progress'), math.random(5000, 8000), false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'switch@trevor@trev_smoking_meth',
        anim = 'trev_smoking_meth_loop',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(ped, 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        TriggerServerEvent('consumables:server:useCokeBaggy')
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['cokebaggy'], 'remove')
        TriggerEvent('evidence:client:SetStatus', 'widepupils', 200)
        cokeBaggyEffect()
    end, function() -- Cancel
        StopAnimTask(ped, 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:Crackbaggy', function()
    local ped = PlayerPedId()
    QBCore.Functions.Progressbar('snort_coke', Lang:t('consumables.crack_progress'), math.random(7000, 10000), false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'switch@trevor@trev_smoking_meth',
        anim = 'trev_smoking_meth_loop',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(ped, 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        TriggerServerEvent('consumables:server:useCrackBaggy')
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['crack_baggy'], 'remove')
        TriggerEvent('evidence:client:SetStatus', 'widepupils', 300)
        crackBaggyEffect()
    end, function() -- Cancel
        StopAnimTask(ped, 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:EcstasyBaggy', function()
    QBCore.Functions.Progressbar('use_ecstasy', Lang:t('consumables.ecstasy_progress'), 3000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'mp_suicide',
        anim = 'pill',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), 'mp_suicide', 'pill', 1.0)
        TriggerServerEvent('consumables:server:useXTCBaggy')
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['xtcbaggy'], 'remove')
        ecstasyEffect()
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), 'mp_suicide', 'pill', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:oxy', function()
    QBCore.Functions.Progressbar('use_oxy', Lang:t('consumables.healing_progress'), 2000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'mp_suicide',
        anim = 'pill',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), 'mp_suicide', 'pill', 1.0)
        TriggerServerEvent('consumables:server:useOxy')
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['oxy'], 'remove')
        ClearPedBloodDamage(PlayerPedId())
        healOxy()
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), 'mp_suicide', 'pill', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

RegisterNetEvent('consumables:client:meth', function()
    QBCore.Functions.Progressbar('snort_meth', Lang:t('consumables.meth_progress'), 1500, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'switch@trevor@trev_smoking_meth',
        anim = 'trev_smoking_meth_loop',
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        TriggerServerEvent('consumables:server:useMeth')
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['meth'], 'remove')
        TriggerEvent('evidence:client:SetStatus', 'widepupils', 300)
        TriggerEvent('evidence:client:SetStatus', 'agitated', 300)
        methBagEffect()
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), 'switch@trevor@trev_smoking_meth', 'trev_smoking_meth_loop', 1.0)
        QBCore.Functions.Notify(Lang:t('consumables.canceled'), 'error')
    end)
end)

-- 2026-09-06 AO依頼: 実機検証で「Prop(手元の見た目)が表示されず、煙も出ない」との
-- 報告を受け、一旦NPC使用中のシナリオ('WORLD_HUMAN_AA_SMOKE')に切り替えてPropは
-- 表示されるようになったが、そのシナリオでは「口元に持っていって吸う」という
-- 従来のAnimation動作が失われてしまうとの指摘があったため、動作(Animation)を
-- 元のAnimDict方式(timetable@gardener@smoking_joint / smoke_idle。実ファイルで存在
-- 確認済み・Jointで動作実績あり)に戻し、Propは引き続き手動でCreateObject/
-- AttachEntityToEntity(Progressbarのpropパラメータ経由)で装着する形にした。
-- Animation(TaskPlayAnim)とProp装着([standalone]/progressbar/client.luaの
-- StartActions内でそれぞれ独立したif分岐)は元々別経路のため、この2つは併用可能。
-- 2026-09-06 診断完了: 一時診断コマンド(/cigpropdebug, /cigtest_a〜i)による切り分けの結果、
-- 「AttachEntityToEntity自体・Bone・Offset・Rotationはすべて正常」で、原因は
-- ng_proc_cigarette01a/p_cs_joint_01というModel自体(Attach後、静止していると描画されない)
-- と判明。代替候補(prop_cs_ciggy_01系)も同様に描画不可だったため、既存アセットのみでの
-- 解消を断念し、AO判断により専用MOD(Prop/Particle)導入で対応する方針に変更した。
-- 診断用の一時コマンド群とDebugCheckSmokingPropヘルパーは検証完了につき削除済み。

-- ============================================================================
-- 2026-09-07 AO依頼: 喫煙時の煙(ptfx)。
-- Prop装着は [standalone]/progressbar 側が担当しているが、progressbarにptfxの機能は
-- 無いため、煙はこちら側でProgressbarの開始/終了/キャンセルに合わせて制御する。
-- 実装方式は jayz666/my-smoking と同じ asset 'core' / effect 'exp_grd_bzgas_smoke' で、
-- GTA V標準アセットのため追加のstreamファイルは不要。設定値は config.lua を参照。
-- ============================================================================

local smokeFx = nil

local function StopSmokeFx()
    if smokeFx then
        StopParticleFxLooped(smokeFx, false)
        smokeFx = nil
    end
end

local function StartSmokeFx()
    if not Config.SmokeFxEnable then return end
    StopSmokeFx()
    local ped = PlayerPedId()
    local asset = Config.SmokeFxAsset
    RequestNamedPtfxAsset(asset)
    local timeout = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(asset) and GetGameTimer() < timeout do Wait(10) end
    if not HasNamedPtfxAssetLoaded(asset) then
        print(('^1[smoke] ptfxアセット "%s" をロードできませんでした^7'):format(asset))
        return
    end
    UseParticleFxAsset(asset)
    local boneIndex = GetPedBoneIndex(ped, Config.SmokeFxBone)
    if Config.SmokeFxNetworked then
        smokeFx = StartNetworkedParticleFxLoopedOnEntityBone(
            Config.SmokeFxEffect, ped,
            Config.SmokeFxOffsetX, Config.SmokeFxOffsetY, Config.SmokeFxOffsetZ,
            Config.SmokeFxRotX, Config.SmokeFxRotY, Config.SmokeFxRotZ,
            boneIndex, Config.SmokeFxScale, false, false, false
        )
    else
        smokeFx = StartParticleFxLoopedOnEntityBone(
            Config.SmokeFxEffect, ped,
            Config.SmokeFxOffsetX, Config.SmokeFxOffsetY, Config.SmokeFxOffsetZ,
            Config.SmokeFxRotX, Config.SmokeFxRotY, Config.SmokeFxRotZ,
            boneIndex, Config.SmokeFxScale, false, false, false
        )
    end
end

-- 死亡時とresource停止時に煙が残らないようにする
AddEventHandler('baseevents:onPlayerDied', function() StopSmokeFx() end)
AddEventHandler('baseevents:onPlayerKilled', function() StopSmokeFx() end)
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then StopSmokeFx() end
end)

RegisterNetEvent('consumables:client:UseJoint', function()
    -- 2026-09-06 AO依頼: 喫煙Animationが表示されない不具合の修正(第1弾)。
    -- 従来はProgressbar完了後(onFinish内)でQBCore.Functions.PlayAnimを個別に呼んでいたが、
    -- この経路はDoesAnimDictExist等のチェックに失敗した場合サイレントに何も起きない上、
    -- Progressbar自体には空の animation={} を渡していたため、Progressbar表示中は
    -- 一切Animationが再生されない作りになっていた。Eat/Drinkと同じ
    -- 「Progressbarのanimation/propパラメータで演出する」方式に統一して解消した。
    --
    -- 2026-09-06 第2弾(シナリオ方式・撤回済み): 一時的にNPC使用中のシナリオ
    -- 'WORLD_HUMAN_AA_SMOKE'に切り替えてPropと煙は表示されるようになったが、
    -- 「口元に持っていって吸う」という従来の動作が失われるとの指摘を受け、
    -- 動作は元のAnimDict方式に戻した(下記参照)。Propは引き続き手動装着。
    StartSmokeFx()
    QBCore.Functions.Progressbar('smoke_joint', Lang:t('consumables.joint_progress'), 1500, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'timetable@gardener@smoking_joint',
        anim = 'smoke_idle',
        flags = 49,
    }, {
        -- 2026-09-07 暫定: タバコ(ng_proc_cigarette01a)で実機確定した値をそのまま流用。
        -- p_cs_joint_01 は形状が異なるため、この値が最適とは限らない。
        -- /cigadj model p_cs_joint_01 → /cigadj keys で別途詰めること(未検証)。
        model = 'p_cs_joint_01',
        bone = 28422,
        coords = vec3(0.080, 0.040, -0.060),
        rotation = vec3(0.0, 195.0, 260.0),
    }, {}, function() -- Done
        StopSmokeFx()
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['joint'], 'remove')
        TriggerEvent('evidence:client:SetStatus', 'weedsmell', 300)
        TriggerServerEvent('hud:server:RelieveStress', Config.RelieveWeedStress)
    end, function() -- Cancel
        StopSmokeFx()
    end)
end)

-- 2026-09-06 AO依頼: 市販タバコ・手巻きタバコ追加。
-- Animationは実ファイルで存在確認済みのJoint用timetable@gardener@smoking_joint/smoke_idle
-- を暫定的に流用(タバコ専用AnimDictは実ファイルから確認できず、未検証の名前を推測導入
-- するリスクを避けた)。喫煙Prop(ng_proc_cigarette01a)も実ファイルのentityhashesから
-- 存在確認済みのものを使用し、Progressbarのpropパラメータで手動装着している。
-- (2026-09-06: 一時的にNPC使用中のシナリオ'WORLD_HUMAN_AA_SMOKE'に切り替えたが、
--  「口元に持っていって吸う」動作が失われるとの指摘を受けて撤回し、AnimDict+手動Prop
--  方式に戻した。)
-- 3種の性能差はStress軽減量(config.lua)とProgressbarの持続時間(標準/短い)で表現している。
-- Stress軽減量・喫煙時間はConfig.RelieveCigaretteStress/RelieveHandrolledCigaretteStress/
-- SmokeCigaretteDuration/SmokeHandrolledDurationとして確定済み(config.lua参照、2026-09-06)。
-- 2026-09-06 追記: 公開されている喫煙系MOD2つ(jayz666/my-smoking、Lusty94/lusty94_smoking)を
-- 調査したところ、どちらもcigarette Propを bone=28422(pos/rot=0,0,0) にAttachしており、
-- これまで使っていたbone=60309とは異なることが判明。2つの独立した実装が一致して28422を
-- 使っていることから、60309がそもそも不適切なAttach先だった可能性が高いと判断し、
-- bone/coords/rotationをMOD側と同じ値(28422 / 0,0,0 / 0,0,0)に変更して実機再検証中。
-- これで表示されない場合は、引き続き専用MOD(Prop/Particle一式)導入で対応する。

RegisterNetEvent('consumables:client:OpenCigarettePack', function()
    TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['cigarette_pack'], 'remove')
    TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['cigarette'], 'add')
end)

-- 2026-09-06 AO依頼: Pattern A(シナリオでProp/煙生成→Animationだけ差し替え)は
-- 実機検証の結果不成立(シナリオ終了と同時にPropが消えることを確認済み)。
-- joint/handrolled_cigaretteと同じAnimDict+手動Prop方式に戻した(Prop表示問題については
-- 上記のジョイントブロックのコメント参照。MOD導入待ち)。
RegisterNetEvent('consumables:client:UseCigarette', function()
    StartSmokeFx()
    QBCore.Functions.Progressbar('smoke_cigarette', Lang:t('consumables.cigarette_progress'), Config.SmokeCigaretteDuration, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'timetable@gardener@smoking_joint',
        anim = 'smoke_idle',
        flags = 49,
    }, {
        -- 2026-09-07 実機で確定した装着値(AO測定)。
        -- 原因は「Propが手のメッシュに埋まっていた」ことで、Model・ネットワーク登録・
        -- Attach処理はいずれも正常だった。offsetを指先方向(+X)へ出して解消。
        model = 'ng_proc_cigarette01a',
        bone = 28422,
        coords = vec3(0.080, 0.040, -0.060),
        rotation = vec3(0.0, 195.0, 260.0),
    }, {}, function() -- Done
        StopSmokeFx()
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['cigarette'], 'remove')
        TriggerServerEvent('hud:server:RelieveStress', Config.RelieveCigaretteStress)
    end, function() -- Cancel
        StopSmokeFx()
    end)
end)

RegisterNetEvent('consumables:client:UseHandrolledCigarette', function()
    StartSmokeFx()
    QBCore.Functions.Progressbar('smoke_handrolled_cigarette', Lang:t('consumables.handrolled_cigarette_progress'), Config.SmokeHandrolledDuration, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'timetable@gardener@smoking_joint',
        anim = 'smoke_idle',
        flags = 49,
    }, {
        -- 2026-09-07 実機で確定した装着値(AO測定)。
        -- 原因は「Propが手のメッシュに埋まっていた」ことで、Model・ネットワーク登録・
        -- Attach処理はいずれも正常だった。offsetを指先方向(+X)へ出して解消。
        model = 'ng_proc_cigarette01a',
        bone = 28422,
        coords = vec3(0.080, 0.040, -0.060),
        rotation = vec3(0.0, 195.0, 260.0),
    }, {}, function() -- Done
        StopSmokeFx()
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['handrolled_cigarette'], 'remove')
        TriggerServerEvent('hud:server:RelieveStress', Config.RelieveHandrolledCigaretteStress)
    end, function() -- Cancel
        StopSmokeFx()
    end)
end)

RegisterNetEvent('consumables:client:UseParachute', function()
    equipParachuteAnim()
    QBCore.Functions.Progressbar('use_parachute', Lang:t('consumables.use_parachute_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        local ped = PlayerPedId()
        TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['parachute'], 'remove')
        GiveWeaponToPed(ped, `GADGET_PARACHUTE`, 1, false, false)
        local parachuteData = {
            outfitData = { ['bag'] = { item = 7, texture = 0 } } -- Adding Parachute Clothing
        }
        TriggerEvent('qb-clothing:client:loadOutfit', parachuteData)
        parachuteEquipped = true
        TaskPlayAnim(ped, 'clothingshirt', 'exit', 8.0, 1.0, -1, 49, 0, false, false, false)
    end)
end)

RegisterNetEvent('consumables:client:ResetParachute', function()
    if parachuteEquipped then
        equipParachuteAnim()
        QBCore.Functions.Progressbar('reset_parachute', Lang:t('consumables.pack_parachute_progress'), 40000, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            local ped = PlayerPedId()
            TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['parachute'], 'add')
            local parachuteResetData = {
                outfitData = { ['bag'] = { item = 0, texture = 0 } } -- Removing Parachute Clothing
            }
            TriggerEvent('qb-clothing:client:loadOutfit', parachuteResetData)
            TaskPlayAnim(ped, 'clothingshirt', 'exit', 8.0, 1.0, -1, 49, 0, false, false, false)
            TriggerServerEvent('consumables:server:AddParachute')
            parachuteEquipped = false
        end)
    else
        QBCore.Functions.Notify(Lang:t('consumables.no_parachute'), 'error')
    end
end)

RegisterNetEvent('consumables:client:UseArmor', function()
    if GetPedArmour(PlayerPedId()) >= 75 then
        QBCore.Functions.Notify(Lang:t('consumables.armor_full'), 'error')
        return
    end
    QBCore.Functions.Progressbar('use_armor', Lang:t('consumables.armor_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        TriggerServerEvent('consumables:server:useArmor')
    end)
end)

RegisterNetEvent('consumables:client:UseHeavyArmor', function()
    if GetPedArmour(PlayerPedId()) == 100 then
        QBCore.Functions.Notify(Lang:t('consumables.armor_full'), 'error')
        return
    end
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    QBCore.Functions.Progressbar('use_heavyarmor', Lang:t('consumables.heavy_armor_progress'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        if not Config.Disable.vestDrawable then
            if PlayerData.charinfo.gender == 0 then
                currVest = GetPedDrawableVariation(ped, 9)
                currVestTexture = GetPedTextureVariation(ped, 9)
                if GetPedDrawableVariation(ped, 9) == 7 then
                    SetPedComponentVariation(ped, 9, 19, GetPedTextureVariation(ped, 9), 2)
                else
                    SetPedComponentVariation(ped, 9, 5, 2, 2)
                end
            else
                currVest = GetPedDrawableVariation(ped, 30)
                currVestTexture = GetPedTextureVariation(ped, 30)
                SetPedComponentVariation(ped, 9, 30, 0, 2)
            end
        end
        TriggerServerEvent('consumables:server:useHeavyArmor')
    end)
end)

RegisterNetEvent('consumables:client:ResetArmor', function()
    local ped = PlayerPedId()
    if currVest ~= nil and currVestTexture ~= nil then
        QBCore.Functions.Progressbar('remove_armor', Lang:t('consumables.remove_armor_progress'), 2500, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            SetPedComponentVariation(ped, 9, currVest, currVestTexture, 2)
            SetPedArmour(ped, 0)
            TriggerEvent('qb-inventory:client:ItemBox', QBCore.Shared.Items['heavyarmor'], 'add')
            TriggerServerEvent('consumables:server:resetArmor')
        end)
    else
        QBCore.Functions.Notify(Lang:t('consumables.armor_empty'), 'error')
    end
end)

-- RegisterNetEvent('consumables:client:UseRedSmoke', function()
--     if parachuteEquipped then
--         local ped = PlayerPedId()
--         SetPlayerParachuteSmokeTrailColor(ped, 255, 0, 0)
--         SetPlayerCanLeaveParachuteSmokeTrail(ped, true)
--         TriggerEvent("qb-inventory:client:ItemBox", QBCore.Shared.Items["smoketrailred"], "remove")
--     else
--         QBCore.Functions.Notify("You need to have a paracute to activate smoke!", "error")
--     end
-- end)

--Threads
local looped = false
function AlcoholLoop()
    if not looped then
        looped = true
        CreateThread(function()
            while true do
                Wait(10)
                if alcoholCount > 0 then
                    Wait(1000 * 60 * 15)
                    alcoholCount -= 1
                else
                    looped = false
                    break
                end
            end
        end)
    end
end

-- Test J: Lusty94導入の事前検証(2026-09-07 AO指示)。
-- ox_lib(interface/client/progress.lua)のcreateProp関数を実ファイルで確認したところ、
-- CreateObjectをネットワーク登録なし(isNetwork/netMissionEntity/bScriptHostObj = false,false,false)の
-- ローカルObjectとして生成していることが判明した。これまでの/cigtest_*は全てtrue,true,true
-- (ネットワーク登録あり)だったため、この方式は未検証。
-- 目的1: ネットワーク登録なしのローカルObjectなら、静止時にも表示されるかを確認する。
-- 目的2: Jointの見た目Propとして p_cs_joint_02(Bone 28422)が実機で自然に見えるかを確認する。
-- 不自然な場合(手に持った位置/口元位置/回転/Animation中の見え方)は、通常タバコと同じ
-- prop_cs_ciggy_01に戻す方針(AO指示)。
-- Animationは現行のtimetable@gardener@smoking_joint/smoke_idle(flags=49、口元に持っていく
-- 動作を維持するため変更していない)をそのまま使用する。
RegisterCommand('cigtest_j', function()
    local ped = PlayerPedId()
    local hash = GetHashKey('p_cs_joint_02')
    if not IsModelValid(hash) then
        print('^1[cigtest_j] FAIL: IsModelValid=false (p_cs_joint_02が無効)^7')
        return
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(50) end
    if not HasModelLoaded(hash) then
        print('^1[cigtest_j] FAIL: HasModelLoaded=false^7')
        return
    end
    local pedCoords = GetEntityCoords(ped)
    -- ox_libのcreateProp関数と全く同じ生成方式(ネットワーク登録なしのローカルObject)。
    local obj = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
    if not DoesEntityExist(obj) then
        print('^1[cigtest_j] FAIL: CreateObject失敗^7')
        SetModelAsNoLongerNeeded(hash)
        return
    end
    local boneIndex = GetPedBoneIndex(ped, 28422)
    AttachEntityToEntity(
        obj, ped, boneIndex,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        true, true, false, true, 0, true
    )
    SetModelAsNoLongerNeeded(hash)
    print('^2[cigtest_j] p_cs_joint_02をBone 28422にAttach(ローカルObject方式)。^7')
    print('^3[cigtest_j] まず5秒間、静止したまま表示します。見えるか確認してください。^7')
    Wait(5000)
    print('^3[cigtest_j] 次にsmoke_idle Animationを再生します。口元への動き・見え方を確認してください。^7')
    loadAnimDict('timetable@gardener@smoking_joint')
    TaskPlayAnim(ped, 'timetable@gardener@smoking_joint', 'smoke_idle', 3.0, 3.0, -1, 49, 0, false, false, false)
    Wait(8000)
    ClearPedTasksImmediately(ped)
    if DoesEntityExist(obj) then
        DetachEntity(obj, true, true)
        DeleteObject(obj)
    end
    print('^3[cigtest_j] ===== END =====^7')
end, false)

-- Test K: 2026-09-07 AO指示により優先順位を再整理。今回の本題は「Lusty94のProp生成方式が
-- 現在のタバコProp非表示問題を解決できるか」であり、Jointの見た目選定(Test J)は副次課題。
-- Test Jとは別に、Lusty94が実際に使っているタバコ用Prop(prop_cs_ciggy_01)を対象に、
-- ox_lib(interface/client/progress.lua createProp)と全く同じ生成方式
-- (CreateObjectをネットワーク登録なし=false,false,falseで生成)・Bone28422で検証する。
-- これまでの/cigtest_*は全てtrue,true,true(ネットワーク登録あり)だったため、この方式は未検証。
RegisterCommand('cigtest_k', function()
    local ped = PlayerPedId()
    local hash = GetHashKey('prop_cs_ciggy_01')
    if not IsModelValid(hash) then
        print('^1[cigtest_k] FAIL: IsModelValid=false (prop_cs_ciggy_01が無効)^7')
        return
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(50) end
    if not HasModelLoaded(hash) then
        print('^1[cigtest_k] FAIL: HasModelLoaded=false^7')
        return
    end
    local pedCoords = GetEntityCoords(ped)
    -- ox_libのcreateProp関数と全く同じ生成方式(ネットワーク登録なしのローカルObject)。
    local obj = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
    if not DoesEntityExist(obj) then
        print('^1[cigtest_k] FAIL: CreateObject失敗^7')
        SetModelAsNoLongerNeeded(hash)
        return
    end
    local boneIndex = GetPedBoneIndex(ped, 28422)
    AttachEntityToEntity(
        obj, ped, boneIndex,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        true, true, false, true, 0, true
    )
    SetModelAsNoLongerNeeded(hash)
    print('^2[cigtest_k] prop_cs_ciggy_01をBone 28422にAttach(ox_libと同じローカルObject方式)。^7')
    print('^3[cigtest_k] まず5秒間、静止したまま表示します。見えるか確認してください(ここが最重要)。^7')
    Wait(5000)
    print('^3[cigtest_k] 次にsmoke_idle Animationを再生します。見え方を確認してください。^7')
    loadAnimDict('timetable@gardener@smoking_joint')
    TaskPlayAnim(ped, 'timetable@gardener@smoking_joint', 'smoke_idle', 3.0, 3.0, -1, 49, 0, false, false, false)
    Wait(8000)
    ClearPedTasksImmediately(ped)
    if DoesEntityExist(obj) then
        DetachEntity(obj, true, true)
        DeleteObject(obj)
    end
    print('^3[cigtest_k] ===== END =====^7')
end, false)

-- ============================================================================
-- 2026-09-07 AO指示: Prop装着位置(見え方)の調整用コマンド /cigadj
--
-- 実機で確定した事実:
--   ・Eat/Drink (bone 60309 / offset 0,0,-0.02 等 / prop_cs_burger_01) は静止時も正常表示
--   ・/cigtest_k (bone 28422 / offset 0,0,0 / prop_cs_ciggy_01 / ローカルObject) は静止時に非表示
--   → Attach処理も描画も機能している。「ネットワーク登録が原因」という仮説は否定済み。
--   → 残る差分は bone(60309 vs 28422) と offset/rotation がゼロかどうかの2点のみ。
--   → 「Propがpedのメッシュに埋まっている」方向を先に検証する。
--
-- GTA Vにはオブジェクトを拡大する安定したネイティブが無いため、「大きくして検証する」は
-- 同じbone・同じoffsetのまま大きいModelに差し替える(preset big)ことで代替する。
-- 埋まっているだけなら、大きいModelは必ずはみ出して見える。
--
-- Prop生成方式は /cigtest_k と同じローカルObject(false,false,false)で固定し、
-- bone / offset / rotation / model だけを変数にしている。
-- 数値が決まったら UseCigarette / UseHandrolledCigarette / UseJoint の prop パラメータへ反映する。
-- ゲームプレイ経路(消費イベント本体)には一切変更を加えていない。
-- ============================================================================

local adjProp = nil
local adjModel = 'prop_cs_ciggy_01'
local adjBone = 28422
local adjPos = { x = 0.0, y = 0.0, z = 0.0 }
local adjRot = { x = 0.0, y = 0.0, z = 0.0 }
local adjAnimOn = false

local function adjDelete()
    if adjProp and DoesEntityExist(adjProp) then
        DetachEntity(adjProp, true, true)
        DeleteObject(adjProp)
    end
    adjProp = nil
end

local function adjReport()
    local ped = PlayerPedId()
    if not adjProp or not DoesEntityExist(adjProp) then
        print('^1[cigadj] Propが存在しません^7')
        return
    end
    local pc = GetEntityCoords(adjProp)
    local bc = GetPedBoneCoords(ped, adjBone, 0.0, 0.0, 0.0)
    local dist = #(pc - bc)
    print('^5[cigadj] ---------------------------------------------^7')
    print(('^5[cigadj] model=%s  bone=%d^7'):format(adjModel, adjBone))
    print(('^5[cigadj] pos=(%.3f, %.3f, %.3f)  rot=(%.1f, %.1f, %.1f)^7'):format(adjPos.x, adjPos.y, adjPos.z, adjRot.x, adjRot.y, adjRot.z))
    print(('^5[cigadj] Prop座標   = %.3f, %.3f, %.3f^7'):format(pc.x, pc.y, pc.z))
    print(('^5[cigadj] Bone座標   = %.3f, %.3f, %.3f^7'):format(bc.x, bc.y, bc.z))
    print(('^5[cigadj] Bone-Prop距離 = %.4f m^7'):format(dist))
    print(('^5[cigadj] AttachedTo=%s  IsEntityVisible=%s  Alpha=%d^7'):format(tostring(GetEntityAttachedTo(adjProp)), tostring(IsEntityVisible(adjProp)), GetEntityAlpha(adjProp)))
    print('^2[cigadj] ↓ そのまま貼れる prop パラメータ ↓^7')
    print(('^2        model = \'%s\',^7'):format(adjModel))
    print(('^2        bone = %d,^7'):format(adjBone))
    print(('^2        coords = vec3(%.3f, %.3f, %.3f),^7'):format(adjPos.x, adjPos.y, adjPos.z))
    print(('^2        rotation = vec3(%.1f, %.1f, %.1f),^7'):format(adjRot.x, adjRot.y, adjRot.z))
    print('^5[cigadj] ---------------------------------------------^7')
end

local function adjSpawn()
    local ped = PlayerPedId()
    adjDelete()
    local hash = GetHashKey(adjModel)
    if not IsModelValid(hash) then
        print(('^1[cigadj] IsModelValid=false : %s^7'):format(adjModel))
        return
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(50) end
    if not HasModelLoaded(hash) then
        print(('^1[cigadj] HasModelLoaded=false : %s^7'):format(adjModel))
        return
    end
    local c = GetEntityCoords(ped)
    -- /cigtest_k と同じローカルObject方式に固定(ネットワーク登録なし)
    adjProp = CreateObject(hash, c.x, c.y, c.z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not DoesEntityExist(adjProp) then
        print('^1[cigadj] CreateObject失敗^7')
        adjProp = nil
        return
    end
    AttachEntityToEntity(
        adjProp, ped, GetPedBoneIndex(ped, adjBone),
        adjPos.x, adjPos.y, adjPos.z,
        adjRot.x, adjRot.y, adjRot.z,
        true, true, false, true, 0, true
    )
    Wait(50)
    adjReport()
end

-- ============================================================================
-- 2026-09-07 AO指示: offsetライブ調整モード /cigadj keys
--
-- 実機で確定した事実(2026-09-07):
--   ・bone 28422 / offset (0,0,0.5) / model ng_proc_cigarette01a → 表示される
--   → タバコModelのロードも描画も正常。「Modelが壊れている」説は否定。
--   ・bone 60309 / offset (0,0,-0.02) では同じModelが見えない
--   → 原因は「Propがpedのメッシュに埋まっている」で確定。
--   ハンバーガー(約15cm)はoffset 0でもはみ出すが、タバコ(数cm)は手の中に完全に収まる。
--
-- 残る作業は「見え始める最小のoffset」を探すことだけなので、
-- コマンドを打ち直さずキーでPropを動かせるモードを追加する。
-- Propは作り直さずAttachし直すだけなので、調整中に消えたり点滅したりしない。
--
-- 使い方:
--   /cigadj keys   モードON/OFF（トグル）
-- 操作:
--   ← →              X - / +
--   ↑ ↓              Y + / -
--   Q E              Z + / -
--   LEFT SHIFT 押しながら  同じキーで Rotation を調整
--   LEFT CTRL 押しながら   微調整 (0.001 / 1.0度)
-- 画面左上に現在値を常時表示し、変更のたびにF8へ貼り付け用コードを出力する。
-- ============================================================================

local adjKeyMode = false

local function adjReattach()
    if not adjProp or not DoesEntityExist(adjProp) then return end
    local ped = PlayerPedId()
    AttachEntityToEntity(
        adjProp, ped, GetPedBoneIndex(ped, adjBone),
        adjPos.x, adjPos.y, adjPos.z,
        adjRot.x, adjRot.y, adjRot.z,
        true, true, false, true, 0, true
    )
end

local function adjDrawLine(txt, y)
    SetTextFont(4)
    SetTextScale(0.34, 0.34)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(txt)
    DrawText(0.015, y)
end

local adjKeyList = { 44, 38, 172, 173, 174, 175, 21, 36 }

local function adjStartKeyMode()
    CreateThread(function()
        while adjKeyMode do
            Wait(0)
            for i = 1, #adjKeyList do
                DisableControlAction(0, adjKeyList[i], true)
            end

            local fine = IsDisabledControlPressed(0, 36)
            local rotMode = IsDisabledControlPressed(0, 21)
            local step = fine and 0.001 or 0.01
            local rstep = fine and 1.0 or 5.0
            local changed = false

            if rotMode then
                if IsDisabledControlJustPressed(0, 174) then adjRot.x = adjRot.x - rstep changed = true end
                if IsDisabledControlJustPressed(0, 175) then adjRot.x = adjRot.x + rstep changed = true end
                if IsDisabledControlJustPressed(0, 172) then adjRot.y = adjRot.y + rstep changed = true end
                if IsDisabledControlJustPressed(0, 173) then adjRot.y = adjRot.y - rstep changed = true end
                if IsDisabledControlJustPressed(0, 44) then adjRot.z = adjRot.z + rstep changed = true end
                if IsDisabledControlJustPressed(0, 38) then adjRot.z = adjRot.z - rstep changed = true end
            else
                if IsDisabledControlJustPressed(0, 174) then adjPos.x = adjPos.x - step changed = true end
                if IsDisabledControlJustPressed(0, 175) then adjPos.x = adjPos.x + step changed = true end
                if IsDisabledControlJustPressed(0, 172) then adjPos.y = adjPos.y + step changed = true end
                if IsDisabledControlJustPressed(0, 173) then adjPos.y = adjPos.y - step changed = true end
                if IsDisabledControlJustPressed(0, 44) then adjPos.z = adjPos.z + step changed = true end
                if IsDisabledControlJustPressed(0, 38) then adjPos.z = adjPos.z - step changed = true end
            end

            if changed then
                adjReattach()
                print(('^2[cigadj] model=\'%s\' bone=%d coords=vec3(%.3f, %.3f, %.3f) rotation=vec3(%.1f, %.1f, %.1f)^7'):format(
                    adjModel, adjBone, adjPos.x, adjPos.y, adjPos.z, adjRot.x, adjRot.y, adjRot.z))
            end

            adjDrawLine(('~y~[cigadj keys]~w~  model: %s   bone: %d'):format(adjModel, adjBone), 0.020)
            adjDrawLine(('coords = vec3(%.3f, %.3f, %.3f)'):format(adjPos.x, adjPos.y, adjPos.z), 0.048)
            adjDrawLine(('rotation = vec3(%.1f, %.1f, %.1f)'):format(adjRot.x, adjRot.y, adjRot.z), 0.076)
            adjDrawLine(('step: %s   mode: %s'):format(fine and '0.001 / 1deg' or '0.01 / 5deg', rotMode and '~g~ROTATION~w~' or 'POSITION'), 0.104)
            adjDrawLine('~b~<- ->~w~ X   ~b~up/down~w~ Y   ~b~Q/E~w~ Z   ~b~SHIFT~w~ rot   ~b~CTRL~w~ fine', 0.132)
        end
    end)
end

RegisterCommand('cigadj', function(_, args)
    local sub = args[1] and string.lower(args[1]) or nil

    if sub == 'off' then
        adjDelete()
        if adjAnimOn then
            ClearPedTasks(PlayerPedId())
            adjAnimOn = false
        end
        print('^3[cigadj] 削除しました^7')
        return
    end

    if sub == 'keys' then
        adjKeyMode = not adjKeyMode
        if adjKeyMode then
            if not adjProp or not DoesEntityExist(adjProp) then adjSpawn() end
            adjStartKeyMode()
            print('^2[cigadj] キー調整モード ON   <- -> : X / up down : Y / Q E : Z / SHIFT : rotation / CTRL : 微調整^7')
        else
            print('^3[cigadj] キー調整モード OFF^7')
            adjReport()
        end
        return
    end

    if sub == 'anim' then
        local ped = PlayerPedId()
        if adjAnimOn then
            ClearPedTasks(ped)
            adjAnimOn = false
            print('^3[cigadj] Animation停止^7')
        else
            loadAnimDict('timetable@gardener@smoking_joint')
            TaskPlayAnim(ped, 'timetable@gardener@smoking_joint', 'smoke_idle', 3.0, 3.0, -1, 49, 0, false, false, false)
            adjAnimOn = true
            print('^3[cigadj] Animation再生 (timetable@gardener@smoking_joint / smoke_idle / flags 49)^7')
        end
        return
    end

    if sub == 'model' then
        if not args[2] then
            print('^1[cigadj] 使い方: /cigadj model <モデル名>^7')
            return
        end
        adjModel = args[2]
        adjSpawn()
        return
    end

    if sub == 'preset' then
        local p = args[2] and string.lower(args[2]) or ''
        if p == 'food' then
            -- Eat(sandwich)と完全に同じ装着条件。Modelはそのまま
            adjBone = 60309
            adjPos = { x = 0.0, y = 0.0, z = -0.02 }
            adjRot = { x = 30.0, y = 0.0, z = 0.0 }
            print('^3[cigadj] preset food : bone=60309 / pos=0,0,-0.02 / rot=30,0,0^7')
        elseif p == 'big' then
            -- bone/offsetは現状のまま、Modelだけ大きいものへ差し替えて「埋まっているだけか」を判定
            adjModel = 'prop_cs_burger_01'
            print('^3[cigadj] preset big : model=prop_cs_burger_01 (bone/offsetは現状維持)^7')
        elseif p == 'cig' then
            adjModel = 'prop_cs_ciggy_01'
            adjBone = 28422
            adjPos = { x = 0.0, y = 0.0, z = 0.0 }
            adjRot = { x = 0.0, y = 0.0, z = 0.0 }
            print('^3[cigadj] preset cig : 現行のタバコ設定を再現^7')
        elseif p == 'air' then
            -- 現在のboneから50cm浮かせる。描画そのものが生きているかの判定用
            adjPos = { x = 0.0, y = 0.0, z = 0.5 }
            print('^3[cigadj] preset air : pos=0,0,0.5 (完全に空中)^7')
        else
            print('^1[cigadj] preset は food / big / cig / air のいずれか^7')
            return
        end
        adjSpawn()
        return
    end

    if args[7] then
        local n = {}
        for i = 1, 7 do
            n[i] = tonumber(args[i])
            if not n[i] then
                print(('^1[cigadj] 数値として解釈できません: 第%d引数 \'%s\'^7'):format(i, tostring(args[i])))
                return
            end
        end
        adjBone = math.floor(n[1])
        adjPos = { x = n[2] + 0.0, y = n[3] + 0.0, z = n[4] + 0.0 }
        adjRot = { x = n[5] + 0.0, y = n[6] + 0.0, z = n[7] + 0.0 }
        adjSpawn()
        return
    end

    if sub == nil then
        adjSpawn()
        return
    end

    print('^1[cigadj] 使い方:^7')
    print('^1  /cigadj                                  現在値で装着し直す^7')
    print('^1  /cigadj preset food|big|cig|air          プリセット^7')
    print('^1  /cigadj model <モデル名>                 Model切替^7')
    print('^1  /cigadj <bone> <x> <y> <z> <rx> <ry> <rz>  直接指定^7')
    print('^1  /cigadj anim                             smoke_idle 再生ON/OFF^7')
    print('^1  /cigadj off                              削除^7')
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        adjDelete()
    end
end)

-- ============================================================================
-- 2026-09-07 AO指示: Model総当たり検証コマンド /cigscan
--
-- 実機で確定した事実(2026-09-07):
--   ・bone 28422 / offset 0,0,0 でも prop_cs_burger_01 は見える
--   ・同じbone・同じoffset・同じコード経路のまま Model だけ ng_proc_cigarette01a に
--     差し替えると消える
--   → 「Propがpedのメッシュに埋まっている」説は否定。位置の問題ではない。
--   → 原因はタバコ系Model側にある。
--
-- ただし /cigadj は Model のロードに失敗すると adjDelete() 実行後に return するため、
-- 「ロード失敗」と「ロードは成功したが描画されない」が どちらも "消えた" に見える。
-- この2つを分離し、あわせて代替Model候補を一括で確認するためのコマンド。
--
-- 各Modelについて以下を出力/実施する:
--   1) IsModelValid
--   2) RequestModel → HasModelLoaded (最大3秒待ち)
--   3) GetModelDimensions (サイズが0なら描画実体が無い疑い)
--   4) 地面に設置して2.5秒表示   ← Model単体で描画されるか
--   5) 右手(bone 60309)にAttachして2.5秒表示 ← Attachすると消えるのか
--
-- 使い方:
--   /cigscan              候補Modelを順に総当たり(先頭は対照群のハンバーガー)
--   /cigscan <モデル名>   1つだけ検証
-- ============================================================================

local scanRunning = false

local scanModels = {
    'prop_cs_burger_01',      -- 対照群: 見えることが実機確認済み
    'prop_cs_ciggy_01',       -- Lusty94 / jayz666 が使用
    'prop_cs_ciggy_01b',
    'ng_proc_cigarette01a',   -- 現在のcigarette/handrolledで使用中
    'p_cs_joint_01',          -- 現在のjointで使用中
    'p_cs_joint_02',
    'prop_cigar_01',
    'prop_cigar_02',
    'prop_cigar_03',
    'ba_prop_battle_vape_01',
    'v_ret_ml_cigs',
    'v_ret_ml_cigs3',
}

local function scanOne(modelName)
    local ped = PlayerPedId()
    local hash = GetHashKey(modelName)
    print('^5[cigscan] =============================================^7')
    print(('^5[cigscan] Model: %s  (hash %d)^7'):format(modelName, hash))

    if not IsModelValid(hash) then
        print('^1[cigscan]   IsModelValid = false  → このビルドに存在しないModel^7')
        return false
    end
    print('^2[cigscan]   IsModelValid = true^7')

    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(50) end
    if not HasModelLoaded(hash) then
        print('^1[cigscan]   HasModelLoaded = false  → 3秒待ってもロードできない^7')
        return false
    end
    print('^2[cigscan]   HasModelLoaded = true^7')

    local mn, mx = GetModelDimensions(hash)
    local sz = mx - mn
    print(('^5[cigscan]   サイズ = %.4f x %.4f x %.4f (m)^7'):format(sz.x, sz.y, sz.z))
    if sz.x < 0.001 and sz.y < 0.001 and sz.z < 0.001 then
        print('^1[cigscan]   → サイズが0。描画実体が無い可能性が高い^7')
    end

    -- 4) 地面に設置して表示（Model単体で描画されるか）
    local fwd = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.2, 0.0)
    local ground = CreateObject(hash, fwd.x, fwd.y, fwd.z, false, false, false)
    if DoesEntityExist(ground) then
        PlaceObjectOnGroundProperly(ground)
        FreezeEntityPosition(ground, true)
        local gc = GetEntityCoords(ground)
        print(('^3[cigscan]   [A] 地面に設置中 (2.5秒) 座標 %.2f, %.2f, %.2f — 足元前方を見てください^7'):format(gc.x, gc.y, gc.z))
        print(('^3[cigscan]       IsEntityVisible=%s Alpha=%d^7'):format(tostring(IsEntityVisible(ground)), GetEntityAlpha(ground)))
        Wait(2500)
        DeleteObject(ground)
    else
        print('^1[cigscan]   [A] CreateObject失敗(地面)^7')
    end

    -- 5) 右手(bone 60309 = ハンバーガーで実績のあるbone)にAttachして表示
    local pc = GetEntityCoords(ped)
    local held = CreateObject(hash, pc.x, pc.y, pc.z, false, false, false)
    if DoesEntityExist(held) then
        AttachEntityToEntity(
            held, ped, GetPedBoneIndex(ped, 60309),
            0.0, 0.0, -0.02, 0.0, 0.0, 0.0,
            true, true, false, true, 0, true
        )
        Wait(100)
        local hc = GetEntityCoords(held)
        local bc = GetPedBoneCoords(ped, 60309, 0.0, 0.0, 0.0)
        print(('^3[cigscan]   [B] 右手にAttach中 (2.5秒) — 手元を見てください^7'))
        print(('^3[cigscan]       Prop=%.3f,%.3f,%.3f  Bone=%.3f,%.3f,%.3f  距離=%.4f^7'):format(hc.x, hc.y, hc.z, bc.x, bc.y, bc.z, #(hc - bc)))
        print(('^3[cigscan]       AttachedTo=%s IsEntityVisible=%s Alpha=%d^7'):format(tostring(GetEntityAttachedTo(held)), tostring(IsEntityVisible(held)), GetEntityAlpha(held)))
        Wait(2500)
        DetachEntity(held, true, true)
        DeleteObject(held)
    else
        print('^1[cigscan]   [B] CreateObject失敗(Attach)^7')
    end

    SetModelAsNoLongerNeeded(hash)
    return true
end

RegisterCommand('cigscan', function(_, args)
    if scanRunning then
        print('^1[cigscan] 実行中です^7')
        return
    end
    scanRunning = true
    print('^2[cigscan] ===== START =====^7')
    print('^2[cigscan] 各Modelにつき [A]地面2.5秒 → [B]右手2.5秒 の順に表示します^7')
    print('^2[cigscan] 三人称で、動かずに見てください^7')

    if args[1] then
        scanOne(args[1])
    else
        for i = 1, #scanModels do
            scanOne(scanModels[i])
            Wait(300)
        end
    end

    print('^2[cigscan] ===== END =====^7')
    print('^2[cigscan] 各Modelについて [A]見えた/見えない [B]見えた/見えない を教えてください^7')
    scanRunning = false
end, false)

-- ============================================================================
-- 2026-09-07 AO指示: Attach軸の方向特定コマンド /cigaxis
--
-- 実機で確定した事実(2026-09-07):
--   ・bone 28422 / offset (0,0,0.03) → タバコが「右手首」に埋まっている
--   ・bone 28422 / offset (0,0,0.5)  → 手の甲から約50cm離れて浮く
--     → 28422 の原点は右手首付近。+Z は手の甲から離れる方向で、指先方向ではない。
--   ・bone 60309 → 左手側に出る。+Z は尻方向。この ped では狙った手ではない。
--   → boneは 28422 が正解。残るは「手首から指先へ向かう軸」がX/Yのどちらの
--     どちら向きかを特定するだけ。
--
-- 現在のModel/Boneのまま、±X ±Y ±Z の6方向へ順に離して各3秒表示する。
-- どの方向が指先側かを目視で特定するためのコマンド。
--
-- 使い方:
--   /cigaxis                 現在のbone、距離0.15mで6方向を巡回
--   /cigaxis <bone>          boneを指定して巡回（例: /cigaxis 57005）
--   /cigaxis <bone> <距離>   距離も指定（例: /cigaxis 28422 0.08）
-- ============================================================================

local axisRunning = false

RegisterCommand('cigaxis', function(_, args)
    if axisRunning then
        print('^1[cigaxis] 実行中です^7')
        return
    end
    axisRunning = true

    if args[1] then
        local b = tonumber(args[1])
        if b then adjBone = math.floor(b) end
    end
    local d = tonumber(args[2]) or 0.15

    local dirs = {
        { name = '+X', p = {  d,  0.0, 0.0 } },
        { name = '-X', p = { -d,  0.0, 0.0 } },
        { name = '+Y', p = { 0.0,  d,  0.0 } },
        { name = '-Y', p = { 0.0, -d,  0.0 } },
        { name = '+Z', p = { 0.0, 0.0,  d  } },
        { name = '-Z', p = { 0.0, 0.0, -d  } },
    }

    print('^2[cigaxis] ===== START =====^7')
    print(('^2[cigaxis] model=%s  bone=%d  距離=%.2fm  各方向3秒^7'):format(adjModel, adjBone, d))
    print('^2[cigaxis] 「指先側へ伸びている方向」がどれかを見てください^7')

    for i = 1, #dirs do
        local dir = dirs[i]
        adjPos = { x = dir.p[1], y = dir.p[2], z = dir.p[3] }
        adjRot = { x = 0.0, y = 0.0, z = 0.0 }
        adjSpawn()
        print(('^3[cigaxis] ▶ %s  coords = vec3(%.3f, %.3f, %.3f)^7'):format(dir.name, adjPos.x, adjPos.y, adjPos.z))
        local until_ = GetGameTimer() + 3000
        while GetGameTimer() < until_ do
            Wait(0)
            adjDrawLine(('~y~[cigaxis]~w~  %s   bone %d   %.2fm'):format(dir.name, adjBone, d), 0.020)
            adjDrawLine(('coords = vec3(%.3f, %.3f, %.3f)'):format(adjPos.x, adjPos.y, adjPos.z), 0.048)
        end
    end

    print('^2[cigaxis] ===== END =====^7')
    print('^2[cigaxis] 指先側だった方向を教えてください。その軸を縮めて埋没しない最小値を出します^7')
    axisRunning = false
end, false)

-- ============================================================================
-- 2026-09-07 AO指示: offset最小値の測定コマンド /cigsweep
--
-- 実機で確定した事実(2026-09-07):
--   ・bone 28422 の +X が指先方向（/cigaxis 28422 0.15 で確認）
--   → 残るのは「手のメッシュから出る最小のX」を求めるだけ。
--
-- 指定軸に沿ってoffsetを段階的に動かし、各段階で一定時間止めて値を画面とF8に出す。
-- Propは作り直さずAttachし直すだけなので、途中で消えたり点滅したりしない。
--
-- 使い方:
--   /cigsweep                                   x軸を 0.00→0.15 / 0.01刻み / 各1.5秒
--   /cigsweep x 0.0 0.15 0.01 1500              軸 開始 終了 刻み 各段階のms
--   /cigsweep y -0.10 0.10 0.01                 負方向も可
-- ============================================================================

local sweepRunning = false

RegisterCommand('cigsweep', function(_, args)
    if sweepRunning then
        print('^1[cigsweep] 実行中です^7')
        return
    end
    sweepRunning = true

    local axis = args[1] and string.lower(args[1]) or 'x'
    if axis ~= 'x' and axis ~= 'y' and axis ~= 'z' then
        print('^1[cigsweep] 軸は x / y / z のいずれか^7')
        sweepRunning = false
        return
    end
    local from = tonumber(args[2]) or 0.0
    local to = tonumber(args[3]) or 0.15
    local step = tonumber(args[4]) or 0.01
    local hold = tonumber(args[5]) or 1500
    if step <= 0 then step = 0.01 end
    if to < from then step = -step end

    adjPos = { x = 0.0, y = 0.0, z = 0.0 }
    adjPos[axis] = from
    adjSpawn()

    print('^2[cigsweep] ===== START =====^7')
    print(('^2[cigsweep] model=%s bone=%d 軸=%s %.3f → %.3f 刻み%.3f 各%.1f秒^7'):format(adjModel, adjBone, axis, from, to, math.abs(step), hold / 1000))
    print('^2[cigsweep] 「見え始めた値」を控えてください^7')

    local v = from
    while (step > 0 and v <= to + 0.0001) or (step < 0 and v >= to - 0.0001) do
        adjPos = { x = 0.0, y = 0.0, z = 0.0 }
        adjPos[axis] = v
        adjReattach()
        print(('^3[cigsweep] %s = %.3f^7'):format(axis, v))
        local until_ = GetGameTimer() + hold
        while GetGameTimer() < until_ do
            Wait(0)
            adjDrawLine(('~y~[cigsweep]~w~  %s = ~g~%.3f~w~   bone %d   %s'):format(axis, v, adjBone, adjModel), 0.020)
            adjDrawLine(('coords = vec3(%.3f, %.3f, %.3f)'):format(adjPos.x, adjPos.y, adjPos.z), 0.048)
        end
        v = v + step
    end

    print('^2[cigsweep] ===== END =====^7')
    print('^2[cigsweep] 見え始めた値を教えてください。そこから rotation を合わせます^7')
    sweepRunning = false
end, false)

-- ============================================================================
-- 2026-09-07 AO依頼: 煙(ptfx)の調整用コマンド /cigsmoke
--
-- config.lua の Config.SmokeFx* を実機で書き換えながら見え方を確認するためのもの。
-- 値が決まったら config.lua に転記すること(このコマンドはメモリ上の値だけ変える)。
--
-- 使い方:
--   /cigsmoke                        現在の設定で10秒間 煙を出す
--   /cigsmoke <bone> <scale> [秒]    boneとscaleを変えて確認 (例: /cigsmoke 20279 0.2 10)
--   /cigsmoke off                    停止
--   /cigsmoke net                    ネットワーク版/ローカル版の切替
-- 参考bone: 31086 = 頭 / 20279 = 口元 (jayz666/my-smoking が使用)
-- ============================================================================

RegisterCommand('cigsmoke', function(_, args)
    local sub = args[1] and string.lower(args[1]) or nil

    if sub == 'off' then
        StopSmokeFx()
        print('^3[cigsmoke] 停止しました^7')
        return
    end

    if sub == 'net' then
        Config.SmokeFxNetworked = not Config.SmokeFxNetworked
        print(('^3[cigsmoke] SmokeFxNetworked = %s (次回の再生から反映)^7'):format(tostring(Config.SmokeFxNetworked)))
        return
    end

    local secs = 10
    if sub then
        local b = tonumber(args[1])
        local sc = tonumber(args[2])
        if not b or not sc then
            print('^1[cigsmoke] 使い方: /cigsmoke <bone> <scale> [秒]  /  /cigsmoke off  /  /cigsmoke net^7')
            return
        end
        Config.SmokeFxBone = math.floor(b)
        Config.SmokeFxScale = sc + 0.0
        secs = tonumber(args[3]) or 10
    end

    print(('^2[cigsmoke] asset=%s effect=%s bone=%d scale=%.3f networked=%s → %d秒^7'):format(
        Config.SmokeFxAsset, Config.SmokeFxEffect, Config.SmokeFxBone, Config.SmokeFxScale,
        tostring(Config.SmokeFxNetworked), secs))
    print('^2[cigsmoke] ↓ config.lua に転記する値 ↓^7')
    print(('^2Config.SmokeFxBone = %d^7'):format(Config.SmokeFxBone))
    print(('^2Config.SmokeFxScale = %.3f^7'):format(Config.SmokeFxScale))

    StartSmokeFx()
    if not smokeFx then
        print('^1[cigsmoke] ptfxを開始できませんでした(上のエラー行を確認)^7')
        return
    end
    Wait(secs * 1000)
    StopSmokeFx()
    print('^3[cigsmoke] 終了^7')
end, false)
