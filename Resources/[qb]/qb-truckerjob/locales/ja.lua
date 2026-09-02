local Translations = {
    error = {
        no_deposit = "$%{value} の保証金が必要です",
        cancelled = "キャンセルしました",
        vehicle_not_correct = "この車両は商用車ではありません！",
        no_driver = "この操作を行うには運転席にいる必要があります",
        no_work_done = "まだ仕事をしていません",
        backdoors_not_open = "車両の後部ドアが開いていません",
        get_out_vehicle = "この操作を行うには車両から降りる必要があります",
        too_far_from_trunk = "車両の荷台から商品箱を取り出してください",
        too_far_from_delivery = "配達地点にもっと近づいてください"
    },

    success = {
        paid_with_cash = "$%{value} の保証金を現金で支払いました",
        paid_with_bank = "$%{value} の保証金を銀行口座から支払いました",
        refund_to_cash = "$%{value} の保証金が現金で返金されました",
        you_earned = "$%{value} を獲得しました",
        payslip_time = "すべての店舗への配達が完了しました。給料を受け取りましょう！",
    },

    menu = {
        header = "利用可能なトラック",
        close_menu = "⬅ メニューを閉じる",
    },

    mission = {
        store_reached = "店舗に到着しました。[E]で荷台から商品箱を取り出し、マーカーまで運んでください",
        take_box = "商品箱を取り出す",
        deliver_box = "商品箱を配達する",
        another_box = "次の商品箱を取り出す",
        goto_next_point = "すべての商品を配達しました。次の配達地点へ向かってください",
        return_to_station = "すべての商品を配達しました。営業所へ戻ってください",
        job_completed = "配送ルートを完了しました。給料を受け取ってください"
    },

    info = {
        deliver_e = "~g~E~w~ - 商品を配達する",
        deliver = "商品を配達する",
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
