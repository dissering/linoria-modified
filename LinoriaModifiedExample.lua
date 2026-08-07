-- Clean, square Linoria Modified example with optional Lucide tab icons.
-- The UI elements remain native Linoria toggles, sliders, dropdowns, buttons,
-- dependency boxes, and managers.

local repo = 'https://raw.githubusercontent.com/dissering/linoria-modified/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local LucideIcons = loadstring(game:HttpGet(repo .. 'addons/LucideIcons.lua'))()

-- Versioned high-resolution assets avoid stale 18px executor caches.
LucideIcons:SetFolder('assets/lucide/png-white-96')

local Window = Library:CreateWindow({
    Title = 'LINORIA MODIFIED',
    Subtitle = '',
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(788, 500),
    TabPadding = 0,
    TabIconSize = 28,
    TabIconPadding = 8,
    IconOnlyTabs = true,
    SideTabs = true,
    TabRailWidth = 74,
    TabHeight = 70,
    CornerRadius = 8,
    Motion = true,
    BackgroundBlur = true,
    BackgroundBlurSize = 12,
    BackgroundBlurAnimate = false,
    BackgroundDimTransparency = 0.52,
    MenuFadeTime = 0.16,
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
SaveManager:BuildConfigSection(Tabs.Settings, 'Left')
ThemeManager:ApplyToGroupbox(MenuGroup)
SaveManager:LoadAutoloadConfig()

Library:Notify('Linoria Modified control panel loaded')
