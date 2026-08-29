-- ao_infohud: 実データ連携版 (Cash / Bank)
-- QBCoreの現金・銀行残高、ゲーム内時計、リアル時刻情報をNUIに送信します。
-- ps-hud / ox系リソースのイベントには一切触れません。単体で追加/削除できます。
--
-- [Bank連携メモ]
-- 本サーバーはRenewed-Bankingを併用していますが、Renewed-Bankingの個人口座残高は
-- 独自テーブルではなくQBCore標準の Player.PlayerData.money.bank をそのまま使用しています。
-- (Renewed-Banking/server/framework.lua の GetFunds/AddMoney/RemoveMoney が
--  Player.Functions.AddMoney / RemoveMoney / GetMoney('bank') を直接呼んでいるため)
-- そのため、qb-core標準の QBCore:Client:OnMoneyChange を拾うだけで、
-- ATMでの入出金・給料・罰金など全てのBank変動がこのHUDにも反映されます。
-- (Renewed-Banking独自の共有口座テーブル bank_accounts_new は個人残高とは無関係なので未使用)

local QBCore = exports['qb-core']:GetCoreObject()

local cash = 0
local bank = 0

local function refreshMoneyFromPlayerData()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.money then return end
    cash = PlayerData.money.cash or 0
    bank = PlayerData.money.bank or 0
end

local function sendUpdate()
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    local gameTime = string.format('%02d:%02d', hours, minutes)

    SendNUIMessage({
        action = 'update',
        gameTime = gameTime,
        cash = cash,
        bank = bank,
        playerId = GetPlayerServerId(PlayerId()),
        serverName = 'ADY GTA'
    })
end

-- ログイン時に現在の所持金を取得して即反映
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    refreshMoneyFromPlayerData()
    sendUpdate()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    cash, bank = 0, 0
end)

-- Cash/Bankどちらの増減もここに集約される(Renewed-BankingのATM操作、給料、罰金等すべて含む)
RegisterNetEvent('QBCore:Client:OnMoneyChange', function(_moneytype, _amount, _operation, _reason)
    refreshMoneyFromPlayerData()
    sendUpdate()
end)

-- キャラ切り替え等でPlayerData全体が入れ替わる場合の保険
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if not val or not val.money then return end
    cash = val.money.cash or 0
    bank = val.money.bank or 0
    sendUpdate()
end)

CreateThread(function()
    -- リソースの再起動などで既にログイン済みだった場合の初期値取得
    if LocalPlayer.state.isLoggedIn then
        refreshMoneyFromPlayerData()
    end

    while true do
        sendUpdate()
        Wait(5000)
    end
end)
