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

-- ════════════════════════════════════════════════════════════════
-- 刑期の表示
--   qb-prison は残り刑期の常時表示を持たず、面会所NPCに話しかけないと分からない。
--   収監中は画面上部に残りを出す。単位は qb-prison と同じ「ヶ月」(実時間で約1分)。
-- ════════════════════════════════════════════════════════════════

local QBCore = exports['qb-core']:GetCoreObject()

local function GetJailTime()
    local pd = QBCore.Functions.GetPlayerData()
    if not pd or not pd.metadata then return 0 end
    return pd.metadata['injail'] or 0
end

CreateThread(function()
    Wait(8000)
    while true do
        local t = GetJailTime()
        if t and t > 0 then
            SetTextFont(4)
            SetTextScale(0.42, 0.42)
            SetTextColour(255, 255, 255, 230)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(('~r~刑期~s~  残り %d ヶ月  ~c~(実時間 約%d分)'):format(t, t))
            DrawText(0.5, 0.020)
            Wait(0)
        else
            Wait(2000)
        end
    end
end)

RegisterCommand('jailtime', function()
    local t = GetJailTime()
    if t and t > 0 then
        QBCore.Functions.Notify(('残り刑期: %d ヶ月(実時間 約%d分)'):format(t, t), 'primary', 6000)
    else
        QBCore.Functions.Notify('服役中ではありません', 'success', 4000)
    end
end, false)
