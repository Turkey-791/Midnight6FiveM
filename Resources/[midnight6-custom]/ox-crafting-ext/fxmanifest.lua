fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Midnight6'
description 'Crafting extension for ox_inventory (item_bench/attachment_bench): XP-gated recipe unlocking, pre-craft skill check for Tier 3/4 recipes, and full material forfeiture on skill-check failure. Reproduces qb-crafting XP progression without modifying ox_inventory, qb-core, or qb-minigames. See data/crafting.lua in ox_inventory for the recipe/location definitions this extension applies to.'
version '1.0.0'

shared_script '@ox_lib/init.lua'

server_script 'server.lua'
client_script 'client.lua'

dependencies {
    'qb-core',
    'ox_lib',
    'ox_inventory',
    'qb-minigames',
}
