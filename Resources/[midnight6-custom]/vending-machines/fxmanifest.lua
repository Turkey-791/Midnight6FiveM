fx_version 'cerulean'
game 'gta5'

author 'Midnight6 (AO依頼で2026-09-07追加)'
description 'GTA V標準の自動販売機プロップ(ドリンク/スナック/コーヒー/バーガー/タバコ)にox_targetでInteractionを追加し、既存のox_inventory Shop UIで商品を販売する。ox_target:addModel()によるモデル単位登録のため座標指定は不要。2026-09-06に作成したcigarette-vendingを統合したもの。ox_inventory/ox_target/qb-core本体は未変更、inventory:target convarも未変更。'
version '1.0.0'

client_scripts {
    'config.lua',
    'client.lua'
}

dependencies {
    'ox_target',
    'ox_inventory'
}
