fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'RDE | SerpentsByte'
name 'rde_aipd_m6'   -- [Midnight6移植] フォーク名
description 'RDE AIPD | Next-Gen Crime & AI Police System'
version '1.0.6-alpha-m6.1'

-- ============================================================================
--     NUI
-- ============================================================================
ui_page 'html/wanted_stars.html'

files {
    'html/wanted_stars.html',
    'html/star.png',
    'html/star2.png',
    'html/star3.png',
    'html/star4.png',
    -- Locales must be listed here so ox_lib can load them on the client side
    'locales/en.lua',
    'locales/de.lua'
}

-- ============================================================================
--     SHARED
-- ============================================================================
-- [Midnight6移植] ox_core のライブラリ読み込みを削除(QBCore環境のため)
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

-- ============================================================================
--     SERVER
-- ============================================================================
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
	'server/crime_witness_handler.lua'
    -- [Midnight6移植] 'server/nostr.lua' は読み込まない(外部ログ機能は不使用)
}

-- ============================================================================
--     CLIENT
-- ============================================================================
client_scripts {
    'client/main.lua',
    'client/crime.lua'
}

-- ============================================================================
--     DEPENDENCIES
-- ============================================================================
-- [Midnight6移植] ox_core → qb-core
dependencies {
    '/server:7290',
    'oxmysql',
    'ox_lib',
    'qb-core',
    'ox_inventory'
}

-- ============================================================================
--     PROVIDES
-- ============================================================================
provides {
    'police_system',
    'wanted_system',
    'jail_system'
}

-- Performance optimization
experimental_features_enabled '1'