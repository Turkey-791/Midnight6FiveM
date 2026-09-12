-- ao_clothing / client
--
-- 「いまいる店で買える drawable はどれか」を判定し、illenium-appearance が使える
-- ブラックリスト形式 { drawables = {...}, textures = {} } で返す。
--
-- Phase 3 時点では、このエクスポートを呼んでいるリソースは存在しない。
-- したがってこのリソースを追加してもゲームの挙動は一切変わらない。
-- 実際に店舗差別化が効き始めるのは Phase 4(illenium 側へのパッチ)から。

local Allowed        = {}    -- [profileId][gender][kind][slotId] = { [drawable] = true }
local CurrentProfile = nil   -- いまいる店のプロファイルID。nil = 店外 = 制限なし
local Ready          = false

local GENDERS = { 'male', 'female' }
local KINDS   = { 'components', 'props' }

local function hasTag(entry, tag)
    for i = 2, #entry do
        if entry[i] == tag then return true end
    end
    return false
end

local function slotEnabled(profile, kind, slotId)
    if not profile.slots then return true end          -- 指定なし = 全スロット扱う
    local t = profile.slots[kind]
    if not t then return false end
    return t[slotId] == true
end

local function build()
    if type(Catalog) ~= 'table' then
        print('^1[ao_clothing] data/catalog.lua が読み込まれていません。フィルタは無効のままです^0')
        return
    end
    if type(Config) ~= 'table' or type(Config.StoreProfiles) ~= 'table' then
        print('^1[ao_clothing] config.lua が読み込まれていません。フィルタは無効のままです^0')
        return
    end

    for pid, profile in pairs(Config.StoreProfiles) do
        local tagset = {}
        for _, t in ipairs(profile.tags or {}) do tagset[t] = true end

        Allowed[pid] = {}
        for _, gender in ipairs(GENDERS) do
            local src = Catalog[gender]
            if src then
                Allowed[pid][gender] = { components = {}, props = {} }
                for _, kind in ipairs(KINDS) do
                    local byslot = src[kind]
                    if byslot then
                        for slotId, items in pairs(byslot) do
                            -- 構造的なスロットは許可セットを作らない。
                            -- 未構築 = 空のブラックリスト = 制限なし、として扱われる。
                            local skip = (kind == 'components' and Config.UnfilteredComponents[slotId])
                                      or (kind == 'props' and Config.UnfilteredProps[slotId])
                            local set     = {}
                            local enabled = slotEnabled(profile, kind, slotId)
                            for drawable, entry in pairs(items) do
                                -- always(装着なし)はティア・タグ・スロット指定を無視して常に許可
                                local ok = hasTag(entry, 'always')
                                if not ok and enabled then
                                    local tier = entry[1]
                                    if tier >= profile.tierMin and tier <= profile.tierMax then
                                        for i = 2, #entry do
                                            if tagset[entry[i]] then ok = true; break end
                                        end
                                    end
                                end
                                if ok then set[drawable] = true end
                            end
                            if not skip then
                                Allowed[pid][gender][kind][slotId] = set
                            end
                        end
                    end
                end
            end
        end
    end
    Ready = true
end

--- いまいる店で許可されていない drawable を列挙して返す。
--  カタログに載っていないスロット(髪・顔・アーマー)や店外では空を返す = 制限なし。
local function blacklistFor(kind, gender, slotId, maxDrawable)
    if not Ready then build() end          -- 起動順の都合で未構築なら、その場で作る
    if not Ready or not CurrentProfile then return { drawables = {}, textures = {} } end

    local byGender = Allowed[CurrentProfile]
    if not byGender then return { drawables = {}, textures = {} } end
    local byKind = byGender[gender]
    if not byKind then return { drawables = {}, textures = {} } end
    local set = byKind[kind] and byKind[kind][slotId]
    if not set then return { drawables = {}, textures = {} } end

    local out = {}
    for d = 0, (maxDrawable or -1) do
        if not set[d] then out[#out + 1] = d end
    end
    return { drawables = out, textures = {} }
end

-- ===== エクスポート(Phase 4 で illenium-appearance から呼ぶ) =====

--- 入店時に呼ぶ。illenium の Config.Stores のインデックス(数値)か、
--  プロファイルID(文字列。'_starter' / 'casino' など)を渡す。
exports('SetCurrentStore', function(ref)
    if not Ready then build() end
    if type(ref) == 'number' then
        CurrentProfile = Config.IlleniumStoreMap[ref]
    elseif type(ref) == 'string' and Config.StoreProfiles[ref] then
        CurrentProfile = ref
    else
        CurrentProfile = nil
    end
    return CurrentProfile
end)

--- 退店時に呼ぶ。以降は制限なしに戻る。
exports('ClearCurrentStore', function()
    CurrentProfile = nil
end)

exports('GetCurrentStore', function()
    return CurrentProfile
end)

--- gender は illenium と同じ 'male' / 'female'。
--  maxDrawable は GetNumberOfPedDrawableVariations(ped, componentId) - 1 を渡す。
exports('GetComponentBlacklist', function(gender, componentId, maxDrawable)
    return blacklistFor('components', gender, componentId, maxDrawable)
end)

--- maxDrawable は GetNumberOfPedPropDrawableVariations(ped, propId) - 1 を渡す。
--  prop の -1(装着なし)は列挙しないので常に選べる。
exports('GetPropBlacklist', function(gender, propId, maxDrawable)
    return blacklistFor('props', gender, propId, maxDrawable)
end)

-- ===== 起動 =====

local function countItems()
    local n = 0
    for _, gender in ipairs(GENDERS) do
        local src = Catalog and Catalog[gender]
        if src then
            for _, kind in ipairs(KINDS) do
                for _, items in pairs(src[kind] or {}) do
                    for _ in pairs(items) do n = n + 1 end
                end
            end
        end
    end
    return n
end

--- 動作確認用コマンド。いまいる店と、スロットごとに何点選べるかを F8 コンソールに出す。
RegisterCommand('ao_clothing_status', function()
    if not Ready then build() end
    if not Ready then
        print('^1[ao_clothing] カタログが読み込めていません^0')
        return
    end
    local pid = CurrentProfile
    print(('[ao_clothing] 現在の店舗: %s'):format(
        pid and (pid .. ' / ' .. (Config.StoreProfiles[pid].label or '')) or '(店外 = 制限なし)'))
    if not pid then return end
    local g = IsPedMale(PlayerPedId()) and 'male' or 'female'
    local NAMES = { [11] = 'トップス', [3] = '腕', [8] = 'インナー', [4] = 'パンツ',
                    [6] = '靴', [1] = 'マスク', [7] = 'アクセ', [5] = 'バッグ', [10] = 'デカール' }
    for _, cid in ipairs({ 11, 3, 8, 4, 6, 1, 7, 5, 10 }) do
        local set = Allowed[pid] and Allowed[pid][g] and Allowed[pid][g].components[cid]
        local n = 0
        if set then for _ in pairs(set) do n = n + 1 end end
        print(('  component %-3d %-9s %s'):format(cid, NAMES[cid] or '?',
            set and (n .. ' 点') or 'フィルタなし(全部選べる)'))
    end
end, false)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    build()
    if not Ready then return end

    local profiles = 0
    for _ in pairs(Config.StoreProfiles) do profiles = profiles + 1 end
    print(('[ao_clothing] 読込完了 — 商品 %d 点 / 店舗プロファイル %d 件(まだどこからも参照されていません)')
        :format(countItems(), profiles))

    if Config.Debug then
        for pid, profile in pairs(Config.StoreProfiles) do
            local n = 0
            for _, gender in ipairs(GENDERS) do
                for _, kind in ipairs(KINDS) do
                    for _, set in pairs(Allowed[pid][gender][kind]) do
                        for _ in pairs(set) do n = n + 1 end
                    end
                end
            end
            print(('[ao_clothing]   %-18s %-28s %5d 点'):format(pid, profile.label, n))
        end
    end
end)
