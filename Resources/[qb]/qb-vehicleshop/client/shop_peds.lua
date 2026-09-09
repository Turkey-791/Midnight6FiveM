--[[
    新設ショップの販売員ペド配置（2026-09-09）
    Big House Storage Inc.（マッスル/クーペ専門店）と
    Sanders Motorcycles（バイク専門店）に、静止ペドを1体ずつ配置します。
--]]

local ShopPeds = {
    {
        model = 'a_m_y_business_01',
        coords = vector4(-512.83, -2199.54, 6.39, 319.92), -- Big House Storage Inc.（マッスル/クーペ専門店）
    },
    {
        model = 'a_m_y_business_01',
        coords = vector4(306.39, -1163.21, 29.29, 299.41), -- Sanders Motorcycles（バイク専門店）
    },
}

CreateThread(function()
    for _, pedInfo in ipairs(ShopPeds) do
        local hash = GetHashKey(pedInfo.model)
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end
        if HasModelLoaded(hash) then
            local ped = CreatePed(4, hash, pedInfo.coords.x, pedInfo.coords.y, pedInfo.coords.z, pedInfo.coords.w, false, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            FreezeEntityPosition(ped, true)
            TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
            SetModelAsNoLongerNeeded(hash)
        end
    end
end)

--[[
    補足：
    - モデル 'a_m_y_business_01'（スーツ姿の男性NPC）を仮で選んでいます。
      見た目を変えたい場合はこの2箇所のモデル名だけ書き換えてください。
    - このペドは会話・購入処理には一切関与しません（見た目だけの演出用）。
--]]
