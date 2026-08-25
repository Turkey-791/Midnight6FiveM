local QBCore = exports['qb-core']:GetCoreObject()
isLoggedIn = false
local Seller = Config.Seller.coords
local PedModel = Config.PedModel
local PedHash = Config.PedHash
local hasLumberjackJob = false


CreateThread(function()
    for k, station in pairs(Config.Locations["lumberjack"]) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, 77)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, 25)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(station.label)
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    for k, station in pairs(Config.Locations["process1"]) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, 238)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, 5)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(station.label)
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    for k, station in pairs(Config.Locations["seller"]) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, 642)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, 37)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(station.label)
        EndTextCommandSetBlipName(blip)
    end
end)

------------------------------ Jack Pick----------------------
RegisterNetEvent('qb-lumberjack:client:cutjack')
AddEventHandler("qb-lumberjack:client:cutjack", function()
    if not hasLumberjackJob then
        QBCore.Functions.Notify("先にSellerに話しかけて受注してください", 'error', 4000)
        return
    end
    
    
    
    QBCore.Functions.Progressbar("cut_wood", Config.Alerts["cut_wood"], 4000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "melee@hatchet@streamed_core",
        anim = "plyr_rear_takedown_b",
        flags = 16,
    }, {}, {}, function() 
        StopAnimTask(ped, dict, "plyr_rear_takedown_b", 1.0)
        TriggerServerEvent("qb-lumberjack:server:cutjack")
        ClearPedTasks(playerPed)
    end)
end)

----------------------------Process Wood----------------------
RegisterNetEvent("qb-lumberjack:client:processwood")
AddEventHandler("qb-lumberjack:client:processwood", function ()
    if not hasLumberjackJob then
        QBCore.Functions.Notify("先にSellerに話しかけて受注してください", 'error', 4000)
        return
    end
    
    QBCore.Functions.TriggerCallback('qb-lumberjack:server:get:proccesswood', function(wood)  
        if wood then
            QBCore.Functions.Progressbar("process_wood", Config.Alerts["proc_wood"], 4000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "mini@repair",
                anim = "fixing_a_player",
                flags = 16,
            }, {}, {}, function ()
                TriggerServerEvent("qb-lumberjack:server:processwood")
            end)
        elseif not wood then
                QBCore.Functions.Notify(Config.Alerts["no_item"], 'error', 4000)
        end
    end)            
end)

--------------------------------
---- Sell Ped ------------------
CreateThread(function()
    RequestModel( GetHashKey( PedModel ) )
    while (not HasModelLoaded( GetHashKey( PedModel))) do
        Wait(1)  
    end
    pedfarmer1 = CreatePed(1, PedHash, Seller, false, true)
    SetEntityInvincible(pedfarmer1, true)
    SetBlockingOfNonTemporaryEvents(pedfarmer1, true)
    FreezeEntityPosition(pedfarmer1, true)
end)

-----------------------------seller wood------------------------------
RegisterNetEvent("qb-lumberjack:client:sellwood")
AddEventHandler("qb-lumberjack:client:sellwood", function ()
    if not hasLumberjackJob then
        QBCore.Functions.Notify("先にSellerに話しかけて受注してください", 'error', 4000)
        return
    end

    QBCore.Functions.TriggerCallback('qb-lumberjack:server:get:sellwood', function(pro_wood)
        if pro_wood then
            QBCore.Functions.Progressbar("sell_wood", Config.Alerts["sell_wood"], 1000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function ()
                TriggerServerEvent("qb-lumberjack:server:sellwood")
            end)
        elseif not pro_wood then
            QBCore.Functions.Notify(Config.Alerts["no_item"], 'error', 4000)
        end    
    end)        
end)

-----------------------------------Locations--------------------------
Citizen.CreateThread(function ()
  exports['qb-target']:AddBoxZone("jacktree1", vector3(-537.61, 5383.73, 70.58), 13, 15,{
      name = "jacktree1",
      heading = 335,
      debugPoly = false,
      minZ=68.78,
      maxZ=72.78
  }, {
      options = {
          {
              event = "qb-lumberjack:client:cutjack",
              icon = "fas fa-circle",
              label = "Cut Wood",
          },
      },
      distance = 3
  })
  exports['qb-target']:AddBoxZone("jacktree2", vector3(-533.6, 5370.08, 70.36), 13, 7,{
      name = "jacktree2",
      heading = 255,
      debugPoly = false,
      minZ=68.36,
      maxZ=72.36
  }, {
      options = {
          {
              event = "qb-lumberjack:client:cutjack",
              icon = "fas fa-circle",
              label = "Cut Wood",
          },
      },
      distance = 3
  })

  exports['qb-target']:AddBoxZone("cutprocess", vector3(-551.15, 5328.95, 73.64), 9, 3,{
      name = "cutprocess",
      heading = 250,
      debugPoly = false,
      minZ=70.44,
      maxZ=74.44
  }, {
      options = {
          {
              event = "qb-lumberjack:client:processwood",
              icon = "fas fa-circle",
              label = "Process Wood",
          },
      },
      distance = 3
  })     
  
  exports['qb-target']:AddBoxZone("sellerped", vector3(175.55, -1279.07, 29.04), 2, 2, {
	name = "seller",
	heading = 340,
	debugPoly = false,
    minZ=26.44,
    maxZ=30.44,
}, {
	options = {
    {
      event = "qb-lumberjack:menuseller",
      icon = "Fas Fa-hands",
      label = "Talk to Seller",
    },
	},
	distance = 3.0
})
end)

----------------------qb-menu-----------------------------
RegisterNetEvent('qb-lumberjack:menuseller', function(data)
    local SellerMenu = {
        {
            header = "LumberJack Seller",
            isMenuHeader = true,
        },
    }

    if hasLumberjackJob then
        SellerMenu[#SellerMenu + 1] = {
            header = "🏁 仕事を終える",
            params = {
                event = 'qb-lumberjack:client:endjob',
            }
        }
    else
        SellerMenu[#SellerMenu + 1] = {
            header = "📋 受注する",
            params = {
                event = 'qb-lumberjack:client:acceptjob',
            }
        }
    end

    SellerMenu[#SellerMenu + 1] = {
        header = "🪓 Selling Wood",
        params = {
            event = 'qb-lumberjack:client:sellwood',
        }
    }

    SellerMenu[#SellerMenu + 1] = {
        header = "Close",
    }

    exports['qb-menu']:openMenu(SellerMenu)
end)

RegisterNetEvent('qb-lumberjack:client:acceptjob', function()
    hasLumberjackJob = true
    QBCore.Functions.Notify("きこりの仕事を受注しました。伐採場へ向かってください。", 'success', 5000)
    SetNewWaypoint(-541.06, 5379.39)
end)

RegisterNetEvent('qb-lumberjack:client:endjob', function()
    hasLumberjackJob = false
    QBCore.Functions.Notify("きこりの仕事を終了しました。", 'primary', 4000)
end)

-----------------------------死亡検知------------------------------
CreateThread(function()
    local wasDead = false
    while true do
        Wait(1000)
        local isDead = IsEntityDead(PlayerPedId())
        if isDead and not wasDead then
            TriggerServerEvent('qb-lumberjack:server:playerDied')
        end
        wasDead = isDead
    end
end)