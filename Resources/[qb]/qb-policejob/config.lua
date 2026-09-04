Config = {}
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true'
Config.MaxSpikes = 5
Config.HandCuffItem = 'handcuffs'
Config.LicenseRank = 2
Config.ArmoryWhitelist = {}
Config.WhitelistedVehicles = {}
Config.PoliceHelicopter = 'POLMAV'
Config.FuelResource = 'LegacyFuel' -- supports any that has a GetFuel() and SetFuel() export

Config.AmmoLabels = {
    AMMO_PISTOL = '9x19mmパラベラム弾',
    AMMO_SMG = '9x19mmパラベラム弾',
    AMMO_RIFLE = '7.62x39mm弾',
    AMMO_MG = '7.92x57mmモーゼル弾',
    AMMO_SHOTGUN = '12ゲージ弾',
    AMMO_SNIPER = '大口径弾',
}

Config.Objects = {
    cone = { model = `prop_roadcone02a`, freeze = false },
    barrier = { model = `prop_barrier_work06a`, freeze = true },
    roadsign = { model = `prop_snow_sign_road_06g`, freeze = true },
    tent = { model = `prop_gazebo_03`, freeze = true },
    light = { model = `prop_worklight_03b`, freeze = true },
}

Config.Locations = {
    duty = {
        vector3(440.085, -974.924, 30.689),
        vector3(-449.811, 6012.909, 31.815),
    },
    vehicle = {
        vector4(448.159, -1017.41, 28.562, 90.654),
        vector4(471.13, -1024.05, 28.17, 274.5),
        vector4(-455.39, 6002.02, 31.34, 87.93),
    },
    stash = {
        vector3(453.075, -980.124, 30.889),
    },
    impound = {
        vector3(436.68, -1007.42, 27.32),
        vector3(-436.14, 5982.63, 31.34),
    },
    helicopter = {
        vector4(449.168, -981.325, 43.691, 87.234),
        vector4(-475.43, 5988.353, 31.716, 31.34),
    },
    trash = {
        vector3(439.0907, -976.746, 30.776),
    },
    fingerprint = {
        vector3(460.9667, -989.180, 24.92),
    },
    evidence = {
        vector3(442.1722, -996.067, 30.689),
        vector3(451.7031, -973.232, 30.689),
        vector3(455.1456, -985.462, 30.689),
    },
    stations = {
        { label = '警察署',        coords = vector4(428.23, -984.28, 29.76, 3.5) },
        { label = '刑務所',                coords = vector4(1845.903, 2585.873, 45.672, 272.249) },
        { label = 'パレト警察署', coords = vector4(-451.55, 6014.25, 31.716, 223.81) },
    },
}

Config.SecurityCameras = {
    hideradar = false,
    cameras = {
        [1] = { label = 'パシフィック銀行 CAM#1', coords = vector3(257.45, 210.07, 109.08), r = { x = -25.0, y = 0.0, z = 28.05 }, canRotate = false, isOnline = true },
        [2] = { label = 'パシフィック銀行 CAM#2', coords = vector3(232.86, 221.46, 107.83), r = { x = -25.0, y = 0.0, z = -140.91 }, canRotate = false, isOnline = true },
        [3] = { label = 'パシフィック銀行 CAM#3', coords = vector3(252.27, 225.52, 103.99), r = { x = -35.0, y = 0.0, z = -74.87 }, canRotate = false, isOnline = true },
        [4] = { label = 'リミテッドリミテッド グローブストリート CAM#1', coords = vector3(-53.1433, -1746.714, 31.546), r = { x = -35.0, y = 0.0, z = -168.9182 }, canRotate = false, isOnline = true },
        [5] = { label = "ロブのリカー プロスペリティストリート CAM#1", coords = vector3(-1482.9, -380.463, 42.363), r = { x = -35.0, y = 0.0, z = 79.53281 }, canRotate = false, isOnline = true },
        [6] = { label = "ロブのリカー サンアンドレアスアベニュー CAM#1", coords = vector3(-1224.874, -911.094, 14.401), r = { x = -35.0, y = 0.0, z = -6.778894 }, canRotate = false, isOnline = true },
        [7] = { label = 'リミテッドリミテッド ジンジャーストリート CAM#1', coords = vector3(-718.153, -909.211, 21.49), r = { x = -35.0, y = 0.0, z = -137.1431 }, canRotate = false, isOnline = true },
        [8] = { label = '24/7スーパーマーケット イノセンスブールバード CAM#1', coords = vector3(23.885, -1342.441, 31.672), r = { x = -35.0, y = 0.0, z = -142.9191 }, canRotate = false, isOnline = true },
        [9] = { label = "ロブのリカー エルランチョブールバード CAM#1", coords = vector3(1133.024, -978.712, 48.515), r = { x = -35.0, y = 0.0, z = -137.302 }, canRotate = false, isOnline = true },
        [10] = { label = 'リミテッドリミテッド ウェストミラードライブ CAM#1', coords = vector3(1151.93, -320.389, 71.33), r = { x = -35.0, y = 0.0, z = -119.4468 }, canRotate = false, isOnline = true },
        [11] = { label = '24/7スーパーマーケット クリントンアベニュー CAM#1', coords = vector3(383.402, 328.915, 105.541), r = { x = -35.0, y = 0.0, z = 118.585 }, canRotate = false, isOnline = true },
        [12] = { label = 'リミテッドリミテッド バンハムキャニオンドライブ CAM#1', coords = vector3(-1832.057, 789.389, 140.436), r = { x = -35.0, y = 0.0, z = -91.481 }, canRotate = false, isOnline = true },
        [13] = { label = "ロブのリカー グレートオーシャンハイウェイ CAM#1", coords = vector3(-2966.15, 387.067, 17.393), r = { x = -35.0, y = 0.0, z = 32.92229 }, canRotate = false, isOnline = true },
        [14] = { label = '24/7スーパーマーケット イネセーノロード CAM#1', coords = vector3(-3046.749, 592.491, 9.808), r = { x = -35.0, y = 0.0, z = -116.673 }, canRotate = false, isOnline = true },
        [15] = { label = '24/7スーパーマーケット バルバレノロード CAM#1', coords = vector3(-3246.489, 1010.408, 14.705), r = { x = -35.0, y = 0.0, z = -135.2151 }, canRotate = false, isOnline = true },
        [16] = { label = '24/7スーパーマーケット ルート68 CAM#1', coords = vector3(539.773, 2664.904, 44.056), r = { x = -35.0, y = 0.0, z = -42.947 }, canRotate = false, isOnline = true },
        [17] = { label = "ロブのリカー ルート68 CAM#1", coords = vector3(1169.855, 2711.493, 40.432), r = { x = -35.0, y = 0.0, z = 127.17 }, canRotate = false, isOnline = true },
        [18] = { label = '24/7スーパーマーケット セノーラ高速道路 CAM#1', coords = vector3(2673.579, 3281.265, 57.541), r = { x = -35.0, y = 0.0, z = -80.242 }, canRotate = false, isOnline = true },
        [19] = { label = '24/7スーパーマーケット アランブラドライブ CAM#1', coords = vector3(1966.24, 3749.545, 34.143), r = { x = -35.0, y = 0.0, z = 163.065 }, canRotate = false, isOnline = true },
        [20] = { label = '24/7スーパーマーケット セノーラ高速道路 CAM#2', coords = vector3(1729.522, 6419.87, 37.262), r = { x = -35.0, y = 0.0, z = -160.089 }, canRotate = false, isOnline = true },
        [21] = { label = 'フリーサ銀行 ホーウィックアベニュー CAM#1', coords = vector3(309.341, -281.439, 55.88), r = { x = -35.0, y = 0.0, z = -146.1595 }, canRotate = false, isOnline = true },
        [22] = { label = 'フリーサ銀行 リージョンスクエア CAM#1', coords = vector3(144.871, -1043.044, 31.017), r = { x = -35.0, y = 0.0, z = -143.9796 }, canRotate = false, isOnline = true },
        [23] = { label = 'フリーサ銀行 ホーウィックアベニュー CAM#2', coords = vector3(-355.7643, -52.506, 50.746), r = { x = -35.0, y = 0.0, z = -143.8711 }, canRotate = false, isOnline = true },
        [24] = { label = 'フリーサ銀行 デルペロブールバード CAM#1', coords = vector3(-1214.226, -335.86, 39.515), r = { x = -35.0, y = 0.0, z = -97.862 }, canRotate = false, isOnline = true },
        [25] = { label = 'フリーサ銀行 グレートオーシャンハイウェイ CAM#1', coords = vector3(-2958.885, 478.983, 17.406), r = { x = -35.0, y = 0.0, z = -34.69595 }, canRotate = false, isOnline = true },
        [26] = { label = 'パレト銀行 CAM#1', coords = vector3(-102.939, 6467.668, 33.424), r = { x = -35.0, y = 0.0, z = 24.66 }, canRotate = false, isOnline = true },
        [27] = { label = 'デルベッキオリカー パレト湾', coords = vector3(-163.75, 6323.45, 33.424), r = { x = -35.0, y = 0.0, z = 260.00 }, canRotate = false, isOnline = true },
        [28] = { label = "ドンのカントリーストア パレト湾 CAM#1", coords = vector3(166.42, 6634.4, 33.69), r = { x = -35.0, y = 0.0, z = 32.00 }, canRotate = false, isOnline = true },
        [29] = { label = "ドンのカントリーストア パレト湾 CAM#2", coords = vector3(163.74, 6644.34, 33.69), r = { x = -35.0, y = 0.0, z = 168.00 }, canRotate = false, isOnline = true },
        [30] = { label = "ドンのカントリーストア パレト湾 CAM#3", coords = vector3(169.54, 6640.89, 33.69), r = { x = -35.0, y = 0.0, z = 5.78 }, canRotate = false, isOnline = true },
        [31] = { label = 'ヴァンジエリコ宝石店 CAM#1', coords = vector3(-627.54, -239.74, 40.33), r = { x = -35.0, y = 0.0, z = 5.78 }, canRotate = true, isOnline = true },
        [32] = { label = 'ヴァンジエリコ宝石店 CAM#2', coords = vector3(-627.51, -229.51, 40.24), r = { x = -35.0, y = 0.0, z = -95.78 }, canRotate = true, isOnline = true },
        [33] = { label = 'ヴァンジエリコ宝石店 CAM#3', coords = vector3(-620.3, -224.31, 40.23), r = { x = -35.0, y = 0.0, z = 165.78 }, canRotate = true, isOnline = true },
        [34] = { label = 'ヴァンジエリコ宝石店 CAM#4', coords = vector3(-622.57, -236.3, 40.31), r = { x = -35.0, y = 0.0, z = 5.78 }, canRotate = true, isOnline = true },
    },
}

Config.EnableRadars = true -- フラグ付きナンバープレートのアラートを有効にする
Config.Radars = {
    vector3(1051.42, 331.11, 84.00),
    vector3(544.43, -373.24, 33.14),
    vector3(-2612.10, 2940.81, 16.67),
    vector3(287.94, -517.44, 42.89),
    vector3(2792.73, 4407.68, 48.44),
    vector3(577.11, -1028.32, 37.07),
    vector3(114.83, -797.89, 30.97),
    vector3(74.33, -163.30, 54.67),
    vector3(28.19, -971.05, 28.96),
}

Config.CarItems = {
    [1] = { name = 'heavyarmor', amount = 2, info = {}, type = 'item', slot = 1, },
    [2] = { name = 'empty_evidence_bag', amount = 10, info = {}, type = 'item', slot = 2, },
    [3] = { name = 'police_stormram', amount = 1, info = {}, type = 'item', slot = 3, },
}

Config.AuthorizedVehicles = {
    -- Grade 0 and higher
    [0] = {
        police = 'パトカー 1',
        police2 = 'パトカー 2',
        police3 = 'パトカー 3',
        police4 = 'パトカー 4',
        policeb = 'パトカー 5',
        policet = 'パトカー 6',
        sheriff = 'シェリフカー 1',
        sheriff2 = 'シェリフカー 2',
    },
}

Config.VehicleSettings = {
    ['car1'] = {          --- モデル名
        ['extras'] = {
            ['1'] = true, -- オン/オフ
            ['2'] = true,
            ['3'] = true,
            ['4'] = true,
            ['5'] = true,
            ['6'] = true,
            ['7'] = true,
            ['8'] = true,
            ['9'] = true,
            ['10'] = true,
            ['11'] = true,
            ['12'] = true,
            ['13'] = true,
        },
        ['livery'] = 1,
    },
    ['car2'] = {
        ['extras'] = {
            ['1'] = true,
            ['2'] = true,
            ['3'] = true,
            ['4'] = true,
            ['5'] = true,
            ['6'] = true,
            ['7'] = true,
            ['8'] = true,
            ['9'] = true,
            ['10'] = true,
            ['11'] = true,
            ['12'] = true,
            ['13'] = true,
        },
        ['livery'] = 1,
    }
}