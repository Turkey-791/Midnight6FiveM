local QBCore = exports['qb-core']:GetCoreObject({ 'Functions' })
local PlayerJob = {}

AddEventHandler('onResourceStart', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		QBCore.Functions.GetPlayerData(function(PlayerData)
			PlayerJob = PlayerData.job
		end)
	end
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	QBCore.Functions.GetPlayerData(function(PlayerData)
		PlayerJob = PlayerData.job
	end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
	if key == 'job' then
		local JobInfo = val
		PlayerJob = JobInfo
	elseif key == 'all' then
		local JobInfo = val.job
		PlayerJob = JobInfo
	end
end)

local tasking = false
local startVineyard = false
local random = 0
local pickedGrapes = 0
local blip = 0
local winetimer = Config.wineTimer
local loadIngredients = false
local wineStarted = false
local finishedWine = false
local jobBlip = nil -- [2026-09-04 追加] 求人マップブリップ(常時表示)のハンドル

local grapeLocations = {
	[1] = vector3(-1875.41, 2100.37, 138.86),
	[2] = vector3(-1908.69, 2107.48, 131.31),
	[3] = vector3(-1866.04, 2112.64, 134.41),
	[4] = vector3(-1907.76, 2125.35, 124.03),
	[5] = vector3(-1850.31, 2142.95, 122.30),
	[6] = vector3(-1888.22, 2164.51, 114.81),
	[7] = vector3(-1835.52, 2180.59, 104.88),
	[8] = vector3(-1891.98, 2208.35, 94.56),
	[9] = vector3(-1720.37, 2182.03, 106.18),
	[10] = vector3(-1808.52, 2173.14, 107.63),
	[11] = vector3(-1784.22, 2222.80, 92.86),
	[12] = vector3(-1889.13, 2250.05, 79.63),
	[13] = vector3(-1861.16, 2254.32, 81.04),
	[14] = vector3(-1886.75, 2272.45, 70.81),
	[15] = vector3(-1845.49, 2274.63, 73.33),
	[16] = vector3(-1687.28, 2195.76, 97.87),
	[17] = vector3(-1741.18, 2173.22, 114.39),
	[18] = vector3(-1743.17, 2141.11, 121.18),
	[19] = vector3(-1813.84, 2089.57, 134.21),
	[20] = vector3(-1698.71, 2150.65, 110.41),
}

local function log(debugMessage)
	print(('^6[^3qb-vineyard^6]^0 %s'):format(debugMessage))
end

local function CreateBlip()
	if tasking then
		blip = AddBlipForCoord(grapeLocations[random].x, grapeLocations[random].y, grapeLocations[random].z)
	end
	SetBlipSprite(blip, 465)
	SetBlipScale(blip, 1.0)
	SetBlipAsShortRange(blip, false)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName('Drop Off')
	EndTextCommandSetBlipName(blip)
end

local function nextTask()
	if tasking then
		return
	end
	random = math.random(#grapeLocations)
	tasking = true
	CreateBlip()
end

local function startVinyard()
	local amount = math.random(Config.PickAmount.min, Config.PickAmount.max)
	QBCore.Functions.Notify(Lang:t('text.start_shift'))
	while startVineyard do
		if tasking then
			Wait(5000)
		else
			nextTask()
			pickedGrapes = pickedGrapes + 1
			if pickedGrapes == amount then
				nextTask()
				Wait(20000)
				startVineyard = false
				pickedGrapes = 0
				QBCore.Functions.Notify(Lang:t('text.end_shift'))
				-- [2026-09-05 追加] 収穫終了時、加工場(グレープジュースゾーン)への
				-- 案内メッセージ+ウェイポイントを自動セットする
				if Config.GuideToProcessing.enabled then
					QBCore.Functions.Notify(Lang:t('text.go_to_processing'))
					SetNewWaypoint(Config.Vineyard.grapejuice.coords.x, Config.Vineyard.grapejuice.coords.y)
				end
			end
		end
		Wait(5)
	end
end

local function DeleteBlip()
	if DoesBlipExist(blip) then
		RemoveBlip(blip)
	end
end

-- ============================================================
-- [2026-09-04 追加] 求人マップブリップ(建物入口に常時表示)
-- 収穫地点の一時的なブリップ(CreateBlip/DeleteBlip)とは別物で、
-- ジョブに就いているかどうかに関わらず常に表示しておく。
-- ============================================================
local function CreateJobBlip()
	if not Config.JobBlip.enabled then return end
	if jobBlip and DoesBlipExist(jobBlip) then return end

	local coords = Config.JobDoor.coords
	jobBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
	SetBlipSprite(jobBlip, Config.JobBlip.sprite)
	SetBlipColour(jobBlip, Config.JobBlip.color)
	SetBlipScale(jobBlip, Config.JobBlip.scale)
	SetBlipAsShortRange(jobBlip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(Config.JobBlip.label)
	EndTextCommandSetBlipName(jobBlip)
end

-- ============================================================
-- [2026-09-05 追加] 加工場(グレープジュースゾーン)マップブリップ(常時表示)
-- 求人ブリップと同じ考え方で、ジョブの有無に関わらず常時表示する。
-- ============================================================
local processingBlip = nil
local function CreateProcessingBlip()
	if not Config.ProcessingBlip.enabled then return end
	if processingBlip and DoesBlipExist(processingBlip) then return end

	local coords = Config.ProcessingBlip.coords
	processingBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
	SetBlipSprite(processingBlip, Config.ProcessingBlip.sprite)
	SetBlipColour(processingBlip, Config.ProcessingBlip.color)
	SetBlipScale(processingBlip, Config.ProcessingBlip.scale)
	SetBlipAsShortRange(processingBlip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(Config.ProcessingBlip.label)
	EndTextCommandSetBlipName(processingBlip)
end

-- ============================================================
-- [2026-09-05 追加] 加工場ゾーンの装飾オブジェクト(見た目のみ・機能なし)
-- 「プレハブのみで寂しい」との要望のため、加工設備っぽい樽・木箱を
-- 加工場ゾーン付近に配置する。PlaceObjectOnGroundProperlyで地面に
-- スナップさせるため、Config側のZ座標が多少ずれていても浮いたり
-- 埋まったりしにくい。ゲームプレイには一切影響しない純粋な装飾。
-- ============================================================
local function SpawnDecorProp(model, coords, heading)
	local hash = GetHashKey(model)
	RequestModel(hash)
	local tries = 0
	while not HasModelLoaded(hash) and tries < 100 do
		Wait(10)
		tries = tries + 1
	end
	if not HasModelLoaded(hash) then
		log(('装飾オブジェクトのモデル読み込みに失敗しました: %s'):format(model))
		return
	end
	local obj = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
	PlaceObjectOnGroundProperly(obj)
	SetEntityHeading(obj, heading or 0.0)
	FreezeEntityPosition(obj, true)
	SetModelAsNoLongerNeeded(hash)
	return obj
end

local function CreateProcessingProps()
	if not Config.ProcessingProps.enabled then return end
	CreateThread(function()
		local base = Config.ProcessingProps.coords
		for _, item in ipairs(Config.ProcessingProps.items) do
			SpawnDecorProp(item.model, base + item.offset, item.heading)
		end
	end)
end

-- ============================================================
-- [2026-09-05 追加] ワイン醸造ゾーンの目印(ブリップ + 地面マーカー + 樽)
-- 加工場と同じ考え方で、常時表示のブリップと装飾オブジェクトを追加する。
-- さらに、建物が存在しないため近づいた際に地面にマーカーを表示し、
-- 遠くから見ても位置がわかるようにする。
-- ============================================================
local wineBlip = nil
local function CreateWineBlip()
	if not Config.WineBlip.enabled then return end
	if wineBlip and DoesBlipExist(wineBlip) then return end

	local coords = Config.WineBlip.coords
	wineBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
	SetBlipSprite(wineBlip, Config.WineBlip.sprite)
	SetBlipColour(wineBlip, Config.WineBlip.color)
	SetBlipScale(wineBlip, Config.WineBlip.scale)
	SetBlipAsShortRange(wineBlip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(Config.WineBlip.label)
	EndTextCommandSetBlipName(wineBlip)
end

local function CreateWineProps()
	if not Config.WineProps.enabled then return end
	CreateThread(function()
		local base = Config.WineProps.coords
		for _, item in ipairs(Config.WineProps.items) do
			SpawnDecorProp(item.model, base + item.offset, item.heading)
		end
	end)
end

local function CreateWineMarker()
	if not Config.WineMarker.enabled then return end
	CreateThread(function()
		local coords = Config.Vineyard.wine.coords
		local mSize = Config.WineMarker.size
		local mColor = Config.WineMarker.color
		while true do
			local sleep = 1000
			local pcoords = GetEntityCoords(PlayerPedId())
			local dist = #(pcoords - coords)
			if dist < Config.WineMarker.radius then
				sleep = 0
				DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
					mSize.x, mSize.y, mSize.z,
					mColor.r, mColor.g, mColor.b, mColor.a,
					false, true, 2, false, nil, nil, false)
			end
			Wait(sleep)
		end
	end)
end

-- ============================================================
-- [2026-09-05 追加] 収穫地点の地面マーカー(白い輪っか)
-- ブリップの「?」マークだけだと立ち位置がわかりづらいとの要望のため、
-- 現在有効な収穫地点(tasking中の grapeLocations[random])に、
-- シフト中のみ薄い白色のマーカーを表示する。tasking/randomは
-- ファイル先頭で宣言済みのアップバリューをそのまま参照する。
-- ============================================================
local function CreateGrapeMarkerThread()
	if not Config.GrapeMarker.enabled then return end
	CreateThread(function()
		local mSize = Config.GrapeMarker.size
		local mColor = Config.GrapeMarker.color
		while true do
			local sleep = 250
			if tasking and random ~= 0 and grapeLocations[random] then
				sleep = 0
				local coords = grapeLocations[random]
				DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
					mSize.x, mSize.y, mSize.z,
					mColor.r, mColor.g, mColor.b, mColor.a,
					false, true, 2, false, nil, nil, false)
			end
			Wait(sleep)
		end
	end)
end

-- resourceの開始タイミングに関わらず(既に起動済みのリソースへ後から
-- 接続してきたプレイヤーも含めて)確実に表示されるよう、クライアント
-- スクリプトの読み込み時に直接呼び出す(プレイヤーデータ取得を待たない)。
CreateJobBlip()
CreateProcessingBlip()
CreateProcessingProps()
CreateWineBlip()
CreateWineProps()
CreateWineMarker()
CreateGrapeMarkerThread()

local function pickProcess()
	QBCore.Functions.Progressbar('pick_grape', Lang:t('progress.pick_grapes'), math.random(6000, 8000), false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function() -- Done
		tasking = false
		TriggerServerEvent('qb-vineyard:server:getGrapes')
		DeleteBlip()
		ClearPedTasks(PlayerPedId())
	end, function() -- Cancel
		ClearPedTasks(PlayerPedId())
		QBCore.Functions.Notify(Lang:t('task.cancel_task'), 'error')
	end)
end

local function LoadAnim(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(1)
	end
end

local function PickAnim()
	local ped = PlayerPedId()
	LoadAnim('amb@prop_human_bum_bin@idle_a')
	TaskPlayAnim(ped, 'amb@prop_human_bum_bin@idle_a', 'idle_a', 6.0, -6.0, -1, 47, 0, 0, 0, 0)
end

local grapeZones = {}
for k = 1, #grapeLocations do
	local label = ('GrapeZone-%s'):format(k)
	grapeZones[k] = {
		isInside = false,
		zone = BoxZone:Create(grapeLocations[k], 1.75, 3, {
			name = label,
			minZ = grapeLocations[k].z - 1.0,
			maxZ = grapeLocations[k].z + 1.0,
			debugPoly = Config.Debug,
		})
	}
	grapeZones[k].zone:onPlayerInOut(function(isPointInside)
		grapeZones[k].isInside = isPointInside
		if grapeZones[k].isInside then
			if Config.Debug then
				log(Lang:t('text.zone_entered', { zone = label }))
				if k == random then log(Lang:t('text.valid_zone')) else log(Lang:t('text.invalid_zone')) end
			end

			if k == random then
				CreateThread(function()
					while grapeZones[k].isInside and k == random do
						exports['qb-core']:DrawText(Lang:t('task.start_task'), 'right')
						if not IsPedInAnyVehicle(PlayerPedId()) and IsControlJustReleased(0, 38) then
							PickAnim()
							pickProcess()
							exports['qb-core']:HideText()
							random = 0
						end
						Wait(1)
					end
				end)
			end
		else
			if Config.Debug then log(Lang:t('text.zone_exited', { zone = label })) end
			exports['qb-core']:HideText()
		end
	end)
end

local function StartWineProcess()
	CreateThread(function()
		wineStarted = true
		while winetimer > 0 do
			winetimer = winetimer - 1
			Wait(1000)
		end
		wineStarted = false
		finishedWine = true
		winetimer = Config.wineTimer
	end)
end


local function PrepareAnim()
	local ped = PlayerPedId()
	LoadAnim('amb@code_human_wander_rain@male_a@base')
	TaskPlayAnim(ped, 'amb@code_human_wander_rain@male_a@base', 'static', 6.0, -6.0, -1, 47, 0, 0, 0, 0)
end

local function grapeJuiceProcess()
	QBCore.Functions.Progressbar('grape_juice', Lang:t('progress.process_grapes'), math.random(15000, 20000), false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function() -- Done
		TriggerServerEvent('qb-vineyard:server:receiveGrapeJuice')
		ClearPedTasks(PlayerPedId())
	end, function() -- Cancel
		ClearPedTasks(PlayerPedId())
		QBCore.Functions.Notify(Lang:t('task.cancel_task'), 'error')
	end)
end

local Zones = {}
Zones[1] = {
	isInside = false,
	zone = PolyZone:Create(Config.Vineyard.start.zones, {
		name = 'Vineyard-Start',
		minZ = Config.Vineyard.start.minZ,
		maxZ = Config.Vineyard.start.maxZ,
		debugPoly = Config.Debug
	})
}
Zones[1].zone:onPlayerInOut(function(isPointInside)
	Zones[1].isInside = isPointInside
	if isPointInside then
		if Config.Debug then log(Lang:t('text.zone_entered', { zone = 'Start' })) end
		CreateThread(function()
			while Zones[1].isInside do
				if PlayerJob.name == 'vineyard' then
					if not startVineyard then
						exports['qb-core']:DrawText(Lang:t('task.start_task'), 'right')
						if IsControlJustReleased(0, 38) and not startVineyard then
							startVineyard = true
							startVinyard()
						end
					end
				else
					-- [2026-09-04 追加] まだvineyard jobではないプレイヤー向けの
					-- 求人受付(建物入口でEキーを押すと受注する)
					exports['qb-core']:DrawText(Lang:t('task.apply_job'), 'right')
					if IsControlJustReleased(0, 38) then
						TriggerServerEvent('qb-vineyard:server:applyJob')
					end
				end
				Wait(1)
			end
		end)
	else
		if Config.Debug then log(Lang:t('text.zone_exited', { zone = 'Start' })) end
		exports['qb-core']:HideText()
	end
end)

Zones[2] = {
	isInside = false,
	zone = PolyZone:Create(Config.Vineyard.wine.zones, {
		name = 'Vineyard-Wine',
		minZ = Config.Vineyard.wine.minZ,
		maxZ = Config.Vineyard.wine.maxZ,
		debugPoly = Config.Debug
	})
}
Zones[2].zone:onPlayerInOut(function(isPointInside)
	Zones[2].isInside = isPointInside
	if isPointInside then
		if Config.Debug then log(Lang:t('text.zone_entered', { zone = 'Wine' })) end

		if not startVineyard and PlayerJob.name == 'vineyard' then
			CreateThread(function()
				while Zones[2].isInside do
					if not wineStarted then
						if not loadIngredients then
							exports['qb-core']:DrawText(Lang:t('task.load_ingrediants'), 'right')
							if IsControlJustPressed(0, 38) and not LocalPlayer.state.inv_busy then
								QBCore.Functions.TriggerCallback('qb-vineyard:server:loadIngredients', function(result)
									if result then loadIngredients = true end
								end)
							end
						else
							if not finishedWine then
								exports['qb-core']:DrawText(Lang:t('task.wine_process'), 'right')
								if IsControlJustPressed(0, 38) and not LocalPlayer.state.inv_busy then
									StartWineProcess()
								end
							else
								exports['qb-core']:DrawText(Lang:t('task.get_wine'), 'right')
								if IsControlJustPressed(0, 38) and not LocalPlayer.state.inv_busy then
									TriggerServerEvent('qb-vineyard:server:receiveWine')
									finishedWine = false
									loadIngredients = false
									wineStarted = false
								end
							end
						end
					else
						exports['qb-core']:DrawText(Lang:t('task.countdown', { time = winetimer }), 'right')
						Wait(999)
					end
					Wait(1)
				end
			end)

			-- [2026-09-03 追加] wine納品(売却)。既存の醸造フロー(Eキー, 'right'表示)
			-- とは別スレッド・別キー(Gキー, 'left'表示)にして、「醸造開始」と
			-- 「完成品納品」を別操作として明確に区別する。数量・価格はいずれも
			-- サーバー側(qb-vineyard:server:sellWine)で決定するため、ここでは
			-- イベント送信のみを行う。
			CreateThread(function()
				while Zones[2].isInside do
					exports['qb-core']:DrawText(Lang:t('task.sell_wine'), 'left')
					if IsControlJustPressed(0, 47) and not LocalPlayer.state.inv_busy then
						TriggerServerEvent('qb-vineyard:server:sellWine')
					end
					Wait(1)
				end
			end)
		end
	else
		if Config.Debug then log(Lang:t('text.zone_exited', { zone = 'Wine' })) end
		exports['qb-core']:HideText()
	end
end)

Zones[3] = {
	isInside = false,
	zone = PolyZone:Create(Config.Vineyard.grapejuice.zones, {
		name = 'Vineyard-GrapeJuice',
		minZ = Config.Vineyard.grapejuice.minZ,
		maxZ = Config.Vineyard.grapejuice.maxZ,
		debugPoly = Config.Debug
	})
}
Zones[3].zone:onPlayerInOut(function(isPointInside)
	Zones[3].isInside = isPointInside
	if isPointInside then
		if Config.Debug then log(Lang:t('text.zone_entered', { zone = 'Juice' })) end
		if not startVineyard and PlayerJob.name == 'vineyard' then
			CreateThread(function()
				while Zones[3].isInside do
					exports['qb-core']:DrawText(Lang:t('task.make_grape_juice'), 'right')
					if IsControlJustPressed(0, 38) and not LocalPlayer.state.inv_busy then
						QBCore.Functions.TriggerCallback('qb-vineyard:server:grapeJuice', function(result)
							if result then
								PrepareAnim()
								grapeJuiceProcess()
							end
						end)
					end
					Wait(1)
				end
			end)
		end
	else
		if Config.Debug then log(Lang:t('text.zone_exited', { zone = 'Juice' })) end
		exports['qb-core']:HideText()
	end
end)
