---@diagnostic disable: undefined-global
-- ════════════════════════════════════════════════════════════════
-- m6_crime | CLIENT
--   AI出動倍率の保持のみ。実際に倍率を使うのは rde_aipd_m6 側。
--   ここでは他のリソースから参照できるように export を置いている。
-- ════════════════════════════════════════════════════════════════

local policeFactor = 1.0

RegisterNetEvent('m6_crime:client:policeFactor', function(factor)
    if type(factor) ~= 'number' then return end
    policeFactor = factor
    if Config.Debug then
        print(('^3[m6_crime]^7 AI出動倍率 = %.2f'):format(policeFactor))
    end
end)

exports('GetPoliceFactor', function() return policeFactor end)
