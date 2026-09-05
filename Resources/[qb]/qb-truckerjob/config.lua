Config = {}

Config.UseTarget = GetConvar('UseTarget', 'false') == 'true'

Config.TruckerJobTruckDeposit = 125
Config.TruckerJobFixedLocation = false
Config.TruckerJobMaxDrops = 20 -- amount of locations before being forced to return to station to reload
Config.TruckerJobDropPrice = 500
Config.TruckerJobBonus = 20 -- this is a percentage to calculate bonus over 5 deliveries.
Config.TruckerJobPaymentTax = 15

Config.TruckerJobLocations = {
    ["main"] = {
        label = "トラック営業所",
        coords = vector4(153.68, -3211.88, 5.91, 274.5),
    },
    ["vehicle"] = {
        label = "トラック保管場",
        coords = vector4(141.12, -3204.31, 5.85, 267.5),
    },
    -- 2026-09-02 Trucker/Delivery修正: Config.TruckerJobLocations["stores"] が未定義のままだったため、
    -- getNewLocation() が nil値インデックスで確実にクラッシュし、配送車受け取り直後に配送先を
    -- 決定できず、trucker jobが機能していなかった(qb-shops:server:SetShopList が
    -- qb-shops側に実装されておらず、応答が返らないことが原因と判明。詳細はPhase A調査報告を参照)。
    -- ここでは qb-shops/config.lua の Config.Locations に既に定義されている配送先座標(.delivery)を
    -- そのまま静的にコピーして追加した(新規座標は一切考案していない)。qb-shopsのファイルは
    -- 一切変更していない(このリストはqb-truckerjob独自の複製データであり、qb-shopsへの
    -- ランタイム依存はこれにより完全に無くなった)。
    -- 元の内容は変更前バックアップ([_backup]/audit-fixes-2026-09-02/qb-truckerjob/config.lua.orig)を参照。
    ["stores"] = {
        { name = '247supermarket', label = '24/7 スーパーマーケット', coords = vector4(26.45, -1315.51, 29.62, 0.07) },
        { name = '247supermarket2', label = '24/7 スーパーマーケット', coords = vector4(-3047.95, 590.71, 7.62, 19.53) },
        { name = '247supermarket3', label = '24/7 スーパーマーケット', coords = vector4(-3245.76, 1005.25, 12.83, 269.45) },
        { name = '247supermarket4', label = '24/7 スーパーマーケット', coords = vector4(1741.76, 6419.61, 35.04, 6.83) },
        { name = '247supermarket5', label = '24/7 スーパーマーケット', coords = vector4(1963.81, 3750.09, 32.26, 302.46) },
        { name = '247supermarket6', label = '24/7 スーパーマーケット', coords = vector4(541.54, 2663.53, 42.17, 120.51) },
        { name = '247supermarket7', label = '24/7 スーパーマーケット', coords = vector4(2662.19, 3264.95, 55.24, 168.55) },
        { name = '247supermarket8', label = '24/7 スーパーマーケット', coords = vector4(2553.24, 399.73, 108.56, 344.86) },
        { name = '247supermarket9', label = '24/7 スーパーマーケット', coords = vector4(379.97, 357.3, 102.56, 26.42) },
        { name = 'ltdgasoline', label = 'LTD ガソリン', coords = vector4(-40.51, -1747.45, 29.29, 326.39) },
        { name = 'ltdgasoline2', label = 'LTD ガソリン', coords = vector4(-702.89, -917.44, 19.21, 181.96) },
        { name = 'ltdgasoline3', label = 'LTD ガソリン', coords = vector4(-1829.29, 801.49, 138.41, 41.39) },
        { name = 'ltdgasoline4', label = 'LTD ガソリン', coords = vector4(1160.62, -312.06, 69.28, 3.77) },
        { name = 'ltdgasoline5', label = 'LTD ガソリン', coords = vector4(1702.68, 4917.28, 42.22, 139.27) },
        { name = 'robsliquor', label = "Rob's Liquor", coords = vector4(-1226.92, -901.82, 12.28, 213.26) },
        { name = 'robsliquor2', label = "Rob's Liquor", coords = vector4(-1468.29, -387.61, 38.79, 220.13) },
        { name = 'robsliquor3', label = "Rob's Liquor", coords = vector4(-2961.49, 376.25, 15.02, 111.41) },
        { name = 'robsliquor4', label = "Rob's Liquor", coords = vector4(1194.52, 2722.21, 38.62, 9.37) },
        { name = 'robsliquor5', label = "Rob's Liquor", coords = vector4(1129.73, -989.27, 45.97, 280.98) },
        { name = 'hardware', label = 'ハードウェア店', coords = vector4(89.15, -1745.29, 30.09, 315.25) },
        { name = 'hardware2', label = 'ハードウェア店', coords = vector4(2704.68, 3457.21, 55.54, 176.28) },
        { name = 'hardware3', label = 'ハードウェア店', coords = vector4(-438.25, 6146.9, 31.48, 136.99) },
        { name = 'ammunation', label = 'アミュネーション', coords = vector4(-660.61, -938.14, 21.83, 167.22) },
        { name = 'ammunation2', label = 'アミュネーション', coords = vector4(820.97, -2146.7, 28.71, 359.98) },
        { name = 'ammunation3', label = 'アミュネーション', coords = vector4(1687.17, 3755.47, 34.34, 163.69) },
        { name = 'ammunation4', label = 'アミュネーション', coords = vector4(-341.72, 6098.49, 31.32, 11.05) },
        { name = 'ammunation5', label = 'アミュネーション', coords = vector4(249.0, -50.64, 69.94, 60.71) },
        { name = 'ammunation6', label = 'アミュネーション', coords = vector4(-5.82, -1107.48, 29.0, 164.32) },
        { name = 'ammunation7', label = 'アミュネーション', coords = vector4(2578.77, 285.53, 108.61, 277.2) },
        { name = 'ammunation8', label = 'アミュネーション', coords = vector4(-1127.67, 2708.18, 18.8, 41.76) },
        { name = 'ammunation9', label = 'アミュネーション', coords = vector4(847.83, -1020.36, 27.88, 88.29) },
        { name = 'ammunation10', label = 'アミュネーション', coords = vector4(-1302.44, -385.23, 36.62, 303.79) },
        { name = 'ammunation11', label = 'アミュネーション', coords = vector4(-3183.6, 1084.35, 20.84, 68.13) },
        { name = 'weedshop', label = 'スモーク・オン・ザ・ウォーター', coords = vector4(-1162.13, -1568.57, 4.39, 328.52) },
        { name = 'seaword', label = 'シーワード', coords = vector4(-1674.18, -1073.7, 13.15, 333.56) },
        { name = 'leisureshop', label = 'レジャーショップ', coords = vector4(-1507.64, 1505.52, 115.29, 262.2) },
        { name = 'police', label = '警察署ショップ', coords = vector4(459.0441, -1008.0366, 28.2627, 271.4695) },
        { name = 'ambulance', label = '救急ショップ', coords = vector4(283.5821, -614.8570, 43.3792, 159.2903) },
        { name = 'mechanic', label = 'メカニックショップ', coords = vector4(-354.3936, -128.2882, 39.4307, 251.4931) },
        { name = 'mechanic2', label = 'メカニックショップ', coords = vector4(1189.9852, 2651.1873, 37.8351, 317.7137) },
        { name = 'mechanic3', label = 'メカニックショップ', coords = vector4(-1131.9661, -1972.0144, 13.1603, 358.8637) },
        { name = 'bennys', label = 'メカニックショップ', coords = vector4(-232.5028, -1311.7202, 31.2960, 180.3716) },
        { name = 'beeker', label = 'メカニックショップ', coords = vector4(119.3033, 6626.7358, 31.9558, 46.1566) },
        { name = 'prison', label = '売店', coords = vector4(1845.8175, 2585.9312, 45.6721, 96.7577) },
        { name = 'blackmarket', label = '闇市場', coords = vector4(-428.6385, -1728.1962, 19.7838, 75.6646) },
    },
}

Config.TruckerJobVehicles = {
    ["rumpo"] = {
        ["label"] = "Rumpo 配送バン",
        ["cargodoors"] = {
            [0] = 2,
            [1] = 3
        },
        ["trunkpos"] = 1.5
    },
    ["benson"] = {
        ["label"] = "Benson 配送トラック",
        ["jobrep"] = 0,
        ["cargodoors"] = {
            [0] = 5
        },
        ["trunkpos"] = 3
    },
    ["mule5"] = {
        ["label"] = "Mule 配送トラック",
        ["jobrep"] = 0,
        ["cargodoors"] = {
            [0] = 2,
            [1] = 3
        },
        ["trunkpos"] = 1.5
    },
    ["pounder"] = {
        ["label"] = "Pounder 大型トラック",
        ["jobrep"] = 0,
        ["cargodoors"] = {
            [0] = 2,
            [1] = 3
        },
        ["trunkpos"] = 7
    },
    ["boxville4"] = {
        ["label"] = "Boxville 配送バン",
        ["jobrep"] = 0,
        ["cargodoors"] = {
            [0] = 2,
            [1] = 3
        },
        ["trunkpos"] = 1.5
    },
}