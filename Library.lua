local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local Lighting = game:GetService('Lighting');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();
local Environment = getgenv();

-- Re-executing the library used to stack another full set of input,
-- RenderStepped, player, glow, and blur connections. Cleanly unload the
-- previous Linoria instance before constructing the replacement.
local PreviousLibrary = rawget(Environment, 'Library');
if type(PreviousLibrary) == 'table'
    and typeof(PreviousLibrary.ScreenGui) == 'Instance'
    and type(PreviousLibrary.Unload) == 'function'
then
    pcall(function()
        PreviousLibrary:Unload();
    end);
end;

Environment.Library = nil;

for _, Effect in next, Lighting:GetChildren() do
    if Effect:IsA('BlurEffect') and Effect.Name == 'LinoriaModifiedBlur' then
        Effect:Destroy();
    end;
end;

local StaleScreenGui = CoreGui:FindFirstChild('LinoriaModifiedUI');
if StaleScreenGui then
    StaleScreenGui:Destroy();
end;

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.Name = 'LinoriaModifiedUI';
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.IgnoreGuiInset = true;
ScreenGui.DisplayOrder = 1000;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    -- Tuned for the compact square/pixel dashboard style used by the example.
    -- Existing scripts can still override these values or use ThemeManager.
    FontColor = Color3.fromRGB(237, 237, 237);
    MainColor = Color3.fromRGB(24, 24, 24);
    BackgroundColor = Color3.fromRGB(16, 16, 16);
    AccentColor = Color3.fromRGB(213, 139, 166);
    OutlineColor = Color3.fromRGB(52, 52, 52);
    IconColor = Color3.fromRGB(255, 255, 255);
    RiskColor = Color3.fromRGB(255, 50, 50),

    LucideVersion = '1.30.0';
    LucideFolder = 'assets/lucide/png-white-256';
    LucideDownloadBaseUrl = 'https://raw.githubusercontent.com/dissering/linoria-modified/main/assets/lucide/png-white-256/';
    LucideAttemptedDownloads = {};
    LucideAliases = {
        combat = 'swords';
        visuals = 'eye';
        world = 'radar';
        players = 'users-round';
        console = 'terminal';
        theme = 'palette';
        security = 'shield-check';
        interface = 'monitor-cog';
        input = 'mouse-pointer-2';
    };

    Black = Color3.new(0, 0, 0);
    -- Proggy Clean is loaded through FontFace when executor custom assets are
    -- available. Code is the closest sharp monospace fallback for measurement
    -- and executors that do not expose custom-font APIs.
    Font = Enum.Font.Code;
    FontFace = nil;
    FontFolder = 'assets/fonts';
    FontFile = 'assets/fonts/ProggyClean.ttf';
    FontDownloadUrl = 'https://raw.githubusercontent.com/dissering/linoria-modified/main/assets/fonts/ProggyClean.ttf';

    OpenedFrames = {};
    DependencyBoxes = {};
    BackgroundEffects = {};
    AccentGradients = {};
    SurfaceGradients = {};
    GlowEffects = {};
    SnowExclusions = {};
    RainbowAccent = false;
    RainbowSpeed = 0.085;
    RainbowSaturation = 0.86;
    RainbowValue = 1;
    CornersEnabled = false;

    Signals = {};
    ScreenGui = ScreenGui;
};

local PopupBlocker = Instance.new('TextButton');
PopupBlocker.Name = 'PopupBlocker';
PopupBlocker.Active = true;
PopupBlocker.AutoButtonColor = false;
PopupBlocker.BackgroundTransparency = 1;
PopupBlocker.BorderSizePixel = 0;
PopupBlocker.Modal = false;
PopupBlocker.Size = UDim2.fromScale(1, 1);
PopupBlocker.Text = '';
PopupBlocker.Visible = false;
PopupBlocker.ZIndex = 13;
PopupBlocker.Parent = ScreenGui;

Library.PopupBlocker = PopupBlocker;

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    Hue = (Hue + (Delta * Library.RainbowSpeed)) % 1

    Library.CurrentRainbowHue = Hue;
    Library.CurrentRainbowColor = Color3.fromHSV(
        Hue,
        Library.RainbowSaturation,
        Library.RainbowValue
    );

    if RainbowStep >= (1 / 30) then
        RainbowStep = 0

        if Library.RainbowAccent and Library.UpdateDynamicAccent then
            Library.AccentColor = Library.CurrentRainbowColor;
            Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);
            Library:UpdateDynamicAccent();
        end;
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();

    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;

    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();

    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;

    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    
    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;

    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);

    if not success then
        local _, i = event:find(":%d+: ");

        if not i then
            return Library:Notify(event);
        end;

        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;

    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;

    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    if Library.FontFace
        and (_Instance:IsA('TextLabel')
            or _Instance:IsA('TextButton')
            or _Instance:IsA('TextBox'))
    then
        pcall(function()
            _Instance.FontFace = Library.FontFace;
        end);
    end;

    return _Instance;
end;

function Library:Tween(Instance, Properties, Duration, EasingStyle, EasingDirection)
    if not Instance then
        return;
    end;

    local TweenInfoObject = TweenInfo.new(
        Duration or 0.22,
        EasingStyle or Enum.EasingStyle.Quint,
        EasingDirection or Enum.EasingDirection.Out
    );

    local Tween = TweenService:Create(Instance, TweenInfoObject, Properties);
    Tween:Play();

    return Tween;
end;

function Library:IsPointerInput(Input)
    return Input
        and (Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch);
end;

function Library:GetPointerPosition(Input)
    if Input and Input.UserInputType == Enum.UserInputType.Touch then
        return Vector2.new(Input.Position.X, Input.Position.Y);
    end;

    return Vector2.new(Mouse.X, Mouse.Y);
end;

function Library:IsPointerDown(Input)
    if not Input then
        return false;
    end;

    if Input.UserInputType == Enum.UserInputType.Touch then
        return Input.UserInputState ~= Enum.UserInputState.End
            and Input.UserInputState ~= Enum.UserInputState.Cancel;
    end;

    return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1);
end;

function Library:AddCorner(Instance, Radius, Force)
    if (not Library.CornersEnabled and not Force) or not Instance or not Radius or Radius <= 0 then
        return;
    end;

    return Library:Create('UICorner', {
        CornerRadius = UDim.new(0, Radius);
        Parent = Instance;
    });
end;

function Library:NormalizeLucideIconName(Name)
    if type(Name) ~= 'string' then
        return nil;
    end;

    Name = Name:gsub('^%s+', ''):gsub('%s+$', '');
    if Name == '' then
        return nil;
    end;

    local HadSeparator = Name:find('[-_%s]') ~= nil;

    Name = Name:gsub('(%u)(%u%l)', '%1-%2');
    Name = Name:gsub('(%l)(%u)', '%1-%2');

    if not HadSeparator then
        Name = Name:gsub('(%a)(%d)', '%1-%2');
        Name = Name:gsub('(%d)(%a)', '%1-%2');
    end;
    Name = Name:gsub('[%s_]+', '-');
    Name = Name:gsub('%-+', '-'):lower();

    if not Name:match('^[%w%-]+$') then
        return nil;
    end;

    return Library.LucideAliases[Name] or Name;
end;

function Library:SetLucideFolder(Folder)
    assert(type(Folder) == 'string' and Folder ~= '', 'SetLucideFolder expects a non-empty folder');
    Library.LucideFolder = Folder:gsub('[\\/]+$', '');
    return Library;
end;

function Library:SetLucideDownloadBaseUrl(Url)
    assert(type(Url) == 'string' and Url ~= '', 'SetLucideDownloadBaseUrl expects a non-empty URL');
    Library.LucideDownloadBaseUrl = Url:gsub('/+$', '') .. '/';
    return Library;
end;

function Library:EnsureLucideFolder()
    if type(makefolder) ~= 'function' then
        return;
    end;

    local Current = '';

    for Segment in string.gmatch(Library.LucideFolder, '[^/\\]+') do
        Current = Current == '' and Segment or Current .. '/' .. Segment;
        pcall(makefolder, Current);
    end;
end;

function Library:EnsureAssetFolder(Folder)
    if type(makefolder) ~= 'function' or type(Folder) ~= 'string' then
        return;
    end;

    local Current = '';

    for Segment in string.gmatch(Folder, '[^/\\]+') do
        Current = Current == '' and Segment or Current .. '/' .. Segment;
        pcall(makefolder, Current);
    end;
end;

function Library:LoadCustomFont()
    if type(getcustomasset) ~= 'function' then
        return false;
    end;

    local Path = Library.FontFile;
    local Exists = false;

    if type(isfile) == 'function' then
        local Success, Result = pcall(isfile, Path);
        Exists = Success and Result == true;
    end;

    if not Exists and type(writefile) == 'function' then
        local Success, Data = pcall(function()
            return game:HttpGet(Library.FontDownloadUrl);
        end);

        if Success and type(Data) == 'string' and #Data > 1024 then
            local Header = Data:sub(1, 4);
            local IsFont = Header == '\0\1\0\0'
                or Header == 'OTTO'
                or Header == 'true'
                or Header == 'typ1';

            if IsFont then
                Library:EnsureAssetFolder(Library.FontFolder);
                Exists = pcall(writefile, Path, Data);
            end;
        end;
    end;

    local AssetSuccess, Asset = pcall(getcustomasset, Path);
    if not AssetSuccess or type(Asset) ~= 'string' or Asset == '' then
        return false;
    end;

    local FontSuccess, CustomFont = pcall(function()
        return Font.new(Asset, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    end);

    if not FontSuccess then
        return false;
    end;

    Library.FontFace = CustomFont;
    return true;
end;

function Library:GetLucideIconPath(Name)
    local Normalized = Library:NormalizeLucideIconName(Name);
    if not Normalized then
        return nil;
    end;

    return string.format('%s/%s.png', Library.LucideFolder, Normalized), Normalized;
end;

function Library:DownloadLucideIcon(Name)
    local Path, Normalized = Library:GetLucideIconPath(Name);

    if not Path or Library.LucideAttemptedDownloads[Path] then
        return;
    end;

    Library.LucideAttemptedDownloads[Path] = true;

    if type(writefile) ~= 'function' or not game then
        return;
    end;

    local Success, Data = pcall(function()
        return game:HttpGet(Library.LucideDownloadBaseUrl .. Normalized .. '.png');
    end);

    if not Success
        or type(Data) ~= 'string'
        or #Data < 24
        or Data:sub(1, 8) ~= '\137PNG\r\n\26\n' then

        return;
    end;

    Library:EnsureLucideFolder();
    pcall(writefile, Path, Data);
end;

function Library:GetLucideIcon(Name)
    local Path = Library:GetLucideIconPath(Name);

    if not Path or type(getcustomasset) ~= 'function' then
        return nil;
    end;

    local Success, Asset = pcall(getcustomasset, Path);
    if Success and type(Asset) == 'string' and Asset ~= '' then
        return Asset;
    end;

    Library:DownloadLucideIcon(Name);
    Success, Asset = pcall(getcustomasset, Path);

    if Success and type(Asset) == 'string' and Asset ~= '' then
        return Asset;
    end;

    return nil;
end;

-- Accepts an rbxasset/rbxassetid URL, local executor path, or bare Lucide name.
function Library:ResolveAsset(Asset)
    if type(Asset) ~= 'string' or Asset == '' then
        return Asset;
    end;

    if Asset:match('^rbxasset://') or Asset:match('^rbxassetid://') or Asset:match('^https?://') then
        return Asset;
    end;

    local IsBareIconName = not Asset:find('[/\\]') and not Asset:find('%.');
    if IsBareIconName then
        return Library:GetLucideIcon(Asset);
    end;

    if type(getcustomasset) == 'function' then
        local Success, Resolved = pcall(getcustomasset, Asset);

        if Success and type(Resolved) == 'string' and Resolved ~= '' then
            return Resolved;
        end;
    end;

    return Asset;
end;

Library:LoadCustomFont();

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });

    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);

    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;

    local Dragging = false;
    local DragInput;
    local Moving = false;
    local GrabOffset = Vector2.new(0, 0);
    local TargetPosition = Instance.Position;

    local function GetPointerPosition(Input)
        if Input and Input.UserInputType == Enum.UserInputType.Touch then
            return Vector2.new(Input.Position.X, Input.Position.Y);
        end;

        return Vector2.new(Mouse.X, Mouse.Y);
    end;

    Instance.InputBegan:Connect(function(Input)
        local IsPointerInput = Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch;

        if IsPointerInput and not Dragging then
            local AbsolutePosition = Instance.AbsolutePosition;
            local AbsoluteSize = Instance.AbsoluteSize;
            local PointerPosition = GetPointerPosition(Input);

            GrabOffset = Vector2.new(
                PointerPosition.X - AbsolutePosition.X,
                PointerPosition.Y - AbsolutePosition.Y
            );

            if GrabOffset.Y > (Cutoff or 40) then
                return;
            end;

            -- Convert the current absolute position into the parent's local
            -- coordinate space before dragging, preserving the exact grab point.
            local ParentPosition = Instance.Parent.AbsolutePosition;
            TargetPosition = UDim2.fromOffset(
                AbsolutePosition.X - ParentPosition.X + (AbsoluteSize.X * Instance.AnchorPoint.X),
                AbsolutePosition.Y - ParentPosition.Y + (AbsoluteSize.Y * Instance.AnchorPoint.Y)
            );
            Instance.Position = TargetPosition;

            Dragging = true;
            DragInput = Input;
            Moving = false;

            local EndConnection;
            EndConnection = Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    if DragInput == Input then
                        Dragging = false;
                        DragInput = nil;
                    end;

                    EndConnection:Disconnect();
                end;
            end);
        end;
    end);

    Library:GiveSignal(RenderStepped:Connect(function(Delta)
        if Dragging then
            local AbsoluteSize = Instance.AbsoluteSize;
            local ScreenSize = ScreenGui.AbsoluteSize;
            local ScreenPosition = ScreenGui.AbsolutePosition;
            local ParentPosition = Instance.Parent.AbsolutePosition;

            if ScreenSize.X <= 0 or ScreenSize.Y <= 0 then
                ScreenSize = workspace.CurrentCamera.ViewportSize;
            end;

            local PointerPosition = GetPointerPosition(DragInput);
            local Left = math.clamp(
                PointerPosition.X - GrabOffset.X,
                ScreenPosition.X + 4,
                math.max(ScreenPosition.X + 4, ScreenPosition.X + ScreenSize.X - AbsoluteSize.X - 4)
            );
            local Top = math.clamp(
                PointerPosition.Y - GrabOffset.Y,
                ScreenPosition.Y + 4,
                math.max(ScreenPosition.Y + 4, ScreenPosition.Y + ScreenSize.Y - AbsoluteSize.Y - 4)
            );

            TargetPosition = UDim2.fromOffset(
                Left - ParentPosition.X + (AbsoluteSize.X * Instance.AnchorPoint.X),
                Top - ParentPosition.Y + (AbsoluteSize.Y * Instance.AnchorPoint.Y)
            );
            Instance.Position = TargetPosition;
            Moving = false;
        end;

        if Moving then
            local Alpha = 1 - math.exp(-26 * Delta);
            Instance.Position = Instance.Position:Lerp(TargetPosition, Alpha);

            if not Dragging
                and math.abs(Instance.Position.X.Offset - TargetPosition.X.Offset) < 0.5
                and math.abs(Instance.Position.Y.Offset - TargetPosition.Y.Offset) < 0.5 then

                Instance.Position = TargetPosition;
                Moving = false;
            end;
        end;
    end));
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    if type(InfoStr) ~= 'string' or InfoStr == '' or not HoverInstance then
        return;
    end;

    if not Library.Tooltip then
        local Tooltip = Library:Create('CanvasGroup', {
            AnchorPoint = Vector2.new(0, 0);
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            GroupTransparency = 1;
            Position = UDim2.fromOffset(0, 0);
            Size = UDim2.fromOffset(80, 28);
            Visible = false;
            ZIndex = 300;
            Parent = Library.ScreenGui;
        });

        Library:AddCorner(Tooltip, 6, true);
        Library:AddSurfaceGradient(Tooltip, -90);

        local TooltipStroke = Library:Create('UIStroke', {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = Library.OutlineColor;
            Thickness = 1;
            Transparency = 0.2;
            Parent = Tooltip;
        });

        Library:AddToRegistry(TooltipStroke, {
            Color = 'OutlineColor';
        });

        local TooltipScale = Library:Create('UIScale', {
            Scale = 0.96;
            Parent = Tooltip;
        });

        local TooltipLabel = Library:CreateLabel({
            Position = UDim2.fromOffset(8, 5);
            Size = UDim2.new(1, -16, 1, -10);
            TextSize = 12;
            TextWrapped = true;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Center;
            ZIndex = 301;
            Parent = Tooltip;
        });

        local TooltipCaret = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Rotation = 45;
            Size = UDim2.fromOffset(8, 8);
            ZIndex = 300;
            Parent = Tooltip;
        });

        Library:AddToRegistry(TooltipCaret, {
            BackgroundColor3 = 'MainColor';
        });

        Library.Tooltip = Tooltip;
        Library.TooltipLabel = TooltipLabel;
        Library.TooltipScale = TooltipScale;
        Library.TooltipCaret = TooltipCaret;

        local function UpdateTooltipPosition()
            if not Tooltip.Visible or not Library.TooltipOwner then
                return;
            end;

            local ScreenSize = Library.ScreenGui.AbsoluteSize;
            if ScreenSize.X <= 0 or ScreenSize.Y <= 0 then
                ScreenSize = workspace.CurrentCamera.ViewportSize;
            end;

            local TooltipSize = Tooltip.AbsoluteSize;
            local OwnerPosition = Library.TooltipOwner.AbsolutePosition;
            local OwnerSize = Library.TooltipOwner.AbsoluteSize;
            local ScreenPosition = Library.ScreenGui.AbsolutePosition;
            local OwnerX = OwnerPosition.X - ScreenPosition.X;
            local OwnerY = OwnerPosition.Y - ScreenPosition.Y;
            local TargetX = OwnerX + (OwnerSize.X * 0.5);
            local AboveY = OwnerY - TooltipSize.Y - 6;
            local ShowingAbove = AboveY >= 8;
            local X = math.clamp(
                TargetX - (TooltipSize.X * 0.5),
                8,
                math.max(8, ScreenSize.X - TooltipSize.X - 8)
            );
            local Y = ShowingAbove and AboveY or (OwnerY + OwnerSize.Y + 6);

            Y = math.clamp(Y, 8, math.max(8, ScreenSize.Y - TooltipSize.Y - 8));
            Tooltip.Position = UDim2.fromOffset(X, Y);

            TooltipCaret.Position = UDim2.fromOffset(
                math.clamp(TargetX - X, 12, math.max(12, TooltipSize.X - 12)),
                ShowingAbove and TooltipSize.Y or 0
            );
        end;

        Library.UpdateTooltipPosition = UpdateTooltipPosition;
        Library:GiveSignal(RenderStepped:Connect(UpdateTooltipPosition));
    end;

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return;
        end;

        local NaturalWidth = Library:GetTextBounds(InfoStr, Library.Font, 12);
        local Width = math.clamp(NaturalWidth + 16, 64, 240);
        local _, WrappedHeight = Library:GetTextBounds(
            InfoStr,
            Library.Font,
            12,
            Vector2.new(Width - 16, 1000)
        );

        Library.TooltipOwner = HoverInstance;
        Library.TooltipLabel.Text = InfoStr;
        Library.Tooltip.Size = UDim2.fromOffset(Width, math.max(26, WrappedHeight + 10));
        Library.Tooltip.GroupTransparency = 1;
        Library.TooltipScale.Scale = 0.96;
        Library.Tooltip.Visible = true;
        Library.UpdateTooltipPosition();

        Library:Tween(Library.Tooltip, {
            GroupTransparency = 0;
        }, 0.14, Enum.EasingStyle.Quart);
        Library:Tween(Library.TooltipScale, {
            Scale = 1;
        }, 0.14, Enum.EasingStyle.Quart);
    end);

    HoverInstance.MouseLeave:Connect(function()
        if Library.TooltipOwner ~= HoverInstance then
            return;
        end;

        Library.TooltipOwner = nil;
        Library:Tween(Library.Tooltip, {
            GroupTransparency = 1;
        }, 0.1, Enum.EasingStyle.Quad);
        Library:Tween(Library.TooltipScale, {
            Scale = 0.97;
        }, 0.1, Enum.EasingStyle.Quad);

        task.delay(0.1, function()
            if not Library.TooltipOwner then
                Library.Tooltip.Visible = false;
            end;
        end);
    end);
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    local function Apply(PropertiesToApply)
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesToApply do
            local Value = Library[ColorIdx] or ColorIdx;

            if typeof(Value) == 'Color3' then
                Library:Tween(Instance, { [Property] = Value }, 0.14, Enum.EasingStyle.Quad);
            else
                Instance[Property] = Value;
            end;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end;

    HighlightInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return;
        end;

        Apply(Properties);
    end)

    HighlightInstance.MouseLeave:Connect(function()
        Apply(PropertiesDefault);
    end)
end;

function Library:MouseIsOverOpenedFrame(Input)
    local PointerPosition = Library:GetPointerPosition(Input);

    for Frame, _ in next, Library.OpenedFrames do
        if not Frame or not Frame.Parent or not Frame.Visible then
            Library.OpenedFrames[Frame] = nil;
            continue;
        end;

        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

        if PointerPosition.X >= AbsPos.X and PointerPosition.X <= AbsPos.X + AbsSize.X
            and PointerPosition.Y >= AbsPos.Y and PointerPosition.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame, Input)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    local PointerPosition = Library:GetPointerPosition(Input);

    if PointerPosition.X >= AbsPos.X and PointerPosition.X <= AbsPos.X + AbsSize.X
        and PointerPosition.Y >= AbsPos.Y and PointerPosition.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;

function Library:GetLighterColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, math.clamp(V * 1.2, 0, 1));
end;

function Library:GetSurfaceBaseColor()
    return Library:GetLighterColor(Library.MainColor);
end;

function Library:GetSurfaceGradient()
    local Main = Library.MainColor;
    local Dark = Library:GetDarkerColor(Main);
    local Light = Library:GetLighterColor(Main);
    local Base = Library:GetSurfaceBaseColor();

    local function Normalize(Color)
        return Color3.new(
            math.clamp(Color.R / math.max(Base.R, 1 / 255), 0, 1),
            math.clamp(Color.G / math.max(Base.G, 1 / 255), 0, 1),
            math.clamp(Color.B / math.max(Base.B, 1 / 255), 0, 1)
        );
    end;

    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Normalize(Dark:Lerp(Main, 0.35)));
        ColorSequenceKeypoint.new(0.52, Normalize(Main));
        ColorSequenceKeypoint.new(1, Normalize(Light:Lerp(Main, 0.55)));
    });
end;

function Library:AddSurfaceGradient(Instance, Rotation)
    if not Instance then
        return;
    end;

    Instance.BackgroundColor3 = Library:GetSurfaceBaseColor();

    local Gradient = Library:Create('UIGradient', {
        Color = Library:GetSurfaceGradient();
        Rotation = Rotation or -90;
        Parent = Instance;
    });

    table.insert(Library.SurfaceGradients, {
        Gradient = Gradient;
        Instance = Instance;
    });

    return Gradient;
end;

function Library:UpdateSurfaceGradients()
    for Index = #Library.SurfaceGradients, 1, -1 do
        local Data = Library.SurfaceGradients[Index];
        local Instance = Data and Data.Instance;
        local Gradient = Data and Data.Gradient;

        if not Instance or not Instance.Parent or not Gradient or not Gradient.Parent then
            table.remove(Library.SurfaceGradients, Index);
        else
            Instance.BackgroundColor3 = Library:GetSurfaceBaseColor();
            Gradient.Color = Library:GetSurfaceGradient();
        end;
    end;
end;

function Library:GetInactiveIconColor()
    return Library.FontColor:Lerp(Library.MainColor, 0.45);
end;

function Library:GetRainbowGradient()
    local Phase = Library.CurrentRainbowHue or 0;
    local Points = {};

    for Index = 0, 6 do
        local Position = Index / 6;
        table.insert(Points, ColorSequenceKeypoint.new(
            Position,
            Color3.fromHSV(
                (Phase + Position) % 1,
                Library.RainbowSaturation,
                Library.RainbowValue
            )
        ));
    end;

    return ColorSequence.new(Points);
end;

function Library:GetAccentGradient(RainbowOnly)
    if Library.RainbowAccent then
        return Library:GetRainbowGradient();
    end;

    if RainbowOnly then
        return ColorSequence.new(Color3.new(1, 1, 1));
    end;

    local Accent = Library.AccentColor;
    local Dark = Library:GetDarkerColor(Accent);
    local Bright = Accent:Lerp(Color3.new(1, 1, 1), 0.5);

    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Dark);
        ColorSequenceKeypoint.new(0.28, Accent);
        ColorSequenceKeypoint.new(0.5, Bright);
        ColorSequenceKeypoint.new(0.72, Accent);
        ColorSequenceKeypoint.new(1, Dark);
    });
end;

function Library:AddAccentGradient(Gradient, RainbowOnly)
    if not Gradient then
        return;
    end;

    local Data = {
        Gradient = Gradient;
        RainbowOnly = RainbowOnly == true;
    };

    Gradient.Color = Library:GetAccentGradient(Data.RainbowOnly);
    table.insert(Library.AccentGradients, Data);
    return Gradient;
end;

function Library:UpdateAccentGradients()
    for Index = #Library.AccentGradients, 1, -1 do
        local Data = Library.AccentGradients[Index];
        local Gradient = Data and (Data.Gradient or Data);

        if not Gradient or not Gradient.Parent then
            table.remove(Library.AccentGradients, Index);
        else
            Gradient.Color = Library:GetAccentGradient(Data.RainbowOnly == true);
        end;
    end;
end;

function Library:UpdateDynamicAccent()
    for _, Object in next, Library.Registry do
        if Object.Instance and Object.Instance.Parent then
            for Property, ColorIdx in next, Object.Properties do
                if ColorIdx == 'AccentColor' then
                    Object.Instance[Property] = Library.AccentColor;
                elseif ColorIdx == 'AccentColorDark' then
                    Object.Instance[Property] = Library.AccentColorDark;
                end;
            end;
        end;
    end;

    Library:UpdateSurfaceGradients();
    Library:UpdateAccentGradients();
end;

function Library:SetRainbowAccent(Enabled)
    Library.RainbowAccent = Enabled == true;

    if Library.RainbowAccent then
        Library.AccentColor = Library.CurrentRainbowColor
            or Color3.fromHSV(0, Library.RainbowSaturation, Library.RainbowValue);
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);
    end;

    Library:UpdateDynamicAccent();
end;

function Library:AddGlow(Target, Info)
    if typeof(Target) ~= 'Instance' or not Target:IsA('GuiObject') then
        return;
    end;

    Info = type(Info) == 'table' and Info or {};

    local Padding = math.max(4, tonumber(Info.Padding) or 20);
    local Transparency = math.clamp(tonumber(Info.Transparency) or 0.76, 0, 1);
    local Enabled = Info.Enabled ~= false;
    local Holder = Library:Create('Frame', {
        Active = false;
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Name = 'LinoriaGlowHolder';
        Position = UDim2.fromOffset(0, 0);
        Size = UDim2.fromOffset(0, 0);
        Visible = false;
        ZIndex = math.max(0, Target.ZIndex - 1);
        Parent = ScreenGui;
    });

    local Image = Library:Create('ImageLabel', {
        Active = false;
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Image = Info.Image or 'http://www.roblox.com/asset/?id=18245826428';
        ImageColor3 = Library.AccentColor;
        ImageTransparency = Transparency;
        Name = 'LinoriaGlow';
        Position = UDim2.fromOffset(-Padding, -Padding);
        ScaleType = Enum.ScaleType.Slice;
        Size = UDim2.new(1, Padding * 2, 1, Padding * 2);
        SliceCenter = Rect.new(21, 21, 79, 79);
        ZIndex = Holder.ZIndex;
        Parent = Holder;
    });

    Library:AddToRegistry(Image, {
        ImageColor3 = function()
            return Library.RainbowAccent and Color3.new(1, 1, 1) or Library.AccentColor;
        end;
    }, true);

    local ImageGradient = Library:Create('UIGradient', {
        Rotation = 0;
        Parent = Image;
    });

    Library:AddAccentGradient(ImageGradient, true);

    local Scale = Library:Create('UIScale', {
        Scale = tonumber(Info.Scale) or 1;
        Parent = Holder;
    });

    local Glow = {
        Connections = {};
        Destroyed = false;
        Enabled = Enabled;
        Holder = Holder;
        Image = Image;
        ImageGradient = ImageGradient;
        Scale = Scale;
        Target = Target;
        Transparency = Transparency;
    };

    function Glow:Track(Connection)
        table.insert(self.Connections, Connection);
        return Connection;
    end;

    function Glow:Destroy()
        if self.Destroyed then
            return;
        end;

        self.Destroyed = true;
        Library.SnowExclusions[Target] = nil;

        for Index = #self.Connections, 1, -1 do
            local Connection = table.remove(self.Connections, Index);
            pcall(function()
                Connection:Disconnect();
            end);
        end;

        for Index = #Library.GlowEffects, 1, -1 do
            if Library.GlowEffects[Index] == self then
                table.remove(Library.GlowEffects, Index);
                break;
            end;
        end;

        if Holder.Parent then
            Holder:Destroy();
        end;
    end;

    function Glow:Sync()
        if self.Destroyed then
            return;
        end;

        if not Target.Parent then
            self:Destroy();
            return;
        end;

        local ScreenPosition = ScreenGui.AbsolutePosition;
        local TargetPosition = Target.AbsolutePosition;
        local TargetSize = Target.AbsoluteSize;

        Holder.Position = UDim2.fromOffset(
            math.floor(TargetPosition.X - ScreenPosition.X + 0.5),
            math.floor(TargetPosition.Y - ScreenPosition.Y + 0.5)
        );
        Holder.Size = UDim2.fromOffset(
            math.floor(TargetSize.X + 0.5),
            math.floor(TargetSize.Y + 0.5)
        );
        Holder.ZIndex = math.max(0, Target.ZIndex - 1);
        Image.ZIndex = Holder.ZIndex;
        Holder.Visible = self.Enabled
            and Target.Visible
            and TargetSize.X > 0
            and TargetSize.Y > 0;
    end;

    function Glow:SetEnabled(Value)
        self.Enabled = Value == true;
        self:Sync();
    end;

    function Glow:SetTransparency(Value, Duration)
        self.Transparency = math.clamp(tonumber(Value) or self.Transparency, 0, 1);

        if tonumber(Duration) and Duration > 0 then
            Library:Tween(Image, {
                ImageTransparency = self.Transparency;
            }, Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
        else
            Image.ImageTransparency = self.Transparency;
        end;
    end;

    Glow:Track(Target:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
        Glow:Sync();
    end));
    Glow:Track(Target:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        Glow:Sync();
    end));
    Glow:Track(Target:GetPropertyChangedSignal('Visible'):Connect(function()
        Glow:Sync();
    end));
    Glow:Track(Target:GetPropertyChangedSignal('ZIndex'):Connect(function()
        Glow:Sync();
    end));
    Glow:Track(Target.Destroying:Connect(function()
        Glow:Destroy();
    end));
    Glow:Track(Target.AncestryChanged:Connect(function(_, Parent)
        if not Parent then
            Glow:Destroy();
        else
            Glow:Sync();
        end;
    end));
    Glow:Track(ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        Glow:Sync();
    end));

    if Info.ExcludeSnow ~= false then
        Library.SnowExclusions[Target] = true;
    end;

    table.insert(Library.GlowEffects, Glow);
    task.defer(function()
        if Holder.Parent then
            Glow:Sync();
        end;
    end);
    return Glow;
end;

function Library:RefreshPopupBlocker()
    local HasOpenFrame = false;

    for Frame, _ in next, Library.OpenedFrames do
        if Frame and Frame.Parent and Frame.Visible then
            HasOpenFrame = true;
        else
            Library.OpenedFrames[Frame] = nil;
        end;
    end;

    PopupBlocker.Visible = HasOpenFrame;
    PopupBlocker.Modal = HasOpenFrame;
end;

function Library:OpenFrame(Frame)
    Library.OpenedFrames[Frame] = true;
    Library:RefreshPopupBlocker();
end;

function Library:CloseFrame(Frame)
    Library.OpenedFrames[Frame] = nil;
    Library:RefreshPopupBlocker();
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    -- TODO: Could have an 'active' list of objects
    -- where the active list only contains Visible objects.

    -- IMPL: Could setup .Changed events on the AddToRegistry function
    -- that listens for the 'Visible' propert being changed.
    -- Visible: true => Add to active list, and call UpdateColors function
    -- Visible: false => Remove from active list.

    -- The above would be especially efficient for a rainbow menu color or live color-changing.

    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;

    Library:UpdateSurfaceGradients();
    Library:UpdateAccentGradients();
end;

function Library:GiveSignal(Signal)
    -- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    if Library.Unloaded then
        return;
    end;

    Library.Unloaded = true;

    for Idx = #Library.GlowEffects, 1, -1 do
        local Glow = Library.GlowEffects[Idx];

        if Glow and type(Glow.Destroy) == 'function' then
            Glow:Destroy();
        else
            table.remove(Library.GlowEffects, Idx);
        end;
    end;

    -- Unload all of the signals
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        pcall(function()
            Connection:Disconnect()
        end)
    end

     -- Call our unload callback, maybe to undo some hooks etc
    if Library.OnUnload then
        Library.OnUnload()
    end

    for Idx = #Library.BackgroundEffects, 1, -1 do
        local Effect = table.remove(Library.BackgroundEffects, Idx);

        if Effect and Effect.Parent then
            Effect:Destroy();
        end;
    end;

    if ScreenGui.Parent then
        ScreenGui:Destroy()
    end

    if rawget(Environment, 'Library') == Library then
        Environment.Library = nil
    end

    if rawget(Environment, 'Toggles') == Toggles then
        Environment.Toggles = nil
    end

    if rawget(Environment, 'Options') == Options then
        Environment.Options = nil
    end
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};

do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        local AddonContainer = self.AddonContainer or ToggleLabel;
        -- local Container = self.Container;

        if self.ActivateInlineAddons then
            self:ActivateInlineAddons();
        end;

        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);

            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = AddonContainer;
        });

        Library:AddCorner(DisplayFrame, 4);

        -- Transparency image taken from https://github.com/matas3535/SplixPrivateDrawingLibrary/blob/main/Library.lua cus i'm lazy
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        Library:AddCorner(CheckerFrame, 4);

        -- 1/16/23
        -- Rewrote this to be placed inside the Library ScreenGui
        -- There was some issue which caused RelativeOffset to be way off
        -- Thus the color picker would never show

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            Active = true;
            BackgroundColor3 = Library.OutlineColor;
            BorderSizePixel = 0;
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });

        Library:AddToRegistry(PickerFrameOuter, {
            BackgroundColor3 = 'OutlineColor';
        });

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            ClipsDescendants = true;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        Library:AddCorner(PickerFrameOuter, 7);
        Library:AddCorner(PickerFrameInner, 6);

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });

        Library:AddCorner(SatVibMapOuter, 6);
        Library:AddCorner(SatVibMapInner, 5);

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });

        Library:AddCorner(SatVibMap, 5);

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });

        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });

        Library:AddCorner(HueSelectorOuter, 7);
        Library:AddCorner(HueSelectorInner, 6);

        local HueCursor = Library:Create('Frame', { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });

        Library:AddCorner(HueBoxOuter, 5);
        Library:AddCorner(HueBoxInner, 4);

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });

        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });

            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });

            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });

            TransparencyCursor = Library:Create('Frame', { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = ColorPicker.Title,--Info.Default;
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });


        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                Active = true;
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });

            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });

            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
                Library:OpenFrame(self.Container)
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
                Library:CloseFrame(self.Container)
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });

                Library:OnHighlight(Button, Button, 
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );

                Button.InputBegan:Connect(function(Input)
                    if not Library:IsPointerInput(Input) then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)


            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local SequenceTable = {};

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library:CloseFrame(Frame);
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library:OpenFrame(PickerFrameOuter);
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library:CloseFrame(PickerFrameOuter);
        end;

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                while Library:IsPointerDown(Input) do
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local PointerPosition = Library:GetPointerPosition(Input);
                    local MouseX = math.clamp(PointerPosition.X, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(PointerPosition.Y, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                while Library:IsPointerDown(Input) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local PointerPosition = Library:GetPointerPosition(Input);
                    local MouseY = math.clamp(PointerPosition.Y, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Library:IsPointerInput(Input) then
                    while Library:IsPointerDown(Input) do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local PointerPosition = Library:GetPointerPosition(Input);
                        local MouseX = math.clamp(PointerPosition.X, MinX, MaxX);

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));

                        ColorPicker:Display();

                        RenderStepped:Wait();
                    end;

                    Library:AttemptSave();
                end;
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;
                local PointerPosition = Library:GetPointerPosition(Input);

                if PointerPosition.X < AbsPos.X or PointerPosition.X > AbsPos.X + AbsSize.X
                    or PointerPosition.Y < (AbsPos.Y - 20 - 1) or PointerPosition.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide();
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container, Input) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local AddonContainer = self.AddonContainer or ToggleLabel;
        local Container = self.Container;

        if self.ActivateInlineAddons then
            self:ActivateInlineAddons();
        end;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle'; -- Always, Toggle, Hold
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };

        if KeyPicker.SyncToggleState and ParentObj.Type == 'Toggle' then
            KeyPicker.Toggled = ParentObj.Value;
        end

        local PickOuter = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 80, 0, 16);
            ZIndex = 6;
            Parent = AddonContainer;
        });

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });

        Library:AddCorner(PickOuter, 4);
        Library:AddCorner(PickInner, 3);

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 11;
            Text = Info.Default;
            TextWrapped = false;
            TextTruncate = Enum.TextTruncate.AtEnd;
            ZIndex = 8;
            Parent = PickInner;
        });

        local function UpdateDisplayLabel(Value)
            local Text = tostring(Value or 'None');
            local Width = Library:GetTextBounds(Text, Library.Font, 11);

            DisplayLabel.Text = Text;
            PickOuter.Size = UDim2.fromOffset(math.clamp(Width + 14, 38, 88), 16);
        end;

        UpdateDisplayLabel(Info.Default);

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModePopupHeight = (#Modes * 18) + 8;

        local ModeSelectOuter = Library:Create('CanvasGroup', {
            Active = true;
            AnchorPoint = Vector2.new(1, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            GroupTransparency = 1;
            Position = UDim2.fromOffset(0, 0);
            Size = UDim2.fromOffset(82, ModePopupHeight);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        });

        local function UpdateModePopupPosition()
            local PopupSize = ModeSelectOuter.AbsoluteSize;
            local ScreenSize = ScreenGui.AbsoluteSize;
            local PickPosition = PickOuter.AbsolutePosition;
            local PickSize = PickOuter.AbsoluteSize;

            if ScreenSize.X <= 0 or ScreenSize.Y <= 0 then
                ScreenSize = workspace.CurrentCamera.ViewportSize;
            end;

            local Right = math.clamp(PickPosition.X + PickSize.X, PopupSize.X + 8, ScreenSize.X - 8);
            local Y = PickPosition.Y + PickSize.Y + 4;

            if Y + PopupSize.Y > ScreenSize.Y - 8 then
                Y = math.max(8, PickPosition.Y - PopupSize.Y - 4);
            end;

            ModeSelectOuter.Position = UDim2.fromOffset(Right, Y);
        end;

        PickOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateModePopupPosition);
        PickOuter:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateModePopupPosition);
        ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateModePopupPosition);
        task.defer(UpdateModePopupPosition);

        local ModeSelectInner = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });

        Library:AddCorner(ModeSelectOuter, 5);
        Library:AddCorner(ModeSelectInner, 4);

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });

        Library:Create('UIPadding', {
            PaddingTop = UDim.new(0, 4);
            PaddingBottom = UDim.new(0, 4);
            PaddingLeft = UDim.new(0, 8);
            PaddingRight = UDim.new(0, 8);
            Parent = ModeSelectInner;
        });

        local ModeSelectScale = Library:Create('UIScale', {
            Scale = 0.95;
            Parent = ModeSelectOuter;
        });

        local ModeMotionId = 0;

        local function ShowModePopup()
            ModeMotionId = ModeMotionId + 1;
            UpdateModePopupPosition();
            ModeSelectOuter.GroupTransparency = 1;
            ModeSelectScale.Scale = 0.95;
            ModeSelectOuter.Visible = true;
            Library:OpenFrame(ModeSelectOuter);
            Library:Tween(ModeSelectOuter, { GroupTransparency = 0 }, 0.16, Enum.EasingStyle.Quart);
            Library:Tween(ModeSelectScale, { Scale = 1 }, 0.16, Enum.EasingStyle.Quart);
        end;

        local function HideModePopup()
            if not ModeSelectOuter.Visible then
                return;
            end;

            ModeMotionId = ModeMotionId + 1;
            local MotionId = ModeMotionId;
            Library:Tween(ModeSelectOuter, { GroupTransparency = 1 }, 0.11, Enum.EasingStyle.Quad);
            Library:Tween(ModeSelectScale, { Scale = 0.96 }, 0.11, Enum.EasingStyle.Quad);

            task.delay(0.11, function()
                if ModeMotionId == MotionId then
                    ModeSelectOuter.Visible = false;
                    Library:CloseFrame(ModeSelectOuter);
                end;
            end);
        end;

        local ContainerLabel = Library:Create('TextButton', {
            Name = 'KeybindRow';
            Active = true;
            AutoButtonColor = false;
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = 0.46;
            BorderSizePixel = 0;
            Font = Library.Font;
            Text = '';
            TextColor3 = Library.FontColor;
            TextSize = 12;
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 22);
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        });

        Library:ApplyTextStroke(ContainerLabel);
        Library:AddCorner(ContainerLabel, 5, true);
        Library:AddToRegistry(ContainerLabel, {
            BackgroundColor3 = 'MainColor';
            TextColor3 = 'FontColor';
        }, true);

        local ContainerGrid = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(7, 0);
            Size = UDim2.new(1, -14, 1, 0);
            ZIndex = 111;
            Parent = ContainerLabel;
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal;
            Padding = UDim.new(0, 5);
            SortOrder = Enum.SortOrder.LayoutOrder;
            VerticalAlignment = Enum.VerticalAlignment.Center;
            Parent = ContainerGrid;
        });

        local ContainerName = Library:CreateLabel({
            LayoutOrder = 1;
            Size = UDim2.new(0, 108, 1, 0);
            Text = tostring(Info.Text or Idx);
            TextSize = 11;
            TextTruncate = Enum.TextTruncate.AtEnd;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 111;
            Parent = ContainerGrid;
        }, true);

        local ContainerKey = Library:CreateLabel({
            BackgroundColor3 = Library.BackgroundColor;
            BackgroundTransparency = 0.08;
            BorderSizePixel = 0;
            LayoutOrder = 2;
            Size = UDim2.fromOffset(38, 16);
            Text = '';
            TextColor3 = Library.FontColor;
            TextSize = 10;
            TextTruncate = Enum.TextTruncate.AtEnd;
            TextXAlignment = Enum.TextXAlignment.Center;
            ZIndex = 111;
            Parent = ContainerGrid;
        }, true);

        Library:AddCorner(ContainerKey, 3, true);
        Library:AddToRegistry(ContainerKey, {
            BackgroundColor3 = 'BackgroundColor';
            TextColor3 = 'FontColor';
        }, true);

        local ContainerKeyStroke = Library:Create('UIStroke', {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = Library.OutlineColor;
            Thickness = 1;
            Transparency = 0.42;
            Parent = ContainerKey;
        });

        Library:AddToRegistry(ContainerKeyStroke, {
            Color = 'OutlineColor';
        }, true);

        local ContainerMode = Library:CreateLabel({
            BackgroundColor3 = Library.BackgroundColor;
            BackgroundTransparency = 0.42;
            BorderSizePixel = 0;
            LayoutOrder = 3;
            Size = UDim2.fromOffset(60, 16);
            Text = '';
            TextColor3 = Library.FontColor:Lerp(Library.MainColor, 0.26);
            TextSize = 10;
            TextTruncate = Enum.TextTruncate.AtEnd;
            TextXAlignment = Enum.TextXAlignment.Center;
            ZIndex = 111;
            Parent = ContainerGrid;
        }, true);

        Library.RegistryMap[ContainerMode].Properties.TextColor3 = function()
            return Library.FontColor:Lerp(Library.MainColor, 0.26);
        end;
        Library.RegistryMap[ContainerMode].Properties.BackgroundColor3 = 'BackgroundColor';
        Library:AddCorner(ContainerMode, 3, true);

        local ContainerModeStroke = Library:Create('UIStroke', {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = Library.OutlineColor;
            Thickness = 1;
            Transparency = 0.58;
            Parent = ContainerMode;
        });

        Library:AddToRegistry(ContainerModeStroke, {
            Color = 'OutlineColor';
        }, true);

        local ContainerScale = Library:Create('UIScale', {
            Scale = 1;
            Parent = ContainerLabel;
        });

        local ModeButtons = {};
        local ApplyModeState = function() end;

        for Idx, Mode in next, Modes do
            local ModeButton = {};

            local Label = Library:CreateLabel({
                Active = true;
                Size = UDim2.new(1, 0, 0, 18);
                TextSize = 12;
                Text = Mode;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                HideModePopup();
                ApplyModeState();
            end;

            function ModeButton:Deselect()
                KeyPicker.Mode = nil;

                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if Library:IsPointerInput(Input) then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);

            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker.SyncToggleState and ParentObj.Type == 'Toggle'
                and ParentObj.Value
                or KeyPicker:GetState();

            ContainerLabel.Visible = true;
            ContainerName.Text = tostring(Info.Text or Idx);
            ContainerKey.Text = tostring(KeyPicker.Value);
            ContainerMode.Text = tostring(KeyPicker.Mode);
            local RowColor = State and Library.MainColor:Lerp(Library.AccentColor, 0.14) or Library.MainColor;

            Library:Tween(ContainerLabel, {
                BackgroundColor3 = RowColor;
                BackgroundTransparency = State and 0.34 or 0.58;
            }, 0.14, Enum.EasingStyle.Quad);
            ContainerName.TextColor3 = Library.FontColor;
            ContainerKey.TextColor3 = Library.FontColor;
            ContainerMode.TextColor3 = Library.FontColor:Lerp(Library.MainColor, 0.26);

            Library.RegistryMap[ContainerLabel].Properties.BackgroundColor3 = function()
                return State and Library.MainColor:Lerp(Library.AccentColor, 0.14) or Library.MainColor;
            end;
            Library.RegistryMap[ContainerName].Properties.TextColor3 = 'FontColor';
            Library.RegistryMap[ContainerKey].Properties.TextColor3 = 'FontColor';
            Library.RegistryMap[ContainerMode].Properties.TextColor3 = function()
                return Library.FontColor:Lerp(Library.MainColor, 0.26);
            end;

            local YSize = 0

            for _, Row in next, Library.KeybindContainer:GetChildren() do
                if Row:IsA('TextButton') and Row.Name == 'KeybindRow' and Row.Visible then
                    YSize = YSize + Row.Size.Y.Offset + 3;
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, 248, 0, YSize + 29)
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end

                local Key = KeyPicker.Value;

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            UpdateDisplayLabel(Key);
            KeyPicker.Value = Key;
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick(ForcedState)
            local State = ForcedState;

            if State == nil then
                State = KeyPicker:GetState();
            end;

            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(State)
            end

            Library:SafeCallback(KeyPicker.Callback, State)
            Library:SafeCallback(KeyPicker.Clicked, State)
        end

        function KeyPicker:ToggleFromList()
            local State;

            if ParentObj.Type == 'Toggle' then
                State = not ParentObj.Value;
            else
                State = not KeyPicker.Toggled;
            end;

            KeyPicker.Toggled = State;
            KeyPicker:DoClick(State);
            KeyPicker:Update();
            Library:AttemptSave();
        end;

        ContainerLabel.InputBegan:Connect(function(Input)
            if not Library:IsPointerInput(Input) or Library:MouseIsOverOpenedFrame(Input) then
                return;
            end;

            Library:Tween(ContainerScale, { Scale = 0.97 }, 0.08, Enum.EasingStyle.Quad);
            KeyPicker:ToggleFromList();
        end);

        ContainerLabel.InputEnded:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                Library:Tween(ContainerScale, { Scale = 1 }, 0.12, Enum.EasingStyle.Quart);
            end;
        end);

        ApplyModeState = function()
            if KeyPicker.Mode == 'Always' then
                KeyPicker.Toggled = true;
            elseif KeyPicker.Mode == 'Hold' then
                KeyPicker.Toggled = false;
            end;

            KeyPicker:DoClick();
            KeyPicker:Update();
        end;

        local function InputMatchesKey(Input)
            if KeyPicker.Value == 'MB1' then
                return Input.UserInputType == Enum.UserInputType.MouseButton1;
            elseif KeyPicker.Value == 'MB2' then
                return Input.UserInputType == Enum.UserInputType.MouseButton2;
            end;

            return Input.UserInputType == Enum.UserInputType.Keyboard
                and Input.KeyCode.Name == KeyPicker.Value;
        end;

        local Picking = false;

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch and not Library:MouseIsOverOpenedFrame(Input) then
                ShowModePopup();
            elseif Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame(Input) then
                Picking = true;

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    end;

                    Break = true;
                    Picking = false;

                    UpdateDisplayLabel(Key);
                    KeyPicker.Value = Key;

                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

                    Library:AttemptSave();

                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame(Input) then
                ShowModePopup();
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if InputMatchesKey(Input) then
                    if KeyPicker.Mode == 'Toggle' then
                        KeyPicker.Toggled = not KeyPicker.Toggled;
                        KeyPicker:DoClick(KeyPicker.Toggled);
                    elseif KeyPicker.Mode == 'Hold' then
                        KeyPicker.Toggled = true;
                        KeyPicker:DoClick(true);
                    end;
                end;

                KeyPicker:Update();
            end;

            if Library:IsPointerInput(Input) then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;
                local PointerPosition = Library:GetPointerPosition(Input);

                if PointerPosition.X < AbsPos.X or PointerPosition.X > AbsPos.X + AbsSize.X
                    or PointerPosition.Y < (AbsPos.Y - 20 - 1) or PointerPosition.Y > AbsPos.Y + AbsSize.Y then

                    HideModePopup();
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Hold' and InputMatchesKey(Input) then
                    KeyPicker.Toggled = false;
                    KeyPicker:DoClick(false);
                end;

                KeyPicker:Update();
            end;
        end))

        ApplyModeState();
        KeyPicker:Update();

        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;

        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;

    function Funcs:AddButton(...)
        -- TODO: Eventually redo this
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                Active = true;
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });

            Library:AddCorner(Outer, 5);
            Library:AddCorner(Inner, 4);

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:AddToRegistry(Outer, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });

            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });

            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'OutlineColor' }
            );

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            Button.Scale = Button.Scale or Library:Create('UIScale', {
                Scale = 1;
                Parent = Button.Outer;
            });

            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)

                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:Disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame(Input) then
                    return false
                end

                if not Library:IsPointerInput(Input) then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end

                Library:Tween(Button.Scale, { Scale = 0.98 }, 0.08, Enum.EasingStyle.Quad);

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func);
            end)

            Button.Outer.InputEnded:Connect(function(Input)
                if Library:IsPointerInput(Input) then
                    Library:Tween(Button.Scale, { Scale = 1 }, 0.12, Enum.EasingStyle.Quart);
                end;
            end);
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end


        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });

        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });

        Library:AddCorner(DividerOuter, 3);
        Library:AddCorner(DividerInner, 2);

        Library:AddToRegistry(DividerOuter, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            ClipsDescendants = true;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });

        Library:AddCorner(TextBoxOuter, 5);
        Library:AddCorner(TextBoxInner, 4);

        local TextBoxStroke = Library:Create('UIStroke', {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = Library.OutlineColor;
            Thickness = 1;
            Transparency = 0.18;
            Parent = TextBoxOuter;
        });

        Library:AddToRegistry(TextBoxStroke, {
            Color = 'OutlineColor';
        });

        Library:AddToRegistry(TextBoxOuter, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'OutlineColor' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 3, 0, 0);
            Size = UDim2.new(1, -8, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        -- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
        -- thank you nicemike40 :)

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                -- we aren't focused, or we fit so be normal
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                -- we are focused and don't fit, so adjust position
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    -- calculate pixel width of text from start to cursor
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    -- check if we're inside the box with the cursor
                    local currentCursorPos = Box.Position.X.Offset + width

                    -- adjust if necessary
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(ToggleOuter, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });

        Library:AddCorner(ToggleOuter, 8);
        Library:AddCorner(ToggleInner, 8);

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleKnob = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundColor3 = Library.FontColor:Lerp(Library.MainColor, 0.5);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 2, 0.5, 0);
            Size = UDim2.fromOffset(11, 11);
            ZIndex = 7;
            Parent = ToggleInner;
        });

        Library:AddCorner(ToggleKnob, 6);

        Library:AddToRegistry(ToggleKnob, {
            BackgroundColor3 = function()
                return Toggle.Value and Library.FontColor or Library.FontColor:Lerp(Library.MainColor, 0.5);
            end;
        });

        local ToggleScale = Library:Create('UIScale', {
            Scale = 1;
            Parent = ToggleOuter;
        });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 201, 1, 0);
            Position = UDim2.new(1, 7, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });

        local ToggleTextWidth = Library:GetTextBounds(Info.Text, Library.Font, 14);
        local AddonOffset = math.clamp(ToggleTextWidth + 8, 24, 145);
        local AddonContainer = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(35 + AddonOffset, -1);
            Size = UDim2.fromOffset(math.max(38, 201 - AddonOffset), 17);
            Visible = false;
            ZIndex = 7;
            Parent = ToggleInner;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Left;
            VerticalAlignment = Enum.VerticalAlignment.Center;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = AddonContainer;
        });

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 198, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });

        function Toggle:ActivateInlineAddons()
            AddonContainer.Visible = true;
            ToggleLabel.Size = UDim2.fromOffset(math.max(20, AddonOffset - 4), 13);
            ToggleLabel.TextTruncate = Enum.TextTruncate.AtEnd;
            ToggleRegion.Size = UDim2.fromOffset(35 + AddonOffset - 4, 15);
        end;

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'OutlineColor' }
        );

        function Toggle:UpdateColors()
            Toggle:Display();
        end;

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            local BackgroundColor = Toggle.Value and Library.AccentColor or Library.MainColor;
            local BorderColor = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library:Tween(ToggleInner, {
                BackgroundColor3 = BackgroundColor;
                BorderColor3 = BorderColor;
            }, 0.16);

            Library:Tween(ToggleKnob, {
                BackgroundColor3 = Toggle.Value and Library.FontColor or Library.FontColor:Lerp(Library.MainColor, 0.5);
                Position = Toggle.Value and UDim2.new(1, -13, 0.5, 0) or UDim2.new(0, 2, 0.5, 0);
            }, 0.18, Enum.EasingStyle.Quart);

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);

            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
                Library:Tween(ToggleScale, { Scale = 0.94 }, 0.08, Enum.EasingStyle.Quad);
                Toggle:SetValue(not Toggle.Value) -- Why was it not like this from the start?
                Library:AttemptSave();
            end;
        end);

        ToggleRegion.InputEnded:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                Library:Tween(ToggleScale, { Scale = 1 }, 0.12, Enum.EasingStyle.Quart);
            end;
        end);

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.AddonContainer = AddonContainer;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;
        local SliderValueLabel;

        if not Info.Compact then
            local SliderHeader = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, -4, 0, 16);
                ZIndex = 5;
                Parent = Container;
            });

            Library:CreateLabel({
                Size = UDim2.new(0.7, 0, 1, 0);
                Font = Enum.Font.GothamMedium;
                TextSize = 13;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Center;
                ZIndex = 5;
                Parent = SliderHeader;
            });

            SliderValueLabel = Library:CreateLabel({
                AnchorPoint = Vector2.new(1, 0);
                Position = UDim2.fromScale(1, 0);
                Size = UDim2.new(0.3, 0, 1, 0);
                TextColor3 = Library.FontColor:Lerp(Library.MainColor, 0.28);
                TextSize = 12;
                TextXAlignment = Enum.TextXAlignment.Right;
                TextYAlignment = Enum.TextYAlignment.Center;
                ZIndex = 5;
                Parent = SliderHeader;
            });

            Library.RegistryMap[SliderValueLabel].Properties.TextColor3 = function()
                return Library.FontColor:Lerp(Library.MainColor, 0.28);
            end;

            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, 10);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(SliderOuter, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            ClipsDescendants = true;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });

        Library:AddCorner(SliderOuter, 7);
        Library:AddCorner(SliderInner, 6);

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local SliderStroke = Library:Create('UIStroke', {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = Library.OutlineColor;
            Thickness = 1;
            Transparency = 0.2;
            Parent = SliderOuter;
        });

        Library:AddToRegistry(SliderStroke, {
            Color = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            BorderSizePixel = 0;
            ClipsDescendants = true;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });

        Library:AddCorner(Fill, 6);

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 12;
            Text = 'Infinite';
            Visible = Info.Compact or false;
            ZIndex = 9;
            Parent = SliderInner;
        });

        local Thumb = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            BackgroundColor3 = Library.FontColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 0.5, 0);
            Size = UDim2.fromOffset(12, 12);
            ZIndex = 10;
            Parent = SliderOuter;
        });

        Library:AddCorner(Thumb, 6);
        Library:AddToRegistry(Thumb, {
            BackgroundColor3 = 'FontColor';
        });

        local ThumbScale = Library:Create('UIScale', {
            Scale = 1;
            Parent = Thumb;
        });

        local ThumbGlow = Library:Create('UIStroke', {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = Library.AccentColor;
            Thickness = 2;
            Transparency = 1;
            Parent = Thumb;
        });

        Library:AddToRegistry(ThumbGlow, {
            Color = 'AccentColor';
        });

        local SliderHitbox = Library:Create('Frame', {
            Active = true;
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0.5, -10);
            Size = UDim2.new(1, 0, 0, 20);
            ZIndex = 11;
            Parent = SliderOuter;
        });

        Library:OnHighlight(SliderOuter, SliderStroke,
            { Color = 'AccentColor' },
            { Color = 'OutlineColor' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        local FillTween;
        local ThumbTween;

        function Slider:Display(Instant, VisualPercent)
            local Suffix = Info.Suffix or '';

            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                SliderValueLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                SliderValueLabel.Text = string.format('%s / %s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local Percent = VisualPercent or math.clamp((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1);
            Percent = math.clamp(Percent, 0, 1);
            Slider.MaxSize = math.max(1, SliderInner.AbsoluteSize.X);

            if FillTween then
                FillTween:Cancel();
                FillTween = nil;
            end;

            if ThumbTween then
                ThumbTween:Cancel();
                ThumbTween = nil;
            end;

            if Instant then
                Fill.Size = UDim2.new(Percent, 0, 1, 0);
                Thumb.Position = UDim2.new(Percent, 0, 0.5, 0);
            else
                FillTween = Library:Tween(Fill, {
                    Size = UDim2.new(Percent, 0, 1, 0);
                }, 0.12, Enum.EasingStyle.Quad);
                ThumbTween = Library:Tween(Thumb, {
                    Position = UDim2.new(Percent, 0, 0.5, 0);
                }, 0.12, Enum.EasingStyle.Quad);
            end;

            HideBorderRight.Visible = false;
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;

        function Slider:GetValueFromXOffset(X)
            local TrackWidth = math.max(1, SliderInner.AbsoluteSize.X);
            Slider.MaxSize = TrackWidth;
            return Round(Library:MapValue(X, 0, TrackWidth, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);

            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;

        local SliderDragInput;
        local SliderDragConnection;
        local SliderEndConnection;
        local SliderHovered = false;

        SliderHitbox.MouseEnter:Connect(function()
            SliderHovered = true;

            if not SliderDragInput then
                Library:Tween(ThumbScale, { Scale = 1.08 }, 0.12, Enum.EasingStyle.Quart);
                Library:Tween(ThumbGlow, { Transparency = 0.68 }, 0.12, Enum.EasingStyle.Quad);
            end;
        end);

        SliderHitbox.MouseLeave:Connect(function()
            SliderHovered = false;

            if not SliderDragInput then
                Library:Tween(ThumbScale, { Scale = 1 }, 0.14, Enum.EasingStyle.Quart);
                Library:Tween(ThumbGlow, { Transparency = 1 }, 0.14, Enum.EasingStyle.Quad);
            end;
        end);

        local function UpdateSliderFromInput(Input)
            local PointerPosition = Library:GetPointerPosition(Input);
            local TrackWidth = math.max(1, SliderInner.AbsoluteSize.X);
            local X = math.clamp(PointerPosition.X - SliderInner.AbsolutePosition.X, 0, TrackWidth);
            local Percent = X / TrackWidth;
            local NewValue = Slider:GetValueFromXOffset(X);
            local OldValue = Slider.Value;

            Slider.Value = NewValue;
            Slider:Display(true, Percent);

            if NewValue ~= OldValue then
                Library:SafeCallback(Slider.Callback, Slider.Value);
                Library:SafeCallback(Slider.Changed, Slider.Value);
            end;
        end;

        local function StopSliderDrag()
            if SliderDragConnection then
                SliderDragConnection:Disconnect();
                SliderDragConnection = nil;
            end;

            if SliderEndConnection then
                SliderEndConnection:Disconnect();
                SliderEndConnection = nil;
            end;

            SliderDragInput = nil;
            Library:Tween(ThumbScale, { Scale = SliderHovered and 1.08 or 1 }, 0.14, Enum.EasingStyle.Quart);
            Library:Tween(ThumbGlow, { Transparency = SliderHovered and 0.68 or 1 }, 0.14, Enum.EasingStyle.Quad);
            Slider:Display();
            Library:AttemptSave();
        end;

        SliderHitbox.InputBegan:Connect(function(Input)
            if not Library:IsPointerInput(Input)
                or SliderDragInput
                or Library:MouseIsOverOpenedFrame(Input) then

                return;
            end;

            SliderDragInput = Input;
            Library:Tween(ThumbScale, { Scale = 1.12 }, 0.1, Enum.EasingStyle.Quart);
            Library:Tween(ThumbGlow, { Transparency = 0.28 }, 0.1, Enum.EasingStyle.Quad);
            UpdateSliderFromInput(Input);

            SliderDragConnection = RenderStepped:Connect(function()
                if SliderDragInput then
                    UpdateSliderFromInput(SliderDragInput);
                end;
            end);

            SliderEndConnection = Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End
                    or Input.UserInputState == Enum.UserInputState.Cancel then

                    StopSliderDrag();
                end;
            end);
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType; -- can be either 'Player' or 'Team'
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(DropdownOuter, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            ClipsDescendants = true;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });

        Library:AddCorner(DropdownOuter, 5);
        Library:AddCorner(DropdownInner, 4);

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local DropdownStroke = Library:Create('UIStroke', {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = Library.OutlineColor;
            Thickness = 1;
            Transparency = 0.18;
            Parent = DropdownOuter;
        });

        Library:AddToRegistry(DropdownStroke, {
            Color = 'OutlineColor';
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            ImageColor3 = Library:GetInactiveIconColor();
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });

        Library:AddToRegistry(DropdownArrow, {
            ImageColor3 = function()
                return Library:GetInactiveIconColor();
            end;
        });

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -25, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextTruncate = Enum.TextTruncate.AtEnd;
            TextWrapped = false;
            ZIndex = 7;
            Parent = DropdownInner;
        });

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;
        local SearchEnabled = Info.Searchable ~= false;
        local SearchHeight = SearchEnabled and 28 or 0;

        local ListOuter = Library:Create('CanvasGroup', {
            AnchorPoint = Vector2.new(0, 0);
            Active = true;
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderSizePixel = 0;
            ClipsDescendants = true;
            GroupTransparency = 1;
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });

        Library:AddCorner(ListOuter, 6);

        Library:AddToRegistry(ListOuter, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ListStroke = Library:Create('UIStroke', {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = Library.OutlineColor;
            Thickness = 1;
            Transparency = 0.12;
            Parent = ListOuter;
        });

        Library:AddToRegistry(ListStroke, {
            Color = 'OutlineColor';
        });

        local ListShadow = Library:Create('Frame', {
            Active = false;
            BackgroundColor3 = Color3.new(0, 0, 0);
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.fromOffset(0, 0);
            Size = UDim2.fromOffset(0, 0);
            Visible = false;
            ZIndex = 19;
            Parent = ScreenGui;
        });

        Library:AddCorner(ListShadow, 7, true);

        local ListScale = Library:Create('UIScale', {
            Scale = 1;
            Parent = ListOuter;
        });

        local ListTargetPosition = UDim2.fromOffset(0, 0);
        local ListOpenDirection = 1;
        local DropdownOpen = false;
        local DropdownMotionId = 0;

        DropdownOuter.MouseEnter:Connect(function()
            if not DropdownOpen and not Library:MouseIsOverOpenedFrame() then
                Library:Tween(DropdownStroke, {
                    Color = Library.AccentColor;
                }, 0.12, Enum.EasingStyle.Quad);
            end;
        end);

        DropdownOuter.MouseLeave:Connect(function()
            if not DropdownOpen then
                Library:Tween(DropdownStroke, {
                    Color = Library.OutlineColor;
                }, 0.14, Enum.EasingStyle.Quad);
            end;
        end);

        local function RecalculateListPosition()
            local FieldPosition = DropdownOuter.AbsolutePosition;
            local FieldSize = DropdownOuter.AbsoluteSize;
            local ListHeight = ListOuter.AbsoluteSize.Y;
            local BelowY = FieldPosition.Y + FieldSize.Y + 4;
            local ScreenHeight = ScreenGui.AbsoluteSize.Y;

            if ScreenHeight <= 0 then
                ScreenHeight = workspace.CurrentCamera.ViewportSize.Y;
            end;

            if BelowY + ListHeight > ScreenHeight - 8 and FieldPosition.Y - ListHeight - 4 >= 8 then
                ListOpenDirection = -1;
                ListTargetPosition = UDim2.fromOffset(FieldPosition.X, FieldPosition.Y - ListHeight - 4);
            else
                ListOpenDirection = 1;
                ListTargetPosition = UDim2.fromOffset(FieldPosition.X, BelowY);
            end;

            if not DropdownOpen then
                ListOuter.Position = ListTargetPosition;
                ListShadow.Position = ListTargetPosition + UDim2.fromOffset(0, 4);
            end;
        end;

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2 + SearchHeight));
            ListShadow.Size = ListOuter.Size;
            RecalculateListPosition();
        end;

        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);
        DropdownOuter:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            RecalculateListSize(ListOuter.AbsoluteSize.Y);
        end);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            ClipsDescendants = true;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });

        Library:AddCorner(ListInner, 6);

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local SearchBox;

        if SearchEnabled then
            SearchBox = Library:Create('TextBox', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderSizePixel = 0;
                ClearTextOnFocus = false;
                Font = Library.Font;
                PlaceholderColor3 = Library.GetDarkerColor and Library:GetDarkerColor(Library.FontColor) or Library.FontColor;
                PlaceholderText = 'Search...';
                Position = UDim2.fromOffset(4, 4);
                Size = UDim2.new(1, -8, 0, 20);
                Text = '';
                TextColor3 = Library.FontColor;
                TextSize = 13;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 24;
                Parent = ListInner;
            });

            Library:AddToRegistry(SearchBox, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
                PlaceholderColor3 = 'FontColor';
                TextColor3 = 'FontColor';
            });

            Library:AddCorner(SearchBox, 4);

            local SearchStroke = Library:Create('UIStroke', {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                Color = Library.OutlineColor;
                Thickness = 1;
                Transparency = 0.2;
                Parent = SearchBox;
            });

            Library:AddToRegistry(SearchStroke, {
                Color = 'OutlineColor';
            });

            local SearchIconAsset = Library:GetLucideIcon('search');
            local SearchIcon = Library:Create('ImageLabel', {
                AnchorPoint = Vector2.new(0, 0.5);
                BackgroundTransparency = 1;
                Image = SearchIconAsset or '';
                ImageColor3 = Library:GetInactiveIconColor();
                Position = UDim2.fromOffset(11, 14);
                Size = UDim2.fromOffset(12, 12);
                ScaleType = Enum.ScaleType.Fit;
                Visible = type(SearchIconAsset) == 'string' and SearchIconAsset ~= '';
                ZIndex = 25;
                Parent = ListInner;
            });

            Library:AddToRegistry(SearchIcon, {
                ImageColor3 = function()
                    return Library:GetInactiveIconColor();
                end;
            });

            Library:Create('UIPadding', {
                PaddingLeft = UDim.new(0, 24);
                PaddingRight = UDim.new(0, 7);
                Parent = SearchBox;
            });
        end;

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Position = SearchEnabled and UDim2.fromOffset(4, 28) or UDim2.fromOffset(4, 4);
            Size = SearchEnabled and UDim2.new(1, -8, 1, -32) or UDim2.new(1, -8, 1, -8);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
            ScrollBarImageTransparency = 0.15,
        });

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:BuildDropdownList()
            local Values = {};
            local Buttons = {};
            local Query = SearchBox and string.lower(SearchBox.Text) or '';

            for _, Value in next, Dropdown.Values do
                if Query == '' or string.find(string.lower(tostring(Value)), Query, 1, true) then
                    table.insert(Values, Value);
                end;
            end;

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};

                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, -4, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });

                Library:AddCorner(Button, 4);

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Active = true;
                    Size = UDim2.new(1, -16, 1, 0);
                    Position = UDim2.new(0, 8, 0, 0);
                    TextSize = 14;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    ZIndex = 25;
                    Parent = Button;
                });

                local Selected;
                local Hovered = false;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = 'FontColor';

                    local TintAmount = Hovered and (Selected and 0.18 or 0.08) or (Selected and 0.12 or 0);
                    Library:Tween(Button, {
                        BackgroundColor3 = Library.MainColor:Lerp(Library.AccentColor, TintAmount);
                    }, 0.12, Enum.EasingStyle.Quad);

                    Library.RegistryMap[Button].Properties.BackgroundColor3 = function()
                        local Amount = Hovered and (Selected and 0.18 or 0.08) or (Selected and 0.12 or 0);
                        return Library.MainColor:Lerp(Library.AccentColor, Amount);
                    end;
                end;

                Button.MouseEnter:Connect(function()
                    Hovered = true;
                    Table:UpdateButton();
                end);

                Button.MouseLeave:Connect(function()
                    Hovered = false;
                    Table:UpdateButton();
                end);

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Library:IsPointerInput(Input) then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();

                            if not Info.Multi then
                                task.defer(function()
                                    Dropdown:CloseDropdown();
                                end);
                            end;
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 5 + SearchHeight;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            if SearchBox then
                SearchBox.Text = '';
                Dropdown:BuildDropdownList();
            end;

            DropdownMotionId = DropdownMotionId + 1;
            DropdownOpen = true;
            RecalculateListPosition();

            ListScale.Scale = 0.94;
            ListOuter.GroupTransparency = 1;
            ListOuter.Position = ListTargetPosition + UDim2.fromOffset(0, -8 * ListOpenDirection);
            ListShadow.BackgroundTransparency = 1;
            ListShadow.Position = ListTargetPosition + UDim2.fromOffset(0, 1 - (8 * ListOpenDirection));
            ListShadow.Visible = true;
            ListOuter.Visible = true;
            Library:OpenFrame(ListOuter);
            Library:Tween(ListScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Quint);
            Library:Tween(ListOuter, {
                GroupTransparency = 0;
                Position = ListTargetPosition;
            }, 0.18, Enum.EasingStyle.Quint);
            Library:Tween(ListShadow, {
                BackgroundTransparency = 0.68;
                Position = ListTargetPosition + UDim2.fromOffset(0, 4);
            }, 0.18, Enum.EasingStyle.Quint);
            Library:Tween(DropdownArrow, {
                ImageColor3 = Library.AccentColor;
                Rotation = 180;
            }, 0.18, Enum.EasingStyle.Quint);
            Library:Tween(DropdownStroke, {
                Color = Library.AccentColor;
            }, 0.16, Enum.EasingStyle.Quad);
            Library.RegistryMap[DropdownStroke].Properties.Color = 'AccentColor';

            if SearchBox then
                SearchBox:CaptureFocus();
            end;
        end;

        function Dropdown:CloseDropdown()
            if not DropdownOpen then
                return;
            end;

            DropdownOpen = false;
            DropdownMotionId = DropdownMotionId + 1;
            local MotionId = DropdownMotionId;

            if SearchBox then
                SearchBox:ReleaseFocus();
            end;

            Library:Tween(ListScale, { Scale = 0.96 }, 0.14, Enum.EasingStyle.Quart);
            Library:Tween(ListOuter, {
                GroupTransparency = 1;
                Position = ListTargetPosition + UDim2.fromOffset(0, -6 * ListOpenDirection);
            }, 0.14, Enum.EasingStyle.Quart);
            Library:Tween(ListShadow, {
                BackgroundTransparency = 1;
                Position = ListTargetPosition + UDim2.fromOffset(0, 1 - (6 * ListOpenDirection));
            }, 0.14, Enum.EasingStyle.Quart);
            Library:Tween(DropdownArrow, {
                ImageColor3 = Library:GetInactiveIconColor();
                Rotation = 0;
            }, 0.14, Enum.EasingStyle.Quart);
            Library:Tween(DropdownStroke, {
                Color = Library.OutlineColor;
            }, 0.14, Enum.EasingStyle.Quad);
            Library.RegistryMap[DropdownStroke].Properties.Color = 'OutlineColor';

            task.delay(0.14, function()
                if DropdownMotionId == MotionId and not DropdownOpen then
                    ListOuter.Visible = false;
                    ListOuter.GroupTransparency = 1;
                    ListScale.Scale = 1;
                    ListOuter.Position = ListTargetPosition;
                    ListShadow.Visible = false;
                    ListShadow.BackgroundTransparency = 1;
                    ListShadow.Position = ListTargetPosition + UDim2.fromOffset(0, 4);
                    Library:CloseFrame(ListOuter);
                end;
            end);
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
                if DropdownOpen then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);

        if SearchBox then
            SearchBox:GetPropertyChangedSignal('Text'):Connect(function()
                if DropdownOpen then
                    Dropdown:BuildDropdownList();
                end;
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;
                local PointerPosition = Library:GetPointerPosition(Input);

                if PointerPosition.X < AbsPos.X or PointerPosition.X > AbsPos.X + AbsSize.X
                    or PointerPosition.Y < (AbsPos.Y - 20 - 1) or PointerPosition.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end));

        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        return Dropdown;
    end;

    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };
        
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);

        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

-- < Create other UI elements >
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });

    local WatermarkOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(1, 0.5);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(1, -12, 0.5, 0);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddCorner(WatermarkOuter, 6, true);
    Library:AddCorner(WatermarkInner, 5, true);

    Library:AddToRegistry(WatermarkInner, {
        BackgroundColor3 = 'MainColor';
    });

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 202;
        Parent = WatermarkInner;
    });

    Library:AddCorner(InnerFrame, 5, true);

    Library:AddSurfaceGradient(InnerFrame, -90);

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library.WatermarkGlow = Library:AddGlow(WatermarkOuter, {
        Padding = 14;
        Transparency = 0.78;
    });
    Library:MakeDraggable(Library.Watermark);

    local WatermarkPressInput;
    local WatermarkPressPosition;
    local WatermarkPressTime = 0;
    local WatermarkMoved = false;

    local function GetWatermarkPointerPosition(Input)
        if Input and Input.UserInputType == Enum.UserInputType.Touch then
            return Vector2.new(Input.Position.X, Input.Position.Y);
        end;

        return Vector2.new(Mouse.X, Mouse.Y);
    end;

    local function UpdateWatermarkPressMovement()
        if not WatermarkPressInput or not WatermarkPressPosition then
            return;
        end;

        local CurrentPosition = GetWatermarkPointerPosition(WatermarkPressInput);
        local MoveThreshold = WatermarkPressInput.UserInputType == Enum.UserInputType.Touch and 10 or 6;

        if (CurrentPosition - WatermarkPressPosition).Magnitude > MoveThreshold then
            WatermarkMoved = true;
        end;
    end;

    Library:GiveSignal(InputService.InputChanged:Connect(function(Input)
        local IsMouseMovement = WatermarkPressInput
            and WatermarkPressInput.UserInputType == Enum.UserInputType.MouseButton1
            and Input.UserInputType == Enum.UserInputType.MouseMovement;
        local IsActiveTouch = WatermarkPressInput
            and WatermarkPressInput.UserInputType == Enum.UserInputType.Touch
            and Input == WatermarkPressInput;

        if IsMouseMovement or IsActiveTouch then
            UpdateWatermarkPressMovement();
        end;
    end));

    Library:GiveSignal(WatermarkOuter.InputBegan:Connect(function(Input)
        local IsPointerInput = Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch;

        if not IsPointerInput or WatermarkPressInput then
            return;
        end;

        WatermarkPressInput = Input;
        WatermarkPressPosition = GetWatermarkPointerPosition(Input);
        WatermarkPressTime = os.clock();
        WatermarkMoved = false;

        local EndConnection;
        EndConnection = Input.Changed:Connect(function()
            UpdateWatermarkPressMovement();

            if Input.UserInputState ~= Enum.UserInputState.End then
                return;
            end;

            local IsCurrentPress = WatermarkPressInput == Input;
            local TapTime = Input.UserInputType == Enum.UserInputType.Touch and 0.6 or 0.45;
            local IsClick = IsCurrentPress
                and not WatermarkMoved
                and (os.clock() - WatermarkPressTime) <= TapTime;

            if IsCurrentPress then
                WatermarkPressInput = nil;
                WatermarkPressPosition = nil;
            end;

            EndConnection:Disconnect();

            if IsClick and type(Library.Toggle) == 'function' then
                task.spawn(Library.Toggle);
            end;
        end);
    end));



    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BackgroundColor3 = Color3.new(1, 1, 1);
        BackgroundTransparency = 0;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 12, 0.5, 0);
        Size = UDim2.new(0, 248, 0, 24);
        Visible = false;
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = ScreenGui;
    });

    local KeybindInner = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    Library:AddCorner(KeybindOuter, 6, true);
    Library:AddSurfaceGradient(KeybindOuter, -90);

    local KeybindStroke = Library:Create('UIStroke', {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Color = Library.OutlineColor;
        Thickness = 1;
        Transparency = 0.25;
        Parent = KeybindOuter;
    });

    Library:AddToRegistry(KeybindStroke, {
        Color = 'OutlineColor';
    }, true);

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, -16, 0, 22);
        Position = UDim2.fromOffset(8, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Library.FontColor:Lerp(Library.MainColor, 0.35);
        TextSize = 12;
        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });

    Library.RegistryMap[KeybindLabel].Properties.TextColor3 = function()
        return Library.FontColor:Lerp(Library.MainColor, 0.35);
    end;

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -23);
        Position = UDim2.new(0, 0, 0, 23);
        ZIndex = 1;
        Parent = KeybindInner;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 3);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library.KeybindGlow = Library:AddGlow(KeybindOuter, {
        Padding = 14;
        Transparency = 0.78;
    });
end;

function Library:SetWatermarkVisibility(Bool)
    if not Library.Watermark then
        return;
    end;

    Library.WatermarkVisibility = not not Bool;
    Library.Watermark.Visible = Library.WatermarkVisibility;
end;

function Library:SetKeybindVisibility(Bool)
    if not Library.KeybindFrame then
        return;
    end;

    Library.KeybindFrame.Visible = not not Bool;
end;

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 14);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);

    if Library.WatermarkVisibility == nil then
        Library.Watermark.Visible = true;
    end;

    Library.WatermarkText.Text = Text;
end;

function Library:AttachWatermark(Target, Info)
    Info = type(Info) == 'table' and Info or {};

    if type(Target) == 'table' then
        Target = Target.Instance or Target.Outer;
    end;

    if Library.WatermarkAttachmentConnections then
        for _, Connection in next, Library.WatermarkAttachmentConnections do
            pcall(function()
                Connection:Disconnect();
            end);
        end;
    end;

    Library.WatermarkAttachmentConnections = {};

    if typeof(Target) ~= 'Instance' or not Target:IsA('GuiObject') then
        return;
    end;

    local Alignment = tostring(Info.Alignment or 'Center'):lower();
    local Gap = math.max(0, tonumber(Info.Gap) or 6);
    local Margin = math.max(2, tonumber(Info.Margin) or 6);

    local function UpdatePosition()
        if not Target.Parent or not Library.Watermark.Parent then
            return;
        end;

        local Viewport = ScreenGui.AbsoluteSize;
        local TargetPosition = Target.AbsolutePosition;
        local TargetSize = Target.AbsoluteSize;
        local WatermarkSize = Library.Watermark.AbsoluteSize;
        local X;

        if Alignment == 'left' then
            X = TargetPosition.X;
        elseif Alignment == 'right' then
            X = TargetPosition.X + TargetSize.X - WatermarkSize.X;
        else
            X = TargetPosition.X + ((TargetSize.X - WatermarkSize.X) * 0.5);
        end;

        X = math.clamp(X, Margin, math.max(Margin, Viewport.X - WatermarkSize.X - Margin));

        local Y = TargetPosition.Y - WatermarkSize.Y - Gap;
        Y = math.clamp(Y, Margin, math.max(Margin, Viewport.Y - WatermarkSize.Y - Margin));

        Library.Watermark.AnchorPoint = Vector2.new(0, 0);
        Library.Watermark.Position = UDim2.fromOffset(math.floor(X + 0.5), math.floor(Y + 0.5));
    end;

    local Connections = Library.WatermarkAttachmentConnections;
    table.insert(Connections, Target:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdatePosition));
    table.insert(Connections, Target:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdatePosition));
    table.insert(Connections, Library.Watermark:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdatePosition));
    table.insert(Connections, ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdatePosition));

    for _, Connection in next, Connections do
        Library:GiveSignal(Connection);
    end;

    Library.UpdateWatermarkAttachment = UpdatePosition;
    task.defer(UpdatePosition);
end;

function Library:StartWatermark(Info)
    Info = type(Info) == 'table' and Info or {};

    if Library.WatermarkUpdateConnection then
        Library.WatermarkUpdateConnection:Disconnect();
    end;

    local Title = tostring(Info.Title or 'zzz');
    local RefreshRate = math.max(0.2, tonumber(Info.RefreshRate) or 0.5);
    local Frames = 0;
    local FrameTime = 0;
    local RefreshTime = 0;
    local FPS = 0;

    local function UpdateText()
        local Parts = { Title };

        if Info.ShowPlayer ~= false then
            table.insert(Parts, LocalPlayer.Name);
        end;

        if Info.ShowFPS ~= false then
            table.insert(Parts, string.format('%d FPS', FPS));
        end;

        if Info.ShowPing ~= false then
            local Ping = 0;
            pcall(function()
                Ping = math.floor((LocalPlayer:GetNetworkPing() * 1000) + 0.5);
            end);
            table.insert(Parts, string.format('%d ms', Ping));
        end;

        if Info.ShowTime ~= false then
            table.insert(Parts, os.date('%H:%M:%S'));
        end;

        Library:SetWatermark(table.concat(Parts, '  |  '));
    end;

    UpdateText();

    if Info.AttachTo then
        Library:AttachWatermark(Info.AttachTo, {
            Alignment = Info.Alignment;
            Gap = Info.Gap;
            Margin = Info.Margin;
        });
    end;

    local Connection = RenderStepped:Connect(function(Delta)
        Frames = Frames + 1;
        FrameTime = FrameTime + Delta;
        RefreshTime = RefreshTime + Delta;

        if RefreshTime >= RefreshRate then
            FPS = FrameTime > 0 and math.floor((Frames / FrameTime) + 0.5) or 0;
            Frames = 0;
            FrameTime = 0;
            RefreshTime = 0;
            UpdateText();
        end;
    end);

    Library.WatermarkUpdateConnection = Connection;
    Library:GiveSignal(Connection);
    return Connection;
end;

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

    YSize = YSize + 7

    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });

    local NotifyGlow = Library:AddGlow(NotifyOuter, {
        Padding = 12;
        Transparency = 0.82;
    });

    Library:AddCorner(NotifyOuter, 5);

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    Library:AddCorner(NotifyInner, 4);

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner;
    });

    Library:AddCorner(InnerFrame, 3);
    Library:AddSurfaceGradient(InnerFrame, -90);

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame;
    });

    Library:Tween(NotifyOuter, {
        Size = UDim2.new(0, XSize + 8 + 4, 0, YSize);
    }, 0.28);

    task.spawn(function()
        wait(Time or 5);

        Library:Tween(NotifyOuter, {
            Size = UDim2.new(0, 0, 0, YSize);
        }, 0.28);

        wait(0.28);

        if NotifyGlow then
            NotifyGlow:Destroy();
        end;

        if NotifyOuter.Parent then
            NotifyOuter:Destroy();
        end;
    end);
end;

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 600) end
    if type(Config.TabIconSize) ~= 'number' then Config.TabIconSize = 16 end
    if type(Config.TabIconPadding) ~= 'number' then Config.TabIconPadding = 5 end
    if type(Config.IconOnlyTabs) ~= 'boolean' then Config.IconOnlyTabs = false end
    if type(Config.SideTabs) ~= 'boolean' then Config.SideTabs = false end
    if type(Config.TopRightTabs) ~= 'boolean' then Config.TopRightTabs = false end
    if type(Config.FillSideTabs) ~= 'boolean' then Config.FillSideTabs = false end
    if type(Config.AccentGlow) ~= 'boolean' then Config.AccentGlow = true end
    if type(Config.GlowPadding) ~= 'number' then Config.GlowPadding = 20 end
    if type(Config.GlowTransparency) ~= 'number' then Config.GlowTransparency = 0.74 end
    if type(Config.GlowPulseTransparency) ~= 'number' then Config.GlowPulseTransparency = 0.64 end
    if type(Config.MenuSnow) ~= 'boolean' then Config.MenuSnow = false end
    if type(Config.SnowCount) ~= 'number' then Config.SnowCount = 42 end
    if type(Config.SnowSpeed) ~= 'number' then Config.SnowSpeed = 1 end
    if type(Config.SnowAvoidPadding) ~= 'number' then Config.SnowAvoidPadding = 18 end
    if type(Config.TabRailWidth) ~= 'number' then Config.TabRailWidth = 126 end
    if type(Config.TabHeight) ~= 'number' then Config.TabHeight = 34 end
    if type(Config.TabTransitionTime) ~= 'number' then Config.TabTransitionTime = 0.18 end
    if type(Config.CornerRadius) ~= 'number' then Config.CornerRadius = 0 end
    if type(Config.Motion) ~= 'boolean' then Config.Motion = true end
    if type(Config.Draggable) ~= 'boolean' then Config.Draggable = false end
    if type(Config.Responsive) ~= 'boolean' then Config.Responsive = true end
    if type(Config.MobileBreakpoint) ~= 'number' then Config.MobileBreakpoint = 640 end
    if type(Config.MobileMargin) ~= 'number' then Config.MobileMargin = 10 end
    if type(Config.BackgroundBlur) ~= 'boolean' then Config.BackgroundBlur = false end
    if type(Config.BackgroundBlurSize) ~= 'number' then Config.BackgroundBlurSize = 10 end
    if type(Config.BackgroundBlurAnimate) ~= 'boolean' then Config.BackgroundBlurAnimate = false end
    if type(Config.BackgroundDimTransparency) ~= 'number' then Config.BackgroundDimTransparency = 0.42 end
    if type(Config.AutoFitContentHeight) ~= 'boolean' then Config.AutoFitContentHeight = false end
    if type(Config.ContentBottomPadding) ~= 'number' then Config.ContentBottomPadding = 18 end

    local SideTabs = Config.SideTabs;
    local TopRightTabs = Config.TopRightTabs and not SideTabs;
    local TouchTargets = InputService.TouchEnabled;
    local TabRailWidth = math.max(Config.IconOnlyTabs and 64 or 96, Config.TabRailWidth);
    Library.CornersEnabled = Config.CornerRadius > 0;

    local InitialViewport = ScreenGui.AbsoluteSize;
    if InitialViewport.X <= 0 or InitialViewport.Y <= 0 then
        InitialViewport = workspace.CurrentCamera.ViewportSize;
    end;

    local BaseWindowSize = Vector2.new(
        Config.Size.X.Offset > 0 and Config.Size.X.Offset or math.max(1, InitialViewport.X * Config.Size.X.Scale),
        Config.Size.Y.Offset > 0 and Config.Size.Y.Offset or math.max(1, InitialViewport.Y * Config.Size.Y.Scale)
    );

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
        Config = Config;
        SideTabs = SideTabs;
        TopRightTabs = TopRightTabs;
    };

    local Dimmer = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(0, 0, 0);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.fromScale(1, 1);
        Visible = false;
        ZIndex = 0;
        Parent = ScreenGui;
    });

    local BackgroundBlur;

    if Config.BackgroundBlur then
        BackgroundBlur = Library:Create('BlurEffect', {
            Name = 'LinoriaModifiedBlur';
            Enabled = false;
            Size = 0;
            Parent = Lighting;
        });

        table.insert(Library.BackgroundEffects, BackgroundBlur);
    end;

    local GlowHolder = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint;
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Name = 'LinoriaGlowHolder';
        Position = Config.Position;
        Size = Config.Size;
        Visible = false;
        ZIndex = 0;
        Parent = ScreenGui;
    });

    local GlowPadding = math.max(4, Config.GlowPadding);
    local GlowImage = Library:Create('ImageLabel', {
        Active = false;
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Image = 'http://www.roblox.com/asset/?id=18245826428';
        ImageColor3 = Library.AccentColor;
        ImageTransparency = math.clamp(Config.GlowTransparency, 0, 1);
        Name = 'LinoriaGlow';
        Position = UDim2.fromOffset(-GlowPadding, -GlowPadding);
        ScaleType = Enum.ScaleType.Slice;
        Size = UDim2.new(1, GlowPadding * 2, 1, GlowPadding * 2);
        SliceCenter = Rect.new(21, 21, 79, 79);
        ZIndex = 0;
        Parent = GlowHolder;
    });

    Library:AddToRegistry(GlowImage, {
        ImageColor3 = function()
            return Library.RainbowAccent and Color3.new(1, 1, 1) or Library.AccentColor;
        end;
    }, true);

    local GlowImageGradient = Library:Create('UIGradient', {
        Rotation = 0;
        Parent = GlowImage;
    });

    Library:AddAccentGradient(GlowImageGradient, true);

    local GlowScale = Library:Create('UIScale', {
        Scale = Config.Motion and 0.96 or 1;
        Parent = GlowHolder;
    });

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ClipsDescendants = true;
        ZIndex = 1;
        Parent = ScreenGui;
    });

    Library:AddCorner(Outer, Config.CornerRadius);

    local OuterScale = Library:Create('UIScale', {
        Scale = Config.Motion and 0.96 or 1;
        Parent = Outer;
    });

    Library.SnowExclusions[Outer] = true;

    local function SyncGlow()
        GlowHolder.Position = Outer.Position;
        GlowHolder.Size = Outer.Size;
    end;

    Outer:GetPropertyChangedSignal('Position'):Connect(SyncGlow);
    Outer:GetPropertyChangedSignal('Size'):Connect(SyncGlow);

    if Config.Draggable then
        Library:MakeDraggable(Outer, 25);
    end;

    local SnowLayer = Library:Create('CanvasGroup', {
        Active = false;
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        GroupTransparency = 1;
        Name = 'LinoriaSnowLayer';
        Position = UDim2.fromOffset(0, 0);
        Size = UDim2.fromScale(1, 1);
        Visible = false;
        ZIndex = 0;
        Parent = ScreenGui;
    });

    local SnowRandom = Random.new();
    local Snowflakes = {};
    local SnowCount = math.floor(math.clamp(Config.SnowCount, 0, 100));

    if TouchTargets then
        SnowCount = math.min(SnowCount, 28);
    end;

    local function GetSnowViewport()
        local Viewport = ScreenGui.AbsoluteSize;

        if Viewport.X <= 0 or Viewport.Y <= 0 then
            Viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
                or Vector2.new(1920, 1080);
        end;

        return Viewport;
    end;

    local function ResetSnowflake(Particle, SpawnAbove)
        local Viewport = GetSnowViewport();
        local Depth = SnowRandom:NextNumber(0.18, 1);
        local Size = math.floor(1 + (Depth * 4) + 0.5);
        local Transparency = math.clamp(0.14 + ((1 - Depth) * 0.62), 0, 0.82);

        Particle.X = SnowRandom:NextNumber(0, math.max(1, Viewport.X - Size));
        Particle.Y = SpawnAbove
            and -SnowRandom:NextNumber(Size, math.max(Size + 1, Viewport.Y * 0.35))
            or SnowRandom:NextNumber(0, math.max(1, Viewport.Y - Size));
        Particle.Size = Size;
        Particle.Depth = Depth;
        Particle.Speed = (SnowRandom:NextNumber(18, 38) + (Depth * 42)) * math.max(0.1, Config.SnowSpeed);
        Particle.BaseDrift = SnowRandom:NextNumber(-9, 9);
        Particle.AvoidVelocity = 0;
        Particle.SwayAmplitude = SnowRandom:NextNumber(5, 16) * (0.55 + (Depth * 0.45));
        Particle.Phase = SnowRandom:NextNumber(0, math.pi * 2);
        Particle.Frequency = SnowRandom:NextNumber(0.55, 1.35);
        Particle.Instance.Size = UDim2.fromOffset(Size, Size);
        Particle.Instance.BackgroundTransparency = Transparency;
    end;

    local function GetBlockingSnowBounds(Point, Radius, ExtraPadding)
        local Padding = math.max(0, Config.SnowAvoidPadding)
            + Radius
            + math.max(0, tonumber(ExtraPadding) or 0);

        local function CheckTarget(Target)
            if typeof(Target) ~= 'Instance'
                or not Target:IsA('GuiObject')
                or not Target.Parent
                or not Target.Visible
            then
                return;
            end;

            local Position = Target.AbsolutePosition;
            local Size = Target.AbsoluteSize;

            if Size.X <= 0 or Size.Y <= 0 then
                return;
            end;

            local Left = Position.X - Padding;
            local Top = Position.Y - Padding;
            local Right = Position.X + Size.X + Padding;
            local Bottom = Position.Y + Size.Y + Padding;

            if Point.X >= Left and Point.X <= Right
                and Point.Y >= Top and Point.Y <= Bottom
            then
                return Left, Top, Right, Bottom;
            end;
        end;

        for Target in next, Library.SnowExclusions do
            if not Target or not Target.Parent then
                Library.SnowExclusions[Target] = nil;
            else
                local Left, Top, Right, Bottom = CheckTarget(Target);
                if Left then
                    return Left, Top, Right, Bottom;
                end;
            end;
        end;

        for Frame in next, Library.OpenedFrames do
            local Left, Top, Right, Bottom = CheckTarget(Frame);
            if Left then
                return Left, Top, Right, Bottom;
            end;
        end;
    end;

    local function MoveSnowOutsideUi(Particle, Delta)
        local HalfSize = Particle.Size * 0.5;
        local Point = Vector2.new(Particle.X + HalfSize, Particle.Y + HalfSize);
        local Left, _, Right = GetBlockingSnowBounds(Point, HalfSize, 26);

        if Left then
            local Middle = (Left + Right) * 0.5;
            local Direction = Point.X <= Middle and -1 or 1;
            local TargetVelocity = Direction * (34 + (Particle.Depth * 28));
            local Alpha = math.clamp(Delta * 5, 0, 1);
            Particle.AvoidVelocity = Particle.AvoidVelocity
                + ((TargetVelocity - Particle.AvoidVelocity) * Alpha);
        else
            Particle.AvoidVelocity = Particle.AvoidVelocity
                + ((0 - Particle.AvoidVelocity) * math.clamp(Delta * 2.5, 0, 1));
        end;

        local NewPoint = Vector2.new(Particle.X + HalfSize, Particle.Y + HalfSize);
        return GetBlockingSnowBounds(NewPoint, HalfSize) == nil;
    end;

    for Index = 1, SnowCount do
        local Flake = Library:Create('Frame', {
            Active = false;
            BackgroundColor3 = Library.FontColor;
            BackgroundTransparency = 0.3;
            BorderSizePixel = 0;
            Name = 'LinoriaSnowflake';
            Position = UDim2.fromOffset(0, 0);
            Size = UDim2.fromOffset(3, 3);
            ZIndex = SnowLayer.ZIndex;
            Parent = SnowLayer;
        });

        Library:AddToRegistry(Flake, {
            BackgroundColor3 = 'FontColor';
        }, true);
        Library:AddCorner(Flake, 8, true);

        local Particle = {
            Instance = Flake;
        };

        ResetSnowflake(Particle, Index > math.floor(SnowCount * 0.45));
        Snowflakes[Index] = Particle;
    end;

    Library:GiveSignal(RenderStepped:Connect(function(Delta)
        if not SnowLayer.Visible then
            return;
        end;

        Delta = math.min(Delta, 0.05);
        local Viewport = GetSnowViewport();
        local Now = os.clock();

        for _, Particle in next, Snowflakes do
            Particle.Y = Particle.Y + (Particle.Speed * Delta);
            Particle.X = Particle.X
                + ((Particle.BaseDrift + Particle.AvoidVelocity) * Delta)
                + (math.sin((Now * Particle.Frequency) + Particle.Phase) * Particle.SwayAmplitude * Delta);

            if Particle.Y > Viewport.Y + Particle.Size then
                ResetSnowflake(Particle, true);
            end;

            if Particle.X < -Particle.Size then
                Particle.X = Viewport.X + Particle.Size;
            elseif Particle.X > Viewport.X + Particle.Size then
                Particle.X = -Particle.Size;
            end;

            Particle.Instance.Visible = MoveSnowOutsideUi(Particle, Delta);
            Particle.Instance.Position = UDim2.fromOffset(
                math.floor(Particle.X + 0.5),
                math.floor(Particle.Y + 0.5)
            );
        end;
    end));

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = function()
            return Library:GetSurfaceBaseColor();
        end;
        BorderColor3 = 'OutlineColor';
    });

    Library:AddCorner(Inner, math.max(0, Config.CornerRadius - 1));
    Library:AddSurfaceGradient(Inner, -90);

    local InnerStroke = Library:Create('UIStroke', {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Color = Library.OutlineColor;
        Thickness = 1;
        Transparency = 0.18;
        Parent = Inner;
    });

    Library:AddToRegistry(InnerStroke, {
        Color = 'OutlineColor';
    });

    local WindowLogoAsset = Library:ResolveAsset(Config.Logo or Config.logo);
    local HasWindowLogo = type(WindowLogoAsset) == 'string' and WindowLogoAsset ~= '';

    local WindowLogo = Library:Create('ImageLabel', {
        AnchorPoint = Vector2.new(0, 0.5);
        BackgroundTransparency = 1;
        Image = HasWindowLogo and WindowLogoAsset or '';
        ImageColor3 = Library.IconColor;
        Position = UDim2.new(0, 7, 0, 12);
        Size = UDim2.fromOffset(16, 16);
        ScaleType = Enum.ScaleType.Fit;
        Visible = HasWindowLogo;
        ZIndex = 2;
        Parent = Inner;
    });

    pcall(function()
        WindowLogo.ResampleMode = Enum.ResamplerMode.Default;
    end);

    Library:AddToRegistry(WindowLogo, {
        ImageColor3 = 'IconColor';
    });

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, HasWindowLogo and 28 or 7, 0, 0);
        Size = UDim2.new(1, HasWindowLogo and -171 or -150, 0, 25);
        Text = Config.Title or '';
        TextXAlignment = Enum.TextXAlignment.Left;
        TextYAlignment = Enum.TextYAlignment.Center;
        TextSize = 14;
        ZIndex = 1;
        Parent = Inner;
    });

    local WindowSubtitle = Library:CreateLabel({
        AnchorPoint = Vector2.new(1, 0);
        Position = UDim2.new(1, -8, 0, 0);
        Size = UDim2.new(0, 135, 0, 25);
        Text = Config.Subtitle or '';
        Visible = type(Config.Subtitle) == 'string' and Config.Subtitle ~= '';
        TextXAlignment = Enum.TextXAlignment.Right;
        TextYAlignment = Enum.TextYAlignment.Center;
        TextSize = 11;
        ZIndex = 1;
        Parent = Inner;
    });

    local WindowAccentClip = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Position = UDim2.new(0, 9, 0, 22);
        Size = UDim2.new(1, -18, 0, 4);
        ZIndex = 2;
        Parent = Inner;
    });

    Library:AddCorner(WindowAccentClip, 3, true);

    local WindowAccentGlow = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BackgroundTransparency = 0.86;
        BorderSizePixel = 0;
        Position = UDim2.fromOffset(0, 0);
        Size = UDim2.fromScale(1, 1);
        ZIndex = 2;
        Parent = WindowAccentClip;
    });

    WindowAccentGlow.Visible = Config.AccentGlow;

    Library:AddCorner(WindowAccentGlow, 3, true);

    local WindowAccentGlowGradient = Library:Create('UIGradient', {
        Offset = Vector2.new(-1, 0);
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.72);
            NumberSequenceKeypoint.new(0.5, 0);
            NumberSequenceKeypoint.new(1, 0.72);
        });
        Parent = WindowAccentGlow;
    });

    Library:AddAccentGradient(WindowAccentGlowGradient);

    local WindowAccent = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0.5, -1);
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 3;
        Parent = WindowAccentClip;
    });

    Library:AddCorner(WindowAccent, 2, true);

    local WindowAccentGradient = Library:Create('UIGradient', {
        Offset = Vector2.new(-1, 0);
        Parent = WindowAccent;
    });

    Library:AddAccentGradient(WindowAccentGradient);

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderColor3 = Library.OutlineColor;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Position = UDim2.new(0, 8, 0, 27);
        Size = UDim2.new(1, -16, 1, -35);
        ZIndex = 1;
        Parent = Inner;
    });

    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = function()
            return Library:GetSurfaceBaseColor();
        end;
        BorderColor3 = 'OutlineColor';
    });

    Library:AddSurfaceGradient(MainSectionOuter, -90);

    local MainSectionInner = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });

    Library:AddCorner(MainSectionOuter, math.max(0, Config.CornerRadius - 1));

    local MainSectionStroke = Library:Create('UIStroke', {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Color = Library.OutlineColor;
        Thickness = 1;
        Transparency = 0.18;
        Parent = MainSectionOuter;
    });

    Library:AddToRegistry(MainSectionStroke, {
        Color = 'OutlineColor';
    });

    local TabArea = Library:Create('Frame', {
        AnchorPoint = TopRightTabs and Vector2.new(1, 0) or Vector2.new(0, 0);
        BackgroundColor3 = SideTabs and Library.MainColor or Color3.new(0, 0, 0);
        BackgroundTransparency = SideTabs and 0 or 1;
        BorderColor3 = Library.OutlineColor;
        BorderSizePixel = SideTabs and 1 or 0;
        Position = SideTabs and UDim2.new(0, 8, 0, 8)
            or (TopRightTabs and UDim2.new(1, -8, 0, TouchTargets and 0 or 2) or UDim2.new(0, 8, 0, 8));
        Size = SideTabs and UDim2.new(0, TabRailWidth, 1, -16)
            or (TopRightTabs and (TouchTargets and UDim2.new(1, -76, 0, 25) or UDim2.new(0.62, 0, 0, 21))
                or UDim2.new(1, -16, 0, 21));
        ZIndex = TopRightTabs and 6 or 1;
        Parent = TopRightTabs and Inner or MainSectionInner;
    });

    if SideTabs then
        Library:AddToRegistry(TabArea, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:AddCorner(TabArea, math.max(0, Config.CornerRadius - 2));
    end;

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = SideTabs and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal;
        HorizontalAlignment = SideTabs and Enum.HorizontalAlignment.Center
            or (TopRightTabs and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left);
        VerticalAlignment = Enum.VerticalAlignment.Center;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderColor3 = Library.OutlineColor;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        Position = SideTabs and UDim2.new(0, TabRailWidth + 16, 0, 8)
            or (TopRightTabs and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 8, 0, 30));
        Size = SideTabs and UDim2.new(1, -TabRailWidth - 24, 1, -16)
            or (TopRightTabs and UDim2.new(1, -16, 1, -16) or UDim2.new(1, -16, 1, -38));
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = function()
            return Library:GetSurfaceBaseColor();
        end;
        BorderColor3 = 'OutlineColor';
    });

    Library:AddSurfaceGradient(TabContainer, -90);

    Library:AddCorner(TabContainer, math.max(0, Config.CornerRadius - 2));

    Window.CompactLayout = false;
    local DefaultContentChromeHeight = (SideTabs or TopRightTabs) and 67 or 89;
    local ContentResizeQueued = false;

    function Window:GetRequiredContentHeight()
        if not Config.AutoFitContentHeight or not Window.ActiveTab then
            return BaseWindowSize.Y;
        end;

        local ActiveTab = Window.ActiveTab;
        local LeftHeight = ActiveTab.LeftLayout and ActiveTab.LeftLayout.AbsoluteContentSize.Y or 0;
        local RightHeight = ActiveTab.RightLayout and ActiveTab.RightLayout.AbsoluteContentSize.Y or 0;
        local TallestColumn = math.max(LeftHeight, RightHeight);
        local VisibleSide = ActiveTab.LeftSide;
        local ContentChromeHeight = VisibleSide
            and (Outer.AbsoluteSize.Y - VisibleSide.AbsoluteSize.Y)
            or DefaultContentChromeHeight;

        if ContentChromeHeight < 40 or ContentChromeHeight > 160 then
            ContentChromeHeight = DefaultContentChromeHeight;
        end;

        return math.max(
            BaseWindowSize.Y,
            math.ceil(TallestColumn + ContentChromeHeight + math.max(8, Config.ContentBottomPadding))
        );
    end;

    function Window:QueueContentResize()
        if not Config.AutoFitContentHeight or ContentResizeQueued then
            return;
        end;

        ContentResizeQueued = true;
        task.defer(function()
            ContentResizeQueued = false;

            if Outer.Parent then
                Window:ApplyResponsiveLayout();
            end;
        end);
    end;

    function Window:ApplyResponsiveLayout()
        local Viewport = ScreenGui.AbsoluteSize;
        if Viewport.X <= 0 or Viewport.Y <= 0 then
            Viewport = workspace.CurrentCamera.ViewportSize;
        end;

        local Margin = math.max(4, Config.MobileMargin);
        local AvailableWidth = math.max(240, Viewport.X - (Margin * 2));
        local AvailableHeight = math.max(240, Viewport.Y - (Margin * 2));
        local CompactLayout = Config.Responsive
            and InputService.TouchEnabled
            and (Viewport.X <= Config.MobileBreakpoint or AvailableWidth < BaseWindowSize.X);

        Window.CompactLayout = CompactLayout;

        for _, Tab in next, Window.Tabs do
            if Tab.SetMobileLayout then
                Tab:SetMobileLayout(CompactLayout);
            end;
        end;

        local DesiredHeight = Window:GetRequiredContentHeight();
        local TargetWidth = Config.Responsive and math.min(BaseWindowSize.X, AvailableWidth) or BaseWindowSize.X;
        local TargetHeight = Config.Responsive and math.min(DesiredHeight, AvailableHeight) or DesiredHeight;

        Outer.Size = UDim2.fromOffset(math.floor(TargetWidth + 0.5), math.floor(TargetHeight + 0.5));
    end;

    Library:GiveSignal(ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        Window:ApplyResponsiveLayout();
    end));

    if workspace.CurrentCamera then
        Library:GiveSignal(workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
            Window:ApplyResponsiveLayout();
        end));
    end;

    Window.Dimmer = Dimmer;
    Window.BackgroundBlur = BackgroundBlur;
    Window.Snow = SnowLayer;
    Window.Scale = OuterScale;
    Window.Glow = GlowHolder;
    Window.Logo = WindowLogo;
    Window.Instance = Outer;
    Window.Outer = Outer;

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;

    function Window:SetWindowLogo(Logo)
        local Resolved = Library:ResolveAsset(Logo);
        local Visible = type(Resolved) == 'string' and Resolved ~= '';

        WindowLogo.Image = Visible and Resolved or '';
        WindowLogo.Visible = Visible;
        WindowLabel.Position = UDim2.new(0, Visible and 28 or 7, 0, 0);
        WindowLabel.Size = UDim2.new(1, Visible and -171 or -150, 0, 25);
    end;

    Window.SetLogo = Window.SetWindowLogo;

    local function UpdateSideTabSizing()
        if not SideTabs or not Config.FillSideTabs then
            return;
        end;

        local TabCount = 0;

        for _, Tab in next, Window.Tabs do
            if Tab.Button then
                TabCount = TabCount + 1;
            end;
        end;

        if TabCount == 0 then
            return;
        end;

        local TotalPadding = math.max(0, Config.TabPadding) * math.max(0, TabCount - 1);
        local ButtonOffset = -(TotalPadding / TabCount);

        for _, Tab in next, Window.Tabs do
            if Tab.Button then
                Tab.Button.Size = UDim2.new(1, -10, 1 / TabCount, ButtonOffset);
            end;
        end;
    end;

    function Window:AddTab(Name)
        local TabInfo = type(Name) == 'table' and Name or { Name = Name };
        local TabName = TabInfo.Name or TabInfo.Text or 'Tab';
        local TabIconName = TabInfo.Icon or TabInfo.icon or TabInfo.Logo or TabInfo.logo;
        local TabIcon = Library:ResolveAsset(TabIconName);

        if type(TabName) ~= 'string' then
            TabName = tostring(TabName);
        end;

        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
            RightElements = {};
            MobileLayout = Window.CompactLayout;
            Name = TabName;
            Icon = TabIconName;
        };

        local HasIcon = type(TabIcon) == 'string' and TabIcon ~= '';
        local IconOnly = Config.IconOnlyTabs and HasIcon;
        local TabIconSize = math.floor(math.max(TouchTargets and 20 or 12, Config.TabIconSize) + 0.5);
        local TabIconPadding = math.max(0, Config.TabIconPadding);
        local TabButtonWidth = Library:GetTextBounds(TabName, Library.Font, 16);
        local TabContentWidth = TabButtonWidth + 8 + 4;
        local TabTextOffset = SideTabs and 12 or 0;

        if IconOnly then
            TabContentWidth = TabIconSize + (TopRightTabs and (TouchTargets and 14 or 12) or 16);
            TabTextOffset = 0;
        end;

        if HasIcon and not IconOnly then
            TabContentWidth = TabContentWidth + TabIconSize + TabIconPadding;
            TabTextOffset = TabTextOffset + (SideTabs and (TabIconSize + TabIconPadding) or (5 + TabIconSize + TabIconPadding));
        end;

        local TabButton = Library:Create('Frame', {
            Active = true;
            BackgroundColor3 = SideTabs and Library.MainColor or Library.BackgroundColor;
            BackgroundTransparency = (SideTabs or TopRightTabs) and 1 or 0;
            BorderColor3 = Library.OutlineColor;
            BorderSizePixel = (SideTabs or TopRightTabs) and 0 or 1;
            Size = SideTabs and UDim2.new(1, -10, 0, Config.TabHeight)
                or UDim2.new(0, TabContentWidth, 1, 0);
            ZIndex = TopRightTabs and 7 or 1;
            Parent = TabArea;
        });

        Tab.Button = TabButton;

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = SideTabs and 'MainColor' or 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:AddCorner(TabButton, math.max(0, Config.CornerRadius - 2));

        local TabButtonIcon;

        if HasIcon then
            TabButtonIcon = Library:Create('ImageLabel', {
                AnchorPoint = IconOnly and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5);
                BackgroundTransparency = 1;
                Image = Library:ResolveAsset(TabIcon);
                ImageColor3 = Library:GetInactiveIconColor();
                ImageTransparency = 0.14;
                Position = IconOnly and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, SideTabs and 12 or 5, 0.5, 0);
                Size = UDim2.fromOffset(TabIconSize, TabIconSize);
                ScaleType = Enum.ScaleType.Fit;
                ZIndex = TopRightTabs and 8 or 2;
                Parent = TabButton;
            });

            pcall(function()
                TabButtonIcon.ResampleMode = Enum.ResamplerMode.Default;
            end);

            Library:AddToRegistry(TabButtonIcon, {
                ImageColor3 = function()
                    return Window.ActiveTab == Tab and Library.IconColor or Library:GetInactiveIconColor();
                end;
                ImageTransparency = function()
                    return Window.ActiveTab == Tab and 0 or 0.14;
                end;
            });
        end;

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, TabTextOffset, 0, 0);
            Size = UDim2.new(1, -TabTextOffset - (SideTabs and 8 or 0), 1, -1);
            Text = TabName;
            Visible = not IconOnly;
            TextSize = SideTabs and 13 or 16;
            TextXAlignment = SideTabs and Enum.TextXAlignment.Left or (HasIcon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center);
            ZIndex = TopRightTabs and 8 or 1;
            Parent = TabButton;
        });

        if IconOnly then
            Library:AddToolTip(TabName, TabButton);
        end;

        local Blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = SideTabs and 1 or 1;
            Visible = not SideTabs and not TopRightTabs;
            ZIndex = TopRightTabs and 8 or 3;
            Parent = TabButton;
        });

        Library:AddToRegistry(Blocker, {
            BackgroundColor3 = 'MainColor';
        });

        local TabFrame = Library:Create('CanvasGroup', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            GroupTransparency = 0;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 3;
            Parent = TabContainer;
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 3;
            ScrollBarImageColor3 = Library.OutlineColor;
            ZIndex = 3;
            Parent = TabFrame;
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 3;
            ScrollBarImageColor3 = Library.OutlineColor;
            ZIndex = 3;
            Parent = TabFrame;
        });

        local LeftLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });

        local RightLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });

        Tab.LeftSide = LeftSide;
        Tab.RightSide = RightSide;
        Tab.LeftLayout = LeftLayout;
        Tab.RightLayout = RightLayout;

        for _, SideInfo in next, { { LeftSide, LeftLayout }, { RightSide, RightLayout } } do
            local Side = SideInfo[1];
            local Layout = SideInfo[2];

            Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y);

                if Window.ActiveTab == Tab then
                    Window:QueueContentResize();
                end;
            end);
        end;

        function Tab:ShowTab()
            for _, OtherTab in next, Window.Tabs do
                if OtherTab ~= Tab then
                    OtherTab:HideTab();
                end;
            end;

            Blocker.BackgroundTransparency = (SideTabs or TopRightTabs) and 1 or 0;
            if not SideTabs and not TopRightTabs then
                TabButton.BackgroundColor3 = Library.MainColor;
                Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            end;
            if TabButtonIcon then
                Library:Tween(TabButtonIcon, {
                    ImageColor3 = Library.IconColor;
                    ImageTransparency = 0;
                }, 0.18, Enum.EasingStyle.Quad);
            end;

            if Config.Motion then
                TabFrame.Position = UDim2.new(0, SideTabs and 10 or 4, 0, 0);
                TabFrame.GroupTransparency = 0.16;
                TabFrame.Visible = true;
                Library:Tween(TabFrame, {
                    Position = UDim2.new(0, 0, 0, 0);
                    GroupTransparency = 0;
                }, Config.TabTransitionTime);
            else
                TabFrame.Visible = true;
            end;

            Window.ActiveTab = Tab;
            Window:QueueContentResize();
        end;

        function Tab:SetMobileLayout(Enabled)
            Enabled = not not Enabled;

            if Tab.MobileLayout == Enabled and Tab.MobileLayoutApplied then
                return;
            end;

            Tab.MobileLayout = Enabled;
            Tab.MobileLayoutApplied = true;

            LeftSide.Size = Enabled
                and UDim2.new(1, -14, 1, -16)
                or UDim2.new(0.5, -10, 1, -16);
            RightSide.Visible = not Enabled;

            for _, Element in next, Tab.RightElements do
                if Element and Element.Parent then
                    Element.Parent = Enabled and LeftSide or RightSide;
                end;
            end;

            if Window.ActiveTab == Tab then
                Window:QueueContentResize();
            end;
        end;

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            if not SideTabs and not TopRightTabs then
                TabButton.BackgroundColor3 = Library.BackgroundColor;
                Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            end;
            if TabButtonIcon then
                Library:Tween(TabButtonIcon, {
                    ImageColor3 = Library:GetInactiveIconColor();
                    ImageTransparency = 0.14;
                }, 0.16, Enum.EasingStyle.Quad);
            end;

            TabFrame.GroupTransparency = 0;
            TabFrame.Visible = false;
        end;

        if SideTabs or TopRightTabs then
            TabButton.MouseEnter:Connect(function()
                if Window.ActiveTab == Tab or Library:MouseIsOverOpenedFrame() then
                    return;
                end;

                if TabButtonIcon then
                    Library:Tween(TabButtonIcon, {
                        ImageColor3 = Library.FontColor:Lerp(Library.MainColor, 0.22);
                        ImageTransparency = 0.04;
                    }, 0.14, Enum.EasingStyle.Quad);
                end;
            end);

            TabButton.MouseLeave:Connect(function()
                if Window.ActiveTab == Tab then
                    return;
                end;

                if TabButtonIcon and Window.ActiveTab ~= Tab then
                    Library:Tween(TabButtonIcon, {
                        ImageColor3 = Library:GetInactiveIconColor();
                        ImageTransparency = 0.14;
                    }, 0.14, Enum.EasingStyle.Quad);
                end;
            end);
        end;

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;

        function Tab:SetIcon(Icon)
            local ResolvedIcon = Library:ResolveAsset(Icon);

            TabIcon = ResolvedIcon;
            Tab.Icon = Icon;

            if TabButtonIcon then
                TabButtonIcon.Image = ResolvedIcon or '';
                TabButtonIcon.Visible = type(ResolvedIcon) == 'string' and ResolvedIcon ~= '';
                TabButtonLabel.Visible = not Config.IconOnlyTabs or not TabButtonIcon.Visible;
                return;
            end;

            if type(ResolvedIcon) ~= 'string' or ResolvedIcon == '' then
                return;
            end;

            TabButtonIcon = Library:Create('ImageLabel', {
                AnchorPoint = Config.IconOnlyTabs and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5);
                BackgroundTransparency = 1;
                Image = ResolvedIcon;
                ImageColor3 = Window.ActiveTab == Tab and Library.IconColor or Library:GetInactiveIconColor();
                ImageTransparency = Window.ActiveTab == Tab and 0 or 0.14;
                Position = Config.IconOnlyTabs and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, SideTabs and 12 or 5, 0.5, 0);
                Size = UDim2.fromOffset(TabIconSize, TabIconSize);
                ScaleType = Enum.ScaleType.Fit;
                ZIndex = TopRightTabs and 8 or 2;
                Parent = TabButton;
            });

            pcall(function()
                TabButtonIcon.ResampleMode = Enum.ResamplerMode.Default;
            end);

            if Config.IconOnlyTabs then
                TabButtonLabel.Visible = false;
                Library:AddToolTip(TabName, TabButton);
            end;

            Library:AddToRegistry(TabButtonIcon, {
                ImageColor3 = function()
                    return Window.ActiveTab == Tab and Library.IconColor or Library:GetInactiveIconColor();
                end;
                ImageTransparency = function()
                    return Window.ActiveTab == Tab and 0 or 0.14;
                end;
            });
        end;

        function Tab:AddGroupbox(Info)
            local Groupbox = {};
            local SectionColor = Library:GetLighterColor(Library.MainColor);

            local BoxOuter = Library:Create('Frame', {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                ClipsDescendants = true;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = (Info.Side == 1 or Tab.MobileLayout) and LeftSide or RightSide;
            });

            if Info.Side == 2 then
                BoxOuter.LayoutOrder = 1000 + #Tab.RightElements;
                table.insert(Tab.RightElements, BoxOuter);
            end;

            Library:AddCorner(BoxOuter, Config.CornerRadius);

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = SectionColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = function()
                    return Library:GetLighterColor(Library.MainColor);
                end;
            });

            Library:AddCorner(BoxInner, math.max(0, Config.CornerRadius - 1));

            local BoxStroke = Library:Create('UIStroke', {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                Color = Library.OutlineColor;
                Thickness = 1;
                Transparency = 0.08;
                Parent = BoxInner;
            });

            Library:AddToRegistry(BoxStroke, {
                Color = 'OutlineColor';
            });

            local HeaderSurface = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BackgroundTransparency = 0.18;
                BorderSizePixel = 0;
                Position = UDim2.fromOffset(1, 1);
                Size = UDim2.new(1, -2, 0, 25);
                ZIndex = 4;
                Parent = BoxInner;
            });

            Library:AddToRegistry(HeaderSurface, {
                BackgroundColor3 = 'MainColor';
            });

            Library:AddCorner(HeaderSurface, math.max(0, Config.CornerRadius - 2));

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.OutlineColor;
                BackgroundTransparency = 0.12;
                BorderSizePixel = 0;
                Position = UDim2.new(0, 10, 0, 25);
                Size = UDim2.new(1, -20, 0, 1);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'OutlineColor';
            });

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, -20, 0, 18);
                Position = UDim2.new(0, 10, 0, 5);
                TextColor3 = Library.FontColor;
                TextSize = 13;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library.RegistryMap[GroupboxLabel].Properties.TextColor3 = function()
                return Library.FontColor;
            end;

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 10, 0, 27);
                Size = UDim2.new(1, -20, 1, -37);
                ZIndex = 1;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });

            function Groupbox:Resize()
                local Size = 0;

                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, 37 + Size);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(1);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
                OrderedTabs = {};
            };
            local SectionColor = Library:GetLighterColor(Library.MainColor);

            local BoxOuter = Library:Create('Frame', {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                ClipsDescendants = true;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = (Info.Side == 1 or Tab.MobileLayout) and LeftSide or RightSide;
            });

            if Info.Side == 2 then
                BoxOuter.LayoutOrder = 1000 + #Tab.RightElements;
                table.insert(Tab.RightElements, BoxOuter);
            end;

            Library:AddCorner(BoxOuter, Config.CornerRadius);

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = SectionColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = function()
                    return Library:GetLighterColor(Library.MainColor);
                end;
            });

            Library:AddCorner(BoxInner, math.max(0, Config.CornerRadius - 1));

            local TabboxStroke = Library:Create('UIStroke', {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                Color = Library.OutlineColor;
                Thickness = 1;
                Transparency = 0.28;
                Parent = BoxInner;
            });

            Library:AddToRegistry(TabboxStroke, {
                Color = 'OutlineColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.OutlineColor;
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 1);
                ZIndex = 10;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'OutlineColor';
            });

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 8, 0, 6);
                Size = UDim2.new(1, -16, 0, 20);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });

            function Tabbox:AddTab(Name)
                local Tab = {};

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    BorderSizePixel = 0;
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonRadius = math.max(2, Config.CornerRadius - 2);
                Library:AddCorner(Button, ButtonRadius, true);

                local LeftSquareMask = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderSizePixel = 0;
                    Position = UDim2.fromOffset(0, 0);
                    Size = UDim2.new(0, ButtonRadius + 1, 1, 0);
                    Visible = false;
                    ZIndex = 6;
                    Parent = Button;
                });

                local RightSquareMask = Library:Create('Frame', {
                    AnchorPoint = Vector2.new(1, 0);
                    BackgroundColor3 = Library.MainColor;
                    BorderSizePixel = 0;
                    Position = UDim2.fromScale(1, 0);
                    Size = UDim2.new(0, ButtonRadius + 1, 1, 0);
                    Visible = false;
                    ZIndex = 6;
                    Parent = Button;
                });

                Library:AddToRegistry(LeftSquareMask, {
                    BackgroundColor3 = 'MainColor';
                });
                Library:AddToRegistry(RightSquareMask, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 10, 0, 31);
                    Size = UDim2.new(1, -20, 1, -41);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';
                    LeftSquareMask.BackgroundColor3 = Library.BackgroundColor;
                    RightSquareMask.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[LeftSquareMask].Properties.BackgroundColor3 = 'BackgroundColor';
                    Library.RegistryMap[RightSquareMask].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;

                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                    LeftSquareMask.BackgroundColor3 = Library.MainColor;
                    RightSquareMask.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[LeftSquareMask].Properties.BackgroundColor3 = 'MainColor';
                    Library.RegistryMap[RightSquareMask].Properties.BackgroundColor3 = 'MainColor';
                end;

                function Tab:Resize()
                    local TabCount = 0;

                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    for Index, OrderedTab in ipairs(Tabbox.OrderedTabs) do
                        OrderedTab.LeftSquareMask.Visible = Index > 1;
                        OrderedTab.RightSquareMask.Visible = Index < TabCount;
                    end;

                    if (not Container.Visible) then
                        return;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 41 + Size);
                end;

                Button.InputBegan:Connect(function(Input)
                    if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tab.Button = Button;
                Tab.LeftSquareMask = LeftSquareMask;
                Tab.RightSquareMask = RightSquareMask;
                Tabbox.Tabs[Name] = Tab;
                table.insert(Tabbox.OrderedTabs, Tab);

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(1);
                Tab:Resize();

                -- Show first tab (number is 2 cus of the UIListLayout that also sits in that instance)
                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
                Tab:ShowTab();
            end;
        end);

        -- The tab container also owns its background surface, so child count is
        -- not a reliable first-tab test. Window.Tabs is still empty here only
        -- for the first tab, which guarantees that its content is shown.
        if next(Window.Tabs) == nil then
            Tab:ShowTab();
        end;

        Window.Tabs[TabName] = Tab;
        Tab:SetMobileLayout(Window.CompactLayout);
        UpdateSideTabSizing();
        Window:ApplyResponsiveLayout();
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    local TransparencyCache = {};
    local Toggled = false;
    local Fading = false;

    task.spawn(function()
        while Outer.Parent do
            if Toggled and Config.AccentGlow then
                local GradientTravel = Library.RainbowAccent and 0.24 or 1;

                Library:Tween(GlowImage, {
                    ImageTransparency = math.clamp(Config.GlowPulseTransparency, 0, 1);
                }, 3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
                Library:Tween(WindowAccentGradient, {
                    Offset = Vector2.new(GradientTravel, 0);
                }, 3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
                Library:Tween(WindowAccentGlowGradient, {
                    Offset = Vector2.new(GradientTravel, 0);
                }, 3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
                Library:Tween(WindowAccentGlow, {
                    BackgroundTransparency = 0.76;
                }, 3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
                task.wait(3.2);

                if Toggled then
                    Library:Tween(GlowImage, {
                        ImageTransparency = math.clamp(Config.GlowTransparency, 0, 1);
                    }, 3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
                    Library:Tween(WindowAccentGradient, {
                        Offset = Vector2.new(-GradientTravel, 0);
                    }, 3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
                    Library:Tween(WindowAccentGlowGradient, {
                        Offset = Vector2.new(-GradientTravel, 0);
                    }, 3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
                    Library:Tween(WindowAccentGlow, {
                        BackgroundTransparency = 0.86;
                    }, 3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut);
                    task.wait(3.2);
                end;
            else
                task.wait(0.25);
            end;
        end;
    end);

    function Library:Toggle()
        if Fading then
            return;
        end;

        local FadeTime = Config.MenuFadeTime;
        Fading = true;
        Toggled = (not Toggled);
        ModalElement.Modal = Toggled;

        if Toggled then
            Outer.Visible = true;
            GlowHolder.Visible = Config.AccentGlow;

            if Config.MenuSnow then
                SnowLayer.Visible = true;
                SnowLayer.GroupTransparency = 1;
                Library:Tween(SnowLayer, {
                    GroupTransparency = 0;
                }, FadeTime, Enum.EasingStyle.Quad);
            end;

            Dimmer.Visible = true;
            Dimmer.BackgroundTransparency = 1;
            Library:Tween(Dimmer, {
                BackgroundTransparency = Config.BackgroundDimTransparency;
            }, FadeTime);

            if BackgroundBlur then
                BackgroundBlur.Enabled = true;
                if Config.BackgroundBlurAnimate then
                    BackgroundBlur.Size = 0;
                    Library:Tween(BackgroundBlur, {
                        Size = Config.BackgroundBlurSize;
                    }, FadeTime);
                else
                    BackgroundBlur.Size = Config.BackgroundBlurSize;
                end;
            end;

            if Config.Motion then
                OuterScale.Scale = 0.96;
                if Config.AccentGlow then
                    GlowScale.Scale = 0.96;
                end;
                Library:Tween(OuterScale, {
                    Scale = 1;
                }, FadeTime);
                if Config.AccentGlow then
                    Library:Tween(GlowScale, {
                        Scale = 1;
                    }, FadeTime);
                end;
            end;
        else
            Library:Tween(Dimmer, {
                BackgroundTransparency = 1;
            }, FadeTime);

            if Config.MenuSnow then
                Library:Tween(SnowLayer, {
                    GroupTransparency = 1;
                }, FadeTime, Enum.EasingStyle.Quad);
            end;

            if BackgroundBlur then
                if Config.BackgroundBlurAnimate then
                    Library:Tween(BackgroundBlur, {
                        Size = 0;
                    }, FadeTime);
                else
                    BackgroundBlur.Size = 0;
                end;
            end;

            if Config.Motion then
                Library:Tween(OuterScale, {
                    Scale = 0.96;
                }, FadeTime);
                if Config.AccentGlow then
                    Library:Tween(GlowScale, {
                        Scale = 0.96;
                    }, FadeTime);
                end;
            end;
        end;

        for _, Desc in next, Outer:GetDescendants() do
            local Properties = {};

            if Desc:IsA('ImageLabel') then
                table.insert(Properties, 'ImageTransparency');
                table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                table.insert(Properties, 'TextTransparency');
            elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('UIStroke') then
                table.insert(Properties, 'Transparency');
            end;

            local Cache = TransparencyCache[Desc];

            if (not Cache) then
                Cache = {};
                TransparencyCache[Desc] = Cache;
            end;

            for _, Prop in next, Properties do
                if not Cache[Prop] then
                    Cache[Prop] = Desc[Prop];
                end;

                if Cache[Prop] == 1 then
                    continue;
                end;

                TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play();
            end;
        end;

        task.wait(FadeTime);

        Outer.Visible = Toggled;
        GlowHolder.Visible = Toggled and Config.AccentGlow;
        Dimmer.Visible = Toggled;
        SnowLayer.Visible = Toggled and Config.MenuSnow;

        if BackgroundBlur then
            BackgroundBlur.Enabled = Toggled;
        end;

        Fading = false;
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.Keyboard then
            return;
        end;

        local IsRightControl = Input.KeyCode == Enum.KeyCode.RightControl;
        local IsConfiguredKey = type(Library.ToggleKeybind) == 'table'
            and Library.ToggleKeybind.Type == 'KeyPicker'
            and Input.KeyCode.Name == Library.ToggleKeybind.Value;

        -- Right Control is permanent, while the picker can add a second key.
        -- The OR also prevents a RightControl picker from toggling twice.
        if IsRightControl or IsConfiguredKey then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer;

    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();

    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange));
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange));

Environment.Library = Library
return Library
