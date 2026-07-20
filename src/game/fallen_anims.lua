-- Auto-generated from dump/catalog/animations.tsv - all unique animation asset IDs.
-- Playback must match Fallen: Humanoid:LoadAnimation(anim):Play() with default speed/weight.

local M = {}

M.LABELS = {
    "None",
    "Hit",
    "Sleep",
    "Body Stone Pickaxe Equip",
    "Body Stone Pickaxe Idle",
    "Body Stone Pickaxe Throw",
    "Body Stone Pickaxe Swing1",
    "Body Stone Pickaxe Swing2",
    "Cam Stone Pickaxe Equip",
    "VM Stone Pickaxe Hit",
    "VM Stone Pickaxe Idle",
    "VM Stone Pickaxe Inspect",
    "VM Stone Pickaxe ThrowWindup",
    "VM Stone Pickaxe Miss",
    "VM Stone Pickaxe Equip",
    "VM Stone Pickaxe Throw",
    "VM Stone Pickaxe Windup",
    "VM Stone Pickaxe ThrowHold",
    "VM Wooden Spear Hit",
    "VM Wooden Spear Idle",
    "VM Wooden Spear Inspect",
    "VM Wooden Spear ThrowWindup",
    "VM Wooden Spear Equip",
    "VM Wooden Spear Throw",
    "VM Wooden Spear Windup",
    "VM Wooden Spear ThrowHold",
    "Body Wooden Spear Equip",
    "Body Wooden Spear Idle",
    "Body Wooden Spear Throw",
    "Body Wooden Spear Aim",
    "Body Wooden Spear Swing1",
    "VM ez shovel Hit",
    "VM ez shovel Idle",
    "VM ez shovel Inspect",
    "VM ez shovel Miss",
    "VM ez shovel Equip",
    "VM ez shovel ThrowWindup",
    "VM ez shovel ThrowHold",
    "VM ez shovel Windup",
    "Body Pumpkin Launcher Equip",
    "Body Pumpkin Launcher Idle",
    "VM Pumpkin Launcher Equip",
    "VM Pumpkin Launcher Idle",
    "VM Pumpkin Launcher Inspect",
    "VM Pumpkin Launcher Reload1",
    "VM Pumpkin Launcher Reload2",
    "VM Pumpkin Launcher Reload3",
    "VM Pumpkin Launcher Shoot",
    "Cam Pumpkin Launcher Reload",
    "VM Boulder Hit",
    "VM Boulder Idle",
    "VM Boulder Inspect",
    "VM Boulder ThrowWindup",
    "VM Boulder Miss",
    "VM Boulder Equip",
    "VM Boulder Throw",
    "VM Boulder Windup",
    "Body Boulder Equip",
    "Body Boulder Idle",
    "Body Boulder Swing1",
    "VM Small Medkit Equip",
    "VM Small Medkit Idle",
    "VM Small Medkit Use",
    "Body Small Medkit Use",
    "Body Small Medkit Idle",
    "Body Small Medkit Equip",
    "Body Military M4A1 Aim",
    "VM Military M4A1 Equip",
    "VM Military M4A1 Inspect",
    "VM Military M4A1 Reload",
    "VM Military M4A1 Shoot",
    "VM Military M4A1 SightFix",
    "VM Salvaged AK74u Idle",
    "VM Salvaged AK74u Equip",
    "VM Salvaged AK74u Reload",
    "VM Salvaged AK74u Inspect",
    "VM Salvaged AK74u Shoot",
    "VM Salvaged AK74u Equip (8322)",
    "VM Salvaged AK74u Idle (2757)",
    "VM Salvaged AK74u Inspect (6548)",
    "VM Salvaged AK74u Reload (3807)",
    "VM Salvaged AK74u Shoot (8023)",
    "VM Nail Gun Equip",
    "VM Nail Gun Idle",
    "VM Nail Gun Inspect",
    "VM Nail Gun Reload",
    "VM Timed Charge Idle",
    "VM Timed Charge Equip",
    "VM Timed Charge Throw",
    "VM Steel Pickaxe Hit",
    "VM Steel Pickaxe Idle",
    "VM Steel Pickaxe Inspect",
    "VM Steel Pickaxe ThrowWindup",
    "VM Steel Pickaxe Miss",
    "VM Steel Pickaxe Equip",
    "VM Steel Pickaxe Throw",
    "VM Steel Pickaxe Windup",
    "VM Military Grenade Idle",
    "VM Military Grenade Equip",
    "VM Military Grenade UnderHandThrow",
    "VM Military Grenade Light",
    "VM Military Grenade OverHandThrow",
    "VM Military Grenade ThrowStart",
    "VM Salvaged RPG Idle",
    "VM Salvaged RPG Equip",
    "VM Salvaged RPG Reload",
    "VM Salvaged RPG Inspect",
    "VM Salvaged RPG Shoot",
    "VM Salvaged Python Equip",
    "VM Salvaged Python Idle",
    "VM Salvaged Python Inspect",
    "VM Salvaged Python Reload",
    "VM Salvaged Python Shoot",
    "VM Salvaged M14 Equip",
    "VM Salvaged M14 Reload",
    "VM Salvaged M14 Shoot",
    "VM Salvaged SMG Equip",
    "VM Salvaged SMG Reload",
    "VM Salvaged P250 Idle",
    "VM Salvaged P250 Equip",
    "VM Salvaged P250 Reload",
    "VM Salvaged P250 Inspect",
    "VM Salvaged P250 Shoot",
    "VM Salvaged Sniper Equip",
    "VM Salvaged Sniper Reload",
    "VM Salvaged Sniper Shoot",
    "VM Salvaged Sniper Inspect",
    "VM Salvaged Sniper Bolt",
    "VM Wooden Bow Idle",
    "VM Wooden Bow AimStart",
    "VM Wooden Bow AimHold",
    "VM Wooden Bow Equip",
    "VM Wooden Bow Inspect",
    "VM Wooden Bow JumpShotAimStart",
    "VM Wooden Bow JumpShotAim",
    "VM Wooden Bow AimStop",
    "Body Wooden Bow Idle",
    "Body Wooden Bow AimStart",
    "Body Wooden Bow AimHold",
    "VM Pink Keycard Use",
    "VM Pink Keycard Idle",
    "VM Pink Keycard Equip",
    "VM Bandage Equip",
    "VM Bandage Idle",
    "VM Bandage Use",
    "Body Bandage Use",
    "VM Health Pen Equip",
    "VM Health Pen Idle",
    "VM Health Pen Use",
    "VM Salvaged Pipe Rifle Idle",
    "VM Salvaged Pipe Rifle Equip",
    "VM Salvaged Pipe Rifle Inspect",
    "VM Salvaged Pipe Rifle Shoot",
    "VM Salvaged Pipe Rifle BoltNOTUSED",
    "VM Salvaged Pipe Rifle Reload1",
    "VM Salvaged Pipe Rifle Reload2",
    "VM Salvaged Pipe Rifle Reload3",
    "VM Salvaged AK47 Equip",
    "VM Salvaged AK47 Reload",
    "VM Salvaged AK47 Shoot",
    "VM Salvaged AK47 Idle",
    "VM Salvaged AK47 Inspect",
    "VM Salvaged AK47 Equip (8743)",
    "VM Salvaged AK47 Reload (6911)",
    "VM Salvaged AK47 Idle (5515)",
    "VM Salvaged AK47 Inspect (5998)",
    "VM Salvaged AK47 ShootRENAMEWHENFIXED",
    "VM Steel Shovel Dig",
    "VM Crossbow Idle",
    "VM Crossbow Equip",
    "VM Crossbow Reload",
    "VM Crossbow Inspect",
    "VM Crossbow Shoot",
    "VM Crossbow Unloaded",
    "VM Crossbow Loaded",
    "VM Lighter Idle",
    "VM Lighter Inspect",
    "VM Lighter Equip",
    "VM Lighter Use",
    "VM Lighter Idle (7599)",
    "VM Lighter Inspect (6415)",
    "VM Lighter Equip (7300)",
    "VM Lighter Use (3870)",
    "VM Salvaged Pump Action Idle",
    "VM Salvaged Pump Action Equip",
    "VM Salvaged Pump Action Inspect",
    "VM Salvaged Pump Action Bolt",
    "VM Salvaged Pump Action Reload1",
    "VM Salvaged Pump Action Reload2",
    "VM Salvaged Pump Action Reload3",
    "VM Military AA12 Equip",
    "VM Military AA12 Inspect",
    "VM Military AA12 Reload1",
    "VM Military AA12 Reload2",
    "VM Military AA12 Reload3",
    "VM Military AA12 Shoot",
    "VM Military AA12 Idle",
    "VM Salvaged Skorpion Equip",
    "VM Salvaged Skorpion Reload",
    "VM Salvaged Skorpion Shoot",
    "VM Salvaged Skorpion Inspect",
    "VM Military Barrett Equip",
    "VM Military Barrett Reload",
    "VM Military Barrett Shoot",
    "VM Military Barrett Inspect",
    "VM Military Barrett Bolt",
    "VM Military Barrett SightFix",
    "VM Military PKM Equip",
    "VM Military PKM Reload",
    "VM Military PKM Idle",
    "VM Military PKM Inspect",
    "VM Machete Hit",
    "VM Machete Idle",
    "VM Machete Inspect",
    "VM Machete Miss",
    "VM Machete Equip",
    "VM Machete ThrowWindup",
    "VM Machete ThrowHold",
    "VM Machete Windup",
    "VM Mining Drill Idle",
    "VM Mining Drill WindupLoop",
    "VM Mining Drill Equip",
    "VM Chainsaw Idle",
    "VM Chainsaw WindupLoop",
    "VM Chainsaw Equip",
    "VM Chainsaw Reload",
    "VM Military MP7 Idle",
    "VM Military MP7 Equip",
    "VM Military MP7 Reload",
    "VM Military MP7 Inspect",
    "VM Military MP7 Shootold",
    "VM Military USP Shoot",
    "VM Salvaged Shotgun Equip",
    "VM Salvaged Shotgun Light",
    "VM Salvaged Shotgun Idle",
    "VM Salvaged Shotgun Inspect",
    "VM Salvaged Shotgun Reload",
    "VM Salvaged Break Action Equip",
    "VM Salvaged Break Action Reload",
    "VM Salvaged Break Action Idle",
    "VM Salvaged Break Action Inspect",
    "Body Blueprint Idle",
    "Body Blueprint Equip",
    "VM Military Grenade Launcher Idle",
    "VM Military Grenade Launcher Equip",
    "VM Military Grenade Launcher Inspect",
    "VM Military Grenade Launcher Shoot",
    "VM Military Grenade Launcher Reload1",
    "VM Military Grenade Launcher Reload2",
    "VM Military Grenade Launcher Reload3",
    "VM Salvaged Grenade Launcher Idle",
    "VM Salvaged Grenade Launcher Equip",
    "VM Salvaged Grenade Launcher Inspect",
    "VM Salvaged Grenade Launcher Shoot",
    "VM Salvaged Grenade Launcher Reload",
    "VM Wire Cutters Equip",
    "VM Wire Cutters Idle",
    "VM Wire Cutters WireCutter",
    "VM Wire Cutters Inspect",
    "VM Salvaged Double Barrel Equip",
    "VM Salvaged Double Barrel Reload",
    "VM Salvaged Double Barrel Idle",
    "VM Salvaged Double Barrel Inspect",
    "VM Military M39 Equip",
    "VM Military M39 Reload",
    "VM Military M39 Shoot",
    "VM Military M39 Idle",
    "VM Military M39 Inspect",
    "Idle",
    "Backward",
    "Forward",
    "Left",
    "Right",
    "Sprint",
    "SprintLeft",
    "SprintRight",
    "CrouchForward",
    "Swim",
    "SwimIdle",
    "Down",
    "DownFall",
    "Sit",
    "SitPilot",
    "Run",
    "Spook",
    "Idle (8126)",
    "Idle (5032)",
    "AttackIdle",
    "Run (7717)",
    "Attack",
    "Animation",
    "SpinAnimation",
    "SpinAnimation (4993)",
    "Idle (6751)",
}

M.IDS = {
    nil, -- None
    "12295196614", -- Hit
    "2889482101", -- Sleep
    "12404717807", -- Body Stone Pickaxe Equip
    "12404519685", -- Body Stone Pickaxe Idle
    "12404755793", -- Body Stone Pickaxe Throw
    "12404582634", -- Body Stone Pickaxe Swing1
    "12404586561", -- Body Stone Pickaxe Swing2
    "13824449779", -- Cam Stone Pickaxe Equip
    "11254599050", -- VM Stone Pickaxe Hit
    "11254603653", -- VM Stone Pickaxe Idle
    "11254610632", -- VM Stone Pickaxe Inspect
    "12087089666", -- VM Stone Pickaxe ThrowWindup
    "12097635857", -- VM Stone Pickaxe Miss
    "11254620945", -- VM Stone Pickaxe Equip
    "12086968738", -- VM Stone Pickaxe Throw
    "11254713577", -- VM Stone Pickaxe Windup
    "12315210121", -- VM Stone Pickaxe ThrowHold
    "12323621850", -- VM Wooden Spear Hit
    "12323431574", -- VM Wooden Spear Idle
    "12323465168", -- VM Wooden Spear Inspect
    "12323588559", -- VM Wooden Spear ThrowWindup
    "12323373070", -- VM Wooden Spear Equip
    "12323523249", -- VM Wooden Spear Throw
    "12323686914", -- VM Wooden Spear Windup
    "12330525319", -- VM Wooden Spear ThrowHold
    "12332656326", -- Body Wooden Spear Equip
    "12332628544", -- Body Wooden Spear Idle
    "12332606670", -- Body Wooden Spear Throw
    "12332631981", -- Body Wooden Spear Aim
    "12332622716", -- Body Wooden Spear Swing1
    "14753903836", -- VM ez shovel Hit
    "14753747589", -- VM ez shovel Idle
    "14753755728", -- VM ez shovel Inspect
    "14753829920", -- VM ez shovel Miss
    "14753765263", -- VM ez shovel Equip
    "14753924056", -- VM ez shovel ThrowWindup
    "14753962771", -- VM ez shovel ThrowHold
    "14753821942", -- VM ez shovel Windup
    "10982184970", -- Body Pumpkin Launcher Equip
    "10982102481", -- Body Pumpkin Launcher Idle
    "107763869878004", -- VM Pumpkin Launcher Equip
    "96964900616385", -- VM Pumpkin Launcher Idle
    "113058224726735", -- VM Pumpkin Launcher Inspect
    "122129787681927", -- VM Pumpkin Launcher Reload1
    "131841243736090", -- VM Pumpkin Launcher Reload2
    "134448134384946", -- VM Pumpkin Launcher Reload3
    "84284689931857", -- VM Pumpkin Launcher Shoot
    "13885646898", -- Cam Pumpkin Launcher Reload
    "12576117123", -- VM Boulder Hit
    "12576197130", -- VM Boulder Idle
    "12576193813", -- VM Boulder Inspect
    "12576260677", -- VM Boulder ThrowWindup
    "12576268434", -- VM Boulder Miss
    "12576113229", -- VM Boulder Equip
    "12576313309", -- VM Boulder Throw
    "12576221319", -- VM Boulder Windup
    "2640084383", -- Body Boulder Equip
    "2640084707", -- Body Boulder Idle
    "2640085047", -- Body Boulder Swing1
    "15126852724", -- VM Small Medkit Equip
    "15126828005", -- VM Small Medkit Idle
    "15126848291", -- VM Small Medkit Use
    "2529243689", -- Body Small Medkit Use
    "2529244101", -- Body Small Medkit Idle
    "2529246854", -- Body Small Medkit Equip
    "10982316984", -- Body Military M4A1 Aim
    "15435529127", -- VM Military M4A1 Equip
    "15435570035", -- VM Military M4A1 Inspect
    "15435623751", -- VM Military M4A1 Reload
    "15435532750", -- VM Military M4A1 Shoot
    "15442290533", -- VM Military M4A1 SightFix
    "10905196277", -- VM Salvaged AK74u Idle
    "13642327129", -- VM Salvaged AK74u Equip
    "13642332380", -- VM Salvaged AK74u Reload
    "10905213921", -- VM Salvaged AK74u Inspect
    "13642336532", -- VM Salvaged AK74u Shoot
    "98129074368322", -- VM Salvaged AK74u Equip (8322)
    "93372634082757", -- VM Salvaged AK74u Idle (2757)
    "109508842676548", -- VM Salvaged AK74u Inspect (6548)
    "128093247273807", -- VM Salvaged AK74u Reload (3807)
    "130287124408023", -- VM Salvaged AK74u Shoot (8023)
    "13327911632", -- VM Nail Gun Equip
    "13327914671", -- VM Nail Gun Idle
    "13327938850", -- VM Nail Gun Inspect
    "13327926806", -- VM Nail Gun Reload
    "13328349172", -- VM Timed Charge Idle
    "13329537452", -- VM Timed Charge Equip
    "13328390675", -- VM Timed Charge Throw
    "13327409098", -- VM Steel Pickaxe Hit
    "13327377006", -- VM Steel Pickaxe Idle
    "13327416430", -- VM Steel Pickaxe Inspect
    "13326920636", -- VM Steel Pickaxe ThrowWindup
    "13326904374", -- VM Steel Pickaxe Miss
    "13326900120", -- VM Steel Pickaxe Equip
    "13326927760", -- VM Steel Pickaxe Throw
    "13326914930", -- VM Steel Pickaxe Windup
    "13328557028", -- VM Military Grenade Idle
    "13328550574", -- VM Military Grenade Equip
    "13328572108", -- VM Military Grenade UnderHandThrow
    "13328632174", -- VM Military Grenade Light
    "13328582483", -- VM Military Grenade OverHandThrow
    "13328629789", -- VM Military Grenade ThrowStart
    "13446590342", -- VM Salvaged RPG Idle
    "13446858662", -- VM Salvaged RPG Equip
    "13446581922", -- VM Salvaged RPG Reload
    "13446577751", -- VM Salvaged RPG Inspect
    "13446573652", -- VM Salvaged RPG Shoot
    "11066772771", -- VM Salvaged Python Equip
    "11066778914", -- VM Salvaged Python Idle
    "11066786478", -- VM Salvaged Python Inspect
    "11066790798", -- VM Salvaged Python Reload
    "12581889409", -- VM Salvaged Python Shoot
    "13670792109", -- VM Salvaged M14 Equip
    "13670748435", -- VM Salvaged M14 Reload
    "13670812891", -- VM Salvaged M14 Shoot
    "14205062509", -- VM Salvaged SMG Equip
    "14121442831", -- VM Salvaged SMG Reload
    "12522326352", -- VM Salvaged P250 Idle
    "12522337951", -- VM Salvaged P250 Equip
    "12522315610", -- VM Salvaged P250 Reload
    "12522200642", -- VM Salvaged P250 Inspect
    "12523778090", -- VM Salvaged P250 Shoot
    "102278056019292", -- VM Salvaged Sniper Equip
    "76688960452168", -- VM Salvaged Sniper Reload
    "76442867538012", -- VM Salvaged Sniper Shoot
    "131088076477856", -- VM Salvaged Sniper Inspect
    "134064393891680", -- VM Salvaged Sniper Bolt
    "13676749170", -- VM Wooden Bow Idle
    "13676752865", -- VM Wooden Bow AimStart
    "13676756566", -- VM Wooden Bow AimHold
    "13676758676", -- VM Wooden Bow Equip
    "13676761493", -- VM Wooden Bow Inspect
    "13676765827", -- VM Wooden Bow JumpShotAimStart
    "13680356359", -- VM Wooden Bow JumpShotAim
    "13681000136", -- VM Wooden Bow AimStop
    "13960174047", -- Body Wooden Bow Idle
    "13960202666", -- Body Wooden Bow AimStart
    "13960210609", -- Body Wooden Bow AimHold
    "13956423938", -- VM Pink Keycard Use
    "13956427413", -- VM Pink Keycard Idle
    "13956571659", -- VM Pink Keycard Equip
    "13958285864", -- VM Bandage Equip
    "13958303128", -- VM Bandage Idle
    "13958298879", -- VM Bandage Use
    "14860445359", -- Body Bandage Use
    "13970663013", -- VM Health Pen Equip
    "13970667527", -- VM Health Pen Idle
    "14547962925", -- VM Health Pen Use
    "13651086373", -- VM Salvaged Pipe Rifle Idle
    "13651149446", -- VM Salvaged Pipe Rifle Equip
    "13651157242", -- VM Salvaged Pipe Rifle Inspect
    "13651300466", -- VM Salvaged Pipe Rifle Shoot
    "13651231180", -- VM Salvaged Pipe Rifle BoltNOTUSED
    "13651242520", -- VM Salvaged Pipe Rifle Reload1
    "13651250402", -- VM Salvaged Pipe Rifle Reload2
    "13651260689", -- VM Salvaged Pipe Rifle Reload3
    "13537714744", -- VM Salvaged AK47 Equip
    "13537638231", -- VM Salvaged AK47 Reload
    "13537754482", -- VM Salvaged AK47 Shoot
    "13537644331", -- VM Salvaged AK47 Idle
    "13537721124", -- VM Salvaged AK47 Inspect
    "17685378743", -- VM Salvaged AK47 Equip (8743)
    "17685566911", -- VM Salvaged AK47 Reload (6911)
    "17685385515", -- VM Salvaged AK47 Idle (5515)
    "17685475998", -- VM Salvaged AK47 Inspect (5998)
    "17685395097", -- VM Salvaged AK47 ShootRENAMEWHENFIXED
    "14753791797", -- VM Steel Shovel Dig
    "13661804506", -- VM Crossbow Idle
    "13661753951", -- VM Crossbow Equip
    "13661745837", -- VM Crossbow Reload
    "13661800907", -- VM Crossbow Inspect
    "13662357236", -- VM Crossbow Shoot
    "13662019424", -- VM Crossbow Unloaded
    "13662041428", -- VM Crossbow Loaded
    "15099920803", -- VM Lighter Idle
    "15099969777", -- VM Lighter Inspect
    "15099967111", -- VM Lighter Equip
    "15099971616", -- VM Lighter Use
    "111476823327599", -- VM Lighter Idle (7599)
    "79402821816415", -- VM Lighter Inspect (6415)
    "99169514187300", -- VM Lighter Equip (7300)
    "122545087673870", -- VM Lighter Use (3870)
    "15374900583", -- VM Salvaged Pump Action Idle
    "15375439667", -- VM Salvaged Pump Action Equip
    "15374945610", -- VM Salvaged Pump Action Inspect
    "15375019749", -- VM Salvaged Pump Action Bolt
    "15374989233", -- VM Salvaged Pump Action Reload1
    "15374950237", -- VM Salvaged Pump Action Reload2
    "15374959462", -- VM Salvaged Pump Action Reload3
    "15126455919", -- VM Military AA12 Equip
    "15126678129", -- VM Military AA12 Inspect
    "15126706765", -- VM Military AA12 Reload1
    "15126674376", -- VM Military AA12 Reload2
    "15126715408", -- VM Military AA12 Reload3
    "15373354010", -- VM Military AA12 Shoot
    "15126659544", -- VM Military AA12 Idle
    "15610812844", -- VM Salvaged Skorpion Equip
    "15610728466", -- VM Salvaged Skorpion Reload
    "15610787069", -- VM Salvaged Skorpion Shoot
    "15610777856", -- VM Salvaged Skorpion Inspect
    "15882735108", -- VM Military Barrett Equip
    "15882748975", -- VM Military Barrett Reload
    "15882738576", -- VM Military Barrett Shoot
    "15882744613", -- VM Military Barrett Inspect
    "15882725391", -- VM Military Barrett Bolt
    "15883684762", -- VM Military Barrett SightFix
    "16487127739", -- VM Military PKM Equip
    "16487134130", -- VM Military PKM Reload
    "16487121752", -- VM Military PKM Idle
    "16487140562", -- VM Military PKM Inspect
    "16291366168", -- VM Machete Hit
    "16291340052", -- VM Machete Idle
    "16291343338", -- VM Machete Inspect
    "16291351155", -- VM Machete Miss
    "16291336720", -- VM Machete Equip
    "16291353748", -- VM Machete ThrowWindup
    "16291886891", -- VM Machete ThrowHold
    "16291363603", -- VM Machete Windup
    "17293759024", -- VM Mining Drill Idle
    "17293721866", -- VM Mining Drill WindupLoop
    "17293764948", -- VM Mining Drill Equip
    "17293422918", -- VM Chainsaw Idle
    "17293404371", -- VM Chainsaw WindupLoop
    "17293430835", -- VM Chainsaw Equip
    "17293426037", -- VM Chainsaw Reload
    "17766851333", -- VM Military MP7 Idle
    "17766847963", -- VM Military MP7 Equip
    "17766833600", -- VM Military MP7 Reload
    "17766840940", -- VM Military MP7 Inspect
    "17767250057", -- VM Military MP7 Shootold
    "96523967415718", -- VM Military USP Shoot
    "131870776267221", -- VM Salvaged Shotgun Equip
    "133968261920038", -- VM Salvaged Shotgun Light
    "72995644901984", -- VM Salvaged Shotgun Idle
    "84933068402315", -- VM Salvaged Shotgun Inspect
    "102019461344676", -- VM Salvaged Shotgun Reload
    "13975378175", -- VM Salvaged Break Action Equip
    "13975340954", -- VM Salvaged Break Action Reload
    "13975409679", -- VM Salvaged Break Action Idle
    "13975434038", -- VM Salvaged Break Action Inspect
    "13734772923", -- Body Blueprint Idle
    "13734803430", -- Body Blueprint Equip
    "140326279747478", -- VM Military Grenade Launcher Idle
    "123224971801444", -- VM Military Grenade Launcher Equip
    "114050633809537", -- VM Military Grenade Launcher Inspect
    "74802718135370", -- VM Military Grenade Launcher Shoot
    "91952685534246", -- VM Military Grenade Launcher Reload1
    "94356108553295", -- VM Military Grenade Launcher Reload2
    "133913608950018", -- VM Military Grenade Launcher Reload3
    "112882818317211", -- VM Salvaged Grenade Launcher Idle
    "70585446035249", -- VM Salvaged Grenade Launcher Equip
    "88599504281373", -- VM Salvaged Grenade Launcher Inspect
    "107924799713201", -- VM Salvaged Grenade Launcher Shoot
    "86919401341255", -- VM Salvaged Grenade Launcher Reload
    "117405006736055", -- VM Wire Cutters Equip
    "133616833248387", -- VM Wire Cutters Idle
    "106169010693313", -- VM Wire Cutters WireCutter
    "134536396023659", -- VM Wire Cutters Inspect
    "84783032215478", -- VM Salvaged Double Barrel Equip
    "97601710279998", -- VM Salvaged Double Barrel Reload
    "126786002630099", -- VM Salvaged Double Barrel Idle
    "86800914023444", -- VM Salvaged Double Barrel Inspect
    "76090728842149", -- VM Military M39 Equip
    "117764005979607", -- VM Military M39 Reload
    "102880815400501", -- VM Military M39 Shoot
    "116186830802406", -- VM Military M39 Idle
    "85821031583482", -- VM Military M39 Inspect
    "10976840199", -- Idle
    "10976855782", -- Backward
    "10976858264", -- Forward
    "10976863741", -- Left
    "10976866578", -- Right
    "10976869491", -- Sprint
    "2128761345", -- SprintLeft
    "2128762025", -- SprintRight
    "2904653470", -- CrouchForward
    "913384386", -- Swim
    "913389285", -- SwimIdle
    "13435049596", -- Down
    "13435061543", -- DownFall
    "2506281703", -- Sit
    "134970817907270", -- SitPilot
    "12611991969", -- Run
    "12612385659", -- Spook
    "12611998126", -- Idle (8126)
    "12796825032", -- Idle (5032)
    "12795190660", -- AttackIdle
    "12795187717", -- Run (7717)
    "12795184400", -- Attack
    "89167396213866", -- Animation
    "123000349120728", -- SpinAnimation
    "109026981614993", -- SpinAnimation (4993)
    "17513186751", -- Idle (6751)
}

function M.asset_url(id)
    if not id or id == "" then return nil end
    local s = tostring(id)
    if s:find("rbxassetid", 1, true) or s:find("http", 1, true) then
        return s
    end
    return "rbxassetid://" .. s
end

function M.id_for_index(idx)
    idx = tonumber(idx) or 0
    if idx < 0 or idx >= #M.IDS then return nil end
    return M.IDS[idx + 1]
end

return M
