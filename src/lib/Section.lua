--[[
    Section Organization System
    Collapsible sections with smooth animations and intelligent layout

    @author Advanced UI Library Team
    @version 1.0.0
--]]

local Section = {}
Section.__index = Section

-- Dependencies
local AnimationEngine = require(script.Parent.AnimationEngine)

-- Section state
local SectionState = {
    Expanded = "Expanded",
    Collapsed = "Collapsed",
    Animating = "Animating"
}

--[[
    Create a new section instance
]]
function Section.new(config, theme, parentFrame, layoutOrder)
    local self = setmetatable({}, Section)

    -- Configuration
    self.Name = config.Name or "Section"
    self.Theme = theme
    self.ParentFrame = parentFrame
    self.LayoutOrder = layoutOrder or 1
    self.Collapsible = config.Collapsible ~= false
    self.DefaultCollapsed = config.DefaultCollapsed or false
    self.Description = config.Description

    -- Collaboration settings
    self.Collaboration = config.Collaboration or {}

    -- State
    self.State = self.DefaultCollapsed and SectionState.Collapsed or SectionState.Expanded
    self.IsVisible = true
    self.Components = {}

    -- GUI elements
    self.Container = nil
    self.Header = nil
    self.TitleLabel = nil
    self.DescriptionLabel = nil
    self.ToggleButton = nil
    self.ToggleIcon = nil
    self.ContentFrame = nil
    self.ContentScrolling = nil

    -- Events
    self.Connections = {}

    -- Animation references
    self.CurrentAnimation = nil

    -- Unique ID for tracking
    self.Id = "Section_" .. tick() .. "_" .. math.random(1000, 9999)

    self:_createGui()
    self:_setupEventHandlers()

    return self
end

--[[
    Create GUI elements for the section
]]
function Section:_createGui()
    -- Create main container
    self.Container = Instance.new("Frame")
    self.Container.Name = self.Name .. "Section"
    self.Container.Size = UDim2.new(1, 0, 0, 0)
    self.Container.BackgroundTransparency = 1
    self.Container.LayoutOrder = self.LayoutOrder
    self.Container.Parent = self.ParentFrame

    -- Create header
    self.Header = Instance.new("Frame")
    self.Header.Name = "Header"
    self.Header.Size = UDim2.new(1, 0, 0, 0)
    self.Header.BackgroundColor3 = self.Theme.Colors.Surface
    self.Header.BorderSizePixel = 0
    self.Header.Parent = self.Container

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, self.Theme.BorderRadius.Medium)
    headerCorner.Parent = self.Header

    -- Create header content layout
    local headerLayout = Instance.new("UIListLayout")
    headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    headerLayout.Padding = UDim.new(0, self.Theme.Spacing.S)
    headerLayout.Parent = self.Header

    -- Create title row
    local titleRow = Instance.new("Frame")
    titleRow.Name = "TitleRow"
    titleRow.Size = UDim2.new(1, 0, 0, 36)
    titleRow.BackgroundTransparency = 1
    titleRow.LayoutOrder = 1
    titleRow.Parent = self.Header

    -- Create title row layout
    local titleLayout = Instance.new("UIListLayout")
    titleLayout.FillDirection = Enum.FillDirection.Horizontal
    titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    titleLayout.Padding = UDim.new(0, self.Theme.Spacing.S)
    titleLayout.Parent = titleRow

    -- Create toggle button if collapsible
    if self.Collapsible then
        self.ToggleButton = Instance.new("TextButton")
        self.ToggleButton.Name = "ToggleButton"
        self.ToggleButton.Size = UDim2.new(0, 24, 0, 24)
        self.ToggleButton.BackgroundTransparency = 1
        self.ToggleButton.BorderSizePixel = 0
        self.ToggleButton.Text = ""
        self.ToggleButton.Parent = titleRow

        -- Create toggle icon
        self.ToggleIcon = Instance.new("ImageLabel")
        self.ToggleIcon.Name = "ToggleIcon"
        self.ToggleIcon.Size = UDim2.new(0, 16, 0, 16)
        self.ToggleIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
        self.ToggleIcon.BackgroundTransparency = 1
        self.ToggleIcon.Image = "rbxasset://textures/ui/InspectMenu/expand.png"
        self.ToggleIcon.ImageColor3 = self.Theme.Colors.TextSecondary
        self.ToggleIcon.Parent = self.ToggleButton

        -- Set initial rotation based on state
        if self.State == SectionState.Collapsed then
            self.ToggleIcon.Rotation = 0
        else
            self.ToggleIcon.Rotation = 90
        end
    else
        -- Add spacer if not collapsible
        local spacer = Instance.new("Frame")
        spacer.Name = "Spacer"
        spacer.Size = UDim2.new(0, 8, 1, 0)
        spacer.BackgroundTransparency = 1
        spacer.Parent = titleRow
    end

    -- Create title label
    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Name = "TitleLabel"
    self.TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = self.Theme.Typography.Font
    self.TitleLabel.Text = self.Name
    self.TitleLabel.TextColor3 = self.Theme.Colors.Text
    self.TitleLabel.TextSize = self.Theme.Typography.HeaderSize
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.Parent = titleRow

    -- Create description label if provided
    if self.Description then
        self.DescriptionLabel = Instance.new("TextLabel")
        self.DescriptionLabel.Name = "DescriptionLabel"
        self.DescriptionLabel.Size = UDim2.new(1, -16, 0, 0)
        self.DescriptionLabel.AutomaticSize = Enum.AutomaticSize.Y
        self.DescriptionLabel.Position = UDim2.new(0, 8, 0, 0)
        self.DescriptionLabel.BackgroundTransparency = 1
        self.DescriptionLabel.Font = self.Theme.Typography.Font
        self.DescriptionLabel.Text = self.Description
        self.DescriptionLabel.TextColor3 = self.Theme.Colors.TextSecondary
        self.DescriptionLabel.TextSize = self.Theme.Typography.TextSize
        self.DescriptionLabel.TextWrapped = true
        self.DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        self.DescriptionLabel.LayoutOrder = 2
        self.DescriptionLabel.Parent = self.Header
    end

    -- Create content frame
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Name = "ContentFrame"
    self.ContentFrame.Size = UDim2.new(1, 0, 0, 0)
    self.ContentFrame.BackgroundTransparency = 1
    self.ContentFrame.BorderSizePixel = 0
    self.ContentFrame.Parent = self.Container

    -- Create content scrolling frame
    self.ContentScrolling = Instance.new("ScrollingFrame")
    self.ContentScrolling.Name = "ContentScrolling"
    self.ContentScrolling.Size = UDim2.new(1, 0, 1, 0)
    self.ContentScrolling.Position = UDim2.new(0, 0, 0, 0)
    self.ContentScrolling.BackgroundTransparency = 1
    self.ContentScrolling.BorderSizePixel = 0
    self.ContentScrolling.ScrollBarThickness = 0
    self.ContentScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.ContentScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.ContentScrolling.Parent = self.ContentFrame

    -- Create content layout
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, self.Theme.Spacing.S)
    contentLayout.Parent = self.ContentScrolling

    -- Update container size based on content
    self:_updateSize()

    -- Set initial visibility
    if self.State == SectionState.Collapsed then
        self.ContentFrame.Visible = false
    end
end

--[[
    Setup event handlers for section interactions
]]
function Section:_setupEventHandlers()
    -- Toggle button click
    if self.Collapsible and self.ToggleButton then
        local connection = self.ToggleButton.MouseButton1Click:Connect(function()
            self:Toggle()
        end)
        table.insert(self.Connections, connection)

        -- Hover effects
        connection = self.ToggleButton.MouseEnter:Connect(function()
            AnimationEngine:Hover(self.ToggleButton, self.Theme.Colors.Primary, 0.2)
        end)
        table.insert(self.Connections, connection)

        connection = self.ToggleButton.MouseLeave:Connect(function()
            AnimationEngine:Unhover(self.ToggleButton, self.Theme.Colors.Surface, 0.2)
        end)
        table.insert(self.Connections, connection)
    end

    -- Content size change
    local connection = self.ContentScrolling:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self:_updateSize()
    end)
    table.insert(self.Connections, connection)
end

--[[
    Toggle section expanded/collapsed state
]]
function Section:Toggle()
    if not self.Collapsible then return end

    if self.State == SectionState.Expanded then
        self:Collapse()
    elseif self.State == SectionState.Collapsed then
        self:Expand()
    end
end

--[[
    Expand the section
]]
function Section:Expand()
    if not self.Collapsible or self.State == SectionState.Expanded then return end

    self.State = SectionState.Animating

    -- Animate toggle icon
    if self.ToggleIcon then
        self.CurrentAnimation = AnimationEngine:Rotate(
            self.ToggleIcon,
            90,
            0.3,
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad
        )
    end

    -- Show content
    self.ContentFrame.Visible = true
    self.ContentFrame.Size = UDim2.new(1, 0, 0, 0)

    -- Animate content appearance
    local contentSize = self.ContentScrolling.AbsoluteContentSize.Y
    self.ContentFrame:TweenSize(
        UDim2.new(1, 0, 0, contentSize),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true,
        function()
            self.State = SectionState.Expanded
            self:_updateSize()
            self.CurrentAnimation = nil

            -- Sync expansion with collaborators
            if self.Collaboration.Enabled and self.Collaboration.SyncState then
                self:_syncExpanded()
            end
        end
    )
end

--[[
    Collapse the section
]]
function Section:Collapse()
    if not self.Collapsible or self.State == SectionState.Collapsed then return end

    self.State = SectionState.Animating

    -- Animate toggle icon
    if self.ToggleIcon then
        self.CurrentAnimation = AnimationEngine:Rotate(
            self.ToggleIcon,
            0,
            0.3,
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad
        )
    end

    -- Animate content disappearance
    self.ContentFrame:TweenSize(
        UDim2.new(1, 0, 0, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true,
        function()
            self.ContentFrame.Visible = false
            self.State = SectionState.Collapsed
            self:_updateSize()
            self.CurrentAnimation = nil

            -- Sync collapse with collaborators
            if self.Collaboration.Enabled and self.Collaboration.SyncState then
                self:_syncCollapsed()
            end
        end
    )
end

--[[
    Set section expanded state
]]
function Section:SetExpanded(isExpanded)
    if isExpanded then
        self:Expand()
    else
        self:Collapse()
    end
end

--[[
    Add a component to the section
]]
function Section:AddComponent(component)
    table.insert(self.Components, component)
    self:_updateSize()
end

--[[
    Create a component in the section
]]
function Section:CreateComponent(componentType, config)
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
    local componentInstance = component.new(config, self.Theme, self.ContentScrolling, #self.Components + 1)
    table.insert(self.Components, componentInstance)

    -- Update size
    self:_updateSize()

    return componentInstance
end

--[[
    Remove a component from the section
]]
function Section:RemoveComponent(component)
    for i, comp in ipairs(self.Components) do
        if comp == component then
            table.remove(self.Components, i)
            if component.Destroy then
                component:Destroy()
            end
            self:_updateSize()
            break
        end
    end
end

--[[
    Set section theme
]]
function Section:SetTheme(theme)
    self.Theme = theme

    -- Update header
    self.Header.BackgroundColor3 = theme.Colors.Surface
    self.TitleLabel.TextColor3 = theme.Colors.Text

    if self.DescriptionLabel then
        self.DescriptionLabel.TextColor3 = theme.Colors.TextSecondary
    end

    if self.ToggleIcon then
        self.ToggleIcon.ImageColor3 = theme.Colors.TextSecondary
    end

    -- Update components
    for _, component in ipairs(self.Components) do
        if component.SetTheme then
            component:SetTheme(theme)
        end
    end
end

--[[
    Update section name
]]
function Section:SetName(name)
    self.Name = name
    self.TitleLabel.Text = name
    self.Container.Name = name .. "Section"
end

--[[
    Update section description
]]
function Section:SetDescription(description)
    self.Description = description

    if description then
        if not self.DescriptionLabel then
            -- Create description label
            self.DescriptionLabel = Instance.new("TextLabel")
            self.DescriptionLabel.Name = "DescriptionLabel"
            self.DescriptionLabel.Size = UDim2.new(1, -16, 0, 0)
            self.DescriptionLabel.AutomaticSize = Enum.AutomaticSize.Y
            self.DescriptionLabel.Position = UDim2.new(0, 8, 0, 0)
            self.DescriptionLabel.BackgroundTransparency = 1
            self.DescriptionLabel.Font = self.Theme.Typography.Font
            self.DescriptionLabel.TextColor3 = self.Theme.Colors.TextSecondary
            self.DescriptionLabel.TextSize = self.Theme.Typography.TextSize
            self.DescriptionLabel.TextWrapped = true
            self.DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
            self.DescriptionLabel.LayoutOrder = 2
            self.DescriptionLabel.Parent = self.Header
        end

        self.DescriptionLabel.Text = description
        self.DescriptionLabel.Visible = true
    elseif self.DescriptionLabel then
        self.DescriptionLabel.Visible = false
    end

    self:_updateSize()
end

--[[
    Update section size based on content
]]
function Section:_updateSize()
    -- Calculate header height
    local headerHeight = 36 -- Title row height
    if self.DescriptionLabel and self.DescriptionLabel.Visible then
        headerHeight = headerHeight + self.DescriptionLabel.TextBounds.Y + self.Theme.Spacing.S
    end

    -- Set header size
    self.Header.Size = UDim2.new(1, 0, 0, headerHeight)

    -- Calculate content height
    local contentHeight = 0
    if self.State == SectionState.Expanded then
        contentHeight = self.ContentScrolling.AbsoluteContentSize.Y
    end

    -- Set content frame size
    self.ContentFrame.Size = UDim2.new(1, 0, 0, contentHeight)

    -- Set container size
    local totalHeight = headerHeight + contentHeight
    self.Container.Size = UDim2.new(1, 0, 0, totalHeight)
end

--[[
    Update layout
]]
function Section:UpdateLayout()
    self:_updateSize()

    -- Update components
    for _, component in ipairs(self.Components) do
        if component.UpdateLayout then
            component:UpdateLayout()
        end
    end
end

--[[
    Get section ID
]]
function Section:GetId()
    return self.Id
end

--[[
    Get section name
]]
function Section:GetName()
    return self.Name
end

--[[
    Check if section is expanded
]]
function Section:IsExpanded()
    return self.State == SectionState.Expanded
end

--[[
    Check if section is collapsed
]]
function Section:IsCollapsed()
    return self.State == SectionState.Collapsed
end

--[[
    Get components
]]
function Section:GetComponents()
    return self.Components
end

--[[
    Search through section content
]]
function Section:Search(query)
    local results = {}

    if query and query ~= "" then
        local lowerQuery = string.lower(query)

        -- Search section name
        if string.find(string.lower(self.Name), lowerQuery) then
            table.insert(results, {
                Type = "Section",
                Name = self.Name,
                Section = self
            })
        end

        -- Search description
        if self.Description and string.find(string.lower(self.Description), lowerQuery) then
            table.insert(results, {
                Type = "Description",
                Name = self.Name,
                Section = self,
                Content = self.Description
            })
        end

        -- Search components
        for _, component in ipairs(self.Components) do
            if component.Search then
                local componentResults = component:Search(query)
                for _, result in ipairs(componentResults) do
                    result.Section = self
                    table.insert(results, result)
                end
            end
        end

        -- Expand section if matches found and it's collapsed
        if #results > 0 and self:IsCollapsed() then
            self:Expand()
        end
    end

    return results
end

--[[
    Collaboration sync methods
]]
function Section:_syncExpanded()
    -- Send expansion event to collaboration server
end

function Section:_syncCollapsed()
    -- Send collapse event to collaboration server
end

--[[
    Handle collaboration events
]]
function Section:HandleCollaborationEvent(eventType, data)
    if eventType == "expand" then
        self:Expand()
    elseif eventType == "collapse" then
        self:Collapse()
    end
end

--[[
    Destroy the section and clean up
]]
function Section:Destroy()
    -- Stop any ongoing animation
    if self.CurrentAnimation then
        self.CurrentAnimation:Cancel()
        self.CurrentAnimation = nil
    end

    -- Disconnect connections
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end

    -- Destroy components
    for _, component in ipairs(self.Components) do
        if component.Destroy then
            component:Destroy()
        end
    end

    -- Destroy GUI elements
    if self.Container then
        self.Container:Destroy()
    end

    -- Clear references
    self.Components = {}
    self.Connections = {}
end

return Section