Config = {
	Debug = false,
	PickAmount = { min = 8, max = 12 },
	GrapeAmount = { min = 8, max = 12 },
	GrapeJuiceAmount = { min = 6, max = 10 },
	WineAmount = { min = 6, max = 10 },
	wineTimer = 180,
	Vineyard = {
		start = {
			coords = vector3(-1928.81, 2059.53, 140.84),
			zones = {
				vector2(-1926.19, 2059.13),
				vector2(-1925.46, 2062.16),
				vector2(-1930.47, 2063.81),
				vector2(-1931.35, 2060.37),
			},
			minZ = 140.24,
			maxZ = 141.44
		},
		wine = {
			coords = vector3(-1879.54, 2062.55, 135.92),
			zones = {
				vector2(-1873.85, 2063.01),
				vector2(-1876.35, 2059.48),
				vector2(-1883.02, 2062.11),
				vector2(-1882.03, 2064.85),
				vector2(-1880.51, 2065.44)
			},
			minZ = 135.42,
			maxZ = 136.42
		},
		grapejuice = {
			coords = vector3(828.76, 2191.16, 52.37),
			zones = {
				vector2(830.91, 2194.49),
				vector2(827.81, 2196.07),
				vector2(824.6, 2189.71),
				vector2(827.54, 2188.28),
			},
			minZ = 51.85,
			maxZ = 52.74
		}
	}
}

-- ============================================================
-- [2026-09-03 追加] wine納品(換金)報酬 -- 作業報酬システム
-- QBCore基本給(qb-core/shared/jobs.lua の vineyard.grades[].payment)とは
-- 別枠の、実際にワインを納品した際の報酬。金額は仮値であり、
-- Midnight6全体の経済設計確定後に本Configの値のみを変更して調整する。
-- 詳細は resources/vineyard_newsjob_reward_implementation_2026-09-03.md を参照。
-- ============================================================
Config.WineSellPrice = 100    -- wine 1個を納品した際の報酬(仮値・最終決定ではない)
Config.WineSellRadius = 15.0  -- 納品(売却)を受け付ける、ワインゾーン中心からの許容距離(m)

-- ============================================================
-- [2026-09-04 追加] ジョブ受注(入社)ドア + 求人マップブリップ
--
-- 既存のStartゾーン(シフト開始地点)の建物入口を、そのまま
-- 「まだvineyard jobではないプレイヤーがEキーで応募する場所」としても使う。
-- 新しいゾーンは追加せず、既存Startゾーンのクライアント側ロジックを拡張する形で
-- 実装している(qb-vineyard/client.lua の Zones[1] を参照)。
-- ============================================================
Config.JobDoor = {
	coords = Config.Vineyard.start.coords, -- Startゾーンと同じ建物入口を使用
	radius = 5.0,                          -- サーバー側で受注を受け付ける距離(m)。PolyZone判定より少し広めに余裕を持たせている
}

Config.JobBlip = {
	enabled = true,
	sprite = 827, -- ご指定のスプライトID
	color = 69,   -- 黄緑(Lime/Yellow-Green相当。未確認・実機で見た目が違えば数値を変更してください。近い候補: 5=黄, 2=緑)
	scale = 0.8,
	label = 'ぶどう園 求人',
}
