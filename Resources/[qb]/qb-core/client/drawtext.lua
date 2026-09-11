-- ============================================================================
-- 2026-09-11 Midnight6: Text UI を ox_lib へ委譲する。
--
-- USE_OX_TEXTUI を false に戻すと、元の qb-core 独自NUI の動作に戻る(1行)。
--
-- ★ox_lib の呼び出し本体は [midnight6-custom]/ao_uibridge にある。
--   ox_lib/init.lua は「ox_lib が起動済みでなければ error」で始まり、
--   server.cfg は ensure qb-core(73行) → ensure [ox](74行) の順であるため、
--   このファイルに @ox_lib/init.lua を読み込ませると qb-core が落ちる。
--   そのため ox_lib 依存は別リソースに出し、ここからはイベントで委譲する。
--
-- 元の実装は _backup/oxlib-uibridge-20260911/drawtext.lua.orig にある。
-- ============================================================================
local USE_OX_TEXTUI = true

local function hideText()
    if USE_OX_TEXTUI then
        return TriggerEvent('ao_uibridge:textui:hide')
    end

    SendNUIMessage({
        action = 'HIDE_TEXT',
    })
end

local function drawText(text, position)
    if type(position) ~= 'string' then position = 'left' end

    if USE_OX_TEXTUI then
        return TriggerEvent('ao_uibridge:textui:show', text, position)
    end

    SendNUIMessage({
        action = 'DRAW_TEXT',
        data = {
            text = text,
            position = position
        }
    })
end

local function changeText(text, position)
    if type(position) ~= 'string' then position = 'left' end

    if USE_OX_TEXTUI then
        -- ox_lib の Text UI は表示の差し替えも showTextUI で行う
        return TriggerEvent('ao_uibridge:textui:show', text, position)
    end

    SendNUIMessage({
        action = 'CHANGE_TEXT',
        data = {
            text = text,
            position = position
        }
    })
end

local function keyPressed()
    if USE_OX_TEXTUI then
        -- 元は「押された表示を出して 500ms 後に消す」演出。
        -- ox_lib に同等の演出が無いため、そのまま閉じる。
        return TriggerEvent('ao_uibridge:textui:keyPressed')
    end

    CreateThread(function()
        SendNUIMessage({
            action = 'KEY_PRESSED',
        })
        Wait(500)
        hideText()
    end)
end

RegisterNetEvent('qb-core:client:DrawText', function(text, position)
    drawText(text, position)
end)

RegisterNetEvent('qb-core:client:ChangeText', function(text, position)
    changeText(text, position)
end)

RegisterNetEvent('qb-core:client:HideText', function()
    hideText()
end)

RegisterNetEvent('qb-core:client:KeyPressed', function()
    keyPressed()
end)

exports('DrawText', drawText)
exports('ChangeText', changeText)
exports('HideText', hideText)
exports('KeyPressed', keyPressed)
