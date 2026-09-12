fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Midnight6 / AO'
name 'm6_crime'
description 'Midnight6 犯罪共通窓口 — 事件台帳・時効・警察人数によるAI制御・通報の集約'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/connectors.lua'
}

client_scripts {
    'client/main.lua'
}

-- 刑期表示。日本語をネイティブの DrawText で出すと豆腐文字になるため NUI を使う
ui_page 'html/jail_hud.html'

files {
    'html/jail_hud.html'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'qb-core'
}
