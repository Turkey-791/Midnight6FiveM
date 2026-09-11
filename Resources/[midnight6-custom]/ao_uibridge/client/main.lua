-- ============================================================================
-- ao_uibridge — qb-core の Text UI / Notify を ox_lib へ橋渡しする
-- (Midnight6 / 2026-09-11)
--
-- 【なぜ別リソースなのか】
--   ox_lib/init.lua の冒頭に
--       if GetResourceState('ox_lib') ~= 'started' then error(...) end
--   があり、server.cfg は ensure qb-core(73行) → ensure [ox](74行) の順である。
--   そのため qb-core に @ox_lib/init.lua を足すと qb-core が読み込みエラーで落ち、
--   サーバー全体が起動しなくなる。
--   → ox_lib の呼び出しはこのリソース([ox] より後に起動)に置き、
--     qb-core からはイベントで委譲する。qb-core に ox 依存を持たせない。
--
-- 【qb-core 側の対応】
--   qb-core/client/drawtext.lua       … USE_OX_TEXTUI フラグで委譲
--   qb-core/client/functions.lua      … USE_OX_NOTIFY  フラグで委譲
--   どちらも false に戻せば元の qb-core NUI に戻る(1行)。
--
-- 【既知の制約】
--   ox_lib の Text UI は画面に1つしか出せない(シングルトン)。
--   従来は qb-core の Text UI と qb-menu の showHeader が別NUIだったため
--   同時表示できたが、これ以降は後から出した方が前のものを上書きする。
-- ============================================================================

-- qb-core の position('left' / 'right' / 'top')を ox_lib の表記へ
local POSITION = {
    left   = 'left-center',
    right  = 'right-center',
    top    = 'top-center',
    bottom = 'bottom-center',
}

-- qb-core の通知種別 → ox_lib の NotificationType('info' / 'warning' / 'success' / 'error')
-- 稼働中コードで使われているのは error / success / primary / police / ambulance の5種のみ。
local NOTIFY_TYPE = {
    success   = 'success',
    error     = 'error',
    warning   = 'warning',
    primary   = 'info',
    police    = 'info',
    ambulance = 'info',
    info      = 'info',
}

-- ---------------------------------------------------------------------------
-- Text UI
-- ---------------------------------------------------------------------------
AddEventHandler('ao_uibridge:textui:show', function(text, position)
    if type(text) ~= 'string' or text == '' then return end
    lib.showTextUI(text, { position = POSITION[position] or POSITION.left })
end)

AddEventHandler('ao_uibridge:textui:hide', function()
    lib.hideTextUI()
end)

-- 元の KeyPressed は「押された表示を出して 500ms 後に消す」だった。
-- ox_lib に同等の演出が無いため、そのまま閉じる。
AddEventHandler('ao_uibridge:textui:keyPressed', function()
    lib.hideTextUI()
end)

-- ---------------------------------------------------------------------------
-- Notify
--   qb-core の Notify(text, texttype, length, icon)。
--   text はテーブル({ text = , caption = })で渡ってくることもある。
-- ---------------------------------------------------------------------------
AddEventHandler('ao_uibridge:notify', function(text, texttype, length, icon)
    local data = {
        type     = NOTIFY_TYPE[texttype] or 'info',
        duration = tonumber(length) or 5000,
    }

    if type(text) == 'table' then
        data.title       = text.caption
        data.description = text.text or 'Placeholder'
    else
        data.description = tostring(text)
    end

    if icon and icon ~= '' then data.icon = icon end

    lib.notify(data)
end)
