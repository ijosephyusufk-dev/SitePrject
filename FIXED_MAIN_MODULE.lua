--[[
    Advanced Roblox GUI Library - SIMPLIFIED Main Module
    This version fixes the structural issues and provides a working foundation

    USAGE:
    1. Create Folder in ReplicatedStorage named "AdvancedUILib"
    2. Create ModuleScript in that folder named "Main"
    3. Copy this entire script into that ModuleScript
    4. Use the FIXED_EXAMPLE.lua script to load it
--]]

local AdvancedUILib = {}
AdvancedUILib.__index = AdvancedUILib

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Simple theme definitions
local THEMES = {
    Default = {
        Background = Color3.new(0.1, 0.1, 0.1),
        Surface = Color3.new(0.15, 0.15, 0.15),
        Primary = Color3.new(0, 0.4, 0.8),
        Text = Color3.new(1, 1, 1),
        TextSecondary = Color3.new(0.7, 0.7, 0.7),
        Border = Color3.new(0.3, 0.3, 0.3),
        Success = Color3.new(0, 0.8, 0),
        Warning = Color3.new(1, 0.8, 0),
        Error = Color3.new(0.8, 0, 0)
    },
    Dark = {
        Background = Color3.new(0.05, 0.05, 0.05),
        Surface = Color3.new(0.1, 0.1, 0.1),
        Primary = Color3.new(0.1, 0.3, 0.6),
        Text = Color3.new(0.95, 0.95, 0.95),
        TextSecondary = Color3.new(0.6, 0.6, 0.6),
        Border = Color3.new(0.2, 0.2, 0.2),
        Success = Color3.new(0.1, 0.7, 0.1),
        Warning = Color3.new(0.9, 0.7, 0.1),
        Error = Color3.new(0.7, 0.1, 0.1)
    }
}

local currentTheme = THEMES.Default
local windows = {}

--[[
    Simple Window Class
]]
local Window = {}
Window.__index = Window

function Window.new(config)
    local self = setmetatable({}, Window)

    self.Name = config.Name or "Window"
    self.Theme = config.Theme or "Default"
    self.Size = config.Size or UDim2.new(0, 400, 0, 300)
    self.Position = config.Position or UDim2.new(0.5, -200, 0.5, -150)
    self.Visible = false
    self.Tabs = {}

    self:_createGui()
    return self
end

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
    self.MainFrame.BackgroundColor3 = currentTheme.Background
    self.MainFrame.BorderSizePixel = 1
    self.MainFrame.BorderColor3 = currentTheme.Border
    self.MainFrame.Parent = self.ScreenGui

    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.MainFrame

    -- Create title bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.Size = UDim2.new(1, 0, 0, 40)
    self.TitleBar.Position = UDim2.new(0, 0, 0, 0)
    self.TitleBar.BackgroundColor3 = currentTheme.Surface
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.MainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = self.TitleBar

    -- Create title label
    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Name = "TitleLabel"
    self.TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = Enum.Font.Gotham
    self.TitleLabel.Text = self.Name
    self.TitleLabel.TextColor3 = currentTheme.Text
    self.TitleLabel.TextSize = 16
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.Parent = self.TitleBar

    -- Create close button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Name = "CloseButton"
    self.CloseButton.Size = UDim2.new(0, 30, 0, 30)
    self.CloseButton.Position = UDim2.new(1, -40, 0, 5)
    self.CloseButton.BackgroundColor3 = currentTheme.Error
    self.CloseButton.BorderSizePixel = 0
    self.CloseButton.Font = Enum.Font.GothamMedium
    self.CloseButton.Text = "×"
    self.CloseButton.TextColor3 = Color3.new(1, 1, 1)
    self.CloseButton.TextSize = 18
    self.CloseButton.Parent = self.TitleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = self.CloseButton

    -- Create content area
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Name = "ContentArea"
    self.ContentArea.Size = UDim2.new(1, -16, 1, -56)
    self.ContentArea.Position = UDim2.new(0, 8, 0, 48)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.MainFrame

    -- Create tab container
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.Size = UDim2.new(1, 0, 0, 40)
    self.TabContainer.Position = UDim2.new(0, 0, 0, 0)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.Parent = self.ContentArea

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = self.TabContainer

    -- Create tab content area
    self.TabContent = Instance.new("ScrollingFrame")
    self.TabContent.Name = "TabContent"
    self.TabContent.Size = UDim2.new(1, 0, 1, -40)
    self.TabContent.Position = UDim2.new(0, 0, 0, 40)
    self.TabContent.BackgroundTransparency = 1
    self.TabContent.BorderSizePixel = 0
    self.TabContent.ScrollBarThickness = 8
    self.TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabContent.Parent = self.ContentArea

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = self.TabContent

    -- Setup dragging
    self:_setupDragging()

    -- Setup close button
    self.CloseButton.MouseButton1Click:Connect(function()
        self:Hide()
    end)
end

function Window:_setupDragging()
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart = nil
    local startPos = nil

    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

function Window:CreateTab(config)
    local Tab = {}
    Tab.Name = config.Name or "Tab"
    Tab.Components = {}

    -- Create tab button
    local TabButton = Instance.new("TextButton")
    TabButton.Name = Tab.Name .. "Tab"
    TabButton.Size = UDim2.new(0, 100, 1, 0)
    TabButton.BackgroundColor3 = currentTheme.Surface
    TabButton.BorderSizePixel = 0
    TabButton.Font = Enum.Font.Gotham
    TabButton.Text = Tab.Name
    TabButton.TextColor3 = currentTheme.TextSecondary
    TabButton.TextSize = 14
    TabButton.Parent = self.TabContainer

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = TabButton

    -- Create tab content
    local TabContent = Instance.new("Frame")
    TabContent.Name = Tab.Name .. "Content"
    TabContent.Size = UDim2.new(1, 0, 0, 0)
    TabContent.BackgroundTransparency = 1
    TabContent.Visible = false
    TabContent.Parent = self.TabContent

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = TabContent

    -- Tab functions
    function Tab:CreateButton(config)
        local button = Instance.new("TextButton")
        button.Name = config.Name or "Button"
        button.Size = UDim2.new(1, -16, 0, 30)
        button.BackgroundColor3 = currentTheme.Primary
        button.BorderSizePixel = 0
        button.Font = Enum.Font.Gotham
        button.Text = config.Name or "Button"
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 14
        button.Parent = TabContent

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button

        -- Hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = currentTheme.Primary:lerp(Color3.new(1, 1, 1), 0.2)
        end)

        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = currentTheme.Primary
        end)

        button.MouseButton1Click:Connect(config.Callback or function() end)

        -- Update canvas size
        self:_updateCanvasSize()

        return button
    end

    function Tab:CreateToggle(config)
        local toggle = Instance.new("Frame")
        toggle.Name = config.Name or "Toggle"
        toggle.Size = UDim2.new(1, -16, 0, 30)
        toggle.BackgroundColor3 = currentTheme.Surface
        toggle.BorderSizePixel = 0
        toggle.Parent = TabContent

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 4)
        toggleCorner.Parent = toggle

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.Text = config.Name or "Toggle"
        label.TextColor3 = currentTheme.Text
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggle

        local toggleButton = Instance.new("TextButton")
        toggleButton.Size = UDim2.new(0, 40, 0, 20)
        toggleButton.Position = UDim2.new(1, -45, 0, 5)
        toggleButton.BackgroundColor3 = config.Default and currentTheme.Success or currentTheme.Border
        toggleButton.BorderSizePixel = 0
        toggleButton.Font = Enum.Font.GothamMedium
        toggleButton.Text = config.Default and "✓" or ""
        toggleButton.TextColor3 = Color3.new(1, 1, 1)
        toggleButton.TextSize = 12
        toggleButton.Parent = toggle

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 10)
        buttonCorner.Parent = toggleButton

        local state = config.Default or false

        toggleButton.MouseButton1Click:Connect(function()
            state = not state
            toggleButton.BackgroundColor3 = state and currentTheme.Success or currentTheme.Border
            toggleButton.Text = state and "✓" or ""

            if config.Callback then
                config.Callback(state)
            end
        end)

        self:_updateCanvasSize()

        return toggle
    end

    function Tab:_updateCanvasSize()
        local contentSize = TabContent.AbsoluteContentSize
        TabContent.Size = UDim2.new(1, 0, 0, contentSize.Y)
        self.TabContent.CanvasSize = UDim2.new(0, 0, 0, self.TabContent.AbsoluteContentSize.Y)
    end

    -- Tab switching
    TabButton.MouseButton1Click:Connect(function()
        -- Hide all other tabs
        for _, otherTab in pairs(self.Tabs) do
            if otherTab.Content then
                otherTab.Content.Visible = false
            end
            if otherTab.Button then
                otherTab.Button.TextColor3 = currentTheme.TextSecondary
                otherTab.Button.BackgroundColor3 = currentTheme.Surface
            end
        end

        -- Show this tab
        TabContent.Visible = true
        TabButton.TextColor3 = currentTheme.Text
        TabButton.BackgroundColor3 = currentTheme.Primary
    end)

    Tab.Button = TabButton
    Tab.Content = TabContent

    table.insert(self.Tabs, Tab)

    -- Auto-select first tab
    if #self.Tabs == 1 then
        TabContent.Visible = true
        TabButton.TextColor3 = currentTheme.Text
        TabButton.BackgroundColor3 = currentTheme.Primary
    end

    self:_updateCanvasSize()

    return Tab
end

function Window:_updateCanvasSize()
    self.TabContent.CanvasSize = UDim2.new(0, 0, 0, self.TabContent.AbsoluteContentSize.Y)
end

function Window:Show()
    if not self.Visible then
        self.Visible = true
        self.ScreenGui.Enabled = true

        -- Animate appearance
        self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
        self.MainFrame:TweenSize(
            self.Size,
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Back,
            0.3,
            true
        )
    end
end

function Window:Hide()
    if self.Visible then
        self.Visible = false
        self.ScreenGui.Enabled = false
    end
end

function Window:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

--[[
    Library Functions
]]
function AdvancedUILib:CreateWindow(config)
    local window = Window.new(config)
    table.insert(windows, window)
    return window
end

function AdvancedUILib:SetTheme(themeName)
    if THEMES[themeName] then
        currentTheme = THEMES[themeName]
        return true
    end
    return false
end

function AdvancedUILib:GetTheme()
    return currentTheme
end

function AdvancedUILib:Notify(config)
    warn("Notification: " .. (config.Title or "") .. " - " .. (config.Content or ""))
end

function AdvancedUILib:GetPerformanceMetrics()
    return {
        FPS = workspace:GetRealFPS(),
        MemoryUsage = collectgarbage("count"),
        ActiveComponents = #windows
    }
end

function AdvancedUILib:EnableAnalytics(config)
    warn("Analytics enabled (simplified version)")
end

return AdvancedUILib