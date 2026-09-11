fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Menu of options for players to interact with to do certain tasks'
version '1.5.0'

-- 2026-09-10 Midnight6: client.lua を ox_lib ブリッジに差し替えたため、
-- lib.* を使えるよう ox_lib の init を読み込む。
shared_scripts {
    '@ox_lib/init.lua'
}

client_script 'client.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/style.css'
}
