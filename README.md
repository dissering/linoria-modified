# Linoria Modified
A Roblox UI library inspired by Splix, BBot and many others.

Used in the Linoria script hub: https://kyaru.cloud

###### Example Script:
* [Example](Example.lua) - loads the Linoria Modified dashboard
* [Full dashboard example](LinoriaModifiedExample.lua)

###### Interface Addons:
* [Theme Manager](addons/ThemeManager.lua)&nbsp;&nbsp;|&nbsp;&nbsp;[Save Manager](addons/SaveManager.lua) 

## Features
- Tabs, group boxes, and tab boxes
- Almost any UI element you would ever need (toggles, sliders, dropdowns, etc)
- Interface automatically becomes scrollable whenever there are too many UI elements
- Dependency boxes, allowing you to easily hide/show UI elements depending on the state of other UI elements
- Optional icon tabs with local executor assets: `Window:AddTab({ Name = 'Combat', Icon = 'rbxassetid://...' })`

## Linoria Modified dashboard example

`Example.lua` now loads `LinoriaModifiedExample.lua`, which keeps Linoria's native controls and managers but adds a clean left navigation rail, rounded monochrome styling, page-like tabs, animated page transitions, menu-only blur/dim effects, searchable dropdowns, and optional Lucide icons. The bundled Lucide SVG sources and antialiased executor-ready 96px PNGs live in `assets/lucide/`.

```lua
local Icons = loadstring(game:HttpGet(repo .. 'addons/LucideIcons.lua'))()
Icons:SetFolder('assets/lucide/png-white-96')

local Combat = Window:AddTab({
    Name = 'Combat',
    Icon = Icons:Get('Combat'),
})
```

When `getcustomasset` is unavailable, the icon is skipped and the tab stays fully functional.


## Interface Preview
<img src="https://i.imgur.com/qs0Hqc6.png" />

## Contributors
- Inori: Main developer.
- Wally: Cleaning up verbose code, extending library functionality.
- Stefanuk: Extending library functionality.
- matas3535: Creator of Splix.
