fx_version 'cerulean'
game 'gta5'


shared_scripts {
    'config.lua'
}

client_scripts {
    '@PolyZone/client.lua',
	'client/*.lua',
}

server_scripts {
    'server/sv.lua',
}

dependency {
    "qb-target"
}

exports {
    'isInsideCasino'
}