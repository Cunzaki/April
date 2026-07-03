-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local v1 = {};
options = {
    visibleOnLoad = true,
    defaultSoundMode = "global",
    defaultSoundModeForOwners = "global",
    enableSoundModeToggle = false,
    freemiumMode = false,
    autoPlay = false,
    requireEquip = true,
    defaultPlayerSize = 2
};
tracks = {
    {
        id = "15379813342",
        artist = "zensei _____",
        title = "kaleidoscope"
    },
    {
        id = "16495782602",
        artist = "Finding Mero & Scarr.",
        title = "itÕs not easy when youÕre alone"
    },
    {
        id = "15379812739",
        artist = "Woven",
        title = "Alma"
    },
    {
        id = "15618407254",
        artist = "Aether",
        title = "Moonstone"
    },
    {
        id = "15379841115",
        artist = "zensei _____",
        title = "destination heartbreak"
    },
    {
        id = "15379849326",
        artist = "Seawayz",
        title = "Breathing Me In"
    },
    {
        id = "17267490000",
        artist = "Scarr.",
        title = "Tender"
    },
    {
        id = "15379827687",
        artist = "¯neheart & Kazukii",
        title = "restless"
    },
    {
        id = "17267543208",
        artist = "A.M.R",
        title = "Little Stars"
    },
    {
        id = "16495809984",
        artist = "JNATHYN & F.O.O.L",
        title = "Tension"
    },
    {
        id = "14985152596",
        artist = "SKYLER",
        title = "Fall"
    },
    {
        id = "14985156758",
        artist = "Godlands",
        title = "Crashing"
    },
    {
        id = "16495778963",
        artist = "KUURO",
        title = "DAMAGE"
    },
    {
        id = "16042280125",
        artist = "F.O.O.L & Waveshaper",
        title = "Encounter"
    },
    {
        id = "15618906235",
        artist = "Godlands",
        title = "SLEEPER"
    },
    {
        id = "17267465365",
        artist = "SKYLER",
        title = "Hit My Line"
    },
    {
        id = "17267580344",
        artist = "KUURO & SKUM",
        title = "Alive"
    },
    {
        id = "16042281673",
        artist = "Kage & MASTERIA",
        title = "Lights Out"
    },
    {
        id = "16495779985",
        artist = "SKYLER",
        title = "Overdrive"
    },
    {
        id = "17267542361",
        artist = "YULA",
        title = "Journey To Ascendance"
    },
    {
        id = "15618991567",
        artist = "Foxela",
        title = "fallen (Instrumental)"
    },
    {
        id = "15379807795",
        artist = "Sol Rising & Banaati",
        title = "Arise"
    },
    {
        id = "16495792511",
        artist = "Snavs",
        title = "High"
    },
    {
        id = "16495818996",
        artist = "PYLOT & F.O.O.L",
        title = "The Law"
    },
    {
        id = "17267560610",
        artist = "Forty Cats & Arentis",
        title = "Zen"
    },
    {
        id = "17267461857",
        artist = "Bound to Divide",
        title = "Spirals"
    },
    {
        id = "17267575036",
        artist = "Direct & CloudNone",
        title = "Nectar"
    },
    {
        id = "17267585504",
        artist = "PROFF",
        title = "Nara"
    },
    {
        id = "17267443085",
        artist = "ATTLAS",
        title = "A Game Of Fairies"
    }
};
playlists = { {
        id = "explore",
        isFree = false,
        name = "Explore",
        image = "17287445550",
        tracks = { "15379813342", "16495782602", "15379812739", "15618407254", "15379841115", "15379849326", "17267490000", "15379827687", "17267543208" }
    }, {
        id = "ambush",
        isFree = false,
        name = "Ambush",
        image = "17287446823",
        tracks = { "16495809984", "14985152596", "14985156758", "16495778963", "16042280125", "15618906235", "17267465365", "17267580344", "16042281673", "16495779985" }
    }, {
        id = "ascendance",
        isFree = false,
        name = "Ascendance",
        image = "17287448570",
        tracks = { "17267542361", "15618991567", "15379807795", "16495792511", "16495818996", "17267560610", "17267461857", "17267575036", "17267585504", "17267443085" }
    } };
colors = {
    white = "#ffffff",
    primary = "#111111",
    secondary = "#1c1b1b",
    highlight = "#b013ec",
    textPrimary = "#ffffff",
    textSecondary = "#868686"
};
elements = {
    cornerRadiusLarge = 9,
    cornerRadiusSmall = 3
};
images = {
    play = "rbxassetid://13894681062",
    pause = "rbxassetid://13894688190",
    search = "rbxassetid://13977518985",
    close = "rbxassetid://13977560303",
    collapse = "rbxassetid://14048045729",
    expand = "rbxassetid://14048042862",
    forward = "rbxassetid://13976610789",
    favoriteOutline = "rbxassetid://14048919972",
    favoriteSolid = "rbxassetid://14053489615",
    playlist = "rbxassetid://14054236584",
    lockedPlaylist = "rbxassetid://15421789997",
    globalActive = "rbxassetid://15474978322",
    globalDisabled = "rbxassetid://15475032917",
    back = ""
};

function v1.GetColors() -- Line: 115
    return colors;
end;

function v1.GetElements() -- Line: 119
    return elements;
end;

function v1.GetImages() -- Line: 123
    return images;
end;

function v1.GetOptions() -- Line: 127
    return options;
end;

function v1.GetTracks() -- Line: 131
    return tracks;
end;

function v1.GetPlaylists() -- Line: 135
    return playlists;
end;

return v1;