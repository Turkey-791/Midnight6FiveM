# クラフトベンチ修正 指示書（qb-crafting → ox_inventory純正クラフト 移行）

> このドキュメントは、別のチャットセッション（前提知識ゼロの状態）に引き継いでも作業を再開できるように、これまでの調査結果と決定事項をまとめたものです。
> **これはまだ仕様書の段階であり、コードの修正はまだ一切行っていません。** 修正に着手する際は、このドキュメントを渡した上で「この指示書の通りに実装してください」と明示的に指示してください。

---

## 0. サーバー環境

- フレームワーク: QBCore
- インベントリ: **ox_inventory**（実データの唯一の正）
- `[qb]/qb-inventory` という名前のリソースが存在するが、これは実体ではなく **「qb-inventory compatibility shim」**（2026-08-17頃に作成された互換シム）。`exports['qb-inventory']:AddItem/RemoveItem/HasItem/GetItemByName/GetItemsByName/GetItemBySlot/ClearInventory/OpenInventory` などのレガシー呼び出しをox_inventoryへ転送する。
- デバイス上のパス（Windows / Resources直下）:
  - `Resources/[qb]/qb-crafting`
  - `Resources/[qb]/qb-inventory`（シム）
  - `Resources/[qb]/qb-core`
  - `Resources/[qb]/qb-scrapyard`
  - `Resources/[qb]/qb-recyclejob`
  - `Resources/[ox]/ox_inventory`

---

## 1. 発端の問題

クラフトベンチを開くと `lockpick` しか表示されない。しかし `qb-crafting/config.lua` の `Config.item_bench.recipes` には12種類のレシピが登録されている。

## 2. 調査で判明したこと（結論）

### 2-1. 実際にゲーム画面に表示されているUIは qb-crafting ではなく、**ox_inventory純正のクラフト機能**だった

ユーザーが送付したスクリーンショットのUI（グリッド型のアイテム欄、右上「Crafting Bench」ヘッダー、ツールチップ「Lockpick / 5s / 5% Hammer / 5x Scrap Metal」）は、qb-craftingのqb-menuベースの表示（テキストリスト）とは別物。

証拠:
- `"Open Crafting Bench"` という文言は `qb-crafting` のlocaleには存在せず、`[ox]/ox_inventory/locales/en.json` にのみ存在する。
- ツールチップの内容（5x Scrap Metal, 5% Hammer, 5秒）は `qb-crafting/config.lua` のlockpickレシピ（22x metalscrap + 32x plastic、hammerの概念なし）とは一致せず、`[ox]/ox_inventory/data/crafting.lua` の以下の定義と完全一致する。

```lua
-- [ox]/ox_inventory/data/crafting.lua （現状の全文）
return {
    {
        name = 'debug_crafting',
        items = {
            {
                name = 'lockpick',
                ingredients = {
                    scrapmetal = 5,
                    WEAPON_HAMMER = 0.05
                },
                duration = 5000,
                count = 2,
            },
        },
        points = {
            vec3(-1147.083008, -2002.662109, 13.180260),
            vec3(-345.374969, -130.687088, 39.009613)
        },
        zones = { ... },
        blip = { id = 566, colour = 31, scale = 0.8 },
    },
}
```

### 2-2. 「lockpickしか表示されない」の直接原因

上記の通り、`debug_crafting` というベンチ（ox_inventory導入時に付属していたサンプル/デバッグ用の設定と思われる）に **lockpickのレシピが1件しか登録されていない** ため。バグではなく、サンプル設定のまま追加設定がされていない状態。qb-craftingのconfig.luaを編集しても、このベンチの表示には一切反映されない（別システムのため）。

### 2-3. 仮にqb-craftingを直接直そうとしても、別の構造的問題がある

`qb-crafting/server.lua` はプレイヤーの所持品を次のように取得している。

```lua
-- qb-crafting/server.lua 18-25
QBCore.Functions.CreateCallback('crafting:getPlayerInventory', function(source, cb)
    local player = exports['qb-core']:GetPlayer(source)
    if player then
        cb(player.PlayerData.items)   -- ← QBCoreの生データを直接参照
    else
        cb({})
    end
end)
```

一方、`qb-inventory` シム（`Resources/[qb]/qb-inventory/server/main.lua`）は `exports['qb-inventory']:AddItem/RemoveItem/HasItem/GetItemByName` などの**関数呼び出し**はox_inventoryへ正しく転送するが、**`player.PlayerData.items`（QBCoreの生データテーブル）を同期する処理は持っていない**（`LoadInventory`はコメント付きの空テーブルを返すダミー）。

→ つまりqb-craftingは、シムが提供する「正しく橋渡しされた経路」を通らず、**同期されていない生データを直接見ている**。これがゆえに、たとえレシピを12件とも表示させたとしても、素材の所持判定（`requiredItems`のチェック）が実際のox_inventoryの中身と一致しない可能性が高い。qb-craftingを活かす場合は、`client.lua`/`server.lua`のインベントリ読み取り部分を、シムが提供する`HasItem`/`GetItemByName`等を使う形に書き直す必要がある。

### 2-4. アイテム名の整合性（qbscrap問題）について

ox_inventory純正クラフトのサンプルレシピが使っている `scrapmetal` は、サーバー全体を検索しても**ox_inventory自身のサンプルレシピ以外どこからも参照されていない**（孤立した飾りアイテム）。

一方、qb-craftingのレシピが使っている `metalscrap` は、以下の既存ジョブ系リソースと紐づいた**本物の経済アイテム**であることを確認済み。

```
[qb]/qb-scrapyard/config.lua
  Config.Items = { 'metalscrap', 'plastic', ... }

[qb]/qb-recyclejob/server.lua
  Recieve = { { item = 'metalscrap', ... }, { item = 'plastic', ... } }
  Sales   = { metalscrap = 2, plastic = 2, ... }
```

`metalscrap` は `ox_inventory/data/items.lua` にも既に別途定義済み（`scrapmetal`とは別のアイテムとして両方存在）。

→ **結論: レシピの登録方式（仕組み）はox_inventory純正クラフトに寄せるが、アイテム名（metalscrap等）はqb時代のものをそのまま流用する。** ox_inventory側の `scrapmetal` を使ったサンプルレシピは、qbscrapの経済とは無関係なので置き換え対象。

---

## 3. 決定した修正方針

**ox_inventory純正のクラフト機能（`[ox]/ox_inventory/data/crafting.lua`）に一本化する。qb-craftingは廃止する。**

理由:
1. 実際にプレイヤーが操作しているUI・データソースは既にox_inventory側であり、qb-crafting側は前述2-3の通り構造的にインベントリと同期しない設計になっている。
2. アイテム名（metalscrap等）はそのまま流用可能なので、レシピ内容自体は失われない。移行はあくまで「登録フォーマットの変換」。
3. ox_inventory純正クラフトは既に動作実績あり（lockpickレシピは正常に機能している）。

### 3-1. 失われる機能とその対策（要検討・要決定）

qb-craftingには「クラフト経験値（`craftingrep`というQBCoreのmetadataキー）でレシピを段階的に解放する」仕組みがあったが、ox_inventory純正クラフトには標準搭載されていない。

- ox_inventoryには `craftItem` イベント用の公式フック機構（`modules/hooks/server.lua` の `TriggerEventHooks('craftItem', payload)`）がある。クラフト成功時に外部リソースからフックできるので、経験値付与ロジック（`Player.AddRep(xpType, xpGain)`）はここに移植可能。
- ただし「XP不足のレシピを非表示/ロックする」という**レシピ単位**の制御は、ox_inventoryの `groups` 制限が**ベンチ／ゾーン単位**にしか効かないため、そのままの形では再現できない。
  - 対策案A: レシピをXP帯ごとに複数のベンチ（初級/中級/上級）に分割し、ベンチ単位で `groups`（job/gang等）による解放にする。
  - 対策案B: XPによる個別レシピの表示制御は諦め、素材があれば誰でも作れる形にする（シンプル化）。
  - **→ これは実装前に依頼者（AO）に確認・決定してもらう必要がある。**
- 設置式ベンチ（アイテムを使って好きな場所にベンチを置く、というqb-craftingの挙動）も、ox_inventory純正クラフトでは基本的に固定座標(`vec3`)方式。この動線を残すかどうかも要確認（優先度は低めでよい可能性が高い）。

---

## 4. 移行対象データ（qb-crafting/config.lua の全文、変換の元データ）

### item_bench.recipes（12件）／ xpType = 'craftingrep'

| item | xpRequired | xpGain | requiredItems |
|---|---|---|---|
| lockpick | 0 | 1 | metalscrap 22, plastic 32 |
| screwdriverset | 0 | 2 | metalscrap 30, plastic 42 |
| electronickit | 0 | 3 | metalscrap 30, plastic 45, aluminum 28 |
| radioscanner | 0 | 4 | electronickit 2, plastic 52, steel 40 |
| gatecrack | 110 | 5 | metalscrap 10, plastic 50, aluminum 30, iron 17, electronickit 2 |
| handcuffs | 160 | 6 | metalscrap 36, steel 24, aluminum 28 |
| repairkit | 200 | 7 | metalscrap 32, steel 43, plastic 61 |
| pistol_ammo | 250 | 8 | metalscrap 50, steel 37, copper 26 |
| ironoxide | 300 | 9 | iron 60, glass 30 |
| aluminumoxide | 300 | 10 | aluminum 60, glass 30 |
| armor | 350 | 11 | iron 33, steel 44, plastic 55, aluminum 22 |
| drill | 1750 | 12 | iron 50, steel 50, screwdriverset 3, advancedlockpick 2 |

### attachment_bench.recipes（4件）／ xpType = 'attachmentcraftingrep'

| item | xpRequired | xpGain | requiredItems |
|---|---|---|---|
| clip_attachment | 0 | 10 | metalscrap 140, steel 250, rubber 60 |
| suppressor_attachment | 0 | 10 | metalscrap 165, steel 285, rubber 75 |
| drum_attachment | 0 | 10 | metalscrap 230, steel 365, rubber 130 |
| smallscope_attachment | 0 | 10 | metalscrap 255, steel 390, rubber 145 |

上記アイテム名（クラフト対象・素材とも全て）は `qb-core/shared/items.lua` に定義済みであることを確認済み（実行時エラーの原因にはならない）。ただし移行後はox_inventory側の `data/items.lua` にも同名アイテムが存在するか個別に要確認（`metalscrap` は確認済み、他は未確認）。

---

## 5. 移行先フォーマットの参考例

`ox_inventory/data/crafting.lua` の1レシピあたりの形式:

```lua
{
    name = 'アイテム名',
    ingredients = {
        素材名 = 個数,
        ...
    },
    duration = ミリ秒,   -- クラフトにかかる時間
    count = 出来上がる個数,
},
```

現状ある `debug_crafting` ベンチの `lockpick`（`scrapmetal`使用）は、`metalscrap`ベースの本物のレシピに置き換える想定。

---

## 6. 未決事項（実装前に確認すべきこと）

1. XP制限（レシピごとの段階解放）をどう再現するか（3-1の対策案A/Bのどちらか、または別案）。
2. `attachment_bench`（4レシピ）も同じベンチにまとめるか、別ベンチとして分けるか。
3. 設置式（持ち運び）ベンチの動線を残すか、固定座標のままでよいか。
4. `qb-crafting` リソースそのものを削除するか、`resources.cfg` から `ensure` を外すだけに留めるか。
5. `duration`（クラフト所要時間）はqb-crafting側に明示的な設定がなかった（`math.random(2000,5000) * amountToCraft`をprogressbarに使っていただけ）。ox_inventory側の`duration`値をどう設定するか、レシピごとに要検討（一律でよいか、重要度に応じて変えるか）。

---

## 7. 参照ファイル一覧（別チャットで直接読み直す場合のパス）

```
Resources/[qb]/qb-crafting/config.lua
Resources/[qb]/qb-crafting/client.lua
Resources/[qb]/qb-crafting/server.lua
Resources/[qb]/qb-inventory/server/main.lua        （シム本体）
Resources/[qb]/qb-scrapyard/config.lua
Resources/[qb]/qb-recyclejob/server.lua
Resources/[qb]/qb-core/shared/items.lua
Resources/[ox]/ox_inventory/data/crafting.lua      （現状: debug_craftingのみ）
Resources/[ox]/ox_inventory/data/items.lua
Resources/[ox]/ox_inventory/modules/crafting/client.lua
Resources/[ox]/ox_inventory/modules/crafting/server.lua
Resources/[ox]/ox_inventory/modules/hooks/server.lua
Resources/[ox]/ox_inventory/locales/ja.json
```

---

## 8. このドキュメントの使い方

新しいチャットにこのファイルを渡し、上記「6. 未決事項」への回答を伝えた上で、
「この指示書の通りに `ox_inventory/data/crafting.lua` へレシピを移行し、必要なら経験値フックを実装してください」
と依頼すれば、そのまま実装に着手できます。

**このドキュメント自体には、まだ実装（コード変更）は含まれていません。**
