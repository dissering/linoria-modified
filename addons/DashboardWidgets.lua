-- Small animated dashboard widgets for Linoria Modified.
-- These are presentation widgets inspired by nhack's floating HUD panels;
-- Linoria groupboxes remain responsible for interactive controls.

local Players = game:GetService('Players');

local DashboardWidgets = {
    Library = nil;
    Items = {};
};

local function clampNumber(Value, Minimum, Maximum)
    return math.clamp(tonumber(Value) or Minimum, Minimum, Maximum);
end;

function DashboardWidgets:SetLibrary(Library)
    self.Library = Library;
    return self;
end;

function DashboardWidgets:RequireLibrary()
    assert(self.Library, 'DashboardWidgets:SetLibrary must be called first');
    return self.Library;
end;

function DashboardWidgets:CreatePanel(Info)
    local Library = self:RequireLibrary();
    Info = Info or {};

    local Panel = {
        Items = {};
        CursorY = 5;
        Visible = Info.Visible ~= false;
    };

    local Outer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = Info.Position or UDim2.fromOffset(80, 120);
        Size = Info.Size or UDim2.fromOffset(220, 160);
        Visible = Panel.Visible;
        ZIndex = Info.ZIndex or 20;
        Parent = Library.ScreenGui;
    });

    Library:AddToRegistry(Outer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    Library:AddCorner(Outer, Info.Radius or 6);

    local Scale = Library:Create('UIScale', {
        Scale = Panel.Visible and 1 or 0.92;
        Parent = Outer;
    });

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.fromOffset(1, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = Outer.ZIndex + 1;
        Parent = Outer;
    });

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    Library:AddCorner(Inner, math.max(0, (Info.Radius or 6) - 1));

    local Accent = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = Inner.ZIndex + 1;
        Parent = Inner;
    });

    Library:AddToRegistry(Accent, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    local Header = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.fromOffset(8, 4);
        Size = UDim2.new(1, -16, 0, 20);
        ZIndex = Inner.ZIndex + 1;
        Parent = Inner;
    });

    local Title = Library:CreateLabel({
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, 0);
        Text = Info.Title or 'WIDGET';
        TextColor3 = Library.AccentColor;
        TextSize = 11;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = Header.ZIndex + 1;
        Parent = Header;
    });

    Library:AddToRegistry(Title, {
        TextColor3 = 'AccentColor';
    }, true);

    local Body = Library:Create('Frame', {
        BackgroundTransparency = 1;
        ClipsDescendants = true;
        Position = UDim2.fromOffset(8, 28);
        Size = UDim2.new(1, -16, 1, -36);
        ZIndex = Inner.ZIndex + 1;
        Parent = Inner;
    });

    Library:MakeDraggable(Outer, 26);

    Panel.Instance = Outer;
    Panel.Inner = Inner;
    Panel.Body = Body;
    Panel.Title = Title;
    Panel.Scale = Scale;

    function Panel:SetTitle(Text)
        Title.Text = Text;
    end;

    function Panel:SetVisible(Visible)
        Panel.Visible = Visible;

        if Visible then
            Outer.Visible = true;
            Scale.Scale = 0.92;
            Library:Tween(Scale, { Scale = 1 }, 0.22);
        else
            local Tween = Library:Tween(Scale, { Scale = 0.92 }, 0.18);

            if Tween then
                Tween.Completed:Connect(function()
                    if not Panel.Visible then
                        Outer.Visible = false;
                    end;
                end);
            end;
        end;
    end;

    function Panel:AddText(Text, Color, Height)
        local Label = Library:CreateLabel({
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(2, Panel.CursorY);
            Size = UDim2.new(1, -4, 0, Height or 16);
            Text = Text or '';
            TextColor3 = Color or Library.FontColor;
            TextSize = 11;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Center;
            TextWrapped = true;
            ZIndex = Body.ZIndex + 1;
            Parent = Body;
        });

        Library:AddToRegistry(Label, {
            TextColor3 = Color and nil or 'FontColor';
        }, true);

        Panel.CursorY = Panel.CursorY + (Height or 16) + 2;
        table.insert(Panel.Items, Label);
        return Label;
    end;

    function Panel:AddDivider()
        local Divider = Library:Create('Frame', {
            BackgroundColor3 = Library.OutlineColor;
            BorderSizePixel = 0;
            Position = UDim2.fromOffset(2, Panel.CursorY + 2);
            Size = UDim2.new(1, -4, 0, 1);
            ZIndex = Body.ZIndex + 1;
            Parent = Body;
        });

        Library:AddToRegistry(Divider, {
            BackgroundColor3 = 'OutlineColor';
        }, true);

        Panel.CursorY = Panel.CursorY + 7;
        return Divider;
    end;

    function Panel:AddBar(LabelText, Value, Color)
        local BarLabel = Panel:AddText(LabelText, Library.FontColor, 14);
        local Bar = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            Position = UDim2.fromOffset(2, Panel.CursorY);
            Size = UDim2.new(1, -4, 0, 10);
            ZIndex = Body.ZIndex + 1;
            Parent = Body;
        });

        Library:AddToRegistry(Bar, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        }, true);

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Color or Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(clampNumber(Value, 0, 1), 0, 1, 0);
            ZIndex = Bar.ZIndex + 1;
            Parent = Bar;
        });

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = Color and nil or 'AccentColor';
        }, true);

        Panel.CursorY = Panel.CursorY + 14;

        local BarObject = {
            Label = BarLabel;
            Instance = Bar;
            Fill = Fill;
        };

        function BarObject:SetValue(NewValue)
            Library:Tween(Fill, {
                Size = UDim2.new(clampNumber(NewValue, 0, 1), 0, 1, 0);
            }, 0.2);
        end;

        return BarObject;
    end;

    function Panel:Destroy()
        if Outer.Parent then
            Outer:Destroy();
        end;
    end;

    table.insert(self.Items, Panel);
    return Panel;
end;

function DashboardWidgets:CreateRadar(Info)
    local Library = self:RequireLibrary();
    Info = Info or {};
    Info.Title = Info.Title or 'RADAR';
    Info.Size = Info.Size or UDim2.fromOffset(180, 190);

    local Panel = self:CreatePanel(Info);
    local Bounds = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.fromOffset(2, 4);
        Size = UDim2.new(1, -4, 1, -34);
        ClipsDescendants = true;
        ZIndex = Panel.Body.ZIndex + 1;
        Parent = Panel.Body;
    });

    Library:AddToRegistry(Bounds, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    Library:AddCorner(Bounds, 3);

    for _, Line in next, {
        { Size = UDim2.new(1, 0, 0, 1); Position = UDim2.new(0, 0, 0.5, 0) },
        { Size = UDim2.new(0, 1, 1, 0); Position = UDim2.new(0.5, 0, 0, 0) },
        { Size = UDim2.new(1, 0, 0, 1); Position = UDim2.new(0, 0, 0.25, 0) },
        { Size = UDim2.new(1, 0, 0, 1); Position = UDim2.new(0, 0, 0.75, 0) },
    } do
        local Grid = Library:Create('Frame', {
            BackgroundColor3 = Library.OutlineColor;
            BackgroundTransparency = 0.35;
            BorderSizePixel = 0;
            Size = Line.Size;
            Position = Line.Position;
            ZIndex = Bounds.ZIndex + 1;
            Parent = Bounds;
        });

        Library:AddToRegistry(Grid, {
            BackgroundColor3 = 'OutlineColor';
        }, true);
    end;

    local Dot = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.fromScale(0.5, 0.5);
        Size = UDim2.fromOffset(5, 5);
        ZIndex = Bounds.ZIndex + 2;
        Parent = Bounds;
    });

    Library:AddToRegistry(Dot, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    Library:AddCorner(Dot, 5);

    local Sweep = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 1);
        BackgroundColor3 = Library.AccentColor;
        BackgroundTransparency = 0.35;
        BorderSizePixel = 0;
        Position = UDim2.new(0.5, 0, 0.5, 0);
        Size = UDim2.new(0, 1, 0.5, 0);
        Rotation = 0;
        ZIndex = Bounds.ZIndex + 1;
        Parent = Bounds;
    });

    Library:AddToRegistry(Sweep, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    task.spawn(function()
        while Panel.Instance.Parent do
            Library:Tween(Sweep, { Rotation = 360 }, 1.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);
            task.wait(1.8);
            Sweep.Rotation = 0;
        end;
    end);

    function Panel:Upsert(Key, Data)
        self.Entries = self.Entries or {};
        local Entry = self.Entries[Key];

        if not Entry then
            Entry = Library:Create('Frame', {
                AnchorPoint = Vector2.new(0.5, 0.5);
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.fromOffset(4, 4);
                ZIndex = Bounds.ZIndex + 2;
                Parent = Bounds;
            });

            Library:AddToRegistry(Entry, {
                BackgroundColor3 = 'AccentColor';
            }, true);
            Library:AddCorner(Entry, 4);
            self.Entries[Key] = Entry;
        end;

        if Data and typeof(Data.Position) == 'Vector2' then
            Entry.Position = UDim2.fromOffset(Data.Position.X, Data.Position.Y);
        end;

        Entry.Visible = not Data or Data.Visible ~= false;
        return Entry;
    end;

    return Panel;
end;

function DashboardWidgets:CreateConsole(Info)
    local Library = self:RequireLibrary();
    local Panel = self:CreatePanel(Info or {});
    Panel:SetTitle((Info and Info.Title) or 'CONSOLE');
    Panel:AddText('SYSTEM READY', nil, 15);
    Panel:AddText('waiting for output...', Library:GetDarkerColor(Library.FontColor), 15);

    function Panel:AddOutput(Text)
        local Label = self:AddText(Text, Library.FontColor, 15);
        Label.TextTruncate = Enum.TextTruncate.AtEnd;
        return Label;
    end;

    return Panel;
end;

function DashboardWidgets:CreatePlayerList(Info)
    local Library = self:RequireLibrary();
    local Panel = self:CreatePanel(Info or {});
    Panel:SetTitle((Info and Info.Title) or 'PLAYERS');

    local function Refresh()
        for _, Item in next, Panel.Items do
            if Item:IsA('TextLabel') then
                Item:Destroy();
            end;
        end;

        Panel.CursorY = 5;
        Panel.Items = {};

        for _, Player in next, Players:GetPlayers() do
            Panel:AddText(Player.DisplayName .. '  //  ' .. Player.Name, Library.FontColor, 15);
        end;
    end;

    Refresh();
    Panel.Refresh = Refresh;
    return Panel;
end;

function DashboardWidgets:CreateStats(Info)
    local Library = self:RequireLibrary();
    local Panel = self:CreatePanel(Info or {});
    Panel:SetTitle((Info and Info.Title) or 'STATS');
    Panel:AddText('FPS       60', Library.FontColor, 15);
    Panel:AddText('PING      24 ms', Library.FontColor, 15);
    Panel:AddText('TARGETS   0', Library.FontColor, 15);
    Panel:AddText('STATUS    ONLINE', Library.AccentColor, 15);
    return Panel;
end;

function DashboardWidgets:DestroyAll()
    for Index = #self.Items, 1, -1 do
        local Panel = table.remove(self.Items, Index);
        Panel:Destroy();
    end;
end;

return DashboardWidgets;
