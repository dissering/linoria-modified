-- Compact dashboard-style Linoria Modified example with optional Lucide tab icons.
-- Run this from a local checkout of Linoria Modified so the bundled PNG assets can
-- be resolved by getcustomasset(). The UI elements are still native Linoria
-- toggles, sliders, dropdowns, buttons, dependency boxes, and managers.

local repo = 'https://raw.githubusercontent.com/dissering/linoria-modified/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local LucideIcons = loadstring(game:HttpGet(repo .. 'addons/LucideIcons.lua'))()
local DashboardWidgets = loadstring(game:HttpGet(repo .. 'addons/DashboardWidgets.lua'))()

-- Change this to wherever the bundled assets were placed on the executor.
LucideIcons:SetFolder('assets/lucide/png')
DashboardWidgets:SetLibrary(Library)

local Window = Library:CreateWindow({
    Title = 'LINORIA MODIFIED // CONTROL PANEL',
    Subtitle = 'FLUENT // ONLINE',
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(760, 540),
    TabPadding = 4,
    TabIconSize = 16,
    TabIconPadding = 5,
    SideTabs = true,
    TabRailWidth = 126,
    TabHeight = 32,
    CornerRadius = 6,
    Motion = true,
    BackgroundBlur = true,
    BackgroundBlurSize = 9,
    BackgroundDimTransparency = 0.48,
    MenuFadeTime = 0.18,
})

local function Tab(Name, Icon)
    return Window:AddTab({
        Name = Name,
        Icon = LucideIcons:Get(Icon),
    })
end

local Tabs = {
    Combat = Tab('Combat', 'Combat'),
    Visuals = Tab('Visuals', 'Visuals'),
    World = Tab('World', 'World'),
    Players = Tab('Players', 'Players'),
    Settings = Tab('Settings', 'Settings'),
}

Library:SetWatermark('LINORIA MODIFIED // FLUENT')

local Radar = DashboardWidgets:CreateRadar({
    Title = 'RADAR',
    Icon = LucideIcons:Get('World'),
    Position = UDim2.fromOffset(42, 180),
    Size = UDim2.fromOffset(182, 194),
})

local EspPreview = DashboardWidgets:CreatePanel({
    Title = 'ESP PREVIEW',
    Icon = LucideIcons:Get('Visuals'),
    Position = UDim2.fromOffset(246, 180),
    Size = UDim2.fromOffset(210, 194),
})
EspPreview:AddText('TARGET MODEL', Library.FontColor, 15)
EspPreview:AddText('  humanoid_root_part', Library:GetDarkerColor(Library.FontColor), 15)
EspPreview:AddBar('Visibility', 0.78, Library.AccentColor)
EspPreview:AddBar('Distance', 0.42, Color3.fromRGB(82, 224, 158))
EspPreview:AddText('status: tracked', Color3.fromRGB(82, 224, 158), 15)

local Console = DashboardWidgets:CreateConsole({
    Title = 'CONSOLE',
    Icon = LucideIcons:Get('Console'),
    Position = UDim2.fromOffset(48, 402),
    Size = UDim2.fromOffset(408, 142),
})
Console:AddOutput('[info] dashboard initialized')
Console:AddOutput('[info] widgets connected')

local PlayersWidget = DashboardWidgets:CreatePlayerList({
    Title = 'PLAYERS',
    Icon = LucideIcons:Get('Players'),
    Position = UDim2.fromOffset(1390, 160),
    Size = UDim2.fromOffset(290, 232),
})

local StatsWidget = DashboardWidgets:CreateStats({
    Title = 'STATS',
    Icon = LucideIcons:Get('Interface'),
    Position = UDim2.fromOffset(1410, 420),
    Size = UDim2.fromOffset(220, 140),
})

local TargetWidget = DashboardWidgets:CreatePanel({
    Title = 'TARGET INDICATOR',
    Icon = LucideIcons:Get('Crosshair'),
    Position = UDim2.fromOffset(790, 630),
    Size = UDim2.fromOffset(260, 82),
})
TargetWidget:AddText('NO TARGET SELECTED', Library.FontColor, 15)
TargetWidget:AddBar('Health', 0, Color3.fromRGB(82, 224, 158))

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
UiSettings:AddToggle('ShowDashboardWidgets', {
    Text = 'Show dashboard widgets',
    Default = true,
    Callback = function(Value)
        for _, Widget in next, DashboardWidgets.Items do
            Widget:SetVisible(Value)
        end
    end,
})
UiSettings:AddLabel('Menu keybind'):AddKeyPicker('MenuKeybind', {
    Default = 'Insert',
    NoUI = true,
    Text = 'Menu keybind',
})
UiSettings:AddButton('Unload', function()
    Library:Unload()
end)

Library:OnUnload(function()
    DashboardWidgets:DestroyAll()
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
