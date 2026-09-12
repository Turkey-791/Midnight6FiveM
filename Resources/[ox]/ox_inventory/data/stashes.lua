return {
	{
		-- ============================================================================
		-- ★ Midnight6 による変更 (2026-09-12) — coords の1行だけ
		--
		-- このサーバーは inventory:target が未設定(既定 false)なため、ox_inventory は
		-- target ではなく coords にマーカーを出し、半径1.2m で E キーを拾う
		-- (modules/inventory/client.lua の lib.points.new → Utils.nearbyMarker:
		--  point.currentDistance < 1.2 かつ IsControlJustReleased(0, 38))。
		--
		-- 旧値 vec3(452.3, -991.4, 30.7) は、illenium-appearance の警察更衣室
		--   Config.ClothingRooms: coords vector4(454.91, -990.89, 30.69, 193.4)
		--                         size vector3(4,4,4) / rotation 45 の回転ボックス
		-- の境界から 0.21m しか離れていなかった。illenium も独自のポーリングで
		-- IsControlJustReleased(0, 38) を見ている(client/zones.lua の ZonesLoop)ため、
		-- 重なった幅約1m で E を押すと「アウトフィット変更」と「ロッカー」が
		-- 同時に開いていた(AO報告 2026-09-12)。
		--
		-- 下の target.loc はこのロッカー本体の位置としてこのファイルが元から
		-- 持っている値なので、coords をそれに合わせる。これで更衣室ボックスから
		-- 約2.99m 離れるため、E の二重発火が起きなくなる。
		--
		-- ★ ox_inventory を更新すると失われる。
		--   原本: resources/_backup/audit-fixes-20260912/ox_inventory/data/stashes.lua.orig
		-- ============================================================================
		coords = vec3(451.25, -994.28, 30.69), -- Midnight6 2026-09-12: 旧 vec3(452.3, -991.4, 30.7)
		target = {
			loc = vec3(451.25, -994.28, 30.69),
			length = 1.2,
			width = 5.6,
			heading = 0,
			minZ = 29.49,
			maxZ = 32.09,
			label = 'Open personal locker'
		},
		name = 'policelocker',
		label = 'Personal locker',
		owner = true,
		slots = 70,
		weight = 70000,
		groups = shared.police
	},

	{
		coords = vec3(301.3, -600.23, 43.28),
		target = {
			loc = vec3(301.82, -600.99, 43.29),
			length = 0.6,
			width = 1.8,
			heading = 340,
			minZ = 43.34,
			maxZ = 44.74,
			label = 'Open personal locker'
		},
		name = 'emslocker',
		label = 'Personal Locker',
		owner = true,
		slots = 70,
		weight = 70000,
		groups = {['ambulance'] = 0}
	},
}
