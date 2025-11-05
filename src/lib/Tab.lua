--[[
    Tab Navigation System
    Dynamic tab creation with icon support and state management

    @author Advanced UI Library Team
    @version 1.0.0
--]]

local Tab = {}
Tab.__index = Tab

-- Dependencies
local Section = require(script.Parent.Section)
local AnimationEngine = require(script.Parent.AnimationEngine)

-- Tab state
local TabState = {
    Active = "Active",
    Inactive = "Inactive",
    Hovered = "Hovered"
}

--[[
    Create a new tab instance
]]
function Tab.new(config, theme, contentFrame, tabScrolling, layoutOrder)
    local self = setmetatable({}, Tab)

    -- Configuration
    self.Name = config.Name or "Tab"
    self.Icon = config.Icon
    self.Theme = theme
    self.ContentFrame = contentFrame
    self.TabScrolling = tabScrolling
    self.LayoutOrder = layoutOrder or 1

    -- Collaboration settings
    self.Collaboration = config.Collaboration or {}

    -- State
    self.State = TabState.Inactive
    self.IsVisible = false
    self.Sections = {}
    self.Components = {}

    -- GUI elements
    self.TabButton = nil
    self.ContentContainer = nil
    self.IconLabel = nil
    self.NameLabel = nil
    self.BadgeLabel = nil

    -- Events
    self.Connections = {}

    -- Unique ID for tracking
    self.Id = "Tab_" .. tick() .. "_" .. math.random(1000, 9999)

    self:_createGui()
    self:_setupEventHandlers()

    return self
end

--[[
    Create GUI elements for the tab
]]
function Tab:_createGui()
    -- Create tab button
    self.TabButton = Instance.new("TextButton")
    self.TabButton.Name = self.Name .. "Tab"
    self.TabButton.Size = UDim2.new(0, 120, 1, 0)
    self.TabButton.BackgroundTransparency = 1
    self.TabButton.BorderSizePixel = 0
    self.TabButton.LayoutOrder = self.LayoutOrder
    self.TabButton.Parent = self.TabScrolling

    -- Create tab background
    local tabBackground = Instance.new("Frame")
    tabBackground.Name = "Background"
    tabBackground.Size = UDim2.new(1, 0, 1, 0)
    tabBackground.Position = UDim2.new(0, 0, 0, 0)
    tabBackground.BackgroundColor3 = self.Theme.Colors.Surface
    tabBackground.BackgroundTransparency = 0.5
    tabBackground.BorderSizePixel = 0
    tabBackground.Parent = self.TabButton

    local backgroundCorner = Instance.new("UICorner")
    backgroundCorner.CornerRadius = UDim.new(0, self.Theme.BorderRadius.Medium)
    backgroundCorner.Parent = tabBackground

    -- Create content layout
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Horizontal
    contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = self.TabButton

    -- Create icon if provided
    if self.Icon then
        self.IconLabel = Instance.new("ImageLabel")
        self.IconLabel.Name = "Icon"
        self.IconLabel.Size = UDim2.new(0, 20, 0, 20)
        self.IconLabel.BackgroundTransparency = 1
        self.IconLabel.Image = self.Icon
        self.IconLabel.ImageColor3 = self.Theme.Colors.TextSecondary
        self.IconLabel.Parent = self.TabButton

        -- Add aspect ratio constraint
        local aspectRatio = Instance.new("UIAspectRatioConstraint")
        aspectRatio.AspectRatio = 1
        aspectRatio.Parent = self.IconLabel
    end

    -- Create name label
    self.NameLabel = Instance.new("TextLabel")
    self.NameLabel.Name = "Name"
    self.NameLabel.Size = UDim2.new(0, 0, 0, 20)
    self.NameLabel.AutomaticSize = Enum.AutomaticSize.X
    self.NameLabel.BackgroundTransparency = 1
    self.NameLabel.Font = self.Theme.Typography.Font
    self.NameLabel.Text = self.Name
    self.NameLabel.TextColor3 = self.Theme.Colors.TextSecondary
    self.NameLabel.TextSize = self.Theme.Typography.TextSize
    self.NameLabel.Parent = self.TabButton

    -- Create badge (initially hidden)
    self.BadgeLabel = Instance.new("TextLabel")
    self.BadgeLabel.Name = "Badge"
    self.BadgeLabel.Size = UDim2.new(0, 20, 0, 20)
    self.BadgeLabel.Position = UDim2.new(1, -10, 0, 0)
    self.BadgeLabel.BackgroundColor3 = self.Theme.Colors.Error
    self.BadgeLabel.BorderSizePixel = 0
    self.BadgeLabel.Font = Enum.Font.GothamMedium
    self.BadgeLabel.Text = ""
    self.BadgeLabel.TextColor3 = Color3.new(1, 1, 1)
    self.BadgeLabel.TextSize = 10
    self.BadgeLabel.Visible = false
    self.BadgeLabel.Parent = self.TabButton

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 10)
    badgeCorner.Parent = self.BadgeLabel

    -- Create content container
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Name = self.Name .. "Content"
    self.ContentContainer.Size = UDim2.new(1, 0, 1, 0)
    self.ContentContainer.Position = UDim2.new(0, 0, 0, 0)
    self.ContentContainer.BackgroundTransparency = 1
    self.ContentContainer.Visible = false
    self.ContentContainer.Parent = self.ContentFrame

    -- Create content layout
    local containerLayout = Instance.new("UIListLayout")
    containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    containerLayout.Padding = UDim.new(0, self.Theme.Spacing.M)
    containerLayout.Parent = self.ContentContainer

    -- Update scrolling canvas size
    self:_updateCanvasSize()
end

--[[
    Setup event handlers for tab interactions
]]
function Tab:_setupEventHandlers()
    -- Tab button click
    local connection = self.TabButton.MouseButton1Click:Connect(function()
        self:Activate()
    end)
    table.insert(self.Connections, connection)

    -- Tab button hover
    connection = self.TabButton.MouseEnter:Connect(function()
        if self.State ~= TabState.Active then
            self:_setHovered(true)
        end
    end)
    table.insert(self.Connections, connection)

    connection = self.TabButton.MouseLeave:Connect(function()
        if self.State ~= TabState.Active then
            self:_setHovered(false)
        end
    end)
    table.insert(self.Connections, connection)

    -- Content size change
    connection = self.ContentContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:_updateCanvasSize()
    end)
    table.insert(self.Connections, connection)
end

--[[
    Set hover state
]]
function Tab:_setHovered(isHovered)
    local background = self.TabButton.Background
    local nameLabel = self.NameLabel
    local iconLabel = self.IconLabel

    if isHovered then
        self.State = TabState.Hovered
        background.BackgroundTransparency = 0.3
        background.BackgroundColor3 = self.Theme.Colors.Primary
        nameLabel.TextColor3 = self.Theme.Colors.Text
        if iconLabel then
            iconLabel.ImageColor3 = self.Theme.Colors.Text
        end

        -- Add hover animation
        AnimationEngine:Hover(background, self.Theme.Colors.Primary, 0.2)
    else
        self.State = TabState.Inactive
        background.BackgroundTransparency = 0.5
        background.BackgroundColor3 = self.Theme.Colors.Surface
        nameLabel.TextColor3 = self.Theme.Colors.TextSecondary
        if iconLabel then
            iconLabel.ImageColor3 = self.Theme.Colors.TextSecondary
        end

        -- Add unhover animation
        AnimationEngine:Unhover(background, self.Theme.Colors.Surface, 0.2)
    end
end

--[[
    Activate the tab
]]
function Tab:Activate()
    if self.State == TabState.Active then return end

    -- Deactivate other tabs (would be handled by Window)
    self.State = TabState.Active
    self.IsVisible = true

    -- Update tab button appearance
    local background = self.TabButton.Background
    background.BackgroundTransparency = 0
    background.BackgroundColor3 = self.Theme.Colors.Primary

    self.NameLabel.TextColor3 = self.Theme.Colors.Text
    if self.IconLabel then
        self.IconLabel.ImageColor3 = self.Theme.Colors.Text
    end

    -- Show content
    self.ContentContainer.Visible = true

    -- Animate content appearance
    self.ContentContainer.Size = UDim2.new(1, 0, 0, 0)
    self.ContentContainer:TweenSize(
        UDim2.new(1, 0, 1, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true
    )

    -- Sync activation with collaborators
    if self.Collaboration.Enabled and self.Collaboration.SyncState then
        self:_syncActivation()
    end

    -- Clear badge when activated
    self:ClearBadge()
end

--[[
    Deactivate the tab
]]
function Tab:SetActive(isActive)
    if isActive then
        self:Activate()
    else
        self:Deactivate()
    end
end

--[[
    Deactivate the tab
]]
function Tab:Deactivate()
    if self.State ~= TabState.Active then return end

    self.State = TabState.Inactive
    self.IsVisible = false

    -- Update tab button appearance
    local background = self.TabButton.Background
    background.BackgroundTransparency = 0.5
    background.BackgroundColor3 = self.Theme.Colors.Surface

    self.NameLabel.TextColor3 = self.Theme.Colors.TextSecondary
    if self.IconLabel then
        self.IconLabel.ImageColor3 = self.Theme.Colors.TextSecondary
    end

    -- Hide content
    self.ContentContainer.Visible = false

    -- Sync deactivation with collaborators
    if self.Collaboration.Enabled and self.Collaboration.SyncState then
        self:_syncDeactivation()
    end
end

--[[
    Create a new section
]]
function Tab:CreateSection(config)
    local section = Section.new(config, self.Theme, self.ContentContainer, #self.Sections + 1)
    table.insert(self.Sections, section)

    -- Update canvas size
    self:_updateCanvasSize()

    return section
end

--[[
    Create a component directly in the tab
]]
function Tab:CreateComponent(componentType, config)
    -- Import the component
    local component
    if componentType == "Button" then
        component = require(script.Parent.Parent.components.Basic.Button)
    elseif componentType == "Toggle" then
        component = require(script.Parent.Parent.components.Basic.Toggle)
    elseif componentType == "Slider" then
        component = require(script.Parent.Parent.components.Basic.Slider)
    elseif componentType == "TextBox" then
        component = require(script.Parent.Parent.components.Basic.TextBox)
    elseif componentType == "Label" then
        component = require(script.Parent.Parent.components.Basic.Label)
    elseif componentType == "Dropdown" then
        component = require(script.Parent.Parent.components.Basic.Dropdown)
    else
        error("Unknown component type: " .. tostring(componentType))
    end

    -- Create component instance
    local componentInstance = component.new(config, self.Theme, self.ContentContainer, #self.Components + 1)
    table.insert(self.Components, componentInstance)

    -- Update canvas size
    self:_updateCanvasSize()

    return componentInstance
end

--[[
    Set tab theme
]]
function Tab:SetTheme(theme)
    self.Theme = theme

    -- Update tab button
    local background = self.TabButton.Background

    if self.State == TabState.Active then
        background.BackgroundColor3 = theme.Colors.Primary
        self.NameLabel.TextColor3 = theme.Colors.Text
        if self.IconLabel then
            self.IconLabel.ImageColor3 = theme.Colors.Text
        end
    else
        background.BackgroundColor3 = theme.Colors.Surface
        self.NameLabel.TextColor3 = theme.Colors.TextSecondary
        if self.IconLabel then
            self.IconLabel.ImageColor3 = theme.Colors.TextSecondary
        end
    end

    -- Update sections
    for _, section in ipairs(self.Sections) do
        section:SetTheme(theme)
    end

    -- Update components
    for _, component in ipairs(self.Components) do
        if component.SetTheme then
            component:SetTheme(theme)
        end
    end
end

--[[
    Update tab name
]]
function Tab:SetName(name)
    self.Name = name
    self.NameLabel.Text = name
    self.TabButton.Name = name .. "Tab"
    self.ContentContainer.Name = name .. "Content"
end

--[[
    Update tab icon
]]
function Tab:SetIcon(iconId)
    self.Icon = iconId

    if iconId then
        if not self.IconLabel then
            -- Create icon if it doesn't exist
            self.IconLabel = Instance.new("ImageLabel")
            self.IconLabel.Name = "Icon"
            self.IconLabel.Size = UDim2.new(0, 20, 0, 20)
            self.IconLabel.BackgroundTransparency = 1
            self.IconLabel.Parent = self.TabButton

            local aspectRatio = Instance.new("UIAspectRatioConstraint")
            aspectRatio.AspectRatio = 1
            aspectRatio.Parent = self.IconLabel

            -- Move icon to correct position in layout
            self.IconLabel.LayoutOrder = -1
        end

        self.IconLabel.Image = iconId
        self.IconLabel.Visible = true

        if self.State == TabState.Active then
            self.IconLabel.ImageColor3 = self.Theme.Colors.Text
        else
            self.IconLabel.ImageColor3 = self.Theme.Colors.TextSecondary
        end
    elseif self.IconLabel then
        self.IconLabel.Visible = false
    end
end

--[[
    Show a badge on the tab
]]
function Tab:ShowBadge(text, color)
    self.BadgeLabel.Text = tostring(text)
    self.BadgeLabel.BackgroundColor3 = color or self.Theme.Colors.Error
    self.BadgeLabel.Visible = true
end

--[[
    Update badge count
]]
function Tab:UpdateBadge(count)
    if count and count > 0 then
        self:ShowBadge(count)
    else
        self:ClearBadge()
    end
end

--[[
    Clear the badge
]]
function Tab:ClearBadge()
    self.BadgeLabel.Visible = false
    self.BadgeLabel.Text = ""
end

--[[
    Update layout
]]
function Tab:UpdateLayout()
    -- Update canvas size
    self:_updateCanvasSize()

    -- Update sections
    for _, section in ipairs(self.Sections) do
        if section.UpdateLayout then
            section:UpdateLayout()
        end
    end

    -- Update components
    for _, component in ipairs(self.Components) do
        if component.UpdateLayout then
            component:UpdateLayout()
        end
    end
end

--[[
    Update scrolling canvas size
]]
function Tab:_updateCanvasSize()
    if self.ContentFrame and self.ContentContainer.Visible then
        local contentSize = self.ContentContainer.AbsoluteContentSize
        self.ContentFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y)
    end

    if self.TabScrolling then
        local tabSize = self.TabScrolling.AbsoluteContentSize
        self.TabScrolling.CanvasSize = UDim2.new(0, tabSize.X, 0, 0)
    end
end

--[[
    Get tab ID
]]
function Tab:GetId()
    return self.Id
end

--[[
    Get tab name
]]
function Tab:GetName()
    return self.Name
end

--[[
    Check if tab is active
]]
function Tab:IsActive()
    return self.State == TabState.Active
end

--[[
    Get sections
]]
function Tab:GetSections()
    return self.Sections
end

--[[
    Get components
]]
function Tab:GetComponents()
    return self.Components
end

--[[
    Focus tab (scroll to it if needed)
]]
function Tab:Focus()
    -- Check if tab is visible in scrolling frame
    local tabButton = self.TabButton
    local scrollingFrame = self.TabScrolling

    if tabButton and scrollingFrame then
        local tabPosition = tabButton.AbsolutePosition
        local tabSize = tabButton.AbsoluteSize
        local scrollPosition = scrollingFrame.AbsolutePosition
        local scrollSize = scrollingFrame.AbsoluteSize

        local tabLeft = tabPosition.X - scrollPosition.X
        local tabRight = tabLeft + tabSize.X

        if tabLeft < 0 or tabRight > scrollSize.X then
            -- Scroll to make tab visible
            local targetOffset = math.max(0, tabLeft - 50)
            scrollingFrame.CanvasPosition = Vector2.new(targetOffset, 0)
        end
    end
end

--[[
    Collaboration sync methods
]]
function Tab:_syncActivation()
    -- Send activation event to collaboration server
end

function Tab:_syncDeactivation()
    -- Send deactivation event to collaboration server
end

function Tab:_syncScroll()
    -- Send scroll position to collaboration server
end

--[[
    Handle collaboration events
]]
function Tab:HandleCollaborationEvent(eventType, data)
    if eventType == "activate" then
        self:Activate()
    elseif eventType == "deactivate" then
        self:Deactivate()
    elseif eventType == "scroll" then
        if self.TabScrolling then
            self.TabScrolling.CanvasPosition = Vector2.new(data.scrollX, 0)
        end
    end
end

--[[
    Destroy the tab and clean up
]]
function Tab:Destroy()
    -- Disconnect connections
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end

    -- Destroy sections
    for _, section in ipairs(self.Sections) do
        section:Destroy()
    end

    -- Destroy components
    for _, component in ipairs(self.Components) do
        if component.Destroy then
            component:Destroy()
        end
    end

    -- Destroy GUI elements
    if self.TabButton then
        self.TabButton:Destroy()
    end

    if self.ContentContainer then
        self.ContentContainer:Destroy()
    end

    -- Clear references
    self.Sections = {}
    self.Components = {}
    self.Connections = {}
end

return Tab