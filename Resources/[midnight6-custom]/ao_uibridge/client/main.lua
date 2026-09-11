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

-- ---------------------------------------------------------------------------
-- Progressbar
--   qb-core の Progressbar(name, label, duration, useWhileDead, canCancel,
--                          disableControls, animation, prop, propTwo,
--                          onFinish, onCancel)
--
--   コールバックは qb-core 側がトークンで保持している。ここでは完了結果だけを
--   'ao_uibridge:progressDone' で返す(true=完走 / false=キャンセル /
--   nil=開始されなかった)。
--
--   ★挙動を元の progressbar リソースに合わせるため、以下を明示している。
--     1) ox_lib の追加中断条件(ラグドール/手錠/落下/水泳)をすべて許可する。
--        元の progressbar は「死亡」以外では中断しないため。
--        これを外すと、潜水(qb-diving)・手錠中(qb-policejob)・
--        ラグドール中の進捗が即座に中断される。
--     2) アニメの blendOut と flag を元の値にする。
--        元: blendIn 3.0 / blendOut 3.0 / duration -1 / flag = flags or 1
--        ox_lib の既定: blendOut 1.0 / flag 49 で異なる。
--     3) 実行中に再度呼ばれた場合は何もしない(元の progressbar と同じ)。
--        lib.progressBar は「前の進捗が終わるまで待つ」ため、
--        そのままだと進捗が積まれてしまう。
--     4) inv_busy(アンダースコア)を設定する。
--        ox_lib は invBusy(ox_inventory の作法)しか設定しないが、
--        QB系リソース(qb-vineyard など)は inv_busy を見ている。
-- ---------------------------------------------------------------------------
local function toVec3(v)
    if not v then return nil end
    if type(v) == 'vector3' then return v end
    if type(v) ~= 'table' then return nil end
    return vec3(v.x or 0.0, v.y or 0.0, v.z or 0.0)
end

local function convertProp(p)
    if type(p) ~= 'table' or not p.model then return nil end
    return {
        model = p.model,
        bone  = p.bone,
        pos   = toVec3(p.coords)   or vec3(0.0, 0.0, 0.0),
        rot   = toVec3(p.rotation) or vec3(0.0, 0.0, 0.0),
    }
end

AddEventHandler('ao_uibridge:progress', function(token, o)
    if type(o) ~= 'table' then return end

    -- (3) 実行中なら何もしない
    if lib.progressActive() then
        TriggerEvent('ao_uibridge:progressDone', token, nil)
        return
    end

    CreateThread(function()
        local data = {
            label        = o.label,
            duration     = tonumber(o.duration) or 0,
            useWhileDead = o.useWhileDead and true or false,
            canCancel    = o.canCancel and true or false,
            -- (1) 元の progressbar と中断条件を揃える
            allowRagdoll  = true,
            allowCuffed   = true,
            allowFalling  = true,
            allowSwimming = true,
        }

        local cd = o.controlDisables
        if type(cd) == 'table' then
            data.disable = {
                move   = cd.disableMovement    and true or false,
                car    = cd.disableCarMovement and true or false,
                mouse  = cd.disableMouse       and true or false,
                combat = cd.disableCombat      and true or false,
            }
        end

        -- (2) アニメ
        local a = o.animation
        if type(a) == 'table' then
            if a.animDict and a.anim then
                data.anim = {
                    dict         = a.animDict,
                    clip         = a.anim,
                    flag         = a.flags or 1,
                    blendIn      = 3.0,
                    blendOut     = 3.0,
                    duration     = -1,
                    playbackRate = 0,
                }
            elseif a.task then
                data.anim = { scenario = a.task }
            end
        end

        local p1, p2 = convertProp(o.prop), convertProp(o.propTwo)
        if p1 and p2 then
            data.prop = { p1, p2 }
        else
            data.prop = p1 or p2
        end

        -- (4) QB系が見ている inv_busy を立てる
        LocalPlayer.state:set('inv_busy', true, true)

        local ok, completed = pcall(lib.progressBar, data)

        LocalPlayer.state:set('inv_busy', false, true)

        if not ok then
            print(('^1[ao_uibridge] progressBar が失敗しました: %s^0'):format(tostring(completed)))
            completed = nil
        end

        TriggerEvent('ao_uibridge:progressDone', token, completed)
    end)
end)

-- qb-vehiclekeys は進行中の中断に progressbar:client:cancel を使っている
-- (車奪い中に対象が死亡 / 車が離れた場合)。ox_lib 側にも伝える。
-- lib.cancelProgress() は進捗が無いと error になるため必ず確認する。
AddEventHandler('progressbar:client:cancel', function()
    if lib.progressActive() then
        lib.cancelProgress()
    end
end)
