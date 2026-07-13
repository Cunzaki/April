local M = {}

-- Chunk Studios (1154360) staff ranks above Fan.
-- Roles: OG, Game Tester, Game Moderator, Contribution, Developers,
-- Lead Developer, Co-Founder, Founder. Excludes Guest / Member / Fan.
-- Synced from groups.roblox.com on 2026-07-09.
M.ROLES = {

    -- Founder
    [16681869] = "Founder", -- neddleduck

    -- Co-Founder
    [47983795] = "Co-Founder", -- ChickenBagelz

    -- Lead Developer
    [25548179] = "Lead Developer", -- AsianAbrex
    [363101315] = "Lead Developer", -- Warm_Vibes

    -- Contribution
    [174212818] = "Contribution", -- YTGonzo

    -- Game Moderator
    [584370127] = "Game Moderator", -- 1Newy1
    [4243907215] = "Game Moderator", -- AaronElagant
    [81993536] = "Game Moderator", -- aidenas2011
    [979624578] = "Game Moderator", -- B_BEAMO
    [602009251] = "Game Moderator", -- Bajoogies_XD
    [2525997354] = "Game Moderator", -- BlackWhiteYT11
    [1383415614] = "Game Moderator", -- Bryponfx
    [2276999095] = "Game Moderator", -- CelebredKillerq
    [3122439095] = "Game Moderator", -- chancerocke
    [836836349] = "Game Moderator", -- didusha123
    [1190967808] = "Game Moderator", -- djvdhshscshs
    [2732967856] = "Game Moderator", -- DontTouchZGrass
    [113179883] = "Game Moderator", -- DopeIlI
    [3034930770] = "Game Moderator", -- Fan_hellrider
    [1478885961] = "Game Moderator", -- fordjdj12
    [833946684] = "Game Moderator", -- GamerGubbi
    [4553863490] = "Game Moderator", -- giovannirv2
    [1116486172] = "Game Moderator", -- Hakob_8w8
    [8593140875] = "Game Moderator", -- HurbertTheP3r73rt
    [2364950171] = "Game Moderator", -- ilovetowerbattle_9
    [1374319325] = "Game Moderator", -- jostjohnyca
    [3470393585] = "Game Moderator", -- k6ppo
    [41482597] = "Game Moderator", -- kerub131
    [51281722] = "Game Moderator", -- KittenBagelz
    [1058831985] = "Game Moderator", -- krisidisi23
    [510349404] = "Game Moderator", -- Kristian4209
    [991290934] = "Game Moderator", -- Lexi34567812
    [122915793] = "Game Moderator", -- LionTooth99999
    [202751467] = "Game Moderator", -- lumbers2
    [1937516999] = "Game Moderator", -- matheu09173
    [839333692] = "Game Moderator", -- Matheus06532
    [1004214871] = "Game Moderator", -- owner12310
    [3968854760] = "Game Moderator", -- puferyba
    [353983652] = "Game Moderator", -- Puhgee
    [2924549627] = "Game Moderator", -- rashhhh2
    [7178750309] = "Game Moderator", -- Rikumah
    [399754916] = "Game Moderator", -- sirfluf
    [7278178099] = "Game Moderator", -- thecarrotman513
    [4225513035] = "Game Moderator", -- Waitwhatb40
    [1193091081] = "Game Moderator", -- Weerdeeg
    [1290522339] = "Game Moderator", -- Xonnik921

    -- Game Tester
    [3328476579] = "Game Tester", -- 657rikgf7t6r_deleted
    [4751004788] = "Game Tester", -- Adopt_me21893
    [405807238] = "Game Tester", -- AgentSwitchblade
    [75983689] = "Game Tester", -- Agustinxd1
    [566258203] = "Game Tester", -- aidaidaiai
    [1783760731] = "Game Tester", -- AlcaponeRP1
    [3122661168] = "Game Tester", -- anomic552
    [187378148] = "Game Tester", -- AP600
    [32819957] = "Game Tester", -- asthecar
    [2270254503] = "Game Tester", -- AYOPEPOCHECK
    [3307992031] = "Game Tester", -- BaconEater171
    [4323168809] = "Game Tester", -- Bacspas3
    [1679965910] = "Game Tester", -- banana_rama0man
    [4129018777] = "Game Tester", -- BEAMEDBYU6
    [388477413] = "Game Tester", -- belucka6
    [71123508] = "Game Tester", -- BerserkerPhoenix
    [272328715] = "Game Tester", -- blueduck6
    [111282064] = "Game Tester", -- booboobooty310
    [330341352] = "Game Tester", -- breezyytsub
    [358770591] = "Game Tester", -- bude1134
    [1423307474] = "Game Tester", -- bXxlegendxXd
    [253299193] = "Game Tester", -- C4DooMB4
    [3098351403] = "Game Tester", -- Ch3et000
    [3629511297] = "Game Tester", -- Cheesyhub
    [1062012113] = "Game Tester", -- CheNyooo
    [149351059] = "Game Tester", -- ChrisKunoi
    [528878616] = "Game Tester", -- christopher_mil
    [39754447] = "Game Tester", -- convictvince
    [1166315368] = "Game Tester", -- crevette2053
    [92376478] = "Game Tester", -- dabossuSA
    [81904325] = "Game Tester", -- danailg77
    [47960346] = "Game Tester", -- darthcx
    [1740725288] = "Game Tester", -- dayrampage
    [88004813] = "Game Tester", -- dip348
    [777957956] = "Game Tester", -- Dispure
    [401977043] = "Game Tester", -- DrAgOnHeArTeD211
    [66673673] = "Game Tester", -- DrippxyMichael
    [319964782] = "Game Tester", -- duztrr
    [1843191406] = "Game Tester", -- dzixjhs
    [859559655] = "Game Tester", -- EggPlantWithSoup
    [544673905] = "Game Tester", -- Emmanuel30_05
    [964786827] = "Game Tester", -- erendu5454
    [120558923] = "Game Tester", -- Excelinq
    [528689869] = "Game Tester", -- FakeIsNotAllowed
    [1988542987] = "Game Tester", -- FatBoi8901
    [1112958760] = "Game Tester", -- fgteevsean12321
    [30925626] = "Game Tester", -- FortisAegis
    [209024298] = "Game Tester", -- freemonys
    [296957574] = "Game Tester", -- gabito224
    [4112832247] = "Game Tester", -- GAMMINGPRO9876
    [1211266317] = "Game Tester", -- GirlsAreConfusing
    [158711542] = "Game Tester", -- goochoo22
    [2908991078] = "Game Tester", -- Graydog_111
    [1369925187] = "Game Tester", -- HARIS21927
    [30420315] = "Game Tester", -- Hawj915
    [2411276967] = "Game Tester", -- hexxedVA
    [596842880] = "Game Tester", -- heybebey
    [369096190] = "Game Tester", -- hhhhhsha
    [294520324] = "Game Tester", -- hi1343344
    [354616370] = "Game Tester", -- hmmRaze
    [152602534] = "Game Tester", -- Huys_ThePvpNoob
    [5155592767] = "Game Tester", -- Iam2proud
    [2736604977] = "Game Tester", -- IamGreat400
    [744002430] = "Game Tester", -- il_rest
    [1003354757] = "Game Tester", -- ilikemuffins143
    [476384450] = "Game Tester", -- IlliteritWarden
    [89357392] = "Game Tester", -- Inferno3745
    [839169788] = "Game Tester", -- Itslettuce58976
    [125119895] = "Game Tester", -- jamesblast07
    [81244502] = "Game Tester", -- jhanix1
    [19572046] = "Game Tester", -- jockinjack
    [4818964581] = "Game Tester", -- Joex0fficial
    [266587090] = "Game Tester", -- judgemylove
    [113864715] = "Game Tester", -- justingamer20007
    [1825000373] = "Game Tester", -- Jxrvo
    [3129484805] = "Game Tester", -- kitcatIover
    [147963748] = "Game Tester", -- kkmoney225
    [943493706] = "Game Tester", -- knightgaming40
    [720369995] = "Game Tester", -- kondraccky_805
    [589240045] = "Game Tester", -- kyecooper199
    [110703379] = "Game Tester", -- lavalthelion101
    [121539737] = "Game Tester", -- ldryantran
    [2793699387] = "Game Tester", -- LilSaltines
    [462735927] = "Game Tester", -- ljh142
    [207850384] = "Game Tester", -- LonelyDwayne
    [54187785] = "Game Tester", -- LordVolta
    [93490819] = "Game Tester", -- madwolfman567
    [107643044] = "Game Tester", -- MaloniPepperoni
    [4178829350] = "Game Tester", -- maniatako922
    [1467807563] = "Game Tester", -- McJerry09
    [15068817] = "Game Tester", -- millesy98
    [1682565633] = "Game Tester", -- MXTHXIS
    [1739291317] = "Game Tester", -- N1sshoku
    [4169625678] = "Game Tester", -- Nag_Fatality
    [3336944186] = "Game Tester", -- namcygd
    [104802564] = "Game Tester", -- NoProfits
    [471184676] = "Game Tester", -- NotReallyTeal
    [1435261209] = "Game Tester", -- occss
    [36681613] = "Game Tester", -- OofyBloxx
    [173703440] = "Game Tester", -- pablothemix
    [53147489] = "Game Tester", -- pickleman703
    [105326410] = "Game Tester", -- PilotClassic
    [1903573421] = "Game Tester", -- PointMelon
    [1196539159] = "Game Tester", -- PrettylBoi
    [32511642] = "Game Tester", -- PurpleWildcat_TV
    [495196468] = "Game Tester", -- Q_rt0254
    [47600679] = "Game Tester", -- qasd5234
    [2007113987] = "Game Tester", -- Railzeur123
    [651067419] = "Game Tester", -- RainZero14
    [1430722279] = "Game Tester", -- Rand0m_dudd
    [199995959] = "Game Tester", -- Rblizzard2
    [53123109] = "Game Tester", -- ReggieMysticKush
    [3144275918] = "Game Tester", -- rek_tf
    [68032793] = "Game Tester", -- RetakeX
    [701681929] = "Game Tester", -- ricepowertograin
    [1487454844] = "Game Tester", -- RipperExistence
    [136244389] = "Game Tester", -- rmfoshocmd
    [2325994781] = "Game Tester", -- roblox_user_2325994781
    [1651300462] = "Game Tester", -- RobyNeT212006
    [769361337] = "Game Tester", -- Rovive_Academy
    [2402742033] = "Game Tester", -- s4nt1ms_kruc
    [92269758] = "Game Tester", -- Salad_Time
    [1238641965] = "Game Tester", -- segantionelton
    [2024926585] = "Game Tester", -- shadows_rin
    [2618080172] = "Game Tester", -- shoetermcgavinn
    [58895799] = "Game Tester", -- shorty8838
    [129861303] = "Game Tester", -- Slightly_Vexed
    [885074899] = "Game Tester", -- snooppuppy100
    [506132522] = "Game Tester", -- soggoni0124
    [601480881] = "Game Tester", -- solderdamon2
    [51256414] = "Game Tester", -- Sovrigh
    [2216129561] = "Game Tester", -- StEpSiS546
    [111275810] = "Game Tester", -- SuddenBog2003
    [75094576] = "Game Tester", -- superspeedymillien
    [828629819] = "Game Tester", -- supremedisgrace
    [302699989] = "Game Tester", -- talktodoves
    [3156776755] = "Game Tester", -- tewibod123
    [636711290] = "Game Tester", -- theDfizzle
    [460894635] = "Game Tester", -- TheForgottenNoob665
    [186496434] = "Game Tester", -- TheWingedGuest
    [436367347] = "Game Tester", -- timascool
    [122885852] = "Game Tester", -- TjTheBandit
    [1854518141] = "Game Tester", -- ToeNae
    [1238384774] = "Game Tester", -- universe_slayer3
    [140188350] = "Game Tester", -- UTVoidDreemurr
    [880282497] = "Game Tester", -- wardog6543211
    [2774417571] = "Game Tester", -- wisn214
    [35408811] = "Game Tester", -- wookey12
    [865455244] = "Game Tester", -- xdkillers21
    [1074469795] = "Game Tester", -- xRavageures
    [143666227] = "Game Tester", -- xshadowb910
    [193244642] = "Game Tester", -- xToxi
    [370428947] = "Game Tester", -- XxAlphaSquadX
    [410533487] = "Game Tester", -- Xxdeathuserx
    [1919836380] = "Game Tester", -- xxxchrisbrofist
    [2961878034] = "Game Tester", -- xxxtr1plex
    [1317389983] = "Game Tester", -- Y0qh
    [4520170314] = "Game Tester", -- YET_YTY
    [385583913] = "Game Tester", -- yigido201
    [3960654237] = "Game Tester", -- YuhImHimN
    [25352140] = "Game Tester", -- Yumeissotuffandcute
    [2277409973] = "Game Tester", -- zh00on

    -- OG
    [436380269] = "OG", -- acount51
    [90699110] = "OG", -- Charlogo318
    [135830651] = "OG", -- CustomChance
    [519325044] = "OG", -- epicgamergup
    [729090464] = "OG", -- erikunasX
    [36681298] = "OG", -- ipatdress
    [91044471] = "OG", -- jacobplayer555
    [75090191] = "OG", -- Militarysoup98533
    [97246381] = "OG", -- nimb1e
    [227286903] = "OG", -- OnlySoap
    [80659656] = "OG", -- pixxleatedderp
    [676856598] = "OG", -- Spoopy_Birb
    [41053073] = "OG", -- Ultramahsuperman102
    [164058661] = "OG", -- Zeus24X
}

function M.short_label(role)
    if not role then return "STAFF" end
    if role == "Game Moderator" then return "MOD" end
    if role == "Game Tester" then return "TESTER" end
    if role == "Lead Developer" or role == "Developers" then return "DEV" end
    if role == "Co-Founder" then return "CO-FOUNDER" end
    if role == "Founder" then return "FOUNDER" end
    if role == "OG" then return "OG" end
    if role == "Contribution" then return "CONTRIB" end
    return role:upper()
end

function M.glyph_kind(role)
    if not role then return "staff" end
    local r = role:lower()
    if r:find("moderator", 1, true) then return "mod" end
    if r:find("tester", 1, true) then return "tester" end
    if r:find("developer", 1, true) or r:find("founder", 1, true) then return "dev" end
    if r == "og" then return "og" end
    if r:find("contribution", 1, true) then return "contrib" end
    return "staff"
end

function M.role_for(user_id)
    if not user_id then return nil end
    return M.ROLES[user_id] or M.ROLES[tonumber(user_id)]
end

function M.is_mod(user_id)
    return M.role_for(user_id) ~= nil
end

return M
