fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Menu that allows players to input information for various things'
version '1.2.0'

-- 2026-09-10 Midnight6: client.lua を ox_lib ブリッジに差し替えたため、
-- lib.* を使えるよう ox_lib の init を読み込む。
shared_scripts {
    '@ox_lib/init.lua'
}

client_script 'client.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles/*.css',
    'html/script.js'
}
