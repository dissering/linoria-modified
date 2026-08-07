-- Clean, square Linoria Modified example with optional Lucide tab icons.
-- The UI elements remain native Linoria toggles, sliders, dropdowns, buttons,
-- dependency boxes, and managers.

local repo = 'https://raw.githubusercontent.com/dissering/linoria-modified/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local DashboardWidgets = loadstring(game:HttpGet(repo .. 'addons/DashboardWidgets.lua'))()

local Window = Library:CreateWindow({
    Title = 'zzz',
    Subtitle = '',
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(720, 360),
    TabPadding = 3,
    TabIconSize = 18,
    TabIconPadding = 6,
    IconOnlyTabs = true,
    SideTabs = false,
    TopRightTabs = true,
    FillSideTabs = false,
    AccentGlow = false,
    TabRailWidth = 74,
    TabHeight = 21,
    CornerRadius = 8,
    Motion = true,
    Draggable = false,
    Responsive = true,
    AutoFitContentHeight = false,
    ContentBottomPadding = 18,
    MobileBreakpoint = 640,
    MobileMargin = 10,
    BackgroundBlur = true,
    BackgroundBlurSize = 20,
    BackgroundBlurAnimate = false,
    BackgroundDimTransparency = 0.52,
    MenuFadeTime = 0.16,
})

local function Tab(Name, Icon)
    return Window:AddTab({
        Name = Name,
        Icon = Icon,
    })
end

local Tabs = {
    Combat = Tab('Combat', 'swords'),
    Visuals = Tab('Visuals', 'eye'),
    World = Tab('World', 'radar'),
    Components = Tab('Components', 'monitor-cog'),
    Settings = Tab('Settings', 'settings-2'),
}

DashboardWidgets:SetLibrary(Library)

local PlayerListWidget = DashboardWidgets:CreatePlayerList({
    Title = 'PLAYER LIST',
    AttachTo = Window,
    Side = 'Right',
    Gap = 8,
    Size = UDim2.fromOffset(300, 360),
    MatchHeight = true,
    MinimumHeight = 0,
    MatchWindowStyle = true,
    Draggable = false,
    ShowHeadshots = true,
    HeadshotSize = 18,
    Columns = { 'Name', 'UserId', 'Priority' },
    Priorities = { 'Friendly', 'Neutral', 'Priority' },
    DefaultPriority = 'Neutral',
    RowHeight = 24,
    Actions = { 'Teleport', 'Spectate', 'StopSpectating', 'Refresh' },
})

local CombatAim = Tabs.Combat:AddLeftGroupbox('Targeting')
CombatAim:AddToggle('CombatEnabled', {
    Text = 'Enable targeting',
    Default = false,
    Tooltip = 'Master switch for the combat module.',
}):AddKeyPicker('CombatKeybind', {
    Default = 'Q',
    SyncToggleState = true,
    Text = 'Targeting',
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
}):AddKeyPicker('EspKeybind', {
    Default = 'V',
    SyncToggleState = true,
    Text = 'ESP',
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
WorldMain:AddToggle('WorldFullbright', {
    Text = 'Fullbright',
    Default = false,
}):AddKeyPicker('FullbrightKeybind', {
    Default = 'B',
    SyncToggleState = true,
    Text = 'Fullbright',
})
WorldMain:AddToggle('WorldNoFog', { Text = 'Remove fog', Default = false })
WorldMain:AddSlider('WorldBrightness', {
    Text = 'Brightness',
    Default = 2,
    Min = 0,
    Max = 5,
    Rounding = 1,
})

-- Component gallery: tabboxes act as compact sub-pages inside a main page.
local ComponentPages = Tabs.Components:AddLeftTabbox('Component pages')
local ControlsPage = ComponentPages:AddTab('Controls')
ControlsPage:AddToggle('ExampleEnabled', {
    Text = 'Example toggle',
    Default = true,
}):AddKeyPicker('ExampleKeybind', {
    Default = 'E',
    SyncToggleState = true,
    Text = 'Example toggle',
})
ControlsPage:AddBlank(2)
ControlsPage:AddSlider('ExampleAmount', {
    Text = 'Example slider',
    Default = 45,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = '%',
})
ControlsPage:AddDropdown('ExampleDropdown', {
    Text = 'Searchable dropdown',
    Values = { 'First option', 'Second option', 'Third option', 'Fourth option' },
    Default = 1,
})
ControlsPage:AddInput('ExampleInput', {
    Text = 'Text input',
    Default = 'hello',
    Finished = true,
})
ControlsPage:AddLabel('Example color'):AddColorPicker('ExampleColor', {
    Default = Color3.fromRGB(213, 139, 166),
    Title = 'Example color',
})

local AdvancedPage = ComponentPages:AddTab('Advanced')
AdvancedPage:AddDropdown('ExampleMultiDropdown', {
    Text = 'Multi-select dropdown',
    Values = { 'Alpha', 'Beta', 'Gamma', 'Delta' },
    Default = { 'Alpha', 'Gamma' },
    Multi = true,
})
local DependencyToggle = AdvancedPage:AddToggle('ExampleDependency', {
    Text = 'Show dependent controls',
    Default = true,
})
local DependencyBox = AdvancedPage:AddDependencyBox()
DependencyBox:SetupDependencies({ { DependencyToggle, true } })
DependencyBox:AddSlider('ExampleDependentSlider', {
    Text = 'Dependent value',
    Default = 5,
    Min = 1,
    Max = 10,
    Rounding = 0,
})
DependencyBox:AddButton('Dependent action', function()
    Library:Notify('Dependent action clicked')
end)

local ComponentActions = Tabs.Components:AddRightGroupbox('Actions')
ComponentActions:AddLabel('Buttons, notifications, dividers, and wrapped labels.')
ComponentActions:AddButton({
    Text = 'Show notification',
    Func = function()
        Library:Notify('This is a Linoria notification')
    end,
})
ComponentActions:AddBlank(4)
ComponentActions:AddButton({
    Text = 'Primary action',
    Func = function()
        Library:Notify('Primary action clicked')
    end,
}):AddButton({
    Text = 'Secondary',
    Func = function()
        Library:Notify('Secondary action clicked')
    end,
})
ComponentActions:AddLabel('The Controls and Advanced headers on the left are sub-pages.', true)

local UiSettings = Tabs.Settings:AddLeftGroupbox('Interface')
Library:StartWatermark({
    Title = 'zzz',
    AttachTo = Window,
    Alignment = 'Center',
    Gap = 6,
    ShowPlayer = true,
    ShowFPS = true,
    ShowPing = true,
    ShowTime = true,
    RefreshRate = 0.5,
})
UiSettings:AddToggle('ShowWatermark', {
    Text = 'Show watermark',
    Default = true,
    Callback = function(Value)
        Library:SetWatermarkVisibility(Value)
    end,
})
Library:SetKeybindVisibility(true)
UiSettings:AddToggle('ShowKeybinds', {
    Text = 'Show keybind list',
    Default = true,
    Callback = function(Value)
        Library:SetKeybindVisibility(Value)
    end,
})
UiSettings:AddLabel('Menu keybind'):AddKeyPicker('MenuKeybind', {
    Default = 'RightControl',
    Modes = { 'Toggle' },
    NoUI = true,
    Text = 'Menu keybind',
})
Library.ToggleKeybind = Options.MenuKeybind
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

Window:ApplyResponsiveLayout()
task.defer(function()
    Window:ApplyResponsiveLayout()

    if PlayerListWidget.UpdateAttachedPosition then
        PlayerListWidget:UpdateAttachedPosition()
    end

    if Library.UpdateWatermarkAttachment then
        Library.UpdateWatermarkAttachment()
    end
end)

Library:Notify('zzz loaded')
