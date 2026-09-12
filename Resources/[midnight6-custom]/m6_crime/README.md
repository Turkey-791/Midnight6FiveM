# m6_crime — Midnight6 犯罪共通窓口

犯罪の入口と出口を1箇所に集約するリソース。AI警察MODを差し替えても、犯罪MOD側には手を入れずに済むようにするのが目的。

## 役割

1. **共通窓口** — すべての犯罪を `exports['m6_crime']:Report()` に集約
2. **事件台帳** — `m6_crime_incidents` テーブル(起動時に自動作成)
3. **時効** — 種別ごとの時効秒数。1分ごとに期限切れを `expired` へ
4. **AI警察への出力** — `exports['rde_aipd_m6']:SetWantedLevel()`
5. **プレイヤー警察への通報** — `qb-phone:client:addPoliceAlert` と `police:client:policeAlert`
6. **警察人数 → AI出動倍率** — `m6_crime:client:policeFactor` を全クライアントへ配信

## 使い方(他のMODから犯罪を投げる)

```lua
-- サーバー側
exports['m6_crime']:Report(offenderSrc, 'STORE_ROBBERY', coords, {
    sourceMod = 'my-robbery-script',
    witnessed = true,       -- 目撃者がいたか(台帳の記録用)
    level     = 3,          -- 省略時は Config.CrimeTypes の値
    skipAi    = false,      -- true にすると台帳と通報だけで手配はしない
    meta      = { note = '任意の情報' },
})
```

## 既存MODの取り込み(server/connectors.lua)

FiveM は同じイベント名に複数リソースがハンドラを登録できるため、**相手のMODを改造せずに**取り込んでいる。

| MOD | 受けているイベント | 送信元 |
|---|---|---|
| qb-storerobbery | `qb-storerobbery:server:callCops` | 犯人 |
| qb-bankrobbery | `qb-bankrobbery:server:callCops` | 犯人 |
| qb-truckrobbery | `qb-armoredtruckheist:server:callCops` | 犯人 |
| 宝石店・空き巣・ドラッグ・車両キー | `police:server:policeAlert` | 犯人(警察職からの中継は無視) |

`police:server:policeAlert` は文面からしか犯罪の種類が分からないため、既定では手配レベルを付けずに台帳へ記録するだけ。
種別を分けたい場合は、各MODの発火箇所に `exports['m6_crime']:Report(...)` を1行足すのが確実。

## AI警察との接続

| 方向 | 手段 |
|---|---|
| m6_crime → RDE(手配) | `exports['rde_aipd_m6']:SetWantedLevel(src, level, reason)` |
| RDE → m6_crime(犯罪検知) | `m6_crime:server:crime`(RDE の `LogCrime` から) |
| RDE → m6_crime(逮捕) | `m6_crime:server:arrested`(RDE の `JailPlayer` から。AI逮捕・プレイヤー警察・管理者コマンドのすべてが通る) |
| RDE → m6_crime(出所) | `m6_crime:server:released` |
| RDE → m6_crime(捕縛前の切断) | `m6_crime:server:captureAborted` |

## 事件の状態

| status | 意味 |
|---|---|
| `open` | 未解決(時効カウント中) |
| `served` | 逮捕・服役で清算 |
| `arrested` | 逮捕で停止(`Config.Statute.settleOnArrest = false` のとき) |
| `expired` | 時効成立 |
| `fled_disconnect` | 捕縛処理の途中で切断 |

## 参照用 export

```lua
exports['m6_crime']:GetIncidents(citizenid, status, limit)  -- 事件一覧
exports['m6_crime']:GetOpenIncidentCount(citizenid)          -- 未解決件数
exports['m6_crime']:GetPoliceCount()                         -- 勤務中の警察人数
exports['m6_crime']:GetPoliceFactor()                        -- 現在のAI出動倍率
```

## 管理コマンド

- `/m6crimes [ID]` — 対象の未解決事件を表示(コンソールに一覧)
- `/m6police` — 現在の警察人数とAI出動倍率

## まだ作っていないもの

- 捜査(証拠から犯人を特定する流れ)
- 前科の参照UI
- 時効の延長・リセットの細かいルール(config に枠だけある)
- 捕縛前に切断したプレイヤーの、再接続時の扱い(現状は `fled_disconnect` として記録するだけ)
