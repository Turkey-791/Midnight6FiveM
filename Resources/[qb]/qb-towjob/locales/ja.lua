--[[
FXServer：Ver25770／更新日：2026年4月8日
日本語翻訳：揚げポテGameSV (@agepote_x_info)
当翻訳はFiveMとは関係なく非公認です。
※二次配布及び自作発言禁止
]]--

local Translations = {
    error = {
        finish_work = "先にすべての作業を完了してください",
        vehicle_not_correct = "これは正しい車両ではありません",
        failed = "失敗しました",
        not_towing_vehicle = "牽引車両に乗っている必要があります",
        too_far_away = "離れすぎています",
        no_work_done = "まだ作業をしていません",
        no_deposit = "$%{value}の預り金が必要です",
    },
    success = {
        paid_with_cash = "現金で$%{value}の預り金を支払いました",
        paid_with_bank = "銀行から$%{value}の預り金を支払いました",
        refund_to_cash = "現金で$%{value}の預り金が返金されました",
        you_earned = "$%{value}を獲得しました",
    },
    menu = {
        header = "利用可能なトラック",
        close_menu = "⬅ メニューを閉じる",
    },
    mission = {
        delivered_vehicle = "車両を配達しました",
        get_new_vehicle = "新しい車両を受け取ることができます",
        towing_vehicle = "車両を吊り上げています...",
        goto_depot = "車両をヘイズ車庫に運んでください",
        vehicle_towed = "車両を牽引しました",
        untowing_vehicle = "車両を降ろしてください",
        vehicle_takenoff = "車両を降ろしました",
    },
    info = {
        tow = "あなたのフラットベッドの後ろに車を載せてください",
        toggle_npc = "NPCジョブを切り替える",
        skick = "エクスプロイトの悪用を試みました",
    },
    label = {
        payslip = "給与明細",
        vehicle = "車両",
        npcz = "NPCゾーン",
    }
}

if GetConvar('qb_locale', 'en') == 'ja' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end