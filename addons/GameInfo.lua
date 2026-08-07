-- Roblox game metadata helper for the Linoria Modified loader page.

local HttpService = game:GetService('HttpService');
local MarketplaceService = game:GetService('MarketplaceService');
local Players = game:GetService('Players');

local GameInfo = {};

local function RequestJson(Url)
    if type(game.HttpGet) ~= 'function' then
        return nil;
    end;

    local Success, Body = pcall(function()
        return game:HttpGet(Url);
    end);

    if not Success or type(Body) ~= 'string' or Body == '' then
        return nil;
    end;

    local DecodedSuccess, Decoded = pcall(HttpService.JSONDecode, HttpService, Body);
    return DecodedSuccess and Decoded or nil;
end;

local function FormatUpdated(Value)
    if type(Value) ~= 'string' or Value == '' then
        return 'UNKNOWN';
    end;

    local Success, Date = pcall(DateTime.fromIsoDate, Value);

    if Success and Date then
        local FormatSuccess, Formatted = pcall(function()
            return Date:FormatUniversalTime('MMM D, YYYY', 'en-us');
        end);

        if FormatSuccess and type(Formatted) == 'string' then
            return string.upper(Formatted);
        end;
    end;

    return string.upper(string.sub(Value, 1, 10));
end;

local function EnsureFolder(Folder)
    if type(makefolder) ~= 'function' then
        return;
    end;

    local Current = '';

    for Segment in string.gmatch(Folder, '[^/\\]+') do
        Current = Current == '' and Segment or Current .. '/' .. Segment;
        pcall(makefolder, Current);
    end;
end;

local function ResolveIcon(AssetId, UniverseId)
    local Number = tonumber(AssetId);

    if Number and Number > 0 then
        return 'rbxassetid://' .. tostring(Number);
    end;

    if not UniverseId or UniverseId <= 0 or type(writefile) ~= 'function' or type(getcustomasset) ~= 'function' then
        return nil;
    end;

    local ThumbnailData = RequestJson('https://thumbnails.roblox.com/v1/games/icons?universeIds=' .. tostring(UniverseId) .. '&size=150x150&format=Png&isCircular=false');
    local ImageUrl = ThumbnailData and ThumbnailData.data and ThumbnailData.data[1] and ThumbnailData.data[1].imageUrl;

    if type(ImageUrl) ~= 'string' or ImageUrl == '' then
        return nil;
    end;

    local Folder = 'assets/cache';
    local Path = Folder .. '/game-icon-' .. tostring(UniverseId) .. '.png';
    local ExistingSuccess, ExistingAsset = pcall(getcustomasset, Path);

    if ExistingSuccess and type(ExistingAsset) == 'string' and ExistingAsset ~= '' then
        return ExistingAsset;
    end;

    local DownloadSuccess, Data = pcall(function()
        return game:HttpGet(ImageUrl);
    end);

    if not DownloadSuccess or type(Data) ~= 'string' or #Data < 20 then
        return nil;
    end;

    EnsureFolder(Folder);
    local WriteSuccess = pcall(writefile, Path, Data);

    if not WriteSuccess then
        return nil;
    end;

    local ResolveSuccess, Asset = pcall(getcustomasset, Path);
    return ResolveSuccess and Asset or nil;
end;

function GameInfo:Get()
    local PlaceId = tonumber(game.PlaceId) or 0;
    local UniverseId = tonumber(game.GameId) or 0;
    local Product = {};
    local Online = {};

    pcall(function()
        Product = MarketplaceService:GetProductInfo(PlaceId) or {};
    end);

    if UniverseId > 0 then
        local Response = RequestJson('https://games.roblox.com/v1/games?universeIds=' .. tostring(UniverseId));
        Online = Response and Response.data and Response.data[1] or {};
    end;

    local Name = Online.name or Product.Name or game.Name or 'UNKNOWN GAME';
    local Playing = tonumber(Online.playing) or Players.NumPlayers or 0;
    local Updated = FormatUpdated(Online.updated or Product.Updated);
    local Icon = ResolveIcon(Product.IconImageAssetId or Product.iconImageAssetId, UniverseId);

    return {
        Name = tostring(Name);
        PlaceId = PlaceId;
        UniverseId = UniverseId;
        Playing = Playing;
        Updated = Updated;
        Icon = Icon;
    };
end;

return GameInfo;
