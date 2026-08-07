-- Local Lucide asset resolver for Linoria Modified.
--
-- The repository includes SVG sources and antialiased 256px PNGs under:
--   assets/lucide/svg
--   assets/lucide/png-white-256
--
-- In an executor, getcustomasset() turns the PNG path into an ImageLabel URL.
-- Missing PNGs are downloaded from this repository automatically when the
-- executor exposes writefile/makefolder.
-- If the asset API is unavailable, Get() returns nil and Linoria simply draws
-- a text-only tab, preserving compatibility with ordinary Roblox clients.

local LucideIcons = {
    Version = '1.30.0',
    -- Versioned so executors do not reuse an older cached colored icon set.
    Folder = 'assets/lucide/png-white-256',
    DownloadBaseUrl = 'https://raw.githubusercontent.com/dissering/linoria-modified/main/assets/lucide/png-white-256/',
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
    },
};

function LucideIcons:Normalize(Name)
    if type(Name) ~= 'string' then
        return nil;
    end;

    Name = self.Names[Name] or Name;
    Name = Name:gsub('^%s+', ''):gsub('%s+$', '');

    if Name == '' then
        return nil;
    end;

    local HadSeparator = Name:find('[-_%s]') ~= nil;

    Name = Name:gsub('(%u)(%u%l)', '%1-%2');
    Name = Name:gsub('(%l)(%u)', '%1-%2');

    if not HadSeparator then
        Name = Name:gsub('(%a)(%d)', '%1-%2');
        Name = Name:gsub('(%d)(%a)', '%1-%2');
    end;

    Name = Name:gsub('[%s_]+', '-');
    Name = Name:gsub('%-+', '-'):lower();

    if not Name:match('^[%w%-]+$') then
        return nil;
    end;

    return Name;
end;

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
    local FileName = self:Normalize(Name);

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
    local FileName = self:Normalize(Name);

    if not Path or not FileName or self.AttemptedDownloads[Path] then
        return;
    end;

    self.AttemptedDownloads[Path] = true;

    if type(writefile) ~= 'function' or not game then
        return;
    end;

    local Success, Data = pcall(function()
        return game:HttpGet(self.DownloadBaseUrl .. FileName .. '.png');
    end);

    if not Success
        or type(Data) ~= 'string'
        or #Data < 24
        or Data:sub(1, 8) ~= '\137PNG\r\n\26\n' then

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

function LucideIcons:ApplyToLibrary(Library)
    assert(type(Library) == 'table', 'LucideIcons:ApplyToLibrary expects the Linoria library');

    if Library.SetLucideFolder then
        Library:SetLucideFolder(self.Folder);
    end;

    if Library.SetLucideDownloadBaseUrl then
        Library:SetLucideDownloadBaseUrl(self.DownloadBaseUrl);
    end;

    return self;
end;

return LucideIcons
