-- Runs the qb-minigames Skillbar (the same minigame qb-crafting used) on
-- request from the server-side craftItem hook, and returns the pass/fail
-- result. qb-minigames itself is not modified.
lib.callback.register('ox-crafting-ext:runMinigame', function(difficulty)
    return exports['qb-minigames']:Skillbar(difficulty, '1234')
end)
