Config = {}
QBCore = exports['qb-core']:GetCoreObject()
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)
Config.PauseMapText = ''                                     -- Text shown above the map when ESC is pressed. If left empty 'FiveM' will appear
Config.HarnessUses = 20
Config.DamageNeeded = 100.0                                  -- amount of damage till you can push your vehicle. 0-1000
Config.Logging = 'discord'                                   -- fivemanage

Config.AFK = {
    ignoredGroups = {
        ['mod'] = true,
        ['admin'] = true,
        ['god'] = true
    },
    secondsUntilKick = 1000000, -- AFK Kick Time Limit (in seconds)
    kickInCharMenu = false      -- Set to true if you want to kick players for being AFK even when they are in the character menu.
}

Config.HandsUp = {
    command = 'hu',
    keybind = 'X',
    controls = { 24, 25, 47, 58, 59, 63, 64, 71, 72, 75, 140, 141, 142, 143, 257, 263, 264 }
}

Config.Binoculars = {
    zoomSpeed = 10.0,        -- camera zoom speed
    storeBinocularsKey = 177 -- backspace by default
}

-- 2026-09-12 AO依頼(AI警察導入): GTA標準のWantedと警察出動を停止。
-- rde_aipd_m6 が独自のWanted/AI警察を持つため、標準側を有効にすると二重に出動する。
Config.AIResponse = {
    wantedLevels = false, -- if true, you will recieve wanted levels
    dispatchServices = {  -- AI dispatch services
        [1] = false,      -- Police Vehicles
        [2] = false,      -- Police Helicopters
        [3] = false,      -- Fire Department Vehicles
        [4] = false,      -- Swat Vehicles
        [5] = false,      -- Ambulance Vehicles
        [6] = false,      -- Police Motorcycles
        [7] = false,      -- Police Backup
        [8] = false,      -- Police Roadblocks
        [9] = false,      -- PoliceAutomobileWaitPulledOver
        [10] = false,     -- PoliceAutomobileWaitCruising
        [11] = false,     -- Gang Members
        [12] = false,     -- Swat Helicopters
        [13] = false,     -- Police Boats
        [14] = false,     -- Army Vehicles
        [15] = false      -- Biker Backup
    }
}

-- To Set This Up visit https://forum.cfx.re/t/how-to-updated-discord-rich-presence-custom-image/157686
Config.Discord = {
    isEnabled = false,                                     -- If set to true, then discord rich presence will be enabled
    applicationId = '00000000000000000',                   -- The discord application id
    iconLarge = 'logo_name',                               -- The name of the large icon
    iconLargeHoverText = 'This is a Large icon with text', -- The hover text of the large icon
    iconSmall = 'small_logo_name',                         -- The name of the small icon
    iconSmallHoverText = 'This is a Small icon with text', -- The hover text of the small icon
    updateRate = 60000,                                    -- How often the player count should be updated
    showPlayerCount = true,                                -- If set to true the player count will be displayed in the rich presence
    maxPlayers = 48,                                       -- Maximum amount of players
    buttons = {
        {
            text = 'First Button!',
            url = 'fivem://connect/localhost:30120'
        },
        {
            text = 'Second Button!',
            url = 'fivem://connect/localhost:30120'
        }
    }
}

Config.Density = {
    parked = 0.8,
    vehicle = 0.8,
    multiplier = 0.8,
    peds = 0.8,
    scenario = 0.8
}

Config.Disable = {
    hudComponents = { 2, 3, 4, 7, 9, 13, 14, 19, 20, 21, 22 }, -- Hud Components: https://docs.fivem.net/natives/?_0x6806C51AD12B83B8
    controls = { 37 },                                            -- Controls: https://docs.fivem.net/docs/game-references/controls/
    displayAmmo = true,                                           -- false disables ammo display
    ambience = false,                                             -- disables distance sirens, distance car alarms, flight music, etc
    idleCamera = true,                                            -- disables the idle cinematic camera
    vestDrawable = false,                                         -- disables the vest equipped when using heavy armor
    pistolWhipping = true,                                        -- disables pistol whipping
    driveby = false,                                              -- disables driveby
    carRadio = false                                              -- When set to true car radio will default to off when entering a vehicle.
}

Config.RelieveWeedStress = math.random(15, 20) -- stress relief amount (100 max)

-- 2026-09-06 AO依頼: 喫煙システム追加分(市販タバコ/手巻きタバコ)。数値確定(2026-09-06)。
-- 性能順: 市販タバコ(cigarette) < 手巻きタバコ(handrolled_cigarette) < ジョイント(joint、上のRelieveWeedStress=15-20は既存のまま変更していない)
Config.RelieveCigaretteStress = math.random(5, 8) -- 市販タバコのstress軽減量(100 max)
Config.RelieveHandrolledCigaretteStress = math.random(10, 14) -- 手巻きタバコのstress軽減量(joint未満・cigarette超)
-- 2026-09-07 AO判断(案A): 吸い終わりが早すぎたため全体を延長し、傾斜をかけた。
-- 性能順(強いほど短時間)は維持: joint 4秒 < handrolled 6秒 < cigarette 8秒。
-- ジョイントの4秒は「変更前の市販タバコの喫煙時間」に合わせた基準値。
-- Animation(smoke_idle / flags 49)はループフラグ付きなので、延長しても途中で止まらない。
Config.SmokeCigaretteDuration = 8000 -- (ms) 市販タバコの喫煙時間(一番長い)
Config.SmokeHandrolledDuration = 6000 -- (ms) 手巻きタバコの喫煙時間(市販タバコより短く/速く)
Config.SmokeJointDuration = 4000 -- (ms) ジョイントの喫煙時間(一番短く/強い)

-- 2026-09-07 AO依頼: 喫煙時の煙(ptfx)設定。
-- 参考にした実装は jayz666/my-smoking。asset 'core' / effect 'exp_grd_bzgas_smoke' を
-- Pedのボーンにloopで貼る方式で、GTA V標準アセットのため追加streamは不要。
-- 実機で /cigsmoke を使って詰められる。
Config.SmokeFxEnable = true                    -- 煙のON/OFF
Config.SmokeFxAsset = 'core'                   -- ptfxアセット名(GTA V標準)
Config.SmokeFxEffect = 'exp_grd_bzgas_smoke'   -- エフェクト名
Config.SmokeFxBone = 31086                     -- 31086 = 頭 / 20279 = 口元
Config.SmokeFxOffsetX = 0.0
Config.SmokeFxOffsetY = 0.0
Config.SmokeFxOffsetZ = 0.0
Config.SmokeFxRotX = 0.0
Config.SmokeFxRotY = 0.0
Config.SmokeFxRotZ = 0.0
-- true: 他プレイヤーにも見える / false: 自分だけ(jayz666と同じローカル版)
-- ネットワーク版で煙が全く出ない場合は false にして再確認すること。
Config.SmokeFxNetworked = true

-- 2026-09-07 AO依頼: 煙をアイテム別に調整する。
--   delay = 喫煙開始から煙が出るまでの待ち時間(ms)。口元へ持っていく前に煙が出る問題の対策。
--   scale = 煙の量/大きさ。大きすぎると煙幕になるので注意。
--   r,g,b = 煙の色(0-255)。数値を下げるほど濃いグレーになる。
--   alpha = 濃さ(0.0-1.0)。
-- ※ 色/濃さの指定(SetParticleFxLoopedColour / SetParticleFxLoopedAlpha)が
--    exp_grd_bzgas_smoke に効くかは実機未検証。効かない場合は scale で差をつけること。
-- 【重要】delay は必ず喫煙時間(Duration)より短くすること。長いと煙が一度も出ない。
-- 現行Duration: cigarette 8000ms / handrolled 6000ms / joint 4000ms
-- delayは「手を口元へ持っていくまでの時間」であり、Animationで決まる固定値なので
-- Durationに比例させず3種とも同じ2000msにしている(2026-09-07 案A適用時)。
-- 早すぎる/遅すぎる場合は /cigsmoke set <key> <delay> ... で詰めること。
Config.SmokeFxDefault = { delay = 2000, scale = 0.10, r = 255, g = 255, b = 255, alpha = 1.0 }
Config.SmokeFxItems = {
    -- 市販タバコ: 現状の量を基準にする(AO指示)
    ['cigarette']            = { delay = 2000, scale = 0.10, r = 255, g = 255, b = 255, alpha = 1.0 },
    -- 手巻きタバコ: 少し灰色を濃くする(AO指示)
    ['handrolled_cigarette'] = { delay = 2000, scale = 0.12, r = 150, g = 150, b = 150, alpha = 1.0 },
    -- ジョイント: 一番煙の量を多くする(AO指示)。Durationが一番短いので煙の出る時間も短い
    ['joint']                = { delay = 1800, scale = 0.22, r = 255, g = 255, b = 255, alpha = 1.0 },
}

Config.Consumables = {
    eat = { -- default food items
        ['sandwich'] = math.random(35, 54),
        ['tosti'] = math.random(40, 50),
        ['twerks_candy'] = math.random(35, 54),
        ['snikkel_candy'] = math.random(40, 50)
    },
    drink = { -- default drink items
        ['water_bottle'] = math.random(35, 54),
        ['kurkakola'] = math.random(35, 54),
        ['coffee'] = math.random(40, 50)
    },
    alcohol = { -- default alcohol items
        ['whiskey'] = math.random(20, 30),
        ['beer'] = math.random(30, 40),
        ['vodka'] = math.random(20, 40),
    },
    custom = { -- put any custom items here
        -- ['newitem'] = {
        --     progress = {
        --         label = 'Using Item...',
        --         time = 5000
        --     },
        --     animation = {
        --         animDict = 'amb@prop_human_bbq@male@base',
        --         anim = 'base',
        --         flags = 8,
        --     },
        --     prop = {
        --         model = false,
        --         bone = false,
        --         coords = false, -- vector 3 format
        --         rotation = false, -- vector 3 format
        --     },
        --     replenish = {'''
        --         type = 'Hunger', -- replenish type 'Hunger'/'Thirst' / false
        --         replenish = math.random(20, 40),
        --         isAlcohol = false, -- if you want it to add alcohol count
        --         event = false, -- 'eventname' if you want it to trigger an outside event on use useful for drugs
        --         server = false -- if the event above is a server event
        --     }
        -- }
    }
}

Config.Fireworks = {
    delay = 5, -- time in s till it goes off
    items = {  -- firework items
        'firework1',
        'firework2',
        'firework3',
        'firework4'
    }
}

Config.BlacklistedScenarios = {
    types = {
        'WORLD_VEHICLE_MILITARY_PLANES_SMALL',
        'WORLD_VEHICLE_MILITARY_PLANES_BIG',
        'WORLD_VEHICLE_AMBULANCE',
        'WORLD_VEHICLE_POLICE_NEXT_TO_CAR',
        'WORLD_VEHICLE_POLICE_CAR',
        'WORLD_VEHICLE_POLICE_BIKE'
    },
    groups = {
        2017590552,
        2141866469,
        1409640232,
        `ng_planes`
    }
}

Config.BlacklistedVehs = {
    [`shamal`] = true,
    [`luxor`] = true,
    [`luxor2`] = true,
    [`jet`] = true,
    [`lazer`] = true,
    [`buzzard`] = true,
    [`buzzard2`] = true,
    [`annihilator`] = true,
    [`savage`] = true,
    [`titan`] = true,
    [`rhino`] = true,
    [`firetruck`] = true,
    [`mule`] = true,
    [`maverick`] = true,
    [`blimp`] = true,
    [`airtug`] = true,
    [`camper`] = true,
    [`hydra`] = true,
    [`oppressor`] = true,
    [`technical3`] = true,
    [`insurgent3`] = true,
    [`apc`] = true,
    [`tampa3`] = true,
    [`trailersmall2`] = true,
    [`halftrack`] = true,
    [`hunter`] = true,
    [`vigilante`] = true,
    [`akula`] = true,
    [`barrage`] = true,
    [`khanjali`] = true,
    [`caracara`] = true,
    [`blimp3`] = true,
    [`menacer`] = true,
    [`oppressor2`] = true,
    [`scramjet`] = true,
    [`strikeforce`] = true,
    [`cerberus`] = true,
    [`cerberus2`] = true,
    [`cerberus3`] = true,
    [`scarab`] = true,
    [`scarab2`] = true,
    [`scarab3`] = true,
    [`rrocket`] = true,
    [`ruiner2`] = true,
    [`deluxo`] = true,
    [`cargoplane2`] = true,
    [`voltic2`] = true
}

Config.BlacklistedWeapons = {
    [`WEAPON_RAILGUN`] = true,
}

Config.BlacklistedPeds = {
--    [`s_m_y_ranger_01`] = true,
--    [`s_m_y_sheriff_01`] = true,
--    [`s_m_y_cop_01`] = true,
--    [`s_f_y_sheriff_01`] = true,
--    [`s_f_y_cop_01`] = true,
--    [`s_m_y_hwaycop_01`] = true
}

Config.Objects = { -- for object removal
    { coords = vector3(266.09, -349.35, 44.74), heading = 0, length = 200, width = 200, model = 'prop_sec_barier_02b' },
    { coords = vector3(285.28, -355.78, 45.13), heading = 0, length = 200, width = 200, model = 'prop_sec_barier_02a' },
}

-- You may add more than 2 selections and it will bring up a menu for the player to select which floor be sure to label each section though
Config.Teleports = {
    [1] = {                   -- Elevator @ labs
        [1] = {               -- up
            poly = { coords = vector3(3540.74, 3675.59, 20.99), heading = 167.5, length = 2, width = 2 },
            allowVeh = false, -- whether or not to allow use in vehicle
            label = false     -- set this to a string for a custom label or leave it false to keep the default. if more than 2 options, label all options

        },
        [2] = { -- down
            poly = { coords = vector3(3540.74, 3675.59, 28.11), heading = 172.5, length = 2, width = 2 },
            allowVeh = false,
            label = false
        }
    },
    [2] = { --Coke Processing Enter/Exit
        [1] = {
            poly = { coords = vector3(909.49, -1589.22, 30.51), heading = 92.24, length = 2, width = 2 },
            allowVeh = false,
            label = '[E] Enter Coke Processing'
        },
        [2] = {
            poly = { coords = vector3(1088.81, -3187.57, -38.99), heading = 181.7, length = 2, width = 2 },
            allowVeh = false,
            label = '[E] Leave'
        }
    }
}

Config.CarWash = {
    dirtLevel = 0.1,                                                                                   -- threshold for the dirt level to be counted as dirty
    defaultPrice = 20,                                                                                 -- default price for the carwash
    locations = {
        [1] = { coords = vector3(174.81, -1736.77, 28.87), length = 7.0, width = 8.8, heading = 359 }, -- South Los Santos Carson Avenue
        [2] = { coords = vector3(25.2, -1391.98, 28.91), length = 6.6, width = 8.2, heading = 0 },     -- South Los Santos Innocence Boulevard
        [3] = { coords = vector3(-74.27, 6427.72, 31.02), length = 9.4, width = 8, heading = 315 },    -- Paleto Bay Boulevard
        [4] = { coords = vector3(1362.69, 3591.81, 34.5), length = 6.4, width = 8, heading = 21 },     -- Sandy Shores
        [5] = { coords = vector3(-699.84, -932.68, 18.59), length = 11.8, width = 5.2, heading = 0 }   -- Little Seoul Gas Station
    }
}
