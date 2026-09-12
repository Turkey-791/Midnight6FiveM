-- 起動確認用。サーバーコンソールにカタログの読み込み結果を1行だけ出す。
-- (client/main.lua の print は F8 のクライアントコンソールにしか出ないため)
CreateThread(function()
    local items = 0
    if type(Catalog) == 'table' then
        for _, gender in pairs(Catalog) do
            for _, kind in pairs(gender) do
                for _, slot in pairs(kind) do
                    for _ in pairs(slot) do items = items + 1 end
                end
            end
        end
    end
    local profiles = 0
    for _ in pairs((type(Config) == 'table' and Config.StoreProfiles) or {}) do
        profiles = profiles + 1
    end
    if items == 0 then
        print('^1[ao_clothing] カタログを読み込めませんでした(data/catalog.lua を確認してください)^0')
    else
        print(('[ao_clothing] カタログ %d 点 / 店舗プロファイル %d 件 を読み込みました'):format(items, profiles))
    end
end)
