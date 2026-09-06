--[[
FXServer：Ver25770／更新日：2026年4月8日
日本語翻訳：揚げポテGameSV (@agepote_x_info)
当翻訳はFiveMとは関係なく非公認です。
※二次配布及び自作発言禁止
]]--

local Translations = {
    afk = {
        will_kick = 'あなたは離席中です。',
        time_seconds = ' 秒後にキックされます！',
        time_minutes = ' 分後にキックされます！',
        kick_message = '離席中のためキックされました'
    },
    wash = {
        in_progress = "車両を洗車中です...",
        wash_vehicle = "[E] 車両を洗車する",
        wash_vehicle_target = "車両を洗車する",
        dirty = "車両は汚れていません",
        cancel = "洗車をキャンセルしました..."
    },
    consumables = {
        eat_progress = "食事中です...",
        drink_progress = "飲んでいます...",
        liqour_progress = "お酒を飲んでいます...",
        coke_progress = "軽く嗅いでいます...",
        crack_progress = "クラックを吸っています...",
        ecstasy_progress = "ピルを飲んでいます",
        healing_progress = "回復中です",
        meth_progress = "アスメスを吸っています",
        joint_progress = "ジョイントに火をつけています...",
        cigarette_progress = "タバコを吸っています...",
        handrolled_cigarette_progress = "手巻きタバコを吸っています...",
        use_parachute_progress = "パラシュートを装着しています...",
        pack_parachute_progress = "パラシュートをたたんでいます...",
        no_parachute = "パラシュートを持っていません！",
        armor_full = "すでに十分なアーマーを装着しています！",
        armor_empty = "ベストを着用していません...",
        armor_progress = "ボディアーマーを装着しています...",
        heavy_armor_progress = "ボディアーマーを装着しています...",
        remove_armor_progress = "ボディアーマーを外しています...",
        canceled = "キャンセルしました..."
    },
    cruise = {
        unavailable = "クルーズコントロールは利用できません",
        activated = "クルーズコントロールを起動しました",
        deactivated = "クルーズコントロールを解除しました",
        not_Enough_Fuel = "燃料が足りない"
    },
    editor = {
        started = "録画を開始しました！",
        save = "録画を保存しました！",
        delete = "録画を削除しました！",
        editor = "後でな、ワニさん！"
    },
    firework = {
        place_progress = "花火を設置中です...",
        canceled = "キャンセルしました...",
        time_left = "花火の打ち上げまで残り~r~"
    },
    seatbelt = {
        use_harness_progress = "レーシングハーネスを装着しています",
        remove_harness_progress = "レーシングハーネスを外しています",
        no_car = "車に乗っていません。"
    },
    teleport = {
        teleport_default = 'エレベーターを使用する'
    },
    pushcar = {
        stop_push = "[E] 押すのをやめる",
        notDamaged = "車両は押すほど損傷していない！"
    }
}

if GetConvar('qb_locale', 'en') == 'ja' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end