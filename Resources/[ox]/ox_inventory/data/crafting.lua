-- Midnight6: qb-crafting -> ox_inventory Crafting migration (Phase 1).
--
-- The 'debug_crafting' sample bench (lockpick only, using ox_inventory's
-- sample 'scrapmetal' item) has been replaced by the two real benches below,
-- which reproduce qb-crafting's item_bench/attachment_bench recipes exactly
-- (same completed items, same ingredient item names/amounts - metalscrap,
-- not scrapmetal - so nothing else on the server needs to change).
--
-- XP-gated unlocking, the pre-craft skill check (Tier 3/4 recipes only),
-- and the "forfeit materials on skill-check failure" penalty are NOT
-- implemented here - ox_inventory's core crafting module has no such
-- concepts and is not modified. They are implemented entirely in the
-- separate '[midnight6-custom]/ox-crafting-ext' resource via
-- exports.ox_inventory:registerHook('craftItem', ...), which this file
-- and this module do not need to know about.
--
-- item_bench uses the same two locations (and blip) that 'debug_crafting'
-- used, since that is the crafting bench players are already used to.
-- attachment_bench is a new location (did not exist before - qb-crafting's
-- attachment_bench had no fixed location, it was placed by hand via item).
return {
	{
		name = 'item_bench',
		items = {
			{
				name = 'lockpick',
				ingredients = { metalscrap = 22, plastic = 32 },
				duration = 2500,
				count = 1,
			},
			{
				name = 'screwdriverset',
				ingredients = { metalscrap = 30, plastic = 42 },
				duration = 2800,
				count = 1,
			},
			{
				name = 'electronickit',
				ingredients = { metalscrap = 30, plastic = 45, aluminum = 28 },
				duration = 3100,
				count = 1,
			},
			{
				name = 'radioscanner',
				ingredients = { electronickit = 2, plastic = 52, steel = 40 },
				duration = 3400,
				count = 1,
			},
			{
				name = 'gatecrack',
				ingredients = { metalscrap = 10, plastic = 50, aluminum = 30, iron = 17, electronickit = 2 },
				duration = 3700,
				count = 1,
			},
			{
				name = 'handcuffs',
				ingredients = { metalscrap = 36, steel = 24, aluminum = 28 },
				duration = 4000,
				count = 1,
			},
			{
				name = 'repairkit',
				ingredients = { metalscrap = 32, steel = 43, plastic = 61 },
				duration = 4300,
				count = 1,
			},
			{
				name = 'ammo-9', -- was pistol_ammo
				ingredients = { metalscrap = 50, steel = 37, copper = 26 },
				duration = 4600,
				count = 1,
			},
			{
				name = 'ironoxide',
				ingredients = { iron = 60, glass = 30 },
				duration = 4900,
				count = 1,
			},
			{
				name = 'aluminumoxide',
				ingredients = { aluminum = 60, glass = 30 },
				duration = 4900,
				count = 1,
			},
			{
				name = 'armor',
				ingredients = { iron = 33, steel = 44, plastic = 55, aluminum = 22 },
				duration = 5200,
				count = 1,
			},
			{
				name = 'drill',
				ingredients = { iron = 50, steel = 50, screwdriverset = 3, advancedlockpick = 2 },
				duration = 6000,
				count = 1,
			},
		},
		points = {
			vec3(-1147.083008, -2002.662109, 13.180260),
			vec3(-345.374969, -130.687088, 39.009613)
		},
		zones = {
			{
				coords = vec3(-1146.2, -2002.05, 13.2),
				size = vec3(3.8, 1.05, 0.15),
				distance = 1.5,
				rotation = 315.0,
			},
			{
				coords = vec3(-346.1, -130.45, 39.0),
				size = vec3(3.8, 1.05, 0.15),
				distance = 1.5,
				rotation = 70.0,
			},
		},
		blip = { id = 566, colour = 31, scale = 0.8 },
	},
	{
		name = 'attachment_bench',
		items = {
			{
				name = 'clip_attachment',
				ingredients = { metalscrap = 140, steel = 250, rubber = 60 },
				duration = 4500,
				count = 1,
			},
			{
				name = 'suppressor_attachment',
				ingredients = { metalscrap = 165, steel = 285, rubber = 75 },
				duration = 5000,
				count = 1,
			},
			{
				name = 'drum_attachment',
				ingredients = { metalscrap = 230, steel = 365, rubber = 130 },
				duration = 5800,
				count = 1,
			},
			{
				name = 'smallscope_attachment',
				ingredients = { metalscrap = 255, steel = 390, rubber = 145 },
				duration = 6200,
				count = 1,
			},
		},
		-- Confirmed location (AO, in-game): inside the weapon shop building,
		-- no loading-screen/interior transition at this spot, so it's on the
		-- persistent open-world map exactly like item_bench's points - no
		-- special interior handling needed. No blip requested for this bench.
		points = {
			vec3(827.18, -2158.39, 29.62)
		},
		zones = {
			{
				coords = vec3(827.18, -2158.39, 29.62),
				size = vec3(3.8, 1.05, 0.15),
				distance = 1.5,
				rotation = 70.0,
			},
		},
	},
}
