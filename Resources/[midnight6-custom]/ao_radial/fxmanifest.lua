fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Midnight6 / AO'
description 'ox_lib ラジアルメニュー。UI のみを担当し、実処理は qb-radialmenu 側に残す'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'radial_items.lua', -- 自動生成された項目定義(AoRadialData)。main.lua より先に読む
    'client/main.lua'
}
