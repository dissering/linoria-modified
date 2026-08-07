-- Clean, square Linoria Modified example with optional Lucide tab icons.
-- The UI elements remain native Linoria toggles, sliders, dropdowns, buttons,
-- dependency boxes, and managers.

local repo = 'https://raw.githubusercontent.com/dissering/linoria-modified/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local LucideIcons = loadstring(game:HttpGet(repo .. 'addons/LucideIcons.lua'))()
local GameInfo = loadstring(game:HttpGet(repo .. 'addons/GameInfo.lua'))()

-- Change this to wherever the bundled assets were placed on the executor.
LucideIcons:SetFolder('assets/lucide/png-white')

local Window = Library:CreateWindow({
    Title = 'LINORIA MODIFIED',
    Subtitle = '',
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(788, 500),
    TabPadding = 2,
    TabIconSize = 16,
    TabIconPadding = 6,
    IconOnlyTabs = true,
    SideTabs = true,
    TabRailWidth = 148,
    TabHeight = 34,
    CornerRadius = 0,
    Motion = true,
    BackgroundBlur = true,
    BackgroundBlurSize = 12,
    BackgroundBlurAnimate = false,
    BackgroundDimTransparency = 0.52,
    MenuFadeTime = 0.16,
})

local CurrentGame = GameInfo:Get()

local function Tab(Name, Icon)
    return Window:AddTab({
        Name = Name,
        Icon = LucideIcons:Get(Icon),
    })
end

local Tabs = {
    Loader = Tab('Loader', 'Loader'),
    Combat = Tab('Combat', 'Combat'),
    Visuals = Tab('Visuals', 'Visuals'),
    World = Tab('World', 'World'),
    Players = Tab('Players', 'Players'),
    Settings = Tab('Settings', 'Settings'),
}

local GameScriptUrls = {
    -- Add game-specific endpoints here, for example:
    -- [123456789] = 'https://example.com/game-script.lua',
}

local GlobalEnvironment = type(getgenv) == 'function' and getgenv() or _G
local GameScriptUrl = GlobalEnvironment.LinoriaModifiedScriptUrl or GameScriptUrls[CurrentGame.PlaceId]

local LoaderInfo = Tabs.Loader:AddLeftGroupbox('GAME INFO')
local GameLogo = Library:Create('ImageLabel', {
    BackgroundColor3 = Library.MainColor;
    BorderColor3 = Library.OutlineColor;
    Image = CurrentGame.Icon or '';
    Size = UDim2.fromOffset(72, 72);
    Visible = type(CurrentGame.Icon) == 'string' and CurrentGame.Icon ~= '';
    ScaleType = Enum.ScaleType.Fit;
    ZIndex = 5;
    Parent = LoaderInfo.Container;
})

local LogoScale = Library:Create('UIScale', {
    Scale = 1;
    Parent = GameLogo;
})

LoaderInfo:AddLabel('GAME', false)
LoaderInfo:AddLabel(CurrentGame.Name, true)
local PlayingLabel = LoaderInfo:AddLabel('PLAYING   ' .. tostring(CurrentGame.Playing), false)
local UpdatedLabel = LoaderInfo:AddLabel('UPDATED   ' .. CurrentGame.Updated, false)
LoaderInfo:AddLabel('PLACE ID  ' .. tostring(CurrentGame.PlaceId), false)
LoaderInfo:Resize()

local LoaderOptions = Tabs.Loader:AddRightGroupbox('LOAD SCRIPT')
LoaderOptions:AddLabel('LOAD SCRIPT FOR THIS GAME', true)
LoaderOptions:AddLabel('The script endpoint is selected for the current place.', true)
local LoaderStatus = LoaderOptions:AddLabel(GameScriptUrl and 'STATUS    READY' or 'STATUS    NO ENDPOINT', false)
LoaderOptions:AddLabel('PLAYERS   ' .. tostring(CurrentGame.Playing), false)
LoaderOptions:AddButton({
    Text = 'Load script',
    Func = function()
        if type(GameScriptUrl) ~= 'string' or GameScriptUrl == '' then
            LoaderStatus:SetText('STATUS    NO ENDPOINT')
            Library:Notify('Add a game script endpoint first', 3)
            return
        end

        LoaderStatus:SetText('STATUS    DOWNLOADING')

        local HttpSuccess, Source = pcall(function()
            return game:HttpGet(GameScriptUrl)
        end)

        if not HttpSuccess or type(Source) ~= 'string' or Source == '' then
            LoaderStatus:SetText('STATUS    DOWNLOAD FAILED')
            Library:Notify('Unable to download the game script', 3)
            return
        end

        local Compile = loadstring or load
        local CompileSuccess, CompiledOrError = false, nil

        if type(Compile) == 'function' then
            CompileSuccess, CompiledOrError = pcall(Compile, Source)
        end

        local Chunk = CompileSuccess and CompiledOrError or nil
        local CompileError = CompileSuccess and nil or CompiledOrError

        if not Chunk then
            LoaderStatus:SetText('STATUS    COMPILE FAILED')
            Library:Notify(tostring(CompileError or 'Invalid script'), 3)
            return
        end

        LoaderStatus:SetText('STATUS    LOADING')
        local RunSuccess, RuntimeError = pcall(Chunk)

        if not RunSuccess then
            LoaderStatus:SetText('STATUS    RUNTIME FAILED')
            Library:Notify(tostring(RuntimeError), 3)
            return
        end

        LoaderStatus:SetText('STATUS    LOADED')
        Library:Notify(CurrentGame.Name .. ' loaded', 2)
    end,
})
LoaderOptions:AddButton('Refresh game info', function()
    local FreshInfo = GameInfo:Get()
    CurrentGame.Playing = FreshInfo.Playing
    CurrentGame.Updated = FreshInfo.Updated
    PlayingLabel:SetText('PLAYING   ' .. tostring(FreshInfo.Playing))
    UpdatedLabel:SetText('UPDATED   ' .. FreshInfo.Updated)
    Library:Notify('Game information refreshed', 2)
end)
LoaderOptions:Resize()

task.spawn(function()
    while GameLogo.Parent do
        Library:Tween(LogoScale, { Scale = 1.06 }, 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(0.7)
        Library:Tween(LogoScale, { Scale = 1 }, 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(0.7)
    end
end)

local CombatAim = Tabs.Combat:AddLeftGroupbox('Targeting')
CombatAim:AddToggle('CombatEnabled', {
    Text = 'Enable targeting',
    Default = false,
    Tooltip = 'Master switch for the combat module.',
})
CombatAim:AddToggle('CombatFov', {
    Text = 'Use FOV check',
    Default = true,
})
CombatAim:AddSlider('CombatFovSize', {
    Text = 'FOV radius',
    Default = 90,
    Min = 0,
    Max = 180,
    Rounding = 0,
    Suffix = '°',
})
CombatAim:AddDropdown('CombatPart', {
    Text = 'Target part',
    Values = { 'Head', 'UpperTorso', 'HumanoidRootPart' },
    Default = 1,
})

local CombatUtility = Tabs.Combat:AddRightGroupbox('Utilities')
CombatUtility:AddToggle('CombatSilent', {
    Text = 'Silent mode',
    Default = false,
})
CombatUtility:AddToggle('CombatPrediction', {
    Text = 'Prediction',
    Default = true,
})
CombatUtility:AddSlider('CombatPredictionAmount', {
    Text = 'Prediction amount',
    Default = 12,
    Min = 0,
    Max = 30,
    Rounding = 1,
})

local VisualEsp = Tabs.Visuals:AddLeftGroupbox('ESP')
VisualEsp:AddToggle('EspEnabled', {
    Text = 'Enable ESP',
    Default = true,
})
VisualEsp:AddToggle('EspBoxes', { Text = 'Boxes', Default = true })
VisualEsp:AddToggle('EspNames', { Text = 'Names', Default = true })
VisualEsp:AddToggle('EspDistance', { Text = 'Distance', Default = false })
VisualEsp:AddLabel('ESP color'):AddColorPicker('EspColor', {
    Default = Color3.fromRGB(105, 157, 255),
    Title = 'ESP color',
})

local VisualCrosshair = Tabs.Visuals:AddRightGroupbox('Crosshair')
VisualCrosshair:AddToggle('CrosshairEnabled', {
    Text = 'Enable crosshair',
    Default = false,
})
VisualCrosshair:AddSlider('CrosshairSize', {
    Text = 'Size',
    Default = 8,
    Min = 2,
    Max = 24,
    Rounding = 0,
    Suffix = 'px',
})
VisualCrosshair:AddSlider('CrosshairGap', {
    Text = 'Spacing',
    Default = 4,
    Min = 0,
    Max = 16,
    Rounding = 0,
    Suffix = 'px',
})

local WorldMain = Tabs.World:AddLeftGroupbox('World')
WorldMain:AddToggle('WorldFullbright', { Text = 'Fullbright', Default = false })
WorldMain:AddToggle('WorldNoFog', { Text = 'Remove fog', Default = false })
WorldMain:AddSlider('WorldBrightness', {
    Text = 'Brightness',
    Default = 2,
    Min = 0,
    Max = 5,
    Rounding = 1,
})

local PlayersList = Tabs.Players:AddLeftGroupbox('Player list')
PlayersList:AddDropdown('SelectedPlayer', {
    Text = 'Selected player',
    SpecialType = 'Player',
    Default = 1,
})
PlayersList:AddButton('Refresh players', function()
    Library:Notify('Player list refreshed')
end)

local UiSettings = Tabs.Settings:AddLeftGroupbox('Interface')
UiSettings:AddToggle('ShowWatermark', {
    Text = 'Show watermark',
    Default = true,
})
UiSettings:AddLabel('Menu keybind'):AddKeyPicker('MenuKeybind', {
    Default = 'Insert',
    NoUI = true,
    Text = 'Menu keybind',
})
UiSettings:AddButton('Unload', function()
    Library:Unload()
end)

local MenuGroup = Tabs.Settings:AddRightGroupbox('Theme')
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('LinoriaModified')
SaveManager:SetFolder('LinoriaModified/configs')
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToGroupbox(MenuGroup)
SaveManager:LoadAutoloadConfig()

Library:Notify('Linoria Modified control panel loaded')
