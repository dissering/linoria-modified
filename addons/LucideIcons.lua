-- Local Lucide asset resolver for Linoria Modified.
--
-- The repository includes SVG sources and 18px PNGs under:
--   assets/lucide/svg
--   assets/lucide/png-white
--
-- In an executor, getcustomasset() turns the PNG path into an ImageLabel URL.
-- Missing PNGs are downloaded from this repository automatically when the
-- executor exposes writefile/makefolder.
-- If the asset API is unavailable, Get() returns nil and Linoria simply draws
-- a text-only tab, preserving compatibility with ordinary Roblox clients.

local LucideIcons = {
    -- Versioned so executors do not reuse an older cached colored icon set.
    Folder = 'assets/lucide/png-white',
    DownloadBaseUrl = 'https://raw.githubusercontent.com/dissering/linoria-modified/main/assets/lucide/png-white/',
    AttemptedDownloads = {},

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
        Loader = 'download',
        Download = 'download',
    },
};

function LucideIcons:SetFolder(Folder)
    assert(type(Folder) == 'string' and Folder ~= '', 'LucideIcons:SetFolder expects a non-empty folder')
    self.Folder = Folder
    return self
end;

function LucideIcons:SetDownloadBaseUrl(Url)
    assert(type(Url) == 'string' and Url ~= '', 'LucideIcons:SetDownloadBaseUrl expects a non-empty URL')
    self.DownloadBaseUrl = Url:gsub('/+$', '') .. '/'
    return self
end;

function LucideIcons:GetPath(Name)
    local FileName = self.Names[Name] or Name

    if type(FileName) ~= 'string' or FileName == '' then
        return nil
    end;

    return string.format('%s/%s.png', self.Folder, FileName)
end;

function LucideIcons:EnsureFolder()
    if type(makefolder) ~= 'function' then
        return;
    end;

    local Current = '';

    for Segment in string.gmatch(self.Folder, '[^/\\]+') do
        Current = Current == '' and Segment or Current .. '/' .. Segment;
        pcall(makefolder, Current);
    end;
end;

function LucideIcons:Resolve(Name)
    local Path = self:GetPath(Name)

    if not Path or type(getcustomasset) ~= 'function' then
        return nil
    end;

    local Success, Asset = pcall(getcustomasset, Path)

    if Success and type(Asset) == 'string' and Asset ~= '' then
        return Asset;
    end;

    return nil;
end;

function LucideIcons:Download(Name)
    local Path = self:GetPath(Name)

    if not Path or self.AttemptedDownloads[Path] then
        return;
    end;

    self.AttemptedDownloads[Path] = true;

    if type(writefile) ~= 'function' or not game then
        return;
    end;

    local FileName = self.Names[Name] or Name;
    local Success, Data = pcall(function()
        return game:HttpGet(self.DownloadBaseUrl .. FileName .. '.png');
    end);

    if not Success or type(Data) ~= 'string' or #Data < 20 then
        return;
    end;

    self:EnsureFolder();
    pcall(writefile, Path, Data);
end;

function LucideIcons:Get(Name)
    local Asset = self:Resolve(Name);

    if Asset then
        return Asset;
    end;

    self:Download(Name);
    return self:Resolve(Name);
end;

return LucideIcons
