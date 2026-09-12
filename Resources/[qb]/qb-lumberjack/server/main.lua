local QBCore = exports['qb-core']:GetCoreObject()
local diedBeforeSale = {}

------------------------------ Jack Pick----------------------
RegisterServerEvent("qb-lumberjack:server:cutjack")
AddEventHandler("qb-lumberjack:server:cutjack", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.AddItem("wood", 1)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items["wood"], "add")
        TriggerClientEvent('QBCore:Notify', src, 'Cut your trunks.', "success")
end)

----------------------------Process Wood----------------------

QBCore.Functions.CreateCallback('qb-lumberjack:server:get:proccesswood', function(source, cb)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local wood = Ply.Functions.GetItemByName("wood")
    if wood ~= nil then
        cb(true)
    else
        cb(false)
    end
end)

RegisterServerEvent('qb-lumberjack:server:processwood', function()
    local source = source
    local Player = QBCore.Functions.GetPlayer(tonumber(source))
    local wood = 1
    Player.Functions.RemoveItem('wood', 1)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['wood'], "remove")
    Wait(1000)
    Player.Functions.AddItem('wood_pro', wood)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['wood_pro'], "add")
    TriggerClientEvent('QBCore:Notify', source, "Successfully ", "success")
    diedBeforeSale[source] = false
end)

RegisterServerEvent('qb-lumberjack:server:playerDied')
AddEventHandler('qb-lumberjack:server:playerDied', function()
    local src = source
    diedBeforeSale[src] = true
end)

-------------------------seller-------------------------------
QBCore.Functions.CreateCallback('qb-lumberjack:server:get:sellwood', function(source, cb)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local wood = Ply.Functions.GetItemByName("wood_pro")
    if wood ~= nil then
        cb(true)
    else
        cb(false)
    end
end)

RegisterServerEvent('qb-lumberjack:server:sellwood')
AddEventHandler('qb-lumberjack:server:sellwood', function()

    local xPlayer = QBCore.Functions.GetPlayer(source)
	local Item = xPlayer.Functions.GetItemByName('wood_pro')
   
	
	if Item == nil then
       TriggerClientEvent('QBCore:Notify', source, 'You dont have Processed Wood', "error")  
	else
	 for k, v in pairs(Config.Prices) do
        
		
		if Item.amount > 0 then
            -- 2026-09-10 経済設計【暫定値・要再調整】
            -- 基準時給$7,500/hへの移行にあたり、木こりは多工程・長距離移動職として
            -- 目標$8,000/h(1サイクル30分あたり$4,000)に置いた。
            --
            -- コードから確定している事実:
            --   伐採    Progressbar 4000ms → wood 1個
            --   加工    Progressbar 4000ms → wood_pro 1個 (伐採地から53m)
            --   売却    Progressbar 1000ms → 1個ずつ売却 (加工地から6,646m)
            --   伐採ポイントは Config.Locations に1箇所のみ = その場で連続採取できる
            --
            -- コードから読めない部分(ここが単価の誤差要因):
            --   1サイクル30分のうち、売却NPCまでの往復に約15分かかる。残り約15分での
            --   産出個数を「伐採7秒+加工6秒+売却2.5秒=15.5秒/個」として約55個と仮定した。
            --   $4,000 ÷ 55個 = 約$73 → $70〜80 とした。
            --
            -- 再調整の式: 新単価 = 4000 ÷ (30分1サイクルの実産出個数)
            --   実産出が55個より多ければ単価を下げ、少なければ上げる。1回の割り算で直せる。
            --   車両トランクを使った大量まとめ売りが常態化する場合は産出個数がさらに増える。
            local reward = math.random(70, 80)

            if diedBeforeSale[source] then
                reward = math.floor(reward / 2)
            end

			xPlayer.Functions.RemoveItem('wood_pro', 1)
			TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items['wood_pro'], "remove")
			xPlayer.Functions.AddMoney("cash", reward, "sold-pawn-items")

            if diedBeforeSale[source] then
                TriggerClientEvent('QBCore:Notify', source, '道中で死亡したため、買取額が半額になりました。', "primary")
            else
                TriggerClientEvent('QBCore:Notify', source, 'Successfully Selling.', "success")
            end

            diedBeforeSale[source] = false
        end
     end
	end
end)