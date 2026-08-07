# Lucide assets

These icons are sourced from [Lucide](https://github.com/lucide-icons/lucide), an ISC-licensed icon set.

- `svg/` contains the original 24px Lucide SVG sources with a white stroke.
- `png/` and `png-white/` contain white 18px transparent PNGs rendered for `getcustomasset()`/`ImageLabel` use. The example uses the versioned `png-white/` folder so old colored executor caches are bypassed.
- `addons/LucideIcons.lua` maps friendly names such as `Combat` and `Visuals` to these files.

If an executor has `writefile` and `makefolder` but does not have the PNGs yet,
`LucideIcons:Get()` downloads the requested asset from this repository into
`assets/lucide/png-white` before resolving it with `getcustomasset()`.

The PNG files are the runtime assets used by `LinoriaModifiedExample.lua`; the SVG files are kept as editable sources if you want to change stroke color or size.
