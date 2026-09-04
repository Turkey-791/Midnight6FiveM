Config = {}

Config.UseableItems = true -- Set to false if you want to use commands instead of usable items

Config.Locations = {
    ['main'] = {
        coords = vector4(-597.89, -929.95, 24.0, 271.5),
    },
    ['inside'] = {
        coords = vector4(-77.46, -833.77, 243.38, 67.5),
    },
    ['outside'] = {
        coords = vector4(-598.25, -929.86, 23.86, 86.5),
    },
    ['vehicle'] = {
        coords = vector4(-552.24, -925.61, 23.86, 242.5),
        vehicles = {
            [0] = {
                ['rumpo'] = { label = 'Rumpo', modLivery = 2 },
            },
            [1] = {
                ['rumpo'] = { label = 'Rumpo', modLivery = 2 },
            },
            [2] = {
                ['rumpo'] = { label = 'Rumpo', modLivery = 2 },
            },
            [3] = {
                ['rumpo'] = { label = 'Rumpo', modLivery = 2 },
            },
            [4] = {
                ['rumpo'] = { label = 'Rumpo', modLivery = 2 },
            },
        },
    },
    ['heli'] = {
        coords = vector4(-583.08, -930.55, 36.83, 89.26),
        vehicles = {
            [0] = {
                ['frogger'] = { label = 'Frogger' },
                ['conada'] = { label = 'Conada', modLivery = 5 },
            },
            [1] = {
                ['frogger'] = { label = 'Frogger' },
                ['conada'] = { label = 'Conada', modLivery = 5 },
            },
            [2] = {
                ['frogger'] = { label = 'Frogger' },
                ['conada'] = { label = 'Conada', modLivery = 5 },
            },
            [3] = {
                ['frogger'] = { label = 'Frogger' },
                ['conada'] = { label = 'Conada', modLivery = 5 },
            },
            [4] = {
                ['frogger'] = { label = 'Frogger' },
                ['conada'] = { label = 'Conada', modLivery = 5 },
            },
        },
    }
}

Config.VehicleItems = {
    [1] = {
        name = 'newscam',
        amount = 1,
        info = {},
    },
    [2] = {
        name = 'newsmic',
        amount = 1,
        info = {},
    },
    [3] = {
        name = 'newsbmic',
        amount = 1,
        info = {},
    },
}

-- ============================================================
-- [2026-09-03 追加] 取材案件・作業報酬システム
-- QBCore基本給(qb-core/shared/jobs.lua の reporter.grades[].payment)とは
-- 別枠の、実際に取材を完了した際の報酬。金額・座標は仮値であり、
-- Midnight6全体の経済設計確定後に本Configの値のみを変更して調整する。
-- 詳細は resources/vineyard_newsjob_reward_implementation_2026-09-03.md を参照。
-- ============================================================
Config.NewsReward = 150 -- 取材1件を完了した際の報酬(仮値・最終決定ではない)
Config.NewsReportRadius = 15.0 -- 取材完了(サーバー側)を受け付ける、取材地点からの許容距離(m)
Config.NewsReportTime = { min = 8000, max = 12000 } -- 撮影プログレスバーの所要時間(ms)

-- 取材地点(仮の座標。実機で侵入可否・障害物の有無を確認のうえ調整すること)
Config.NewsLocations = {
    { coords = vector3(195.62, -933.53, 30.68), label = 'レジオン・スクエア' },
    { coords = vector3(441.62, -981.7, 30.68), label = 'ミッションロウ署前' },
    { coords = vector3(-1850.99, -1232.4, 13.02), label = 'デルペロ埠頭' },
    { coords = vector3(-1197.68, -1531.85, 4.36), label = 'ヴェスパッチ・ビーチ' },
    { coords = vector3(731.61, 1195.27, 359.29), label = 'ヴィンウッドサイン展望地' },
}
