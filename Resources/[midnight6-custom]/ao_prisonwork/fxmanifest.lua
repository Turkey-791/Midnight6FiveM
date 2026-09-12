fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Midnight6'
description 'qb-prison の刑務作業を差し替え・拡張するアドオン(職種3種/職種別減刑/素材ドロップ/所内犯罪ペナルティ)'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'qb-core',
    'qb-prison',
}
