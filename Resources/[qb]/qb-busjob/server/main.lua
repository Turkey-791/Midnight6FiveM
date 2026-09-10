function NearBus(src)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    for _, v in pairs(Config.NPCLocations.Locations) do
        local dist = #(coords - vector3(v.x, v.y, v.z))
        if dist < 20 then
            return true
        end
    end
end

-- 2026-09-09 経済設計: 従来$15〜25(+36%の確率で+$10〜20のボーナス、平均約$25/人)だった乗客
-- 報酬を、基準時給$3,000/hに合わせて$145〜155(平均$150)/人に引き上げた。バスは社交性・RP要素が
-- 薄い(ただルートを回るだけの)単純作業のため、退屈な仕事ほど犯罪に流れやすいという懸念を踏まえ、
-- タクシー・記者のような「低めでよい」枠ではなく標準枠として設定している。
-- あわせて、ランダムボーナスの仕組みは金額のブレを分かりにくくするだけなので撤去し、
-- 平均額そのものを$145〜155の範囲に収める単純な乱数に統一した。
RegisterNetEvent('qb-busjob:server:NpcPay', function()
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    local Payment = math.random(145, 155)
    if Player.PlayerData.job.name == 'bus' then
        if NearBus(src) then
            Player.AddMoney('cash', Payment, 'Bus job')
        else
            DropPlayer(src, Lang:t('error.exploit'))
        end
    else
        DropPlayer(src, Lang:t('error.exploit'))
    end
end)
