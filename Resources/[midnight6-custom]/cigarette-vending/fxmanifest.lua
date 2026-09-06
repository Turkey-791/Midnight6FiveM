fx_version 'cerulean'
game 'gta5'

author 'Midnight6 (AO依頼で2026-09-06追加)'
description 'prop_vend_fags_01(タバコ自動販売機)にox_targetでInteractionを追加し、既存ox_inventory Shop UIでcigarette_packを販売する。ox_inventory/ox_target本体は未変更。inventory:target convarも変更していない(グローバル切り替えを避けるため、ここから直接ox_targetのaddModelを呼ぶ方式)。'
version '1.0.0'

client_scripts {
    'client.lua'
}

dependencies {
    'ox_target',
    'ox_inventory'
}
