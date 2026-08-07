# Lucide assets

These icons are sourced from `lucide-static` 1.30.0 from [Lucide](https://github.com/lucide-icons/lucide), an ISC-licensed icon set.

- `svg/` contains all 2,022 static icon names with their official Lucide geometry and a white stroke.
- `png-white-256/` contains all 2,022 matching antialiased transparent PNGs for `getcustomasset()`/`ImageLabel` use.
- `icons.json` records the package version and complete sorted icon-name catalog.
- `png/`, `png-white/`, and `png-white-96/` are retained as legacy subsets; new code should use `png-white-256/`.

If an executor has `writefile` and `makefolder` but does not have the PNGs yet,
`Library:GetLucideIcon()` and `LucideIcons:Get()` download the requested asset
from this repository before resolving it with `getcustomasset()`.

Names are case-insensitive and accept kebab-case, snake_case, or CamelCase. For
example, `settings-2`, `settings_2`, and `Settings2` resolve to the same asset.
