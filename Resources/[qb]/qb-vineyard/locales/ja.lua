--[[
FXServer：Ver25770／更新日：2026年4月8日
日本語翻訳：揚げポテGameSV (@agepote_x_info)
当翻訳はFiveMとは関係なく非公認です。
※二次配布及び自作発言禁止
]]--

local Translations = {
    error = {
        ["invalid_job"] = "ここで働いているとは思えません...",
        ["invalid_items"] = "必要なアイテムがありません！",
        ["no_items"] = "アイテムを持っていません！",
        ["wine_not_ready"] = "ワインはまだ完成していません...",
        ["too_far_to_sell"] = "納品場所から離れすぎています",
        ["no_wine"] = "納品できるワインを持っていません",
        ["not_on_duty"] = "勤務中のみ利用できます",
        ["already_employed"] = "すでにこの仕事に就いています",
        ["too_far_to_apply"] = "受付(建物入口)から離れすぎています",
    },
    progress = {
        ["pick_grapes"] = "ブドウを収穫しています ..",
        ["process_grapes"] = "ブドウを加工しています ..",
    },
    task = {
        ["start_task"] = "[E] 開始",
        ["load_ingrediants"] = "[E] 材料を積み込む",
        ["wine_process"] = "[E] ワイン作りを開始",
        ["get_wine"] = "[E] ワインを手に入れる",
        ["make_grape_juice"] = "[E] ブドウジュースを作る",
        ["countdown"] = "残り時間 %{time}秒",
        ['cancel_task'] = "タスクをキャンセルしました",
        ["sell_wine"] = "[G] ワインを納品する",
        ["apply_job"] = "[E] 求人に応募する",
    },
    text = {
        ["start_shift"] = "ブドウ園でのシフトが開始されました！",
        ["end_shift"] = "ブドウ園でのシフトが終了しました！",
        ["valid_zone"] = "有効なゾーンです！",
        ["invalid_zone"] = "無効なゾーンです！",
        ["zone_entered"] = "%{zone}ゾーンに入りました",
        ["zone_exited"] = "%{zone}ゾーンから出ました",
    },
    success = {
        ["wine_sold"] = "ワインを納品し、$%{value}を受け取りました",
        ["job_applied"] = "ぶどう園の仕事に就きました！",
    },
}

if GetConvar('qb_locale', 'en') == 'ja' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
