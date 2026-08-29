-- ox-crafting-ext
--
-- Adds the parts of qb-crafting's design that ox_inventory's native
-- crafting module has no concept of, without modifying ox_inventory,
-- qb-core, or qb-minigames:
--   1. XP-gated recipe unlocking (qb-core Player:GetRep/AddRep metadata,
--      same 'craftingrep'/'attachmentcraftingrep' keys qb-crafting used).
--   2. A pre-craft skill check (qb-minigames Skillbar) for the recipes
--      that were XP-tier 3/4 in the original design.
--   3. Full material forfeiture (no partial-random loss like the original
--      qb-crafting - AO asked for full forfeiture here) when that skill
--      check fails, with the craft itself not completing.
--
-- Implemented entirely via ox_inventory's own craftItem hook
-- (exports.ox_inventory:registerHook / the hookId's post-event), which is
-- ox_inventory's supported extension point for exactly this kind of thing
-- (modules/hooks/server.lua) - not ox_lib's separate generic hook system.
--
-- Recipe ingredient amounts are NOT duplicated here - they are read
-- straight from payload.recipe.ingredients (defined once, in
-- ox_inventory/data/crafting.lua) so there is a single source of truth.

-- xpRequired/xpGain/tier per completed item, taken from qb-crafting's
-- original config.lua (item_bench 1-12, attachment_bench 13-16). tier
-- decides whether a skill check runs at all (only 3/4 do) and at what
-- difficulty.
local Requirements = {
    -- item_bench (xpType: craftingrep)
    lockpick               = { xpRequired = 0,    xpGain = 1,  tier = 1 },
    screwdriverset         = { xpRequired = 0,    xpGain = 2,  tier = 1 },
    electronickit          = { xpRequired = 0,    xpGain = 3,  tier = 1 },
    radioscanner           = { xpRequired = 0,    xpGain = 4,  tier = 1 },
    gatecrack              = { xpRequired = 110,  xpGain = 5,  tier = 2 },
    handcuffs              = { xpRequired = 160,  xpGain = 6,  tier = 2 },
    repairkit              = { xpRequired = 200,  xpGain = 7,  tier = 2 },
    ['ammo-9']              = { xpRequired = 250,  xpGain = 8,  tier = 3 }, -- was pistol_ammo
    ironoxide              = { xpRequired = 300,  xpGain = 9,  tier = 3 },
    aluminumoxide           = { xpRequired = 300,  xpGain = 10, tier = 3 },
    armor                   = { xpRequired = 350,  xpGain = 11, tier = 4 },
    drill                   = { xpRequired = 1750, xpGain = 12, tier = 4 },
    -- attachment_bench (xpType: attachmentcraftingrep) - all xpRequired 0
    clip_attachment          = { xpRequired = 0, xpGain = 10, tier = 1 },
    suppressor_attachment    = { xpRequired = 0, xpGain = 10, tier = 1 },
    drum_attachment          = { xpRequired = 0, xpGain = 10, tier = 1 },
    smallscope_attachment    = { xpRequired = 0, xpGain = 10, tier = 1 },
}

local TierDifficulty = { [3] = 'medium', [4] = 'hard' } -- tiers 1/2: no skill check

local XpTypeByBench = {
    item_bench = 'craftingrep',
    attachment_bench = 'attachmentcraftingrep',
}

---Forfeits every ingredient of a recipe from the player's inventory.
---Used only on skill-check failure; ox_inventory has not consumed
---anything yet at this point (the hook runs before consumption), so this
---is the only place these items get removed for a failed attempt.
local function ForfeitIngredients(source, ingredients)
    for name, amount in pairs(ingredients) do
        if amount >= 1 then
            exports.ox_inventory:RemoveItem(source, name, amount)
        end
    end
end

local hookId = exports.ox_inventory:registerHook('craftItem', function(payload)
    local recipe = payload.recipe
    local req = recipe and Requirements[recipe.name]

    -- Not one of the 16 recipes this extension knows about (e.g. a future
    -- recipe added to a different bench) - don't interfere with it.
    if not req then return true end

    local xpType = XpTypeByBench[payload.benchId]
    if not xpType then return true end

    local source = payload.source
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return false end

    local currentXp = Player.GetRep(xpType) or 0
    if currentXp < req.xpRequired then
        TriggerClientEvent('QBCore:Notify', source, ('You need %d %s experience for this (you have %d)'):format(req.xpRequired, xpType, currentXp), 'error')
        return false
    end

    local difficulty = TierDifficulty[req.tier]
    if difficulty then
        local passed = lib.callback.await('ox-crafting-ext:runMinigame', source, difficulty)

        if not passed then
            ForfeitIngredients(source, recipe.ingredients)
            TriggerClientEvent('QBCore:Notify', source, 'Crafting failed, materials lost!', 'error')
            return false
        end
    end

    return true
end)

-- Post-hook: fires once the whole craftItem attempt is finished, with
-- `success` reflecting whether ox_inventory actually consumed the
-- ingredients and granted the item (not just whether this hook allowed
-- it - see ox_inventory/modules/crafting/server.lua, `hooks.success` is
-- reused as the final outcome flag). XP is only granted here, and only
-- once per attempt, so it cannot be double-counted or granted on a
-- rejected/failed attempt.
AddEventHandler(hookId, function(success, payload)
    if not success then return end

    local recipe = payload.recipe
    local req = recipe and Requirements[recipe.name]
    if not req then return end

    local xpType = XpTypeByBench[payload.benchId]
    if not xpType then return end

    local Player = exports['qb-core']:GetPlayer(payload.source)
    if not Player then return end

    -- NOTE: the original qb-crafting computed newXP = currentXP + xpGain
    -- and then called Player.AddRep(xpType, newXP) - but AddRep already
    -- adds its argument to the current value (qb-core/server/player.lua),
    -- so that call actually added (currentXP + xpGain) on top of the
    -- already-stored currentXP, roughly doubling rep on every craft. That
    -- looks like a pre-existing bug in the original resource (never
    -- noticed because qb-crafting has not actually been reachable in
    -- gameplay - see the investigation report). Not reproduced here:
    -- AddRep is called with just the increment, as the API is designed.
    Player.AddRep(xpType, req.xpGain)
    TriggerClientEvent('QBCore:Notify', payload.source, ('+%d %s XP'):format(req.xpGain, xpType), 'success')
end)
