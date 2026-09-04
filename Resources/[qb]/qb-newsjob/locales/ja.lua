--[[
FXServer：Ver25770／更新日：2026年4月8日
日本語翻訳：揚げポテGameSV (@agepote_x_info)
当翻訳はFiveMとは関係なく非公認です。
※二次配布及び自作発言禁止
]]--

local Translations = {
    text = {
        weazle_overlay = "WEAZELオーバーレイ ~INPUT_PICKUP~ \n映像オーバーレイ: ~INPUT_INTERACTION_MENU~",
        weazel_news_vehicles = "WEAZEL News車両",
        close_menu = "⬅ メニューを閉じる",
        weazel_news_helicopters = "WEAZEL Newsヘリコプター",
        store_vehicle = "~g~E~w~ - 車両を保管する",
        vehicles = "~g~E~w~ - 車両",
        store_helicopters = "~g~E~w~ - ヘリコプターを保管する",
        helicopters = "~g~E~w~ - ヘリコプター",
        enter = "~g~E~w~ - 入る",
        go_outside = "~g~E~w~ - 外に出る",
        breaking_news = "速報ニュース",
        title_breaking_news = "午前7時 / 今日のWEAZEL News独占",
        bottom_breaking_news = "発生中の最新ニュースをライブでお届けします",
        assignment_blip = "取材地点",
    },
    error = {
        not_on_duty = "勤務中のみ利用できます",
        assignment_in_progress = "既に取材案件が進行中です",
        no_assignment = "進行中の取材案件がありません。/newsassignment で依頼を受けてください",
        too_far_from_assignment = "取材地点から離れすぎています",
    },
    success = {
        assignment_started = "取材依頼を受けました: %{label}",
        assignment_completed = "取材を納品し、$%{value}を受け取りました",
    },
    task = {
        start_report = "[E] 取材する",
        cancel_task = "作業をキャンセルしました",
    },
    progress = {
        reporting = "取材・撮影しています ..",
    },
}

if GetConvar('qb_locale', 'en') == 'ja' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
