# rde_aipd_m6 — Midnight6 向け移植版

元リソース: [RedDragonElite/rde_aipd](https://github.com/RedDragonElite/rde_aipd) v1.0.6-alpha(commit 6b20f4e)
ライセンス: RDE Black Flag(無料利用・改変可、販売禁止、作者表記の保持が必要)。`LICENSE` とファイル冒頭のヘッダはそのまま残している。

## 変更点(すべて `[Midnight6移植]` のコメント付き)

### フレームワーク層(ox_core → QBCore)

| ファイル | 変更 |
|---|---|
| `fxmanifest.lua` | `@ox_core/lib/init.lua` と依存 `ox_core` を削除、`qb-core` を追加。`server/nostr.lua` を読み込み対象から除外 |
| `server/main.lua` | `require '@ox_core.lib.init'` → `exports['qb-core']:GetCoreObject()`。`GetQbPlayer()` ヘルパーを追加 |
| `server/main.lua` | `IsPolice()` を job 判定に書き換え(`Config.M6.countOnlyOnDuty` で勤務中のみ数えるか切替) |
| `server/main.lua` | `IsAdmin()` を ACE 権限判定に書き換え |
| `server/main.lua` | `GetCharId()` が `citizenid` を返すよう変更 |
| `server/main.lua` | `ox:playerLoaded` → `QBCore:Server:PlayerLoaded`(引数が Player オブジェクトに変わるため書き直し) |
| `client/main.lua` / `client/crime.lua` | `ox:playerLoaded` → `QBCore:Client:OnPlayerLoaded` |
| DB | `police_records.charid` と `crime_logs.charid` を `int(11)` → `varchar(50)`(citizenid は文字列) |

### 収監(qb-prison に一本化)

- `JailPlayer()` は `injail` メタデータを設定して `police:client:SendToJail` を送るだけになった。
  qb-policejob → qb-prison の通常ルートに合流する。
- **刑期の単位変換**: qb-prison は「1 = 60秒」で減算する実装なので、RDE の秒数を 60 で割って渡す(`Config.M6.jailSecondsPerUnit`)。
- RDE 独自の留置場・刑期タイマー・所持品退避・再ログイン時の刑期復元は動かない(`Config.M6.useQbPrison = false` にすると元の挙動に戻る)。
- 所持品は qb-prison の `jailitems` 側に一本化(`Config.Prison.saveInventory = false`)。

### 死亡・瀕死・捕縛

- qb-ambulancejob は瀕死でも死亡でも蘇生させて HP を 150 にするため、`IsEntityDead` と HP による判定をやめ、
  `isdead` / `inlaststand` メタデータを1秒間隔で監視する方式に変更。
- 倒れたとき、**近くに AI 警官がいれば捕縛**として `police:m6Captured` をサーバーへ送る。
  サーバーは手配状態を確認し、`hospital:client:Revive` → 収監の順で処理する(= 刑務所で目が覚める)。
- 近くに AI 警官がいなければ、従来どおり手配解除 → 病院ルート。
- 設定は `Config.M6.capture`。

### プレイヤー警察との共存

- `m6_crime` が配信する `m6_crime:client:policeFactor`(0.0〜1.0)で **AI の出動台数に倍率**をかける。
- 倍率 0 で出動停止 + 出動中のユニットを撤収。
- 部分削減(0.5 など)は「新規出動の上限を下げる」形。すでに出ているユニットは手配が終わるまで残る。

### 通常プレイ範囲の抜け道対策

- 逮捕時の刑期を**クライアントの申告ではなくサーバー側で算出**するよう変更(元は client が渡した値を採用していた)。
- 捕縛処理の途中で切断された場合、`m6_crime:server:captureAborted` を発火(台帳側で記録)。

### コマンド名

- `lib.addCommand` の名前に接頭辞を付けた(既定 `aipd`)。qb-policejob の `/jail` `/unjail` との衝突を回避。
  例: `/aipdjail` `/aipdsetwanted` `/aipdarrest`

## 導入前に必要な設定変更

- `qb-smallresources`: GTA標準の Wanted と警察出動を止める(止めないと標準警官と二重に出る)。
- `server.cfg`: `ensure m6_crime` と `ensure rde_aipd_m6` を追加。
- `test-police`(検証用リソース)は `clearwanted` が紛らわしいので削除を推奨。

## 未検証(実機でしか決まらない)

- AI警官の挙動の質(タックル成立率、逮捕アニメの同期、車両追跡の安定性)
- 目撃・通報の発生頻度(NPC密度に依存)
- 12人・複数人同時手配時の負荷
- 捕縛 → 蘇生 → 収監の流れが、qb-ambulancejob の死亡タイマー(210秒)や医療プレイヤーの蘇生と競合しないか
