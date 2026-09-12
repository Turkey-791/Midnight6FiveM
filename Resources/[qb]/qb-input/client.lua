-- ============================================================================
-- qb-input → ox_lib Input Dialog ブリッジ   (Midnight6 / 2026-09-10)
--
-- リソース名(qb-input)と export 名(ShowInput)は元のまま維持しているため、
-- 呼び出し元 9リソース・20箇所は一切変更していません。
--
-- ★ 元の実装は _backup/oxlib-bridge-20260910/qb-input/client.lua.orig にあります。
--
-- 変換規則(調査で確定した実使用分のみ):
--   header      → lib.inputDialog の第1引数 heading
--   inputs      → 第2引数 rows(配列)
--   inputs.text → label
--   inputs.name → ox_lib には渡さず、index ↔ name の対応表として保持
--   isRequired  → required
--   options {value, text} → {value, label}   ※キー名が違うので変換が必要
--   default     → default
--
--   type: text → input / number → number / select → select
--         radio → select (ox_lib に radio 型がないためドロップダウンになる)
--         color → color
--
-- ★ 非互換1点: submitText(送信ボタンの文字)は ox_lib に該当フィールドが無いため
--   反映されません(固定表記になります)。機能への影響はありません。
--
-- 戻り値: 元の qb-input は { name = 値 } のテーブル、ox_lib は入力順の配列を返す。
--         ここで index → name に詰め替えて返すため、呼び出し元は変更不要。
--         キャンセル時に nil を返す挙動も元と同じ。
-- ============================================================================

-- ---------------------------------------------------------------------------
-- ox_lib の UI は react-markdown で描画され、rehypeRaw を入れていないため
-- <br> などの生HTMLは改行にならない。remark-breaks も無いので単独の \n も
-- 改行にならない。Markdown のハード改行(行末2スペース + 改行)へ変換する。
--   確認: ox_lib/web/build/assets/*.js に react-markdown のみ(rehypeRaw なし)
-- ---------------------------------------------------------------------------
local function mdText(s)
    if type(s) ~= 'string' then return s end
    if not s:find('<', 1, true) then return s end
    s = s:gsub('<[bB][rR]%s*/?>', '  \n')
    return s
end

local TYPE_MAP = {
    text     = 'input',
    input    = 'input',
    number   = 'number',
    select   = 'select',
    radio    = 'select',
    color    = 'color',
    checkbox = 'checkbox',
    slider   = 'slider',
    textarea = 'textarea',
    date     = 'date',
    time     = 'time',
    password = 'input',
}

local function ShowInput(data)
    if not data then return end
    local inputs = data.inputs
    if type(inputs) ~= 'table' or #inputs == 0 then return end

    local rows, names = {}, {}

    for i = 1, #inputs do
        local inp = inputs[i]
        local row = {
            type  = TYPE_MAP[inp.type] or 'input',
            label = mdText(tostring(inp.text or inp.label or inp.header or '')),
        }

        if inp.default ~= nil then row.default = inp.default end
        if inp.isRequired then row.required = true end
        if inp.min ~= nil then row.min = inp.min end
        if inp.max ~= nil then row.max = inp.max end
        if inp.type == 'password' then row.password = true end

        if type(inp.options) == 'table' then
            local opts = {}
            for j = 1, #inp.options do
                local o = inp.options[j]
                opts[j] = {
                    value = o.value,
                    label = tostring(o.text or o.label or o.value or ''),
                }
            end
            row.options = opts
        end

        rows[i]  = row
        names[i] = inp.name
    end

    local result = lib.inputDialog(mdText(tostring(data.header or '')), rows)
    if not result then return nil end

    local out = {}
    for i = 1, #names do
        if names[i] ~= nil then out[names[i]] = result[i] end
    end
    return out
end

exports('ShowInput', ShowInput)
