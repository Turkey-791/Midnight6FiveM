-- ao_prisonwork / config.lua
--
-- qb-prison の刑務作業を置き換えるアドオンの設定。
-- qb-prison 本体には「減刑/刑期延長のフック」しか入れていないので、
-- 作業の内容・座標・報酬はすべてこのファイルで完結する。
--
-- 【座標について】
--   ここに入っている座標は rs-prison (Redline Studios, 2023年アーカイブ) の
--   config から持ってきたもの。electrician の7点は現行 qb-prison の座標と
--   7点すべて完全一致していたため、同じ座標系(デフォルト Bolingbroke)由来と
--   確認できている。cook / janitor はマップ分岐されていない単一セットなので
--   同じ出自の可能性が高いが、実機での確認は取れていない。
--   → /prisonwork_marks で全座標にマーカーを出せるようにしてあるので、
--     一度だけ刑務所を一周して確認してほしい(このコマンドは admin のみ)。
--
--   workout / lockers の座標は rs-prison では Gabz MLO 用のものが
--   「デフォルトマップ用」として丸ごとコピペされていた(QBSpawns と GabzSpawns が
--   コメント1行を除いて完全に同一であることを diff で確認済み)。
--   信用できないので、この config には入れていない。

Config = {}

-- サーバーコンソールへのデバッグ出力
Config.Debug = false

-- 座標確認コマンド /prisonwork_marks を登録するか。
-- 設定してある全作業地点とクラフト台にマーカーを出すだけのもので、
-- 実行した本人にしか見えず、ゲームの挙動には一切影響しない。
-- 実機で一度確認したら false に戻してよい。
Config.MarkCommand = true

-- クラフト台の座標(確認用にここにも持たせている)。
-- 実体は ox_inventory/data/crafting.lua の prison_bench 側。
Config.CraftingBench = vec3(1669.21, 2566.56, 45.56)

-- ───────────────────────────────────────────────────────────
-- 刑務作業
-- ───────────────────────────────────────────────────────────
-- 3職種を常時すべて有効にしている。
-- qb-prison / rs-prison は「入獄時に1職種をランダム割り当て」だったが、
-- 同時収監が1〜2人という Midnight6 の実情では、割り当てられた1職種しか
-- できないと選択肢が無くなるため、全職種を同時に開けている。
--
-- reduce: 作業1回ごとの減刑抽選。chance% で min〜max 単位(1単位=約60秒)短縮。
-- 職種ごとの狙い:
--   janitor     … 短時間・高頻度・小さい減刑(屋外を歩き回る)
--   cook        … 中間
--   electrician … 長時間・低頻度・大きい減刑(拘束時間が長い)
--
-- pay: 作業1回あたりの賃金。犯罪収益設計と突き合わせるまで 0(無効)にしてある。
--      0 以外にすると現金が支給される。

Config.Jobs = {
    {
        id       = 'janitor',
        label    = '清掃',
        textui   = '[E] 清掃する',
        blipName = '刑務作業: 清掃',
        blipColour = 2,
        duration = { 5000, 8000 },
        reduce   = { chance = 60, min = 1, max = 1 },
        pay      = 0,
        material = { chance = 20 },
        anim     = { dict = 'anim@amb@drug_field_workers@rake@male_a@base', clip = 'base', flag = 9 },
        prop     = { model = 'prop_tool_broom', bone = 28422, pos = vec3(-0.01, 0.04, -0.03), rot = vec3(0.0, 0.0, 0.0) },
        locations = {
            vec3(1758.37, 2566.15, 45.55),
            vec3(1756.89, 2514.18, 45.55),
            vec3(1622.82, 2563.98, 45.56),
            vec3(1683.65, 2565.20, 45.55),
            vec3(1635.25, 2502.33, 45.55),
            vec3(1655.69, 2527.02, 45.55),
            vec3(1689.13, 2517.97, 45.56),
        },
    },
    {
        id       = 'cook',
        label    = '調理',
        textui   = '[E] 配食の下ごしらえをする',
        blipName = '刑務作業: 調理',
        blipColour = 5,
        duration = { 8000, 12000 },
        reduce   = { chance = 55, min = 1, max = 2 },
        pay      = 0,
        material = { chance = 22 },
        anim     = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_a', flag = 9 },
        prop     = nil,
        locations = {
            vec3(1780.85, 2564.29, 45.67),
            vec3(1777.57, 2561.91, 45.67),
            vec3(1784.56, 2564.17, 45.67),
            vec3(1786.54, 2564.33, 45.67),
            vec3(1780.19, 2560.78, 45.67),
        },
    },
    {
        id       = 'electrician',
        label    = '電気工事',
        textui   = '[E] 配線を直す',
        blipName = '刑務作業: 電気工事',
        blipColour = 3,
        duration = { 10000, 16000 },
        reduce   = { chance = 50, min = 2, max = 3 },
        pay      = 0,
        material = { chance = 25 },
        anim     = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire', flag = 16 },
        prop     = nil,
        -- 現行 qb-prison の Config.Locations.jobs.electrician と同一の7点
        locations = {
            vec3(1761.46, 2540.41, 45.56),
            vec3(1718.54, 2527.80, 45.56),
            vec3(1700.20, 2474.81, 45.56),
            vec3(1664.83, 2501.58, 45.56),
            vec3(1621.62, 2509.30, 45.56),
            vec3(1627.94, 2538.39, 45.56),
            vec3(1625.10, 2575.99, 45.56),
        },
    },
}

-- 作業で拾える素材(全職種共通)。
-- 4つとも ox_inventory/data/items.lua に存在を確認済み。
Config.Materials = {
    { item = 'metalscrap', min = 1, max = 3 },
    { item = 'rubber',     min = 2, max = 4 },
    { item = 'steel',      min = 3, max = 7 },
    { item = 'plastic',    min = 1, max = 2 },
}

-- 作業中にスマホを拾う確率(%)。0 にすると無効。
-- 旧来の qb-prison は client/jobs.lua から prison:server:CheckChance を呼んで
-- 約1%で1回だけスマホを配っていた。その jobs.lua を fxmanifest から外したため
-- 旧経路は動かなくなっている。挙動を保つためにこちらで同等の処理を持つ。
-- 収監1回につき1個までしか出ない(サーバー側で制限している)。
Config.PhoneChance = 1
Config.PhoneItem   = 'phone'

-- ───────────────────────────────────────────────────────────
-- 所内犯罪のペナルティ
-- ───────────────────────────────────────────────────────────
-- 2026-09-12 AO決定:
--   ・所内で看守を殴っても手配レベルは付けない(AI警察は刑務所に出動させない)
--   ・代わりに刑期を延長する
--   ・段階的な独房懲罰は将来の検討事項(未実装)
--
-- rde_aipd_m6 側は config.lua の noWantedWhileJailed = true によって
-- 収監中の犯罪検知を丸ごと止めている(client/crime.lua:856)。
-- その設定は変更していない。ここは独立したペナルティとして動く。
--
-- 看守の判定は ped の「モデルハッシュ」で行う。
-- rde_aipd_m6 は GetPedType(victim) == 6 で警官判定しているが、
-- 刑務官 ped がその判定に入るかは未確認なので、そこには依存していない。
Config.Punish = {
    enabled = true,

    -- 看守とみなすモデル
    guardModels = {
        `s_m_m_prisguard_01`,
        `s_m_y_prismuscl_01`,
        `s_m_y_cop_01`,
        `s_f_y_cop_01`,
        `s_m_y_sheriff_01`,
        `s_f_y_sheriff_01`,
    },

    assault = { units = 3,  cooldownMs = 8000 },  -- 看守を殴る
    murder  = { units = 20, cooldownMs = 0 },     -- 看守を殺す

    -- 囚人(他プレイヤー)への暴行
    inmateAssault = { enabled = true, units = 1, cooldownMs = 15000 },
    inmateMurder  = { enabled = true, units = 10, cooldownMs = 0 },
}

-- ───────────────────────────────────────────────────────────
-- 脱獄について(このリソースでは扱わない)
-- ───────────────────────────────────────────────────────────
-- 2026-09-12 調査で確定: 脱獄時の「残刑期の持ち越し + 上乗せ + 手配レベル」は
-- すでに m6_crime に実装済みで、有効になっている。
--
--   m6_crime/server/connectors.lua:186-213
--     prison:server:GiveJailItems(escaped = true) を拾い、
--     残刑期 x Config.Escape.carryPenalty(既定 1.5、上限 60)を
--     metadata['m6_owedjail'] へ積み、1秒後に PRISON_ESCAPE(手配レベル4)を発報する
--   rde_aipd_m6/server/main.lua:370-379
--     次に収監されたとき m6_owedjail を刑期に加算して 0 に戻す
--
-- したがって ao_prisonwork 側で脱獄の刑期処理を実装すると二重計上になる。
-- ここでは何もしない。脱獄まわりの不具合は「脱獄ワークストリーム」で扱うこと。
