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
- Complete Lucide 1.30.0 catalog with direct names such as `Icon = 'eye'` or `Logo = 'sparkles'`
- Bundled Proggy Clean font with a sharp built-in Code fallback
- Responsive touch layout with automatic one-column reflow on narrow mobile screens
- Draggable/tappable watermark and clickable keybind HUD actions
- Theme-synchronized gradient surfaces, animated switches, slider thumbs, dropdowns, tabs, buttons, and tooltips

## Linoria Modified dashboard example

`Example.lua` now loads `LinoriaModifiedExample.lua`, which keeps Linoria's native controls and managers but adds compact top-right icon navigation, rounded monochrome cards, animated page/control transitions, menu-only blur/dim effects, searchable dropdowns, responsive touch input, and optional Lucide icons. The bundled Lucide SVG sources and antialiased executor-ready 256px PNGs live in `assets/lucide/`.

```lua
local Window = Library:CreateWindow({
    Title = 'zzz',
    Logo = 'sparkles',
})

local Combat = Window:AddTab({
    Name = 'Combat',
    Icon = 'eye',
})
```

All 2,022 names from `lucide-static` 1.30.0 are included in [`assets/lucide/icons.json`](assets/lucide/icons.json). Names are case-insensitive and accept kebab-case, snake_case, or CamelCase. Missing local PNGs are downloaded on demand when the executor provides `writefile`, `makefolder`, and `getcustomasset`.

The compact UI font is bundled at [`assets/fonts/ProggyClean.ttf`](assets/fonts/ProggyClean.ttf). It is downloaded once into the executor asset folder and applied through `FontFace`; executors without custom-font support automatically use Roblox's sharp monospace `Code` font.

Icons can also be changed at runtime with `Window:SetLogo('eye')` and `Tabs.Combat:SetIcon('crosshair')`.

The main window is static by default. Set `Draggable = true` to opt back into window dragging. `Responsive = true` (the default) resizes to the viewport and reflows two columns into one when `TouchEnabled` is active on a narrow screen.

When `getcustomasset` is unavailable, the icon is skipped and the tab stays fully functional.


## Interface Preview
<img src="https://i.imgur.com/qs0Hqc6.png" />

## Contributors
- Inori: Main developer.
- Wally: Cleaning up verbose code, extending library functionality.
- Stefanuk: Extending library functionality.
- matas3535: Creator of Splix.
