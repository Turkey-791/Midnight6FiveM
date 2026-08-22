QBCore.Shared.ForceJobDefaultDutyAtLogin = true -- true: Force duty state to jobdefaultDuty | false: set duty state from database last saved
QBCore.Shared.Jobs = {
	-- 無職
	unemployed = { label = '市民', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = 'フリーランサー', payment = 10 } } },
	-- バス運転手
	bus = { label = 'バス', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = '運転手', payment = 50 } } },
	-- 裁判官
	judge = { label = '名誉職', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = '裁判官', payment = 100 } } },
	-- 弁護士
	lawyer = { label = '法律事務所', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = 'アソシエイト', payment = 50 } } },
	-- 記者
	reporter = { label = '記者', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = 'ジャーナリスト', payment = 50 } } },
	-- トラッカー
	trucker = { label = 'トラック運転手', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = '運転手', payment = 50 } } },
	-- 牽引業
	tow = { label = '牽引', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = '運転手', payment = 50 } } },
	-- 清掃員
	garbage = { label = '清掃', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = '収集員', payment = 50 } } },
	-- ぶどう園
	vineyard = { label = 'ぶどう園', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = '収穫者', payment = 50 } } },
	-- ホットドッグ販売員
	hotdog = { label = 'ホットドッグ', defaultDuty = true, offDutyPay = false, grades = { ['0'] = { name = '販売員', payment = 50 } } },

	-- 警察
	police = {
		label = '法執行機関',
		type = 'leo',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = '巡査', payment = 75 },
			['2'] = { name = '巡査部長', payment = 100 },
			['3'] = { name = '警部補', payment = 125 },
			['4'] = { name = '署長', isboss = true, payment = 150 },
		},
	},
	-- 救急隊
	ambulance = {
		label = '緊急医療サービス',
		type = 'ems',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = '救急隊員', payment = 75 },
			['2'] = { name = '医師', payment = 100 },
			['3'] = { name = '外科医', payment = 125 },
			['4'] = { name = 'チーフ', isboss = true, payment = 150 },
		},
	},
	-- 不動産
	realestate = {
		label = '不動産',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = '住宅販売員', payment = 75 },
			['2'] = { name = '法人販売員', payment = 100 },
			['3'] = { name = 'ブローカー', payment = 125 },
			['4'] = { name = 'マネージャー', isboss = true, payment = 150 },
		},
	},
	-- タクシー
	taxi = {
		label = 'タクシー',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = '運転手', payment = 75 },
			['2'] = { name = 'イベントドライバー', payment = 100 },
			['3'] = { name = '営業担当', payment = 125 },
			['4'] = { name = 'マネージャー', isboss = true, payment = 150 },
		},
	},
	-- 車ディーラー
	cardealer = {
		label = '車両ディーラー',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = 'ショールーム販売', payment = 75 },
			['2'] = { name = '法人販売', payment = 100 },
			['3'] = { name = '金融担当', payment = 125 },
			['4'] = { name = 'マネージャー', isboss = true, payment = 150 },
		},
	},
	-- メカニック (LS Customs)
	mechanic = {
		label = 'LSカスタムズ',
		type = 'mechanic',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = '見習い', payment = 75 },
			['2'] = { name = '熟練者', payment = 100 },
			['3'] = { name = '上級者', payment = 125 },
			['4'] = { name = 'マネージャー', isboss = true, payment = 150 },
		},
	},
	-- メカニック2 (LS Customs)
	mechanic2 = {
		label = 'LSカスタムズ',
		type = 'mechanic',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = '見習い', payment = 75 },
			['2'] = { name = '熟練者', payment = 100 },
			['3'] = { name = '上級者', payment = 125 },
			['4'] = { name = 'マネージャー', isboss = true, payment = 150 },
		},
	},
	-- メカニック3 (LS Customs)
	mechanic3 = {
		label = 'LSカスタムズ',
		type = 'mechanic',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = '見習い', payment = 75 },
			['2'] = { name = '熟練者', payment = 100 },
			['3'] = { name = '上級者', payment = 125 },
			['4'] = { name = 'マネージャー', isboss = true, payment = 150 },
		},
	},
	-- ビーカース・ガレージ
	beeker = {
		label = 'ビーカース・ガレージ',
		type = 'mechanic',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = '見習い', payment = 75 },
			['2'] = { name = '熟練者', payment = 100 },
			['3'] = { name = '上級者', payment = 125 },
			['4'] = { name = 'マネージャー', isboss = true, payment = 150 },
		},
	},
	-- ベニーズ・オリジナル・モーターワークス
	bennys = {
		label = 'ベニーズ・オリジナル・モーターワークス',
		type = 'mechanic',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
			['0'] = { name = '研修生', payment = 50 },
			['1'] = { name = '見習い', payment = 75 },
			['2'] = { name = '熟練者', payment = 100 },
			['3'] = { name = '上級者', payment = 125 },
			['4'] = { name = 'マネージャー', isboss = true, payment = 150 },
		},
	},
}