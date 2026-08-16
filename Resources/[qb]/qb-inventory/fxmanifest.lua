fx_version 'cerulean'
game 'gta5'

author 'Bridge Shim'
description 'Routes legacy qb-inventory exports to ox_inventory'
version '1.1.0'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory'
}
