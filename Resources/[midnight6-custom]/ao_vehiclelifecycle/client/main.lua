-- ============================================================================
-- ao_vehiclelifecycle / client
-- デポでの引き取り時に「引き取りのみ / 修理込みで引き取り」を選ばせる。
--
-- qb-garages の NUI には手を入れず、既存の takeOutDepo コールバックから
-- このイベントへ委譲してもらう方式にしている(qb-garages 側の差分は数行)。
-- ============================================================================

local function comma(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local out = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    return (out:gsub('^,', ''))
end

RegisterNetEvent('ao_vehiclelifecycle:client:depotOptions', function(data)
    local depotPrice = tonumber(data and data.depotPrice) or 0

    -- 料金が無い(=デポ扱いではない)場合は従来どおりそのまま出庫する
    if depotPrice <= 0 or not Config.DepotRepairEnabled then
        TriggerServerEvent('qb-garages:server:PayDepotPrice', data)
        return
    end

    -- 直前までガレージのNUIが開いていたため、閉じ切るのを待ってからメニューを出す
    Wait(200)

    local repairFee = Config.DepotRepairFee or 0

    exports['qb-menu']:openMenu({
        {
            header = '車両の引き取り',
            txt = ('%s'):format(data.plate or ''),
            isMenuHeader = true,
        },
        {
            header = ('引き取りのみ　$%s'):format(comma(depotPrice)),
            txt = 'エンジンが壊れている場合、そのままでは走行できません',
            params = { event = 'ao_vehiclelifecycle:client:depotPlain', args = data },
        },
        {
            header = ('修理込みで引き取り　$%s'):format(comma(depotPrice + repairFee)),
            txt = ('引き取り $%s ＋ 修理 $%s。エンジン・車体・タイヤ・窓をすべて修復します')
                :format(comma(depotPrice), comma(repairFee)),
            params = { event = 'ao_vehiclelifecycle:client:depotRepair', args = data },
        },
        {
            header = 'キャンセル',
            params = { event = 'qb-menu:closeMenu' },
        },
    })
end)

RegisterNetEvent('ao_vehiclelifecycle:client:depotPlain', function(data)
    TriggerServerEvent('qb-garages:server:PayDepotPrice', data)
end)

RegisterNetEvent('ao_vehiclelifecycle:client:depotRepair', function(data)
    TriggerServerEvent('ao_vehiclelifecycle:server:payDepotWithRepair', data)
end)
