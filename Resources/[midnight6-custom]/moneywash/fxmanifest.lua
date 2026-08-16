fx_version 'cerulean'
game 'gta5'

author 'local'
description 'Simple marked bills money wash for QBCore'
version '1.0.0'

shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'qb-core',
    'qb-target',
    'qb-inventory'
}