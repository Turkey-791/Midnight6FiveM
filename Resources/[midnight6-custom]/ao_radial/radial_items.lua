-- ============================================================================
-- 自動生成ファイル / DO NOT EDIT BY HAND
-- 生成元 : [qb]/qb-radialmenu/config.lua
-- 生成日 : 2026-09-11
--
-- qb-radialmenu の静的メニュー定義を ox_lib radial 用のデータへ機械変換したもの。
-- title→label / shouldClose=false→keepOpen / items→別メニューID(menu) へ対応。
-- event と etype は client/main.lua 側で onSelect クロージャに変換する。
-- ============================================================================

-- client/main.lua から参照するためグローバルに置く
AoRadialData = {
    root = {
        { id = 'citizen', label = '市民', icon = 'user', menu = 'ao_citizen' },
        { id = 'general', label = '一般', icon = 'rectangle-list', menu = 'ao_general' }
    },

    jobs = {
        ['ambulance'] = 'ao_job_ambulance',
        ['hotdog'] = 'ao_job_hotdog',
        ['mechanic'] = 'ao_job_mechanic',
        ['police'] = 'ao_job_police',
        ['reporter'] = 'ao_job_reporter',
        ['taxi'] = 'ao_job_taxi',
        ['tow'] = 'ao_job_tow',
    },

    menus = {
        ['ao_interactions'] = {
            { id = 'handcuff', label = '手錠をかける', icon = 'user-lock', event = 'police:client:CuffPlayerSoft', etype = 'client' },
            { id = 'playerinvehicle', label = '車両に乗せる', icon = 'car-side', event = 'police:client:PutPlayerInVehicle', etype = 'client' },
            { id = 'playeroutvehicle', label = '車両から降ろす', icon = 'car-side', event = 'police:client:SetPlayerOutVehicle', etype = 'client' },
            { id = 'stealplayer', label = '強盗する', icon = 'mask', event = 'police:client:RobPlayer', etype = 'client' },
            { id = 'escort', label = '誘拐する', icon = 'user-group', event = 'police:client:KidnapPlayer', etype = 'client' },
            { id = 'escort2', label = '護送する', icon = 'user-group', event = 'police:client:EscortPlayer', etype = 'client' },
            { id = 'escort554', label = '人質にする', icon = 'child', event = 'A5:Client:TakeHostage', etype = 'client' }
        },
        ['ao_citizen'] = {
            { id = 'givenum', label = '連絡先を教える', icon = 'address-book', event = 'qb-phone:client:GiveContactDetails', etype = 'client' },
            { id = 'getintrunk', label = 'トランクに入る', icon = 'car', event = 'qb-trunk:client:GetIn', etype = 'client' },
            { id = 'cornerselling', label = '路上販売', icon = 'cannabis', event = 'qb-drugs:client:cornerselling', etype = 'client' },
            { id = 'togglehotdogsell', label = 'ホットドッグ販売', icon = 'hotdog', event = 'qb-hotdogjob:client:ToggleSell', etype = 'client' },
            { id = 'interactions', label = 'インタラクション', icon = 'triangle-exclamation', menu = 'ao_interactions' }
        },
        ['ao_meer'] = {
            { id = 'Hat', label = '帽子', icon = 'hat-cowboy-side', event = 'qb-radialmenu:ToggleProps', etype = 'client' },
            { id = 'Glasses', label = 'メガネ', icon = 'glasses', event = 'qb-radialmenu:ToggleProps', etype = 'client' },
            { id = 'Visor', label = 'バイザー', icon = 'hat-cowboy-side', event = 'qb-radialmenu:ToggleProps', etype = 'client' },
            { id = 'Mask', label = 'マスク', icon = 'masks-theater', event = 'qb-radialmenu:ToggleClothing', etype = 'client' },
            { id = 'Vest', label = 'ベスト', icon = 'vest', event = 'qb-radialmenu:ToggleClothing', etype = 'client' },
            { id = 'Bag', label = 'バッグ', icon = 'bag-shopping', event = 'qb-radialmenu:ToggleClothing', etype = 'client' },
            { id = 'Bracelet', label = 'ブレスレット', icon = 'user', event = 'qb-radialmenu:ToggleProps', etype = 'client' },
            { id = 'Watch', label = '時計', icon = 'stopwatch', event = 'qb-radialmenu:ToggleProps', etype = 'client' },
            { id = 'Gloves', label = '手袋', icon = 'mitten', event = 'qb-radialmenu:ToggleClothing', etype = 'client' }
        },
        ['ao_clothesmenu'] = {
            { id = 'Hair', label = '髪', icon = 'user', event = 'qb-radialmenu:ToggleClothing', etype = 'client' },
            { id = 'Ear', label = '耳飾り', icon = 'ear-deaf', event = 'qb-radialmenu:ToggleProps', etype = 'client' },
            { id = 'Neck', label = '首飾り', icon = 'user-tie', event = 'qb-radialmenu:ToggleClothing', etype = 'client' },
            { id = 'Top', label = 'トップス', icon = 'shirt', event = 'qb-radialmenu:ToggleClothing', etype = 'client' },
            { id = 'Shirt', label = 'シャツ', icon = 'shirt', event = 'qb-radialmenu:ToggleClothing', etype = 'client' },
            { id = 'Pants', label = 'パンツ', icon = 'user', event = 'qb-radialmenu:ToggleClothing', etype = 'client' },
            { id = 'Shoes', label = '靴', icon = 'shoe-prints', event = 'qb-radialmenu:ToggleClothing', etype = 'client' },
            { id = 'meer', label = 'その他', icon = 'plus', menu = 'ao_meer' }
        },
        ['ao_general'] = {
            { id = 'clothesmenu', label = '服装', icon = 'shirt', menu = 'ao_clothesmenu' }
        },
        ['ao_vehicledoors'] = {
            { id = 'door0', label = '運転席ドア', icon = 'car-side', event = 'qb-radialmenu:client:openDoor', etype = 'client', keepOpen = true },
            { id = 'door4', label = 'ボンネット', icon = 'car', event = 'qb-radialmenu:client:openDoor', etype = 'client', keepOpen = true },
            { id = 'door1', label = '助手席ドア', icon = 'car-side', event = 'qb-radialmenu:client:openDoor', etype = 'client', keepOpen = true },
            { id = 'door3', label = '右後部', icon = 'car-side', event = 'qb-radialmenu:client:openDoor', etype = 'client', keepOpen = true },
            { id = 'door5', label = 'トランク', icon = 'car', event = 'qb-radialmenu:client:openDoor', etype = 'client', keepOpen = true },
            { id = 'door2', label = '左後部', icon = 'car-side', event = 'qb-radialmenu:client:openDoor', etype = 'client', keepOpen = true }
        },
        ['ao_vehicleextras'] = {
            { id = 'extra1', label = 'エクストラ 1', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra2', label = 'エクストラ 2', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra3', label = 'エクストラ 3', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra4', label = 'エクストラ 4', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra5', label = 'エクストラ 5', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra6', label = 'エクストラ 6', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra7', label = 'エクストラ 7', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra8', label = 'エクストラ 8', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra9', label = 'エクストラ 9', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra10', label = 'エクストラ 10', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra11', label = 'エクストラ 11', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra12', label = 'エクストラ 12', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true },
            { id = 'extra13', label = 'エクストラ 13', icon = 'box-open', event = 'qb-radialmenu:client:setExtra', etype = 'client', keepOpen = true }
        },
        ['ao_stretcheroptions'] = {
            { id = 'spawnstretcher', label = 'ストレッチャーを出す', icon = 'plus', event = 'qb-radialmenu:client:TakeStretcher', etype = 'client', keepOpen = true },
            { id = 'despawnstretcher', label = 'ストレッチャーを片付ける', icon = 'minus', event = 'qb-radialmenu:client:RemoveStretcher', etype = 'client', keepOpen = true }
        },
        ['ao_job_ambulance'] = {
            { id = 'statuscheck', label = '健康状態を確認', icon = 'heart-pulse', event = 'hospital:client:CheckStatus', etype = 'client' },
            { id = 'revivep', label = '蘇生する', icon = 'user-doctor', event = 'hospital:client:RevivePlayer', etype = 'client' },
            { id = 'treatwounds', label = '傷を治療する', icon = 'bandage', event = 'hospital:client:TreatWounds', etype = 'client' },
            { id = 'emergencybutton2', label = '緊急ボタン', icon = 'bell', event = 'police:client:SendPoliceEmergencyAlert', etype = 'client' },
            { id = 'escort', label = '護送する', icon = 'user-group', event = 'police:client:EscortPlayer', etype = 'client' },
            { id = 'stretcheroptions', label = 'ストレッチャー', icon = 'bed-pulse', menu = 'ao_stretcheroptions' }
        },
        ['ao_job_taxi'] = {
            { id = 'togglemeter', label = 'メーターを表示/非表示', icon = 'eye-slash', event = 'qb-taxi:client:toggleMeter', etype = 'client', keepOpen = true },
            { id = 'togglemouse', label = 'メーターを開始/停止', icon = 'hourglass-start', event = 'qb-taxi:client:enableMeter', etype = 'client' },
            { id = 'npc_mission', label = 'NPCミッション', icon = 'taxi', event = 'qb-taxi:client:DoTaxiNpc', etype = 'client' }
        },
        ['ao_job_tow'] = {
            { id = 'togglenpc', label = 'NPCを切り替える', icon = 'toggle-on', event = 'jobs:client:ToggleNpc', etype = 'client' },
            { id = 'towvehicle', label = '車両を牽引する', icon = 'truck-pickup', event = 'qb-tow:client:TowVehicle', etype = 'client' }
        },
        ['ao_job_mechanic'] = {
            { id = 'towvehicle', label = '車両を牽引する', icon = 'truck-pickup', event = 'qb-tow:client:TowVehicle', etype = 'client' }
        },
        ['ao_policeinteraction'] = {
            { id = 'statuscheck', label = '健康状態を確認', icon = 'heart-pulse', event = 'hospital:client:CheckStatus', etype = 'client' },
            { id = 'checkstatus', label = '状態を確認', icon = 'question', event = 'police:client:CheckStatus', etype = 'client' },
            { id = 'escort', label = '護送する', icon = 'user-group', event = 'police:client:EscortPlayer', etype = 'client' },
            { id = 'searchplayer', label = '捜索する', icon = 'magnifying-glass', event = 'police:server:SearchPlayer', etype = 'server' },
            { id = 'jailplayer', label = '逮捕する', icon = 'user-lock', event = 'police:client:JailPlayer', etype = 'client' }
        },
        ['ao_policeobjects'] = {
            { id = 'spawnpion', label = 'コーン', icon = 'triangle-exclamation', event = 'police:client:spawnCone', etype = 'client', keepOpen = true },
            { id = 'spawnhek', label = 'ゲート', icon = 'torii-gate', event = 'police:client:spawnBarrier', etype = 'client', keepOpen = true },
            { id = 'spawnschotten', label = '制限速度標識', icon = 'sign-hanging', event = 'police:client:spawnRoadSign', etype = 'client', keepOpen = true },
            { id = 'spawntent', label = 'テント', icon = 'campground', event = 'police:client:spawnTent', etype = 'client', keepOpen = true },
            { id = 'spawnverlichting', label = '照明', icon = 'lightbulb', event = 'police:client:spawnLight', etype = 'client', keepOpen = true },
            { id = 'spikestrip', label = 'スパイクストリップ', icon = 'caret-up', event = 'police:client:SpawnSpikeStrip', etype = 'client', keepOpen = true },
            { id = 'deleteobject', label = 'オブジェクトを削除', icon = 'trash', event = 'police:client:deleteObject', etype = 'client', keepOpen = true }
        },
        ['ao_job_police'] = {
            { id = 'emergencybutton', label = '緊急ボタン', icon = 'bell', event = 'police:client:SendPoliceEmergencyAlert', etype = 'client' },
            { id = 'checkvehstatus', label = '改造状態を確認', icon = 'circle-info', event = 'qb-tunerchip:client:TuneStatus', etype = 'client' },
            { id = 'takedriverlicense', label = '運転免許を取り消す', icon = 'id-card', event = 'police:client:SeizeDriverLicense', etype = 'client' },
            { id = 'policeinteraction', label = '警察アクション', icon = 'list-check', menu = 'ao_policeinteraction' },
            { id = 'policeobjects', label = 'オブジェクト', icon = 'road', menu = 'ao_policeobjects' }
        },
        ['ao_job_hotdog'] = {
            { id = 'togglesell', label = '販売を切り替える', icon = 'hotdog', event = 'qb-hotdogjob:client:ToggleSell', etype = 'client' }
        },
        ['ao_job_reporter'] = {
            { id = 'newsassignment', label = '取材依頼を受ける', icon = 'newspaper', event = 'qb-newsjob:server:requestAssignment', etype = 'server' }
        },
    },
}
