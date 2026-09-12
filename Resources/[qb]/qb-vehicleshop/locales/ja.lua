--[[
FXServer：Ver25770／更新日：2026年4月8日
日本語翻訳：揚げポテGameSV (@agepote_x_info)
当翻訳はFiveMとは関係なく非公認です。
※二次配布及び自作発言禁止
]]--

local Translations = {
    error = {
        testdrive_alreadyin = "すでに試乗中です",
        testdrive_return = "これはあなたの試乗車ではありません",
        Invalid_ID = "無効なプレイヤーIDが指定されました",
        playertoofar = "このプレイヤーは近くにいません",
        notenoughmoney = "お金が足りません",
        minimumallowed = "最低支払額は$%{value}です",
        overpaid = "払いすぎです",
        alreadypaid = "車両はすでに支払い済みです",
        notworth = "車両にはそこまでの価値がありません",
        downtoosmall = "頭金が少なすぎます",
        exceededmax = "最大支払額を超えました",
        repossessed = "ナンバープレート%{plate}の車両は差し押さえられました",
        buyerinfo = "購入者情報を取得できませんでした",
        notinveh = "譲渡したい車両に乗っている必要があります",
        vehinfo = "車両情報を取得できませんでした",
        notown = "あなたはこの車両を所有していません",
        buyertoopoor = "購入者はお金が足りません",
        nofinanced = "この場所に分割払い中の車両はありません",
        financed = "この車両は分割払いです",
    },
    success = {
        purchased = "ご購入おめでとうございます！",
        earned_commission = "コミッションとして$%{amount}を獲得しました",
        gifted = "車両を贈与しました",
        received_gift = "車両を贈与されました",
        soldfor = "あなたの車両を$%{value}で売却しました",
        boughtfor = "車両を$%{value}で購入しました",
    },
    menus = {
        vehHeader_header = "車両オプション",
        vehHeader_txt = "現在の車両を操作します",
        financed_header = "分割払い中の車両",
        finance_txt = "所有している車両を閲覧します",
        returnTestDrive_header = "試乗を終了",
        goback_header = "戻る",
        veh_price = "価格：$",
        veh_platetxt = "ナンバープレート：",
        veh_finance = "車両の支払い",
        veh_finance_balance = "残り合計残高",
        veh_finance_currency = "$",
        veh_finance_total = "残り支払い回数",
        veh_finance_reccuring = "定期支払額",
        veh_finance_pay = "支払いを行う",
        veh_finance_payoff = "車両を完済する",
        veh_finance_payment = "支払額 ($)",
        submit_text = "送信",
        test_header = "試乗",
        finance_header = "車両を分割払い",
        swap_header = "車両を交換",
        swap_txt = "現在選択中の車両を変更します",
        financesubmit_downpayment = "頭金 - 最低",
        financesubmit_totalpayment = "支払い回数 - 最大",
        --無料使用
        freeuse_test_txt = "現在選択中の車両を試乗する",
        freeuse_buy_header = "車両を購入",
        freeuse_buy_txt = "現在選択中の車両を購入します",
        freeuse_finance_txt = "現在選択中の車両を分割払いで購入する",
        --管理
        managed_test_txt = "プレイヤーに試乗を許可する",
        managed_sell_header = "車両を売却",
        managed_sell_txt = "プレイヤーに車両を売却する",
        managed_finance_txt = "プレイヤーに車両を分割払いで売却する",
        submit_ID = "サーバーID (#)",
    },
    general = {
        testdrive_timer = "残り試乗時間：",
        vehinteraction = "車両操作",
        testdrive_timenoti = "残り%{testdrivetime}分です",
        testdrive_complete = "車両の試乗が完了しました",
        paymentduein = "車両の支払いが残り%{time}分で期限切れになります",
        command_transfervehicle = "車両を贈与または売却します",
        command_transfervehicle_help = "購入者のID",
        command_transfervehicle_amount = "売却額 (オプション)",
    }
}

if GetConvar('qb_locale', 'en') == 'ja' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end