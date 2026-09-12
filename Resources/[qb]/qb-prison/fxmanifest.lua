fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_fxv2_oal 'yes'
author 'Kakarot'
description 'Allows players to be jailed, escape from jail and work in jail'
version '2.3.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'client/main.lua',
    -- 2026-09-12: 刑務作業は ao_prisonwork へ移譲したため client/jobs.lua は読み込まない。
    -- ファイル自体は参照用に残してある(復旧したい場合はこの行を戻すだけでよい)。
    -- 'client/jobs.lua',
    'client/prisonbreak.lua'
}

server_script 'server/main.lua'
