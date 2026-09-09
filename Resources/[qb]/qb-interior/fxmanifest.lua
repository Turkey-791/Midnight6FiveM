fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Collection of shell models with exports for creating them'
version '1.2.0'
this_is_a_map 'yes'

client_scripts {
    'client/main.lua',
    'client/optional.lua'
}

-- 2026-09-08 クラッシュ対策: stream資産22ファイル(約55MB)が ps-housing と
-- バイト単位で完全に同一だったため、qb-interior 側の配信を停止。
-- アーキタイプ(starter_shells_k4mb1.ytyp)と ymap の多重登録が
-- gta-streaming-five.dll のクラッシュ要因と判断。
-- シェル資産は ps-housing が配信する。本リソースは exports のみ提供。
-- 依存: ps-housing が停止すると qb-houserobbery のシェルが出なくなる。
-- 退避先: [_backup]/audit-fixes-2026-09-08/qb-interior_stream/
