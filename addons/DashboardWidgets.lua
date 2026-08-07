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

    local HeaderIcon;

    if Info.Icon then
        HeaderIcon = Library:Create('ImageLabel', {
            BackgroundTransparency = 1;
            Image = Library:ResolveAsset(Info.Icon) or '';
            ImageColor3 = Library.IconColor or Color3.new(1, 1, 1);
            Position = UDim2.fromOffset(0, 3);
            Size = UDim2.fromOffset(14, 14);
            ScaleType = Enum.ScaleType.Fit;
            ZIndex = Header.ZIndex + 1;
            Parent = Header;
        });

        Library:AddToRegistry(HeaderIcon, {
            ImageColor3 = 'IconColor';
        }, true);
    end;

    local Title = Library:CreateLabel({
        BackgroundTransparency = 1;
        Position = UDim2.fromOffset(HeaderIcon and 20 or 0, 0);
        Size = UDim2.new(1, HeaderIcon and -20 or 0, 1, 0);
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

    if Info.Draggable ~= false and not Info.AttachTo then
        Library:MakeDraggable(Outer, 26);
    end;

    Panel.Instance = Outer;
    Panel.Inner = Inner;
    Panel.Body = Body;
    Panel.Title = Title;
    Panel.Icon = HeaderIcon;
    Panel.Scale = Scale;

    local AttachedTo = Info.AttachTo;
    if type(AttachedTo) == 'table' then
        AttachedTo = AttachedTo.Instance or AttachedTo.Outer;
    end;

    if typeof(AttachedTo) == 'Instance' and AttachedTo:IsA('GuiObject') then
        local function UpdateAttachedPosition()
            if not Outer.Parent or not AttachedTo.Parent then
                return;
            end;

            local Gap = math.max(0, tonumber(Info.Gap) or 8);
            local Margin = math.max(4, tonumber(Info.Margin) or 8);
            local Viewport = Library.ScreenGui.AbsoluteSize;
            local PanelSize = Outer.AbsoluteSize;
            local TargetPosition = AttachedTo.AbsolutePosition;
            local TargetSize = AttachedTo.AbsoluteSize;
            local PanelWidth = PanelSize.X > 0 and PanelSize.X or Outer.Size.X.Offset;
            local PanelHeight = PanelSize.Y > 0 and PanelSize.Y or Outer.Size.Y.Offset;
            local PreferredRight = Info.Side ~= 'Left';
            local RightX = TargetPosition.X + TargetSize.X + Gap;
            local LeftX = TargetPosition.X - PanelWidth - Gap;
            local X = PreferredRight and RightX or LeftX;

            if PreferredRight and X + PanelWidth > Viewport.X - Margin then
                X = LeftX;
            elseif not PreferredRight and X < Margin then
                X = RightX;
            end;

            X = math.clamp(X, Margin, math.max(Margin, Viewport.X - PanelWidth - Margin));

            local Y = TargetPosition.Y + (tonumber(Info.VerticalOffset) or 0);
            Y = math.clamp(Y, Margin, math.max(Margin, Viewport.Y - PanelHeight - Margin));

            Outer.Position = UDim2.fromOffset(math.floor(X + 0.5), math.floor(Y + 0.5));
        end;

        Panel.UpdateAttachedPosition = UpdateAttachedPosition;
        Library:GiveSignal(AttachedTo:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateAttachedPosition));
        Library:GiveSignal(AttachedTo:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateAttachedPosition));
        Library:GiveSignal(Library.ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateAttachedPosition));
        task.defer(UpdateAttachedPosition);
    end;

    function Panel:SetTitle(Text)
        Title.Text = Text;
    end;

    function Panel:SetIcon(Icon)
        if not HeaderIcon then
            HeaderIcon = Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                ImageColor3 = Library.IconColor or Color3.new(1, 1, 1);
                Position = UDim2.fromOffset(0, 3);
                Size = UDim2.fromOffset(14, 14);
                ScaleType = Enum.ScaleType.Fit;
                ZIndex = Header.ZIndex + 1;
                Parent = Header;
            });

            Library:AddToRegistry(HeaderIcon, {
                ImageColor3 = 'IconColor';
            }, true);
            Title.Position = UDim2.fromOffset(20, 0);
            Title.Size = UDim2.new(1, -20, 1, 0);
            Panel.Icon = HeaderIcon;
        end;

        HeaderIcon.Image = Library:ResolveAsset(Icon) or '';
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
    Info = Info or {};
    Info.Title = Info.Title or 'PLAYERS';
    Info.Size = Info.Size or UDim2.fromOffset(300, 270);

    if Info.Draggable == nil then
        Info.Draggable = false;
    end;

    local Panel = self:CreatePanel(Info);
    local Priorities = Info.Priorities or { 'Friendly', 'Neutral', 'Priority' };
    if #Priorities == 0 then
        Priorities = { 'Neutral' };
    end;
    local DefaultPriority = Info.DefaultPriority or Priorities[1] or 'Neutral';
    local PriorityByUserId = Info.PriorityByUserId or {};
    local Columns = Info.Columns or { 'Name', 'UserId', 'Priority' };
    local RowHeight = math.max(17, tonumber(Info.RowHeight) or 19);
    local Rows = {};
    local SelectedPlayer;
    local SearchText = '';

    local SearchOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Position = UDim2.fromOffset(2, 2);
        Size = UDim2.new(1, -4, 0, 20);
        ZIndex = Panel.Body.ZIndex + 1;
        Parent = Panel.Body;
    });

    Library:AddToRegistry(SearchOuter, {
        BackgroundColor3 = 'MainColor';
    }, true);
    Library:AddCorner(SearchOuter, 5);

    local SearchStroke = Library:Create('UIStroke', {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Color = Library.OutlineColor;
        Thickness = 1;
        Transparency = 0.18;
        Parent = SearchOuter;
    });

    Library:AddToRegistry(SearchStroke, {
        Color = 'OutlineColor';
    }, true);

    local SearchBox = Library:Create('TextBox', {
        BackgroundTransparency = 1;
        ClearTextOnFocus = false;
        Font = Library.Font;
        PlaceholderColor3 = Library:GetInactiveIconColor();
        PlaceholderText = Info.SearchPlaceholder or 'Search players';
        Position = UDim2.fromOffset(6, 0);
        Size = UDim2.new(1, -12, 1, 0);
        Text = '';
        TextColor3 = Library.FontColor;
        TextSize = 11;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = SearchOuter.ZIndex + 1;
        Parent = SearchOuter;
    });

    Library:ApplyTextStroke(SearchBox);
    Library:AddToRegistry(SearchBox, {
        PlaceholderColor3 = function()
            return Library:GetInactiveIconColor();
        end;
        TextColor3 = 'FontColor';
    }, true);

    local Header = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.fromOffset(2, 26);
        Size = UDim2.new(1, -4, 0, 16);
        ZIndex = Panel.Body.ZIndex + 1;
        Parent = Panel.Body;
    });

    local function CreateColumnLabel(Text, Position, Size, Parent, ZIndex)
        local Label = Library:CreateLabel({
            BackgroundTransparency = 1;
            Position = Position;
            Size = Size;
            Text = Text;
            TextColor3 = Library:GetInactiveIconColor();
            TextSize = 11;
            TextTruncate = Enum.TextTruncate.AtEnd;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = ZIndex;
            Parent = Parent;
        }, true);

        Library.RegistryMap[Label].Properties.TextColor3 = function()
            return Library:GetInactiveIconColor();
        end;
        return Label;
    end;

    CreateColumnLabel(Columns[1] or 'Name', UDim2.fromScale(0, 0), UDim2.new(0.46, -4, 1, 0), Header, Header.ZIndex + 1);
    CreateColumnLabel(Columns[2] or 'UserId', UDim2.fromScale(0.46, 0), UDim2.new(0.29, -4, 1, 0), Header, Header.ZIndex + 1);
    CreateColumnLabel(Columns[3] or 'Priority', UDim2.fromScale(0.75, 0), UDim2.new(0.25, 0, 1, 0), Header, Header.ZIndex + 1);

    local List = Library:Create('ScrollingFrame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel = 0;
        BottomImage = '';
        CanvasSize = UDim2.fromOffset(0, 0);
        Position = UDim2.fromOffset(2, 43);
        ScrollBarImageColor3 = Library.OutlineColor;
        ScrollBarThickness = 2;
        Size = UDim2.new(1, -4, 1, -89);
        TopImage = '';
        ZIndex = Panel.Body.ZIndex + 1;
        Parent = Panel.Body;
    });

    Library:AddToRegistry(List, {
        BackgroundColor3 = 'BackgroundColor';
        ScrollBarImageColor3 = 'OutlineColor';
    }, true);
    Library:AddCorner(List, 4);

    local ListStroke = Library:Create('UIStroke', {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Color = Library.OutlineColor;
        Thickness = 1;
        Transparency = 0.28;
        Parent = List;
    });

    Library:AddToRegistry(ListStroke, {
        Color = 'OutlineColor';
    }, true);

    local ListLayout = Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = List;
    });

    ListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
        List.CanvasSize = UDim2.fromOffset(0, ListLayout.AbsoluteContentSize.Y);
    end);

    local Footer = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 1);
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 2, 1, -2);
        Size = UDim2.new(1, -4, 0, 40);
        ZIndex = Panel.Body.ZIndex + 1;
        Parent = Panel.Body;
    });

    local SelectedLabel = Library:CreateLabel({
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 0, 15);
        Text = 'Selected: none';
        TextSize = 11;
        TextTruncate = Enum.TextTruncate.AtEnd;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Footer.ZIndex + 1;
        Parent = Footer;
    });

    local PriorityButton = Library:Create('Frame', {
        Active = true;
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Position = UDim2.fromOffset(0, 18);
        Size = UDim2.new(1, 0, 0, 20);
        ZIndex = Footer.ZIndex + 1;
        Parent = Footer;
    });

    Library:AddToRegistry(PriorityButton, {
        BackgroundColor3 = 'MainColor';
    }, true);
    Library:AddCorner(PriorityButton, 5);

    local PriorityStroke = Library:Create('UIStroke', {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Color = Library.OutlineColor;
        Thickness = 1;
        Transparency = 0.18;
        Parent = PriorityButton;
    });

    Library:AddToRegistry(PriorityStroke, {
        Color = 'OutlineColor';
    }, true);

    local PriorityLabel = Library:CreateLabel({
        BackgroundTransparency = 1;
        Position = UDim2.fromOffset(6, 0);
        Size = UDim2.new(1, -12, 1, 0);
        Text = 'Priority: --';
        TextSize = 11;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = PriorityButton.ZIndex + 1;
        Parent = PriorityButton;
    });

    local function GetPriority(Player)
        if not Player then
            return DefaultPriority;
        end;

        return PriorityByUserId[Player.UserId] or DefaultPriority;
    end;

    local function UpdateFooter()
        SelectedLabel.Text = SelectedPlayer
            and ('Selected: ' .. SelectedPlayer.DisplayName .. ' (@' .. SelectedPlayer.Name .. ')')
            or 'Selected: none';
        PriorityLabel.Text = SelectedPlayer and ('Priority: ' .. GetPriority(SelectedPlayer)) or 'Priority: --';
    end;

    local function UpdateRowSelection()
        for Player, Row in next, Rows do
            Row.Instance.BackgroundTransparency = Player == SelectedPlayer and 0.86 or 1;
        end;
    end;

    function Panel:Select(Player)
        if type(Player) == 'string' then
            Player = Players:FindFirstChild(Player);
        end;

        if Player ~= nil and (typeof(Player) ~= 'Instance' or not Player:IsA('Player')) then
            return;
        end;

        SelectedPlayer = Player;
        UpdateFooter();
        UpdateRowSelection();
        Library:SafeCallback(Info.Callback, SelectedPlayer);
    end;

    function Panel:GetSelectedPlayer()
        return SelectedPlayer;
    end;

    function Panel:GetPriority(Player)
        return GetPriority(Player or SelectedPlayer);
    end;

    function Panel:SetPriority(Player, Priority)
        Player = Player or SelectedPlayer;
        if not Player or not table.find(Priorities, Priority) then
            return;
        end;

        PriorityByUserId[Player.UserId] = Priority;
        UpdateFooter();

        local Row = Rows[Player];
        if Row then
            Row.PriorityLabel.Text = Priority;
        end;

        Library:SafeCallback(Info.PriorityChanged, Player, Priority);
    end;

    local function Refresh()
        for _, Row in next, Rows do
            for _, Descendant in next, Row.Instance:GetDescendants() do
                Library:RemoveFromRegistry(Descendant);
            end;
            Library:RemoveFromRegistry(Row.Instance);
            Row.Instance:Destroy();
        end;
        table.clear(Rows);

        local PlayerItems = Players:GetPlayers();
        table.sort(PlayerItems, function(Left, Right)
            return Left.Name:lower() < Right.Name:lower();
        end);

        for _, Player in next, PlayerItems do
            local Searchable = (Player.Name .. ' ' .. Player.DisplayName .. ' ' .. tostring(Player.UserId)):lower();
            if SearchText == '' or string.find(Searchable, SearchText, 1, true) then
                local Row = Library:Create('TextButton', {
                    AutoButtonColor = false;
                    BackgroundColor3 = Library.AccentColor;
                    BackgroundTransparency = Player == SelectedPlayer and 0.86 or 1;
                    BorderSizePixel = 0;
                    LayoutOrder = Player == Players.LocalPlayer and -1 or 0;
                    Size = UDim2.new(1, -2, 0, RowHeight);
                    Text = '';
                    ZIndex = List.ZIndex + 1;
                    Parent = List;
                });

                Library:AddToRegistry(Row, {
                    BackgroundColor3 = 'AccentColor';
                }, true);

                local NameText = Player.DisplayName == Player.Name
                    and Player.Name
                    or (Player.DisplayName .. ' (@' .. Player.Name .. ')');
                local NameLabel = CreateColumnLabel(NameText, UDim2.fromOffset(5, 0), UDim2.new(0.46, -9, 1, 0), Row, Row.ZIndex + 1);
                NameLabel.TextColor3 = Library.FontColor;
                Library.RegistryMap[NameLabel].Properties.TextColor3 = 'FontColor';

                local UserIdLabel = CreateColumnLabel(tostring(Player.UserId), UDim2.fromScale(0.46, 0), UDim2.new(0.29, -4, 1, 0), Row, Row.ZIndex + 1);
                UserIdLabel.TextColor3 = Library.FontColor;
                Library.RegistryMap[UserIdLabel].Properties.TextColor3 = 'FontColor';

                local PriorityValue = CreateColumnLabel(GetPriority(Player), UDim2.fromScale(0.75, 0), UDim2.new(0.25, -3, 1, 0), Row, Row.ZIndex + 1);
                PriorityValue.TextColor3 = Library.FontColor;
                Library.RegistryMap[PriorityValue].Properties.TextColor3 = 'FontColor';

                Rows[Player] = {
                    Instance = Row;
                    PriorityLabel = PriorityValue;
                };

                Row.InputBegan:Connect(function(Input)
                    if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
                        Panel:Select(Player);
                    end;
                end);
            end;
        end;

        List.CanvasSize = UDim2.fromOffset(0, ListLayout.AbsoluteContentSize.Y);

        if SelectedPlayer and not SelectedPlayer.Parent then
            Panel:Select(nil);
        elseif not SelectedPlayer and #PlayerItems > 0 then
            Panel:Select(PlayerItems[1]);
        else
            UpdateRowSelection();
            UpdateFooter();
        end;
    end;

    function Panel:SetSearch(Text)
        SearchBox.Text = tostring(Text or '');
    end;

    SearchBox:GetPropertyChangedSignal('Text'):Connect(function()
        SearchText = SearchBox.Text:lower();
        Refresh();
    end);

    PriorityButton.InputBegan:Connect(function(Input)
        if not SelectedPlayer or not Library:IsPointerInput(Input) or Library:MouseIsOverOpenedFrame(Input) then
            return;
        end;

        local Current = GetPriority(SelectedPlayer);
        local CurrentIndex = table.find(Priorities, Current) or 0;
        local NextPriority = Priorities[(CurrentIndex % #Priorities) + 1];
        Panel:SetPriority(SelectedPlayer, NextPriority);
    end);

    Library:GiveSignal(Players.PlayerAdded:Connect(Refresh));
    Library:GiveSignal(Players.PlayerRemoving:Connect(function(Player)
        if SelectedPlayer == Player then
            SelectedPlayer = nil;
        end;
        task.defer(Refresh);
    end));

    Panel.Refresh = Refresh;
    Panel.PriorityByUserId = PriorityByUserId;
    Panel.SearchBox = SearchBox;
    Panel.List = List;
    Refresh();
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
