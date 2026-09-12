Config = {}

-- ============================================================================
-- CORE SETTINGS
-- ============================================================================

Config.Debug = GetConvar('police_debug', 'false') == 'true'
Config.Framework = 'qbcore'  -- [Midnight6移植] ox_core → QBCore

-- ============================================================================
-- [Midnight6移植] M6 追加設定
-- ============================================================================

Config.M6 = {
    -- 収監は qb-prison に一本化する。false にすると RDE 独自の留置場が復活する
    useQbPrison = true,

    -- qb-prison の刑期は「1 = 60秒」で減る実装(qb-prison/client/main.lua 287-297)。
    -- RDE 側の刑期は秒なので、渡すときに 60 で割る。最低値は下の minUnits。
    jailSecondsPerUnit = 60,
    jailMinUnits       = 1,

    -- 捕縛(AI警官に倒された場合)
    capture = {
        enabled          = true,   -- true: 病院送りではなく刑務所で目覚める
        copDistance      = 30.0,   -- 倒れた地点からこの距離内にAI警官がいれば捕縛
        delayMs          = 4000,   -- 倒れてから収監処理を始めるまでの待ち時間
        jailTimeFactor   = 1.0,    -- 通常逮捕の刑期に対する倍率

        -- 収監後に「刑務所で起き上がらせる」処理の設定。
        -- qb-ambulancejob の瀕死確定は遅れて入る(laststand.lua 39-70: Wait(1000) +
        -- ラグドールが止まるまで待ってから InLaststand = true)。
        -- そのため蘇生は1回送るだけでは取りこぼす。到着後に監視して、
        -- 倒れている間は蘇生を送り直す。
        wakeWindowMs     = 20000,  -- 収監後、この時間だけ「倒れていないか」を監視する
        wakeIntervalMs   = 1000,   -- 監視の間隔
        wakeMinGapMs     = 1500,   -- 蘇生を送り直す最短間隔(通知の連発防止)
    },

    -- プレイヤー警察の人数による AI 出動台数の倍率
    -- key = 勤務中の警察人数 / value = 出動台数の倍率(0 で出動しない)
    policeFactor = {
        [0] = 1.0,
        [1] = 0.5,
        [2] = 0.25,
        [3] = 0.0,
    },
    policeFactorDefault = 0.0,  -- 表にない人数(4人以上)の倍率
    countOnlyOnDuty     = true, -- 勤務中のみを数える

    -- コマンド名の接頭辞(qb-policejob の jail/unjail と衝突するため)
    commandPrefix = 'aipd',

    -- 降伏したときに、警官がこの距離まで近づいたら逮捕する
    -- (元は arrestDistance 1.0〜2.5m しかなく、遠くの警官は撃ち続けていた)
    surrenderArrestDistance = 3.5,

    -- 手配レベルごとの刑期(qb-prison の単位 = 1 で約60秒)
    -- 例: 5 = 約5分。ここが実際の服役時間になるので、運用しながら調整する
    jailUnitsByLevel = {
        [1] = 5,
        [2] = 10,
        [3] = 15,
        [4] = 25,
        [5] = 40,
    },

    -- 刑務所にいる間は手配を付けない(刑務官を殴ってもAI警察は出動しない)
    noWantedWhileJailed = true,

    -- 警察職のプレイヤーには手配を付けない。
    -- これが false だと、警官が犯人に発砲しただけで自分が手配され、
    -- AI警察に追われる(元のRDEにはこの除外が無かった)。
    -- countOnlyOnDuty = true のときは「勤務中の警官」だけが対象。
    policeExemptFromWanted = true,

    -- ────────────────────────────────────────────────────────────
    -- 逃げ切り(手配の自然減衰)の難易度
    --   ・警官に見られていない状態が timeBeforeDecay 秒続くと減衰が始まる
    --   ・以後、下の間隔ごとに手配が1段階下がる
    --   ・手配が高いほど逃げ切りに時間がかかる
    -- ────────────────────────────────────────────────────────────
    decay = {
        timeBeforeDecay = 20,   -- 見られなくなってから減衰開始までの秒数
        intervalByLevel = {
            [1] = 20,
            [2] = 30,
            [3] = 45,
            [4] = 60,
            [5] = 90,
        },
    },

    -- 目撃者がいなくても必ず通報される犯罪。
    -- 警官への攻撃・殺害は、無線と本部側の把握があるので目撃者を必要としない。
    -- これが無いと「誰も見ていない場所で警官を殺す」が最も安全な行動になってしまう。
    alwaysReported = {
        MURDER_COP  = true,
        ASSAULT_COP = true,
    },

    -- 警官を殺した直後は、手配の自然減衰(逃げ切り判定)を一定時間止める
    decayBlockAfterCopKill = 60,    -- 秒。0 で無効。[Midnight6調整] 120 → 60

    -- 「音で気づく」犯罪。銃声などは見ていなくても気づくので、
    -- この距離内のNPCは視野・遮蔽の判定を飛ばして目撃者候補にする。
    hearing = {
        enabled = true,
        radius  = 70.0,
        crimes  = {
            SHOOTING    = true,
            MURDER      = true,
            MURDER_COP  = true,
            ASSAULT_COP = true,
            HIT_AND_RUN = true,
        },
    },

    -- 目撃者の通報しやすさ(エリア別)。Midnight6 は人口密度が低いので既定より高め
    phoneChanceByArea = {
        CITY_CENTER = 0.85,
        URBAN       = 0.75,
        SUBURBAN    = 0.60,
        RURAL       = 0.45,
        WILDERNESS  = 0.25,
    },

    -- 薬物所持の判定に使うアイテム名(部分一致)。Midnight6 の品目に合わせて調整する
    drugKeywords = {
        'weed', 'cocaine', 'coke_', 'heroin', 'meth', 'oxy',
        'crack', 'joint', 'drug_', 'drugs_',
    },
}
Config.UseStateBags = true  -- ALWAYS USE STATEBAGS FOR REALTIME SYNC!
Config.SyncInterval = 500
Config.OptimizationMode = true

-- ============================================================================
-- ADMIN & POLICE JOBS
-- ============================================================================

Config.AdminGroups = {
    'owner',
    'admin',
    'superadmin',
    'god',
    'mod'
}

Config.PoliceJobs = {
    'police',
    'sheriff',
    'leo',
    'trooper'
}

-- 🔥 ADMIN EXEMPTION SETTINGS (NEW!)
Config.AdminSettings = {
    exemptFromWanted = false,        -- Admins don't get wanted levels
    exemptFromArrest = false,        -- Admins can't be arrested
    exemptFromJail = false,          -- Admins can't be jailed
    showAdminCrimes = true,         -- Show crimes in console even if exempt
    allowAdminCommands = true       -- Allow admin commands while on duty
}

-- ============================================================================
-- WANTED LEVELS - ULTRA REALISTIC
-- ============================================================================
-- [Midnight6メモ] 実際に出てくるもの(コードで確認済み)
--   Lv1: 2台 警官(cop) 拳銃        命中25 装甲0   非武装には撃たない
--   Lv2: 3台 警官/保安官 +ショットガン 命中35 装甲25  非武装には撃たない
--   Lv3: 4台 SWAT/保安官/FBI ライフル 命中45 装甲50  非武装には撃たない
--   Lv4: 5台 riot/fbi2/police3      命中50 装甲75  非武装には撃たない
--   Lv5: 6台 riot/fbi2/police4      命中60 装甲100 ★非武装でも撃つ
--   ・台数は「プレイヤー警察の人数による倍率」が掛かる(警察1人なら0.5倍)
--   ・ヘリは出ない(useHelicopters / useRoadblocks の設定はコードから参照されていない)
--   ・車両追跡中のロードブロックは、レベルに関係なく発生する
--   ・逮捕を狙う挙動は Lv1〜4。Lv5 だけ射殺前提になる
-- ============================================================================

Config.WantedLevels = {
    [0] = {
        label = "No Warrant",
        icon = "fa-solid fa-shield-check",
        time = 0,
        blip = {sprite = 0, color = 0, scale = 0.0},
        dispatchPriority = 'none'
    },
    [1] = {
        label = "Minor Warrant",
        icon = "fa-solid fa-exclamation",
        time = 90,
        blip = {sprite = 56, color = 5, scale = 0.6},
        dispatchPriority = 'low',
        peds = {
            amount = 2,
            models = {"s_m_y_cop_01"},
            weapons = {"WEAPON_PISTOL"},
            vehicles = {"police", "police2"},
            armor = 0,
            accuracy = 25,
            arrestDistance = 2.5,
            shootUnarmed = false,
            spawnDistance = 350.0,
            chaseSpeed = 25.0,
            combatRange = 40.0,
            fleeThreshold = 30,
            useCovers = false,
            tackleProbability = 0.15
        }
    },
    [2] = {
        label = "Standard Warrant",
        icon = "fa-solid fa-exclamation-circle",
        time = 150,
        blip = {sprite = 56, color = 3, scale = 0.7},
        dispatchPriority = 'normal',
        peds = {
            amount = 3,
            models = {"s_m_y_cop_01", "s_m_y_sheriff_01"},
            weapons = {"WEAPON_PISTOL", "WEAPON_PUMPSHOTGUN"},
            vehicles = {"police", "police2", "sheriff"},
            armor = 25,
            accuracy = 35,
            arrestDistance = 2.0,
            shootUnarmed = false,
            spawnDistance = 350.0,
            chaseSpeed = 35.0,
            combatRange = 50.0,
            fleeThreshold = 20,
            useCovers = true,
            tackleProbability = 0.25
        }
    },
    [3] = {
        label = "Serious Warrant",
        icon = "fa-solid fa-exclamation-triangle",
        time = 240,
        blip = {sprite = 56, color = 47, scale = 0.8},
        dispatchPriority = 'high',
        peds = {
            amount = 4,
            models = {"s_m_y_swat_01", "s_m_y_sheriff_01", "s_m_y_cop_01"},
            weapons = {"WEAPON_CARBINERIFLE", "WEAPON_PUMPSHOTGUN", "WEAPON_PISTOL"},
            vehicles = {"police3", "sheriff", "fbi"},
            armor = 50,
            accuracy = 45,
            arrestDistance = 1.5,
            shootUnarmed = false,
            spawnDistance = 400.0,
            chaseSpeed = 45.0,
            combatRange = 60.0,
            fleeThreshold = 15,
            useCovers = true,
            tackleProbability = 0.35
        }
    },
    [4] = {
        label = "Extreme Warrant",
        icon = "fa-solid fa-skull-crossbones",
        time = 360,
        blip = {sprite = 56, color = 1, scale = 0.9},
        dispatchPriority = 'critical',
        peds = {
            amount = 5,
            models = {"s_m_y_swat_01", "s_m_m_armoured_02", "cs_fbisuit_01"},
            weapons = {"WEAPON_CARBINERIFLE", "WEAPON_PUMPSHOTGUN", "WEAPON_SMG"},
            vehicles = {"riot", "fbi2", "police3"},
            armor = 75,
            accuracy = 55,
            arrestDistance = 1.0,
            shootUnarmed = false,
            spawnDistance = 450.0,
            chaseSpeed = 50.0,
            combatRange = 75.0,
            fleeThreshold = 10,
            useCovers = true,
            tackleProbability = 0.45,
            useHelicopters = true
        }
    },
    [5] = {
        label = "Maximum Warrant",
        icon = "fa-solid fa-radiation",
        time = 600,
        blip = {sprite = 56, color = 1, scale = 1.0},
        dispatchPriority = 'max',
        peds = {
            amount = 6,
            models = {"s_m_y_swat_01", "s_m_m_armoured_02", "s_m_m_armoured_01"},
            weapons = {"WEAPON_CARBINERIFLE", "WEAPON_PUMPSHOTGUN", "WEAPON_SMG", "WEAPON_COMBATMG"},
            vehicles = {"riot", "fbi2", "police4"},
            armor = 100,
            accuracy = 60,   -- [Midnight6調整] 70 → 60
            arrestDistance = 1.0,
            shootUnarmed = true,
            spawnDistance = 500.0,
            chaseSpeed = 55.0,
            combatRange = 100.0,
            fleeThreshold = 5,
            useCovers = true,
            tackleProbability = 0.55,
            useHelicopters = true,
            useRoadblocks = true
        }
    }
}

-- ============================================================================
-- PRISON SYSTEM
-- ============================================================================

Config.Prison = {
    -- [Midnight6移植] 収監は qb-prison に一本化。
    --   saveInventory: qb-prison の jailitems 側が所持品を扱うので false 固定
    --   clearWeapons : 同上
    enabled = true,
    jailTimeMultiplier = 1.0,
    saveInventory = false,
    clearWeapons = false,
    
    entrance = vector4(433.07, -982.04, 30.71, 94.02),
    exit = vector4(442.15, -981.38, 30.69, 47.58),
    
    cells = {
        vector4(460.06, -994.26, 24.91, 268.89),
        vector4(459.60, -997.64, 24.91, 264.71),
        vector4(459.68, -1001.43, 24.91, 265.66)
    },
    
    activities = {
        enabled = false,
        mining = {reward = 50, time = 30},
        cleaning = {reward = 30, time = 20}
    }
}

-- ============================================================================
-- ANIMATIONS - ULTRA REALISTIC
-- ============================================================================

Config.Animations = {
    handsUp = {
        dict = "missminuteman_1ig_2",
        anim = "handsup_base",
        flag = 49
    },
    surrender = {
        dict = "random@arrests@busted",
        anim = "idle_a",
        flag = 49
    },
    arrest = {
        dict = "mp_arrest_paired",
        anim = "crook_p2_back_right",
        flag = 1
    },
    cuffed = {
        dict = "mp_arresting",
        anim = "idle",
        flag = 49
    },
    tackle = {
        dict = "missmic2ig_11",
        anim = "mic_2_ig_11_intro_goon",
        flag = 0
    }
}

-- ============================================================================
-- SURRENDER SYSTEM
-- ============================================================================

Config.SurrenderKey = 'X'
Config.SurrenderDistance = 10.0
Config.SurrenderTime = 3000

-- ============================================================================
-- CRIME TYPES - COMPREHENSIVE
-- ============================================================================

Config.CrimeTypes = {
    MURDER = {
        level = 3,
        description = "Homicide",
        cooldown = 10000,
        witnessChance = 0.95,
        policeAlert = true,
        severity = 'critical'
    },
    MURDER_COP = {
        -- [Midnight6調整] 5 → 3。RDEは「同じレベルの犯罪を重ねると+1」する仕組みなので、
        -- 1人目=Lv3、2人目=Lv4、3人目=Lv5 と段階的に上がる。
        level = 3,
        description = "Officer Down",
        cooldown = 5000,
        witnessChance = 1.0,
        policeAlert = true,
        severity = 'critical'
    },
    ASSAULT = {
        level = 1,
        description = "Assault",
        cooldown = 8000,
        witnessChance = 0.7,
        policeAlert = false,
        severity = 'high'
    },
    ASSAULT_COP = {
        -- [Midnight6調整] 3 → 2(殴っただけで重装備が出ないように)
        level = 2,
        description = "Officer Assault",
        cooldown = 5000,
        witnessChance = 1.0,
        policeAlert = true,
        severity = 'critical'
    },
    SHOOTING = {
        level = 2,
        description = "Shots Fired",
        cooldown = 10000,
        witnessChance = 0.9,
        policeAlert = true,
        severity = 'critical'
    },
    BRANDISHING = {
        level = 1,
        description = "Brandishing Weapon",
        cooldown = 15000,
        witnessChance = 0.6,
        policeAlert = false,
        severity = 'medium'
    },
    VEHICLE_THEFT = {
        level = 1,
        description = "Grand Theft Auto",
        cooldown = 15000,
        witnessChance = 0.65,
        policeAlert = false,
        severity = 'high'
    },
    RECKLESS_DRIVING = {
        level = 1,
        description = "Reckless Driving",
        cooldown = 30000,
        witnessChance = 0.4,
        policeAlert = false,
        severity = 'low'
    },
    HIT_AND_RUN = {
        level = 1,
        description = "Hit and Run",
        cooldown = 15000,
        witnessChance = 0.8,
        policeAlert = false,
        severity = 'high'
    },
    SPEEDING = {
        level = 1,
        description = "Speeding",
        cooldown = 60000,
        witnessChance = 0.3,
        policeAlert = false,
        severity = 'low',
        speedThreshold = 120
    },
    ROBBERY = {
        level = 3,
        description = "Armed Robbery",
        cooldown = 10000,
        witnessChance = 0.9,
        policeAlert = true,
        severity = 'critical'
    },
    BURGLARY = {
        level = 3,
        description = "Burglary",
        cooldown = 10000,
        witnessChance = 0.5,
        policeAlert = false,
        severity = 'high'
    },
    TRESPASSING = {
        level = 1,
        description = "Trespassing",
        cooldown = 45000,
        witnessChance = 0.4,
        policeAlert = false,
        severity = 'low'
    },
    DRUG_POSSESSION = {
        level = 1,
        description = "Drug Possession",
        cooldown = 60000,
        witnessChance = 0.2,
        policeAlert = false,
        severity = 'low'
    },
    DRUG_DEALING = {
        level = 2,
        description = "Drug Trafficking",
        cooldown = 30000,
        witnessChance = 0.5,
        policeAlert = false,
        severity = 'medium'
    },
    VANDALISM = {
        level = 1,
        description = "Vandalism",
        cooldown = 30000,
        witnessChance = 0.5,
        policeAlert = false,
        severity = 'low'
    }
}

-- ============================================================================
-- WITNESS SYSTEM - ADVANCED
-- ============================================================================

Config.WitnessSystem = {
    enabled      = true,
    baseDistance = 80.0,   -- [Midnight6移植] 45 → 80(人通りが少ないため捜索範囲を広げる)
    checkInterval = 1000,
    reportDelay  = 5000,
    cooldown     = 300000,

    areaMultipliers = {
        CITY_CENTER = 1.0,
        URBAN       = 1.0,
        SUBURBAN    = 0.85,
        RURAL       = 0.65,
        WILDERNESS  = 0.40,
    },

    -- ────────────────────────────────────────────────────────────────────────
    -- 🐉 RDE | ULTRA REALISTIC WITNESS v2.0
    -- ────────────────────────────────────────────────────────────────────────

    requireLineOfSight = true,

    -- FOV 240° = NPC ist nur direkt hinter sich blind (120° Blindspot).
    -- War 180° (zu strikt: alle flüchtenden NPCs mit Rücken zum Crime = rejected).
    fieldOfView = 260.0,   -- [Midnight6移植] 240 → 260

    -- Proximity-Grace: 8m — innerhalb dieser Distanz FOV+LOS ignoriert.
    -- War 5m (zu klein: kaum jemand nah genug).
    proximityGraceDistance = 8.0,

    -- Nur noch 1 Re-Scan nach 4000ms statt 2 @ 2500ms.
    -- Nicht jedes Crime wird bemerkt — das ist realistisch.
    delayedRescans        = 2,   -- [Midnight6移植] 1 → 2(最初に誰もいなくても数秒後に再確認)
    delayedRescanInterval = 3000,-- [Midnight6移植] 4000 → 3000

    -- ── NEU: Panik-Phase ─────────────────────────────────────────────────────
    -- Zeuge zögert erst, bevor er das Handy rausholt.
    -- Gibt dem Spieler 1.5-3.5s extra Eingreif-Fenster.
    panicDelay = {
        min = 1500,
        max = 3500,
    },

    -- ── NEU: Einschüchterung ─────────────────────────────────────────────────
    -- Spieler nähert sich Zeugen auf < X Meter → Zeuge flieht, ruft NICHT 911.
    intimidationDistance = 8.0,

    -- ── NEU: Tageszeit-Modifikator ────────────────────────────────────────────
    -- Nachts sind weniger Menschen draußen → weniger Zeugen.
    nightTimeModifier = 0.80,  -- [Midnight6移植] 0.60 → 0.80(夜でも通報が成立しやすく)
    nightHoursStart   = 22,
    nightHoursEnd     = 6,

    -- ── NEU: Combat-Suppression ───────────────────────────────────────────────
    -- Aktives Feuergefecht → Zeugen ducken sich weg statt zu rufen.
    combatSuppression           = true,
    combatSuppressionWindow     = 5000,
    combatSuppressionMultiplier = 0.20,

    playersAsAutoWitnesses = false,

    visiblePhoneCall = true,
    phonePropModel   = 'prop_npc_phone_02',
    callerBlip = {
        enabled    = true,
        sprite     = 280,
        color      = 1,
        scale      = 0.8,
        shortRange = false,
        pulseAlpha = true,
    },

    -- Kürzere Reaktionszeit: 800-2000ms statt 1500-3500ms.
    -- Längere Call-Dauer: 5000-9000ms statt 4000-7000ms (mehr Eingreif-Fenster).
    reactionMin     = 800,
    reactionMax     = 2000,
    callDurationMin = 5000,
    callDurationMax = 9000,
}

-- ============================================================================
-- VEHICLE CO-OCCUPANCY (1.0.2-alpha)
-- ============================================================================
--
-- Wenn der Fahrer ein Verbrechen begeht und du als Beifahrer dabei bist,
-- erbst du das Wanted Level — wie in GTA Online.
--
Config.VehicleCoOccupancy = {
    enabled = true,
    -- Soll der Beifahrer-Wanted-Level um 1 unter dem Fahrer liegen? (false = gleich)
    passengerLowerByOne = false,
    -- Werden Polizei-Jobs in der Crew ausgenommen? (Cop kann nicht selber wanted werden)
    exemptPolice = true,
    -- Werden Admins (laut AdminSettings.exemptFromWanted) ausgenommen?
    exemptAdmins = true,
}

-- ============================================================================
-- CRIME DETECTION REALISM (1.0.2-alpha)
-- ============================================================================
--
-- Schraubt die "Stern für jeden Pups"-Trigger ab.
--
Config.CrimeRealism = {
    -- SHOOTING wird NUR getriggert wenn ein Entity getroffen wurde
    -- ODER der Spieler in eine Zielperson hineinzielt (free-aim auf entity).
    -- Bloßes Abfeuern in die Luft ohne Ziel = kein Crime mehr.
    shootingRequiresTarget = true,

    -- SPEEDING wird NUR getriggert wenn ein Cop tatsächlich Sichtlinie hat.
    -- Verhindert "ich raste durch die Wüste, plötzlich gesucht".
    speedingRequiresCopLOS = true,
    -- Toleranzaufschlag pro Area-Typ (km/h über Limit bis Crime greift).
    speedingTolerance = {
        CITY_CENTER = 25,
        URBAN       = 30,
        SUBURBAN    = 35,
        RURAL       = 50,
        WILDERNESS  = 70,
    },

    -- RECKLESS_DRIVING braucht Cop-Sichtlinie ODER NPC in unmittelbarer Nähe.
    recklessRequiresWitness = true,

    -- BRANDISHING — kleine Chance pro Sekunde wenn Waffe gezogen.
    -- Wenn true: nur triggern wenn NPC oder Cop tatsächlich Sichtlinie hat.
    brandishingRequiresLOS = true,
}

-- ============================================================================
-- POLICE UNIT BLIPS (1.0.2-alpha)
-- ============================================================================
--
-- Unterschiedliche Sprites für Cop-im-Auto vs. Cop-zu-Fuß.
-- Wechselt live während des Spiels.
--
Config.PoliceUnitBlips = {
    vehicle = {
        sprite = 56,   -- "Cop" Sprite — passt für Streifenwagen
        color  = 1,    -- Rot
        scale  = 0.75,
        pulse  = true,
    },
    foot = {
        sprite = 1,    -- Standard-Punkt — kleiner, klar als Fußstreife
        color  = 1,    -- Rot
        scale  = 0.55,
        pulse  = false,
    },
    helicopter = {
        sprite = 422,  -- Helicopter Sprite
        color  = 1,
        scale  = 0.9,
        pulse  = true,
    },
}

-- ============================================================================
-- COP DEATH HANDLING (1.0.2-alpha)
-- ============================================================================
--
-- Verhindert das hässliche "Cop erschossen → Auto poof".
-- Fahrzeug bleibt stehen, wird natürlich entfernt sobald weit weg oder Zeit X.
--
Config.CopDeathHandling = {
    -- Cop-Auto bleibt nach Tod erhalten (statt Sofort-Despawn).
    keepVehicleAfterDeath = true,
    -- Wie lange darf das verlassene Auto in der Welt bleiben? (ms)
    deadCopVehicleLifetime = 120000,  -- 2 Minuten
    -- Distanz ab der das Auto frühzeitig despawnt wenn der Spieler weit weg ist.
    deadCopCullDistance = 250.0,
    -- Cop-Leiche bleibt ebenfalls erhalten (statt Sofort-DeleteEntity).
    keepBodyAfterDeath = true,
    bodyLifetime = 60000,  -- 1 Minute
}

-- ============================================================================
-- POLICE DISENGAGE (1.0.2-alpha)
-- ============================================================================
--
-- Wenn Wanted Level auf 0 fällt: Cops verfolgen NICHT mehr, fahren weg.
-- Diese Sektion steuert wie sauber das aussieht.
--
Config.PoliceDisengage = {
    resetCombatAttributes = true,
    clearHostility        = true,
    silentDeparture       = true,
    -- War 25000 — Cops fahren jetzt in max 15s weg
    maxDepartureWait  = 15000,
    -- War 200.0 — etwas weiter damit sie wirklich weg sind
    departureDistance = 250.0,
    departureSpeed    = 28.0,
}

-- ============================================================================
-- COP TACKLE SYSTEM — Physics-based (v2.0)
-- Portiert vom Player-Reference-Tackle: ForwardVector + RagdollWithFall + Force
-- ============================================================================

Config.CopTackle = {
    enabled = true,
    -- Sprint-Anlauf bevor Impakt (ms)
    sprintTime         = 300,
    -- Ragdoll-Dauer Spieler (random zwischen min/max)
    playerRagdollMin   = 3500,
    playerRagdollMax   = 6000,
    -- Ragdoll-Dauer Cop (trainiert → erholt sich schnell)
    copRagdollDuration = 1200,
    -- Impaktkraft auf Spieler-Ped
    tackleForce        = 8.0,
    -- Cooldown zwischen Tackles (ms)
    cooldown           = 12000,
    -- Max. Distanz für Tackle-Trigger (m)
    triggerDistance    = 4.5,
}

-- ============================================================================
-- AREA DEFINITIONS - COMPREHENSIVE
-- ============================================================================

Config.Areas = {
    {
        name = 'DOWNTOWN_LS',
        coords = vector3(153.9, -1036.4, 29.3),
        radius = 1000.0,
        type = 'CITY_CENTER',
        description = 'Downtown Los Santos'
    },
    {
        name = 'PILLBOX_HILL',
        coords = vector3(56.5, -876.5, 30.7),
        radius = 500.0,
        type = 'CITY_CENTER',
        description = 'Pillbox Hill'
    },
    {
        name = 'VESPUCCI',
        coords = vector3(-1111.9, -1497.8, 4.9),
        radius = 700.0,
        type = 'URBAN',
        description = 'Vespucci Beach'
    },
    {
        name = 'VINEWOOD',
        coords = vector3(131.0, 564.0, 183.9),
        radius = 800.0,
        type = 'URBAN',
        description = 'Vinewood Hills'
    },
    {
        name = 'ROCKFORD_HILLS',
        coords = vector3(-1034.0, -2735.0, 20.2),
        radius = 600.0,
        type = 'URBAN',
        description = 'Rockford Hills'
    },
    {
        name = 'DEL_PERRO',
        coords = vector3(-1470.0, -503.0, 32.8),
        radius = 500.0,
        type = 'URBAN',
        description = 'Del Perro'
    },
    {
        name = 'SANDY_SHORES',
        coords = vector3(1959.9, 3741.5, 32.3),
        radius = 800.0,
        type = 'SUBURBAN',
        description = 'Sandy Shores'
    },
    {
        name = 'PALETO_BAY',
        coords = vector3(-279.0, 6230.0, 31.7),
        radius = 700.0,
        type = 'SUBURBAN',
        description = 'Paleto Bay'
    },
    {
        name = 'HARMONY',
        coords = vector3(1185.0, 2637.0, 38.4),
        radius = 500.0,
        type = 'SUBURBAN',
        description = 'Harmony'
    },
    {
        name = 'GRAPESEED',
        coords = vector3(1686.2, 4815.3, 42.0),
        radius = 800.0,
        type = 'RURAL',
        description = 'Grapeseed'
    },
    {
        name = 'GREAT_OCEAN_HIGHWAY',
        coords = vector3(-2500.0, 2500.0, 20.0),
        radius = 1000.0,
        type = 'RURAL',
        description = 'Great Ocean Highway'
    },
    {
        name = 'MOUNT_CHILIAD',
        coords = vector3(493.9, 5588.7, 794.0),
        radius = 1500.0,
        type = 'WILDERNESS',
        description = 'Mount Chiliad'
    },
    {
        name = 'RATON_CANYON',
        coords = vector3(-1652.0, 4445.0, 15.0),
        radius = 1200.0,
        type = 'WILDERNESS',
        description = 'Raton Canyon'
    },
    {
        name = 'ALAMO_SEA',
        coords = vector3(1370.0, 3800.0, 34.0),
        radius = 1500.0,
        type = 'WILDERNESS',
        description = 'Alamo Sea'
    }
}

-- ============================================================================
-- POLICE BLIPS
-- ============================================================================

Config.PoliceBlips = {
    sprite = 56,
    color = 1,
    scale = 0.4,
    alpha = 255,
    displayTime = 120000,
    flash = true
}

-- ============================================================================
-- OPTIMIZATION SETTINGS
-- ============================================================================

Config.Optimization = {
    maxPoliceUnits = 8,
    spawnCooldown = 5000,
    updateInterval = 500,
    cleanupInterval = 10000,
    maxRenderDistance = 500.0,
    cullDistance = 600.0,
    entityPoolSize = 20,
    useEntityCulling = true
}

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

Config.Notifications = {
    wantedSet = "Wanted level: %d stars",
    wantedRemoved = "You are no longer wanted",
    wantedIncrease = "Wanted level increased",
    wantedDecrease = "Wanted level decreased",
    surrendering = "Surrendering to police...",
    arrested = "You have been arrested",
    jailed = "Jailed for %d seconds",
    jailReleased = "You have been released",
    policeAlert = "Code %s: %s at %s",
    seconds = "seconds",
    crimeReported = "%s detected!",
    crimeWitnessed = "%d witness(es) reported crime",
    policeNotified = "Police have been notified"
}

-- ============================================================================
-- DEBUG COMMANDS
-- ============================================================================

Config.DebugCommands = {
    enabled = Config.Debug,
    commands = {
        'debugpolice',
        'clearcops',
        'testwanted',
        'spawncop',
        'testcrime',
        'crimestatus'
    }
}

-- ============================================================================
-- COMPATIBILITY SETTINGS
-- ============================================================================

Config.Compatibility = {
    useLegacyEvents = false,
    
    integrations = {
        esx_policejob = false,
        qb_policejob = false,
        ps_dispatch = false
    }
}

-- ============================================================================
-- LOCALE SETTINGS
-- ============================================================================

-- Default language for the system.
-- Supported: 'en' (English) | 'de' (Deutsch)
-- Override on your server with:  set ox:locale "de"
Config.Locale = GetConvar('ox:locale', 'en')

-- ============================================================================
--
--   🐉 RED DRAGON ELITE | rde_aipd
--   CONFIG EXTENSION — rde_nostr_log Integration
--   Author: RDE | SerpentsByte | https://rd-elite.com/
--   Version: 1.1.0
--
--   INSTRUCTIONS:
--     Paste this block INTO your existing config.lua (anywhere after the
--     existing Config table declaration).
--     Requires: rde_nostr_log resource to be started BEFORE rde_aipd.
--
--   SETUP:
--     1. ensure rde_nostr_log   ← must come BEFORE rde_aipd in server.cfg
--     2. ensure rde_aipd
--
-- ============================================================================
--
--  Decentralized, uncensorable, permanent logging.
--  Replace Discord webhooks forever. Powered by rde_nostr_log.
--
--  Install: https://github.com/RedDragonElite/rde_nostr_log
--  Set enabled = false to completely disable all Nostr logging.
--
-- ============================================================================
-- ─────────────────────────────────────────────────────────────────────────────
--  NOSTR LOGGING INTEGRATION
--  Powers every police event into the decentralized Nostr network via
--  rde_nostr_log's export API. Zero overhead — all calls are fire-and-forget.
-- ─────────────────────────────────────────────────────────────────────────────

Config.Nostr = {

    -- Master switch: set false to completely disable all Nostr logging
    -- [Midnight6移植] 外部ログ(rde_nostr_log)は使わないので false
    enabled  = false,

    -- The resource name of your rde_nostr_log installation.
    -- Change this only if you renamed the resource folder.
    resource = 'rde_nostr_log',

    -- ── PER-CATEGORY SWITCHES ───────────────────────────────────────────────
    -- Set any category to false to silence that event type entirely.
    -- Useful for high-traffic servers that want to cut Nostr noise.

    logLevel = {
        player_connect    = false,   -- 🟢 Player joined the server
        player_disconnect = false,   -- 🔴 Player left the server
        player_wanted     = true,   -- ⭐ Wanted level set / cleared
        crime_detected    = true,   -- 🚨 Crime event detected
        player_arrested   = true,   -- 🚔 Player arrested (before jail)
        player_jailed     = true,   -- ⛓  Player teleported to jail
        player_released   = true,   -- ✅ Player released from jail
        cop_killed        = true,   -- 💀 Player killed a police officer
        admin_action      = true,   -- 🛡  Admin used a police command
    },

}

-- ─────────────────────────────────────────────────────────────────────────────
--  QUICK REFERENCE — What triggers each log category
-- ─────────────────────────────────────────────────────────────────────────────
--
--  player_connect    → ox:playerLoaded  (fires after charid loads)
--  player_disconnect → playerDropped    (fires before state cleanup)
--  player_wanted     → SetWantedLevel() (both increase AND clear)
--  crime_detected    → police:reportCrime event  (every crime type)
--  player_arrested   → police:arrestPlayer callback (paired with anim)
--  player_jailed     → JailPlayer()     (after inventory is saved)
--  player_released   → ReleasePlayer()  (after inventory is restored)
--  cop_killed        → MURDER_COP crime type specifically
--  admin_action      → /setwanted /clearwanted /jail /unjail /panic
--
-- ─────────────────────────────────────────────────────────────────────────────
-- ============================================================================
-- ICONS & COLORS  (RDE Standard)
-- ============================================================================

Config.Icons = {
    success  = 'check-circle',
    error    = 'x-circle',
    warning  = 'alert-triangle',
    info     = 'info',
    police   = 'shield',
    skull    = 'skull',
    star     = 'star',
    jail     = 'lock',
    escape   = 'wind',
    weapon   = 'crosshair',
}

Config.Colors = {
    success  = '#10b981',
    error    = '#ef4444',
    warning  = '#f59e0b',
    info     = '#3b82f6',
    police   = '#60a5fa',
    skull    = '#f43f5e',
    jail     = '#a78bfa',
}