fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ao_infohud'
author 'AO'
description 'Top-right info HUD: server logo, real time, in-game time, cash/bank'
version '1.0.0'

dependency 'qb-core'

-- 既存のps-hud/qb-core/ox系リソースには一切触れません。単体で追加/削除できます。

client_scripts {
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/images/logo.png'
}
