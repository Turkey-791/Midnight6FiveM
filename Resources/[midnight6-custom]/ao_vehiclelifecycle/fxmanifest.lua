fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Midnight6 / AO'
description 'Server-authoritative vehicle lifecycle - 破壊・放置の検知とデポ送り (Phase G-1: 検知とログのみ)'
version '0.1.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
