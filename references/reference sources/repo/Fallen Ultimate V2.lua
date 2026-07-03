if (not LPH_OBFUSCATED) then
    LPH_ENCNUM = function(toEncrypt, ...)
        assert(type(toEncrypt) == "number" and #{...} == 0, "LPH_ENCNUM only accepts a single constant double or integer as an argument.")
        return toEncrypt
    end
    LPH_NUMENC = LPH_ENCNUM

    LPH_ENCSTR = function(toEncrypt, ...)
        assert(type(toEncrypt) == "string" and #{...} == 0, "LPH_ENCSTR only accepts a single constant string as an argument.")
        return toEncrypt
    end
    LPH_STRENC = LPH_ENCSTR

    LPH_ENCFUNC = function(toEncrypt, encKey, decKey, ...)
        assert(type(toEncrypt) == "function" and type(encKey) == "string" and #{...} == 0, "LPH_ENCFUNC accepts a constant function, constant string, and string variable as arguments.")
        return toEncrypt
    end
    LPH_FUNCENC = LPH_ENCFUNC

    LPH_JIT = function(f, ...)
        assert(type(f) == "function" and #{...} == 0, "LPH_JIT only accepts a single constant function as an argument.")
        return f
    end
    LPH_JIT_MAX = LPH_JIT

    LPH_NO_VIRTUALIZE = function(f, ...)
        assert(type(f) == "function" and #{...} == 0, "LPH_NO_VIRTUALIZE only accepts a single constant function as an argument.")
        return f
    end

    LPH_NO_UPVALUES = function(f, ...)
        assert(type(setfenv) == "function", "LPH_NO_UPVALUES can only be used on Lua versions with getfenv & setfenv")
        assert(type(f) == "function" and #{...} == 0, "LPH_NO_UPVALUES only accepts a single constant function as an argument.")
        return f
    end

    LPH_CRASH = function(...)
        assert(#{...} == 0, "LPH_CRASH does not accept any arguments.")
    end
end

local Cheat = { GameName = 'None', Modules = { }, Globals = { } }

local Globals = {};
game:GetService("ScriptContext").Error:Connect(function(msg, trace, scr)
    if not scr or trace:find("''") or msg:find("''") or trace:find('ChocoSploit') or msg:find('ChocoSploit') then
        game:GetService("Players").LocalPlayer:Kick('error detected\n' .. msg)
    end
end)

local LastVisible = {}
local VisibleHoldTime = 0.15


local Crosshair = {
	--
};

--// FOV Bypass
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Mt = getrawmetatable(Camera)
local OldIndex = Mt.__index
setreadonly(Mt, false)

Mt.__index = newcclosure(function(Self, Key)
    if Self == Camera and Key == "FieldOfView" then
        return 70
    end
    return OldIndex(Self, Key)
end)
setreadonly(Mt, true)

do
    local Converted = {
        ["_Crosshair"] = Instance.new("ScreenGui"),
        ["_Container"] = Instance.new("Frame"),
        ["_1"] = Instance.new("Frame"),
        ["_1G"] = Instance.new("UIGradient"),
        ["_2"] = Instance.new("Frame"),
        ["_2G"] = Instance.new("UIGradient"),
        ["_3"] = Instance.new("Frame"),
        ["_3G"] = Instance.new("UIGradient"),
        ["_4"] = Instance.new("Frame"),
        ["_4G"] = Instance.new("UIGradient"),
    }

    Converted["_Crosshair"].Name = "Crosshair"
    Converted["_Crosshair"].Parent = game:GetService("CoreGui")
    Converted["_Crosshair"].IgnoreGuiInset = true
    Converted["_Crosshair"].Enabled = false

    Converted["_Container"].AnchorPoint = Vector2.new(0.5, 0.5)
    Converted["_Container"].Position = UDim2.new(0.5, 0, 0.5, 0)
    Converted["_Container"].Size = UDim2.new(0, 0, 0, 0)
    Converted["_Container"].BackgroundTransparency = 1
    Converted["_Container"].Parent = Converted["_Crosshair"]

    local function makeLine(obj, size, pos)
        obj.AnchorPoint = Vector2.new(0.5, 0.5)
        obj.BackgroundColor3 = Color3.new(1,1,1)
        obj.BorderSizePixel = 0
        obj.Size = size
        obj.Position = pos
        obj.Parent = Converted["_Container"]

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.new(0,0,0)
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = obj
    end

    makeLine(Converted["_1"], UDim2.new(0,1,0,20), UDim2.new(0.5,0,0.5,-20))
    makeLine(Converted["_2"], UDim2.new(0,1,0,20), UDim2.new(0.5,0,0.5,20))
    makeLine(Converted["_3"], UDim2.new(0,20,0,1), UDim2.new(0.5,20,0.5,0))
    makeLine(Converted["_4"], UDim2.new(0,20,0,1), UDim2.new(0.5,-20,0.5,0))

    local function makeGradient(g, rot)
        g.Rotation = rot or 0
        g.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.6, 0.7),
            NumberSequenceKeypoint.new(1, 1)
        }
    end

    makeGradient(Converted["_1G"], 270)
    makeGradient(Converted["_2G"], 90)
    makeGradient(Converted["_3G"], 0)
    makeGradient(Converted["_4G"], 180)

    Converted["_1G"].Parent = Converted["_1"]
    Converted["_2G"].Parent = Converted["_2"]
    Converted["_3G"].Parent = Converted["_3"]
    Converted["_4G"].Parent = Converted["_4"]

    Crosshair.ScreenGui = Converted["_Crosshair"]
    Crosshair.MainFrame = Converted["_Container"]

    Crosshair.Objects = {
        Converted["_1"],
        Converted["_2"],
        Converted["_3"],
        Converted["_4"]
    }
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Library = loadstring([===[--[[
    NAME: Aether.lua
    FOR: PUBLIC SALE
]]

-- Variables
    local ServiceCache = {};
    getgenv().Services = setmetatable({}, {__index = function(Self, Index)
        if not ServiceCache[Index] then
            ServiceCache[Index] = cloneref(game:GetService(Index));
        end;

        return ServiceCache[Index];
    end});

    local Keys = {
        [Enum.KeyCode.LeftShift] = "LS",
        [Enum.KeyCode.RightShift] = "RS",
        [Enum.KeyCode.LeftControl] = "LC",
        [Enum.KeyCode.RightControl] = "RC",
        [Enum.KeyCode.Insert] = "INS",
        [Enum.KeyCode.Backspace] = "BS",
        [Enum.KeyCode.Return] = "Ent",
        [Enum.KeyCode.LeftAlt] = "LA",
        [Enum.KeyCode.RightAlt] = "RA",
        [Enum.KeyCode.CapsLock] = "CAPS",
        [Enum.KeyCode.One] = "1",
        [Enum.KeyCode.Two] = "2",
        [Enum.KeyCode.Three] = "3",
        [Enum.KeyCode.Four] = "4",
        [Enum.KeyCode.Five] = "5",
        [Enum.KeyCode.Six] = "6",
        [Enum.KeyCode.Seven] = "7",
        [Enum.KeyCode.Eight] = "8",
        [Enum.KeyCode.Nine] = "9",
        [Enum.KeyCode.Zero] = "0",
        [Enum.KeyCode.KeypadOne] = "Num1",
        [Enum.KeyCode.KeypadTwo] = "Num2",
        [Enum.KeyCode.KeypadThree] = "Num3",
        [Enum.KeyCode.KeypadFour] = "Num4",
        [Enum.KeyCode.KeypadFive] = "Num5",
        [Enum.KeyCode.KeypadSix] = "Num6",
        [Enum.KeyCode.KeypadSeven] = "Num7",
        [Enum.KeyCode.KeypadEight] = "Num8",
        [Enum.KeyCode.KeypadNine] = "Num9",
        [Enum.KeyCode.KeypadZero] = "Num0",
        [Enum.KeyCode.Minus] = "-",
        [Enum.KeyCode.Equals] = "=",
        [Enum.KeyCode.Tilde] = "~",
        [Enum.KeyCode.LeftBracket] = "[",
        [Enum.KeyCode.RightBracket] = "]",
        [Enum.KeyCode.RightParenthesis] = ")",
        [Enum.KeyCode.LeftParenthesis] = "(",
        [Enum.KeyCode.Semicolon] = ",",
        [Enum.KeyCode.Quote] = "'",
        [Enum.KeyCode.BackSlash] = "\\",
        [Enum.KeyCode.Comma] = ",",
        [Enum.KeyCode.Period] = ".",
        [Enum.KeyCode.Slash] = "/",
        [Enum.KeyCode.Asterisk] = "*",
        [Enum.KeyCode.Plus] = "+",
        [Enum.KeyCode.Period] = ".",
        [Enum.KeyCode.Backquote] = "`",
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
        [Enum.KeyCode.Escape] = "ESC",
        [Enum.KeyCode.Space] = "SPC",
    }

    local Camera = workspace.CurrentCamera
    local LocalPlayer = Services.Players.LocalPlayer
    local GuiInset = Services.GuiService:GetGuiInset().Y
    local Mouse = LocalPlayer:GetMouse()
--

if getgenv().Library and getgenv().Library.Unload then
    getgenv().Library:Unload()
end

getgenv().Library = {
    Directory = "Ultimate",
    Folders = {
        "/Fonts",
        "/Configs",
        "/Themes",
    },

    Flags = {};
    ConfigFlags = {};
    Connections = {};
    Threads = {};
    Blurs = {};
    Notifications = {Notifs = {}};
    Keybinds = {};
    Mods = {};

    OpenElement = {};

    EasingStyle = Enum.EasingStyle.Quint;
    EasingDirection = Enum.EasingDirection.InOut;
    TweeningSpeed = .3;
    DraggingSpeed = .05;
    Tweening = false;
}; do
    Library.__index = Library

    for _,path in Library.Folders do
        makefolder(Library.Directory .. path)
    end

    if not isfile(Library.Directory.."/Autoload.txt") then
        writefile(Library.Directory.."/Autoload.txt", "")
    end

    local Flags = Library.Flags
    local ConfigFlags = Library.ConfigFlags
    local Notifications = Library.Notifications

    local Themes = {
        Preset = {
            ["Accent"] = Color3.fromRGB(0, 189, 255),
            ["ElementBackground"] = Color3.fromRGB(20, 20, 22),
            ["SectionBackground"] = Color3.fromRGB(15, 16, 18),
            ["ElementOutline"] = Color3.fromRGB(25, 25, 29),
            ["Inline"] = Color3.fromRGB(23, 24, 27),
            ["Other"] = Color3.fromRGB(24, 24, 24),
            ["TabButtons"] = Color3.fromRGB(20, 22, 26),
            ["Unselected"] = Color3.fromRGB(170, 170, 170),
            ["TextColor"] = Color3.fromRGB(255, 255, 255),
            ["Background"] = Color3.fromRGB(12, 12, 14),
            ["Font"] = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        };
        Utility = {};
    }; do
        for Theme, Color in Themes.Preset do
            if Theme == "font" then
                continue
            end

            Themes.Utility[Theme] = {
                BackgroundColor3 = {};
                TextColor3 = {};
                ImageColor3 = {};
                ScrollBarImageColor3 = {};
                Color = {};
            }
        end

        Library.Themify = function(self, Theme, Property)
            table.insert(Themes.Utility[Theme][Property], self.Instance)

            return self
        end

        Library.Refresh = function(self, Theme, Color)
            for Property, Data in Themes.Utility[Theme] do
                for _,Object in Data do
                    if (Property == "Color" or property == "Transparency") and not (Object:IsA("UIStroke") or Object:IsA("UIGradient")) then
                        continue
                    end

                    if (Object[Property] == Themes.Preset[Theme]) then
                        Object[Property] = Color
                    end
                end
            end

            Themes.Preset[Theme] = Color
        end

        Library.GetTheme = function(self)
            local Config = {}

            for Idx, Value in Themes.Preset do
                if Idx == "Font" then
                    continue
                end

                Config[Idx] = {Transparency = 1, Color = Value:ToHex()}
            end

            return Services.HttpService:JSONEncode(Config)
        end

        Library.SaveTheme = function(self, Config)
            local Path = string.format("%s/%s/%s.Cfg", Library.Directory, "Themes", Config)
            writefile(Path, self:GetTheme())
        end

        Library.DeleteTheme = function(self, Config)
            local Path = string.format("%s/%s/%s.Cfg", Library.Directory, "Themes", Config)

            if isfile(Path) then
                delfile(Path)
            end
        end

        Library.UpdateThemingList = function(self)
            local List = {}

            for _, File in listfiles(Library.Directory .. "/Themes") do
                local Name = File:gsub(Library.Directory .. "/Themes\\", ""):gsub(".Cfg", ""):gsub(Library.Directory .. "\\Themes\\", "")
                List[#List + 1] = Name
            end

            self.RefreshOptions(List)
        end
    end

    Library.GetTransparency = function(self, obj)
        local Instance = obj

        if Instance:IsA("Frame") then
            return {"BackgroundTransparency"}
        elseif Instance:IsA("TextLabel") or Instance:IsA("TextButton") then
            return { "TextTransparency", "BackgroundTransparency" }
        elseif Instance:IsA("ImageLabel") or Instance:IsA("ImageButton") then
            return { "BackgroundTransparency", "ImageTransparency" }
        elseif Instance:IsA("ScrollingFrame") then
            return { "BackgroundTransparency", "ScrollBarImageTransparency" }
        elseif Instance:IsA("TextBox") then
            return { "TextTransparency", "BackgroundTransparency" }
        elseif Instance:IsA("UIStroke") then
            return { "Transparency" }
        elseif Instance:IsA("BasePart") then
            return { "Transparency" }
        end

        return nil
    end

    Library.Tween = function(self, Properties, Info, Obj)
        local Instance = self.Instance or Obj

        local Tween = Services.TweenService:Create(Instance, Info or TweenInfo.new(Library.TweeningSpeed, Library.EasingStyle, Enum.EasingDirection.InOut, 0, false, 0), Properties)
        Tween:Play()

        return Tween
    end

    Library.AddGlow = function(self, Options)
        Options = Options or {}

        local Cfg = {
            Amount = Options.Amount or 5;
            DampingFactor = Options.DampingFactor or 0.4;
            Parent = self.Instance;
            Items = {};
        }

        local Items = Cfg.Items;

        for Outline = 0, Cfg.Amount do
            Items[tostring(Outline)] = Library:Create( "UIStroke", {
                Parent = self.Instance;
                Color = Themes.Preset.Accent;
                BorderOffset = UDim.new(0, Outline);
                Transparency = (Outline / (Cfg.Amount + Cfg.DampingFactor))
            }):Themify("Accent", "Color")

            Library:Create( "UIGradient", {
                Parent = Items[tostring(Outline)].Instance;
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, Cfg.DampingFactor),
                    NumberSequenceKeypoint.new(1, Cfg.DampingFactor)
                }
            })
        end

        table.insert(Library.Glows, Cfg)

        return self
    end

    Library.Fade = function(self, obj, prop, vis)
        if not (prop and obj) then
            return
        end

        local OldTransparency = obj[prop]
        obj[prop] = vis and 1 or OldTransparency

        local Animation = Library:Tween({[prop] = vis and OldTransparency or 1}, nil, obj)
        Library:Connect(Animation.Completed, function()
            if not vis then
                obj[prop] = OldTransparency
            end
        end)

        return Animation
    end

    Library.TweenDescendants = function(self, Bool, Path)
        Path = Path or {Tweening = false}

        if Path.Tweening == true then
            return
        end

        local Instance = self.Instance
        Path.Tweening = true

        if Bool then
            Instance.Visible = true
        end

        local Children = Instance:GetDescendants()
        table.insert(Children, Instance)

        if self.Blur then
            table.insert(Children, self.Blur)
        end

        local FadingAnimation;
        for _,obj in Children do
            local Index = Library:GetTransparency(obj)

            if not Index then
                continue
            end

            if type(Index) == "table" then
                for _,prop in Index do
                    FadingAnimation = Library:Fade(obj, prop, Bool)
                end
            else
                FadingAnimation = Library:Fade(obj, Index, Bool)
            end
        end

        Library:Connect(FadingAnimation.Completed, function()
            Path.Tweening = false
            Instance.Visible = Bool
        end)
    end

    Library.Resizify = function(self)
        local Instance = self.Instance

        local Resizing = Library:Create("TextButton", {
            Position = UDim2.new(1, -10, 1, -10);
            Size = UDim2.new(0, 10, 0, 10);
            BorderSizePixel = 0;
            Parent = Instance;
            BackgroundTransparency = 1;
            Text = ""
        })

        local IsResizing = false
        local Size;
        local InputLost;
        local ParentSize = Instance.Size

        Resizing.Instance.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                IsResizing = true
                InputLost = input.Position
                Size = Instance.Size
            end
        end)

        Resizing.Instance.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                IsResizing = false
            end
        end)

        Library:Connect(Services.UserInputService.InputChanged, function(input, game_event)
            if IsResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                self:Tween({
                    Size = UDim2.new(
                        Size.X.Scale,
                        math.clamp(Size.X.Offset + (input.Position.X - InputLost.X), ParentSize.X.Offset, Camera.ViewportSize.X),
                        Size.Y.Scale,
                        math.clamp(Size.Y.Offset + (input.Position.Y - InputLost.Y), ParentSize.Y.Offset, Camera.ViewportSize.Y)
                    )
                }, TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0))
            end
        end)
    end

    Library.Hovering = function(self)
        local y_cond = self.Instance.AbsolutePosition.Y <= Mouse.Y and Mouse.Y <= self.Instance.AbsolutePosition.Y + self.Instance.AbsoluteSize.Y
        local x_cond = self.Instance.AbsolutePosition.X <= Mouse.X and Mouse.X <= self.Instance.AbsolutePosition.X + self.Instance.AbsoluteSize.X

        return (y_cond and x_cond)
    end

    Library.Draggify = function(self)
        local Instance = self.Instance

        local Dragging = false
        local IntialSize = Instance.Position
        local InitialPosition

        Instance.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                InitialPosition = Input.Position
                InitialSize = Instance.Position
            end
        end)

        Instance.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end)

        Library:Connect(Services.UserInputService.InputChanged, function(Input, GameEvent)
            if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                local Horizontal = Camera.ViewportSize.X
                local Vertical = Camera.ViewportSize.Y

                local NewPosition = UDim2.new(
                    0,
                    InitialSize.X.Offset + (Input.Position.X - InitialPosition.X),
                    0,
                    InitialSize.Y.Offset + (Input.Position.Y - InitialPosition.Y)
                )

                self:Tween({Position = NewPosition}, TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0))
            end
        end)

        return self
    end

    Library.ConvertToHex = function(self, Color)
        local r = math.floor(Color.R * 255)
        local g = math.floor(Color.G * 255)
        local b = math.floor(Color.B * 255)
        return string.format("#%02X%02X%02X", r, g, b)
    end

    Library.ConvertFromHex = function(self, Color)
        Color = Color:gsub("#", "")
        local r = tonumber(Color:sub(1, 2), 16) / 255
        local g = tonumber(Color:sub(3, 4), 16) / 255
        local b = tonumber(Color:sub(5, 6), 16) / 255
        return Color3.new(r, g, b)
    end

    Library.GroupRGB = function(self, String)
        local Values = {}

        for Value in string.gmatch(String, "[^,]+") do
            table.insert(Values, tonumber(Value))
        end

        if #Values == 4 then
            return unpack(Values)
        else
            return
        end
    end

    Library.ConvertEnum = function(self, enum)
        local EnumParts = {}

        for _,part in string.gmatch(tostring(enum), "[%w_]+") do
            table.insert(EnumParts, part)
        end

        local EnumTable = tostring(enum)

        for i = 2, #EnumParts do
            local EnumItem = EnumTable[EnumParts[i]]

            EnumTable = EnumItem
        end

        return EnumTable
    end

    Library.Lerp = function(self, start, finish, t)
        t = t or 1 / 8

        return start * (1 - t) + finish * t
    end

    Library.Round = function(self, num, float)
        local Multiplier = 1 / (float or 1)
        return math.floor(num * Multiplier + 0.5) / Multiplier
    end

    Library.UpdateConfigList = function(self)
        local List = {}

        for _, File in listfiles(Library.Directory .. "/Configs") do
            local Name = File:gsub(Library.Directory .. "/Configs\\", ""):gsub(".Cfg", ""):gsub(Library.Directory .. "\\Configs\\", "")
            List[#List + 1] = Name
        end

        self.RefreshOptions(List)
    end

    Library.Keypicker = function(self, properties)
        local Cfg = {
            Text = properties.Text or "Color",
            Flag = properties.Flag or properties.Name or "Colorpicker",
            Callback = properties.Callback or function() end,

            Color = properties.Color or Color3.fromRGB(1, 1, 1), -- Default to white color if not provided
            Alpha = properties.Alpha or properties.Transparency or 0,

            -- Other
            Open = false,
            Items = {};
            Tweening = false;
        }

        local DraggingSat = false
        local DraggingHue = false
        local DraggingAlpha = false

        local h, s, v = Cfg.Color:ToHSV()
        local a = Cfg.Alpha

        local OldHue = h;
        local OldAlpha = a;

        Flags[Cfg.Flag] = {Color = Cfg.Color, Transparency = Cfg.Alpha}

        local Items = Cfg.Items; do
            Items.Holder = self.Items.Holder
            if not Items.Holder then
                Items.Object = Library:Create( "Frame", {
                    Parent = self.Items.Elements.Instance;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(1, 0, 0, 18);
                    BorderSizePixel = 0
                })

                Items.Text = Library:Create( "TextLabel", {
                    FontFace = Themes.Preset.Font;
                    TextColor3 = Color3.fromRGB(252, 252, 252);
                    Text = Cfg.Text;
                    Parent = Items.Object.Instance;
                    AnchorPoint = Vector2.new(0, 0.5);
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 0, 0.5, 0);
                    BorderSizePixel = 0;
                    ZIndex = 2
                })

                Items.Holder = Library:Create( "Frame", {
                    Parent = Items.Object.Instance;
                    Position = UDim2.new(1, 1, 0, 0);
                    Size = UDim2.new(0, 0, 1, 0);
                    BorderSizePixel = 0
                })

                Library:Create( "UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    Parent = Items.Holder.Instance;
                    Padding = UDim.new(0, 7);
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            Items.ColorpickerObject = Library:Create( "Frame", {
                AnchorPoint = Vector2.new(1, 0);
                Parent = Items.Holder.Instance;
                Position = UDim2.new(1, 1, 0, 0);
                Size = UDim2.new(0, 16, 0, 16);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Accent"]
            }):Themify("Accent", "BackgroundColor3")

            Library:Create( "UICorner", {
                Parent = Items.ColorpickerObject.Instance;
                CornerRadius = UDim.new(0, 5)
            })

            do -- Element clicker
                Items.Colorpicker = Library:Create( "TextButton", {
                    Parent = Library.Other.Instance;
                    Position = UDim2.new(0.04664722830057144, 0, 0.17076167464256287, 0);
                    Size = UDim2.new(0, 221, 0, 257);
                    BorderSizePixel = 0;
                    BackgroundColor3 = Themes.Preset["Background"]
                }):Themify("Background", "BackgroundColor3")

                Library:Create( "UIStroke", {
                    Parent = Items.Colorpicker.Instance;
                    Transparency = 0.5
                })

                Library:Create( "UICorner", {
                    Parent = Items.Colorpicker.Instance;
                    CornerRadius = UDim.new(0, 10)
                })

                Items.Title = Library:Create( "TextLabel", {
                    FontFace = Themes.Preset.Font;
                    TextColor3 = Themes.Preset["TextColor"];
                    Text = "Colorpicker";
                    Parent = Items.Colorpicker.Instance;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 8, 0, 8);
                    BorderSizePixel = 0;
                    ZIndex = 2
                }):Themify("TextColor", "TextColor3")

                Items.SatValBackground = Library:Create( "Frame", {
                    Parent = Items.Colorpicker.Instance;
                    Position = UDim2.new(0, 8, 0, 33);
                    Size = UDim2.new(1, -43, 1, -101);
                    BorderSizePixel = 0;
                    BackgroundColor3 = Color3.fromRGB(21, 255, 99)
                })

                Items.Saturation = Library:Create( "Frame", {
                    Parent = Items.SatValBackground.Instance;
                    Size = UDim2.new(1, 0, 1, 0);
                    ZIndex = 2;
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255);
                    BorderSizePixel = 0
                })

                Library:Create( "UIGradient", {
                    Rotation = 270;
                    Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                };
                    Parent = Items.Saturation.Instance;
                    Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
                }
                })

                Library:Create( "UICorner", {
                    Parent = Items.Saturation.Instance;
                    CornerRadius = UDim.new(0, 3)
                })

                Items.Value = Library:Create( "Frame", {
                    Parent = Items.SatValBackground.Instance;
                    Size = UDim2.new(1, 0, 1, 0);
                    BorderSizePixel = 0
                })

                Library:Create( "UIGradient", {
                    Parent = Items.Value.Instance;
                    Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }
                })

                Library:Create( "UICorner", {
                    Parent = Items.Value.Instance;
                    CornerRadius = UDim.new(0, 5)
                })

                Library:Create( "UICorner", {
                    Parent = Items.SatValBackground.Instance;
                    CornerRadius = UDim.new(0, 5)
                })

                Library:Create( "UIStroke", {
                    Color = Themes.Preset.ElementOutline;
                    Parent = Items.SatValBackground.Instance
                }):Themify("ElementOutline", "Color")

                Items.SatValPickerHolder = Library:Create( "Frame", {
                    Parent = Items.SatValBackground.Instance;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 3, 0, 3);
                    Size = UDim2.new(1, -6, 1, -6);
                    BorderSizePixel = 0
                })

                Items.SatValPicker = Library:Create( "Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5);
                    Parent = Items.SatValPickerHolder.Instance;
                    Position = UDim2.new(0.5, 0, 0.5, 0);
                    Size = UDim2.new(0, 7, 0, 7);
                    ZIndex = 1000;
                    BorderSizePixel = 0;
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                })

                Library:Create( "UICorner", {
                    Parent = Items.SatValPicker.Instance;
                    CornerRadius = UDim.new(1, 5)
                })

                Items.Inline = Library:Create( "Frame", {
                    Parent = Items.SatValPicker.Instance;
                    AnchorPoint = Vector2.new(0.5, 0.5);
                    BackgroundTransparency = 0.3499999940395355;
                    Position = UDim2.new(0.5, 0, 0.5, 0);
                    Size = UDim2.new(1, -2, 1, -2);
                    ZIndex = 1001;
                    BorderSizePixel = 0
                })

                Library:Create( "UICorner", {
                    Parent = Items.Inline.Instance;
                    CornerRadius = UDim.new(1, 0)
                })

                Items.Hue = Library:Create( "Frame", {
                    AnchorPoint = Vector2.new(1, 0);
                    Parent = Items.Colorpicker.Instance;
                    Position = UDim2.new(1, -8, 0, 32);
                    Size = UDim2.new(0, 18, 1, -100);
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255);
                    BorderSizePixel = 0
                })

                Library:Create( "UICorner", {
                    Parent = Items.Hue.Instance;
                    CornerRadius = UDim.new(0, 5)
                })

                Library:Create( "UIGradient", {
                    Rotation = 90;
                    Parent = Items.Hue.Instance;
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                    }
                })

                Library:Create( "UIStroke", {
                    Color = Themes.Preset.ElementOutline;
                    Parent = Items.Hue.Instance
                }):Themify("ElementOutline", "Color")

                Items.HuePickerHolder = Library:Create( "Frame", {
                    Parent = Items.Hue.Instance;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 0, 0, 3);
                    Size = UDim2.new(1, 0, 1, -6);
                    BorderSizePixel = 0
                })

                Items.HuePicker = Library:Create( "Frame", {
                    Parent = Items.HuePickerHolder.Instance;
                    AnchorPoint = Vector2.new(0.5, 0.5);
                    BackgroundTransparency = 0.3499999940395355;
                    Position = UDim2.new(0.5, 0, 0.5, 0);
                    Size = UDim2.new(1, 0, 0, 6);
                    ZIndex = 100;
                    BorderSizePixel = 0
                })

                Library:Create( "UICorner", {
                    Parent = Items.HuePicker.Instance;
                    CornerRadius = UDim.new(0, 2)
                })

                Library:Create( "UIStroke", {
                    Parent = Items.HuePicker.Instance
                })

                Items.Alpha = Library:Create( "Frame", {
                    AnchorPoint = Vector2.new(0, 1);
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255);
                    Parent = Items.Colorpicker.Instance;
                    Position = UDim2.new(0, 8, 1, -41);
                    Size = UDim2.new(1, -17, 0, 18);
                    BorderSizePixel = 0
                })

                Library:Create( "UICorner", {
                    Parent = Items.Alpha.Instance;
                    CornerRadius = UDim.new(0, 5)
                })

                Items.AlphaIndicator = Library:Create( "ImageLabel", {
                    ScaleType = Enum.ScaleType.Tile;
                    ClipsDescendants = true;
                    Parent = Items.Alpha.Instance;
                    Rotation = 180;
                    Image = "rbxassetid://18274452449";
                    BackgroundTransparency = 1;
                    Size = UDim2.new(1, 0, 1, 0);
                    TileSize = UDim2.new(0, 6, 0, 6);
                    BorderSizePixel = 0
                })

                Items.AlphaIndicatorHolder = Library:Create( "Frame", {
                    Parent = Items.AlphaIndicator.Instance;
                    Size = UDim2.new(1, 0, 1, 0);
                    BorderSizePixel = 0
                })

                Library:Create( "UICorner", {
                    Parent = Items.AlphaIndicatorHolder.Instance;
                    CornerRadius = UDim.new(0, 5)
                })

                Items.AlphaGradient = Library:Create( "UIGradient", {
                    Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(21, 255, 99)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 255, 99))
                };
                    Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                };
                    Parent = Items.AlphaIndicatorHolder.Instance
                })

                Library:Create( "UICorner", {
                    Parent = Items.AlphaIndicator.Instance;
                    CornerRadius = UDim.new(0, 5)
                })

                Library:Create( "UIStroke", {
                    Color = Themes.Preset.ElementOutline;
                    Parent = Items.Alpha.Instance
                }):Themify("ElementOutline", "Color")

                Items.AlphaPickerHolder = Library:Create( "Frame", {
                    Parent = Items.Alpha.Instance;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 3, 0, 0);
                    Size = UDim2.new(1, -6, 1, 0);
                    BorderSizePixel = 0
                })

                Items.AlphaPicker = Library:Create( "Frame", {
                    Parent = Items.AlphaPickerHolder.Instance;
                    AnchorPoint = Vector2.new(0.5, 0.5);
                    BackgroundTransparency = 0.3499999940395355;
                    Position = UDim2.new(0.5, 0, 0.5, 0);
                    Size = UDim2.new(0, 6, 1, 0);
                    ZIndex = 100;
                    BorderSizePixel = 0
                })

                Library:Create( "UICorner", {
                    Parent = Items.AlphaPicker.Instance;
                    CornerRadius = UDim.new(0, 2)
                })

                Library:Create( "UIStroke", {
                    Parent = Items.AlphaPicker.Instance
                })

                Items.Elements = Library:Create( "Frame", {
                    Parent = Items.Colorpicker.Instance;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 8, 1, -32);
                    Size = UDim2.new(1, -16, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y
                })

                local Section = setmetatable({Items = Items}, Library)
                Items.RGB = Section:AddInput({Flag = "ignore", PlaceHolder = "Color", Callback = function(text)
                    if Cfg.Set then
                        local r, g, b, a = Library:GroupRGB(text)

                        if (r and g and b and a) then
                            Cfg.Set(Color3.fromRGB(r, g, b), 1 - a)
                        else
                            Cfg.Set(Color3.fromHSV(h, s, v), 1 - a)
                        end
                    end
                end})

                Library:Create( "UIListLayout", {
                    Parent = Items.Elements.Instance;
                    Padding = UDim.new(0, 7);
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            do -- Holder
                Items.Colorpicker:Resizify()
                Items.Colorpicker:Reparent(Library.Elements.Instance)
            end
        end

        Cfg.SetVisible = function()
            if Cfg.Tweening == true then
                return
            end

            Cfg.Open = not Cfg.Open

            Items.Colorpicker.Instance.Position = UDim2.new(0, Items.ColorpickerObject.Instance.AbsolutePosition.X, 0, Items.ColorpickerObject.Instance.AbsolutePosition.Y + (Cfg.Open and 64 or 74))
            Items.Colorpicker:Tween({Position = UDim2.new(0, Items.ColorpickerObject.Instance.AbsolutePosition.X, 0, Items.ColorpickerObject.Instance.AbsolutePosition.Y + (Cfg.Open and 74 or 64))})
            Items.Colorpicker:TweenDescendants(Cfg.Open, Cfg)
        end

        Cfg.UpdateColor = function()
            local Mouse = Services.UserInputService:GetMouseLocation()
            local Offset = Vector2.new(Mouse.X, Mouse.Y - GuiInset)

            if DraggingSat then
                s = math.clamp((Offset - Items.Saturation.Instance.AbsolutePosition).X / Items.Saturation.Instance.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((Offset - Items.Saturation.Instance.AbsolutePosition).Y / Items.Saturation.Instance.AbsoluteSize.Y, 0, 1)
            elseif DraggingHue then
                h = math.clamp((Offset - Items.Hue.Instance.AbsolutePosition).Y / Items.Hue.Instance.AbsoluteSize.Y, 0, 1)
            elseif DraggingAlpha then
                a = math.clamp((Offset - Items.Alpha.Instance.AbsolutePosition).X / Items.Alpha.Instance.AbsoluteSize.X, 0, 1)
            end

            Cfg.Set()
        end

        Cfg.Set = function(Color, Alpha)
            if type(Color) == "boolean" then
                return
            end

            if Color then
                h, s, v = Color:ToHSV()
            end

            if Alpha then
                a = Alpha
            end

            local TweenInformation = TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
            local Flag = Flags[Cfg.Flag]

            Items.ColorpickerObject.Instance.BackgroundColor3 = Color3.fromHSV(h, s, v)
            Items.SatValBackground.Instance.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            Items.AlphaGradient.Instance.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromHSV(h, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
            }

            Items.SatValPicker:Tween({Position = UDim2.new(s, 0, 1 - v, 0)}, TweenInformation)
            Items.AlphaPicker:Tween({Position = UDim2.new(a, 0, 0.5, 0)}, TweenInformation)
            Items.HuePicker:Tween({Position = UDim2.new(0.5, 0, h, 0)}, TweenInformation)

            OldHue = h
            OldAlpha = a

            Color = Items.ColorpickerObject.Instance.BackgroundColor3 -- Overwriting to format<<

            if not Items.RGB.Focused then
                Items.RGB.Items.Textbox.Instance.Text = string.format("%s, %s, %s, %s", Library:Round(Color.R * 255), Library:Round(Color.G * 255), Library:Round(Color.B * 255), Library:Round(1 - a, 0.01))
            end

            Flags[Cfg.Flag] = {
                Color = Color;
                Transparency = a
            }

            Cfg.Callback(Color, a)
        end

        Items.ColorpickerObject:OnClick(Cfg.SetVisible)
        Items.Colorpicker:OutsideClick(Cfg)

        Cfg.DisableDragging = function()
            DraggingSat = false
            DraggingHue = false
            DraggingAlpha = false
        end

        Items.Alpha:OnDrag(Cfg.UpdateColor, function(Dragging)
            if Dragging then
                DraggingAlpha = true
            else
                Cfg.DisableDragging()
            end
        end)

        Items.Hue:OnDrag(Cfg.UpdateColor, function(Dragging)
            if Dragging then
                DraggingHue = true
            else
                Cfg.DisableDragging()
            end
        end)

        Items.Saturation:OnDrag(Cfg.UpdateColor, function(Dragging)
            if Dragging then
                DraggingSat = true
            else
                Cfg.DisableDragging()
            end
        end)

        Cfg.Set(Cfg.Color, Cfg.Alpha)

        ConfigFlags[Cfg.Flag] = Cfg.Set

        if self.UpdateSection then
            self.UpdateSection(Items.Object.Instance or self.Items.Object.Instance)
        end

        return setmetatable(Cfg, Library)
    end

    Library.GetConfig = function(self)
        local Config = {}

        for Idx, Value in Flags do
            if type(Value) == "table" and Value.Key then
                Config[Idx] = {Active = Value.Active, Mode = Value.Mode, Key = tostring(Value.Key)}
            elseif type(Value) == "table" and Value["Transparency"] and Value["Color"] then
                Config[Idx] = {Transparency = Value["Transparency"], Color = Value["Color"]:ToHex()}
            else
                Config[Idx] = Value
            end
        end

        return Services.HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(self, JSON)
        local Config = Services.HttpService:JSONDecode(JSON)

        for Idx, Value in Config do
            local Function = ConfigFlags[Idx]

            if Idx == "ignore" then
                continue
            end

            if Function then
                if type(Value) == "table" and Value["Transparency"] and Value["Color"] then
                    Function(Color3.fromHex(Value["Color"]), Value["Transparency"])
                else
                    Function(Value)
                end
            end
        end
    end

    Library.DeleteConfig = function(self, Config)
        local Path = string.format("%s/%s/%s.Cfg", Library.Directory, "Configs", Config)
        if isfile(Path) then
            delfile(Path)
        end
    end

    Library.SaveConfig = function(self, Config)
        local Path = string.format("%s/%s/%s.Cfg", Library.Directory, "Configs", Config)
        writefile(Path, self:GetConfig())
    end

    Library.AutoLoad = function(self)
        self.Window.Tweening = true
        local Name = readfile(Library.Directory.."/Autoload.txt")

        if Name ~= "" then
            for i = 1, 2 do
                self:LoadConfig(readfile(Library.Directory .. "/Configs/" .. Name .. ".Cfg"))
            end
        end
        self.Window.Tweening = false
    end

    Library.Thread = function(self, Function)
        local Thread = coroutine.create(Function)

        coroutine.wrap(function()
            coroutine.resume(Thread)
        end)()

        table.insert(self.Threads, Thread)

        return Thread
    end

    Library.SafeCall = function(self, Function, ...)
        local Arguments = { ... }
        local Success, Result = pcall(Function, table.unpack(Arguments))

        if not Success then
            warn(Result)
            return false
        end

        return Success
    end

    Library.Connect = function(self, Signal, Callback)
        local ConnectionInfo = {
            Event = Signal,
            Callback = Callback,
            Connection;
        }

        Library:Thread(function()
            ConnectionInfo.Connection = Signal:Connect(Callback)
        end)

        table.insert(self.Connections, ConnectionInfo)

        return ConnectionInfo
    end

    Library.OnClick = function(self, Callback)
        local Connection = Library:Connect(self.Instance.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Callback()
            end
        end)

        return Connection
    end

    Library.OnHover = function(self, Callback1, Callback2)
        Callback2 = Callback2 or function() end

        Library:Connect(self.Instance.MouseEnter, function()
            Callback1()
        end)

        Library:Connect(self.Instance.MouseLeave, function()
            Callback2()
        end)
    end

    Library.OnDrag = function(self, Callback1, Callback2)
        local Dragging = false
        Callback2 = Callback2 or function() end

        self.Instance.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                Callback2(Dragging)
            end
        end)

        Library:Connect(Services.UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = false
                Callback2(Dragging)
            end
        end)

        Library:Connect(Services.UserInputService.InputChanged, function(input)
            if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                Callback1(input)
            end
        end)
    end

    Library.Reparent = function(self, Parent)
        Parent = Parent or self.Instance.Parent

        local Connection = Library:Connect(self.Instance:GetPropertyChangedSignal("Visible"), function()
            local Visible = self.Instance.Visible

            self.Instance.Parent = Visible and Parent or Library.Other.Instance
        end)
    end

    Library.OutsideClick = function(self, Cfg)
        local Connection = Library:Connect(Services.UserInputService.InputBegan, function(input)
            if self.Instance.Visible == false then
                return
            end

            local InputType = input.UserInputType

            if not (InputType == Enum.UserInputType.MouseButton1 or InputType == Enum.UserInputType.Touch) then
                return
            end

            if not self:Hovering() then
                Cfg.SetVisible(false)
            end
        end)

        return Connection
    end

    Library.Disconnect = function(self, Name)
        self.Connection:Disconnect()
    end

    Library.Create = function(self, Class, Options)
        local Info = {
            Instance = Instance.new(Class);
            Properties = Options;
            Blur;
        }

        local Instance = Info.Instance

        for Property, Value in Info.Properties do
            Instance[Property] = Value
        end

        if Class == "TextButton" then
            Instance.AutoButtonColor = false
            Instance.Text = ""
        end

        if Class == "TextLabel" or Class == "TextBox" then
            Instance.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Instance.TextSize = 15
        end

        Instance.Name = "\0"

        return setmetatable(Info, Library)
    end

    Library.Unload = function(self)
        repeat task.wait() until #self.Notifications == 0

        for Index, Value in self.Connections do
            if Value.Connection then
                Value.Connection:Disconnect()
            end
        end

        for Index, Value in self.Threads do
            coroutine.close(Value)
        end

        local Items = {self.Items, self.Other, self.Blur, self.Elements, self.HUD}

        for _, Item in Items do
            if Item then
                Item.Instance:Destroy()
                Item = nil
            end
        end

        Library = nil
        getgenv().Library = nil
    end

    Library.GetCalculatePosition = function(self, Position, Normal, Origin, Direction)
        local n = Normal;
        local d = Direction;
        local v = Origin - Position;

        local num = (n.x * v.x) + (n.y * v.y) + (n.z * v.z); -- Dot exists for vector3.new too lazy to test
        local den = (n.x * d.x) + (n.y * d.y) + (n.z * d.z);
        local a = -num / den;

        return Origin + (a * Direction);
    end;

    Library.Blurify = function(self, Strength)
        Strength = Strength or 0.97

        local Instance = self.Instance
        self.Strength = Strength
        Library.Blurs[#Library.Blurs + 1] = self
        local Part = Library:Create("Part", {
            Material = Enum.Material.Glass;
            Transparency = Strength;
            Reflectance = 1;
            CastShadow = false;
            Anchored = true;
            CanCollide = false;
            CanQuery = false;
            CollisionGroup = " ";
            Size = Vector3.new(1, 1, 1) * 0.01;
            Color = Color3.fromRGB(0,0,0);
            Parent = Camera,
        });

        local BlockMesh = Library:Create("BlockMesh", {
            Parent = Part.Instance;
        })

        local DepthOfField = Library:Create("DepthOfFieldEffect", {
            Parent = Services.Lighting;
            Enabled = true;
            FarIntensity = 0;
            FocusDistance = 0;
            InFocusRadius = 1000;
            NearIntensity = 1;
            Name = ""
        })

        Library:Connect(Services.RunService.RenderStepped, function()
            if not self.Instance.Visible then
                Part.Transparency = 1
                Part.Instance.CFrame = CFrame.new(0/0, 9e9, 9e9)
                return
            end

            local Corner0 = Instance.AbsolutePosition;
            local Corner1 = Corner0 + Instance.AbsoluteSize;

            local Ray0 = Workspace.CurrentCamera.ScreenPointToRay(Workspace.CurrentCamera,Corner0.X, Corner0.Y, 1);
            local Ray1 = Workspace.CurrentCamera.ScreenPointToRay(Workspace.CurrentCamera,Corner1.X, Corner1.Y, 1);

            local Origin = Workspace.CurrentCamera.CFrame.Position + Workspace.CurrentCamera.CFrame.LookVector * (0.05 - Workspace.CurrentCamera.NearPlaneZ);

            local Normal = Workspace.CurrentCamera.CFrame.LookVector;

            local Pos0 = Library:GetCalculatePosition(Origin, Normal, Ray0.Origin, Ray0.Direction);
            local Pos1 = Library:GetCalculatePosition(Origin, Normal, Ray1.Origin, Ray1.Direction);

            Pos0 = Workspace.CurrentCamera.CFrame:PointToObjectSpace(Pos0);
            Pos1 = Workspace.CurrentCamera.CFrame:PointToObjectSpace(Pos1);

            local Size = Pos1 - Pos0;
            local Center = (Pos0 + Pos1) / 2;

            BlockMesh.Instance.Offset = Center
            BlockMesh.Instance.Scale  = Size / 0.0101;

            Part.Instance.CFrame = Workspace.CurrentCamera.CFrame;
            Part.Instance.Transparency = self.Strength
        end)

        return self
    end

    Library.Items = Library:Create( "ScreenGui" , {
        Parent = Services.CoreGui;
        Name = "\0";
        Enabled = true;
        ZIndexBehavior = Enum.ZIndexBehavior.Global;
        IgnoreGuiInset = true;
        DisplayOrder = 100;
    });

    Library.Other = Library:Create( "ScreenGui" , {
        Parent = Services.CoreGui;
        Name = "\0";
        Enabled = false;
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
        IgnoreGuiInset = true;
    });

    Library.Elements = Library:Create( "ScreenGui" , {
        Parent = Services.CoreGui;
        Name = "\0";
        Enabled = true;
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
        IgnoreGuiInset = true;
        DisplayOrder = 101;
    });

    -- // Elements
    Library.CreateWindow = function(self, Data)
        Data = Data or {}
        local Self = self

        local Cfg = {
            Title = Data.Title or "Aether.lua";
            SubText = Data.SubText or "Baseplate";
            Size = Data.Size or UDim2.fromOffset(775, 531);
            Image = Data.Image or "rbxassetid://95259225424429";
            IsMobile = Data.IsMobile or false;

            Position;
            Size;
            Items = {};
            Tweening = false;
            Tick = tick();
            Fps = 0;
            TabInfo;
            Visible = true;
        }

        local Items = Cfg.Items; do
            Items.Menu = Library:Create( "Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5);
                Parent = Library.Items.Instance;
                ClipsDescendants = true;
                Position = UDim2.fromScale(0.5, 0.5);
                Size = Cfg.Size;
                Visible = false;
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Background"]
            }):Themify("Background", "BackgroundColor3")

            Library:Create( "UIScale", {
                Parent = Items.Menu.Instance;
                Scale = 1
            })

            Items.Menu.Instance.Position = UDim2.fromOffset(Items.Menu.Instance.AbsolutePosition.X, Items.Menu.Instance.AbsolutePosition.Y)
            Items.Menu.Instance.AnchorPoint = Vector2.new(0, 0)

            Items.Menu:Draggify()
            Items.Menu:Resizify()

            Library:Create( "UICorner", {
                Parent = Items.Menu.Instance;
                CornerRadius = UDim.new(0, 10)
            })

            Library:Create( "UIStroke", {
                Parent = Items.Menu.Instance;
                Transparency = 0.5
            })

            Items.SideBar = Library:Create( "Frame", {
                Parent = Items.Menu.Instance;
                Size = UDim2.new(0, 178, 1, 0);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Background"]
            }):Themify("Background", "BackgroundColor3")

            Items.TabButtonHolder = Library:Create( "Frame", {
                Parent = Items.SideBar.Instance;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 88);
                Size = UDim2.new(1, 0, 1, -88);
                BorderSizePixel = 0
            })

            Library:Create( "UIListLayout", {
                Parent = Items.TabButtonHolder.Instance;
                Padding = UDim.new(0, 8);
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Library:Create( "UIPadding", {
                Parent = Items.TabButtonHolder.Instance;
                PaddingRight = UDim.new(0, 16);
                PaddingLeft = UDim.new(0, 16)
            })

            Library:Create( "UICorner", {
                Parent = Items.SideBar.Instance;
                CornerRadius = UDim.new(0, 10)
            })

            Library:Create( "Frame", {
                Parent = Items.SideBar.Instance;
                Position = UDim2.new(1, 0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Inline"]
            }):Themify("Inline", "BackgroundColor3")

            Items.Pages = Library:Create( "Frame", {
                Parent = Items.Menu.Instance;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 178, 0, 88);
                Size = UDim2.new(1, -178, 1, -88);
                BorderSizePixel = 0
            })

            Library:Create( "UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalFlex = Enum.UIFlexAlignment.Fill;
                Parent = Items.Pages.Instance;
                Padding = UDim.new(0, 15);
                SortOrder = Enum.SortOrder.LayoutOrder;
                VerticalFlex = Enum.UIFlexAlignment.Fill
            })

            Library:Create( "UIPadding", {
                PaddingBottom = UDim.new(0, 16);
                Parent = Items.Pages.Instance;
                PaddingLeft = UDim.new(0, 17);
                PaddingRight = UDim.new(0, 16)
            })

            Items.Topbar = Library:Create( "Frame", {
                Parent = Items.Menu.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 71);
                BorderSizePixel = 0
            })

            Items.Subtabs = Library:Create( "Frame", {
                Parent = Items.Topbar.Instance;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 178, 0, 0);
                Size = UDim2.new(1, -178, 1, 0);
                BorderSizePixel = 0
            })

            Library:Create( "UIPadding", {
                PaddingTop = UDim.new(0, 17);
                PaddingBottom = UDim.new(0, 17);
                Parent = Items.Subtabs.Instance;
                PaddingRight = UDim.new(0, 15);
                PaddingLeft = UDim.new(0, 18)
            })

            Library:Create( "Frame", {
                Parent = Items.Topbar.Instance;
                Position = UDim2.new(0, 0, 1, 0);
                Size = UDim2.new(1, 0, 0, 1);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Inline"]
            }):Themify("Inline", "BackgroundColor3")

            Items.LogoHolder = Library:Create( "Frame", {
                Parent = Items.Topbar.Instance;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 82);
                BorderSizePixel = 0
            })

            Items.Logo = Library:Create( "ImageLabel", {
                ImageColor3 = Themes.Preset["Accent"];
                Parent = Items.LogoHolder.Instance;
                AnchorPoint = Vector2.new(0, 0.5);
                Image = Cfg.Image;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 15, 0.5, -5);
                Size = UDim2.new(0, 45, 0, 46);
                BorderSizePixel = 0
            }):Themify("Accent", "ImageColor3")

            Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Themes.Preset["Accent"];
                Text = Cfg.Title;
                Parent = Items.Logo.Instance;
                AnchorPoint = Vector2.new(0, 0.5);
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Position = UDim2.new(1, 10, 0.25, 0);
                BorderSizePixel = 0;
                ZIndex = 2
            }):Themify("Accent", "TextColor3")

            Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Themes.Preset["Unselected"];
                Text = Cfg.SubText;
                Parent = Items.Logo.Instance;
                AnchorPoint = Vector2.new(0, 0.5);
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Position = UDim2.new(1, 10, 0.550000011920929, 1);
                BorderSizePixel = 0;
                ZIndex = 2
            }):Themify("Unselected", "TextColor3")

            Items.MobileFrame = Library:Create( "Frame", {
                Visible = false;
                Parent = Items.Menu.Instance;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 71);
                Size = UDim2.new(1, 0, 1, -71);
                ZIndex = 100;
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Background"]
            }):Themify("Background", "BackgroundColor3")

            Items.MobileFrame2 = Library:Create( "Frame", {
                Visible = false;
                Parent = Items.Menu.Instance;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 71, 0, 0);
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 100;
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Background"]
            }):Themify("Background", "BackgroundColor3");

                        -- // keybind list top
            Items.KeybindList = Library:Create("Frame",{ZIndex = 999; Parent = Library.HUD.Instance; Size = UDim2.new(0, 200, 0, 31); Position = UDim2.new(0, 37, 0, 401); BorderSizePixel = 0; ZIndex = 2; BackgroundColor3 = Color3.fromRGB(20, 20, 22)})
            Items.UIStroke = Library:Create("UIStroke",{Color = Color3.fromRGB(23, 24, 27); Parent = Items.KeybindList.Instance})
            Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 2); PaddingBottom = UDim.new(0, 2); Parent = Items.KeybindList.Instance; PaddingRight = UDim.new(0, 2); PaddingLeft = UDim.new(0, 2)})
            Items.UICorner = Library:Create("UICorner",{Parent = Items.KeybindList.Instance})
            Items.Titles = Library:Create("TextLabel",{LayoutOrder = 1; TextColor3 = Color3.fromRGB(245, 245, 245); Text = "Keybinds"; Parent = Items.KeybindList.Instance; AutomaticSize = Enum.AutomaticSize.XY; Position = UDim2.new(0, 0, 0, 3); BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Left; BorderSizePixel = 0; ZIndex = 2; BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
            Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 4); PaddingBottom = UDim.new(0, 6); Parent = Items.Titles.Instance; PaddingRight = UDim.new(0, 5); PaddingLeft = UDim.new(0, 7)})
            Items.Filler = Library:Create("Frame",{Parent = Items.KeybindList.Instance; Position = UDim2.new(0, -3, 1, -14); Size = UDim2.new(1, 6, 0, 18); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(20, 20, 22)})
            Items.BottomFiller = Library:Create("Frame",{AnchorPoint = Vector2.new(0, 1); Parent = Items.Filler.Instance; Position = UDim2.new(0, 0, 1, 0); Size = UDim2.new(1, 0, 0, 1); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(23, 24, 27)})
            Items.KeyboardIcon = Library:Create("ImageLabel",{ImageColor3 = Themes.Preset.Accent; Parent = Items.KeybindList.Instance; Size = UDim2.new(0, 18, 0, 18); AnchorPoint = Vector2.new(1, 0); Image = "rbxassetid://97239058232142"; BackgroundTransparency = 1; Position = UDim2.new(1, -5, 0, 5); ZIndex = 2; BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Themify("Accent", "ImageColor3")

            Items.KeybindList:Draggify()


            -- // Where the keybinds are parented
            Items.KeybindHolder = Library:Create("Frame",{ZIndex = 0; Parent = Items.KeybindList.Instance; Size = UDim2.new(0, 200, 0, 0); Position = UDim2.new(0, -2, 0, 18); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(15, 16, 18)})
            Items.UICorner = Library:Create("UICorner",{Parent = Items.KeybindHolder.Instance})
            Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 18); PaddingBottom = UDim.new(0, 2); Parent = Items.KeybindHolder.Instance; PaddingRight = UDim.new(0, 2); PaddingLeft = UDim.new(0, 2)})
            Items.UIStroke = Library:Create("UIStroke",{Color = Color3.fromRGB(23, 24, 27); Parent = Items.KeybindHolder.Instance})


            -- // Modlist list top
            Items.ModList = Library:Create("Frame",{ZIndex = 999; Parent = Library.HUD.Instance; Size = UDim2.new(0, 200, 0, 31); Position = UDim2.new(0, 37 + 200 + 10, 0, 401); BorderSizePixel = 0; ZIndex = 2; BackgroundColor3 = Color3.fromRGB(20, 20, 22)})
            Items.UIStroke = Library:Create("UIStroke",{Color = Color3.fromRGB(23, 24, 27); Parent = Items.ModList.Instance})
            Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 2); PaddingBottom = UDim.new(0, 2); Parent = Items.ModList.Instance; PaddingRight = UDim.new(0, 2); PaddingLeft = UDim.new(0, 2)})
            Items.UICorner = Library:Create("UICorner",{Parent = Items.ModList.Instance})
            Items.Titles = Library:Create("TextLabel",{LayoutOrder = 1; TextColor3 = Color3.fromRGB(245, 245, 245); Text = "Mods"; Parent = Items.ModList.Instance; AutomaticSize = Enum.AutomaticSize.XY; Position = UDim2.new(0, 0, 0, 3); BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Left; BorderSizePixel = 0; ZIndex = 2; BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
            Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 4); PaddingBottom = UDim.new(0, 6); Parent = Items.Titles.Instance; PaddingRight = UDim.new(0, 5); PaddingLeft = UDim.new(0, 7)})
            Items.Filler = Library:Create("Frame",{Parent = Items.ModList.Instance; Position = UDim2.new(0, -3, 1, -14); Size = UDim2.new(1, 6, 0, 18); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(20, 20, 22)})
            Items.BottomFiller = Library:Create("Frame",{AnchorPoint = Vector2.new(0, 1); Parent = Items.Filler.Instance; Position = UDim2.new(0, 0, 1, 0); Size = UDim2.new(1, 0, 0, 1); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(23, 24, 27)})
            Items.KeyboardIcon = Library:Create("ImageLabel",{ImageColor3 = Themes.Preset.Accent; Parent = Items.ModList.Instance; Size = UDim2.new(0, 18, 0, 18); AnchorPoint = Vector2.new(1, 0); Image = "rbxassetid://74208295465261"; BackgroundTransparency = 1; Position = UDim2.new(1, -5, 0, 5); ZIndex = 2; BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Themify("Accent", "ImageColor3")

            Items.ModList:Draggify()

            -- // Where the Mods are parented
            Items.ModHolder = Library:Create("Frame",{ZIndex = 0; Parent = Items.ModList.Instance; Size = UDim2.new(0, 200, 0, 0); Position = UDim2.new(0, -2, 0, 18); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(15, 16, 18)})
            Items.UICorner = Library:Create("UICorner",{Parent = Items.ModHolder.Instance})
            Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 18); PaddingBottom = UDim.new(0, 2); Parent = Items.ModHolder.Instance; PaddingRight = UDim.new(0, 2); PaddingLeft = UDim.new(0, 2)})
            Items.UIStroke = Library:Create("UIStroke",{Color = Color3.fromRGB(23, 24, 27); Parent = Items.ModHolder.Instance})
        end

        Items.Menu.Instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if Cfg.Visible or Cfg.Tweening then
                return
            end

            Cfg.Position = Items.Menu.Instance.AbsolutePosition
        end)

        Items.Menu.Instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if not Cfg.Visible or Cfg.Tweening then
                return
            end

            local AbsoluteSize = Items.Menu.Instance.AbsoluteSize
            Cfg.Size = Vector2.new(AbsoluteSize.X, AbsoluteSize.Y)
        end)

        Items.Watermark = Library:Create("CanvasGroup",{Parent = Library.HUD.Instance; Position = UDim2.new(0, 30, 0, 200); BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.XY; BackgroundColor3 = Color3.fromRGB(12, 12, 14)}):Draggify()
        Items.Title = Library:Create("TextLabel",{LayoutOrder = 1; TextColor3 = Color3.fromRGB(245, 245, 245); Text = Cfg.Text; Parent = Items.Watermark.Instance; BackgroundTransparency = 1; BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.XY; BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
        Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 5); PaddingBottom = UDim.new(0, 7); Parent = Items.Title.Instance; PaddingRight = UDim.new(0, 8); PaddingLeft = UDim.new(0, 8)})
        Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 2); PaddingBottom = UDim.new(0, 2); Parent = Items.Watermark.Instance; PaddingRight = UDim.new(0, 2); PaddingLeft = UDim.new(0, 2)})
        Items.UICorner = Library:Create("UICorner",{Parent = Items.Watermark.Instance})


        local AbsoluteSize = Items.Menu.Instance.AbsoluteSize
        Cfg.Size = Vector2.new(AbsoluteSize.X, AbsoluteSize.Y)

        local Frames = 0
        local FPS = 0
        local LastTick = tick()
        Services.RunService.RenderStepped:Connect(function()
            Frames += 1
            local Tick = tick()

            if Tick - LastTick >= 1 then
                FPS = Frames
                Frames = 0
                LastTick = Tick
            end

            Items.Title.Instance.Text = string.format("%s | FPS: %s | %s", Cfg.Title, tostring(FPS), os.date("%H:%M:%S"))
        end)

        function Cfg.SetVisible(Bool)
            Cfg.Visible = Bool

            if not Cfg.IsMobile then
                Items.Menu:TweenDescendants(Bool, Cfg)
                return
            end

            if not Cfg.Size then
                return
            end

            Items.MobileFrame:Tween({BackgroundTransparency = Bool and 1 or 0})
            Items.MobileFrame2:Tween({BackgroundTransparency = Bool and 1 or 0})
            Items.Menu:Tween({Size = Bool and UDim2.new(0, Cfg.Size.X, 0, Cfg.Size.Y) or UDim2.new(0, 70, 0, 70)})

            if not (Items.Subtabs.Instance.Visible and Bool) then
                Items.Subtabs:TweenDescendants(Bool, Cfg)
            end

            Cfg.Tweening = false

            if not (Items.SideBar.Instance.Visible and Bool) then
                Items.SideBar:TweenDescendants(Bool, Cfg)
            end
        end

        if Cfg.IsMobile then
            task.delay(Library.TweeningSpeed, function()
                Items.Menu:TweenDescendants(true, Cfg)
            end)

            Items.Logo:OnClick(function()
                if Cfg.Tweening then
                    return
                end

                Cfg.Visible = not Cfg.Visible

                Cfg.SetVisible(Cfg.Visible)
            end)
        end

        Library.Window = setmetatable(Cfg, Library)

        return Library.Window
    end

    Library.AddTab = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Text = Data.Text or Data.Name or Data.Title or "Tab";
            Icon = Data.Icon or "rbxassetid://108020878442937";
            Pages = Data.Pages or {"Page 1", "Page 2"};

            -- DO NOT TOUCH
            Sections = {};
            Enabled = false;
            Items = {};
            Tweening = false;
        }

        local Items = Cfg.Items; do
            do -- Button
                Items.Button = Library:Create( "Frame", {
                    Parent = self.Items.TabButtonHolder.Instance;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(1, 0, 0, 40);
                    ZIndex = 2;
                    BorderSizePixel = 0;
                    BackgroundColor3 = Themes.Preset["TabButtons"]
                }):Themify("TabButtons", "BackgroundColor3")

                Library:Create( "UICorner", {
                    Parent = Items.Button.Instance;
                    CornerRadius = UDim.new(0, 6)
                })

                Library:Create( "ImageLabel", {
                    Parent = Items.Button.Instance;
                    AnchorPoint = Vector2.new(1, 0);
                    Image = "rbxassetid://112325323968017";
                    Size = UDim2.new(0, 5, 0, 17);
                    Position = UDim2.new(1, -7, 0, 12);
                    ZIndex = 2;
                    BorderSizePixel = 0
                })

                Items.Icon = Library:Create( "ImageLabel", {
                    ImageColor3 = Themes.Preset["Unselected"];
                    Parent = Items.Button.Instance;
                    Size = UDim2.new(0, 21, 0, 21);
                    AnchorPoint = Vector2.new(0, 0.5);
                    Image = Cfg.Icon;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 13, 0.5, 0);
                    ZIndex = 2;
                    BorderSizePixel = 0
                }):Themify("Unselected", "ImageColor3"):Themify("Accent", "ImageColor3")

                Items.Title = Library:Create( "TextLabel", {
                    FontFace = Themes.Preset.Font;
                    TextColor3 = Themes.Preset["Unselected"];
                    Text = Cfg.Text;
                    Parent = Items.Icon.Instance;
                    AnchorPoint = Vector2.new(0, 0.5);
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(1, 10, 0.5, 0);
                    BorderSizePixel = 0;
                    ZIndex = 2
                }):Themify("Unselected", "TextColor3")

                Items.Glow = Library:Create( "Frame", {
                    Parent = Items.Button.Instance;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(0, 20, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = Themes.Preset["Accent"]
                }):Themify("Accent", "BackgroundColor3")

                Library:Create( "UICorner", {
                    Parent = Items.Glow.Instance;
                    CornerRadius = UDim.new(0, 3)
                })

                Items.GlowImage = Library:Create( "ImageLabel", {
                    ImageColor3 = Themes.Preset["Accent"];
                    ScaleType = Enum.ScaleType.Slice;
                    ImageTransparency = 1;
                    Parent = Items.Glow.Instance;
                    BackgroundColor3 = Themes.Preset["Accent"];
                    Size = UDim2.new(1, 20, 1, 20);
                    Image = "rbxassetid://18245826428";
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, -20, 0, -10);
                    ZIndex = 2;
                    BorderSizePixel = 0;
                    SliceCenter = Rect.new(Vector2.new(20, 20), Vector2.new(80, 80))
                }):Themify("Accent", "ImageColor3")

                Items.Background = Library:Create( "Frame", {
                    Parent = Items.Button.Instance;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 3, 0, 0);
                    Size = UDim2.new(1, -3, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = Themes.Preset["TabButtons"]
                }):Themify("TabButtons", "BackgroundColor3")

                Library:Create( "UICorner", {
                    Parent = Items.Background.Instance;
                    CornerRadius = UDim.new(0, 6)
                })

                Items.Filler = Library:Create( "Frame", {
                    Parent = Items.Background.Instance;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(0, 6, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = Themes.Preset["TabButtons"]
                }):Themify("TabButtons", "BackgroundColor3")
            end

            do -- Page
                Items.MainPage = Library:Create( "Frame", {
                    Parent = Library.Other.Instance; -- self.Items.Main.Instance
                    Visible = false;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 178, 0, 88);
                    Size = UDim2.new(1, -178, 1, -88);
                    BorderSizePixel = 0
                })
            end

            do -- Subtabs
                Items.Holder = Library:Create( "Frame", {
                    Parent = Library.Other.Instance; -- self.Items.Subtabs.Instance
                    Size = UDim2.new(0, 0, 0, 37);
                    BorderSizePixel = 0;
                    Visible = false;
                    AutomaticSize = Enum.AutomaticSize.X;
                    BackgroundColor3 = Themes.Preset["Background"]
                }):Themify("Background", "BackgroundColor3")

                Library:Create( "UICorner", {
                    Parent = Items.Holder.Instance
                })

                Items.Outline = Library:Create( "UIStroke", {
                    Color = Themes.Preset["ElementBackground"];
                    Parent = Items.Holder.Instance
                }):Themify("ElementBackground", "Color")

                Library:Create( "UIPadding", {
                    PaddingTop = UDim.new(0, 8);
                    PaddingBottom = UDim.new(0, 8);
                    Parent = Items.Holder.Instance;
                    PaddingRight = UDim.new(0, 8);
                    PaddingLeft = UDim.new(0, 7)
                })

                Library:Create( "UIListLayout", {
                    Parent = Items.Holder.Instance;
                    Padding = UDim.new(0, 5);
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    FillDirection = Enum.FillDirection.Horizontal
                })
            end
        end

        for _,Page in Cfg.Pages do
            local PageData = {
               Items = {},
               Tweening = false
            }

            local ButtonParent = Items.Holder
            local PageParent = Items.MainPage

            local MiscItems = PageData.Items; do
                -- // Button
                MiscItems.Button = Library:Create( "Frame", {
                    Parent = ButtonParent.Instance;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(0, 0, 1, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.X;
                    BackgroundColor3 = Themes.Preset["Accent"];
                    ZIndex = 9999
                }):Themify("Accent", "BackgroundColor3")

                Library:Create( "UIGradient", {
                    Parent = MiscItems.Button.Instance;
                    Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0.59375),
                        NumberSequenceKeypoint.new(1, 0)
                    }
                })

                Library:Create( "UICorner", {
                    Parent = MiscItems.Button.Instance;
                    CornerRadius = UDim.new(0, 6)
                })

                MiscItems.Text = Library:Create( "TextLabel", {
                    FontFace = Themes.Preset.Font;
                    Parent = MiscItems.Button.Instance;
                    TextColor3 = Themes.Preset["Unselected"];
                    Text = Page;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    AnchorPoint = Vector2.new(0, 0.5);
                    Size = UDim2.new(0, 0, 1, 0);
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 8, 0.5, -1);
                    BorderSizePixel = 0;
                    ZIndex = 2;
                    BackgroundColor3 = Themes.Preset["ElementBackground"]
                }):Themify("ElementBackground", "BackgroundColor3")

                Library:Create( "UIPadding", {
                    Parent = MiscItems.Button.Instance;
                    PaddingTop = UDim.new(0, 2);
                    PaddingRight = UDim.new(0, 7);
                    PaddingLeft = UDim.new(0, -3);
                })

                MiscItems.Outline = Library:Create( "UIStroke", {
                    Color = Themes.Preset["Accent"];
                    Transparency = 1;
                    Parent = MiscItems.Button.Instance
                }):Themify("Accent", "Color")

                --// Page
                MiscItems.Page = Library:Create( "Frame", {
                    Parent = Library.Other.Instance; -- PageParent.Instance
                    BackgroundTransparency = 1;
                    Visible = false;
                    Size = UDim2.new(1, 0, 1, 0);
                    BorderSizePixel = 0
                })

                Library:Create( "UIPadding", {
                    PaddingBottom = UDim.new(0, 16);
                    Parent = MiscItems.Page.Instance;
                    PaddingLeft = UDim.new(0, 17);
                    PaddingRight = UDim.new(0, 16)
                })

                Library:Create( "UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalFlex = Enum.UIFlexAlignment.Fill;
                    Parent = MiscItems.Page.Instance;
                    Padding = UDim.new(0, 15);
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    VerticalFlex = Enum.UIFlexAlignment.Fill
                })

                MiscItems.Left = Library:Create( "ScrollingFrame", {
                    ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0);
                    Active = true;
                    AutomaticCanvasSize = Enum.AutomaticSize.Y;
                    ScrollBarThickness = 0;
                    Parent = MiscItems.Page.Instance;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(0, 100, 0, 100);
                    BorderSizePixel = 0;
                    CanvasSize = UDim2.new(0, 0, 0, 0)
                })

                Library:Create( "UIPadding", {
                    PaddingTop = UDim.new(0, 1);
                    PaddingBottom = UDim.new(0, 1);
                    Parent = MiscItems.Left.Instance;
                    PaddingRight = UDim.new(0, 1);
                    PaddingLeft = UDim.new(0, 1)
                })

                Library:Create( "UIListLayout", {
                    Parent = MiscItems.Left.Instance;
                    Padding = UDim.new(0, 15);
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                MiscItems.Right = Library:Create( "ScrollingFrame", {
                    ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0);
                    Active = true;
                    AutomaticCanvasSize = Enum.AutomaticSize.Y;
                    ScrollBarThickness = 0;
                    Parent = MiscItems.Page.Instance;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(0, 100, 0, 100);
                    CanvasSize = UDim2.new(0, 0, 0, 0);
                    BorderSizePixel = 0
                })

                Library:Create( "UIPadding", {
                    PaddingTop = UDim.new(0, 1);
                    PaddingBottom = UDim.new(0, 1);
                    Parent = MiscItems.Right.Instance;
                    PaddingRight = UDim.new(0, 1);
                    PaddingLeft = UDim.new(0, 1)
                })

                Library:Create( "UIListLayout", {
                    Parent = MiscItems.Right.Instance;
                    Padding = UDim.new(0, 15);
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            PageData.OpenPage = function()
                local OldTab = Cfg.TabInfo

                if OldTab == PageData then
                    return
                end

                if PageData.Tweening or (OldTab and OldTab.Tweening) then
                    return
                end

                if OldTab then
                    OldTab.Items.Text:Tween({TextColor3 = Themes.Preset.Unselected})
                    OldTab.Items.Outline:Tween({Transparency = 1})
                    OldTab.Items.Button:Tween({BackgroundTransparency = 1})

                    OldTab.Items.Page:TweenDescendants(false, OldTab)
                end

                MiscItems.Text:Tween({TextColor3 = Themes.Preset.TextColor})
                MiscItems.Outline:Tween({Transparency = 0})
                MiscItems.Button:Tween({BackgroundTransparency = 0})
                MiscItems.Page.Instance.Size = UDim2.new(1, -40, 1, -40)
                MiscItems.Page:Tween({Size = UDim2.new(1, 0, 1, 0)})
                MiscItems.Page:TweenDescendants(true, PageData)

                Cfg.TabInfo = PageData
            end

            MiscItems.Button:OnClick(PageData.OpenPage)
            MiscItems.Page:Reparent(PageParent.Instance)

            if not Cfg.TabInfo then
                MiscItems.Outline.Instance.Transparency = 0
                MiscItems.Button.Instance.BackgroundTransparency = 0
                PageData.OpenPage()
            end

            Cfg.Sections[#Cfg.Sections + 1] = setmetatable(PageData, Library)
        end

        Cfg.OpenPage = function()
            local OldTab = self.TabInfo

            if OldTab == Cfg then
                return
            end

            if Cfg.Tweening or (OldTab and OldTab.Tweening) then
                return
            end

            if OldTab then
                OldTab.Items.Icon:Tween({ImageColor3 = Themes.Preset.Unselected})
                OldTab.Items.Title:Tween({TextColor3 = Themes.Preset.Unselected})
                OldTab.Items.GlowImage:Tween({ImageTransparency = 1})

                OldTab.Items.Glow.Instance.BackgroundTransparency = 1
                OldTab.Items.Background.Instance.BackgroundTransparency = 1
                OldTab.Items.Filler.Instance.BackgroundTransparency = 1

                OldTab.Items.MainPage:TweenDescendants(false, self)
                self.Tweening = false
                OldTab.Items.Holder:TweenDescendants(false, self)
            end

            Items.Icon:Tween({ImageColor3 = Themes.Preset.TextColor})
            Items.Title:Tween({TextColor3 = Themes.Preset.TextColor})
            Items.GlowImage:Tween({ImageTransparency = 0.69})

            Items.Glow.Instance.BackgroundTransparency = 0
            Items.Background.Instance.BackgroundTransparency = 0
            Items.Filler.Instance.BackgroundTransparency = 0

            Items.Title:Tween({TextColor3 = Themes.Preset.Accent})
            Items.Icon:Tween({ImageColor3 = Themes.Preset.Accent})

            Items.MainPage.Instance.Size = UDim2.new(1, -178 - 40, 1, -88 - 40);
            Items.MainPage:Tween({Size = UDim2.new(1, -178, 1, -88)})

            Items.MainPage:TweenDescendants(true, Cfg)
            Cfg.Tweening = false
            Items.Holder:TweenDescendants(true, Cfg)

            self.TabInfo = Cfg
        end

        Items.Holder:Reparent(self.Items.Subtabs.Instance)
        Items.MainPage:Reparent(self.Items.Menu.Instance)
        Items.Button:OnClick(Cfg.OpenPage)

        Items.GlowImage.Instance:GetPropertyChangedSignal("ImageColor3"):Connect(function()
            task.wait()

            if self.TabInfo == Cfg then
                Items.Title:Tween({TextColor3 = Themes.Preset.Accent})
                Items.Icon:Tween({ImageColor3 = Themes.Preset.Accent})
            end
        end)

        if not self.TabInfo then
            Cfg.OpenPage()
        end

        return unpack(Cfg.Sections)
    end

    Library.AddSection = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Title = Data.Title or Data.Text or Data.Name or "Title";
            Side = Data.Side or "Left";
            Collasped = Data.Collapsed or false;

            Items = {};
            Tweening = false;
            CachedSize = 0;
            Incrementing = false;
        }

        local ScalingSize = (self.Items and self.Items[Cfg.Side] and self.Items[Cfg.Side].Instance) and 1 or 0
        local OffsetSize = ScalingSize == 1 and 0 or 200

        local Items = Cfg.Items; do
            Items.Section = Library:Create( "Frame", {
                Parent = (self.Items and self.Items[Cfg.Side] and self.Items[Cfg.Side].Instance) or Library.Other.Instance;
                Size = UDim2.new(ScalingSize, OffsetSize, 0, 0);
                Position = UDim2.new(0, 1, 0, 0);
                BorderSizePixel = 0;
                ClipsDescendants = true;
                -- AutomaticSize = Enum.AutomaticSize.Y;
                BackgroundColor3 = Themes.Preset["SectionBackground"]
            }):Themify("SectionBackground", "BackgroundColor3")

            Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Themes.Preset["Unselected"];
                Text = Cfg.Title;
                Parent = Items.Section.Instance;
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 12, 0, 10);
                BorderSizePixel = 0;
                ZIndex = 2
            }):Themify("Unselected", "TextColor3")

            Items.Elements = Library:Create( "Frame", {
                Parent = Items.Section.Instance;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 12, 0, 43);
                Size = UDim2.new(1, -24, 0, 0);
                BorderSizePixel = 0;
                AutomaticSize = Enum.AutomaticSize.Y
            })

            Library:Create( "UIPadding", {
                PaddingBottom = UDim.new(0, 8);
                Parent = Items.Elements.Instance
            })

            Library:Create( "UIListLayout", {
                Parent = Items.Elements.Instance;
                Padding = UDim.new(0, 13);
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Library:Create( "UICorner", {
                Parent = Items.Section.Instance;
                CornerRadius = UDim.new(0, 6)
            })

            Library:Create( "UIStroke", {
                Color = Themes.Preset["Inline"];
                Parent = Items.Section.Instance
            }):Themify("Inline", "Color")

            Items.TopBar = Library:Create( "Frame", {
                Parent = Items.Section.Instance;
                Size = UDim2.new(1, 0, 0, 35);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["ElementBackground"]
            }):Themify("ElementBackground", "BackgroundColor3")

            Items.Filler1 = Library:Create( "Frame", {
                AnchorPoint = Vector2.new(0, 1);
                Parent = Items.TopBar.Instance;
                Position = UDim2.new(0, 0, 1, 0);
                Size = UDim2.new(1, 0, 0, 6);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["ElementBackground"]
            }):Themify("ElementBackground", "BackgroundColor3")

            Items.Filler2 = Library:Create( "Frame", {
                Parent = Items.TopBar.Instance;
                Position = UDim2.new(0, 0, 1, -1);
                Size = UDim2.new(1, 0, 0, 1);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["TabButtons"]
            }):Themify("TabButtons", "BackgroundColor3")

            Library:Create( "UICorner", {
                Parent = Items.TopBar.Instance;
                CornerRadius = UDim.new(0, 6)
            })

            Items.Image = Library:Create( "ImageLabel", {
                Parent = Items.TopBar.Instance;
                Size = UDim2.new(0, 9, 0, 6);
                AnchorPoint = Vector2.new(1, 0.5);
                Image = "rbxassetid://75133155165707";
                BackgroundTransparency = 1;
                Position = UDim2.new(1, -11, 0.5, 0);
                Rotation = 0;
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset.Other
            }):Themify("Other", "BackgroundColor3")
        end

        local Section = Items.Section.Instance

        Cfg.Collapse = function(bool)
            if Cfg.Tweening then
                return
            end

            Cfg.Collapsed = bool

            if bool then
                Items.Section:Tween({Size = UDim2.new(ScalingSize, OffsetSize, 0, 35)})
                Items.Filler1:Tween({BackgroundTransparency = 1})
                Items.Filler2:Tween({BackgroundTransparency = 1})
                Items.Image:Tween({Rotation = 180})

                Items.Elements:Tween({Position = UDim2.new(0, 12, 0, 23)})
                Items.Elements:TweenDescendants(false, Cfg)
            else
                Items.Section:Tween({Size = UDim2.new(ScalingSize, OffsetSize, 0, Cfg.CachedSize + 36)})
                Items.Filler1:Tween({BackgroundTransparency = 0})
                Items.Filler2:Tween({BackgroundTransparency = 0})
                Items.Image:Tween({Rotation = 0})

                Items.Elements:Tween({Position = UDim2.new(0, 12, 0, 43)})
                Items.Elements:TweenDescendants(true, Cfg)
            end
        end

        Items.Image:OnClick(function()
            if Cfg.Tweening then
                return
            end

            Cfg.Collapsed = not Cfg.Collapsed

            Cfg.Collapse(Cfg.Collapsed)
        end)

        Cfg.UpdateSection = function(Instance)
            task.spawn(function()
                if not Cfg.Collapsed then
                    Cfg.CachedSize += Instance.AbsoluteSize.Y + 13
                    Items.Section:Tween({Size = UDim2.new(ScalingSize, OffsetSize, 0, Cfg.CachedSize + 40)})
                end
            end)
        end

        return setmetatable(Cfg, Library)
    end

    Library.AddToggle = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Text = Data.Text or "Toggle";
            Flag = Data.Flag or Data.Name or Data.Text or "Toggle";
            Enabled = Data.Default or false;
            Callback = Data.Callback or function() end;

            Items = {};
        }

        local Items = Cfg.Items; do
            Items.Object = Library:Create( "TextButton", {
                Parent = self.Items.Elements.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 18);
                BorderSizePixel = 0
            })

            Items.AccentChange = Library:Create( "TextButton", {
                Parent = Library.Other.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 18);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset.Accent
            }):Themify("Accent", "BackgroundColor3")

            Items.Text = Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Themes.Preset["Unselected"];
                Text = Cfg.Text;
                Parent = Items.Object.Instance;
                AnchorPoint = Vector2.new(0, 0.5);
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, -1, 0.5, 0);
                BorderSizePixel = 0;
                ZIndex = 2
            }):Themify("Unselected", "TextColor3"):Themify("TextColor", "TextColor3")

            Items.Holder = Library:Create( "Frame", {
                Parent = Items.Object.Instance;
                Position = UDim2.new(1, 0, 0, 0);
                Size = UDim2.new(0, 0, 1, 0);
                BorderSizePixel = 0
            })

            Library:Create( "UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                Parent = Items.Holder.Instance;
                Padding = UDim.new(0, 7);
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Items.Toggle = Library:Create( "Frame", {
                AnchorPoint = Vector2.new(1, 0);
                Parent = Items.Holder.Instance;
                Position = UDim2.new(1, 0, 0, 0);
                Size = UDim2.new(0, 34, 0, 16);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset.Other
            }):Themify("Other", "BackgroundColor3"):Themify("Accent", "BackgroundColor3")

            Items.Stroke = Library:Create( "UIStroke", {
                Color = Themes.Preset["Inline"];
                Parent = Items.Toggle.Instance
            }):Themify("Inline", "Color"):Themify("Accent", "Color")

            Library:Create( "UICorner", {
                Parent = Items.Toggle.Instance;
                CornerRadius = UDim.new(1, 0)
            })

            Items.Gradient = Library:Create( "UIGradient", {
                Parent = Items.Toggle.Instance;
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0.59375),
                    NumberSequenceKeypoint.new(1, 0)
                };
                Enabled = false;
            })

            Items.Circle = Library:Create( "Frame", {
                AnchorPoint = Vector2.new(0, 0.5);
                Parent = Items.Toggle.Instance;
                Position = UDim2.new(0, 2, 0.5, 0);
                Size = UDim2.new(0, 12, 0, 12);
                BorderSizePixel = 0;
                BackgroundColor3 = Color3.fromRGB(56, 56, 56)
            })

            Library:Create( "UICorner", {
                Parent = Items.Circle.Instance;
                CornerRadius = UDim.new(1, 0)
            })
        end

        Cfg.Set = function(bool)
            Items.Gradient.Instance.Enabled = bool
            Cfg.Enabled = bool

            if bool then
                Items.Circle:Tween({AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Items.Stroke:Tween({Color = Themes.Preset.Accent})
                Items.Toggle:Tween({BackgroundColor3 = Themes.Preset.Accent})
                Items.Text:Tween({TextColor3 = Themes.Preset.TextColor})
            else
                Items.Toggle:Tween({BackgroundColor3 = Themes.Preset.Inline})
                Items.Circle:Tween({AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(56, 56, 56)})
                Items.Stroke:Tween({Color = Themes.Preset.Inline})
                Items.Text:Tween({TextColor3 = Themes.Preset.Unselected})
            end

            Flags[Cfg.Flag] = bool
            Cfg.Callback(bool)
        end

        Items.Object:OnClick(function()
            Cfg.Enabled = not Cfg.Enabled
            Cfg.Set(Cfg.Enabled)
        end)

        Items.AccentChange.Instance:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
            print("hi")
            if Cfg.Enabled then
                Items.Stroke:Tween({Color = Themes.Preset.Accent})
                Items.Toggle:Tween({BackgroundColor3 = Themes.Preset.Accent})
            end
        end)

        ConfigFlags[Cfg.Flag] = Cfg.Set
        Cfg.Set(Cfg.Enabled)

        self.UpdateSection(Items.Object.Instance)

        return setmetatable(Cfg, Library)
    end

    Library.AddSlider = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Text = Data.Text or "Text",
            Suffix = Data.Suffix or "",
            Flag = Data.Flag or Data.Name or "Slider",
            Callback = Data.Callback or function() end,

            Min = Data.Min or 0,
            Max = Data.Max or 100,
            Intervals = Data.Decimal or Data.Rounding or 1,
            Value = Data.Default or 10,

            Dragging = false,
            Items = {}
        }

        local Items = Cfg.Items; do
            Items.Object = Library:Create( "TextButton", {
                Parent = self.Items.Elements.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 33);
                BorderSizePixel = 0;
                AutomaticSize = Enum.AutomaticSize.Y;
            })

            Items.Title = Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Color3.fromRGB(252, 252, 252);
                Text = Cfg.Text;
                Parent = Items.Object.Instance;
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, -1, 0, 0);
                BorderSizePixel = 0;
                ZIndex = 2
            })

            Items.Value = Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Color3.fromRGB(252, 252, 252);
                Text = "50%";
                Parent = Items.Object.Instance;
                AnchorPoint = Vector2.new(1, 0);
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Position = UDim2.new(1, 0, 0, 0);
                BorderSizePixel = 0;
                ZIndex = 2
            })

            Items.Accent = Library:Create( "Frame", {
                Parent = Items.Object.Instance;
                Size = UDim2.new(0.5, -2, 0, 5);
                Position = UDim2.new(0, 1, 0, 27);
                ZIndex = 2;
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Accent"]
            }):Themify("Accent", "BackgroundColor3")

            Library:Create( "UIGradient", {
                Parent = Items.Accent.Instance;
                Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0.824999988079071),
                NumberSequenceKeypoint.new(1, 0)
            }
            })

            Library:Create( "UIStroke", {
                Color = Themes.Preset["Accent"];
                Parent = Items.Accent.Instance
            }):Themify("Accent", "Color")

            Library:Create( "UICorner", {
                Parent = Items.Accent.Instance;
                CornerRadius = UDim.new(1, 0)
            })

            Items.Circle = Library:Create( "Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5);
                Parent = Items.Accent.Instance;
                Position = UDim2.new(1, 0, 0.5, 0);
                Size = UDim2.new(0, 7, 0, 7);
                ZIndex = 2;
                BorderSizePixel = 0;
                BackgroundColor3 = Color3.fromRGB(246, 245, 254)
            })

            Library:Create( "UIStroke", {
                Color = Themes.Preset["TextColor"];
                Parent = Items.Circle.Instance
            }):Themify("TextColor", "Color")

            Library:Create( "UICorner", {
                Parent = Items.Circle.Instance;
                CornerRadius = UDim.new(1, 8)
            })

            Items.SliderDragger = Library:Create( "Frame", {
                Parent = Items.Object.Instance;
                Position = UDim2.new(0, 0, 0, 26);
                Size = UDim2.new(1, 1, 0, 7);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["ElementBackground"]
            }):Themify("ElementBackground", "BackgroundColor3")

            Library:Create( "UICorner", {
                Parent = Items.SliderDragger.Instance;
                CornerRadius = UDim.new(1, 0)
            })
        end

        Cfg.Set = function(Value)
            Cfg.Value = math.clamp(Library:Round(Value, Cfg.Intervals), Cfg.Min, Cfg.Max)

            Items.Value.Instance.Text = tostring(Cfg.Value) .. Cfg.Suffix
            Items.Accent:Tween({Size = UDim2.new((Cfg.Value - Cfg.Min) / (Cfg.Max - Cfg.Min), -2, 0, 5)}, TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0))

            Flags[Cfg.Flag] = Cfg.Value
            Cfg.Callback(Flags[Cfg.Flag])
        end

        Cfg.UpdateSlider = function(input)
            local Size = (input.Position.X - Items.SliderDragger.Instance.AbsolutePosition.X) / Items.SliderDragger.Instance.AbsoluteSize.X
            local Value = ((Cfg.Max - Cfg.Min) * Size) + Cfg.Min

            Cfg.Set(Value)
        end

        Cfg.Set(Cfg.Value);
        Items.SliderDragger:OnDrag(Cfg.UpdateSlider)
        self.UpdateSection(Items.Object.Instance)

        ConfigFlags[Cfg.Flag] = Cfg.Set
        return setmetatable(Cfg, Library)
    end

    Library.AddDropdown = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Text = Data.Text or Data.Title or Data.Name or nil;
            Flag = Data.Flag or Data.Text or Data.Title or Data.Name or "Dropdown";
            Options = Data.Options or Data.Values or {""};
            Callback = Data.Callback or function() end;
            Multi = Data.Multi or false;

            -- Ignore these
            Open = true;
            OptionInstances = {};
            MultiItems = {};
            Items = {};
            Tweening = false;
        } Cfg.Default = Data.Default or Cfg.Options[1] or "";

        local Items = Cfg.Items; do
            do -- Outline
                Items.Dropdown = Library:Create( "Frame", {
                    Parent = self.Items.Elements.Instance;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(1, 0, 0, 52);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BorderSizePixel = 0
                })

                Items.Text = Library:Create( "TextLabel", {
                    FontFace = Themes.Preset.Font;
                    TextColor3 = Color3.fromRGB(252, 252, 252);
                    Text = Cfg.Text;
                    Parent = Items.Dropdown.Instance;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, -1, 0, 0);
                    BorderSizePixel = 0;
                    ZIndex = 2
                })

                Items.Outline = Library:Create( "Frame", {
                    Parent = Items.Dropdown.Instance;
                    Position = UDim2.new(0, 1, 0, 26);
                    Size = UDim2.new(1, -1, 0, 24);
                    BorderSizePixel = 0;
                    BackgroundColor3 = Themes.Preset["ElementBackground"]
                }):Themify("ElementBackground", "BackgroundColor3")

                Library:Create( "UIStroke", {
                    Color = Themes.Preset.ElementOutline;
                    Parent = Items.Outline.Instance
                }):Themify("ElementOutline", "Color")

                Library:Create( "UICorner", {
                    Parent = Items.Outline.Instance;
                    CornerRadius = UDim.new(0, 5)
                })

                Items.Rectangles = Library:Create( "ImageLabel", {
                    ImageColor3 = Themes.Preset.Accent;
                    Parent = Items.Outline.Instance;
                    AnchorPoint = Vector2.new(1, 0.5);
                    Image = "rbxassetid://131251144676490";
                    BackgroundTransparency = 1;
                    Position = UDim2.new(1, -8, 0.5, 0);
                    Size = UDim2.new(0, 12, 0, 12);
                    BorderSizePixel = 0
                }):Themify("Accent", "ImageColor3")

                Items.Value = Library:Create( "TextLabel", {
                    FontFace = Themes.Preset.Font;
                    TextColor3 = Color3.fromRGB(252, 252, 252);
                    Text = "Dropdown";
                    Parent = Items.Outline.Instance;
                    AnchorPoint = Vector2.new(0, 0.5);
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 8, 0.5, -1);
                    BorderSizePixel = 0;
                    ZIndex = 2
                })
            end

            do -- Menu
                Items.DropdownHolder = Library:Create( "TextButton", {
                    Size = UDim2.new(0, 248, 0, 0);
                    Position = UDim2.new(0.05539358779788017, 0, 0.5614250898361206, 0);
                    BorderSizePixel = 0;
                    Visible = false;
                    Parent = Library.Other.Instance;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = Themes.Preset["ElementBackground"]
                }):Themify("ElementBackground", "BackgroundColor3")

                Library:Create( "UIStroke", {
                    Color = Themes.Preset.ElementOutline;
                    Parent = Items.DropdownHolder.Instance
                }):Themify("ElementOutline", "Color")

                Library:Create( "UICorner", {
                    Parent = Items.DropdownHolder.Instance;
                    CornerRadius = UDim.new(0, 5)
                })

                Library:Create( "UIPadding", {
                    PaddingTop = UDim.new(0, 2);
                    PaddingBottom = UDim.new(0, 1);
                    Parent = Items.DropdownHolder.Instance;
                    PaddingRight = UDim.new(0, 2);
                    PaddingLeft = UDim.new(0, 2)
                })

                Library:Create( "UIListLayout", {
                    Parent = Items.DropdownHolder.Instance;
                    Padding = UDim.new(0, 5);
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end
        end

        Cfg.RenderOption = function(text)
            local DropdownItems = {}

            DropdownItems.Button = Library:Create( "Frame", {
                Parent = Items.DropdownHolder.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 0);
                BorderSizePixel = 0;
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundColor3 = Themes.Preset["Accent"]
            }):Themify("Accent", "BackgroundColor3")

            Library:Create( "UIGradient", {
                Parent = DropdownItems.Button.Instance;
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0.59375),
                    NumberSequenceKeypoint.new(1, 0)
                }
            })

            Library:Create( "UICorner", {
                Parent = DropdownItems.Button.Instance;
                CornerRadius = UDim.new(0, 5)
            })

            DropdownItems.Text = Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                Parent = DropdownItems.Button.Instance;
                TextColor3 = Themes.Preset["Unselected"];
                Text = text;
                AutomaticSize = Enum.AutomaticSize.XY;
                AnchorPoint = Vector2.new(0, 0.5);
                Size = UDim2.new(0, 0, 1, 0);
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 8, 0.5, -1);
                BorderSizePixel = 0;
                ZIndex = 2;
            }):Themify("Unselected", "TextColor3"):Themify("TextColor", "TextColor3")

            Library:Create( "UIPadding", {
                PaddingBottom = UDim.new(0, 10);
                PaddingTop = UDim.new(0, 10);
                Parent = DropdownItems.Button.Instance
            })

            DropdownItems.Stroke = Library:Create( "UIStroke", {
                Color = Themes.Preset["Accent"];
                Transparency = 1;
                Parent = DropdownItems.Button.Instance
            }):Themify("Accent", "Color")

            table.insert(Cfg.OptionInstances, DropdownItems)

            return DropdownItems
        end

        Cfg.SetVisible = function()
            if Cfg.Tweening then
                return
            end

            Cfg.Open = not Cfg.Open

            local Size = Items.Outline.Instance.AbsoluteSize
            local Position = Items.Outline.Instance.AbsolutePosition

            Items.DropdownHolder.Instance.Size = UDim2.fromOffset(Size.X + 2, 0)

            if Cfg.Open then
                Items.DropdownHolder.Instance.Position = UDim2.fromOffset(Position.X, Position.Y + 75)
                Items.DropdownHolder:Tween({Position = UDim2.fromOffset(Position.X, Position.Y + 85)})
            else
                Items.DropdownHolder:Tween({Position = UDim2.fromOffset(Position.X, Position.Y + 75)})
            end

            Items.DropdownHolder:TweenDescendants(Cfg.Open, Cfg)
        end

        Cfg.Set = function(Value)
            local Selected = {}
            local IsTable = type(Value) == "table"

            for _,Option in Cfg.OptionInstances do
                local Text = Option.Text.Instance.Text

                if Text == Value or (IsTable and table.find(Value, Text)) then
                    table.insert(Selected, Text)
                    Cfg.MultiItems = Selected

                    Option.Text:Tween({TextColor3 = Themes.Preset.TextColor})
                    Option.Button:Tween({BackgroundTransparency = 0})
                    Option.Stroke:Tween({Transparency = 0})
                else
                    Option.Text:Tween({TextColor3 = Themes.Preset.Unselected})
                    Option.Button:Tween({BackgroundTransparency = 1})
                    Option.Stroke:Tween({Transparency = 1})
                end
            end

            Items.Value.Instance.Text = IsTable and table.concat(Selected, ", ") or Selected[1] or ""

            Flags[Cfg.Flag] = IsTable and Selected or Selected[1]
            Cfg.Callback(Flags[Cfg.Flag])
        end

        Cfg.RefreshOptions = function(Options)
            for _,option in Cfg.OptionInstances do
                option.Button.Instance:Destroy()
            end

            Cfg.OptionInstances = {}

            for _,Option in Options do
                local Button = Cfg.RenderOption(Option)
                local Text = Button.Text.Instance.Text

                Button.Button:OnClick(function()
                    if Cfg.Multi then
                        local Selected = table.find(Cfg.MultiItems, Text)

                        if Selected then
                            table.remove(Cfg.MultiItems, Selected)
                        else
                            table.insert(Cfg.MultiItems, Text)
                        end

                        Cfg.Set(Cfg.MultiItems)
                    else
                        Cfg.Set(Text)
                    end
                end)
            end
        end

        Items.Outline:OnClick(Cfg.SetVisible)
        Items.DropdownHolder:Reparent(Library.Elements.Instance)
        Items.DropdownHolder:OutsideClick(Cfg)

        Cfg.RefreshOptions(Cfg.Options)
        Cfg.SetVisible()
        Cfg.Set(Cfg.Default)

        self.UpdateSection(Items.Dropdown.Instance)

        return setmetatable(Cfg, Library)
    end

    Library.AddKeyPicker = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Text = Data.Text or Data.Name or Data.Title or "Keybind";
            Flag = Data.Flag or Data.Text or Data.Name or Data.Title or "Flag";
            Callback = Data.Callback or function() end;
            ShowInList = Data.ShowInList or true;

            Key = Data.Key or Data.Default or nil;
            Mode = Data.Mode or "Toggle";
            Active = Data.Active or false;

            Open = false;
            Tweening = false;
            Binding;

            Items = {};
            Debounce = false;
        }

        Flags[Cfg.Flag] = {
            Mode = Cfg.Mode,
            Key = Cfg.Key,
            Active = Cfg.Active,
            active = Cfg.Active;
        }

        local Items = Cfg.Items; do
            Items.Object = Library:Create( "Frame", {
                Parent = self.Items.Elements.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 16);
                BorderSizePixel = 0
            })

            Items.Title = Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Color3.fromRGB(252, 252, 252);
                Text = Cfg.Text;
                Parent = Items.Object.Instance;
                AnchorPoint = Vector2.new(0, 0.5);
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, -1, 0.5, 0);
                BorderSizePixel = 0;
                ZIndex = 2
            })

            Items.Holder = Library:Create( "Frame", {
                Parent = Items.Object.Instance;
                Position = UDim2.new(1, 0, 0, 0);
                Size = UDim2.new(0, 0, 1, 0);
                BorderSizePixel = 0
            })

            Library:Create( "UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                Parent = Items.Holder.Instance;
                Padding = UDim.new(0, 13);
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Items.Holder2 = Library:Create( "Frame", {
                AnchorPoint = Vector2.new(1, 0);
                Parent = Items.Holder.Instance;
                Position = UDim2.new(1, 0, 0, 0);
                Size = UDim2.new(0, 34, 0, 16);
                BorderSizePixel = 0;
                AutomaticSize = Enum.AutomaticSize.X;
                BackgroundColor3 = Themes.Preset.Other
            }):Themify("Other", "BackgroundColor3")

            Library:Create( "UIStroke", {
                Color = Themes.Preset["Inline"];
                Parent = Items.Holder2.Instance
            }):Themify("Inline", "Color")

            Library:Create( "UIPadding", {
                Parent = Items.Holder2.Instance;
                PaddingRight = UDim.new(0, 8);
                PaddingLeft = UDim.new(0, 8)
            })

            Library:Create( "UICorner", {
                Parent = Items.Holder2.Instance;
                CornerRadius = UDim.new(0, 5)
            })

            Items.Value = Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Color3.fromRGB(252, 252, 252);
                Text = "RightShift";
                Parent = Items.Holder2.Instance;
                AnchorPoint = Vector2.new(0, 0.5);
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, -1, 0.5, 0);
                BorderSizePixel = 0;
                ZIndex = 2
            })

            do -- Keybind holder
                local Section = Library:AddSection({Text = "Settings"})
                Items.Dropdown = Section:AddDropdown({Text = "Mode", Flag = Cfg.Flag.."_MODE", Options = {"Toggle", "Hold", "Always"}, Callback = function(Option)
                    if Cfg.Debounce then
                        return
                    end

                    if Cfg.Set then
                        Cfg.Set(Option)
                    end
                end})

                Items.Section = Section.Items.Section
                Items.Section.Instance.Parent = Library.Items.Instance
                Items.Section.Instance.Visible = false

                Items.Section:Reparent(Library.Elements.Instance)
            end
        end

        local KeybindListElement = Library:AddHotKey({Key = Cfg.Key or "NONE", Name = Cfg.Text})

        Cfg.SetMode = function(Mode)
            Cfg.Mode = Mode

            if Mode == "Always" then
                Cfg.Set(true)
            elseif Mode == "Hold" then
                Cfg.Set(false)
            end

            Flags[Cfg.Flag].Mode = Mode
        end

        Cfg.Set = function(input)
            if type(input) == "boolean" then
                Cfg.Active = input

                if Cfg.Mode == "Always" then
                    Cfg.Active = true
                end
            elseif tostring(input):find("Enum") then
                input = input.Name == "Escape" and "NONE" or input

                Cfg.Key = input or "NONE"
            elseif table.find({"Toggle", "Hold", "Always"}, input) then
                if input == "Always" then
                    Cfg.Active = true
                end

                Cfg.Mode = input
                Cfg.SetMode(Cfg.Mode)
            elseif type(input) == "table" then
                input.Key = type(input.Key) == "string" and input.Key ~= "NONE" and Library:ConvertEnum(input.Key) or input.Key
                input.Key = input.Key == Enum.KeyCode.Escape and "NONE" or input.Key

                Cfg.Key = input.Key or "NONE"

                if input.Active then
                    Cfg.Active = input.Active
                end

                Cfg.SetMode(input.Mode)
            end

            Cfg.Callback(Cfg.Active)

            local text = (tostring(Cfg.Key) ~= "Enums" and (Keys[Cfg.Key] or tostring(Cfg.Key):gsub("Enum.", "")) or nil)
            local __text = text and tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", "") or ""

            Items.Value.Instance.Text = string.format("Key: %s", __text)

            Cfg.Debounce = true
            Items.Dropdown.Set(Cfg.Mode)
            Cfg.Debounce = false


            KeybindListElement:ChangeKey(__text or "NONE")
            KeybindListElement:SetEnabled(Cfg.Active)

            Flags[Cfg.Flag] = {
                Mode = Cfg.Mode,
                Key = Cfg.Key,
                Active = Cfg.Active;
                active = Cfg.Active;
            }
        end

        Cfg.NewKey = function()
            task.wait()
            Items.Value.Instance.Text = "..."

            Cfg.Binding = Library:Connect(Services.UserInputService.InputBegan, function(keycode, game_event)
                if game_event then
                    return
                end

                Cfg.Set(keycode.KeyCode ~= Enum.KeyCode.Unknown and keycode.KeyCode or keycode.UserInputType)

                Cfg.Binding.Connection:Disconnect()
                Cfg.Binding = nil
            end)
        end

        Cfg.SetVisible = function(bool)
            if Cfg.Tweening then
                return
            end

            task.wait()

            local Size = Items.Section.Instance.AbsoluteSize
            local Position = Items.Holder2.Instance.AbsolutePosition

            Items.Section:TweenDescendants(bool, Cfg)
            Items.Section:Tween({Position = UDim2.fromOffset(Position.X + 1, Position.Y + 80)})
        end

        Items.Holder2:OnClick(Cfg.NewKey)

        Items.Dropdown.Items.DropdownHolder:OnClick(function()
            task.spawn(function()
                Cfg.Tweening = true
                task.wait()
                Cfg.Tweening = false
            end)
        end)

        Items.Section:OutsideClick(Cfg)

        Library:Connect(Items.Holder2.Instance.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Cfg.Open = not Cfg.Open
                Cfg.SetVisible(Cfg.Open)
            end
        end)

        Library:Connect(Services.UserInputService.InputBegan, function(input, game_event)
            if game_event then
                return
            end

            local SelectedKey = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType

            if SelectedKey == Cfg.Key or tostring(SelectedKey) == Cfg.Key then
                if Cfg.Mode == "Toggle" then
                    Cfg.Active = not Cfg.Active
                    Cfg.Set(Cfg.Active)
                elseif Cfg.Mode == "Hold" then
                    Cfg.Set(true)
                end
            end
        end)

        Library:Connect(Services.UserInputService.InputEnded, function(input, game_event)
            if game_event then
                return
            end

            local SelectedKey = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType

            if SelectedKey == Cfg.Key or tostring(SelectedKey) == Cfg.Key then
                if Cfg.Mode == "Hold" then
                    Cfg.Set(false)
                end
            end
        end)

        Cfg.Set({Mode = Cfg.Mode, Active = Cfg.Active, Key = Cfg.Key})
        ConfigFlags[Cfg.Flag] = Cfg.Set

        self.UpdateSection(Items.Object.Instance)

        return setmetatable(Cfg, Library)
    end

    Library.AddColorPicker = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Text = Data.Text or Data.Name or "Color",
            Flag = Data.Flag or Data.Name or self.Name or "Colorpicker",
            Callback = Data.Callback or function() end,

            Color = Data.Color or Data.Default or Color3.new(1, 1, 1),  -- Default to white color if not provided
            Alpha = Data.Alpha or Data.Transparency or 1,

            -- Other
            Open = false;
            Items = {};
        }

        local Picker = self:Keypicker(Cfg)

        local Items = Picker.Items; do
            Cfg.Items = Items
            Cfg.Set = Picker.Set
        end;

        Cfg.Set(Cfg.Color, Cfg.Alpha)
        ConfigFlags[Cfg.Flag] = Cfg.Set

        return setmetatable(Cfg, Library)
    end

    Library.AddButton = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Text = Data.Text or "Button";
            Callback = Data.Callback or function() end;

            Items = {}
        }

        local Items = Cfg.Items; do
            Items.ButtonHolder = self.Items and self.Items.ButtonHolder

            if not Items.ButtonHolder then
                Items.ButtonHolder = Library:Create( "Frame", {
                    Parent = self.Items.Elements.Instance;
                    BackgroundTransparency = 1;
                    Size = UDim2.new(1, 0, 0, 24);
                    BorderSizePixel = 0
                })

                Library:Create( "UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalFlex = Enum.UIFlexAlignment.Fill;
                    Parent = Items.ButtonHolder.Instance;
                    Padding = UDim.new(0, 13);
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            end

            Items.Outline = Library:Create( "TextButton", {
                Parent = Items.ButtonHolder.Instance;
                Position = UDim2.new(0, 1, 0, 0);
                Size = UDim2.new(1, -1, 0, 24);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["ElementBackground"]
            }):Themify("ElementBackground", "BackgroundColor3")

            Library:Create( "UIStroke", {
                Color = Themes.Preset.ElementOutline;
                Parent = Items.Outline.Instance
            }):Themify("ElementOutline", "Color")

            Library:Create( "UICorner", {
                Parent = Items.Outline.Instance;
                CornerRadius = UDim.new(0, 5)
            })

            Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Color3.fromRGB(252, 252, 252);
                Text = Cfg.Text;
                Parent = Items.Outline.Instance;
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                BorderSizePixel = 0;
                Position = UDim2.new(0, 0, 0, -1);
                ZIndex = 2;
                BackgroundColor3 = Themes.Preset["Accent"]
            }):Themify("Accent", "BackgroundColor3")

            Items.Accent = Library:Create( "Frame", {
                Parent = Items.Outline.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Accent"]
            }):Themify("Accent", "BackgroundColor3")

            Items.Stroke = Library:Create( "UIStroke", {
                Color = Themes.Preset["Accent"];
                Transparency = 1;
                Parent = Items.Accent.Instance
            }):Themify("Accent", "Color")

            Library:Create( "UIGradient", {
                Parent = Items.Accent.Instance;
                Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0.59375),
                NumberSequenceKeypoint.new(1, 0)
            }
            })

            Library:Create( "UICorner", {
                Parent = Items.Accent.Instance;
                CornerRadius = UDim.new(0, 5)
            })
        end

        Cfg.Press = function()
            Items.Accent.Instance.BackgroundTransparency = 0
            Items.Accent:Tween({BackgroundTransparency = 1})

            Items.Stroke.Instance.Transparency = 0
            Items.Stroke:Tween({Transparency = 1})

            Cfg.Callback()
        end

        Items.Outline:OnClick(Cfg.Press)

        if self.UpdateSection then
            self.UpdateSection(Items.ButtonHolder.Instance)
        end

        return setmetatable(Cfg, Library)
    end

    Library.AddLabel = function(self, Data)
        local Cfg = {
            Text = Data.Text or Data.Title or Data.Name or "Label";
            Items = {};
        }

        local Items = Cfg.Items; do
            Items.Object = Library:Create( "TextButton", {
                Parent = self.Items.Elements.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 18);
                BorderSizePixel = 0
            })

            Items.Text = Library:Create( "TextLabel", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Themes.Preset["TextColor"];
                Text = Cfg.Text;
                Parent = Items.Object.Instance;
                AnchorPoint = Vector2.new(0, 0.5);
                AutomaticSize = Enum.AutomaticSize.XY;
                BackgroundTransparency = 1;
                Position = UDim2.new(0, -1, 0.5, 0);
                BorderSizePixel = 0;
                ZIndex = 2
            }):Themify("TextColor", "TextColor3")

            Cfg.ChangeText = function(Text)
                Items.Text.Instance.Text = Text
            end
        end

        self.UpdateSection(Items.Object.Instance)

        return setmetatable(Cfg, Library)
    end

    Library.AddList = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Flag = Data.Flag or Data.Name or "";
            Options = Data.Options or {"CONTACT FOR BUG"};
            Callback = Data.Callback or function() end;
            Multi = Data.Multi or false;

            Size = Data.Size or 100;

            Items = {};
            OptionInstances = {};
            MultiItems = {};
        }

        local Items = Cfg.Items; do
            Items.List = Library:Create( "Frame", {
                Parent = self.Items.Elements.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, Cfg.Size);
                BorderSizePixel = 0;
            });

            Items.Outline = Library:Create( "Frame", {
                Parent = Items.List.Instance;
                Size = UDim2.new(1, 0, 1, 0);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["Inlines"]
            }):Themify("Inlines", "BackgroundColor3")

            Library:Create( "UICorner", {
                Parent = Items.Outline.Instance;
                CornerRadius = UDim.new(0, 5)
            })

            Items.Inline = Library:Create( "Frame", {
                Parent = Items.Outline.Instance;
                Position = UDim2.new(0, 1, 0, 1);
                Size = UDim2.new(1, -2, 1, -2);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset.ElementBackground
            }):Themify("ElementBackground", "BackgroundColor3")

            Items.ScrollingFrame = Library:Create( "ScrollingFrame", {
                Active = true;
                AutomaticCanvasSize = Enum.AutomaticSize.Y;
                BorderSizePixel = 0;
                CanvasSize = UDim2.new(0, 0, 0, 0);
                ScrollingEnabled = true;
                ScrollBarImageColor3 = Color3.fromRGB(207, 155, 166);
                MidImage = "rbxassetid://102257413888451";
                ScrollBarThickness = 2;
                Parent = Items.Inline.Instance;
                Size = UDim2.new(1, -5, 1, -10);
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 5);
                BottomImage = "rbxassetid://102257413888451";
                TopImage = "rbxassetid://102257413888451"
            })

            Library:Create( "UIPadding", {
                PaddingBottom = UDim.new(0, -4);
                PaddingTop = UDim.new(0, -4);
                Parent = Items.ScrollingFrame.Instance;
            })

            Library:Create( "UIListLayout", {
                Parent = Items.ScrollingFrame.Instance;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Padding = UDim.new(0, -7);
            })

            Library:Create( "UICorner", {
                Parent = Items.ScrollingFrame.Instance;
                CornerRadius = UDim.new(0, 3)
            })

            Library:Create( "UICorner", {
                Parent = Items.Inline.Instance;
                CornerRadius = UDim.new(0, 3)
            })
        end

        Cfg.Set = function(value)
            local Selected = {}
            local IsTable = type(value) == "table"

            for _,option in Cfg.OptionInstances do
                if option.Instance.Text == value or (IsTable and table.find(value, option.Instance.Text)) then
                    table.insert(Selected, option.Instance.Text)
                    Cfg.MultiItems = Selected
                    option:Tween({TextColor3 = Themes.Preset.Accent})
                    option.Instance.FontFace = Fonts.Bold
                    option.Instance.TextSize = 13
                else
                    option:Tween({TextColor3 = Themes.Preset.UnselectedElement})
                    option.Instance.FontFace = Fonts.Elements
                    option.Instance.TextSize = 13
                end
            end

            Flags[Cfg.Flag] = if IsTable then Selected else Selected[1]

            Cfg.Callback(Flags[Cfg.Flag])
        end

        Cfg.RenderOption = function(name)
            local Button = Library:Create( "TextButton", {
                FontFace = Themes.Preset.Font;
                TextColor3 = Themes.Preset["Element Text"];
                Text = name;
                Parent = Items.ScrollingFrame.Instance;
                Size = UDim2.new(1, 0, 0, 0);
                Position = UDim2.new(0, 0, 0, -1);
                BackgroundTransparency = 1;
                TextXAlignment = Enum.TextXAlignment.Left;
                BorderSizePixel = 0;
                AutomaticSize = Enum.AutomaticSize.XY
            }):Themify("Accent", "TextColor3"):Themify("Element Text", "TextColor3")
            Button.Instance.Text = name

            Library:Create( "UIPadding", {
                PaddingBottom = UDim.new(0, 6);
                PaddingTop = UDim.new(0, 6);
                PaddingLeft = UDim.new(0, 6);
                Parent = Button.Instance
            })

            Button:OnHover(
                function()
                    if Flags[Cfg.Flag] == Button.Instance.Text or (type(Flags[Cfg.Flag]) == "table" and table.find(Flags[Cfg.Flag], Button.Instance.Text)) then
                        return
                    end

                    Button:Tween({TextColor3 = Themes.Preset.SelectedMultiTabText})
                end,
                function()
                    if Flags[Cfg.Flag] == Button.Instance.Text or (type(Flags[Cfg.Flag]) == "table" and table.find(Flags[Cfg.Flag], Button.Instance.Text)) then
                        return
                    end

                    Button:Tween({TextColor3 = Themes.Preset.UnselectedElement})
                end
            )

            table.insert(Cfg.OptionInstances, Button)

            return Button
        end

        Cfg.RefreshOptions = function(options)
            for _,option in Cfg.OptionInstances do
                option.Instance:Destroy()
            end

            Cfg.OptionInstances = {}

            for _,option in options do
                local Button = Cfg.RenderOption(option)

                Button:OnClick(function()
                    if Cfg.Multi then
                        local Selected = table.find(Cfg.MultiItems, Button.Instance.Text)

                        if Selected then
                            table.remove(Cfg.MultiItems, Selected)
                        else
                            table.insert(Cfg.MultiItems, Button.Instance.Text)
                        end

                        Cfg.Set(Cfg.MultiItems)
                    else
                        Cfg.Set(Button.Instance.Text)
                    end
                end)
            end
        end

        Flags[Cfg.Flag] = {}
        ConfigFlags[Cfg.Flag] = Cfg.Set
        Cfg.RefreshOptions(Cfg.Options)
        Cfg.Set(Cfg.Default)

        return setmetatable(Cfg, Library)
    end

    Library.AddInput = function(self, Data)
        Data = Data or {}

        local Cfg = {
            Text = Data.Text or Data.Title or Data.Name or nil;
            PlaceHolder = Data.PlaceHolder or Data.PlaceHolderText or Data.Holder or Data.HolderText or "Input here...";
            Default = Data.Default or "";
            Flag = Data.Flag or Data.Name or "TextBox";
            Callback = Data.Callback or function() end;

            Items = {};
            Focused = false;
        }

        Flags[Cfg.Flag] = Cfg.Default

        local Items = Cfg.Items; do
            Items.Object = Library:Create( "Frame", {
                Parent = self.Items.Elements.Instance;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, Cfg.Text and 50 or 26);
                BorderSizePixel = 0
            })

            if Cfg.Text then
                Library:Create( "TextLabel", {
                    FontFace = Themes.Preset.Font;
                    TextColor3 = Color3.fromRGB(252, 252, 252);
                    Text = Cfg.Text;
                    Parent = Items.Object.Instance;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, -1, 0, 0);
                    BorderSizePixel = 0;
                    ZIndex = 2
                })
            end

            Items.Outline = Library:Create( "Frame", {
                Parent = Items.Object.Instance;
                Position = UDim2.new(0, 1, 0, Cfg.Text and 26 or 0);
                Size = UDim2.new(1, -1, 0, 24);
                BorderSizePixel = 0;
                BackgroundColor3 = Themes.Preset["ElementBackground"]
            }):Themify("ElementBackground", "BackgroundColor3")

            Library:Create( "UIStroke", {
                Color = Themes.Preset.ElementOutline;
                Parent = Items.Outline.Instance
            }):Themify("ElementOutline", "Color")

            Library:Create( "UICorner", {
                Parent = Items.Outline.Instance;
                CornerRadius = UDim.new(0, 5)
            })

            Items.Textbox = Library:Create( "TextBox", {
                Parent = Items.Outline.Instance;
                FontFace = Themes.Preset.Font;
                Active = false;
                ClearTextOnFocus = false;
                Text = Cfg.Default;
                TextColor3 = Color3.fromRGB(252, 252, 252);
                Size = UDim2.new(1, 0, 1, 0);
                Selectable = false;
                BorderSizePixel = 0;
                PlaceholderText = Cfg.PlaceHolder;
                BackgroundTransparency = 1;
                TextXAlignment = Enum.TextXAlignment.Left;
                AutomaticSize = Enum.AutomaticSize.XY;
                ZIndex = 2
            })

            Library:Create( "UIPadding", {
                PaddingLeft = UDim.new(0, 8);
                Parent = Items.Textbox.Instance
            })
        end

        Cfg.Set = function(Text)
            Flags[Cfg.Flag] = Text

            Items.Textbox.Instance.Text = Text

            Cfg.Callback(Text)
        end

        Items.Textbox.Instance.Focused:Connect(function()
            Cfg.Focused = true;
        end)

        Items.Textbox.Instance.FocusLost:Connect(function()
            Cfg.Focused = false;

            Cfg.Set(Items.Textbox.Instance.Text)
        end)

        ConfigFlags[Cfg.Flag] = Cfg.Set

        if self.UpdateSection then
            self.UpdateSection(Items.Object.Instance)
        end

        return setmetatable(Cfg, Library)
    end

    Library.InitConfigs = function(self, Window)
        local Tab = Window:AddTab({
            Title = "Settings",
            Icon = "rbxassetid://117366234081415",
            Pages = {"Configs"},
        })

        local Section = Tab:AddSection({
            Side = "Left",
            Title = "Configs"
        })

        local ConfigText;
        local ConfigHolder = Section:AddDropdown({Text = "Configs", Flag = "ConfigList", Callback = function(option)
            if Text and Text.Set and option then
                Text.Set(option)
            end
        end})

        Text = Section:AddInput({Text = "Config Name", Default = "", PlaceHolder = "Config Name:", Flag = "config_Name_text", PlaceHolder = "Type config name here...", Callback = function(text)
            ConfigText = text
        end})

        Section:AddButton({Text = "Save", Callback = function()
            if not ConfigText then
                return
            end

            Library:SaveConfig(ConfigText)
            ConfigHolder:UpdateConfigList()
        end}):AddButton({Text = "Load", Callback = function()
            Window.Tweening = true
            if not ConfigText then
                return
            end

            for i = 1, 2 do
                Library:LoadConfig(readfile(Library.Directory .. "/Configs/" .. ConfigText .. ".cfg"))
            end

            ConfigHolder:UpdateConfigList()

            Window.Tweening = false
        end})

        Section:AddButton({Text = "Delete", Callback = function()
            if not ConfigText then
                return
            end

            Library:DeleteConfig(ConfigText)
            ConfigHolder:UpdateConfigList()
        end}):AddButton({Text = "Refresh", Callback = function()
            ConfigHolder:UpdateConfigList()
        end})

        Section:AddButton({Text = "Set As Auto Load", Callback = function()
            writefile(Library.Directory.."/Autoload.txt", ConfigText)
            Label.ChangeText("Current Config: " .. readfile(Library.Directory.."/Autoload.txt"))
        end})
        Label = Section:AddLabel({Text = "Current Config: ".. readfile(Library.Directory.."/Autoload.txt")})
        Section:AddButton({Text = "Remove Auto Load", Callback = function()
            writefile(Library.Directory.."/Autoload.txt", "")
            Label.ChangeTet("Current Config: "..readfile(Library.Directory.."/Autoload.txt"))
        end})

        local Section = Tab:AddSection({
            Side = "Right",
            Title = "Theming"
        })

        Section:AddColorPicker({Text = "Accent", Default = Themes.Preset.Accent, Transparency = 0, Flag = Name, Callback = function(Value, Alpha)
            Library:Refresh("Accent", Value)
        end})

        local Section = Tab:AddSection({
            Side = "Right",
            Title = "Other"
        })

        Section:AddKeyPicker({Text = "Menu bind", Mode = "Toggle", ShowInList = false, Callback = function(Value)
            Window.SetVisible(Value)
        end})
        Section:AddToggle({Text = "Watermark", Callback = function(Bool)
            self.Window.Items.Watermark.Instance.Visible = Bool
        end})
        Section:AddToggle({Text = "Mod List", Callback = function(Bool)
            self.Window.Items.ModList.Instance.Visible = Bool
        end})
        Section:AddToggle({Text = "Keybind List", Callback = function(Bool)
            self.Window.Items.KeybindList.Instance.Visible = Bool
        end})

        ConfigHolder:UpdateConfigList();
    end

    do -- Keybind lib
        local YOffset = 0
        local BiggestX = 0

        Library.AddHotKey = function(self, Data)
            Data = Data or {}

            local Cfg = {
                Text = Data.Title or Data.Name or Data.Text or "Title";
                Lifetime = Data.Lifetime or 5;

                Items = {};
                Status = true;
                Fade = 2;
                Tick = tick();
                Index = #self.Keybinds + 1
            }

            local Items = Cfg.Items; do
                Items.Keybind = Library:Create("CanvasGroup",{Parent = self.Window.Items.KeybindHolder.Instance; BackgroundTransparency = 1; Size = UDim2.new(1, 0, 0, 25); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Items.Name = Library:Create("TextLabel",{LayoutOrder = 1; TextColor3 = Color3.fromRGB(245, 245, 245); Text = "Idfk"; Parent = Items.Keybind.Instance; AutomaticSize = Enum.AutomaticSize.XY; BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Left; BorderSizePixel = 0; ZIndex = 2; BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 4); PaddingBottom = UDim.new(0, 6); Parent = Items.Name.Instance; PaddingRight = UDim.new(0, 5); PaddingLeft = UDim.new(0, 7)})
                Items.Key = Library:Create("TextLabel",{LayoutOrder = 1; Parent = Items.Keybind.Instance; TextColor3 = Color3.fromRGB(170, 170, 170); Text = "[X]"; AutomaticSize = Enum.AutomaticSize.XY; AnchorPoint = Vector2.new(1, 0); Position = UDim2.new(1, 0, 0, 0); BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Right; BorderSizePixel = 0; ZIndex = 2; BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 4); PaddingBottom = UDim.new(0, 6); Parent = Items.Key.Instance; PaddingRight = UDim.new(0, 5); PaddingLeft = UDim.new(0, 7)})
            end

            function Cfg:ChangeKey(Key)
                if not Key then
                    return
                end

                Items.Key.Instance.Text = tostring("["..Key.."]")
            end

            function Cfg:ChangeName(Name)
                Items.Name.Instance.Text = tostring(Name)
            end

            function Cfg:SetEnabled(Bool)
                Cfg.Status = Bool
            end

            Cfg:ChangeKey(Cfg.Key)
            Cfg:ChangeName(Cfg.Text)

            self.Keybinds[Cfg.Index] = Cfg

            return setmetatable(Cfg, Library)
        end

        Library.LerpKeybinds = function(self)
            YOffset = 0
            BiggestX = 0

            local Tick = tick()
            for _,Object in self.Keybinds do
                Object.Fade = Library:Lerp(Object.Fade, Object.Status and 255 or 0, 0.02)
                local Instance = Object.Items.Keybind.Instance

                local Offset = UDim2.new(0, 0, 0, 0) -- great pasting skills
                local Transparency = 1 - (1 * (Object.Fade / 255))

                Instance.Position = Offset + UDim2.new(0, -(Instance.AbsoluteSize.X - (Instance.AbsoluteSize.X * (Object.Fade / 255))), 0, YOffset)
                Object:SetKeypickerTransparency(Transparency)

                if Object.Status and BiggestX < Instance.AbsoluteSize.X then
                    BiggestX = math.max(BiggestX, Instance.AbsoluteSize.X)
                end

                YOffset += (Instance.AbsoluteSize.Y) * (Object.Fade / 255)
                self.Window.Items.KeybindHolder.Instance.Size = UDim2.new(0, 200, 0, YOffset + 22)
            end
        end

        Library.SetKeypickerTransparency = function(self, Num)
            self.Items.Keybind.Instance.GroupTransparency = Num
        end
    end

    do -- Notification Library
        Library.HUD = Library:Create( "ScreenGui" , {
            Parent = Services.CoreGui;
            Name = "\0";
            Enabled = true;
            IgnoreGuiInset = true;
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
            DisplayOrder = 1000001;
        });

        local YOffset = 0
        local BiggestX = 0

        Library.Notify = function(self, Data)
            Data = Data or {}

            local Cfg = setmetatable({
                Text = Data.Title or Data.Name or Data.Text or "Title";
                Lifetime = Data.Lifetime or 5;

                Items = {};
                Status = true;
                Fade = 2;
                Tick = tick();
                Index = #self.Notifications + 1
            }, Library);

            local Items = Cfg.Items; do
                Items.Notification = Library:Create("CanvasGroup",{GroupTransparency = 1; Parent = Library.HUD.Instance; Position = UDim2.new(0, 30, 0, 60); BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.XY; BackgroundColor3 = Color3.fromRGB(12, 12, 14)})
                Items.Accent = Library:Create("Frame",{Parent = Items.Notification.Instance; Position = UDim2.new(0, -3, 1, -1); Size = UDim2.new(0, 0, 0, 4); BorderSizePixel = 0; BackgroundColor3 = Themes.Preset.Accent}):Themify("Accent", "BackgroundColor3")
                Items.Icon = Library:Create("ImageLabel",{ImageColor3 = Themes.Preset.Accent; Parent = Items.Notification.Instance; AnchorPoint = Vector2.new(0, 0.5); Image = Cfg.Icon; Image = "rbxassetid://82851477751652"; BackgroundTransparency = 1; Position = UDim2.new(0, 5, 0.5, -2); Size = UDim2.new(0, 16, 0, 16); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Themify("Accent", "ImageColor3")
                Items.Title = Library:Create("TextLabel",{LayoutOrder = 1; TextColor3 = Color3.fromRGB(245, 245, 245); Text = Cfg.Text; Parent = Items.Notification.Instance; BackgroundTransparency = 1; BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.XY; BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 4); PaddingBottom = UDim.new(0, 8); Parent = Items.Title.Instance; PaddingRight = UDim.new(0, 5); PaddingLeft = UDim.new(0, 24)})
                Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 2); PaddingBottom = UDim.new(0, 2); Parent = Items.Notification.Instance; PaddingRight = UDim.new(0, 2); PaddingLeft = UDim.new(0, 2)})
                Items.UICorner = Library:Create("UICorner",{Parent = Items.Notification.Instance})
            end

            self.Notifications.Notifs[Cfg.Index] = Cfg
            Items.Accent:Tween({Size = UDim2.new(1, 4, 0, 4)}, TweenInfo.new(Cfg.Lifetime, Library.EasingStyle, Library.EasingDirection, 0, false, 0))

            task.delay(Cfg.Lifetime + 1, function()
                Items.Notification.Instance:Destroy()
                self.Notifications.Notifs[Cfg.Index] = nil
            end)

            return setmetatable(Cfg, Library)
        end

        Library.LerpObjects = function(self)
            YOffset = 0
            BiggestX = 0

            local Tick = tick()
            for _,Object in self.Notifications.Notifs do
                if not Object.Fade then
                    Object.Fade = 2;
                end;
                Object.Fade = Library:Lerp(Object.Fade, Object.Status and 255 or 0, 0.02)

                if Tick - Object.Tick >= Object.Lifetime then
                    Object.Status = false
                end

                local Instance = Object.Items.Notification.Instance

                local Offset = UDim2.new(0, 30, 0, 80)
                local Transparency = 1 - (1 * (Object.Fade / 255))

                Instance.Position = Offset + UDim2.new(0, -(Instance.AbsoluteSize.X - (Instance.AbsoluteSize.X * (Object.Fade / 255))), 0, YOffset)
                Object:SetTransparency(Transparency)

                if Object.Status and BiggestX < Instance.AbsoluteSize.X then
                    BiggestX = math.max(BiggestX, Instance.AbsoluteSize.X)
                end

                YOffset += (Instance.AbsoluteSize.Y + 6) * (Object.Fade / 255)
            end
        end

        Library.SetTransparency = function(self, Num)
            self.Items.Notification.Instance.GroupTransparency = Num
        end

        Library:Notify({ Text = 'Loaded!' })
    end

    do -- Mods lib
        local YOffset = 0
        local BiggestX = 0

        Library.AddMod = function(self, Data)
            Data = Data or {}

            local Cfg = {
                Text = Data.Title or Data.Name or Data.Text or "Title";
                Lifetime = Data.Lifetime or 5;

                Items = {};
                Status = true;
                Fade = 2;
                Tick = tick();
                Index = #self.Mods + 1
            }

            local Items = Cfg.Items; do
                Items.Mod = Library:Create("CanvasGroup",{Parent = self.Window.Items.ModHolder.Instance; BackgroundTransparency = 1; Size = UDim2.new(1, 0, 0, 25); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Items.Name = Library:Create("TextLabel",{LayoutOrder = 1; Parent = Items.Mod.Instance; TextColor3 = Color3.fromRGB(170, 170, 170); Text = "[X]"; AutomaticSize = Enum.AutomaticSize.XY; AnchorPoint = Vector2.new(0, 0); Position = UDim2.new(0, 0, 0, 0); BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Right; BorderSizePixel = 0; ZIndex = 2; BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Items.UIPadding = Library:Create("UIPadding",{PaddingTop = UDim.new(0, 4); PaddingBottom = UDim.new(0, 6); Parent = Items.Name.Instance; PaddingRight = UDim.new(0, 5); PaddingLeft = UDim.new(0, 7)})
            end

            function Cfg:ChangeName(Name)
                Items.Name.Instance.Text = tostring(Name)
            end

            function Cfg:Destroy()
                Cfg.Status = false

                task.delay(1, function()
                    Items.Mod.Instance:Destroy()
                end)
            end

            Cfg:ChangeName(Cfg.Text)

            self.Mods[Cfg.Index] = Cfg

            return setmetatable(Cfg, Library)
        end

        Library.LerpMods = function(self)
            YOffset = 0
            BiggestX = 0

            local Tick = tick()
            for _,Object in self.Mods do
                Object.Fade = Library:Lerp(Object.Fade, Object.Status and 255 or 0, 0.02)
                local Instance = Object.Items.Mod.Instance

                local Offset = UDim2.new(0, 0, 0, 0) -- great pasting skills
                local Transparency = 1 - (1 * (Object.Fade / 255))

                Instance.Position = Offset + UDim2.new(0, -(Instance.AbsoluteSize.X - (Instance.AbsoluteSize.X * (Object.Fade / 255))), 0, YOffset)
                Object:SetModTransparency(Transparency)

                if Object.Status and BiggestX < Instance.AbsoluteSize.X then
                    BiggestX = math.max(BiggestX, Instance.AbsoluteSize.X)
                end

                YOffset += (Instance.AbsoluteSize.Y) * (Object.Fade / 255)
                self.Window.Items.ModHolder.Instance.Size = UDim2.new(0, 200, 0, YOffset + 22)
            end
        end

        Library.SetModTransparency = function(self, Num)
            self.Items.Mod.Instance.GroupTransparency = Num
        end
    end

    Library:Connect(Services.RunService.Heartbeat, function()
        if not (Library.LerpObjects and Library.LerpMods) then
            return
        end

        Library:LerpObjects()
        Library:LerpKeybinds()
        Library:LerpMods()
    end)
end

-- local Flags = Library.Flags
-- local Window = Library:CreateWindow({
--     Title = "Aether.lua",
--     SubText = "Baseplate", -- Replace with game shortened strings.
--     Size = UDim2.fromOffset(775, 531),
--     Image = "rbxassetid://95259225424429",
--     IsMobile = false;
-- })

-- local AimAssist, SilentAim, Settings = Window:AddTab({
--     Title = "Combat",
--     Icon = "rbxassetid://108942872221425",
--     Pages = {"Aim Assist", "Silent Aim", "Settings"},
-- })

-- local Movement, GunMods, Teleports = Window:AddTab({
--     Title = "Misc",
--     Icon = "rbxassetid://72895573992960",
--     Pages = {"Movement", "Gun Mods", "Teleports"}
-- })

-- local Section = AimAssist:AddSection({
--     Text = "Silent Aim",
--     Side = "Left",
--     Collapsed = false,
-- })

-- Section:AddToggle({
--     Text = "Toggle",
--     Flag = "Custom Config Flag",
--     Enabled = false,
--     Callback = function(bool)
--         print(bool)
--         print(Flags["Custom Config Flag"])
--     end
-- })

-- Section:AddSlider({
--     Text = "Slider",
--     Flag = "Custom Slider Flag",
--     Min = 0,
--     Max = 100,
--     Rounding = 5,
--     Default = 50,
--     Suffix = "%",
--     Callback = function(int)
--         print(int)
--         print(Flags["Custom Slider Flag"])
--     end
-- })

-- Section:AddDropdown({
--     Text = "Example Dropdown",
--     Values = {"Option 1", "Option 2", "Option 3"},
--     Default = "Option 1",
--     Multi = false, -- Whether to allow multiple selections
--     Flag = "Dropdown flag",
--     Callback = function(Value)
--         print("Dropdown new value:", Value)
--         print(Flags["Dropdown flag"])
--     end
-- })

-- local Keybind = Section:AddKeyPicker({
--     Text = "Example Keybind",
--     Mode = "Toggle", -- Options: "Toggle", "Hold", "Always"
--     ShowInList = true, -- Self explanatory
--     Callback = function(Value)
--         print("Keybind pressed, value:", Value)
--     end
-- })

-- Section:AddColorPicker({
--     Default = Color3.fromRGB(255, 0, 0),
--     Title = "Select Color",
--     Transparency = 0,
--     Flag = "Cock",
--     Callback = function(Value, Alpha)
--         print("Color changed to:", Value, Alpha)
--         -- print(Flags["Cock"].Color, Flags["Cock"].Transparency)
--     end
-- }):AddColorPicker({
--     Default = Color3.fromRGB(255, 255, 0),
--     Title = "Select Color",
--     Transparency = 0,
--     Flag = "Cock",
--     Callback = function(Value, Alpha)
--         print("Color changed to:", Value, Alpha)
--         -- print(Flags["Cock"].Color, Flags["Cock"].Transparency)
--     end
-- })

-- task.wait(Library.TweeningSpeed)
-- Library:InitConfigs(Window)
-- Library:AutoLoad()
-- Window.SetVisible(true)


return Library;]===])()

Library.Font = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
Library.Holder = Library.Elements;

Library.Notification = function(self, text, time)
    return Library:Notify({ Text = text, Lifetime = time });
end;

local flags = Library.Flags
local Window = Library:CreateWindow({
    Title = "Fallen Ultimate",
    SubText = "Public",
    Size = UDim2.fromOffset(775, 531),
    Image = "rbxassetid://82851477751652",
    IsMobile = false,
})

local Debris, Players, Workspace, GuiService, RunService, UserInputService, ReplicatedStorage, Lighting, HttpService =
    game:GetService('Debris'), game:GetService('Players'), game:GetService('Workspace'),
    game:GetService('GuiService'), game:GetService('RunService'), game:GetService('UserInputService'),
    game:GetService('ReplicatedStorage'), game:GetService('Lighting'), game:GetService('HttpService')

Cheat.Globals.HitSoundNames = {}
Cheat.Globals.RaidEsps = {}
Cheat.Globals.QuickStackFunctions = {}
Cheat.Globals.HitSoundIds = {}
Cheat.Globals.DesyncParts = {}
Cheat.Globals.DesyncedPositions = {}

Cheat.Globals.LastManip = tick()
Cheat.Globals.LastAutoReload = tick()


-- Watermark via notification loop (no direct watermark API in new lib)
task.spawn(function()
    while true do
        task.wait(1)
        -- Update title dynamically if the new library supports it, otherwise use a mod label
        -- Library:Notify({ Text = string.format("LUMEN | %s | %s | %d PLAYERS", os.date("%d/%m/%Y"), os.date("%H:%M:%S"), #Players:GetPlayers()), Lifetime = 1 })
    end
end)

--// Tabs
local CombatTab = Window:AddTab({ Title = "Combat",   Icon = "rbxassetid://108942872221425",  Pages = {'Combat'} })
local ESPTab, Boss, AI = Window:AddTab({ Title = "ESP",  Icon = "rbxassetid://2990054943", Pages = {'Players', 'Boss', 'AI'} })
local VisualsTab = Window:AddTab({ Title = "Visuals",  Icon = "rbxassetid://86838383310617", Pages = {'Visuals'} })
local MiscTab    = Window:AddTab({ Title = "Misc",     Icon = "rbxassetid://133292957761995", Pages = {'Misc'} })

--// UI Elements
do
    --// Combat
    do
        --// Aimbot
        do
            local AimbotSection = CombatTab:AddSection({ Text = "Aimbot", Side = "Left", Collapsed = false })

            AimbotSection:AddToggle({ Text = "Enabled",           Flag = "AimbotEnabled",      Enabled = false })

            AimbotSection:AddSlider({ Text = "Hit Chance",        Flag = "HitChance",          Min = 0, Max = 100, Default = 100, Rounding = 1, Suffix = "%" })

            AimbotSection:AddToggle({ Text = "Force Penetration", Flag = "ForcePenetration",   Enabled = false })

            AimbotSection:AddToggle({ Text = "Manipulation",      Flag = "Manipulation",       Enabled = false })
            AimbotSection:AddColorPicker({ Title = "Manipulation Color", Flag = "ManipulationIndicatorColor", Default = Color3.fromRGB(255, 0, 0), Transparency = 0 })

            AimbotSection:AddToggle({ Text = "Target Teammates",  Flag = "TargetTeammates",    Enabled = true })

            AimbotSection:AddToggle({ Text = "Visible Check",     Flag = "VisibleCheck",       Enabled = false })
            AimbotSection:AddColorPicker({ Title = "Visible Color", Flag = "VisibleIndicatorColor", Default = Color3.fromRGB(0, 189, 255), Transparency = 0 })

            AimbotSection:AddToggle({ Text = "Down Check",        Flag = "DownCheck",          Enabled = true })
            AimbotSection:AddToggle({ Text = "Flags",             Flag = "CombatIndicators",   Enabled = true })

            AimbotSection:AddDropdown({
                Text    = "Target Parts",
                Flag    = "TargetParts",
                Values  = {
                    "Head","UpperTorso","LowerTorso",
                    "LeftUpperArm","LeftLowerArm","LeftHand",
                    "RightUpperArm","RightLowerArm","RightHand",
                    "LeftUpperLeg","LeftLowerLeg","LeftFoot",
                    "RightUpperLeg","RightLowerLeg","RightFoot"
                },
                Default = "Head",
                Multi   = true,
            })

            AimbotSection:AddToggle({ Text = "Draw Fov", Flag = "FovEnabled", Enabled = false })
            AimbotSection:AddColorPicker({ Title = "Fov Color", Flag = "FovColor", Default = Color3.fromRGB(0, 189, 255), Transparency = 4 })

            AimbotSection:AddToggle({
                Text = "Filled Fov",
                Flag = "FovFilled",
                Enabled = false
            })

            AimbotSection:AddSlider({
                Text = "Fill Transparency",
                Flag = "FovFillTransparency",
                Min = 0,
                Max = 1,
                Default = 1,
                Rounding = 0.01
            })

            AimbotSection:AddSlider({ Text = "Fov Size",    Flag = "FovSize",      Min = 0,   Max = 500, Default = 200, Rounding = 1 })
            AimbotSection:AddSlider({ Text = "Thickness",   Flag = "FovThickness", Min = 1,   Max = 5,   Default = 4.5,   Rounding = 0.1 })

        end

        --// Gun Mods
        do
            local GunModsSection = CombatTab:AddSection({ Text = "Gun Mods", Side = "Right", Collapsed = false })

            GunModsSection:AddToggle({ Text = "No Recoil",     Flag = "NoRecoil",      Enabled = false })
            GunModsSection:AddToggle({ Text = "No Spread",     Flag = "NoSpread",      Enabled = false })
            GunModsSection:AddToggle({ Text = "No Sway",       Flag = "NoSway",        Enabled = false })
            GunModsSection:AddToggle({ Text = "RPM",           Flag = "RPM",           Enabled = false })

            GunModsSection:AddSlider({ Text = "Multiplier",    Flag = "RapidFireRate", Min = 1, Max = 1.5, Default = 1, Rounding = 0.1 })

            GunModsSection:AddToggle({ Text = "Instant Bullet", Flag = "InstantBullet", Enabled = false })
            GunModsSection:AddToggle({ Text = "Hit Sounds",     Flag = "Hitsounds",     Enabled = false })

            GunModsSection:AddDropdown({
                Text    = "Hit Sound",
                Flag    = "HitsoundSelect",
                Values  = Cheat.Globals.HitSoundNames,
                Default = Cheat.Globals.HitSoundNames[1] or "",
                Multi   = false,
            })

            GunModsSection:AddSlider({ Text = "Volume", Flag = "HitsoundVolume", Min = 0, Max = 1, Default = 0.5, Rounding = 0.1 })
        end
        --// KillAura
        -- do
        --     local MiscCombatSection = MiscCombat:AddSection({ Text = "Killaura", Side = "Left", Collapsed = false })

        --     MiscCombatSection:AddToggle({
        --         Text = "Enabled",
        --         Flag = "KillauraToggle",
        --         Enabled = false
        --     })

        --     MiscCombatSection:AddKeyPicker({
        --         Text = "Activation",
        --         Flag = "Killaura Activation",
        --         Mode = "Hold",
        --         ShowInList = true
        --     })

        --     MiscCombatSection:AddSlider({
        --         Text = "Radius",
        --         Flag = "KillauraRadius",
        --         Min = 1,
        --         Max = 25,
        --         Default = 10,
        --         Rounding = 1
        --     })

        --     MiscCombatSection:AddSlider({
        --         Text = "Spin Speed",
        --         Flag = "SpinSpeed",
        --         Min = 0,
        --         Max = 20,
        --         Default = 5,
        --         Rounding = 0.1
        --     })

        --     MiscCombatSection:AddColorPicker({
        --         Title = "Circle Color",
        --         Flag = "KillAuraColor",
        --         Default = Color3.fromRGB(255, 0, 0),
        --         Transparency = 0
        --     })

        --     MiscCombatSection:AddToggle({
        --         Text = "Third Person",
        --         Flag = "ThirdPerson",
        --         Enabled = false
        --     })

        --     MiscCombatSection:AddKeyPicker({
        --         Text = "Third Person Key",
        --         Flag = "Third Person Activation",
        --         Mode = "Hold",
        --         ShowInList = true
        --     })
        -- end

        -- do
        --     local AutoFarmSection = MiscCombat:AddSection({ Text = "Auto Farm", Side = "Right", Collapsed = false })

        --     AutoFarmSection:AddToggle({
        --         Text = "Enabled",
        --         Flag = "AutoFarmToggle",
        --         Enabled = false
        --     })

        --     AutoFarmSection:AddKeyPicker({
        --         Text = "Activation",
        --         Flag = "AutoFarm Activation",
        --         Mode = "Hold",
        --         ShowInList = true
        --     })

        --     AutoFarmSection:AddSlider({
        --         Text = "Radius",
        --         Flag = "AutoFarmRadius",
        --         Min = 1,
        --         Max = 30,
        --         Default = 12,
        --         Rounding = 1
        --     })

        --     AutoFarmSection:AddColorPicker({
        --         Title = "Circle Color",
        --         Flag = "AutoFarmColor",
        --         Default = Color3.fromRGB(0, 255, 100),
        --         Transparency = 0
        --     })
        -- end

    --// Visuals
    do

        local function BuildESPSection(tab, className, side)
            local s = tab:AddSection({ Text = className, Side = side, Collapsed = false })
            s:AddToggle({ Text = "Target Highlight", Flag = className .. "TargetHighlight", Enabled = false })
            s:AddColorPicker({ Title = "Target Color", Flag = className .. "TargetColor", Default = Color3.fromRGB(255, 60, 60), Transparency = 0 })
            s:AddToggle({ Text = "Enable",     Flag = className .. "ESPEnabled", Enabled = false })

            s:AddToggle({ Text = "Boxes",      Flag = className .. "Boxes",      Enabled = false })
            s:AddColorPicker({ Title = "Box Color",    Flag = className .. "BoxColor",    Default = Color3.fromRGB(255,255,255), Transparency = 0 })


            if className == "Players" then
                s:AddToggle({ Text = "Chams", Flag = className .. "Chams", Enabled = false })
                s:AddColorPicker({ Title = "Chams Color",   Flag = className .. "ChamsColor1", Default = Color3.fromRGB(219, 0, 255), Transparency = 0.3 })
                s:AddColorPicker({ Title = "Chams Outline", Flag = className .. "ChamsColor2", Default = Color3.fromRGB(219, 0, 255), Transparency = 0 })
            end

            s:AddToggle({ Text = "Names",      Flag = className .. "Names",      Enabled = false })
            s:AddColorPicker({ Title = "Name Color",   Flag = className .. "NameColor",   Default = Color3.fromRGB(255,255,255), Transparency = 0 })

            s:AddToggle({ Text = "Health Bar", Flag = className .. "Health",     Enabled = false })
            s:AddColorPicker({ Title = "Health Low",  Flag = className .. "HealthLow",  Default = Color3.fromRGB(255, 0, 0),   Transparency = 0 })
            s:AddColorPicker({ Title = "Health Mid",  Flag = className .. "HealthMid",  Default = Color3.fromRGB(255, 255, 0), Transparency = 0 })
            s:AddColorPicker({ Title = "Health High", Flag = className .. "HealthHigh", Default = Color3.fromRGB(0, 255, 0),   Transparency = 0 })

            s:AddToggle({ Text = "Distance",   Flag = className .. "Distance",   Enabled = false })
            s:AddColorPicker({ Title = "Distance Color", Flag = className .. "DistanceColor", Default = Color3.fromRGB(255,255,255), Transparency = 0 })

            s:AddToggle({ Text = "Weapon",     Flag = className .. "Weapon",     Enabled = false })
            s:AddColorPicker({ Title = "Weapon Color", Flag = className .. "WeaponColor", Default = Color3.fromRGB(255,255,255), Transparency = 0 })


            s:AddToggle({ Text = "Gradient Text", Flag = className .. "GradientText", Enabled = false })
            s:AddToggle({ Text = "Animated Gradient", Flag = className .. "AnimatedGradientText", Enabled = false })
            s:AddSlider({ Text = "Gradient Speed", Flag = className .. "GradientSpeed", Min = 1, Max = 10, Default = 4, Rounding = 1 })

            s:AddColorPicker({ Title = "Text Gradient 1", Flag = className .. "TextGrad1", Default = Color3.fromRGB(255,255,255), Transparency = 0 })
            s:AddColorPicker({ Title = "Text Gradient 2", Flag = className .. "TextGrad2", Default = Color3.fromRGB(150,150,150), Transparency = 0 })

            s:AddSlider({ Text = "Max Distance (studs)", Flag = className .. "MaxDistance", Min = 20, Max = 10000, Default = 10000, Rounding = 1 })
        end

        BuildESPSection(ESPTab, "Players", "Left")
        BuildESPSection(Boss, "Boss",    "Left")
        BuildESPSection(AI, "AI",      "Left")

        --// Misc ESP
        do
            local MiscESPSection = ESPTab:AddSection({ Text = "Misc", Side = "Right", Collapsed = false })
            MiscESPSection:AddToggle({ Text = "Enabled", Flag = "MiscEnabledESP", Enabled = false })

            for _, v in next, {'Stone','Metal','Phosphate','Wool','Animals','Care Package','Drops','Body Bag','Salvaged Flycopter','Auto Turret','Shotgun Turret'} do
                local maxDist = (v == 'Care Package' or v == 'Salvaged Flycopter') and 3000 or v == 'Body Bag' and 1000 or 400
                local defaultDist = (v == 'Care Package' or v == 'Salvaged Flycopter') and 3000 or 50

                MiscESPSection:AddToggle({ Text = v,             Flag = v .. "Enabled",     Enabled = false })
                MiscESPSection:AddColorPicker({ Title = v .. " Color", Flag = v .. "Color", Default = Color3.fromRGB(255,255,255), Transparency = 0 })
                MiscESPSection:AddSlider({ Text = "Max Distance", Flag = v .. "MaxDistance", Min = 10, Max = maxDist, Default = defaultDist, Rounding = 1 })
            end
        end

        --// Misc Visuals
        do
            local Lighting = game:GetService("Lighting")
            local RunService = game:GetService("RunService")

            local MiscVisualsSection = VisualsTab:AddSection({ Text = "Misc", Side = "Left", Collapsed = false })

            local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

            local Bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
            local ColorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
            local SunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
            local DoF = Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect", Lighting)

            -- defaults
            local DefaultAmbient = Lighting.Ambient
            local DefaultOutdoorAmbient = Lighting.OutdoorAmbient
            local DefaultClockTime = Lighting.ClockTime
            local DefaultFogStart = Lighting.FogStart
            local DefaultFogEnd = Lighting.FogEnd

            local OldDensity = Atmosphere and Atmosphere.Density or 0.3

            --// AMBIENCE
            MiscVisualsSection:AddToggle({
                Text = "Ambience",
                Flag = "AmbienceEnabled",
                Enabled = false,
                Callback = function(v)
                    if not v then
                        Lighting.Ambient = DefaultAmbient
                    end
                end
            })

            MiscVisualsSection:AddColorPicker({
                Title = "Ambience Color",
                Flag = "AmbienceColor",
                Default = Color3.fromRGB(255,255,255),
                Transparency = 0
            })



            --// TIME
            MiscVisualsSection:AddToggle({
                Text = "Time Changer",
                Flag = "TimeChanger",
                Enabled = false,
                Callback = function(v)
                    if not v then
                        Lighting.ClockTime = DefaultClockTime
                    end
                end
            })

            MiscVisualsSection:AddSlider({
                Text = "Time",
                Flag = "Time",
                Min = 0,
                Max = 24,
                Default = 12,
                Rounding = 0.1
            })


            MiscVisualsSection:AddToggle({
                Text = "No Fog",
                Flag = "NoFog",
                Enabled = false,
                Callback = function(v)
                    if not v then
                        Lighting.FogStart = DefaultFogStart
                        Lighting.FogEnd = DefaultFogEnd

                        if Atmosphere then
                            Atmosphere.Density = OldDensity
                        end
                    end
                end
            })

            --// BLOOM
            -- MiscVisualsSection:AddToggle({
            --     Text = "Bloom",
            --     Flag = "BloomEnabled",
            --     Enabled = false,
            --     Callback = function(v)
            --         Bloom.Enabled = v
            --     end
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "Bloom Intensity",
            --     Flag = "BloomIntensity",
            --     Min = 0,
            --     Max = 10,
            --     Default = 1,
            --     Rounding = 0.1
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "Bloom Size",
            --     Flag = "BloomSize",
            --     Min = 0,
            --     Max = 100,
            --     Default = 24,
            --     Rounding = 0.1
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "Bloom Threshold",
            --     Flag = "BloomThreshold",
            --     Min = 0,
            --     Max = 5,
            --     Default = 2,
            --     Rounding = 0.1
            -- })

            --// COLOR
            -- MiscVisualsSection:AddToggle({
            --     Text = "Color Correction",
            --     Flag = "ColorCorrectionEnabled",
            --     Enabled = false,
            --     Callback = function(v)
            --         ColorCorrection.Enabled = v
            --     end
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "Brightness",
            --     Flag = "Brightness",
            --     Min = -5,
            --     Max = 5,
            --     Default = 0,
            --     Rounding = 0.1
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "Contrast",
            --     Flag = "Contrast",
            --     Min = -5,
            --     Max = 5,
            --     Default = 0,
            --     Rounding = 0.1
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "Saturation",
            --     Flag = "Saturation",
            --     Min = -5,
            --     Max = 5,
            --     Default = 0.3,
            --     Rounding = 0.1
            -- })

            -- MiscVisualsSection:AddColorPicker({
            --     Title = "Tint",
            --     Flag = "Tint",
            --     Default = Color3.fromRGB(255,255,255),
            --     Transparency = 0
            -- })

            --// SUN
            MiscVisualsSection:AddToggle({
                Text = "Sun Rays",
                Flag = "SunRaysEnabled",
                Enabled = false,
                Callback = function(v)
                    SunRays.Enabled = v
                end
            })

            MiscVisualsSection:AddSlider({
                Text = "Sun Intensity",
                Flag = "SunIntensity",
                Min = 0,
                Max = 5,
                Default = 0.25,
                Rounding = 0.1
            })

            MiscVisualsSection:AddSlider({
                Text = "Sun Spread",
                Flag = "SunSpread",
                Min = 0,
                Max = 1,
                Default = 1,
                Rounding = 0.1
            })

            --// DOF
            -- MiscVisualsSection:AddToggle({
            --     Text = "Depth Of Field",
            --     Flag = "DoFEnabled",
            --     Enabled = false,
            --     Callback = function(v)
            --         DoF.Enabled = v
            --     end
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "Focus Distance",
            --     Flag = "FocusDistance",
            --     Min = 0,
            --     Max = 100,
            --     Default = 20,
            --     Rounding = 0.1
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "InFocus Radius",
            --     Flag = "InFocusRadius",
            --     Min = 0,
            --     Max = 100,
            --     Default = 10,
            --     Rounding = 0.1
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "Near Intensity",
            --     Flag = "NearIntensity",
            --     Min = 0,
            --     Max = 1,
            --     Default = 0,
            --     Rounding = 0.1
            -- })

            -- MiscVisualsSection:AddSlider({
            --     Text = "Far Intensity",
            --     Flag = "FarIntensity",
            --     Min = 0,
            --     Max = 1,
            --     Default = 0.75,
            --     Rounding = 0.1
            -- })

            --// LOOP
            RunService.RenderStepped:Connect(function()

                if flags.AmbienceEnabled then
                    Lighting.Ambient = flags.AmbienceColor.Color
                end

                if flags.TimeChanger then
                    Lighting.ClockTime = flags.Time
                end

                if flags.NoFog then
                    Lighting.FogStart = 999999
                    Lighting.FogEnd = 999999

                    if Atmosphere then
                        Atmosphere.Density = 0
                        Atmosphere.Offset = 0
                        Atmosphere.Glare = 0
                        Atmosphere.Haze = 0
                    end
                end

                -- Bloom.Enabled = flags.BloomEnabled
                -- if flags.BloomEnabled then
                --     Bloom.Intensity = flags.BloomIntensity
                --     Bloom.Size = flags.BloomSize
                --     Bloom.Threshold = flags.BloomThreshold
                -- end

                -- ColorCorrection.Enabled = flags.ColorCorrectionEnabled
                -- if flags.ColorCorrectionEnabled then
                --     ColorCorrection.Brightness = flags.Brightness
                --     ColorCorrection.Contrast = flags.Contrast
                --     ColorCorrection.Saturation = flags.Saturation
                --     ColorCorrection.TintColor = flags.Tint.Color
                -- end

                SunRays.Enabled = flags.SunRaysEnabled
                if flags.SunRaysEnabled then
                    SunRays.Intensity = flags.SunIntensity
                    SunRays.Spread = flags.SunSpread
                end

                -- DoF.Enabled = flags.DoFEnabled
                -- if flags.DoFEnabled then
                --     DoF.FocusDistance = flags.FocusDistance
                --     DoF.InFocusRadius = flags.InFocusRadius
                --     DoF.NearIntensity = flags.NearIntensity
                --     DoF.FarIntensity = flags.FarIntensity
                -- end

            end)

            MiscVisualsSection:AddToggle({ Text = "Raid ESP",       Flag = "ESPRaids",          Enabled = false })
            MiscVisualsSection:AddToggle({ Text = "Notifications",  Flag = "RaidNotifications", Enabled = false })

            MiscVisualsSection:AddToggle({ Text = "Bullet Tracers", Flag = "BulletTracers",     Enabled = false })
            MiscVisualsSection:AddColorPicker({ Title = "Tracer Color", Flag = "BulletTracersColor", Default = Color3.fromRGB(255,255,255), Transparency = 0 })
            MiscVisualsSection:AddSlider({ Text = "Duration", Flag = "BulletTracersDuration", Min = 1, Max = 5, Default = 2, Rounding = 0.1 })

            MiscVisualsSection:AddToggle({ Text = "Hit Notifications", Flag = "HitNotifications", Enabled = false })

            MiscVisualsSection:AddToggle({ Text = "Gun Chams", Flag = "GunChams", Enabled = false })
            MiscVisualsSection:AddColorPicker({ Title = "Gun Color", Flag = "GunChamsColor", Default = Color3.fromRGB(255,255,255), Transparency = 1 })
            MiscVisualsSection:AddDropdown({ Text = "Gun Material", Flag = "GunChamsMaterial", Values = {'ForceField','Neon','Glass','Ice','Wood','Plastic','Metal'}, Default = "ForceField", Multi = false })

            MiscVisualsSection:AddToggle({ Text = "Arms Chams", Flag = "ArmChams", Enabled = false })
            MiscVisualsSection:AddColorPicker({ Title = "Arms Color", Flag = "ArmChamsColor", Default = Color3.fromRGB(255,255,255), Transparency = 1 })
            MiscVisualsSection:AddDropdown({ Text = "Arms Material", Flag = "ArmChamsMaterial", Values = {'ForceField','Neon','Glass','Ice','Wood','Plastic','Metal'}, Default = "ForceField", Multi = false })
        end
        do
            local CrosshairSection = VisualsTab:AddSection({Text = "Crosshair", Side = "Right"})

            CrosshairSection:AddToggle({Text = "Crosshair", Flag = "Crosshair"})
            CrosshairSection:AddToggle({Text = "Crosshair rotation", Flag = "RotateCrosshair", Default = true})
            CrosshairSection:AddToggle({Text = "Sync with FOV Color", Flag = "SyncCrosshair"})


            CrosshairSection:AddColorPicker({
                Title = "Independent color",
                Flag = "IndependentColor",
                Default = Color3.fromRGB(0,189,255),
                Transparency = 0
            })

            CrosshairSection:AddSlider({Text = "Crosshair Width", Flag = "CrosshairWidth", Min = 1, Max = 3, Default = 3})
            CrosshairSection:AddSlider({Text = "Crosshair Length", Flag = "CrosshairLength", Min = 5, Max = 40, Default = 19})
            CrosshairSection:AddSlider({Text = "Crosshair Gap", Flag = "CrosshairGap", Min = 1, Max = 40, Default = 20})

            CrosshairSection:AddSlider({Text = "Crosshair Transparency 1", Flag = "CrosshairTransparency1", Min = 0, Max = 1, Default = 0})
            CrosshairSection:AddSlider({Text = "Crosshair Transparency 2", Flag = "CrosshairTransparency2", Min = 0, Max = 1, Default = 0})

            CrosshairSection:AddSlider({Text = "Crosshair Tween Speed", Flag = "CrosshairTweenSpeed", Min = 0, Max = 1, Default = 0.05})


        end
    end


    RunService.RenderStepped:Connect(function()
        if not Crosshair or not Crosshair.ScreenGui then return end

        Crosshair.ScreenGui.Enabled = flags.Crosshair

        if not flags.Crosshair then return end

        local Length = flags.CrosshairLength
        local Width = flags.CrosshairWidth
        local Gap = flags.CrosshairGap

        local Color = typeof(flags.IndependentColor) == "table" and flags.IndependentColor.Color or flags.IndependentColor


        Crosshair.Objects[1].Size = UDim2.new(0, Width, 0, Length)
        Crosshair.Objects[2].Size = UDim2.new(0, Width, 0, Length)
        Crosshair.Objects[3].Size = UDim2.new(0, Length, 0, Width)
        Crosshair.Objects[4].Size = UDim2.new(0, Length, 0, Width)


        Crosshair.Objects[1].Position = UDim2.new(0.5, 0, 0.5, -Gap)
        Crosshair.Objects[2].Position = UDim2.new(0.5, 0, 0.5, Gap)
        Crosshair.Objects[3].Position = UDim2.new(0.5, Gap, 0.5, 0)
        Crosshair.Objects[4].Position = UDim2.new(0.5, -Gap, 0.5, 0)


        if flags.RotateCrosshair then
            Crosshair.MainFrame.Rotation += 0.5
        else
            Crosshair.MainFrame.Rotation = 0
        end

        -- color sync
        -- if flags.SyncCrosshair then
        --     Color = Visuals.FOVInline.BackgroundColor3
        -- end

        for i = 1, 4 do
            Crosshair.Objects[i].BackgroundColor3 = Color

            local g = Crosshair.Objects[i]:FindFirstChildOfClass("UIGradient")
            if g then
                g.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.633416473865509, flags.CrosshairTransparency1),
                    NumberSequenceKeypoint.new(1, flags.CrosshairTransparency2)
                }
            end
        end


        local Camera = workspace.CurrentCamera
        if not Camera then return end

        local ScreenSize = Camera.ViewportSize
        Crosshair.MainFrame.Position = UDim2.new(0, ScreenSize.X/2, 0, ScreenSize.Y/2)
    end)


    --// Misc
    do
        --// Movement
        do
            local MovementSection = MiscTab:AddSection({ Text = "Movement", Side = "Left", Collapsed = false })

            MovementSection:AddToggle({ Text = "Speed",    Flag = "SpeedEnabled",   Enabled = false })
            MovementSection:AddKeyPicker({ Text = "Speed Bind",  Flag = "SpeedBind",      Mode = "Toggle", ShowInList = true })
            MovementSection:AddSlider({ Text = "Speed",    Flag = "SpeedSpeed",     Min = 16, Max = 30, Default = 16, Rounding = 1 })

            MovementSection:AddToggle({ Text = "Flight",   Flag = "FlightEnabled",  Enabled = false })
            MovementSection:AddKeyPicker({ Text = "Flight Bind", Flag = "FlightBind",     Mode = "Toggle", ShowInList = true })
            MovementSection:AddSlider({ Text = "Speed",    Flag = "FlightSpeed",    Min = 1,  Max = 20, Default = 10, Rounding = 1 })

            MovementSection:AddToggle({ Text = "Zoom",     Flag = "ZoomEnabled",    Enabled = false })
            MovementSection:AddKeyPicker({ Text = "Zoom Bind",   Flag = "ZoomKeybind",    Mode = "Hold",   ShowInList = true })
            MovementSection:AddSlider({ Text = "Fov",      Flag = "ZoomAmount",     Min = 1,  Max = 80, Default = 30, Rounding = 1 })

            local Players = game:GetService("Players")
            local Client = Players.LocalPlayer

            MovementSection:AddToggle({
                Text = "Third person",
                Flag = "ThirdPersonToggle"
            })

            MovementSection:AddSlider({
                Text = "Third person Distance",
                Flag = "ModThirdPerson",
                Default = 5,
                Min = 5,
                Max = 20,
                Callback = function(v)
                    Client.CameraMaxZoomDistance = v
                    Client.CameraMinZoomDistance = v
                end
            })

            MovementSection:AddKeyPicker({
                Text = "Third person Key",
                Flag = "ThirdPersonKey",
                Mode = "Toggle",
                ShowIndicator = "Third person",
                Callback = function(state)
                    if state then
                        local dist = flags.ModThirdPerson or 5
                        Client.CameraMaxZoomDistance = dist
                        Client.CameraMinZoomDistance = dist
                        Client.CameraMode = Enum.CameraMode.Classic
                    else
                        Client.CameraMode = Enum.CameraMode.LockFirstPerson
                    end
                end
            })

            MovementSection:AddToggle({ Text = "Freecam",  Flag = "Freecam",        Enabled = false })
            MovementSection:AddKeyPicker({ Text = "Freecam Bind", Flag = "FreecamKeybind", Mode = "Toggle", ShowInList = true })
            MovementSection:AddSlider({ Text = "Speed",    Flag = "FreecamSpeed",   Min = 1,  Max = 100, Default = 10, Rounding = 1 })

            MovementSection:AddToggle({ Text = "Bunnyhop", Flag = "Bunnyhop",       Enabled = false })

            MovementSection:AddToggle({ Text = "Noclip",   Flag = "NoclipEnabled",  Enabled = false })
            MovementSection:AddKeyPicker({ Text = "Noclip Bind",  Flag = "NoclipKeybind",  Mode = "Hold",   ShowInList = true })

            MovementSection:AddToggle({ Text = "Rocket Noclip", Flag = "RocketNoclip", Enabled = false })
        end

        --// Exploits
        do
            local ExploitsSection = MiscTab:AddSection({ Text = "Exploits", Side = "Right", Collapsed = false })

            ExploitsSection:AddToggle({ Text = "Fov Changer",    Flag = "FovChanger",    Enabled = false })
            ExploitsSection:AddSlider({ Text = "Fov Amount",     Flag = "FovAmount",     Min = 70, Max = 120, Default = 100, Rounding = 1 })

            ExploitsSection:AddToggle({ Text = "No Bob",         Flag = "NoBob",         Enabled = false })
            ExploitsSection:AddToggle({ Text = "Perfect Farm",   Flag = "PerfectFarm",   Enabled = false })
            ExploitsSection:AddToggle({ Text = "Infinite Fly",   Flag = "InfiniteFly",   Enabled = false })
            ExploitsSection:AddToggle({ Text = "No Fall Damage", Flag = "NoFall",        Enabled = false })
            ExploitsSection:AddToggle({ Text = "No Grounded",    Flag = "NoGrounded",    Enabled = false })
            ExploitsSection:AddToggle({ Text = "Silent Walk",    Flag = "SilentWalk",    Enabled = false })

            ExploitsSection:AddToggle({
                Text    = "Instant Loot",
                Flag    = "InstantLoot",
                Enabled = false,
                Callback = function(value)
                    local QuickStackFunctions = Cheat.Globals.QuickStackFunctions or {}
                    if #QuickStackFunctions > 0 then
                        for _, FUNCTION in QuickStackFunctions do
                            debug.setconstant(FUNCTION, 19, value and 0 or 0.9)
                            debug.setconstant(FUNCTION, 20, value and 0 or 0.3)
                            debug.setconstant(FUNCTION, 21, value and 0 or 0.1)
                        end
                    end
                end,
            })

            ExploitsSection:AddToggle({ Text = "Instant Last Code", Flag = "InstantLastCode", Enabled = false })
        end
    end
end

task.wait(Library.TweeningSpeed)
Library:InitConfigs(Window)
Library:AutoLoad()
Window.SetVisible(true)

--// Game Code
local Camera = Workspace.CurrentCamera
local Client = Players.LocalPlayer
repeat wait() until Client and Client.Character and Workspace:FindFirstChild('VFX')
local wsVFXFolder = Workspace.VFX
local VMs = wsVFXFolder and wsVFXFolder:FindFirstChild('VMs')
local Drops = workspace:FindFirstChild('Drops')
local Plants = workspace:FindFirstChild('Plants')
local Animals = workspace:FindFirstChild('Animals')

local Modules = ReplicatedStorage:WaitForChild("Modules")
local rsVFXFolder = ReplicatedStorage:WaitForChild("VFX")
local Values = ReplicatedStorage:WaitForChild("Values")

local ItemClass = Modules and require(Modules:WaitForChild("ItemClass"))
local VFXModule = Modules and require(Modules.VFXModule)
local ItemsModule = Modules and require(Modules.Items)
local RaycastUtil = Modules and require(Modules.RaycastUtil)
local SettingsModule = Modules and require(Modules.SettingsModule)
local SoundModule = Modules and require(Modules.SoundModule)
local ToolInfo = Modules and require(Modules.ToolInfo)

if not (ItemClass and VFXModule and ItemsModule and RaycastUtil and SettingsModule and SoundModule) then
    Client:Kick("Failed to load game modules.")
    return
end

local clanController, clanControllerShared
if Client:FindFirstChild("PlayerScripts") and Client.PlayerScripts:FindFirstChild("ClanController") then
    clanController = getsenv(Client.PlayerScripts:WaitForChild("ClanController"))
    clanControllerShared = clanController and clanController.shared
else
    clanControllerShared = {cachedTeamModels = {}}
end

local isTeam = LPH_NO_VIRTUALIZE(function(player)
    if typeof(player) ~= 'Instance' or not player:IsA('Player') then return false end
    local teamCache = clanControllerShared and clanControllerShared.cachedTeamModels
    return teamCache and teamCache[player.UserId] or false
end)

local getgun = function(character)
    if not character then return "None" end
    for _, model in character:GetChildren() do
        if not model:IsA('Model') then
            continue
        end

        if model.Name == 'Hair' or model.Name == 'HolsterModel' then
            continue
        end

        if not model.PrimaryPart then
            continue
        end

        if model:FindFirstChild("Detail") or model:FindFirstChild("Main") or model:FindFirstChild("Handle") or model:FindFirstChild("Attachments") or model:FindFirstChild("ArrowAttach") or model:FindFirstChild("Attach") then
            return model.Name
        end;
    end;

    return "None"
end

local Targeting = {
    TargetPart = nil,
    TargetCharacter = nil,
    ManipulatedPosition = nil,
    ManipPos = nil,
    Targets = {},
}


--// Gun Mods
do
    local oldAttachmentStats = ItemClass.AttachmentStats
    ItemClass.AttachmentStats = LPH_NO_UPVALUES(function(v50, v51)
        local tb = debug.traceback()
        local r = oldAttachmentStats(v50, v51)

        if tb and tb:find('ViewmodelController') and r then
            if flags['RPM'] then
                r.FireRateMult = flags['RapidFireRate'] - 1
            end

            if flags['InstantBullet'] then
                r.SpeedMult = 100
            end

            if flags['NoRecoil'] then
                r.RecoilMult = -1;
            end

            if flags['NoSpread'] then
                r.AimSpreadMult = -1;
                r.HipSpreadMult = -1;
            end

            if flags['NoSway'] then
                r.SwayMult = -1;
            end
        end

        return r
    end)

    RunService.Heartbeat:Connect(function()
        -- debug.profilebegin("Auto Reload")

    end)
end
local RaidEvent = Instance.new("BindableEvent", ReplicatedStorage);

do --// Visuals
    --// Player ESP
    do
        local ESP = {}
-- bred the pred
        local function hookPlayer(p)
            if p == Client then return end
            p.CharacterAdded:Connect(function(c) createESP(c, p.Name, 'Players') end)
            p.CharacterRemoving:Connect(function(c)
                local e = ESP[c]
                if e then
                    e.Holder:Destroy()
                    ESP[c] = nil
                    if e.Cham then
                        e.Cham:Destroy()
                    end
                end
            end)
            if p.Character then
                createESP(p.Character, p.Name, 'Players')
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
        Players.PlayerAdded:Connect(hookPlayer)
        Players.PlayerRemoving:Connect(function(p)
            if p.Character and ESP[p.Character] then
                local e = ESP[p.Character]
                e.Holder:Destroy()
                ESP[p.Character]=nil
                if e.Cham then
                    e.Cham.Enabled = false
                end
            end
        end)

        local SoldierClassType = {
            Brutus = "Boss",
            Bruno = "Boss",
            BTR = "Boss",
            Boris = "Boss",
            Soldier = "AI",
        }

        local Military = workspace:FindFirstChild('Military')
        local Events = workspace:FindFirstChild('Events')

        if Military and Events then
            local function CacheSoldier(model)
                if (not model) or (not model.Parent) then return end
                local classType = SoldierClassType[model.Name]
                if not classType then return end
                if ESP[model] then return end
                createESP(model, model.Name, classType)
            end

            local function OnModelAdded(model)
                task.defer(function()
                    if model and model.Parent then
                        CacheSoldier(model)
                    end
                end)
            end

            local function OnModelRemoved(model)
                if model and ESP[model] then ESP[model].Holder:Destroy() ESP[model]=nil end
            end

            for _, obj in ipairs(Events:GetChildren()) do
                if obj.Name == 'BTR' then
                    CacheSoldier(obj)
                end
            end

            Events.ChildAdded:Connect(function(obj)
                if obj.Name == 'BTR' then
                    OnModelAdded(obj)
                end
            end)

            Events.ChildRemoved:Connect(function(obj)
                if obj.Name == 'BTR' then
                    OnModelRemoved(obj)
                end
            end)

            for _, folder in ipairs(Military:GetChildren()) do
                for _, soldier in ipairs(folder:GetChildren()) do
                    if soldier:IsA('Model') then
                        CacheSoldier(soldier)
                    end
                end

                folder.ChildAdded:Connect(function(soldier)
                    if soldier:IsA('Model') then
                        OnModelAdded(soldier)
                    end
                end)

                folder.ChildRemoved:Connect(function(soldier)
                    if soldier:IsA('Model') then
                        OnModelRemoved(soldier)
                    end
                end)
            end
        end
    end

    --// Fov Circle
    do
        local FovCircleOutline = Drawing.new('Circle')
        FovCircleOutline.Visible = false
        FovCircleOutline.NumSides = 64
        FovCircleOutline.ZIndex = 9
        FovCircleOutline.Filled = false
        FovCircleOutline.Transparency = 1
        FovCircleOutline.Radius = 200
        FovCircleOutline.Thickness = 4
        FovCircleOutline.Color = Color3.fromRGB(0, 0, 0)

        local FovCircle = Drawing.new('Circle')
        FovCircle.Visible = false
        FovCircle.NumSides = 64
        FovCircle.ZIndex = 10
        FovCircle.Filled = false
        FovCircle.Transparency = 1
        FovCircle.Radius = 200
        FovCircle.Thickness = 2
        FovCircle.Color = Color3.fromRGB(255, 20, 147)

        local FovFill = Drawing.new('Circle')
        FovFill.Visible = false
        FovFill.NumSides = 64
        FovFill.ZIndex = 8
        FovFill.Filled = true
        FovFill.Transparency = 1
        FovFill.Radius = 200
        FovFill.Thickness = 0
        FovFill.Color = Color3.fromRGB(255, 20, 147)

        local textHolder = Instance.new('Frame')
        textHolder.BackgroundTransparency = 1
        textHolder.BorderSizePixel = 0
        textHolder.ZIndex = 3
        textHolder.AnchorPoint = Vector2.new(0.5, 0)
        textHolder.Size = UDim2.fromOffset(0, 0)
        textHolder.Position = UDim2.new(0.5, 0, 0.5, 10)
        textHolder.AutomaticSize = Enum.AutomaticSize.XY
        textHolder.Visible = true
        textHolder.Parent = Library.Elements.Instance

        local layout = Instance.new('UIListLayout')
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 2)
        layout.Parent = textHolder

        local manipulationText = Instance.new('TextLabel')
        manipulationText.BackgroundTransparency = 1
        manipulationText.Size = UDim2.fromOffset(0, 0)
        manipulationText.AutomaticSize = Enum.AutomaticSize.XY
        manipulationText.TextWrapped = false
        manipulationText.FontFace = Library.Font
        manipulationText.TextSize = 14
        manipulationText.TextColor3 = Color3.new(1, 1, 1)
        manipulationText.TextStrokeTransparency = 0.6
        manipulationText.ZIndex = textHolder.ZIndex
        manipulationText.Parent = textHolder

        local visibleText = Instance.new('TextLabel')
        visibleText.BackgroundTransparency = 1
        visibleText.Size = UDim2.fromOffset(0, 0)
        visibleText.AutomaticSize = Enum.AutomaticSize.XY
        visibleText.TextWrapped = false
        visibleText.FontFace = Library.Font
        visibleText.TextSize = 14
        visibleText.Text = "VISIBLE"
        visibleText.TextColor3 = Color3.new(1, 1, 1)
        visibleText.TextStrokeTransparency = 0.6
        visibleText.ZIndex = textHolder.ZIndex
        visibleText.Parent = textHolder
        local lastupd = tick()
        RunService.RenderStepped:Connect(function()
            if tick() - lastupd < 1/30 then return end
            lastupd = tick()

            local radius = flags.FovSize or 200
            local thickness = flags.FovThickness or 2

            local vp = Camera.ViewportSize
            local pos = Vector2.new(vp.X * 0.5, vp.Y * 0.5)


            if flags.CombatIndicators then
                if Targeting.ManipulatedPosition then
                    manipulationText.Text = 'MANIPULATED'
                    manipulationText.TextColor3 = flags.ManipulationIndicatorColor.Color
                    manipulationText.Visible = true
                else
                    manipulationText.Visible = false
                end

                if Targeting.TargetObject and Targeting.TargetObject.CoreInformation and Targeting.TargetObject.CoreInformation.Visible then
                    visibleText.TextColor3 = flags.VisibleIndicatorColor.Color
                    visibleText.Visible = true
                else
                    visibleText.Visible = false
                end
            else
                manipulationText.Visible = false
                visibleText.Visible = false
            end

            if (not flags.FovEnabled) then
                FovCircle.Visible = false
                FovCircleOutline.Visible = false
                return
            end


            local base = flags.FovColor
            local fovColor = base.Color or base
            local fovTransparency = flags.FovFilled and (flags.FovFillTransparency or 1) or 1

            if Targeting and Targeting.TargetPart and flags.PlayersTargetHighlight then
                fovColor = flags.PlayersTargetColor.Color
                local fovTransparency = flags.FovFilled and (flags.FovFillTransparency or 1) or 1
            end

            FovCircle.Position = pos
            FovCircleOutline.Position = pos
            FovFill.Position = pos

            FovCircle.Radius = radius
            FovCircleOutline.Radius = radius
            FovFill.Radius = radius

            local filled = flags.FovFilled == true
            local fillTrans = flags.FovFillTransparency or 1


            FovCircleOutline.Filled = false
            FovCircleOutline.Thickness = thickness + 2
            FovCircleOutline.Transparency = 1
            FovCircleOutline.Color = Color3.new(0,0,0)


            FovCircle.Filled = false
            FovCircle.Thickness = thickness
            FovCircle.Transparency = 1
            FovCircle.Color = fovColor


            FovFill.Filled = filled
            FovFill.Thickness = 0
            FovFill.Transparency = filled and fillTrans or 1
            FovFill.Color = fovColor

            FovCircle.Visible = flags.FovEnabled
            FovCircleOutline.Visible = flags.FovEnabled
            FovFill.Visible = flags.FovEnabled and filled
        end)
    end






    --// Armor Bar
    do
        local textureToInfoMap = {}
        local GunTable = {}
        for _, gun in next, ItemsModule do
            if typeof(gun.Image) == 'table' then
                GunTable[gun.Name] = gun.Image
            else
                GunTable[gun.Name] = {['Default'] = gun.Image}
            end
        end

        for _, gunModel in ReplicatedStorage:WaitForChild("VMs"):GetChildren() do
            for _, skinModel in gunModel:GetChildren() do
                local weaponFolder = skinModel:FindFirstChild("Weapon")
                if weaponFolder and weaponFolder:IsA("Folder") then
                    for _, part in weaponFolder:GetChildren() do
                        local textureId = nil
                        pcall(function()
                            textureId = part.TextureID
                        end)
                        if textureId then
                            textureToInfoMap[textureId] = {
                                gun = gunModel.Name,
                                skin = skinModel.Name,
                            }
                        end
                    end
                end
            end
        end

        local GetArmor = LPH_NO_VIRTUALIZE(function(Character)
            local final = {}
            local names = {}
            if not Character then return {} end
            if type(Character) == 'string' then
                return {}
            end
            for _, child in Character:GetChildren() do
                local armorNumber, skinName = child.Name:match('Armor_(%d+)/(.*)')

                if armorNumber then
                    local key = tonumber(armorNumber)
                    if key then
                        local item = ItemsModule[key]
                        if item and item.Type == 'Armor' and not table.find(names, item.Name) then
                            local image = ''
                            if type(item.Image) == 'table' then
                                if skinName and item.Image[skinName] then
                                    image = item.Image[skinName]
                                elseif item.Image.Default then
                                    image = item.Image.Default
                                end
                            elseif type(item.Image) == 'string' then
                                image = item.Image
                            end

                            local id = string.match(image or '', '%d+')
                            local imageData = ''

                            table.insert(names, item.Name)
                            table.insert(final, {
                                ['Skin'] = skinName,
                                ['Name'] = item.Name,
                                ['Type'] = item.ArmorType,
                                ['Image'] = id
                            })
                        end
                    end
                end
            end

            return final
        end)

        local lastarmor = ''
        local lastupd = tick()

    end


    local killauracircle; do
        killauracircle = Instance.new("MeshPart")
        killauracircle.Material = Enum.Material.Neon
        killauracircle.Orientation = Vector3.new(0, 180, 0)
        killauracircle.Rotation = Vector3.new(180, 0, 180)
        killauracircle.Size = Vector3.new(5.95454740524292, 0.5839467644691467, 6.083468437194824)
        killauracircle.Name = ""
        killauracircle.CanCollide = false
        killauracircle.CanTouch = false
        killauracircle.CanQuery = false
        killauracircle.MeshId = 'rbxassetid://6026280296'
        killauracircle.Parent = workspace
    end

    local autofarmcircle; do
        autofarmcircle = Instance.new("MeshPart")
        autofarmcircle.Material = Enum.Material.Neon
        autofarmcircle.Orientation = Vector3.new(0, 180, 0)
        autofarmcircle.Rotation = Vector3.new(180, 0, 180)
        autofarmcircle.Size = Vector3.new(5.95454740524292, 0.5839467644691467, 6.083468437194824)
        autofarmcircle.Name = ""
        autofarmcircle.CanCollide = false
        autofarmcircle.CanTouch = false
        autofarmcircle.CanQuery = false
        autofarmcircle.MeshId = 'rbxassetid://6026280296'
        autofarmcircle.Parent = workspace
    end

    --// Misc ESP
    do
        local miscCache = {}
        local worldToViewportPoint = Camera.WorldToViewportPoint

        local ScreenGui = Instance.new('ScreenGui')
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.Parent = gethui()

        local function espify(obj, staticname, manualflag)
            if not obj or miscCache[obj] then return end

            local flag = manualflag or obj.Name:gsub('_Node$', '')

            local label = Instance.new('TextLabel')
            label.BackgroundTransparency = 1
            label.TextSize = 12
            label.FontFace = Library.Font
            label.TextColor3 = Color3.new(1, 1, 1)
            label.AnchorPoint = Vector2.new(0.5, 0.5)
            label.AutomaticSize = Enum.AutomaticSize.XY
            label.Size = UDim2.fromOffset(0, 0)
            label.Visible = false
            label.Parent = ScreenGui

            local stroke = Instance.new('UIStroke')
            stroke.Thickness = 1
            stroke.Color = Color3.new(0, 0, 0)
            stroke.Parent = label

            miscCache[obj] = {
                obj = obj,
                label = label,
                stroke = stroke,
                flag = flag,
                staticname = staticname
            }
        end


        local function removeEsp(obj)
            local data = miscCache[obj]
            if data then
                data.label:Destroy()
                miscCache[obj] = nil
            end
        end

        local nodes = workspace:FindFirstChild('Nodes')
        local bases = workspace:FindFirstChild('Bases')

        if nodes then
            local function addNode(v)
                if v:IsA('BasePart') or v:IsA('Model') then
                    espify(v)
                end
            end

            for _, v in nodes:GetChildren() do
                addNode(v)
            end

            nodes.ChildAdded:Connect(addNode)
            nodes.ChildRemoved:Connect(removeEsp)
        end

        if bases then
            local function handleObject(obj)
                if obj:IsA('Model') and (obj.Name == 'Care Package' or obj.Name == 'Salvaged Flycopter' or obj.Name == 'Body Bag' or obj.Name == 'Auto Turret' or obj.Name == 'Shotgun Turret') then
                    espify(obj)
                end
            end

            local function handleFolder(folder)
                for _, obj in folder:GetChildren() do
                    handleObject(obj)
                end
                folder.ChildAdded:Connect(handleObject)
            end

            for _, base in bases:GetChildren() do
                for _, folder in base:GetChildren() do
                    handleFolder(folder)
                end
                base.ChildAdded:Connect(handleFolder)
            end
        end

        if Drops and Plants then
            RunService.RenderStepped:Connect(function()
                if not flags.MiscEnabledESP then return end
                for _, item in pairs(Drops:GetChildren()) do
                    if item:IsA('Model') and not miscCache[item] then
                        local distance = (Camera.CFrame.Position - item:GetPivot().Position).Magnitude
                        if distance <= flags.DropsMaxDistance then
                            espify(item, item.Name, 'Drops')
                        end
                    end
                end
                for _, plant in pairs(Plants:GetChildren()) do
                    if plant:IsA('Model') and not miscCache[plant] then
                        local name = string.gsub(plant.Name, ' Plant', '')
                        local distance = (Camera.CFrame.Position - plant:GetPivot().Position).Magnitude

                        if name == 'Wool' and distance <= flags.WoolMaxDistance then
                            espify(plant, 'Wool', 'Wool')
                        end
                    end
                end
            end)
        end

        if Animals then
            for _, animal in pairs(Animals:GetChildren()) do
                if animal:IsA('Model') then
                    local name = animal.Name:lower():gsub('prefab_animal_', ''):gsub('_', ' ')
                    espify(animal, name, 'Animals')
                end
            end
            Animals.ChildAdded:Connect(function(animal)
                if animal:IsA('Model') then
                    local name = animal.Name:lower():gsub('prefab_animal_', ''):gsub('_', ' ')
                    espify(animal, name, 'Animals')
                end
            end)
            Animals.ChildRemoved:Connect(removeEsp)
        end

        local step = 1 / 60
        local lastTick = tick()

        local function getWorldPosition(obj)
            if obj:IsA('BasePart') then
                return obj.Position
            elseif obj:IsA('Model') then
                return obj:GetPivot().Position
            end
        end

        RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            local now = tick()
            if now - lastTick < step then return end
            lastTick = now

            local miscEnabled = flags.MiscEnabledESP
            local camPos = Camera.CFrame.Position

            for obj, data in pairs(miscCache) do
                if not obj or not obj.Parent then
                    data.label:Destroy()
                    miscCache[obj] = nil
                    continue
                end

                if not miscEnabled or not flags[data.flag .. 'Enabled'] then
                    data.label.Visible = false
                    continue
                end

                local worldPos
                if obj:IsA('BasePart') then
                    worldPos = obj.Position
                else
                    worldPos = obj:GetPivot().Position
                end

                local screenPos, onScreen = worldToViewportPoint(Camera, worldPos)
                if not onScreen then
                    data.label.Visible = false
                    continue
                end

                local dist = (camPos - worldPos).Magnitude
                if dist > flags[data.flag .. 'MaxDistance'] then
                    data.label.Visible = false
                    continue
                end
                local name = data.staticname or data.flag

                data.label.Visible = true
                data.label.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
                data.label.Text = string.format('%s \n%d Studs', name, math.floor(dist))

                local col = flags[data.flag .. 'Color']
                if col then
                    data.label.TextColor3 = col.Color
                end
            end
        end))
    end

    do --// VMs
        local function makeChamClone(part, name, color3, transparency, materialName)
            local clone = part:Clone()
            clone.Name = name
            clone:SetAttribute('__cloned', true)

            clone.Anchored = false
            clone.CanCollide = false
            clone.CanTouch = false
            clone.CanQuery = false
            clone.Massless = true

            clone.Transparency = transparency or 0
            clone.LocalTransparencyModifier = 0

            if color3 then
                clone.Color = color3
            end
            if materialName then
                clone.Material = Enum.Material[materialName]
            end

            clone.Parent = part.Parent
            clone.CFrame = part.CFrame

            local wc = Instance.new('WeldConstraint')
            wc.Part0 = clone
            wc.Part1 = part
            wc.Parent = clone

            return clone
        end

        if VMs then
            VMs.ChildAdded:Connect(function(VM)
                if VM.Name == 'IgnoreMe' then return end
                task.spawn(function()
                    task.wait(0.2)

                    local Viewmodel = Workspace.VFX.VMs:FindFirstChildOfClass('Model')
                    if not Viewmodel then return end

                    local Arms = Viewmodel:WaitForChild('Arms', 9e9)
                    local Weapon = Viewmodel:WaitForChild('Weapon', 9e9)

                    for _, Part in next, Viewmodel:GetDescendants() do
                        if flags.GunChams
                            and Part:IsDescendantOf(Weapon)
                            and (Part:IsA('Part') or Part:IsA('MeshPart'))
                            and not Part:GetAttribute('__hidden')
                        then
                            makeChamClone(
                                Part,
                                '\0',
                                flags.GunChamsColor.Color,
                                1 - flags.GunChamsColor.Transparency,
                                flags.GunChamsMaterial
                            )

                            Part.Transparency = 1
                            Part.LocalTransparencyModifier = 1
                            Part:SetAttribute('__hidden', true)
                        end

                        if flags.ArmChams
                            and Part:IsDescendantOf(Arms)
                            and (Part:IsA('Part') or Part:IsA('MeshPart'))
                            and not Part:GetAttribute('__hidden')
                        then
                            makeChamClone(
                                Part,
                                '\0',
                                flags.ArmChamsColor.Color,
                                1 - flags.ArmChamsColor.Transparency,
                                flags.ArmChamsMaterial
                            )

                            Part.Transparency = 1
                            Part.LocalTransparencyModifier = 1
                            Part:SetAttribute('__hidden', true)
                        end

                        if Part:IsA('SurfaceAppearance')
                            and (Part:IsDescendantOf(Arms) or Part:IsDescendantOf(Weapon))
                            and not Part.Parent:GetAttribute('__cloned')
                        then
                            Part:Destroy()
                        end
                    end
                end)
            end)
        end
    end

    do --// Raid ESP
        local raidGui = Library.Holder.Instance

        local clusters = {}

        local function destroyUI(cl)
            local ui = cl.ui
            if ui then ui:Destroy(); cl.ui = nil end
        end

        local function buildUI(cl)
            destroyUI(cl)

            local root = Instance.new('Frame')
            root.BackgroundTransparency = 1
            root.AnchorPoint = Vector2.new(0.5, 1)
            root.Size = UDim2.fromOffset(200, 64)
            root.Parent = raidGui

            local vlist = Instance.new('UIListLayout')
            vlist.FillDirection = Enum.FillDirection.Vertical
            vlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
            vlist.VerticalAlignment = Enum.VerticalAlignment.Center
            vlist.Padding = UDim.new(0, 2)
            vlist.Parent = root

            local function outline(lbl)
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
            end

            local title = Instance.new('TextLabel')
            title.BackgroundTransparency = 1
            title.Size = UDim2.fromOffset(200, 16)
            title.Text = 'Raid'
            title.TextColor3 = Color3.fromRGB(255, 60, 60)
            title.TextSize = 14
            title.FontFace = Library.Font
            title.TextXAlignment = Enum.TextXAlignment.Center
            title.LayoutOrder = 1
            outline(title)
            title.Parent = root

            local infoRow = Instance.new('Frame')
            infoRow.BackgroundTransparency = 1
            infoRow.Size = UDim2.fromOffset(200, 16)
            infoRow.LayoutOrder = 2
            infoRow.Parent = root

            local hinfo = Instance.new('UIListLayout')
            hinfo.FillDirection = Enum.FillDirection.Horizontal
            hinfo.HorizontalAlignment = Enum.HorizontalAlignment.Center
            hinfo.VerticalAlignment = Enum.VerticalAlignment.Center
            hinfo.Padding = UDim.new(0, 8)
            hinfo.Parent = infoRow

            local distLabel = Instance.new('TextLabel')
            distLabel.BackgroundTransparency = 1
            distLabel.Size = UDim2.fromOffset(80, 16)
            distLabel.TextColor3 = Color3.new(1, 1, 1)
            distLabel.TextSize = 14
            distLabel.FontFace = Library.Font
            distLabel.TextXAlignment = Enum.TextXAlignment.Center
            outline(distLabel)
            distLabel.Parent = infoRow

            local timeLabel = Instance.new('TextLabel')
            timeLabel.BackgroundTransparency = 1
            timeLabel.Size = UDim2.fromOffset(100, 16)
            timeLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            timeLabel.TextSize = 14
            timeLabel.FontFace = Library.Font
            timeLabel.TextXAlignment = Enum.TextXAlignment.Center
            outline(timeLabel)
            timeLabel.Parent = infoRow

            local iconsRow = Instance.new('Frame')
            iconsRow.BackgroundTransparency = 1
            iconsRow.Size = UDim2.new(1, 0, 0, 36)
            iconsRow.Parent = root
            iconsRow.LayoutOrder = 3

            local hicons = Instance.new('UIListLayout')
            hicons.FillDirection = Enum.FillDirection.Horizontal
            hicons.HorizontalAlignment = Enum.HorizontalAlignment.Center
            hicons.VerticalAlignment = Enum.VerticalAlignment.Center
            hicons.Padding = UDim.new(0, 4)
            hicons.Parent = iconsRow

            local counts = {}
            for i = 1, #cl.items do
                local img = cl.items[i].image
                counts[img] = (counts[img] or 0) + 1
            end

            local order = {}
            for img in counts do
                table.insert(order, img)
            end
            table.sort(order, function(a, b)
                return counts[a] > counts[b]
            end)

            for i = 1, #order do
                local img = order[i]

                local holder = Instance.new('Frame')
                holder.Size = UDim2.fromOffset(36, 36)
                holder.BackgroundTransparency = 1
                holder.Parent = iconsRow

                local icon = Instance.new('ImageLabel')
                icon.Size = UDim2.fromScale(1, 1)
                icon.BackgroundTransparency = 1
                icon.Image = img
                icon.Parent = holder

                local c = counts[img]
                if (c > 1) then
                    local badge = Instance.new('TextLabel')
                    badge.AnchorPoint = Vector2.new(1, 0)
                    badge.Position = UDim2.new(1, 0, 0, 0)
                    badge.Size = UDim2.fromOffset(18, 14)
                    badge.BackgroundTransparency = 0.2
                    badge.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    badge.TextColor3 = Color3.new(1, 1, 1)
                    badge.TextSize = 14
                    badge.FontFace = Library.Font
                    badge.Text = tostring(c)
                    outline(badge)
                    badge.Parent = holder

                    Instance.new('UICorner', badge).CornerRadius = UDim.new(0, 4)
                end
            end

            vlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                root.Size = UDim2.fromOffset(200, vlist.AbsoluteContentSize.Y)
            end)

            cl.ui = root
            cl.distLabel = distLabel
            cl.timeLabel = timeLabel
        end


        RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
            local camCF = Camera.CFrame
            local camPos = camCF.Position
            local now = tick()

            local n = #clusters
            for i = 1, n do
                if not flags.ESPRaids then
                    if ui then
                        ui.Visible = false
                    end
                    continue
                end
                local cl = clusters[i]
                local ui = cl.ui
                if (ui) then
                    local v3, on = Camera:WorldToViewportPoint(cl.center)
                    on = on and (v3.Z > 0)

                    if (ui.Visible ~= on) then
                        ui.Visible = on
                    end

                    if (on) then
                        local d = (cl.center - camPos).Magnitude
                        local s = math.clamp(64 + d * 0.02, 48, 128)

                        if (cl._lastSize ~= s) then
                            cl._lastSize = s
                            ui.Size = UDim2.fromOffset(s, s)
                        end

                        local x, y = v3.X, v3.Y
                        if (cl._lastX ~= x or cl._lastY ~= y) then
                            cl._lastX, cl._lastY = x, y
                            ui.Position = UDim2.fromOffset(x, y)
                        end

                        local dist_label = cl.distLabel
                        if (dist_label) then
                            dist_label.Text = string.format('%d studs', math.floor(d + 0.5))
                        end

                        local time_label = cl.timeLabel
                        if (time_label) then
                            local t = cl.lastBoomAt
                            if (t) then
                                local ago = now - t
                                if (ago < 0) then ago = 0 end
                                time_label.Text = string.format('last %.1fs', ago)
                            else
                                time_label.Text = 'last ?'
                            end
                        end
                    end
                end
            end
        end))

        local gcIndex = 1;
        RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
            local now = tick();
            local n = #clusters;
            if (n == 0) then return; end;

            local checks = math.min(n, 32);
            for _ = 1, checks do
                if (n == 0) then break; end;

                if (gcIndex > n) then
                    gcIndex = 1;
                end;

                local cl = clusters[gcIndex];
                if (now - cl.lastUpdate >= 600) then
                    destroyUI(cl);
                    table.remove(clusters, gcIndex);
                    n -= 1;
                else
                    gcIndex += 1;
                end;
            end;
        end));

        local boom = {
            ['C4'] = {image = "rbxassetid://13169199238", name = 'Timed Explosive Charge'},
            ['DynamiteBundle'] = {image = "rbxassetid://15127431071", name = 'Dynamite Bundle'},
            ['DynamiteStick'] = {image = "rbxassetid://15127430886", name = 'Dynamite Stick'},
            ['Rocket'] = {image = "rbxassetid://15132772763", name = 'Rocket'}
        }

        RaidEvent.Event:Connect(LPH_NO_VIRTUALIZE(function(Type, cf)
            local pos = (typeof(cf) == 'CFrame') and cf.Position or cf
            local info = boom[Type]
            if (not info) then return end

            if (flags.ESPRaids) then
                local now = tick()
                local best, bestDist = nil, 400

                for _, cl in clusters do
                    local dist = (pos - cl.center).Magnitude
                    if (dist < bestDist) then
                        best, bestDist = cl, dist
                    end
                end

                if (best) then
                    table.insert(best.items, {pos = pos, image = info.image})
                    best.sum += pos
                    best.n += 1
                    best.center = best.sum / best.n
                    best.lastUpdate = now
                    best.lastBoomAt = now
                    buildUI(best)
                else
                    local cl = {
                        items = {{pos = pos, image = info.image}},
                        sum = pos,
                        n = 1,
                        center = pos,
                        lastUpdate = now,
                        lastBoomAt = now,
                        ui = nil
                    }
                    table.insert(clusters, cl)
                    buildUI(cl)
                end
            end

            if (flags.RaidNotifications) then
                local p = pos
                local coords = math.floor(p.X) .. ', ' .. math.floor(p.Y) .. ', ' .. math.floor(p.Z)
                Library:Notification('A ' .. info.name .. ' has been used at ' .. coords, 10)
            end
        end))
    end
end


--// Targeting
do

    Cheat.Globals.RaycastParams = RaycastParams.new()
    Cheat.Globals.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    Cheat.Globals.RaycastParams.IgnoreWater = true

    local IsPartVisible = LPH_NO_VIRTUALIZE(function(Part, Origin)
        if not Part then return false end
        local Head = Cheat.Globals.ClientCharacter and Cheat.Globals.ClientCharacter:FindFirstChild('Head')
        if not Head then return false end
        Origin = Origin or Head.CFrame.Position
        local to = Part.CFrame.Position
        local dir = (to - Origin)
        local RayResult = workspace:Raycast(Origin, dir, Cheat.Globals.RaycastParams)
        if not RayResult then return true end
        local inst = RayResult.Instance
        return inst and inst:IsDescendantOf(Part.Parent) or false
    end)

    local GetDistanceFromCenter = LPH_NO_VIRTUALIZE(function(part)
        local position = part
        if typeof(part) == "Instance" then position = part.CFrame.Position end
        local sp, on = Camera:WorldToViewportPoint(position)
        if not on then return math.huge end
        local c = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
        return (c - Vector2.new(sp.X, sp.Y)).Magnitude
    end)

    local vectors = {
        Vector3.new(0.5, 0, 0), Vector3.new(-0.5, 0, 0),
        Vector3.new(0, 0, 0.5), Vector3.new(0, 0, -0.5),
        Vector3.new(0, 0.5, 0), Vector3.new(0, -0.5, 0),
        Vector3.new(0.5, 0.5, 0), Vector3.new(0.5, -0.5, 0),
        Vector3.new(-0.5, 0.5, 0), Vector3.new(-0.5, -0.5, 0),
        Vector3.new(0, 0.5, 0.5), Vector3.new(0, -0.5, 0.5),
        Vector3.new(0, 0.5, -0.5), Vector3.new(0, -0.5, -0.5),
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
        Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
    }

    local manipOffsets = {
        Vector3.new( 3, 0, 0), Vector3.new(-3, 0, 0),
        Vector3.new( 6, 0, 0), Vector3.new(-6, 0, 0),
        Vector3.new( 4, 0, 0), Vector3.new(-4, 0, 0),

        Vector3.new( 3, 2, 0), Vector3.new(-3, 2, 0),
        Vector3.new( 6, 2, 0), Vector3.new(-6, 2, 0),
        Vector3.new( 4, 2, 0), Vector3.new(-4, 2, 0),

        Vector3.new( 0.2, 3.9, 0),
        Vector3.new( 1.8, 4.1, 1),
        Vector3.new( 2.1, 4.4, 1.1),
        Vector3.new( 0.15, 5.2, 0.1),
        Vector3.new(-1.8, 5.4,-0.2),
        Vector3.new(-2.3, 6.0,-0.4),
        Vector3.new( 0.1, 6.0, 0.0),

        Vector3.new( 7, 0, 0), Vector3.new(-7, 0, 0),
        Vector3.new( 7, 2, 0), Vector3.new(-7, 2, 0),

        Vector3.new( 0.1, 7.5, 0.0),
        Vector3.new( 0.1, 8.0, 0.0),
    }

    local is_cframe_visible = LPH_NO_VIRTUALIZE(function(cfrom, cto)
        if not (cfrom and cto) then return false end
        local hit = workspace:Raycast(cfrom.Position, cto.Position - cfrom.Position, Cheat.Globals.RaycastParams)
        return not hit
    end)


    local is_part_visible = LPH_NO_VIRTUALIZE(function(originCF, target_part)
        if not (originCF and target_part) then return false end

        if typeof(originCF) == 'Vector3' then
            originCF = CFrame.new(originCF)
        elseif typeof(originCF) ~= 'CFrame' then
            return false
        end

        local originPos = originCF.Position
        local targetPos = target_part:GetPivot().Position
        local direction = targetPos - originPos

        local hit = workspace:Raycast(originPos, direction, Cheat.Globals.RaycastParams)
        if not hit then return true end
        return hit.Instance and hit.Instance.Parent == target_part.Parent or false
    end)

    local FindVisiblePosition = LPH_NO_VIRTUALIZE(function(Origin, Destination)
        local o = (typeof(Origin) == 'CFrame') and Origin or CFrame.new(Origin)
        for i = 1, #manipOffsets do
            local pos = o * manipOffsets[i]
            if IsPartVisible(Destination, pos) then
                return pos
            end
        end
        return nil
    end)

    RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
        debug.profilebegin("Targeting Loop")
        for name, player in pairs(Players:GetPlayers()) do
            if not Targeting.Targets[player] and player ~= Client then
                Targeting.Targets[player] = {
                    Class = "Player",
                    Player = player,
                    Character = player.Character,
                    CoreInformation = { Visible = false, OnScreen = false, Root = nil },
                    LastUpdate = 0,
                    Humanoid = nil,
                    Root = nil,
                }
            end
        end
        Cheat.Globals.RaycastParams.FilterDescendantsInstances = {
            Camera, Cheat.Globals.ClientCharacter,
            workspace:FindFirstChild("VFX"),
            workspace:FindFirstChild("RocketFactoryPinkCardInvisWalls")
        }

        local Silent = (flags.AimbotEnabled) or false
        local TargetParts = flags.TargetParts or {'Head'}
        if not TargetParts or #TargetParts == 0 then return end
        local DesiredPartName = TargetParts[math.random(#TargetParts)] or "Head"
        local ManipulationActive = Silent and (flags.Manipulation == true) or false
        local HitScanActive = flags.HitScan
        local UseVisibleCheck = flags.VisibleCheck == true
        local DownCheck = flags.DownCheck == true
        local ClosestDistance = (flags.FovSize or 0)

        local ClosestTarget = nil
        local EntityCharacter = nil
        local EntityData = nil
        local EntityInstance = nil
        local Manipulated = false
        local Visible = false
        local ManipulatedPart, ManipulatedPosition, ManipulatedPlayer = nil, nil, nil

        local now = tick()

        for Entity, Object in pairs(Targeting.Targets) do
            if not Object then continue end
            if not Object.Character or not Object.Character.Parent then
                Object.Character = (Object.Class == "Player" and Object.Player.Character) or nil
            end

            local character = Object.Character
            if not character or not character.Parent then
                Object.CoreInformation = { Visible = false, OnScreen = false, Root = nil }
                continue
            end

            if now - (Object.LastUpdate or 0) > 1/30 then
                Object.LastUpdate = now
                local Humanoid = character:FindFirstChildOfClass("Humanoid")
                if Humanoid then Object.Humanoid = Humanoid end
                if Object.Class == "Player" or Object.Class == "AI" then
                    Object.Root = (Humanoid and Humanoid.RootPart) or character:FindFirstChild("HumanoidRootPart")
                end
                if not Object.Root then
                    Object.Root = character:FindFirstChild("RootPart") or character:FindFirstChild("HumanoidRootPart")
                end

                local root = Object.Root
                if not root then
                    Object.CoreInformation = { Visible = false, OnScreen = false, Root = nil }
                elseif (Camera.CFrame.Position - root.Position).Magnitude > 2000 then
                    Object.CoreInformation = { Visible = false, OnScreen = false, Root = root }
                else
                    local parts = character:GetChildren()
                    local inf = math.huge
                    local minx, miny, minz = inf, inf, inf
                    local maxx, maxy, maxz = -inf, -inf, -inf
                    local rc = root.CFrame
                    for _, Part in ipairs(parts) do
                        if Part:IsA("BasePart") then
                            local Cf = rc:ToObjectSpace(Part.CFrame)
                            local sx, sy, sz = Part.Size.X, Part.Size.Y, Part.Size.Z
                            local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Cf:components()
                            local wsx = 0.5 * (math.abs(R00) * sx + math.abs(R01) * sy + math.abs(R02) * sz)
                            local wsy = 0.5 * (math.abs(R10) * sx + math.abs(R11) * sy + math.abs(R12) * sz)
                            local wsz = 0.5 * (math.abs(R20) * sx + math.abs(R21) * sy + math.abs(R22) * sz)
                            minx = math.min(minx, X - wsx) ; miny = math.min(miny, Y - wsy) ; minz = math.min(minz, Z - wsz)
                            maxx = math.max(maxx, X + wsx) ; maxy = math.max(maxy, Y + wsy) ; maxz = math.max(maxz, Z + wsz)
                        end
                    end
                    local minv = Vector3.new(minx, miny, minz)
                    local maxv = Vector3.new(maxx, maxy, maxz)
                    local middle = (maxv + minv) * 0.5
                    local cf = rc - rc.Position + rc * middle
                    local half = (maxv - minv) * 0.5
                    local hx, hy, hz = math.min(half.X, 5), math.min(half.Y, 10), math.min(half.Z, 5)
                    local offsets = {
                        Vector3.new( hx,  hy,  hz), Vector3.new( hx,  hy, -hz),
                        Vector3.new( hx, -hy,  hz), Vector3.new( hx, -hy, -hz),
                        Vector3.new(-hx,  hy,  hz), Vector3.new(-hx,  hy, -hz),
                        Vector3.new(-hx, -hy,  hz), Vector3.new(-hx, -hy, -hz),
                    }
                    local on = false
                    for i = 1, 8 do
                        local _, s = Camera:WorldToViewportPoint(cf * offsets[i])
                        if s then on = true break end
                    end

                    if not on then
                        local head = character:FindFirstChild("Head")
                        local vis = head and IsPartVisible(head) or false

                        Object.CoreInformation = {
                            Root = root,
                            RootPosition = root.Position,
                            OnScreen = false,
                            Visible = vis,
                            VisiblePart = vis and head or nil
                        }

                    else
                        local part = character:FindFirstChild(DesiredPartName)

                        if part then
                            local vis = IsPartVisible(part)
                            local now = tick()

                            LastVisiblePart = LastVisiblePart or {}
                            local cache = LastVisiblePart[Object]

                            if vis then
                                LastVisiblePart[Object] = {
                                    Part = part,
                                    Time = now
                                }

                                Object.CoreInformation = {
                                    Visible = true,
                                    VisiblePart = part,
                                    Root = root,
                                    RootPosition = root.Position,
                                    OnScreen = on
                                }

                            elseif cache and (now - cache.Time < VisibleHoldTime) then
                                Object.CoreInformation = {
                                    Visible = true,
                                    VisiblePart = cache.Part,
                                    Root = root,
                                    RootPosition = root.Position,
                                    OnScreen = on
                                }

                            else
                                Object.CoreInformation = {
                                    Visible = false,
                                    VisiblePart = nil,
                                    Root = root,
                                    RootPosition = root.Position,
                                    OnScreen = on
                                }
                            end
                        end
                    end


                        Object.CoreInformation = {
                            Visible = false,
                            VisiblePart = nil,
                            Root = root,
                            RootPosition = root.Position,
                            OnScreen = on
                        }
                        local visPart = nil
                        local names = { "HumanoidRootPart", "RightLowerLeg", "LeftLowerLeg", "RightUpperArm", "LeftUpperArm" }
                        for _, n in ipairs(names) do
                            local p = character:FindFirstChild(n)
                            if p and p:IsA("BasePart") then
                                local vis = IsPartVisible(p)
                                local now = tick()

                                if vis then
                                    LastVisiblePart[character] = { Part = p, Time = now }
                                    visPart = p
                                    break
                                    end
                                    local cache = LastVisiblePart and LastVisiblePart[character]

                                    if cache and (now - cache.Time < VisibleHoldTime) then
                                    visPart = LastVisiblePart[character].Part
                                    break
                                end
                            end
                        end
                        Object.CoreInformation = { Visible = visPart ~= nil, VisiblePart = visPart, Root = root, RootPosition = root.Position, OnScreen = on }
                    end
                end


            local Core = Object.CoreInformation
            if not flags.TargetTeammates and isTeam(Entity) then continue end
            if not (Core and Core.Root and Entity ~= Client) then continue end
            if not (Core.OnScreen and not Object.Teammate and flags.AimbotEnabled) then continue end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end
            if DownCheck and humanoid:GetAttribute('Downed') then continue end

            local Distance = GetDistanceFromCenter(Core.Root)
            if Distance >= ClosestDistance then continue end

            local tpart = nil
            if UseVisibleCheck and Core.Visible then
                tpart = Core.VisiblePart
            elseif not UseVisibleCheck then
                tpart = character:FindFirstChild(DesiredPartName)
            end

            if Cheat.Globals.DesyncedPositions[character] and Cheat.Globals.DesyncParts[character] then
                tpart = Cheat.Globals.DesyncParts[character]
            end

            if character.Name == "BTR" then
                tpart = character:FindFirstChild("HumanoidRootPart")
            end

            if tpart then
                ClosestDistance = Distance
                ClosestTarget  = tpart
                EntityCharacter = character
                EntityData      = Object
                EntityInstance  = Entity
                Visible         = Core.Visible
            end
        end

        if not Visible and Cheat.Globals.ClientCharacter and Cheat.Globals.ClientCharacter:FindFirstChild('Head') and ClosestTarget and EntityData then
            if now - (EntityData.LastManip or 0) > 0.1 then
                EntityData.LastManip = now

                if ManipulationActive then
                    local vp = FindVisiblePosition(Cheat.Globals.ClientCharacter.Head.CFrame, ClosestTarget)
                    if vp then
                        Manipulated = true
                        ManipulatedPart = ClosestTarget
                        ManipulatedPosition = vp
                        ManipulatedPlayer = EntityData.Pointer
                    end
                end

                EntityData.LastManipCFG = {
                    Manipulated = Manipulated,
                    ManipulatedPosition = ManipulatedPosition,
                    ManipulatedPart = ManipulatedPart,
                    ManipulatedPlayer = ManipulatedPlayer,
                }
            elseif EntityData.LastManipCFG then
                Manipulated = EntityData.LastManipCFG.Manipulated
                ManipulatedPosition = EntityData.LastManipCFG.ManipulatedPosition
                ManipulatedPart = EntityData.LastManipCFG.ManipulatedPart
                ManipulatedPlayer = EntityData.LastManipCFG.ManipulatedPlayer
            end
        end

        Targeting.TargetPart = ClosestTarget
        Targeting.TargetCharacter = EntityCharacter
        Targeting.TargetObject = EntityData
        Targeting.ManipulatedPosition = Manipulated and ManipulatedPosition or nil
        debug.profileend()
    end))
    local TrialModList = {
        [4619800148] = "Trial Moderator", --//gobliniukss
        [113179883]  = "Trial Moderator", --// DopeIlI
        [1771300283] = "Trial Moderator"; --// severalracks
        [1077540175] = "Trial Moderator"; --// i3riefcase
        [3320377356] = "Trial Moderator"; --// Kriffith
        [3508020028] = "Trial Moderator"; ---.. SOLDIER
        [3122439095] = "Trial Moderator"; --// CHANCE L	FAO
        [3034556584] = "Trial Moderator"; -- Adam
        [886544546]  = "Trial Moderator";
        [1616925260] = "Trial Moderator";
        [165053216]  = "Trial Moderator";
        [1992294235] = "Trial Moderator";
        [971641336]  = "Trial Moderator";
    };

	local FlaggedRoles = {
		"OG",
		"Game Tester",
		"Game Moderator",
		"Developers",
		"Lead Developer",
		"Co-Founder",
		"Founder",
		"Trial Moderator"
	};

	local function CheckMod(Player)
		local Role = TrialModList[Player.UserId] or Player:GetRoleInGroup(1154360);

		if table.find(FlaggedRoles, Role) then
			Library:Notification("Staff detected! [" .. Player.Name .. "] Role: " .. Role, 30)
            ModeratorList:add_mod(Player.Name, " [" .. Role .. "]")
			return
		end
	end;

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= Client then
            Targeting.Targets[Player] = {
                Class = "Player",
                Player = Player,
                Character = Player.Character,
                LastUpdate = 0,
                Root = nil,
                CoreInformation = { Visible = false, OnScreen = false, Root = nil },
            }
            pcall(CheckMod, Player)
        end
    end

    Players.PlayerAdded:Connect(function(Player)
        if Player ~= Client then
            Targeting.Targets[Player] = {
                Class = "Player",
                Player = Player,
                Character = Player.Character,
                LastUpdate = 0,
                Root = nil,
                CoreInformation = { Visible = false, OnScreen = false, Root = nil },
            }
            pcall(CheckMod, Player)
        end
    end)

    Players.PlayerRemoving:Connect(function(Player)
        Targeting.Targets[Player] = nil
    end)

    local SoldierClassType = {
		Brutus = "Boss",
		Bruno = "Boss",
		BTR = "Boss",
		Boris = "Boss",
		Soldier = "AI",
	}

	local Military = workspace:FindFirstChild("Military")
	if Military then
		local Events = workspace:FindFirstChild("Events")
		local CacheSoldier = function(Soldier)
			local ClassType = SoldierClassType[Soldier.Name]
			if not ClassType then return end

            Targeting.Targets[Soldier] = {
                Class = ClassType,
                Player = Soldier,
                Character = Soldier,
                LastUpdate = 0,
                Root = nil,
                CoreInformation = { Visible = false, OnScreen = false, Root = nil },
            }
		end;

		for Index, BTR in Events:GetChildren() do
			if BTR.Name == "BTR" then
				CacheSoldier(BTR)
			end;
		end;

		Events.ChildAdded:Connect(function(BTR)
			task.wait(1)
			if BTR.Name == "BTR" then
				CacheSoldier(BTR)
			end;
		end)

		for _, Folder in Military:GetChildren() do
			for Index, Soldier in Folder:GetChildren() do
				if Soldier:IsA("Model") then
					CacheSoldier(Soldier)
				end;
			end;

			Folder.ChildAdded:Connect(function(Soldier)
				task.wait(1)
				if Soldier:IsA("Model") then
					CacheSoldier(Soldier)
				end;
			end)
		end;
	end;
end

--// Misc
do
    setreadonly(math, false)
    local oldabs = math.abs
    math.abs = function(x)
        if flags.NoBob and debug.traceback():find('ViewmodelController') then
            for level = 2, 4 do
                if isvalidlevel(level) then
                    local stack = getstack(level)
                    local v = stack and stack[2]
                    if type(v) == 'boolean' then
                        setstack(level, 2, true)
                    end
                end
            end
        end

        return oldabs(x)
    end
    setreadonly(math, true)

    do --// Movement
        RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(dt)
            local Character = Cheat.Globals.ClientCharacter
            local Root = Character and Character:FindFirstChild("HumanoidRootPart")
            local Humanoid = Character and Character:FindFirstChild("Humanoid")
            local IsFlying
            if Humanoid and Root and Humanoid.Health > 0 then
                if
                    flags.SpeedEnabled
                    and flags["SpeedBind"].active
                    and not IsFlying
                    and Root
                then
                    local x, z = 0, 0
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        x += 1
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        x -= 1
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        z += 1
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        z -= 1
                    end

                    if x ~= 0 or z ~= 0 then
                        local cf = Camera.CFrame
                        local forward = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
                        local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit

                        local move = (right * x + forward * z).Unit
                        local hv = move * flags.SpeedSpeed
                        Root.Velocity = Vector3.new(hv.X, Root.Velocity.Y, hv.Z)
                    end
                end

                if
                    flags.Bunnyhop
                    and Humanoid.FloorMaterial ~= Enum.Material.Air
                    and UserInputService:IsKeyDown(Enum.KeyCode.Space)
                then
                    Humanoid.Jump = true
                end

                if
                    (flags["FlightEnabled"] and flags["FlightBind"].active)
                then
                    task.spawn(function()
                        IsFlying = true
                        if Humanoid and Humanoid.Health > 0 then
                            local Delta = dt * flags.FlightSpeed * 3
                            local MoveVector = Vector3.zero

                            local look = Camera.CFrame.LookVector
                            local right = Camera.CFrame.RightVector

                            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                                MoveVector += Vector3.new(look.X, 0, look.Z)
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                                MoveVector -= Vector3.new(look.X, 0, look.Z)
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                                MoveVector -= Vector3.new(right.X, 0, right.Z)
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                                MoveVector += Vector3.new(right.X, 0, right.Z)
                            end

                            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                                MoveVector += Vector3.new(0, 1, 0)
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                                MoveVector += Vector3.new(0, -1, 0)
                            end

                            if MoveVector.Magnitude > 0 then
                                MoveVector = MoveVector.Unit
                            end

                            local MovementDelta = MoveVector * Delta
                            local Position = Root.CFrame.Position + MovementDelta

                            Humanoid.PlatformStand = false
                            Root.Velocity = Vector3.zero
                            Root.CFrame = CFrame.new(Position, Position + Vector3.new(look.X, 0, look.Z))
                        end
                    end)
                end

                if
                    flags.Freecam
                    and flags["FreecamKeybind"]
                    and flags["FreecamKeybind"].active
                    and not IsFlying
                then
                    task.spawn(function()
                        if not Root then
                            return
                        end

                        Cheat.Globals.NeedToReturn = true

                        local CameraLookVector = Camera.CFrame.LookVector
                        local NormalCameraLookVector = CameraLookVector

                        if not Cheat.Globals.SavedPosition then
                            Cheat.Globals.SavedPosition = Root.CFrame
                        end

                        sethiddenproperty(Root, "NetworkIsSleeping", true)

                        local UpPos = Vector3.new(0, 1, 0)
                        local DownPos = Vector3.new(0, -1, 0)
                        local NonePos = Vector3.new(0, 0, 0)

                        local BaseCFrame = Root.CFrame
                        local IsUpPressed = UserInputService:IsKeyDown(Enum.KeyCode.E)
                        local IsDownPressed = UserInputService:IsKeyDown(Enum.KeyCode.Q)
                        local IsForwardPressed = UserInputService:IsKeyDown(119) -- W
                        local IsBackwardPressed = UserInputService:IsKeyDown(115) -- S

                        Root.Anchored = true
                        Root.Velocity = NonePos

                        local Delta = dt * flags.FreecamSpeed * 3

                        local MovementVector = (
                            Humanoid.MoveDirection
                            + (IsUpPressed and UpPos or NonePos)
                            + (IsDownPressed and DownPos or NonePos)
                            + (IsForwardPressed and Vector3.new(0, NormalCameraLookVector.Y, 0) or NonePos)
                            + (IsBackwardPressed and Vector3.new(0, -NormalCameraLookVector.Y, 0) or NonePos)
                        ) * Delta

                        BaseCFrame += MovementVector
                        local Position = BaseCFrame.p
                        Root.CFrame = CFrame.new(Position, Position + Vector3.new(CameraLookVector.X, 0, CameraLookVector.Z))
                        Humanoid.AutoRotate = false
                    end)
                else
                    if Cheat.Globals.NeedToReturn then
                        Humanoid.AutoRotate = true
                        Cheat.Globals.NeedToReturn = false
                        sethiddenproperty(Root, "NetworkIsSleeping", false)

                        for _, Value in Character:GetChildren() do
                            if Value:IsA("BasePart") then
                                sethiddenproperty(Value, "NetworkIsSleeping", false)
                            end
                        end

                        Root.CFrame = Cheat.Globals.SavedPosition
                        Root.Anchored = false
                        Cheat.Globals.SavedPosition = nil
                    end
                end

                if flags.InfiniteFly and IsFlying then
                    local Origin = Root.Position
                    local Result = workspace:Raycast(Origin, Vector3.new(0, -1000, 0), Cheat.Globals.RaycastParams)
                    if Result and Result.Distance > 4 then
                        task.spawn(function()
                            local OldVel = Root.Velocity
                            for _, Part in Character:GetChildren() do
                                if Part:IsA("BasePart") then
                                    Part.Velocity = Vector3.new(0, -9999, 0)
                                end
                            end
                            RunService.RenderStepped:Wait()
                            for _, Part in Character:GetChildren() do
                                if Part:IsA("BasePart") then
                                    Part.Velocity = OldVel
                                end
                            end
                        end)
                    end
                end

                if flags.NoFall and not IsFlying then
                    local Origin = Root.Position
                    local Result = workspace:Raycast(Origin, Vector3.new(0, -1000, 0), Cheat.Globals.RaycastParams)

                    if Result and Result.Distance > 10 then
                        task.spawn(function()
                            local OldVel = Root.Velocity
                            for _, Part in Character:GetChildren() do
                                if Part:IsA("BasePart") then
                                    Part.Velocity = Vector3.new(0, 9999, 0)
                                end
                            end
                            RunService.RenderStepped:Wait()
                            for _, Part in Character:GetChildren() do
                                if Part:IsA("BasePart") then
                                    Part.Velocity = OldVel
                                end
                            end
                        end)
                    end
                end
            end
        end))



        local desync = {}

        RunService.Heartbeat:Connect(function()
            for _, Part in workspace.RocketFactoryPinkCardInvisWalls:GetChildren() do
                if Part:IsA('Part') then
                    Part.CanCollide = flags.RocketNoclip
                end
            end
            if flags.NoclipEnabled and flags.NoclipKeybind.active and Client.Character and Client.Character:FindFirstChild('HumanoidRootPart') then
                desync[1] = Client.Character.HumanoidRootPart.CFrame
                desync[2] = Client.Character.HumanoidRootPart.AssemblyLinearVelocity
                local SpoofThis = Client.Character.HumanoidRootPart.CFrame
                SpoofThis = (SpoofThis + Vector3.new(0, -2.2, 0)) * CFrame.Angles(math.rad(90), 0, 0)
                Client.Character.HumanoidRootPart.CFrame = SpoofThis
                RunService.RenderStepped:Wait()
                if Client.Character and Client.Character.HumanoidRootPart then
                    Client.Character.HumanoidRootPart.CFrame = desync[1]
                    Client.Character.HumanoidRootPart.AssemblyLinearVelocity = desync[2]
                end
            end
        end)

        local defaultFov = Camera.FieldOfView
        local currentFov = defaultFov

        RunService.RenderStepped:Connect(function()
            local zoomOn = flags.ZoomEnabled and flags.ZoomKeybind and flags.ZoomKeybind.active
            local fovOn = flags.FovChanger

            -- decide target fov
            local targetFov = defaultFov

            if zoomOn then
                targetFov = flags.ZoomAmount
            elseif fovOn then
                targetFov = flags.FovAmount
            end


            local speed = flags.FovSmoothness or 0.15
            currentFov = currentFov + (targetFov - currentFov) * speed

            Camera.FieldOfView = currentFov


            if not zoomOn and not fovOn then
                defaultFov = currentFov
            end
        end)
    end
end

--// Main Hooks
do
    local OldRaycast = RaycastUtil.Raycast;
    RaycastUtil.Raycast = LPH_NO_VIRTUALIZE(function(self, ...)
        local Arguments = {...};

        if (not checkcaller()) then
            local Traceback = debug.traceback();

            if (Traceback and Traceback:find('ViewmodelController') and flags.Reach) then
                Arguments[2] = Arguments[2] * 10
            end;

            if (flags.PerfectFarm) then
                local Output = {OldRaycast(self, ...)};
                local HitInstance  = Output[1];
                local HitPosition = Output[2];

                if (not HitInstance or typeof(HitInstance) ~= 'Instance') then
                    return unpack(Output);
                end;

                if (not HitPosition or typeof(HitPosition) ~= 'Vector3') then
                    return unpack(Output);
                end;

                local Model = HitInstance.Parent;
                if (not Model or (not Model:IsA('Model'))) then
                    return unpack(Output);
                end;

                local Folder = Model.Parent;
                if (Folder and (Folder.Name == 'Trees' or Folder.Name == 'Nodes') and Folder:IsA('Folder')) then
                    local CriticalPart = Model:FindFirstChild('NodeSpark') or Model:FindFirstChild('TreeX')
                    if (CriticalPart and typeof(CriticalPart) == 'Instance' and CriticalPart:IsA('Model') and CriticalPart.PrimaryPart) then
                        Output[1] = CriticalPart.PrimaryPart;
                        return unpack(Output);
                    end;
                end;
            end;
        end;

        return OldRaycast(self, unpack(Arguments));
    end);

    setreadonly(getgenv().task, false)
    local oldtaskspawn = getgenv().task.spawn
    getgenv().task.spawn = newcclosure(LPH_NO_VIRTUALIZE(function(func, ...)
        local traceback = debug.traceback()

        if func and type(func) == 'function' and traceback:find('InteractController') then
            if flags.InstantLastCode then
                for i, v in debug.getconstants(func) do
                    if type(v) == 'number' and v == 0.4 then
                        debug.setconstant(func, i, 0)
                    end
                end
            end
        end

        if not func or type(func) ~= 'function' then
            return
        end

        return oldtaskspawn(func, ...)
    end))
    setreadonly(getgenv().task, true)

    local hitsoundsbind = Instance.new('BindableEvent', game:GetService('ReplicatedStorage'))
    local bullettracersbind = Instance.new('BindableEvent', game:GetService('ReplicatedStorage'))
    local hitnotificationsbind = Instance.new('BindableEvent', game:GetService('ReplicatedStorage'))

    hitnotificationsbind.Event:Connect(function(part, char)
        if flags.HitNotifications then
            local player = Players:GetPlayerFromCharacter(char)
            if player then
                local orighealth = char:FindFirstChildOfClass('Humanoid').Health
                local start = tick()
                local hum = char:FindFirstChildOfClass('Humanoid')
                hum.HealthChanged:Once(function(health)
                    local duration = tick() - start
                    if duration > 0.7 then return end
                    Library:Notification("Hit " .. player.Name .. " in their " .. part.Name .. " for " .. math.floor(orighealth - health) .. " damage", 5)
                end)
            end
        end
    end)

    hitsoundsbind.Event:Connect(function()
        if flags.Hitsounds and flags.HitsoundSelect and Cheat.Globals.HitSoundIds[flags.HitsoundSelect] then
            local sound = Instance.new("Sound")
            sound.SoundId = Cheat.Globals.HitSoundIds[flags.HitsoundSelect]
            sound.Volume = flags.HitsoundVolume
            sound.PlayOnRemove = true
            sound.Parent = workspace
            sound:Destroy()
        end
    end)

    bullettracersbind.Event:Connect(function(position)
        if (not flags.BulletTracers) then
            return;
        end;

        local character = Client.Character;
        if (not character) then
            return;
        end;

        local head = character:FindFirstChild('Head');
        if (not head) then
            return;
        end;

        local att0 = Instance.new('Attachment');
        att0.Name = 'IgnoreMe';
        att0.WorldPosition = head.Position;
        att0.Parent = VMs;

        local att1 = Instance.new('Attachment');
        att1.Name = 'IgnoreMe';
        att1.WorldPosition = position;
        att1.Parent = VMs;

        local beam = Instance.new('Beam');
        beam.Name = 'IgnoreMe';
        beam.Attachment0 = att0;
        beam.Attachment1 = att1;

        beam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0)
        })

        beam.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, flags.BulletTracersColor.Color),
            ColorSequenceKeypoint.new(1, flags.BulletTracersColor.Color),
        });


        beam.Texture = "rbxassetid://128372145766358";
        beam.TextureLength = 30;
        beam.TextureMode = Enum.TextureMode.Wrap;
        beam.TextureSpeed = 2;

        beam.Width0 = 0.4;
        beam.Width1 = 0.4;

        beam.FaceCamera = true;
        beam.LightEmission = 0;
        beam.LightInfluence = 0;
        beam.Brightness = 150;

        beam.Parent = VMs;

        local expiry = flags.BulletTracersDuration or 1;
        Debris:AddItem(att0, expiry);
        Debris:AddItem(att1, expiry);
        Debris:AddItem(beam, expiry);
    end)

    local CreateBlood = VFXModule.CreateBlood
    VFXModule.CreateBlood = LPH_NO_UPVALUES(function(self, hit, position)
        local tb = debug.traceback();

        if not tb:find("ReplicatedStorage.Modules.VFXModule:153 function HitVFX") then
            hitnotificationsbind:Fire(hit, hit.Parent)
            hitsoundsbind:Fire()
            bullettracersbind:Fire(position)
        end

        return CreateBlood(self, hit, position)
    end);

    local CreateHole = VFXModule.CreateHole
    VFXModule.CreateHole = LPH_NO_UPVALUES(function(self, hit, position, normal, material, item, impactOnly)
        local tb = debug.traceback();

        if not tb:find("ReplicatedStorage.Modules.VFXModule:153 function HitVFX") then
            bullettracersbind:Fire(position)
        end

        return CreateHole(self, hit, position, normal, material, item, impactOnly)
    end);

    local CreateExplosion = VFXModule.CreateExplosion
    VFXModule.CreateExplosion = LPH_NO_UPVALUES(function(...)
        local Arguments = {...};

        local Type = tostring(Arguments[5]);
        local CFrame = Arguments[2];

        task.spawn(function() RaidEvent:Fire(Type, CFrame) end)

        return CreateExplosion(...)
    end);

    local LastPredictionPos
    local CreateProjectile = VFXModule.CreateProjectile
    VFXModule.CreateProjectile = LPH_NO_UPVALUES(function(self, ...)
        local Args = {...}

        local Traceback = debug.traceback();
        if Traceback:find("ViewmodelController") and Args[1].StepFunction ~= "FakeStepFunc" and Args[1].HitFunction ~= "FakeHitFunc" and not tostring(Args[1].HitFunction):find("Ignore") then
            local now = tick()

            if flags.ForcePenetration then
                for _, v in ipairs(workspace:GetChildren()) do
                    if not v:IsA('Folder') then
                        continue
                    end

                    if v.Name == 'Military' or v.Name == 'Events' then
                        continue
                    end

                    local skip = false
                    for _, c in ipairs(v:GetChildren()) do
                        if c:IsA('Model') and (
                            c.Name == 'Soldier'
                            or c.Name == 'Brutus'
                            or c.Name == 'Bruno'
                            or c.Name == 'Boris'
                            or c.Name == 'BTR'
                        ) then
                            skip = true
                            break
                        end
                    end

                    if not skip then
                        table.insert(Args[1].Filters, v)
                    end
                end
                table.insert(Args[1].Filters, workspace.Terrain);
            end;

            Cheat.Globals.ShouldHit = ((math.floor(Random.new():NextNumber(0, 1) * 100) / 100) <= (flags.HitChance / 100))
            local isvalidstack3 = isvalidlevel(3)
            local isvalidstack2 = isvalidlevel(2)
            local stacklevel = isvalidstack3 and 3 or isvalidstack2 and 2

            if (stacklevel and Targeting.TargetPart and Client.Character) then
                LastPredictionPos = nil
                local HitFunction = Args[1].HitFunction;
                local startPos = Args[1].Position or Args[1].PositionFirst or Camera.CFrame.Position;
                local manipPos = Targeting.ManipulatedPosition
                local targetPos = Targeting.TargetPart and Targeting.TargetPart.Position

                -- if flags.InstantBullet then
                --     Args[1].Speed = 9e9
                --     Args[1].Gravity = 0
                -- end

                local gun = getgun(Client.Character)
                local oldspeed = Args[1].Speed
                if gun and ToolInfo[gun] and Cheat.Globals.ClientCharacter and Cheat.Globals.ClientCharacter:FindFirstChild("InventoryController") and Cheat.Globals.ClientCharacter:FindFirstChild("ViewmodelController") then
                    local InventoryController = Cheat.Globals.ClientCharacter.InventoryController
                    local ViewmodelController = Cheat.Globals.ClientCharacter.ViewmodelController
                    local v376 = InventoryController.Fetch:Invoke();
                    local v377;
                    if not v376 then
                        v377 = nil;
                    else
                        local l_Toolbar_5 = v376.Toolbar;
                        if not l_Toolbar_5 then
                            v377 = nil;
                        else
                            local v379 = l_Toolbar_5[ViewmodelController:GetAttribute("Equipped")];
                            v377 = false;
                            if v379 ~= nil then
                                v377 = false;
                                if v379 ~= 0 then
                                    v377 = v379;
                                end;
                            end;
                        end;
                    end;

                    if v377 then
                        v376 = v377.Ammo;
                        v382 = ItemsModule[v377.ID];
                    end;
                    if v376 then
                        v381 = ItemsModule[v376.ID].AmmoStats;
                    end;

                    local bullet = ToolInfo[gun].Bullet
                    oldspeed = bullet.Speed * (v381.SpeedMult or 1)
                end

                local Speed, Gravity = Args[1].Speed, Args[1].Gravity
                local Distance = (Camera.CFrame.Position - targetPos).Magnitude
                local TimeToHit = Distance / oldspeed

                local G = Gravity * -196.2
                local Drop = -0.5 * G * TimeToHit * TimeToHit
                if tostring(Drop):find("nan") then
                    Drop = 0
                end

                LastPredictionPos = Vector3.new(0, Drop, 0)

                local Stack = debug.getstack(stacklevel);
                local CameraIndex, HRPIndex, FlashIndex, MouseIndex
                local CameraValue, HRPValue, FlashValue, MouseValue

                for i = 1, 100 do
                    local v = rawget(Stack, i)
                    if v then
                        local t = typeof(v)
                        if t == "CFrame" and not CameraValue then
                            local ok, p = pcall(function()
                                return v.p
                            end)
                            if ok and typeof(p) == "Vector3" then
                                CameraValue = v
                                CameraIndex = i
                            end
                        elseif t == "CFrame" and CameraValue and not HRPValue and v ~= CameraValue then
                            local ok, p = pcall(function()
                                return v.p
                            end)
                            if ok and typeof(p) == "Vector3" then
                                HRPValue = v
                                HRPIndex = i
                            end
                        elseif t == "Vector3" and not FlashValue then
                            FlashValue = v
                            FlashIndex = i
                        elseif t == "Vector3" and FlashValue and v ~= FlashValue and not MouseValue then
                            MouseValue = v
                            MouseIndex = i
                        end
                    end
                end

                if CameraValue and HRPValue and FlashValue and MouseValue and Targeting.TargetPart and Targeting.TargetPart.Position and LastPredictionPos then
                    local finalTarget = Targeting.TargetPart and Targeting.TargetPart.Position
                    if LastPredictionPos then
                        finalTarget = finalTarget + LastPredictionPos
                    end

                    local camPos = CameraValue.p
                    local hrpPos = HRPValue.p
                    local newFlash = CFrame.new(FlashValue, finalTarget).p

                    if manipPos then
                        local offC = camPos - FlashValue
                        local offH = hrpPos - FlashValue
                        local newCam = manipPos + offC
                        local newHrp = manipPos + offH
                        CameraValue = CFrame.new(newCam, finalTarget)
                        HRPValue = CFrame.new(newHrp, finalTarget)
                        newFlash = manipPos
                    else
                        CameraValue = CFrame.new(camPos, finalTarget)
                        HRPValue = CFrame.new(hrpPos, finalTarget)
                    end
                    debug.setstack(stacklevel, CameraIndex, CameraValue)
                    debug.setstack(stacklevel, HRPIndex, HRPValue)
                    debug.setstack(stacklevel, FlashIndex, newFlash)
                    debug.setstack(stacklevel, MouseIndex, finalTarget)
                end
            end;

            if (Args[1]['Terminate']) then
                Args[1]['Terminate'] = nil;
            end;

            if Targeting.TargetPart and Cheat.Globals.ShouldHit then
                local p = Targeting.TargetPart
                local hit = p and p.Position
                if p and hit then
                    local origin = Args[1].Position
                    local dir = (hit - origin).Unit
                    local cp = CFrame.new(origin, hit).Position
                    if Targeting.ManipulatedPosition or Targeting.ManipPos then
                        local mp = Targeting.ManipulatedPosition or Targeting.ManipPos
                        dir = (hit - mp).Unit
                        cp = CFrame.new(mp, hit).p
                    end
                    Args[1].Position = cp
                    if Args[1].PositionFirst then
                        Args[1].PositionFirst = cp
                    end
                    Args[1].DirectionFirst = dir
                    Args[1].Direction = dir
                end
            end
        end;

        return CreateProjectile(self, unpack(Args));
    end);

    local UpdateChar = LPH_NO_VIRTUALIZE(function()
        local character = Client.Character or Client.CharacterAdded:Wait()
        Cheat.Globals.ClientCharacter = character

        local hum = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid')
        local InventoryController = character:WaitForChild('InventoryController')
        local EquipArmor = InventoryController:WaitForChild('EquipArmor')

        for _, conn in getconnections(EquipArmor.Event) do
            local f = conn.Function
            if not f then continue end
            for _, v in debug.getupvalues(f) do
                if type(v) ~= 'function' then continue end
                local Constants = debug.getconstants(v)
                if Constants[1] == "ArmorEquip" and Constants[5] == "GetAttribute" then
                    if flags.InstantLoot then
                        debug.setconstant(v, 19, 0)
                        debug.setconstant(v, 20, 0)
                        debug.setconstant(v, 21, 0)
                    end;
                    table.insert(Cheat.Globals.QuickStackFunctions, v)
                end
            end
        end

        for _, c in getconnections(hum.StateChanged) do
            local fn = c.Function
            if type(fn) == 'function' then
                local i = debug.getinfo(fn)
                if i and i.short_src and i.short_src:find('ViewmodelController') then
                    local Old; Old = hookfunction(fn, function(oldState, newState, ...)
                        if flags.NoGrounded then
                            oldState = Enum.HumanoidStateType.Running
                            newState = Enum.HumanoidStateType.Running
                        end
                        local s, r = pcall(Old, oldState, newState, ...)
                        if s then
                            return r
                        end
                        return nil
                    end)
                end
            else
                c:Disconnect()
            end
        end
    end);

    UpdateChar();
    Client.CharacterAdded:Connect(UpdateChar);
   end
end
