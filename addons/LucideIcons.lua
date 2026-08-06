-- Local Lucide asset resolver for Linoria Modified.
--
-- The repository includes SVG sources and 18px PNGs under:
--   assets/lucide/svg
--   assets/lucide/png
--
-- In an executor, getcustomasset() turns the PNG path into an ImageLabel URL.
-- If the asset API is unavailable, Get() returns nil and Linoria simply draws
-- a text-only tab, preserving compatibility with ordinary Roblox clients.

local LucideIcons = {
    Folder = 'assets/lucide/png',

    Names = {
        Combat = 'swords',
        Visuals = 'eye',
        World = 'radar',
        Players = 'users-round',
        Settings = 'settings-2',
        Console = 'terminal',
        Theme = 'palette',
        Security = 'shield-check',
        Crosshair = 'crosshair',
        Map = 'map',
        Interface = 'monitor-cog',
        Input = 'mouse-pointer-2',
    },
};

function LucideIcons:SetFolder(Folder)
    assert(type(Folder) == 'string' and Folder ~= '', 'LucideIcons:SetFolder expects a non-empty folder')
    self.Folder = Folder
    return self
end;

function LucideIcons:GetPath(Name)
    local FileName = self.Names[Name] or Name

    if type(FileName) ~= 'string' or FileName == '' then
        return nil
    end;

    return string.format('%s/%s.png', self.Folder, FileName)
end;

function LucideIcons:Get(Name)
    local Path = self:GetPath(Name)

    if not Path or type(getcustomasset) ~= 'function' then
        return nil
    end;

    local Success, Asset = pcall(getcustomasset, Path)

    if Success and type(Asset) == 'string' and Asset ~= '' then
        return Asset
    end;

    return nil
end;

return LucideIcons
