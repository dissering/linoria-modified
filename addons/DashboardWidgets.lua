-- Small animated dashboard widgets for Linoria Modified.
-- These are presentation widgets inspired by nhack's floating HUD panels;
-- Linoria groupboxes remain responsible for interactive controls.

local Players = game:GetService('Players');
local Workspace = game:GetService('Workspace');

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
        BackgroundColor3 = Info.MatchWindowStyle and Color3.new(1, 1, 1) or Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.fromOffset(1, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = Outer.ZIndex + 1;
        Parent = Outer;
    });

    local InnerRegistry = {
        BorderColor3 = 'OutlineColor';
    };

    if Info.MatchWindowStyle then
        InnerRegistry.BackgroundColor3 = function()
            return Color3.new(1, 1, 1);
        end;
    else
        InnerRegistry.BackgroundColor3 = 'BackgroundColor';
    end;

    Library:AddToRegistry(Inner, InnerRegistry, true);
    Library:AddCorner(Inner, math.max(0, (Info.Radius or 6) - 1));

    if Info.MatchWindowStyle then
        Library:AddSurfaceGradient(Inner, -90);
    end;

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
        TextColor3 = Info.MatchWindowStyle and Library.FontColor or Library.AccentColor;
        TextSize = 11;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = Header.ZIndex + 1;
        Parent = Header;
    });

    Library:AddToRegistry(Title, {
        TextColor3 = Info.MatchWindowStyle and 'FontColor' or 'AccentColor';
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
            local TargetPosition = AttachedTo.AbsolutePosition;
            local TargetSize = AttachedTo.AbsoluteSize;
            local PanelSize = Outer.AbsoluteSize;
            local PanelWidth = PanelSize.X > 0 and PanelSize.X or Outer.Size.X.Offset;
            local PanelHeight;

            if Info.MatchHeight then
                PanelHeight = math.max(
                    tonumber(Info.MinimumHeight) or 160,
                    TargetSize.Y + (tonumber(Info.HeightOffset) or 0)
                );
                PanelHeight = math.floor(PanelHeight + 0.5);

                if Outer.Size.Y.Scale ~= 0 or Outer.Size.Y.Offset ~= PanelHeight then
                    Outer.Size = UDim2.new(Outer.Size.X.Scale, Outer.Size.X.Offset, 0, PanelHeight);
                end;
            else
                PanelHeight = PanelSize.Y > 0 and PanelSize.Y or Outer.Size.Y.Offset;
            end;
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

    function Panel:CreateActionButton(ButtonInfo)
        ButtonInfo = ButtonInfo or {};

        local Button = Library:Create('TextButton', {
            Active = true;
            AutoButtonColor = false;
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Font = Library.Font;
            Position = ButtonInfo.Position or UDim2.fromOffset(0, 0);
            Size = ButtonInfo.Size or UDim2.fromOffset(100, 20);
            Text = tostring(ButtonInfo.Text or 'Action');
            TextColor3 = Library.FontColor;
            TextSize = ButtonInfo.TextSize or 11;
            ZIndex = ButtonInfo.ZIndex or (Body.ZIndex + 1);
            Parent = ButtonInfo.Parent or Body;
        });

        Library:ApplyTextStroke(Button);
        Library:AddToRegistry(Button, {
            BackgroundColor3 = 'MainColor';
            TextColor3 = 'FontColor';
        }, true);
        Library:AddCorner(Button, ButtonInfo.Radius or 5);

        local Stroke = Library:Create('UIStroke', {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Color = Library.OutlineColor;
            Thickness = 1;
            Transparency = 0.18;
            Parent = Button;
        });

        Library:AddToRegistry(Stroke, {
            Color = 'OutlineColor';
        }, true);

        local ButtonScale = Library:Create('UIScale', {
            Scale = 1;
            Parent = Button;
        });

        local ButtonObject = {
            Enabled = ButtonInfo.Enabled ~= false;
            Instance = Button;
            Scale = ButtonScale;
            Stroke = Stroke;
        };

        function ButtonObject:SetText(Text)
            Button.Text = tostring(Text or '');
        end;

        function ButtonObject:SetEnabled(Enabled)
            self.Enabled = Enabled == true;
            Button.TextTransparency = self.Enabled and 0 or 0.5;
        end;

        ButtonObject:SetEnabled(ButtonObject.Enabled);

        Button.InputBegan:Connect(function(Input)
            if not ButtonObject.Enabled
                or not Library:IsPointerInput(Input)
                or Library:MouseIsOverOpenedFrame(Input)
            then
                return;
            end;

            Library:Tween(ButtonScale, { Scale = 0.97 }, 0.08, Enum.EasingStyle.Quad);
            Library:SafeCallback(ButtonInfo.Callback);
        end);

        Button.InputEnded:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                Library:Tween(ButtonScale, { Scale = 1 }, 0.12, Enum.EasingStyle.Quart);
            end;
        end);

        return ButtonObject;
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

    if Info.MatchWindowStyle == nil then
        Info.MatchWindowStyle = true;
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
    local ShowHeadshots = Info.ShowHeadshots ~= false;
    local HeadshotSize = math.max(10, math.min(RowHeight - 4, tonumber(Info.HeadshotSize) or 18));
    local Rows = {};
    local SelectedPlayer;
    local SpectatingPlayer;
    local SpectateCharacterConnection;
    local SearchText = '';
    local Refresh;
    local RefreshQueued = false;
    local Destroyed = false;
    local ActionButtons = {};
    local ActionDefinitions;

    if Info.Actions == nil then
        ActionDefinitions = { 'Teleport', 'Spectate', 'StopSpectating', 'Refresh' };
    elseif Info.Actions == false then
        ActionDefinitions = {};
    else
        ActionDefinitions = Info.Actions;
    end;

    local ActionRows = math.ceil(#ActionDefinitions / 2);
    local FooterHeight = ActionRows > 0 and (42 + (ActionRows * 20) + ((ActionRows - 1) * 4)) or 40;

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
        Size = UDim2.new(1, -4, 1, -(FooterHeight + 49));
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
        Size = UDim2.new(1, -4, 0, FooterHeight);
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

    local PriorityDropdown = Library:Create('Frame', {
        Active = true;
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Position = UDim2.fromOffset(0, 18);
        Size = UDim2.new(1, 0, 0, 20);
        ZIndex = Footer.ZIndex + 1;
        Parent = Footer;
    });

    Library:AddToRegistry(PriorityDropdown, {
        BackgroundColor3 = 'MainColor';
    }, true);
    Library:AddCorner(PriorityDropdown, 5);

    local PriorityStroke = Library:Create('UIStroke', {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Color = Library.OutlineColor;
        Thickness = 1;
        Transparency = 0.18;
        Parent = PriorityDropdown;
    });

    Library:AddToRegistry(PriorityStroke, {
        Color = 'OutlineColor';
    }, true);

    local PriorityLabel = Library:CreateLabel({
        BackgroundTransparency = 1;
        Position = UDim2.fromOffset(6, 0);
        Size = UDim2.new(1, -28, 1, 0);
        Text = 'Priority: --';
        TextSize = 11;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = PriorityDropdown.ZIndex + 1;
        Parent = PriorityDropdown;
    });

    local PriorityArrow = Library:Create('ImageLabel', {
        AnchorPoint = Vector2.new(0.5, 0.5);
        BackgroundTransparency = 1;
        Image = Library:ResolveAsset('chevron-down') or 'http://www.roblox.com/asset/?id=6282522798';
        ImageColor3 = Library:GetInactiveIconColor();
        Position = UDim2.new(1, -11, 0.5, 0);
        Size = UDim2.fromOffset(11, 11);
        ZIndex = PriorityDropdown.ZIndex + 1;
        Parent = PriorityDropdown;
    });

    Library:AddToRegistry(PriorityArrow, {
        ImageColor3 = function()
            return Library:GetInactiveIconColor();
        end;
    }, true);

    local ActionContainer;

    if ActionRows > 0 then
        ActionContainer = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(0, 42);
            Size = UDim2.new(1, 0, 0, FooterHeight - 42);
            ZIndex = Footer.ZIndex + 1;
            Parent = Footer;
        });

        Library:Create('UIGridLayout', {
            CellPadding = UDim2.fromOffset(4, 4);
            CellSize = UDim2.new(0.5, -2, 0, 20);
            FillDirection = Enum.FillDirection.Horizontal;
            FillDirectionMaxCells = 2;
            HorizontalAlignment = Enum.HorizontalAlignment.Left;
            SortOrder = Enum.SortOrder.LayoutOrder;
            VerticalAlignment = Enum.VerticalAlignment.Top;
            Parent = ActionContainer;
        });
    end;

    local PriorityList = Library:Create('CanvasGroup', {
        Active = true;
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        ClipsDescendants = true;
        GroupTransparency = 1;
        Position = UDim2.fromOffset(0, 0);
        Size = UDim2.fromOffset(0, 0);
        Visible = false;
        ZIndex = 240;
        Parent = Library.ScreenGui;
    });

    local PriorityBlocker = Library:Create('TextButton', {
        Active = true;
        AutoButtonColor = false;
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Modal = true;
        Size = UDim2.fromScale(1, 1);
        Text = '';
        Visible = false;
        ZIndex = PriorityList.ZIndex - 1;
        Parent = Library.ScreenGui;
    });

    Library:AddToRegistry(PriorityList, {
        BackgroundColor3 = 'MainColor';
    }, true);
    Library:AddCorner(PriorityList, 5);

    local PriorityListStroke = Library:Create('UIStroke', {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Color = Library.OutlineColor;
        Thickness = 1;
        Transparency = 0.18;
        Parent = PriorityList;
    });

    Library:AddToRegistry(PriorityListStroke, {
        Color = 'OutlineColor';
    }, true);

    local PriorityListScale = Library:Create('UIScale', {
        Scale = 0.96;
        Parent = PriorityList;
    });

    Library:Create('UIPadding', {
        PaddingBottom = UDim.new(0, 2);
        PaddingLeft = UDim.new(0, 2);
        PaddingRight = UDim.new(0, 2);
        PaddingTop = UDim.new(0, 2);
        Parent = PriorityList;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = PriorityList;
    });

    local PriorityOptions = {};
    local PriorityListOpen = false;

    for Index, Priority in ipairs(Priorities) do
        local OptionButton = Library:Create('TextButton', {
            AutoButtonColor = false;
            BackgroundColor3 = Library.AccentColor;
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            LayoutOrder = Index;
            Size = UDim2.new(1, 0, 0, 20);
            Text = '';
            ZIndex = PriorityList.ZIndex + 1;
            Parent = PriorityList;
        });

        Library:AddToRegistry(OptionButton, {
            BackgroundColor3 = 'AccentColor';
        }, true);
        Library:AddCorner(OptionButton, 3);

        local OptionLabel = Library:CreateLabel({
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(6, 0);
            Size = UDim2.new(1, -12, 1, 0);
            Text = Priority;
            TextSize = 11;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = OptionButton.ZIndex + 1;
            Parent = OptionButton;
        }, true);

        PriorityOptions[Priority] = {
            Button = OptionButton;
            Label = OptionLabel;
        };
    end;

    local function GetPriority(Player)
        if not Player then
            return DefaultPriority;
        end;

        return PriorityByUserId[Player.UserId] or DefaultPriority;
    end;

    local function UpdatePriorityOptions()
        local CurrentPriority = SelectedPlayer and GetPriority(SelectedPlayer) or nil;

        for Priority, Option in next, PriorityOptions do
            Option.Button.BackgroundTransparency = Priority == CurrentPriority and 0.86 or 1;
        end;
    end;

    local function UpdateFooter()
        SelectedLabel.Text = SelectedPlayer
            and ('Selected: ' .. SelectedPlayer.DisplayName .. ' (@' .. SelectedPlayer.Name .. ')')
            or 'Selected: none';
        PriorityLabel.Text = SelectedPlayer and ('Priority: ' .. GetPriority(SelectedPlayer)) or 'Priority: --';

        for _, Action in next, ActionButtons do
            local Enabled = true;

            if Action.Id == 'StopSpectating' then
                Enabled = SpectatingPlayer ~= nil;
            elseif Action.RequiresSelection then
                Enabled = SelectedPlayer ~= nil;
            end;

            Action.Button:SetEnabled(Enabled);
        end;

        UpdatePriorityOptions();
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

    local function GetCharacterPart(Player, ClassName, PartName)
        local Character = Player and Player.Character;
        if not Character then
            return nil;
        end;

        if PartName then
            return Character:FindFirstChild(PartName);
        end;

        return Character:FindFirstChildOfClass(ClassName);
    end;

    local function DisconnectSpectateCharacter()
        if SpectateCharacterConnection then
            SpectateCharacterConnection:Disconnect();
            SpectateCharacterConnection = nil;
        end;
    end;

    function Panel:StopSpectating()
        SpectatingPlayer = nil;
        DisconnectSpectateCharacter();

        local Camera = Workspace.CurrentCamera;
        local Humanoid = GetCharacterPart(Players.LocalPlayer, 'Humanoid');

        if Camera and Humanoid then
            Camera.CameraSubject = Humanoid;
        end;

        UpdateFooter();
        Library:SafeCallback(Info.SpectateChanged, nil);
    end;

    function Panel:Spectate(Player)
        Player = Player or SelectedPlayer;
        if not Player then
            Library:Notify('Select a player to spectate', 2);
            return false;
        end;

        if Player == Players.LocalPlayer then
            self:StopSpectating();
            return true;
        end;

        DisconnectSpectateCharacter();
        SpectatingPlayer = Player;

        local function UpdateCameraSubject()
            if SpectatingPlayer ~= Player then
                return;
            end;

            local Camera = Workspace.CurrentCamera;
            local Humanoid = GetCharacterPart(Player, 'Humanoid');
            if Camera and Humanoid then
                Camera.CameraSubject = Humanoid;
            end;
        end;

        SpectateCharacterConnection = Player.CharacterAdded:Connect(function(Character)
            local Humanoid = Character:WaitForChild('Humanoid', 5);
            if SpectatingPlayer == Player and Humanoid and Workspace.CurrentCamera then
                Workspace.CurrentCamera.CameraSubject = Humanoid;
            end;
        end);

        UpdateCameraSubject();
        UpdateFooter();
        Library:SafeCallback(Info.SpectateChanged, Player);
        return true;
    end;

    function Panel:TeleportTo(Player)
        Player = Player or SelectedPlayer;
        if not Player or Player == Players.LocalPlayer then
            Library:Notify('Select another player to teleport to', 2);
            return false;
        end;

        local LocalRoot = GetCharacterPart(Players.LocalPlayer, nil, 'HumanoidRootPart');
        local TargetRoot = GetCharacterPart(Player, nil, 'HumanoidRootPart');

        if not LocalRoot or not TargetRoot then
            Library:Notify('Player character is not ready', 2);
            return false;
        end;

        LocalRoot.CFrame = TargetRoot.CFrame * CFrame.new(0, 0, 3);
        Library:SafeCallback(Info.Teleported, Player);
        return true;
    end;

    local function PositionPriorityList()
        local FieldPosition = PriorityDropdown.AbsolutePosition;
        local FieldSize = PriorityDropdown.AbsoluteSize;
        local Viewport = Library.ScreenGui.AbsoluteSize;
        local ListHeight = (#Priorities * 20) + 4;
        local X = math.clamp(FieldPosition.X, 4, math.max(4, Viewport.X - FieldSize.X - 4));
        local Y = FieldPosition.Y - ListHeight - 4;

        if Y < 4 then
            Y = FieldPosition.Y + FieldSize.Y + 4;
        end;

        Y = math.clamp(Y, 4, math.max(4, Viewport.Y - ListHeight - 4));
        PriorityList.Position = UDim2.fromOffset(math.floor(X + 0.5), math.floor(Y + 0.5));
        PriorityList.Size = UDim2.fromOffset(math.floor(FieldSize.X + 0.5), ListHeight);
    end;

    local function ClosePriorityList()
        if not PriorityListOpen then
            return;
        end;

        PriorityListOpen = false;
        Library:CloseFrame(PriorityList);
        PriorityBlocker.Visible = false;
        Library:Tween(PriorityArrow, { Rotation = 0 }, 0.14, Enum.EasingStyle.Quad);
        Library:Tween(PriorityListScale, { Scale = 0.96 }, 0.12, Enum.EasingStyle.Quad);
        local Tween = Library:Tween(PriorityList, { GroupTransparency = 1 }, 0.12, Enum.EasingStyle.Quad);

        if Tween then
            Tween.Completed:Connect(function()
                if not PriorityListOpen then
                    PriorityList.Visible = false;
                end;
            end);
        else
            PriorityList.Visible = false;
        end;
    end;

    local function OpenPriorityList()
        if PriorityListOpen or not SelectedPlayer then
            return;
        end;

        PositionPriorityList();
        UpdatePriorityOptions();
        PriorityListOpen = true;
        PriorityBlocker.Visible = true;
        PriorityList.Visible = true;
        PriorityList.GroupTransparency = 1;
        PriorityListScale.Scale = 0.96;
        Library:OpenFrame(PriorityList);
        Library:Tween(PriorityArrow, { Rotation = 180 }, 0.16, Enum.EasingStyle.Quart);
        Library:Tween(PriorityListScale, { Scale = 1 }, 0.16, Enum.EasingStyle.Quart);
        Library:Tween(PriorityList, { GroupTransparency = 0 }, 0.14, Enum.EasingStyle.Quad);
    end;

    for Priority, Option in next, PriorityOptions do
        local PriorityValue = Priority;
        Option.Button.InputBegan:Connect(function(Input)
            if Library:IsPointerInput(Input) then
                Panel:SetPriority(SelectedPlayer, PriorityValue);
                ClosePriorityList();
            end;
        end);
    end;

    Refresh = function()
        if Destroyed then
            return;
        end;

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
                local RowPlayer = Player;
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

                local NameOffset = 5;
                if ShowHeadshots then
                    local Headshot = Library:Create('ImageLabel', {
                        BackgroundColor3 = Library.MainColor;
                        BorderSizePixel = 0;
                        Image = '';
                        Position = UDim2.fromOffset(3, math.floor((RowHeight - HeadshotSize) * 0.5));
                        ScaleType = Enum.ScaleType.Crop;
                        Size = UDim2.fromOffset(HeadshotSize, HeadshotSize);
                        ZIndex = Row.ZIndex + 1;
                        Parent = Row;
                    });

                    Library:AddToRegistry(Headshot, {
                        BackgroundColor3 = 'MainColor';
                    }, true);
                    Library:AddCorner(Headshot, math.floor(HeadshotSize * 0.5), true);
                    NameOffset = HeadshotSize + 7;

                    task.spawn(function()
                        local Success, Image = pcall(
                            Players.GetUserThumbnailAsync,
                            Players,
                            RowPlayer.UserId,
                            Enum.ThumbnailType.HeadShot,
                            Enum.ThumbnailSize.Size48x48
                        );

                        local CurrentRow = Rows[RowPlayer];
                        if Success and type(Image) == 'string' and CurrentRow and CurrentRow.Instance == Row and Headshot.Parent then
                            Headshot.Image = Image;
                        end;
                    end);
                end;

                local NameText = Player.DisplayName == Player.Name
                    and Player.Name
                    or (Player.DisplayName .. ' (@' .. Player.Name .. ')');
                local NameLabel = CreateColumnLabel(NameText, UDim2.fromOffset(NameOffset, 0), UDim2.new(0.46, -NameOffset - 4, 1, 0), Row, Row.ZIndex + 1);
                NameLabel.TextColor3 = Library.FontColor;
                Library.RegistryMap[NameLabel].Properties.TextColor3 = 'FontColor';

                local UserIdLabel = CreateColumnLabel(tostring(Player.UserId), UDim2.fromScale(0.46, 0), UDim2.new(0.29, -4, 1, 0), Row, Row.ZIndex + 1);
                UserIdLabel.TextColor3 = Library.FontColor;
                Library.RegistryMap[UserIdLabel].Properties.TextColor3 = 'FontColor';

                local PriorityValue = CreateColumnLabel(GetPriority(Player), UDim2.fromScale(0.75, 0), UDim2.new(0.25, -3, 1, 0), Row, Row.ZIndex + 1);
                PriorityValue.TextColor3 = Library.FontColor;
                Library.RegistryMap[PriorityValue].Properties.TextColor3 = 'FontColor';

                Rows[RowPlayer] = {
                    Instance = Row;
                    PriorityLabel = PriorityValue;
                };

                Row.InputBegan:Connect(function(Input)
                    if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
                        Panel:Select(RowPlayer);
                    end;
                end);
            end;
        end;

        List.CanvasSize = UDim2.fromOffset(0, ListLayout.AbsoluteContentSize.Y);

        if SelectedPlayer and not table.find(PlayerItems, SelectedPlayer) then
            Panel:Select(nil);
        elseif not SelectedPlayer and #PlayerItems > 0 then
            Panel:Select(PlayerItems[1]);
        else
            UpdateRowSelection();
            UpdateFooter();
        end;
    end;

    local function QueueRefresh()
        if RefreshQueued or Destroyed then
            return;
        end;

        RefreshQueued = true;
        task.defer(function()
            RefreshQueued = false;

            if not Destroyed and Panel.Instance.Parent then
                Refresh();
            end;
        end);
    end;

    local ActionText = {
        Teleport = 'Teleport';
        Spectate = 'Spectate';
        StopSpectating = 'Stop spectating';
        Refresh = 'Refresh';
    };

    for Index, ActionInfo in ipairs(ActionDefinitions) do
        local Definition = type(ActionInfo) == 'table' and ActionInfo or { Id = ActionInfo };
        local ActionId = tostring(Definition.Id or Definition.Name or ('Action' .. Index));
        local CustomCallback = Definition.Callback;
        local RequiresSelection = Definition.RequiresSelection;

        if RequiresSelection == nil then
            RequiresSelection = ActionId == 'Teleport' or ActionId == 'Spectate';
        end;

        local function RunAction()
            if type(CustomCallback) == 'function' then
                Library:SafeCallback(CustomCallback, SelectedPlayer, Panel);
            elseif ActionId == 'Teleport' then
                Panel:TeleportTo();
            elseif ActionId == 'Spectate' then
                Panel:Spectate();
            elseif ActionId == 'StopSpectating' then
                Panel:StopSpectating();
            elseif ActionId == 'Refresh' then
                Refresh();
            end;
        end;

        local Button = Panel:CreateActionButton({
            Callback = RunAction;
            Parent = ActionContainer;
            Size = UDim2.new(0.5, -2, 0, 20);
            Text = Definition.Text or ActionText[ActionId] or ActionId;
            ZIndex = Footer.ZIndex + 2;
        });

        table.insert(ActionButtons, {
            Button = Button;
            Id = ActionId;
            RequiresSelection = RequiresSelection;
        });
    end;

    function Panel:SetSearch(Text)
        SearchBox.Text = tostring(Text or '');
    end;

    SearchBox:GetPropertyChangedSignal('Text'):Connect(function()
        SearchText = SearchBox.Text:lower();
        Refresh();
    end);

    PriorityDropdown.InputBegan:Connect(function(Input)
        if not SelectedPlayer or not Library:IsPointerInput(Input) then
            return;
        end;

        if PriorityListOpen then
            ClosePriorityList();
        else
            OpenPriorityList();
        end;
    end);

    PriorityBlocker.InputBegan:Connect(function(Input)
        if PriorityListOpen and Library:IsPointerInput(Input) then
            ClosePriorityList();
        end;
    end);

    Library:GiveSignal(PriorityDropdown:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
        if PriorityListOpen then
            PositionPriorityList();
        end;
    end));

    Library:GiveSignal(PriorityDropdown:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        if PriorityListOpen then
            PositionPriorityList();
        end;
    end));

    Library:GiveSignal(Players.PlayerAdded:Connect(QueueRefresh));
    Library:GiveSignal(Players.PlayerRemoving:Connect(function(Player)
        if SelectedPlayer == Player then
            SelectedPlayer = nil;
        end;

        if SpectatingPlayer == Player then
            Panel:StopSpectating();
        end;

        QueueRefresh();
        task.delay(0.05, QueueRefresh);
    end));

    Panel.Refresh = Refresh;
    Panel.PriorityByUserId = PriorityByUserId;
    Panel.SearchBox = SearchBox;
    Panel.List = List;
    Panel.ActionButtons = ActionButtons;

    local BaseSetVisible = Panel.SetVisible;
    function Panel:SetVisible(Visible)
        if not Visible then
            ClosePriorityList();
        end;
        BaseSetVisible(self, Visible);
    end;

    local BaseDestroy = Panel.Destroy;
    function Panel:Destroy()
        Destroyed = true;
        Panel:StopSpectating();
        ClosePriorityList();
        for _, Descendant in next, PriorityList:GetDescendants() do
            Library:RemoveFromRegistry(Descendant);
        end;
        Library:RemoveFromRegistry(PriorityList);
        PriorityBlocker:Destroy();
        PriorityList:Destroy();
        BaseDestroy(self);
    end;

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
