-- ============================================================================
-- qb-menu → ox_lib Context Menu ブリッジ   (Midnight6 / 2026-09-10)
--
-- このファイルは qb-menu の「中身だけ」を ox_lib 実装に差し替えたものです。
-- リソース名(qb-menu)と export 名(openMenu / closeMenu / showHeader)、
-- 互換イベント(qb-menu:client:openMenu / closeMenu / menuClosed)は元のまま
-- 維持しているため、呼び出し元 19リソース・65箇所は一切変更していません。
--
-- ★ 元の実装は _backup/oxlib-bridge-20260910/qb-menu/client.lua.orig にあります。
--   戻す場合はそのファイルを client.lua に上書きするだけです。
--
-- 変換規則(調査で確定した9フィールドのみが実使用):
--   header       → title
--   txt          → description
--   icon         → icon (FontAwesome) / image (画像パス・アイテム名)
--   isMenuHeader → メニュー自身の title に昇格(項目としては出さない)
--   disabled     → disabled
--   action(関数) → onSelect
--   params.event → event (client) / serverEvent (isServer) / onSelect (isAction)
--   params.args  → args (中身は見ずにそのまま渡す)
-- ============================================================================

local sharedItems = exports['qb-core']:GetShared('Items')

local MENU_ID = 'qb_menu_bridge'

-- ox_inventory の画像パス。qb-inventory/html/images は空(0ファイル)のため、
-- アイテム画像はこちらへ読み替える。
local IMAGE_BASE = 'nui://ox_inventory/web/images/'

local contextOpen  = false
local headerActive = false
local headerData   = nil
local headerThread = false

-- ---------------------------------------------------------------------------
-- 並び替え: 元の qb-menu client.lua:8-15 と同一の挙動
-- ---------------------------------------------------------------------------
local function sortData(data, skipfirst)
    local header = data[1]
    local tempData = data
    if skipfirst then table.remove(tempData, 1) end
    table.sort(tempData, function(a, b) return tostring(a.header) < tostring(b.header) end)
    if skipfirst then table.insert(tempData, 1, header) end
    return tempData
end

-- ---------------------------------------------------------------------------
-- icon の値を ox_lib の icon(FontAwesome) と image(画像) に振り分ける
-- ---------------------------------------------------------------------------
local function resolveIcon(option, icon)
    if type(icon) ~= 'string' or icon == '' then return end

    -- アイテム名で渡された場合は画像パスへ解決する(元の client.lua:20-28 と同じ意図)
    local item = sharedItems[icon]
    if item and item.image then
        option.image = IMAGE_BASE .. item.image
        return
    end

    if icon:find('^nui://') or icon:find('^https?://')
        or icon:find('%.png$') or icon:find('%.jpg$') or icon:find('%.jpeg$') then
        option.image = (icon:gsub('nui://qb%-inventory/html/images/', IMAGE_BASE))
        return
    end

    option.icon = icon
end

-- ---------------------------------------------------------------------------
-- params から ox_lib の実行フィールドを組み立てる
-- ---------------------------------------------------------------------------
local function applyParams(option, item)
    if type(item.action) == 'function' then
        option.onSelect = item.action
        return
    end

    local p = item.params
    if not p or not p.event then return end

    if p.isServer then
        option.serverEvent = p.event
        option.args = p.args
    elseif p.isAction then
        local fn, args = p.event, p.args
        option.onSelect = function() fn(args) end
    elseif p.isCommand then
        local cmd = p.event
        option.onSelect = function() ExecuteCommand(cmd) end
    elseif p.isQBCommand then
        local cmd, args = p.event, p.args
        option.onSelect = function() TriggerServerEvent('QBCore:CallCommand', cmd, args) end
    else
        option.event = p.event
        option.args = p.args
    end
end

local function buildOptions(data)
    local title, options = nil, {}
    for i = 1, #data do
        local v = data[i]
        if type(v) == 'table' then
            if v.isMenuHeader then
                title = tostring(v.header or '')
                if v.txt and v.txt ~= '' then title = title .. ' — ' .. tostring(v.txt) end
            else
                local option = {
                    title = tostring(v.header or ''),
                    description = v.txt,
                }
                resolveIcon(option, v.icon)
                if v.disabled then option.disabled = true end
                applyParams(option, v)
                options[#options + 1] = option
            end
        end
    end
    return title, options
end

-- ---------------------------------------------------------------------------
-- 単一項目を直接実行する(showHeader の [E] 押下用)
-- ---------------------------------------------------------------------------
local function runItem(item)
    if type(item.action) == 'function' then
        item.action()
        return
    end
    local p = item.params
    if not p or not p.event then return end
    if p.isServer then
        TriggerServerEvent(p.event, p.args)
    elseif p.isAction then
        p.event(p.args)
    elseif p.isCommand then
        ExecuteCommand(p.event)
    elseif p.isQBCommand then
        TriggerServerEvent('QBCore:CallCommand', p.event, p.args)
    else
        TriggerEvent(p.event, p.args)
    end
end

-- ---------------------------------------------------------------------------
-- exports
-- ---------------------------------------------------------------------------
local function hideHeader()
    if not headerActive then return end
    headerActive = false
    headerData = nil
    lib.hideTextUI()
end

local function closeMenu()
    hideHeader()
    if contextOpen then
        contextOpen = false
        lib.hideContext(false) -- onExit は呼ばない(元の closeMenu も menuClosed を出さない)
    end
end

local function openMenu(data, sort, skipFirst)
    if not data or not next(data) then return end
    hideHeader()

    if sort then data = sortData(data, skipFirst) end

    local title, options = buildOptions(data)
    if #options == 0 then return end

    contextOpen = true
    lib.registerContext({
        id = MENU_ID,
        title = title or '',
        options = options,
        onExit = function()
            contextOpen = false
            TriggerEvent('qb-menu:client:menuClosed')
        end,
    })
    lib.showContext(MENU_ID)
end

local function startHeaderThread()
    if headerThread then return end
    headerThread = true
    CreateThread(function()
        while headerActive do
            if IsControlJustReleased(0, 38) then -- E
                local data = headerData
                hideHeader()
                if data then
                    if #data == 1 then
                        runItem(data[1])
                    else
                        openMenu(data)
                    end
                end
                break
            end
            Wait(0)
        end
        headerThread = false
    end)
end

-- 元の showHeader は「画面上部にヘッダー行を出しっぱなしにし、LMENU でカーソルを
-- 出してクリックさせる」UIだった。ox_lib に等価物が無いため [E] キー方式に置き換える
-- (2026-09-09 AO承認)。項目が1つなら直接実行、複数なら Context Menu を開く。
local function showHeader(data)
    if not data or not next(data) then return end

    headerData = data
    local label
    if #data == 1 then
        label = tostring(data[1].header or '')
    elseif data[1] and data[1].isMenuHeader then
        label = tostring(data[1].header or '')
    else
        label = 'メニューを開く'
    end

    headerActive = true
    lib.showTextUI(('[E] %s'):format(label))
    startHeaderThread()
end

-- ---------------------------------------------------------------------------
-- 互換イベント
-- ---------------------------------------------------------------------------
RegisterNetEvent('qb-menu:client:openMenu', function(data, sort, skipFirst)
    openMenu(data, sort, skipFirst)
end)

RegisterNetEvent('qb-menu:client:closeMenu', function()
    closeMenu()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    hideHeader()
end)

exports('openMenu', openMenu)
exports('closeMenu', closeMenu)
exports('showHeader', showHeader)
