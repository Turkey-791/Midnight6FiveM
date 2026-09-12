fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Midnight6 / AO'
description '店舗別 衣服カタログ - illenium-appearance に店舗ごとの品揃えフィルタを提供する。カジノ内ブティックの店員PEDもここが出す'
version '0.1.0'

shared_scripts {
    'config.lua',
    'data/catalog.lua'
}

client_scripts {
    'client/main.lua',
    'client/casino_ped.lua'
}

server_scripts {
    'server/main.lua'
}
