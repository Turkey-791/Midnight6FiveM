return {
	['testburger'] = {
		label = 'Test Burger',
		weight = 220,
		degrade = 60,
		client = {
			image = 'burger_chicken.png',
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			export = 'ox_inventory_examples.testburger'
		},
		server = {
			export = 'ox_inventory_examples.testburger',
			test = 'what an amazingly delicious burger, amirite?'
		},
		buttons = {
			{
				label = 'Lick it',
				action = function(slot)
					print('You licked the burger')
				end
			},
			{
				label = 'Squeeze it',
				action = function(slot)
					print('You squeezed the burger :(')
				end
			},
			{
				label = 'What do you call a vegan burger?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('A misteak.')
				end
			},
			{
				label = 'What do frogs like to eat with their hamburgers?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('French flies.')
				end
			},
			{
				label = 'Why were the burger and fries running?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('Because they\'re fast food.')
				end
			}
		},
		consume = 0.3
	},

	['bandage'] = {
		label = 'Bandage',
		weight = 115,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500,
		}
	},

	['black_money'] = {
		label = 'Dirty Money',
	},

	['burger'] = {
		label = 'Burger',
		weight = 220,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a delicious burger'
		},
	},

	['sprunk'] = {
		label = 'Sprunk',
		weight = 350,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a sprunk'
		}
	},

	['parachute'] = {
		label = 'Parachute',
		weight = 8000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 1500
		}
	},

	['garbage'] = {
		label = 'Garbage',
	},

	['paperbag'] = {
		label = 'Paper Bag',
		weight = 1,
		stack = false,
		close = false,
		consume = 0
	},

	['identification'] = {
		label = 'Identification',
		client = {
			image = 'card_id.png'
		}
	},

	['panties'] = {
		label = 'Knickers',
		weight = 10,
		consume = 0,
		client = {
			status = { thirst = -100000, stress = -25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
			usetime = 2500,
		}
	},

	['lockpick'] = {
		label = 'Lockpick',
		weight = 160,
	},

	['phone'] = {
		label = 'Phone',
		weight = 190,
		stack = false,
		consume = 0,
		client = {
			add = function(total)
				if total > 0 then
					pcall(function() return exports.npwd:setPhoneDisabled(false) end)
				end
			end,

			remove = function(total)
				if total < 1 then
					pcall(function() return exports.npwd:setPhoneDisabled(true) end)
				end
			end
		}
	},

	['money'] = {
		label = 'Money',
	},

	['mustard'] = {
		label = 'Mustard',
		weight = 500,
		client = {
			status = { hunger = 25000, thirst = 25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
			usetime = 2500,
			notification = 'You.. drank mustard'
		}
	},

	['water'] = {
		label = 'Water',
		weight = 500,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			cancel = true,
			notification = 'You drank some refreshing water'
		}
	},

	['radio'] = {
		label = 'Radio',
		weight = 1000,
		stack = false,
		allowArmed = true
	},

	['armour'] = {
		label = 'Bulletproof Vest',
		weight = 3000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500
		}
	},

	['clothing'] = {
		label = 'Clothing',
		consume = 0,
	},

	['mastercard'] = {
		label = 'Fleeca Card',
		stack = false,
		weight = 10,
		client = {
			image = 'card_bank.png'
		}
	},

	['scrapmetal'] = {
		label = 'Scrap Metal',
		weight = 80,
	},

	-- ===== Auto-imported from qb-core/shared/items.lua (missing items) =====

	['clip_attachment'] = {
		label = 'Clip',
		weight = 1000,
		description = 'A clip for a weapon',
		client = { image = 'clip_attachment.png' },
	},
	['drum_attachment'] = {
		label = 'Drum',
		weight = 1000,
		description = 'A drum for a weapon',
		client = { image = 'drum_attachment.png' },
	},
	['flashlight_attachment'] = {
		label = 'Flashlight',
		weight = 1000,
		description = 'A flashlight for a weapon',
		client = { image = 'flashlight_attachment.png' },
	},
	['suppressor_attachment'] = {
		label = 'Suppressor',
		weight = 1000,
		description = 'A suppressor for a weapon',
		client = { image = 'suppressor_attachment.png' },
	},
	['smallscope_attachment'] = {
		label = 'Small Scope',
		weight = 1000,
		description = 'A small scope for a weapon',
		client = { image = 'smallscope_attachment.png' },
	},
	['medscope_attachment'] = {
		label = 'Medium Scope',
		weight = 1000,
		description = 'A medium scope for a weapon',
		client = { image = 'medscope_attachment.png' },
	},
	['largescope_attachment'] = {
		label = 'Large Scope',
		weight = 1000,
		description = 'A large scope for a weapon',
		client = { image = 'largescope_attachment.png' },
	},
	['holoscope_attachment'] = {
		label = 'Holo Scope',
		weight = 1000,
		description = 'A holo scope for a weapon',
		client = { image = 'holoscope_attachment.png' },
	},
	['advscope_attachment'] = {
		label = 'Advanced Scope',
		weight = 1000,
		description = 'An advanced scope for a weapon',
		client = { image = 'advscope_attachment.png' },
	},
	['nvscope_attachment'] = {
		label = 'Night Vision Scope',
		weight = 1000,
		description = 'A night vision scope for a weapon',
		client = { image = 'nvscope_attachment.png' },
	},
	['thermalscope_attachment'] = {
		label = 'Thermal Scope',
		weight = 1000,
		description = 'A thermal scope for a weapon',
		client = { image = 'thermalscope_attachment.png' },
	},
	['flat_muzzle_brake'] = {
		label = 'Flat Muzzle Brake',
		weight = 1000,
		description = 'A muzzle brake for a weapon',
		client = { image = 'flat_muzzle_brake.png' },
	},
	['tactical_muzzle_brake'] = {
		label = 'Tactical Muzzle Brake',
		weight = 1000,
		description = 'A muzzle brakee for a weapon',
		client = { image = 'tactical_muzzle_brake.png' },
	},
	['fat_end_muzzle_brake'] = {
		label = 'Fat End Muzzle Brake',
		weight = 1000,
		description = 'A muzzle brake for a weapon',
		client = { image = 'fat_end_muzzle_brake.png' },
	},
	['precision_muzzle_brake'] = {
		label = 'Precision Muzzle Brake',
		weight = 1000,
		description = 'A muzzle brake for a weapon',
		client = { image = 'precision_muzzle_brake.png' },
	},
	['heavy_duty_muzzle_brake'] = {
		label = 'HD Muzzle Brake',
		weight = 1000,
		description = 'A muzzle brake for a weapon',
		client = { image = 'heavy_duty_muzzle_brake.png' },
	},
	['slanted_muzzle_brake'] = {
		label = 'Slanted Muzzle Brake',
		weight = 1000,
		description = 'A muzzle brake for a weapon',
		client = { image = 'slanted_muzzle_brake.png' },
	},
	['split_end_muzzle_brake'] = {
		label = 'Split End Muzzle Brake',
		weight = 1000,
		description = 'A muzzle brake for a weapon',
		client = { image = 'split_end_muzzle_brake.png' },
	},
	['squared_muzzle_brake'] = {
		label = 'Squared Muzzle Brake',
		weight = 1000,
		description = 'A muzzle brake for a weapon',
		client = { image = 'squared_muzzle_brake.png' },
	},
	['bellend_muzzle_brake'] = {
		label = 'Bellend Muzzle Brake',
		weight = 1000,
		description = 'A muzzle brake for a weapon',
		client = { image = 'bellend_muzzle_brake.png' },
	},
	['barrel_attachment'] = {
		label = 'Barrel',
		weight = 1000,
		description = 'A barrel for a weapon',
		client = { image = 'barrel_attachment.png' },
	},
	['grip_attachment'] = {
		label = 'Grip',
		weight = 1000,
		description = 'A grip for a weapon',
		client = { image = 'grip_attachment.png' },
	},
	['comp_attachment'] = {
		label = 'Compensator',
		weight = 1000,
		description = 'A compensator for a weapon',
		client = { image = 'comp_attachment.png' },
	},
	['luxuryfinish_attachment'] = {
		label = 'Luxury Finish',
		weight = 1000,
		description = 'A luxury finish for a weapon',
	},
	['digicamo_attachment'] = {
		label = 'Digital Camo',
		weight = 1000,
		description = 'A digital camo for a weapon',
		client = { image = 'digicamo_attachment.png' },
	},
	['brushcamo_attachment'] = {
		label = 'Brushstroke Camo',
		weight = 1000,
		description = 'A brushstroke camo for a weapon',
		client = { image = 'brushcamo_attachment.png' },
	},
	['wood'] = {
    	label = 'Wood',
    	weight = 1000,
    	stack = true,
    	close = true,
    	description = '木材',
	},
	['wood_pro'] = {
   	 label = 'Processed Wood',
		weight = 1000,
		stack = true,
		close = true,
		description = '加工された木材',
	},
	['woodcamo_attachment'] = {
		label = 'Woodland Camo',
		weight = 1000,
		description = 'A woodland camo for a weapon',
		client = { image = 'woodcamo_attachment.png' },
	},
	['skullcamo_attachment'] = {
		label = 'Skull Camo',
		weight = 1000,
		description = 'A skull camo for a weapon',
		client = { image = 'skullcamo_attachment.png' },
	},
	['sessantacamo_attachment'] = {
		label = 'Sessanta Nove Camo',
		weight = 1000,
		description = 'A sessanta nove camo for a weapon',
		client = { image = 'sessantacamo_attachment.png' },
	},
	['perseuscamo_attachment'] = {
		label = 'Perseus Camo',
		weight = 1000,
		description = 'A perseus camo for a weapon',
		client = { image = 'perseuscamo_attachment.png' },
	},
	['leopardcamo_attachment'] = {
		label = 'Leopard Camo',
		weight = 1000,
		description = 'A leopard camo for a weapon',
		client = { image = 'leopardcamo_attachment.png' },
	},
	['zebracamo_attachment'] = {
		label = 'Zebra Camo',
		weight = 1000,
		description = 'A zebra camo for a weapon',
		client = { image = 'zebracamo_attachment.png' },
	},
	['geocamo_attachment'] = {
		label = 'Geometric Camo',
		weight = 1000,
		description = 'A geometric camo for a weapon',
		client = { image = 'geocamo_attachment.png' },
	},
	['boomcamo_attachment'] = {
		label = 'Boom Camo',
		weight = 1000,
		description = 'A boom camo for a weapon',
		client = { image = 'boomcamo_attachment.png' },
	},
	['patriotcamo_attachment'] = {
		label = 'Patriot Camo',
		weight = 1000,
		description = 'A patriot camo for a weapon',
		client = { image = 'patriotcamo_attachment.png' },
	},
	['weapontint_0'] = {
		label = 'Default Tint',
		weight = 1000,
		description = 'Default/Black Weapon Tint',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_1'] = {
		label = 'Green Tint',
		weight = 1000,
		description = 'Green Weapon Tint',
		client = { image = 'weapontint_green.png' },
	},
	['weapontint_2'] = {
		label = 'Gold Tint',
		weight = 1000,
		description = 'Gold Weapon Tint',
		client = { image = 'weapontint_gold.png' },
	},
	['weapontint_3'] = {
		label = 'Pink Tint',
		weight = 1000,
		description = 'Pink Weapon Tint',
		client = { image = 'weapontint_pink.png' },
	},
	['weapontint_4'] = {
		label = 'Army Tint',
		weight = 1000,
		description = 'Army Weapon Tint',
		client = { image = 'weapontint_army.png' },
	},
	['weapontint_5'] = {
		label = 'LSPD Tint',
		weight = 1000,
		description = 'LSPD Weapon Tint',
		client = { image = 'weapontint_lspd.png' },
	},
	['weapontint_6'] = {
		label = 'Orange Tint',
		weight = 1000,
		description = 'Orange Weapon Tint',
		client = { image = 'weapontint_orange.png' },
	},
	['weapontint_7'] = {
		label = 'Platinum Tint',
		weight = 1000,
		description = 'Platinum Weapon Tint',
		client = { image = 'weapontint_plat.png' },
	},
	['weapontint_mk2_0'] = {
		label = 'Classic Black Tint',
		weight = 1000,
		description = 'Classic Black Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_1'] = {
		label = 'Classic Gray Tint',
		weight = 1000,
		description = 'Classic Gray Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_2'] = {
		label = 'Classic Two-Tone Tint',
		weight = 1000,
		description = 'Classic Two-Tone Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_3'] = {
		label = 'Classic White Tint',
		weight = 1000,
		description = 'Classic White Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_4'] = {
		label = 'Classic Beige Tint',
		weight = 1000,
		description = 'Classic Beige Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_5'] = {
		label = 'Classic Green Tint',
		weight = 1000,
		description = 'Classic Green Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_6'] = {
		label = 'Classic Blue Tint',
		weight = 1000,
		description = 'Classic Blue Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_7'] = {
		label = 'Classic Earth Tint',
		weight = 1000,
		description = 'Classic Earth Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_8'] = {
		label = 'Classic Brown & Black Tint',
		weight = 1000,
		description = 'Classic Brown & Black Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_9'] = {
		label = 'Red Contrast Tint',
		weight = 1000,
		description = 'Red Contrast Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_10'] = {
		label = 'Blue Contrast Tint',
		weight = 1000,
		description = 'Blue Contrast Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_11'] = {
		label = 'Yellow Contrast Tint',
		weight = 1000,
		description = 'Yellow Contrast Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_12'] = {
		label = 'Orange Contrast Tint',
		weight = 1000,
		description = 'Orange Contrast Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_13'] = {
		label = 'Bold Pink Tint',
		weight = 1000,
		description = 'Bold Pink Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_14'] = {
		label = 'Bold Purple & Yellow Tint',
		weight = 1000,
		description = 'Bold Purple & Yellow Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_15'] = {
		label = 'Bold Orange Tint',
		weight = 1000,
		description = 'Bold Orange Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_16'] = {
		label = 'Bold Green & Purple Tint',
		weight = 1000,
		description = 'Bold Green & Purple Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_17'] = {
		label = 'Bold Red Features Tint',
		weight = 1000,
		description = 'Bold Red Features Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_18'] = {
		label = 'Bold Green Features Tint',
		weight = 1000,
		description = 'Bold Green Features Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_19'] = {
		label = 'Bold Cyan Features Tint',
		weight = 1000,
		description = 'Bold Cyan Features Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_20'] = {
		label = 'Bold Yellow Features Tint',
		weight = 1000,
		description = 'Bold Yellow Features Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_21'] = {
		label = 'Bold Red & White Tint',
		weight = 1000,
		description = 'Bold Red & White Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_22'] = {
		label = 'Bold Blue & White Tint',
		weight = 1000,
		description = 'Bold Blue & White Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_23'] = {
		label = 'Metallic Gold Tint',
		weight = 1000,
		description = 'Metallic Gold Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_24'] = {
		label = 'Metallic Platinum Tint',
		weight = 1000,
		description = 'Metallic Platinum Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_25'] = {
		label = 'Metallic Gray & Lilac Tint',
		weight = 1000,
		description = 'Metallic Gray & Lilac Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_26'] = {
		label = 'Metallic Purple & Lime Tint',
		weight = 1000,
		description = 'Metallic Purple & Lime Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_27'] = {
		label = 'Metallic Red Tint',
		weight = 1000,
		description = 'Metallic Red Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_28'] = {
		label = 'Metallic Green Tint',
		weight = 1000,
		description = 'Metallic Green Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_29'] = {
		label = 'Metallic Blue Tint',
		weight = 1000,
		description = 'Metallic Blue Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_30'] = {
		label = 'Metallic White & Aqua Tint',
		weight = 1000,
		description = 'Metallic White & Aqua Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_31'] = {
		label = 'Metallic Orange & Yellow Tint',
		weight = 1000,
		description = 'Metallic Orange & Yellow Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['weapontint_mk2_32'] = {
		label = 'Metallic Red and Yellow Tint',
		weight = 1000,
		description = 'Metallic Red and Yellow Weapon Tint for MK2 Weapons',
		client = { image = 'weapontint_black.png' },
	},
	['pistol_ammo'] = {
		label = 'Pistol ammo',
		weight = 200,
		description = 'Ammo for Pistols',
		client = { image = 'pistol_ammo.png' },
	},
	['rifle_ammo'] = {
		label = 'Rifle ammo',
		weight = 1000,
		description = 'Ammo for Rifles',
		client = { image = 'rifle_ammo.png' },
	},
	['smg_ammo'] = {
		label = 'SMG ammo',
		weight = 500,
		description = 'Ammo for Sub Machine Guns',
		client = { image = 'smg_ammo.png' },
	},
	['shotgun_ammo'] = {
		label = 'Shotgun ammo',
		weight = 500,
		description = 'Ammo for Shotguns',
		client = { image = 'shotgun_ammo.png' },
	},
	['mg_ammo'] = {
		label = 'MG ammo',
		weight = 1000,
		description = 'Ammo for Machine Guns',
		client = { image = 'mg_ammo.png' },
	},
	['snp_ammo'] = {
		label = 'Sniper ammo',
		weight = 1000,
		description = 'Ammo for Sniper Rifles',
		client = { image = 'rifle_ammo.png' },
	},
	['emp_ammo'] = {
		label = 'EMP Ammo',
		weight = 200,
		description = 'Ammo for EMP Launcher',
	},
	['id_card'] = {
		label = 'ID Card',
		weight = 0,
		description = 'A card containing all your information to identify yourself',
		client = { image = 'id_card.png' },
	},
	['driver_license'] = {
		label = 'Drivers License',
		weight = 0,
		description = 'Permit to show you can drive a vehicle',
		client = { image = 'driver_license.png' },
	},
	['lawyerpass'] = {
		label = 'Lawyer Pass',
		weight = 0,
		description = 'Pass exclusive to lawyers to show they can represent a suspect',
		client = { image = 'lawyerpass.png' },
	},
	['weaponlicense'] = {
		label = 'Weapon License',
		weight = 0,
		description = 'Weapon License',
		client = { image = 'weapon_license.png' },
	},
	['bank_card'] = {
		label = 'Bank Card',
		weight = 0,
		description = 'Used to access ATM',
		client = { image = 'bank_card.png' },
	},
	['security_card_01'] = {
		label = 'Security Card A',
		weight = 0,
		description = 'A security card... I wonder what it goes to',
		client = { image = 'security_card_01.png' },
	},
	['security_card_02'] = {
		label = 'Security Card B',
		weight = 0,
		description = 'A security card... I wonder what it goes to',
		client = { image = 'security_card_02.png' },
	},
	['tosti'] = {
		label = 'Grilled Cheese Sandwich',
		weight = 200,
		description = 'Nice to eat',
		client = { image = 'tosti.png' },
	},
	['twerks_candy'] = {
		label = 'Twerks',
		weight = 100,
		description = 'Some delicious candy :O',
		client = { image = 'twerks_candy.png' },
	},
	['snikkel_candy'] = {
		label = 'Snikkel',
		weight = 100,
		description = 'Some delicious candy :O',
		client = { image = 'snikkel_candy.png' },
	},
	['sandwich'] = {
		label = 'Sandwich',
		weight = 200,
		description = 'Nice bread for your stomach',
		client = { image = 'sandwich.png' },
	},
	['water_bottle'] = {
		label = 'Bottle of Water',
		weight = 500,
		description = 'For all the thirsty out there',
		client = { image = 'water_bottle.png' },
	},
	['coffee'] = {
		label = 'Coffee',
		weight = 200,
		description = 'Pump 4 Caffeine',
		client = { image = 'coffee.png' },
	},
	['kurkakola'] = {
		label = 'Cola',
		weight = 500,
		description = 'For all the thirsty out there',
		client = { image = 'cola.png' },
	},
	['beer'] = {
		label = 'Beer',
		weight = 500,
		description = 'Nothing like a good cold beer!',
		client = { image = 'beer.png' },
	},
	['whiskey'] = {
		label = 'Whiskey',
		weight = 500,
		description = 'For all the thirsty out there',
		client = { image = 'whiskey.png' },
	},
	['vodka'] = {
		label = 'Vodka',
		weight = 500,
		description = 'For all the thirsty out there',
		client = { image = 'vodka.png' },
	},
	['grape'] = {
		label = 'Grape',
		weight = 100,
		description = 'Mmmmh yummie, grapes',
		client = { image = 'grape.png' },
	},
	['wine'] = {
		label = 'Wine',
		weight = 300,
		description = 'Some good wine to drink on a fine evening',
		client = { image = 'wine.png' },
	},
	['grapejuice'] = {
		label = 'Grape Juice',
		weight = 200,
		description = 'Grape juice is said to be healthy',
		client = { image = 'grapejuice.png' },
	},
	['joint'] = {
		label = 'Joint',
		weight = 0,
		description = 'Sidney would be very proud at you',
		client = { image = 'joint.png' },
	},
	['cokebaggy'] = {
		label = 'Bag of Coke',
		weight = 0,
		description = 'To get happy real quick',
		client = { image = 'cocaine_baggy.png' },
	},
	['crack_baggy'] = {
		label = 'Bag of Crack',
		weight = 0,
		description = 'To get happy faster',
		client = { image = 'crack_baggy.png' },
	},
	['xtcbaggy'] = {
		label = 'Bag of XTC',
		weight = 0,
		description = 'Pop those pills baby',
		client = { image = 'xtc_baggy.png' },
	},
	['coke_brick'] = {
		label = 'Coke Brick',
		weight = 1000,
		description = 'Heavy package of cocaine, mostly used for deals and takes a lot of space',
		client = { image = 'coke_brick.png' },
	},
	['weed_brick'] = {
		label = 'Weed Brick',
		weight = 1000,
		description = '1KG Weed Brick to sell to large customers.',
		client = { image = 'weed_brick.png' },
	},
	['coke_small_brick'] = {
		label = 'Coke Package',
		weight = 350,
		description = 'Small package of cocaine, mostly used for deals and takes a lot of space',
		client = { image = 'coke_small_brick.png' },
	},
	['oxy'] = {
		label = 'Prescription Oxy',
		weight = 0,
		description = 'The Label Has Been Ripped Off',
		client = { image = 'oxy.png' },
	},
	['meth'] = {
		label = 'Meth',
		weight = 100,
		description = 'A baggie of Meth',
		client = { image = 'meth_baggy.png' },
	},
	['rolling_paper'] = {
		label = 'Rolling Paper',
		weight = 0,
		description = 'Paper made specifically for encasing and smoking tobacco or cannabis.',
		client = { image = 'rolling_paper.png' },
	},
	['weed_whitewidow'] = {
		label = 'White Widow 2g',
		weight = 200,
		description = 'A weed bag with 2g White Widow',
		client = { image = 'weed_baggy.png' },
	},
	['weed_skunk'] = {
		label = 'Skunk 2g',
		weight = 200,
		description = 'A weed bag with 2g Skunk',
		client = { image = 'weed_baggy.png' },
	},
	['weed_purplehaze'] = {
		label = 'Purple Haze 2g',
		weight = 200,
		description = 'A weed bag with 2g Purple Haze',
		client = { image = 'weed_baggy.png' },
	},
	['weed_ogkush'] = {
		label = 'OGKush 2g',
		weight = 200,
		description = 'A weed bag with 2g OG Kush',
		client = { image = 'weed_baggy.png' },
	},
	['weed_amnesia'] = {
		label = 'Amnesia 2g',
		weight = 200,
		description = 'A weed bag with 2g Amnesia',
		client = { image = 'weed_baggy.png' },
	},
	['weed_ak47'] = {
		label = 'AK47 2g',
		weight = 200,
		description = 'A weed bag with 2g AK47',
		client = { image = 'weed_baggy.png' },
	},
	['weed_whitewidow_seed'] = {
		label = 'White Widow Seed',
		weight = 0,
		description = 'A weed seed of White Widow',
		client = { image = 'weed_seed.png' },
	},
	['weed_skunk_seed'] = {
		label = 'Skunk Seed',
		weight = 0,
		description = 'A weed seed of Skunk',
		client = { image = 'weed_seed.png' },
	},
	['weed_purplehaze_seed'] = {
		label = 'Purple Haze Seed',
		weight = 0,
		description = 'A weed seed of Purple Haze',
		client = { image = 'weed_seed.png' },
	},
	['weed_ogkush_seed'] = {
		label = 'OGKush Seed',
		weight = 0,
		description = 'A weed seed of OG Kush',
		client = { image = 'weed_seed.png' },
	},
	['weed_amnesia_seed'] = {
		label = 'Amnesia Seed',
		weight = 0,
		description = 'A weed seed of Amnesia',
		client = { image = 'weed_seed.png' },
	},
	['weed_ak47_seed'] = {
		label = 'AK47 Seed',
		weight = 0,
		description = 'A weed seed of AK47',
		client = { image = 'weed_seed.png' },
	},
	['empty_weed_bag'] = {
		label = 'Empty Weed Bag',
		weight = 0,
		description = 'A small empty bag',
		client = { image = 'weed_baggy_empty.png' },
	},
	['weed_nutrition'] = {
		label = 'Plant Fertilizer',
		weight = 2000,
		description = 'Plant nutrition',
		client = { image = 'weed_nutrition.png' },
	},
	['plastic'] = {
		label = 'Plastic',
		weight = 100,
		description = 'RECYCLE! - Greta Thunberg 2019',
		client = { image = 'plastic.png' },
	},
	['metalscrap'] = {
		label = 'Metal Scrap',
		weight = 100,
		description = 'You can probably make something nice out of this',
		client = { image = 'metalscrap.png' },
	},
	['copper'] = {
		label = 'Copper',
		weight = 100,
		description = 'Nice piece of metal that you can probably use for something',
		client = { image = 'copper.png' },
	},
	['aluminum'] = {
		label = 'Aluminium',
		weight = 100,
		description = 'Nice piece of metal that you can probably use for something',
		client = { image = 'aluminum.png' },
	},
	['aluminumoxide'] = {
		label = 'Aluminium Powder',
		weight = 100,
		description = 'Some powder to mix with',
		client = { image = 'aluminumoxide.png' },
	},
	['iron'] = {
		label = 'Iron',
		weight = 100,
		description = 'Handy piece of metal that you can probably use for something',
		client = { image = 'iron.png' },
	},
	['ironoxide'] = {
		label = 'Iron Powder',
		weight = 100,
		description = 'Some powder to mix with.',
		client = { image = 'ironoxide.png' },
	},
	['steel'] = {
		label = 'Steel',
		weight = 100,
		description = 'Nice piece of metal that you can probably use for something',
		client = { image = 'steel.png' },
	},
	['rubber'] = {
		label = 'Rubber',
		weight = 100,
		description = 'Rubber, I believe you can make your own rubber ducky with it :D',
		client = { image = 'rubber.png' },
	},
	['glass'] = {
		label = 'Glass',
		weight = 100,
		description = 'It is very fragile, watch out',
		client = { image = 'glass.png' },
	},
	['advancedlockpick'] = {
		label = 'Advanced Lockpick',
		weight = 500,
		description = 'If you lose your keys a lot this is very useful... Also useful to open your beers',
		client = { image = 'advancedlockpick.png' },
	},
	['electronickit'] = {
		label = 'Electronic Kit',
		weight = 100,
		description = 'If you\'ve always wanted to build a robot you can maybe start here. Maybe you\'ll be the new Elon Musk?',
		client = { image = 'electronickit.png' },
	},
	['gatecrack'] = {
		label = 'Gatecrack',
		weight = 0,
		description = 'Handy software to tear down some fences',
		client = { image = 'usb_device.png' },
	},
	['thermite'] = {
		label = 'Thermite',
		weight = 1000,
		description = 'Sometimes you\'d wish for everything to burn',
		client = { image = 'thermite.png' },
	},
	['trojan_usb'] = {
		label = 'Trojan USB',
		weight = 0,
		description = 'Handy software to shut down some systems',
		client = { image = 'usb_device.png' },
	},
	['screwdriverset'] = {
		label = 'Toolkit',
		weight = 1000,
		description = 'Very useful to screw... screws...',
		client = { image = 'screwdriverset.png' },
	},
	['drill'] = {
		label = 'Drill',
		weight = 20000,
		description = 'The real deal...',
		client = { image = 'drill.png' },
	},
	['nitrous'] = {
		label = 'Nitrous',
		weight = 1000,
		description = 'Speed up, gas pedal! :D',
		client = { image = 'nitrous.png' },
	},
	['repairkit'] = {
		label = 'Repairkit',
		weight = 2500,
		description = 'A nice toolbox with stuff to repair your vehicle',
		client = { image = 'repairkit.png' },
	},
	['advancedrepairkit'] = {
		label = 'Advanced Repairkit',
		weight = 4000,
		description = 'A nice toolbox with stuff to repair your vehicle',
		client = { image = 'advancedkit.png' },
	},
	['cleaningkit'] = {
		label = 'Cleaning Kit',
		weight = 250,
		description = 'A microfiber cloth with some soap will let your car sparkle again!',
		client = { image = 'cleaningkit.png' },
	},
	['tunerlaptop'] = {
		label = 'Tunerchip',
		weight = 2000,
		description = 'With this tunerchip you can get your car on steroids... If you know what you\'re doing',
		client = { image = 'tunerchip.png' },
	},
	['harness'] = {
		label = 'Race Harness',
		weight = 1000,
		description = 'Racing Harness so no matter what you stay in the car',
		client = { image = 'harness.png' },
	},
	['jerry_can'] = {
		label = 'Jerrycan 20L',
		weight = 20000,
		description = 'A can full of Fuel',
		client = { image = 'jerry_can.png' },
	},
	['tirerepairkit'] = {
		label = 'Tire Repair Kit',
		weight = 1000,
		description = 'A kit to repair your tires',
		client = { image = 'tirerepairkit.png' },
	},
	['veh_toolbox'] = {
		label = 'Toolbox',
		weight = 1000,
		description = 'Check vehicle status',
		client = { image = 'veh_toolbox.png' },
	},
	['veh_armor'] = {
		label = 'Armor',
		weight = 1000,
		description = 'Upgrade vehicle armor',
		client = { image = 'veh_armor.png' },
	},
	['veh_brakes'] = {
		label = 'Brakes',
		weight = 1000,
		description = 'Upgrade vehicle brakes',
		client = { image = 'veh_brakes.png' },
	},
	['veh_engine'] = {
		label = 'Engine',
		weight = 1000,
		description = 'Upgrade vehicle engine',
		client = { image = 'veh_engine.png' },
	},
	['veh_suspension'] = {
		label = 'Suspension',
		weight = 1000,
		description = 'Upgrade vehicle suspension',
		client = { image = 'veh_suspension.png' },
	},
	['veh_transmission'] = {
		label = 'Transmission',
		weight = 1000,
		description = 'Upgrade vehicle transmission',
		client = { image = 'veh_transmission.png' },
	},
	['veh_turbo'] = {
		label = 'Turbo',
		weight = 1000,
		description = 'Install vehicle turbo',
		client = { image = 'veh_turbo.png' },
	},
	['veh_interior'] = {
		label = 'Interior',
		weight = 1000,
		description = 'Upgrade vehicle interior',
		client = { image = 'veh_interior.png' },
	},
	['veh_exterior'] = {
		label = 'Exterior',
		weight = 1000,
		description = 'Upgrade vehicle exterior',
		client = { image = 'veh_exterior.png' },
	},
	['veh_wheels'] = {
		label = 'Wheels',
		weight = 1000,
		description = 'Upgrade vehicle wheels',
		client = { image = 'veh_wheels.png' },
	},
	['veh_neons'] = {
		label = 'Neons',
		weight = 1000,
		description = 'Upgrade vehicle neons',
		client = { image = 'veh_neons.png' },
	},
	['veh_xenons'] = {
		label = 'Xenons',
		weight = 1000,
		description = 'Upgrade vehicle xenons',
		client = { image = 'veh_xenons.png' },
	},
	['veh_tint'] = {
		label = 'Tints',
		weight = 1000,
		description = 'Install vehicle tint',
		client = { image = 'veh_tint.png' },
	},
	['veh_plates'] = {
		label = 'Plates',
		weight = 1000,
		description = 'Install vehicle plates',
		client = { image = 'veh_plates.png' },
	},
	['firstaid'] = {
		label = 'First Aid',
		weight = 2500,
		description = 'You can use this First Aid kit to get people back on their feet',
		client = { image = 'firstaid.png' },
	},
	['ifaks'] = {
		label = 'ifaks',
		weight = 200,
		description = 'ifaks for healing and a complete stress remover.',
		client = { image = 'ifaks.png' },
	},
	['painkillers'] = {
		label = 'Painkillers',
		weight = 0,
		description = 'For pain you can\'t stand anymore, take this pill that\'d make you feel great again',
		client = { image = 'painkillers.png' },
	},
	['walkstick'] = {
		label = 'Walking Stick',
		weight = 1000,
		description = 'Walking stick for ya\'ll grannies out there.. HAHA',
		client = { image = 'walkstick.png' },
	},
	['iphone'] = {
		label = 'iPhone',
		weight = 1000,
		description = 'Very expensive phone',
		client = { image = 'iphone.png' },
	},
	['samsungphone'] = {
		label = 'Samsung S10',
		weight = 1000,
		description = 'Very expensive phone',
		client = { image = 'samsungphone.png' },
	},
	['laptop'] = {
		label = 'Laptop',
		weight = 4000,
		description = 'Expensive laptop',
		client = { image = 'laptop.png' },
	},
	['tablet'] = {
		label = 'Tablet',
		weight = 2000,
		description = 'Expensive tablet',
		client = { image = 'tablet.png' },
	},
	['fitbit'] = {
		label = 'Fitbit',
		weight = 500,
		description = 'I like fitbit',
		client = { image = 'fitbit.png' },
	},
	['radioscanner'] = {
		label = 'Radio Scanner',
		weight = 1000,
		description = 'With this you can get some police alerts. Not 100% effective however',
		client = { image = 'radioscanner.png' },
	},
	['pinger'] = {
		label = 'Pinger',
		weight = 1000,
		description = 'With a pinger and your phone you can send out your location',
		client = { image = 'pinger.png' },
	},
	['cryptostick'] = {
		label = 'Crypto Stick',
		weight = 200,
		description = 'Why would someone ever buy money that doesn\'t exist.. How many would it contain..?',
		client = { image = 'cryptostick.png' },
	},
	['rolex'] = {
		label = 'Golden Watch',
		weight = 1500,
		description = 'A golden watch seems like the jackpot to me!',
		client = { image = 'rolex.png' },
	},
	['diamond_ring'] = {
		label = 'Diamond Ring',
		weight = 1500,
		description = 'A diamond ring seems like the jackpot to me!',
		client = { image = 'diamond_ring.png' },
	},
	['diamond'] = {
		label = 'Diamond',
		weight = 1000,
		description = 'A diamond seems like the jackpot to me!',
	},
	['goldchain'] = {
		label = 'Golden Chain',
		weight = 1500,
		description = 'A golden chain seems like the jackpot to me!',
		client = { image = 'goldchain.png' },
	},
	['tenkgoldchain'] = {
		label = '10k Gold Chain',
		weight = 2000,
		description = '10 carat golden chain',
		client = { image = '10kgoldchain.png' },
	},
	['goldbar'] = {
		label = 'Gold Bar',
		weight = 7000,
		description = 'Looks pretty expensive to me',
		client = { image = 'goldbar.png' },
	},
	['armor'] = {
		label = 'Armor',
		weight = 5000,
		description = 'Some protection won\'t hurt... right?',
		client = { image = 'armor.png' },
	},
	['heavyarmor'] = {
		label = 'Heavy Armor',
		weight = 5000,
		description = 'Some protection won\'t hurt... right?',
		client = { image = 'armor.png' },
	},
	['handcuffs'] = {
		label = 'Handcuffs',
		weight = 100,
		description = 'Comes in handy when people misbehave. Maybe it can be used for something else?',
		client = { image = 'handcuffs.png' },
	},
	['police_stormram'] = {
		label = 'Stormram',
		weight = 18000,
		description = 'A nice tool to break into doors',
		client = { image = 'police_stormram.png' },
	},
	['empty_evidence_bag'] = {
		label = 'Empty Evidence Bag',
		weight = 0,
		description = 'Used a lot to keep DNA from blood, bullet shells and more',
		client = { image = 'evidence.png' },
	},
	['filled_evidence_bag'] = {
		label = 'Evidence Bag',
		weight = 200,
		description = 'A filled evidence bag to see who committed the crime >:(',
		client = { image = 'evidence.png' },
	},
	['firework1'] = {
		label = '2Brothers',
		weight = 1000,
		description = 'Fireworks',
		client = { image = 'firework1.png' },
	},
	['firework2'] = {
		label = 'Poppelers',
		weight = 1000,
		description = 'Fireworks',
		client = { image = 'firework2.png' },
	},
	['firework3'] = {
		label = 'WipeOut',
		weight = 1000,
		description = 'Fireworks',
		client = { image = 'firework3.png' },
	},
	['firework4'] = {
		label = 'Weeping Willow',
		weight = 1000,
		description = 'Fireworks',
		client = { image = 'firework4.png' },
	},
	['dendrogyra_coral'] = {
		label = 'Dendrogyra',
		weight = 1000,
		description = 'Its also known as pillar coral',
		client = { image = 'dendrogyra_coral.png' },
	},
	['antipatharia_coral'] = {
		label = 'Antipatharia',
		weight = 1000,
		description = 'Its also known as black corals or thorn corals',
		client = { image = 'antipatharia_coral.png' },
	},
	['diving_gear'] = {
		label = 'Diving Gear',
		weight = 30000,
		description = 'An oxygen tank and a rebreather',
		client = { image = 'diving_gear.png' },
	},
	['diving_fill'] = {
		label = 'Diving Tube',
		weight = 3000,
		description = 'An oxygen tube and a rebreather',
		client = { image = 'diving_tube.png' },
	},
	['casinochips'] = {
		label = 'Casino Chips',
		weight = 0,
		description = 'Chips For Casino Gambling',
		client = { image = 'casinochips.png' },
	},
	['wheeltoken'] = {
		label = 'Lucky Wheel Token',
		weight = 100,
		description = 'Lucky Wheel Token',
		client = { image = 'token.png' },
	},
	['stickynote'] = {
		label = 'Sticky note',
		weight = 0,
		description = 'Sometimes handy to remember something :)',
		client = { image = 'stickynote.png' },
	},
	['moneybag'] = {
		label = 'Money Bag',
		weight = 0,
		description = 'A bag with cash',
		client = { image = 'moneybag.png' },
	},
	['binoculars'] = {
		label = 'Binoculars',
		weight = 600,
		description = 'Sneaky Breaky...',
		client = { image = 'binoculars.png' },
	},
	['lighter'] = {
		label = 'Lighter',
		weight = 0,
		description = 'On new years eve a nice fire to stand next to',
		client = { image = 'lighter.png' },
	},
	['certificate'] = {
		label = 'Certificate',
		weight = 0,
		description = 'Certificate that proves you own certain stuff',
		client = { image = 'certificate.png' },
	},
	['markedbills'] = {
		label = 'Marked Money',
		weight = 1000,
		description = 'Money?',
		client = { image = 'markedbills.png' },
	},
	['labkey'] = {
		label = 'Key',
		weight = 500,
		description = 'Key for a lock...?',
		client = { image = 'labkey.png' },
	},
	['printerdocument'] = {
		label = 'Document',
		weight = 500,
		description = 'A nice document',
		client = { image = 'printerdocument.png' },
	},
	['newscam'] = {
		label = 'News Camera',
		weight = 100,
		description = 'A camera for the news',
		client = { image = 'newscam.png' },
	},
	['newsmic'] = {
		label = 'News Microphone',
		weight = 100,
		description = 'A microphone for the news',
		client = { image = 'newsmic.png' },
	},
	['newsbmic'] = {
		label = 'Boom Microphone',
		weight = 100,
		description = 'A Useable BoomMic',
		client = { image = 'newsbmic.png' },
	},
	['item_bench'] = {
		label = 'item_bench',
		weight = 15000,
	},
	['attachment_bench'] = {
		label = 'attachment_bench',
		weight = 15000,
	},
}
