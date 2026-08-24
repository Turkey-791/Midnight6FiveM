local Translations = {
    -- エラーメッセージ
    error = {
        not_online                  = 'プレイヤーがオンラインではありません',
        wrong_format                = 'フォーマットが正しくありません',
        missing_args                = 'すべての引数が入力されていません (x, y, z)',
        missing_args2               = 'すべての引数を入力する必要があります！',
        no_access                   = 'このコマンドへのアクセス権がありません',
        company_too_poor            = 'あなたの雇用主は破産しています',
        item_not_exist              = 'アイテムが存在しません',
        too_heavy                   = 'インベントリがいっぱいです',
        location_not_exist          = '場所が存在しません',
        duplicate_license           = '[QBCORE] - 重複するRockstarライセンスが見つかりました',
        no_valid_license            = '[QBCORE] - 有効なRockstarライセンスが見つかりません',
        not_whitelisted             = '[QBCORE] - あなたはこのサーバーのホワイトリストに登録されていません',
        server_already_open         = 'サーバーは既に開いています',
        server_already_closed       = 'サーバーは既に閉じています',
        no_permission               = 'あなたにはこの権限がありません..',
        no_waypoint                 = 'ウェイポイントが設定されていません。',
        tp_error                    = 'テレポート中にエラーが発生しました。',
        ban_table_not_found         = '[QBCORE] - データベースでbansテーブルが見つかりません。SQLファイルが正しくインポートされているか確認してください。',
        connecting_database_error   = '[QBCORE] - データベースへの接続中にエラーが発生しました。SQLサーバーが実行されており、server.cfgファイルの詳細が正しいことを確認してください。',
        connecting_database_timeout = '[QBCORE] - データベース接続がタイムアウトしました。SQLサーバーが実行されており、server.cfgファイルの詳細が正しいことを確認してください。',
    },
    -- 成功メッセージ
    success = {
        server_opened = 'サーバーが開かれました',
        server_closed = 'サーバーが閉じられました',
        teleported_waypoint = 'ウェイポイントにテレポートしました。',
    },
    -- 情報メッセージ
    info = {
        received_paycheck = 'あなたは給料 $%{value} を受け取りました',
        job_info = '職業: %{value} | グレード: %{value2} | 勤務: %{value3}',
        gang_info = 'ギャング: %{value} | グレード: %{value2}',
        on_duty = 'あなたは現在勤務中です！',
        off_duty = 'あなたは現在非番です！',
        checking_ban = 'こんにちは %s。あなたがBANされているか確認しています。',
        join_server = 'ようこそ %s、{Server Name} へ。',
        checking_whitelisted = 'こんにちは %s。あなたの許可を確認しています。',
        exploit_banned = 'あなたはチート行為によりBANされました。詳細についてはDiscordをご確認ください: %{discord}',
        exploit_dropped = 'あなたは悪用行為によりキックされました',
    },
    -- コマンド説明
    command = {
        tp = {
            help = 'プレイヤーまたは座標にテレポート (管理者のみ)',
            params = {
                x = { name = 'id/x', help = 'プレイヤーIDまたはX座標' },
                y = { name = 'y', help = 'Y座標' },
                z = { name = 'z', help = 'Z座標' },
            },
        },
        tpm = { help = 'マーカーにテレポート (管理者のみ)' },
        togglepvp = { help = 'サーバーのPVPを切り替える (管理者のみ)' },
        addpermission = {
            help = 'プレイヤーに権限を与える (ゴッドのみ)',
            params = {
                id = { name = 'id', help = 'プレイヤーID' },
                permission = { name = 'permission', help = '権限レベル' },
            },
        },
        removepermission = {
            help = 'プレイヤーの権限を削除する (ゴッドのみ)',
            params = {
                id = { name = 'id', help = 'プレイヤーID' },
                permission = { name = 'permission', help = '権限レベル' },
            },
        },
        openserver = { help = '全員がサーバーに入れるようにする (管理者のみ)' },
        closeserver = {
            help = '権限のない人がサーバーに入れないようにする (管理者のみ)',
            params = {
                reason = { name = 'reason', help = '閉鎖理由 (任意)' },
            },
        },
        car = {
            help = '車両をスポーンする (管理者のみ)',
            params = {
                model = { name = 'model', help = '車両のモデル名' },
            },
        },
        dv = { help = '車両を削除する (管理者のみ)' },
        dvall = { help = 'すべての車両を削除する (管理者のみ)' },
        dvp = { help = 'すべてのPEDを削除する (管理者のみ)' },
        dvo = { help = 'すべてのオブジェクトを削除する (管理者のみ)' },
        givemoney = {
            help = 'プレイヤーにお金を与える (管理者のみ)',
            params = {
                id = { name = 'id', help = 'プレイヤーID' },
                moneytype = { name = 'moneytype', help = 'お金の種類 (cash, bank, crypto)' },
                amount = { name = 'amount', help = '金額' },
            },
        },
        setmoney = {
            help = 'プレイヤーのお金を設定する (管理者のみ)',
            params = {
                id = { name = 'id', help = 'プレイヤーID' },
                moneytype = { name = 'moneytype', help = 'お金の種類 (cash, bank, crypto)' },
                amount = { name = 'amount', help = '金額' },
            },
        },
        job = { help = 'あなたの職業を確認する' },
        setjob = {
            help = 'プレイヤーの職業を設定する (管理者のみ)',
            params = {
                id = { name = 'id', help = 'プレイヤーID' },
                job = { name = 'job', help = '職業名' },
                grade = { name = 'grade', help = '職業グレード' },
            },
        },
        gang = { help = 'あなたのギャングを確認する' },
        setgang = {
            help = 'プレイヤーのギャングを設定する (管理者のみ)',
            params = {
                id = { name = 'id', help = 'プレイヤーID' },
                gang = { name = 'gang', help = 'ギャング名' },
                grade = { name = 'grade', help = 'ギャンググレード' },
            },
        },
        ooc = { help = 'OOCチャットメッセージ' },
        me = {
            help = 'ローカルメッセージを表示する',
            params = {
                message = { name = 'message', help = '送信するメッセージ' }
            },
        },
    },
}

if GetConvar('qb_locale', 'en') == 'ja' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
