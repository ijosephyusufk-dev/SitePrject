--[[
    Window Management System
    Core window functionality with drag, resize, minimize, and theme support

    @author Advanced UI Library Team
    @version 1.0.0
--]]

local Window = {}
Window.__index = Window

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Dependencies
local Tab = require(script.Parent.Tab)
local AnimationEngine = require(script.Parent.AnimationEngine)
local InputHandler = require(script.Parent.Parent.utils.InputHandler)

-- Window states
local WindowState = {
    Normal = "Normal",
    Minimized = "Minimized",
    Maximized = "Maximized",
    Closed = "Closed"
}

--[[
    Create a new window instance
]]
function Window.new(config, theme, globalConfig)
    local self = setmetatable({}, Window)

    -- Configuration
    self.Name = config.Name or "Window"
    self.Theme = theme
    self.Config = globalConfig or {}
    self.Size = config.Size or UDim2.new(0, 600, 0, 400)
    self.Position = config.Position or UDim2.new(0.5, -300, 0.5, -200)
    self.Resizable = config.Resizable ~= false
    self.Minimizable = config.Minimizable ~= false
    self.Draggable = config.Draggable ~= false
    self.SaveConfig = config.SaveConfig or false
    self.ConfigName = config.ConfigName or ("WindowConfig_" .. self.Name)

    -- Collaboration settings
    self.Collaboration = config.Collaboration or {}

    -- State
    self.State = WindowState.Normal
    self.IsVisible = false
    self.Tabs = {}
    self.ActiveTab = nil
    self.Components = {}
    self.ComponentCount = 0

    -- GUI elements
    self.ScreenGui = nil
    self.MainFrame = nil
    self.TitleBar = nil
    self.TitleLabel = nil
    self.ContentArea = nil
    self.TabContainer = nil
    self.ButtonContainer = nil

    -- Dragging state
    self.IsDragging = false
    self.DragStart = nil
    self.StartPosition = nil

    -- Resize state
    self.IsResizing = false
    self.ResizeStart = nil
    self.ResizeStartSize = nil
    self.ResizeHandle = nil

    -- Animation references
    self.Animations = {}

    -- Event connections
    self.Connections = {}

    self:_createGui()
    self:_setupEventHandlers()

    return self
end

--[[
    Create the GUI elements for the window
]]
function Window:_createGui()
    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = self.Name
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.IgnoreGuiInset = true
    self.ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Create main frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Size = self.Size
    self.MainFrame.Position = self.Position
    self.MainFrame.BackgroundColor3 = self.Theme.Colors.Background
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Parent = self.ScreenGui

    -- Apply corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, self.Theme.BorderRadius.Large)
    corner.Parent = self.MainFrame

    -- Create title bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.Size = UDim2.new(1, 0, 0, 40)
    self.TitleBar.Position = UDim2.new(0, 0, 0, 0)
    self.TitleBar.BackgroundColor3 = self.Theme.Colors.Surface
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.MainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, self.Theme.BorderRadius.Large)
    titleCorner.Parent = self.TitleBar

    -- Create title label
    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Name = "TitleLabel"
    self.TitleLabel.Size = UDim2.new(1, -120, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = self.Theme.Typography.Font
    self.TitleLabel.Text = self.Name
    self.TitleLabel.TextColor3 = self.Theme.Colors.Text
    self.TitleLabel.TextSize = self.Theme.Typography.TitleSize
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.Parent = self.TitleBar

    -- Create button container
    self.ButtonContainer = Instance.new("Frame")
    self.ButtonContainer.Name = "ButtonContainer"
    self.ButtonContainer.Size = UDim2.new(0, 100, 1, 0)
    self.ButtonContainer.Position = UDim2.new(1, -100, 0, 0)
    self.ButtonContainer.BackgroundTransparency = 1
    self.ButtonContainer.Parent = self.TitleBar

    -- Create window buttons
    if self.Minimizable then
        self:_createWindowButton("Minimize", UDim2.new(0, 30, 0, 30), UDim2.new(0, 0, 0, 5), function()
            self:Minimize()
        end)
    end

    self:_createWindowButton("Close", UDim2.new(0, 30, 0, 30), UDim2.new(0, 65, 0, 5), function()
        self:Close()
    end)

    -- Create tab container
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.Size = UDim2.new(1, -32, 0, 40)
    self.TabContainer.Position = UDim2.new(0, 16, 0, 45)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.Parent = self.MainFrame

    -- Create scrolling frame for tabs
    local tabScrolling = Instance.new("ScrollingFrame")
    tabScrolling.Name = "TabScrolling"
    tabScrolling.Size = UDim2.new(1, 0, 1, 0)
    tabScrolling.Position = UDim2.new(0, 0, 0, 0)
    tabScrolling.BackgroundTransparency = 1
    tabScrolling.BorderSizePixel = 0
    tabScrolling.ScrollBarThickness = 0
    tabScrolling.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScrolling.Parent = self.TabContainer

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabScrolling

    -- Create content area
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Name = "ContentArea"
    self.ContentArea.Size = UDim2.new(1, -32, 1, -100)
    self.ContentArea.Position = UDim2.new(0, 16, 0, 90)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.MainFrame

    -- Create content scrolling
    local contentScrolling = Instance.new("ScrollingFrame")
    contentScrolling.Name = "ContentScrolling"
    contentScrolling.Size = UDim2.new(1, 0, 1, 0)
    contentScrolling.Position = UDim2.new(0, 0, 0, 0)
    contentScrolling.BackgroundColor3 = self.Theme.Colors.Surface
    contentScrolling.BorderSizePixel = 0
    contentScrolling.ScrollBarThickness = 8
    contentScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScrolling.Parent = self.ContentArea

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, self.Theme.BorderRadius.Medium)
    contentCorner.Parent = contentScrolling

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 16)
    contentLayout.Parent = contentScrolling

    -- Create resize handle if resizable
    if self.Resizable then
        self:_createResizeHandle()
    end

    -- Store references
    self.TabScrolling = tabScrolling
    self.ContentScrolling = contentScrolling
end

--[[
    Create a window control button
]]
function Window:_createWindowButton(name, size, position, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = self.Theme.Colors.Surface
    button.BorderSizePixel = 0
    button.Font = self.Theme.Typography.Font
    button.Text = ""
    button.Parent = self.ButtonContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, self.Theme.BorderRadius.Small)
    corner.Parent = button

    -- Add icon (simplified for now)
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.GothamMedium
    icon.Text = name == "Close" and "×" or "−"
    icon.TextColor3 = self.Theme.Colors.Text
    icon.TextSize = 16
    icon.Parent = button

    -- Hover effects
    button.MouseEnter:Connect(function()
        AnimationEngine:Hover(button, self.Theme.Colors.Primary, 0.2)
    end)

    button.MouseLeave:Connect(function()
        AnimationEngine:Unhover(button, self.Theme.Colors.Surface, 0.2)
    end)

    button.MouseButton1Click:Connect(callback)
end

--[[
    Create resize handle
]]
function Window:_createResizeHandle()
    self.ResizeHandle = Instance.new("Frame")
    self.ResizeHandle.Name = "ResizeHandle"
    self.ResizeHandle.Size = UDim2.new(0, 16, 0, 16)
    self.ResizeHandle.Position = UDim2.new(1, -16, 1, -16)
    self.ResizeHandle.BackgroundColor3 = self.Theme.Colors.Border
    self.ResizeHandle.BorderSizePixel = 0
    self.ResizeHandle.Parent = self.MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, self.Theme.BorderRadius.Small)
    corner.Parent = self.ResizeHandle

    -- Add resize icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 8, 0, 8)
    icon.Position = UDim2.new(0.5, -4, 0.5, -4)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxasset://textures/ui/InspectMenu/resize.png"
    icon.ImageColor3 = self.Theme.Colors.TextSecondary
    icon.Parent = self.ResizeHandle
end

--[[
    Setup event handlers for dragging and resizing
]]
function Window:_setupEventHandlers()
    -- Title bar dragging
    if self.Draggable then
        self.TitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:_startDragging(input)
            end
        end)

        self.TitleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:_stopDragging()
            end
        end)
    end

    -- Resize handle
    if self.Resizable and self.ResizeHandle then
        self.ResizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:_startResizing(input)
            end
        end)

        self.ResizeHandle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:_stopResizing()
            end
        end)
    end

    -- Mouse movement for dragging and resizing
    local connection
    connection = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if self.IsDragging then
                self:_updateDragging(input)
            elseif self.IsResizing then
                self:_updateResizing(input)
            end
        end
    end)

    table.insert(self.Connections, connection)

    -- Window focus
    self.MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_bringToFront()
        end
    end)
end

--[[
    Start dragging the window
]]
function Window:_startDragging(input)
    self.IsDragging = true
    self.DragStart = input.Position
    self.StartPosition = self.MainFrame.Position
end

--[[
    Update window position while dragging
]]
function Window:_updateDragging(input)
    if not self.IsDragging then return end

    local delta = input.Position - self.DragStart
    local newPosition = UDim2.new(
        self.StartPosition.X.Scale,
        self.StartPosition.X.Offset + delta.X,
        self.StartPosition.Y.Scale,
        self.StartPosition.Y.Offset + delta.Y
    )

    -- Keep window within screen bounds
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local windowSize = self.MainFrame.AbsoluteSize

    newPosition.X.Offset = math.max(0, math.min(newPosition.X.Offset, viewportSize.X - windowSize.X))
    newPosition.Y.Offset = math.max(0, math.min(newPosition.Y.Offset, viewportSize.Y - windowSize.Y))

    self.MainFrame.Position = newPosition

    -- Sync position with collaborators
    if self.Collaboration.Enabled and self.Collaboration.SyncState then
        self:_syncPosition(newPosition)
    end
end

--[[
    Stop dragging the window
]]
function Window:_stopDragging()
    self.IsDragging = false
    self:_saveConfig()
end

--[[
    Start resizing the window
]]
function Window:_startResizing(input)
    self.IsResizing = true
    self.ResizeStart = input.Position
    self.ResizeStartSize = self.MainFrame.Size
end

--[[
    Update window size while resizing
]]
function Window:_updateResizing(input)
    if not self.IsResizing then return end

    local delta = input.Position - self.ResizeStart
    local newSize = UDim2.new(
        self.ResizeStartSize.X.Scale,
        math.max(400, self.ResizeStartSize.X.Offset + delta.X),
        self.ResizeStartSize.Y.Scale,
        math.max(300, self.ResizeStartSize.Y.Offset + delta.Y)
    )

    self.MainFrame.Size = newSize

    -- Update content area size
    self:_updateContentSize()

    -- Sync size with collaborators
    if self.Collaboration.Enabled and self.Collaboration.SyncState then
        self:_syncSize(newSize)
    end
end

--[[
    Stop resizing the window
]]
function Window:_stopResizing()
    self.IsResizing = false
    self:_saveConfig()
end

--[[
    Update content area size
]]
function Window:_updateContentSize()
    -- Content area adjusts automatically with AutoSize
    -- But we might need to update component layouts
    for _, tab in ipairs(self.Tabs) do
        tab:UpdateLayout()
    end
end

--[[
    Bring window to front
]]
function Window:_bringToFront()
    self.ScreenGui.DisplayOrder = 1000 + (#self.Connections + 1)
end

--[[
    Create a new tab
]]
function Window:CreateTab(config)
    local tab = Tab.new(config, self.Theme, self.ContentScrolling, self.TabScrolling, #self.Tabs + 1)
    table.insert(self.Tabs, tab)

    -- Set as active tab if it's the first one
    if #self.Tabs == 1 then
        self:SetActiveTab(tab)
    end

    return tab
end

--[[
    Set the active tab
]]
function Window:SetActiveTab(tab)
    if self.ActiveTab then
        self.ActiveTab:SetActive(false)
    end

    self.ActiveTab = tab
    tab:SetActive(true)

    -- Sync tab selection with collaborators
    if self.Collaboration.Enabled and self.Collaboration.SyncState then
        self:_syncActiveTab(tab:GetId())
    end
end

--[[
    Get the active tab
]]
function Window:GetActiveTab()
    return self.ActiveTab
end

--[[
    Set window theme
]]
function Window:SetTheme(theme)
    self.Theme = theme

    -- Update all GUI elements
    self.MainFrame.BackgroundColor3 = theme.Colors.Background
    self.TitleBar.BackgroundColor3 = theme.Colors.Surface
    self.TitleLabel.TextColor3 = theme.Colors.Text
    self.ContentScrolling.BackgroundColor3 = theme.Colors.Surface

    -- Update tabs
    for _, tab in ipairs(self.Tabs) do
        tab:SetTheme(theme)
    end

    -- Update components
    for _, component in pairs(self.Components) do
        if component.SetTheme then
            component:SetTheme(theme)
        end
    end
end

--[[
    Show the window
]]
function Window:Show()
    if self.IsVisible then return end

    self.IsVisible = true
    self.ScreenGui.Enabled = true

    -- Animate window appearance
    self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
    self.MainFrame:TweenSize(
        self.Size,
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Back,
        0.3,
        true
    )

    -- Sync visibility with collaborators
    if self.Collaboration.Enabled then
        self:_syncVisibility(true)
    end
end

--[[
    Hide the window
]]
function Window:Hide()
    if not self.IsVisible then return end

    self.IsVisible = false

    -- Animate window disappearance
    self.MainFrame:TweenSize(
        UDim2.new(0, 0, 0, 0),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Back,
        0.2,
        true,
        function()
            self.ScreenGui.Enabled = false
            self.MainFrame.Size = self.Size
        end
    )

    -- Sync visibility with collaborators
    if self.Collaboration.Enabled then
        self:_syncVisibility(false)
    end
end

--[[
    Minimize the window
]]
function Window:Minimize()
    if self.State == WindowState.Minimized then return end

    self.State = WindowState.Minimized
    self.ContentArea.Visible = false
    self.TabContainer.Visible = false

    -- Animate to minimized state
    self.MainFrame:TweenSize(
        UDim2.new(0, 200, 0, 40),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.2,
        true
    )

    -- Sync state with collaborators
    if self.Collaboration.Enabled and self.Collaboration.SyncState then
        self:_syncWindowState(WindowState.Minimized)
    end
end

--[[
    Restore window from minimized state
]]
function Window:Restore()
    if self.State ~= WindowState.Minimized then return end

    self.State = WindowState.Normal
    self.ContentArea.Visible = true
    self.TabContainer.Visible = true

    -- Animate back to normal size
    self.MainFrame:TweenSize(
        self.Size,
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.2,
        true
    )

    -- Sync state with collaborators
    if self.Collaboration.Enabled and self.Collaboration.SyncState then
        self:_syncWindowState(WindowState.Normal)
    end
end

--[[
    Close the window
]]
function Window:Close()
    if self.State == WindowState.Closed then return end

    self.State = WindowState.Closed

    -- Animate window closure
    self.MainFrame:TweenSize(
        UDim2.new(0, 0, 0, 0),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Back,
        0.2,
        true,
        function()
            self:Destroy()
        end
    )

    -- Sync closure with collaborators
    if self.Collaboration.Enabled then
        self:_syncWindowState(WindowState.Closed)
    end
end

--[[
    Enable collaboration for this window
]]
function Window:EnableCollaboration(config)
    self.Collaboration = config
    -- Implementation would connect to collaboration system
end

--[[
    Register a component
]]
function Window:RegisterComponent(component)
    self.ComponentCount = self.ComponentCount + 1
    self.Components[component:GetId()] = component
end

--[[
    Unregister a component
]]
function Window:UnregisterComponent(componentId)
    if self.Components[componentId] then
        self.Components[componentId] = nil
        self.ComponentCount = self.ComponentCount - 1
    end
end

--[[
    Get component count
]]
function Window:GetComponentCount()
    return self.ComponentCount
end

--[[
    Save window configuration
]]
function Window:_saveConfig()
    if not self.SaveConfig then return end

    local config = {
        Position = {
            X = self.MainFrame.Position.X.Offset,
            Y = self.MainFrame.Position.Y.Offset
        },
        Size = {
            X = self.MainFrame.Size.X.Offset,
            Y = self.MainFrame.Size.Y.Offset
        },
        State = self.State,
        ActiveTab = self.ActiveTab and self.ActiveTab:GetId() or nil
    }

    -- Save to DataStore or local storage
    -- Implementation depends on storage method
end

--[[
    Collaboration sync methods (simplified)
]]
function Window:_syncPosition(position)
    -- Send position update to collaboration server
end

function Window:_syncSize(size)
    -- Send size update to collaboration server
end

function Window:_syncActiveTab(tabId)
    -- Send active tab update to collaboration server
end

function Window:_syncWindowState(state)
    -- Send window state update to collaboration server
end

function Window:_syncVisibility(visible)
    -- Send visibility update to collaboration server
end

--[[
    Destroy the window and clean up
]]
function Window:Destroy()
    -- Disconnect all connections
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end

    -- Destroy tabs
    for _, tab in ipairs(self.Tabs) do
        tab:Destroy()
    end

    -- Destroy components
    for _, component in pairs(self.Components) do
        if component.Destroy then
            component:Destroy()
        end
    end

    -- Destroy GUI elements
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end

    -- Clear references
    self.Tabs = {}
    self.Components = {}
    self.Connections = {}
end

return Window