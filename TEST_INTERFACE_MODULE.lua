--[[
    Test Server Interface Module
    Complete GUI system for legitimate testing and development

    USAGE:
    1. Create Folder in ReplicatedStorage named "TestGUI"
    2. Create ModuleScript inside named "TestInterface"
    3. Copy this entire script into that ModuleScript
    4. Use EXECUTOR_INTERFACE.lua to run the interface

    FOR EDUCATIONAL AND TESTING PURPOSES ONLY
--]]

local TestInterface = {}
TestInterface.__index = TestInterface

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = game:GetService("Workspace").CurrentCamera

-- State management
local currentScript = ""
local scriptHistory = {}
local outputCallback = nil
local autoScroll = true
local flyEnabled = false
local noClipEnabled = false
local godModeEnabled = false
local infiniteJumpEnabled = false
local freeCameraEnabled = false

-- Theme definitions
local THEMES = {
    Dark = {
        Background = Color3.new(0.05, 0.05, 0.05),
        Surface = Color3.new(0.1, 0.1, 0.1),
        Primary = Color3.new(0.2, 0.4, 0.8),
        Secondary = Color3.new(0.15, 0.15, 0.15),
        Text = Color3.new(1, 1, 1),
        TextSecondary = Color3.new(0.7, 0.7, 0.7),
        Border = Color3.new(0.3, 0.3, 0.3),
        Success = Color3.new(0.1, 0.8, 0.1),
        Warning = Color3.new(0.8, 0.6, 0.1),
        Error = Color3.new(0.8, 0.1, 0.1),
        Console = Color3.new(0, 0, 0),
        ConsoleText = Color3.new(0, 1, 0)
    },
    Executor = {
        Background = Color3.new(0.02, 0.02, 0.02),
        Surface = Color3.new(0.08, 0.08, 0.08),
        Primary = Color3.new(0.1, 0.6, 1),
        Secondary = Color3.new(0.15, 0.15, 0.15),
        Text = Color3.new(0.9, 0.9, 0.9),
        TextSecondary = Color3.new(0.6, 0.6, 0.6),
        Border = Color3.new(0.2, 0.2, 0.2),
        Success = Color3.new(0, 0.8, 0.4),
        Warning = Color3.new(1, 0.7, 0),
        Error = Color3.new(0.9, 0.2, 0.2),
        Console = Color3.new(0, 0, 0),
        ConsoleText = Color3.new(0, 1, 0.5)
    }
}

local currentTheme = THEMES.Executor
local windows = {}

--[[
    Enhanced Window Class with Advanced Features
]]
local Window = {}
Window.__index = Window

function Window.new(config)
    local self = setmetatable({}, Window)

    self.Name = config.Name or "Window"
    self.Theme = THEMES[config.Theme] or currentTheme
    self.Size = config.Size or UDim2.new(0, 400, 0, 300)
    self.Position = config.Position or UDim2.new(0.5, -200, 0.5, -150)
    self.Visible = false
    self.Tabs = {}
    self.ConfigName = config.ConfigName
    self.SaveConfig = config.SaveConfig or false

    self:_createGui()
    self:_loadConfig()
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
    self.MainFrame.BackgroundColor3 = self.Theme.Background
    self.MainFrame.BorderSizePixel = 1
    self.MainFrame.BorderColor3 = self.Theme.Border
    self.MainFrame.Parent = self.ScreenGui

    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = self.MainFrame

    -- Create title bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.Size = UDim2.new(1, 0, 0, 35)
    self.TitleBar.Position = UDim2.new(0, 0, 0, 0)
    self.TitleBar.BackgroundColor3 = self.Theme.Surface
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.MainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 6)
    titleCorner.Parent = self.TitleBar

    -- Create title label
    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Name = "TitleLabel"
    self.TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = Enum.Font.Code
    self.TitleLabel.Text = self.Name
    self.TitleLabel.TextColor3 = self.Theme.Text
    self.TitleLabel.TextSize = 14
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.Parent = self.TitleBar

    -- Create minimize button
    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Name = "MinimizeButton"
    self.MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
    self.MinimizeButton.Position = UDim2.new(1, -55, 0, 5)
    self.MinimizeButton.BackgroundColor3 = self.Theme.Warning
    self.MinimizeButton.BorderSizePixel = 0
    self.MinimizeButton.Font = Enum.Font.Code
    self.MinimizeButton.Text = "_"
    self.MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
    self.MinimizeButton.TextSize = 14
    self.MinimizeButton.Parent = self.TitleBar

    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 3)
    minimizeCorner.Parent = self.MinimizeButton

    -- Create close button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Name = "CloseButton"
    self.CloseButton.Size = UDim2.new(0, 25, 0, 25)
    self.CloseButton.Position = UDim2.new(1, -28, 0, 5)
    self.CloseButton.BackgroundColor3 = self.Theme.Error
    self.CloseButton.BorderSizePixel = 0
    self.CloseButton.Font = Enum.Font.Code
    self.CloseButton.Text = "×"
    self.CloseButton.TextColor3 = Color3.new(1, 1, 1)
    self.CloseButton.TextSize = 16
    self.CloseButton.Parent = self.TitleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 3)
    closeCorner.Parent = self.CloseButton

    -- Create content area
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Name = "ContentArea"
    self.ContentArea.Size = UDim2.new(1, -16, 1, -51)
    self.ContentArea.Position = UDim2.new(0, 8, 0, 43)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.MainFrame

    -- Create tab container
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.Size = UDim2.new(1, 0, 0, 35)
    self.TabContainer.Position = UDim2.new(0, 0, 0, 0)
    self.TabContainer.BackgroundColor3 = self.Theme.Surface
    self.TabContainer.BorderSizePixel = 0
    self.TabContainer.Parent = self.ContentArea

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 4)
    tabCorner.Parent = self.TabContainer

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = self.TabContainer

    -- Create tab content area
    self.TabContent = Instance.new("ScrollingFrame")
    self.TabContent.Name = "TabContent"
    self.TabContent.Size = UDim2.new(1, 0, 1, -35)
    self.TabContent.Position = UDim2.new(0, 0, 0, 35)
    self.TabContent.BackgroundTransparency = 1
    self.TabContent.BorderSizePixel = 0
    self.TabContent.ScrollBarThickness = 8
    self.TabContent.ScrollBarImageColor3 = self.Theme.Border
    self.TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabContent.Parent = self.ContentArea

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 6)
    contentLayout.Parent = self.TabContent

    -- Setup interactions
    self:_setupInteractions()
end

function Window:_setupInteractions()
    -- Window dragging
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
            self:_saveConfig()
        end
    end)

    -- Button interactions
    self.CloseButton.MouseButton1Click:Connect(function()
        self:Hide()
    end)

    self.MinimizeButton.MouseButton1Click:Connect(function()
        self:Minimize()
    end)

    -- Hover effects
    self.CloseButton.MouseEnter:Connect(function()
        self.CloseButton.BackgroundColor3 = Color3.new(1, 0.2, 0.2)
    end)

    self.CloseButton.MouseLeave:Connect(function()
        self.CloseButton.BackgroundColor3 = self.Theme.Error
    end)

    self.MinimizeButton.MouseEnter:Connect(function()
        self.MinimizeButton.BackgroundColor3 = Color3.new(1, 0.9, 0)
    end)

    self.MinimizeButton.MouseLeave:Connect(function()
        self.MinimizeButton.BackgroundColor3 = self.Theme.Warning
    end)
end

function Window:CreateTab(config)
    local Tab = {}
    Tab.Name = config.Name or "Tab"
    Tab.Icon = config.Icon
    Tab.Components = {}

    -- Create tab button
    local TabButton = Instance.new("TextButton")
    TabButton.Name = Tab.Name .. "Tab"
    TabButton.Size = UDim2.new(0, 80, 1, 0)
    TabButton.BackgroundColor3 = self.Theme.Surface
    TabButton.BorderSizePixel = 0
    TabButton.Font = Enum.Font.Code
    TabButton.Text = Tab.Name
    TabButton.TextColor3 = self.Theme.TextSecondary
    TabButton.TextSize = 12
    TabButton.Parent = self.TabContainer

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 4)
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

    -- Section creation
    function Tab:CreateSection(config)
        local Section = {}
        Section.Name = config.Name or "Section"
        Section.Components = {}

        -- Create section frame
        local SectionFrame = Instance.new("Frame")
        SectionFrame.Name = Section.Name .. "Section"
        SectionFrame.Size = UDim2.new(1, 0, 0, 0)
        SectionFrame.BackgroundColor3 = self.Theme.Surface
        SectionFrame.BorderSizePixel = 0
        SectionFrame.Parent = TabContent

        local sectionCorner = Instance.new("UICorner")
        sectionCorner.CornerRadius = UDim.new(0, 4)
        sectionCorner.Parent = SectionFrame

        -- Create section header
        local SectionHeader = Instance.new("Frame")
        SectionHeader.Name = "Header"
        SectionHeader.Size = UDim2.new(1, 0, 0, 30)
        SectionHeader.Position = UDim2.new(0, 0, 0, 0)
        SectionHeader.BackgroundColor3 = self.Theme.Primary
        SectionHeader.BorderSizePixel = 0
        SectionHeader.Parent = SectionFrame

        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 4)
        headerCorner.Parent = SectionHeader

        -- Section title
        local SectionTitle = Instance.new("TextLabel")
        SectionTitle.Name = "Title"
        SectionTitle.Size = UDim2.new(1, -40, 1, 0)
        SectionTitle.Position = UDim2.new(0, 10, 0, 0)
        SectionTitle.BackgroundTransparency = 1
        SectionTitle.Font = Enum.Font.Code
        SectionTitle.Text = Section.Name
        SectionTitle.TextColor3 = Color3.new(1, 1, 1)
        SectionTitle.TextSize = 12
        SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        SectionTitle.Parent = SectionHeader

        -- Section content
        local SectionContent = Instance.new("Frame")
        SectionContent.Name = "Content"
        SectionContent.Size = UDim2.new(1, -16, 0, 0)
        SectionContent.Position = UDim2.new(0, 8, 0, 35)
        SectionContent.BackgroundTransparency = 1
        SectionContent.Parent = SectionFrame

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 6)
        contentLayout.Parent = SectionContent

        -- Component creation methods
        function Section:CreateButton(config)
            local button = Instance.new("TextButton")
            button.Name = config.Name or "Button"
            button.Size = UDim2.new(1, 0, 0, 25)
            button.BackgroundColor3 = config.Style == "Success" and self.Theme.Success or
                                       config.Style == "Error" and self.Theme.Error or
                                       config.Style == "Warning" and self.Theme.Warning or
                                       self.Theme.Primary
            button.BorderSizePixel = 0
            button.Font = Enum.Font.Code
            button.Text = config.Name or "Button"
            button.TextColor3 = Color3.new(1, 1, 1)
            button.TextSize = 11
            button.Parent = SectionContent

            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 3)
            buttonCorner.Parent = button

            button.MouseButton1Click:Connect(config.Callback or function() end)

            -- Hover effect
            button.MouseEnter:Connect(function()
                button.BackgroundColor3 = button.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.2)
            end)

            button.MouseLeave:Connect(function()
                button.BackgroundColor3 = config.Style == "Success" and self.Theme.Success or
                                           config.Style == "Error" and self.Theme.Error or
                                           config.Style == "Warning" and self.Theme.Warning or
                                           self.Theme.Primary
            end)

            self:_updateSize()

            local ButtonComponent = {
                SetValue = function() end,
                GetValue = function() return true end
            }

            table.insert(Section.Components, ButtonComponent)
            return ButtonComponent
        end

        function Section:CreateToggle(config)
            local toggle = Instance.new("Frame")
            toggle.Name = config.Name or "Toggle"
            toggle.Size = UDim2.new(1, 0, 0, 25)
            toggle.BackgroundColor3 = self.Theme.Background
            toggle.BorderSizePixel = 0
            toggle.Parent = SectionContent

            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 3)
            toggleCorner.Parent = toggle

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -50, 1, 0)
            label.Position = UDim2.new(0, 8, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Code
            label.Text = config.Name or "Toggle"
            label.TextColor3 = self.Theme.Text
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = toggle

            local toggleButton = Instance.new("TextButton")
            toggleButton.Size = UDim2.new(0, 35, 0, 18)
            toggleButton.Position = UDim2.new(1, -40, 0, 3.5)
            toggleButton.BackgroundColor3 = config.Default and self.Theme.Success or self.Theme.Border
            toggleButton.BorderSizePixel = 0
            toggleButton.Font = Enum.Font.Code
            toggleButton.Text = config.Default and "✓" or ""
            toggleButton.TextColor3 = Color3.new(1, 1, 1)
            toggleButton.TextSize = 10
            toggleButton.Parent = toggle

            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 9)
            buttonCorner.Parent = toggleButton

            local state = config.Default or false

            toggleButton.MouseButton1Click:Connect(function()
                state = not state
                toggleButton.BackgroundColor3 = state and self.Theme.Success or self.Theme.Border
                toggleButton.Text = state and "✓" or ""

                if config.Callback then
                    config.Callback(state)
                end
            end)

            self:_updateSize()

            local ToggleComponent = {
                SetValue = function(value)
                    state = value
                    toggleButton.BackgroundColor3 = state and self.Theme.Success or self.Theme.Border
                    toggleButton.Text = state and "✓" or ""
                end,
                GetValue = function() return state end
            }

            table.insert(Section.Components, ToggleComponent)
            return ToggleComponent
        end

        function Section:CreateSlider(config)
            local slider = Instance.new("Frame")
            slider.Name = config.Name or "Slider"
            slider.Size = UDim2.new(1, 0, 0, 40)
            slider.BackgroundColor3 = self.Theme.Background
            slider.BorderSizePixel = 0
            slider.Parent = SectionContent

            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 3)
            sliderCorner.Parent = slider

            -- Label
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -80, 0, 15)
            label.Position = UDim2.new(0, 8, 0, 2)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Code
            label.Text = config.Name or "Slider"
            label.TextColor3 = self.Theme.Text
            label.TextSize = 10
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = slider

            -- Value display
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0, 70, 0, 15)
            valueLabel.Position = UDim2.new(1, -75, 0, 2)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Font = Enum.Font.Code
            valueLabel.Text = config.ValueDisplay and string.format(config.ValueDisplay, config.Default) or tostring(config.Default)
            valueLabel.TextColor3 = self.Theme.TextSecondary
            valueLabel.TextSize = 10
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = slider

            -- Slider track
            local track = Instance.new("Frame")
            track.Name = "Track"
            track.Size = UDim2.new(1, -16, 0, 4)
            track.Position = UDim2.new(0, 8, 0, 25)
            track.BackgroundColor3 = self.Theme.Border
            track.BorderSizePixel = 0
            track.Parent = slider

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(0, 2)
            trackCorner.Parent = track

            -- Slider fill
            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.Size = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), 0, 1, 0)
            fill.Position = UDim2.new(0, 0, 0, 0)
            fill.BackgroundColor3 = self.Theme.Primary
            fill.BorderSizePixel = 0
            fill.Parent = track

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 2)
            fillCorner.Parent = fill

            -- Slider handle
            local handle = Instance.new("TextButton")
            handle.Name = "Handle"
            handle.Size = UDim2.new(0, 12, 0, 12)
            handle.Position = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), -6, 0.5, -6)
            handle.BackgroundColor3 = Color3.new(1, 1, 1)
            handle.BorderSizePixel = 0
            handle.Font = Enum.Font.Code
            handle.Text = ""
            handle.Parent = track

            local handleCorner = Instance.new("UICorner")
            handleCorner.CornerRadius = UDim.new(0, 6)
            handleCorner.Parent = handle

            local value = config.Default
            local dragging = false

            local function updateSlider(input)
                if dragging then
                    local relativePos = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                    relativePos = math.max(0, math.min(1, relativePos))

                    value = config.Min + (config.Max - config.Min) * relativePos

                    fill.Size = UDim2.new(relativePos, 0, 1, 0)
                    handle.Position = UDim2.new(relativePos, -6, 0.5, -6)

                    local displayValue = config.ValueDisplay and string.format(config.ValueDisplay, value) or tostring(value)
                    valueLabel.Text = displayValue

                    if config.Callback then
                        config.Callback(value)
                    end
                end
            end

            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)

            UserInputService.InputChanged:Connect(updateSlider)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            self:_updateSize()

            local SliderComponent = {
                SetValue = function(newValue)
                    value = math.max(config.Min, math.min(config.Max, newValue))
                    local relativePos = (value - config.Min) / (config.Max - config.Min)

                    fill.Size = UDim2.new(relativePos, 0, 1, 0)
                    handle.Position = UDim2.new(relativePos, -6, 0.5, -6)

                    local displayValue = config.ValueDisplay and string.format(config.ValueDisplay, value) or tostring(value)
                    valueLabel.Text = displayValue
                end,
                GetValue = function() return value end
            }

            table.insert(Section.Components, SliderComponent)
            return SliderComponent
        end

        function Section:CreateLabel(config)
            local label = Instance.new("TextLabel")
            label.Name = config.Name or "Label"
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundColor3 = self.Theme.Background
            label.BorderSizePixel = 0
            label.Font = Enum.Font.Code
            label.Text = config.Name or "Label"
            label.TextColor3 = self.Theme.Text
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = SectionContent

            local labelCorner = Instance.new("UICorner")
            labelCorner.CornerRadius = UDim.new(0, 3)
            labelCorner.Parent = label

            self:_updateSize()

            local LabelComponent = {
                SetValue = function(newValue)
                    label.Text = newValue
                end,
                GetValue = function() return label.Text end
            }

            table.insert(Section.Components, LabelComponent)
            return LabelComponent
        end

        function Section:CreateTextBox(config)
            local textBox = Instance.new("Frame")
            textBox.Name = config.Name or "TextBox"
            textBox.Size = UDim2.new(1, 0, 0, config.Height or 100)
            textBox.BackgroundColor3 = self.Theme.Background
            textBox.BorderSizePixel = 0
            textBox.Parent = SectionContent

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 3)
            boxCorner.Parent = textBox

            -- Label
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 15)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Code
            label.Text = config.Name or "TextBox"
            label.TextColor3 = self.Theme.Text
            label.TextSize = 10
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = textBox

            -- Text input
            local input = Instance.new("TextBox")
            input.Size = UDim2.new(1, -4, 1, -20)
            input.Position = UDim2.new(0, 2, 0, 18)
            input.BackgroundColor3 = self.Theme.Console
            input.BorderSizePixel = 0
            input.Font = Enum.Font.Code
            input.PlaceholderText = config.Placeholder or ""
            input.Text = ""
            input.TextColor3 = self.Theme.ConsoleText
            input.TextSize = 10
            input.TextXAlignment = Enum.TextXAlignment.Left
            input.TextYAlignment = Enum.TextYAlignment.Top
            input.MultiLine = config.Multiline or false
            input.ClearTextOnFocus = false
            input.Parent = textBox

            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 3)
            inputCorner.Parent = input

            input.FocusLost:Connect(function()
                if config.Callback then
                    config.Callback(input.Text)
                end
            end)

            self:_updateSize()

            local TextBoxComponent = {
                SetValue = function(value)
                    input.Text = value
                end,
                GetValue = function() return input.Text end
            }

            table.insert(Section.Components, TextBoxComponent)
            return TextBoxComponent
        end

        function Section:CreateDropdown(config)
            local dropdown = Instance.new("TextButton")
            dropdown.Name = config.Name or "Dropdown"
            dropdown.Size = UDim2.new(1, 0, 0, 25)
            dropdown.BackgroundColor3 = self.Theme.Background
            dropdown.BorderSizePixel = 0
            dropdown.Font = Enum.Font.Code
            dropdown.Text = config.Name or "Dropdown"
            dropdown.TextColor3 = self.Theme.Text
            dropdown.TextSize = 11
            dropdown.TextXAlignment = Enum.TextXAlignment.Left
            dropdown.Parent = SectionContent

            local dropdownCorner = Instance.new("UICorner")
            dropdownCorner.CornerRadius = UDim.new(0, 3)
            dropdownCorner.Parent = dropdown

            local selectedIndex = 1

            dropdown.MouseButton1Click:Connect(function()
                -- Simple cycling through options
                selectedIndex = (selectedIndex % #config.Options) + 1
                dropdown.Text = config.Name .. ": " .. config.Options[selectedIndex]

                if config.Callback then
                    config.Callback(config.Options[selectedIndex])
                end
            end)

            self:_updateSize()

            local DropdownComponent = {
                SetValue = function(value)
                    for i, option in ipairs(config.Options) do
                        if option == value then
                            selectedIndex = i
                            dropdown.Text = config.Name .. ": " .. option
                            break
                        end
                    end
                end,
                GetValue = function() return config.Options[selectedIndex] end
            }

            table.insert(Section.Components, DropdownComponent)
            return DropdownComponent
        end

        function Section:_updateSize()
            local contentSize = SectionContent.AbsoluteContentSize
            SectionFrame.Size = UDim2.new(1, 0, 0, contentSize.Y + 35)
            Tab:_updateSize()
        end

        table.insert(Tab.Sections, Section)
        Tab:_updateSize()

        return Section
    end

    function Tab:_updateSize()
        local totalSize = 0
        for _, section in pairs(self.Sections or {}) do
            totalSize = totalSize + section.Frame.AbsoluteSize.Y + 8
        end
        TabContent.Size = UDim2.new(1, 0, 0, totalSize)
        self:_updateCanvasSize()
    end

    function Tab:_updateCanvasSize()
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
                otherTab.Button.TextColor3 = self.Theme.TextSecondary
                otherTab.Button.BackgroundColor3 = self.Theme.Surface
            end
        end

        -- Show this tab
        TabContent.Visible = true
        TabButton.TextColor3 = self.Theme.Text
        TabButton.BackgroundColor3 = self.Theme.Primary
    end)

    Tab.Button = TabButton
    Tab.Content = TabContent
    Tab.Sections = {}

    table.insert(self.Tabs, Tab)

    -- Auto-select first tab
    if #self.Tabs == 1 then
        TabContent.Visible = true
        TabButton.TextColor3 = self.Theme.Text
        TabButton.BackgroundColor3 = self.Theme.Primary
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
        self:_saveConfig()
    end
end

function Window:Minimize()
    if self.Visible then
        self.ContentArea.Visible = false
        self.MainFrame:TweenSize(
            UDim2.new(0, 300, 0, 35),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
    end
end

function Window:_saveConfig()
    if self.SaveConfig and self.ConfigName then
        local config = {
            Position = {
                X = self.MainFrame.Position.X.Offset,
                Y = self.MainFrame.Position.Y.Offset
            },
            Size = {
                X = self.MainFrame.Size.X.Offset,
                Y = self.MainFrame.Size.Y.Offset
            }
        }

        local player = Players.LocalPlayer
        local configFolder = player:FindFirstChild("TestGUI_Configs")
        if not configFolder then
            configFolder = Instance.new("Folder")
            configFolder.Name = "TestGUI_Configs"
            configFolder.Parent = player
        end

        local configValue = configFolder:FindFirstChild(self.ConfigName)
        if not configValue then
            configValue = Instance.new("StringValue")
            configValue.Name = self.ConfigName
            configValue.Parent = configFolder
        end

        local HttpService = game:GetService("HttpService")
        configValue.Value = HttpService:JSONEncode(config)
    end
end

function Window:_loadConfig()
    if self.SaveConfig and self.ConfigName then
        local player = Players.LocalPlayer
        local configFolder = player:FindFirstChild("TestGUI_Configs")
        if configFolder then
            local configValue = configFolder:FindFirstChild(self.ConfigName)
            if configValue and configValue.Value ~= "" then
                local HttpService = game:GetService("HttpService")
                local success, config = pcall(function()
                    return HttpService:JSONDecode(configValue.Value)
                end)

                if success and config then
                    if config.Position then
                        self.MainFrame.Position = UDim2.new(0, config.Position.X, 0, config.Position.Y)
                    end
                    if config.Size then
                        self.MainFrame.Size = UDim2.new(0, config.Size.X, 0, config.Size.Y)
                    end
                end
            end
        end
    end
end

function Window:Destroy()
    if self.ScreenGui then
        self:_saveConfig()
        self.ScreenGui:Destroy()
    end
end

--[[
    Library Functions
]]
function TestInterface:CreateWindow(config)
    local window = Window.new(config)
    table.insert(windows, window)
    return window
end

function TestInterface:SetTheme(themeName)
    if THEMES[themeName] then
        currentTheme = THEMES[themeName]
        return true
    end
    return false
end

function TestInterface:GetTheme()
    return currentTheme
end

--[[
    Script Management Functions
]]
function TestInterface:SetCurrentScript(script)
    currentScript = script
end

function TestInterface:GetCurrentScript()
    return currentScript
end

function TestInterface:ExecuteScript(script)
    if not script or script == "" then
        TestInterface:Print("Error: No script to execute")
        return
    end

    TestInterface:Print("Executing script...")

    local success, error = pcall(function()
        local func = loadstring(script)
        if func then
            func()
            TestInterface:Print("Script executed successfully")
        else
            error("Failed to compile script")
        end
    end)

    if not success then
        TestInterface:Print("Script error: " .. tostring(error))
    end

    -- Add to history
    TestInterface:AddToHistory(script)
end

function TestInterface:ClearScript()
    currentScript = ""
    TestInterface:Print("Script cleared")
end

function TestInterface:AddToHistory(script)
    -- Remove from history if it already exists
    for i, histScript in ipairs(scriptHistory) do
        if histScript == script then
            table.remove(scriptHistory, i)
            break
        end
    end

    -- Add to beginning of history
    table.insert(scriptHistory, 1, script)

    -- Limit history to 10 scripts
    while #scriptHistory > 10 do
        table.remove(scriptHistory, #scriptHistory)
    end

    TestInterface:SaveScriptHistory()
end

function TestInterface:GetScriptFromHistory(name)
    return scriptHistory[tonumber(name)] or nil
end

function TestInterface:SaveScriptHistory()
    local player = Players.LocalPlayer
    local configFolder = player:FindFirstChild("TestGUI_Configs")
    if not configFolder then
        configFolder = Instance.new("Folder")
        configFolder.Name = "TestGUI_Configs"
        configFolder.Parent = player
    end

    local historyValue = configFolder:FindFirstChild("ScriptHistory")
    if not historyValue then
        historyValue = Instance.new("StringValue")
        historyValue.Name = "ScriptHistory"
        historyValue.Parent = configFolder
    end

    local HttpService = game:GetService("HttpService")
    historyValue.Value = HttpService:JSONEncode(scriptHistory)
end

function TestInterface:LoadScriptHistory()
    local player = Players.LocalPlayer
    local configFolder = player:FindFirstChild("TestGUI_Configs")
    if configFolder then
        local historyValue = configFolder:FindFirstChild("ScriptHistory")
        if historyValue and historyValue.Value ~= "" then
            local HttpService = game:GetService("HttpService")
            local success, history = pcall(function()
                return HttpService:JSONDecode(historyValue.Value)
            end)

            if success and history then
                scriptHistory = history
            end
        end
    end
end

function TestInterface:LoadScriptDialog()
    TestInterface:Print("Load script dialog - feature coming soon!")
end

--[[
    Player Control Functions
]]
function TestInterface:SetWalkSpeed(speed)
    local player = Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = speed
        TestInterface:Print("Walk speed set to: " .. speed)
    end
end

function TestInterface:SetJumpPower(power)
    local player = Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.JumpPower = power
        TestInterface:Print("Jump power set to: " .. power)
    end
end

function TestInterface:SetHealth(health)
    local player = Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = health
        TestInterface:Print("Health set to: " .. health)
    end
end

function TestInterface:SetGodMode(enabled)
    godModeEnabled = enabled
    local player = Players.LocalPlayer

    if enabled then
        -- Start god mode loop
        spawn(function()
            while godModeEnabled do
                wait(0.1)
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
                end
            end
        end)
        TestInterface:Print("God mode enabled")
    else
        TestInterface:Print("God mode disabled")
    end
end

function TestInterface:SetInfiniteJump(enabled)
    infiniteJumpEnabled = enabled
    local player = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")

    if enabled then
        local connection
        connection = UserInputService.JumpRequest:Connect(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)

        player:SetAttribute("InfiniteJumpConnection", connection)
        TestInterface:Print("Infinite jump enabled")
    else
        local connection = player:GetAttribute("InfiniteJumpConnection")
        if connection then
            connection:Disconnect()
            player:SetAttribute("InfiniteJumpConnection", nil)
        end
        TestInterface:Print("Infinite jump disabled")
    end
end

function TestInterface:SetNoClip(enabled)
    noClipEnabled = enabled
    local player = Players.LocalPlayer

    if enabled then
        -- Start no-clip loop
        spawn(function()
            while noClipEnabled do
                wait(0.1)
                if player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end

            -- Re-enable collision when turned off
            if player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end)
        TestInterface:Print("No-clip enabled")
    else
        TestInterface:Print("No-clip disabled")
    end
end

function TestInterface:SetFly(enabled)
    flyEnabled = enabled
    local player = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")

    if enabled then
        local flySpeed = 50
        local flying = false
        local bv = Instance.new("BodyVelocity")
        local bg = Instance.new("BodyGyro")

        local function startFly()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

            flying = true
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

            bv.Parent = player.Character.HumanoidRootPart
            bg.Parent = player.Character.HumanoidRootPart

            spawn(function()
                while flying do
                    wait()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local camCF = Camera.CFrame
                        local forward = camCF.lookVector
                        local up = camCF.upVector

                        local moveVector = Vector3.new(0, 0, 0)

                        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                            moveVector = moveVector + forward
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                            moveVector = moveVector - forward
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                            moveVector = moveVector - camCF.rightVector
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                            moveVector = moveVector + camCF.rightVector
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                            moveVector = moveVector + up
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                            moveVector = moveVector - up
                        end

                        if moveVector.Magnitude > 0 then
                            moveVector = moveVector.unit * flySpeed
                        end

                        bv.Velocity = moveVector
                        bg.CFrame = camCF
                    end
                end
            end)
        end

        local function stopFly()
            flying = false
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end

        UserInputService.JumpRequest:Connect(function()
            if not flying then
                startFly()
            else
                stopFly()
            end
        end)

        TestInterface:Print("Fly enabled (Press Space to toggle)")
    else
        TestInterface:Print("Fly disabled")
    end
end

function TestInterface:SetFlySpeed(speed)
    -- Update fly speed (would need to modify the fly system)
    TestInterface:Print("Fly speed set to: " .. speed)
end

function TestInterface:ResetCharacter()
    Players.LocalPlayer:LoadCharacter()
    TestInterface:Print("Character reset")
end

--[[
    World Control Functions
]]
function TestInterface:SetTimeOfDay(time)
    Lighting.ClockTime = time
    TestInterface:Print("Time of day set to: " .. string.format("%.1f:00", time))
end

function TestInterface:SetBrightness(brightness)
    Lighting.Brightness = brightness
    TestInterface:Print("Brightness set to: " .. brightness)
end

function TestInterface:SetFogEnd(fogEnd)
    Lighting.FogEnd = fogEnd
    TestInterface:Print("Fog end set to: " .. fogEnd)
end

function TestInterface:SetFieldOfView(fov)
    Camera.FieldOfView = fov
    TestInterface:Print("Field of view set to: " .. fov .. "°")
end

function TestInterface:SetFreeCamera(enabled)
    freeCameraEnabled = enabled
    -- Implementation would require more complex camera handling
    TestInterface:Print("Free camera " .. (enabled and "enabled" or "disabled"))
end

function TestInterface:ResetCamera()
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CFrame = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame
    TestInterface:Print("Camera reset")
end

--[[
    Tool Functions
]]
function TestInterface:OpenExplorer()
    TestInterface:Print("Explorer tool - feature coming soon!")
end

function TestInterface:OpenProperties()
    TestInterface:Print("Properties inspector - feature coming soon!")
end

function TestInterface:OpenRemoteSpy()
    TestInterface:Print("Remote spy - feature coming soon!")
end

function TestInterface:OpenPerformanceMonitor()
    TestInterface:Print("Performance monitor - feature coming soon!")
end

function TestInterface:ClearAllEffects()
    -- Reset all modifications
    TestInterface:SetGodMode(false)
    TestInterface:SetInfiniteJump(false)
    TestInterface:SetNoClip(false)
    TestInterface:SetFly(false)
    TestInterface:SetWalkSpeed(16)
    TestInterface:SetJumpPower(50)
    TestInterface:SetHealth(100)
    TestInterface:Print("All effects cleared")
end

function TestInterface:TeleportToSpawn()
    local player = Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
        TestInterface:Print("Teleported to spawn")
    end
end

function TestInterface:CopyCFrame()
    local player = Players.LocalPlayer
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local cframe = player.Character.HumanoidRootPart.CFrame
        -- Copy to clipboard (would need more complex implementation)
        TestInterface:Print("CFrame: " .. tostring(cframe))
    end
end

function TestInterface:PrintPlayerInfo()
    local player = Players.LocalPlayer
    local info = string.format([[
Player: %s
UserID: %d
Team: %s
Health: %d/%d
WalkSpeed: %d
JumpPower: %d
Position: %s
    ]],
        player.Name,
        player.UserId,
        player.Team and player.Team.Name or "No Team",
        player.Character and player.Character:FindFirstChild("Humanoid") and math.floor(player.Character.Humanoid.Health) or 0,
        player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.MaxHealth or 0,
        player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.WalkSpeed or 0,
        player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.JumpPower or 0,
        player.Character and player.Character:FindFirstChild("HumanoidRootPart") and tostring(player.Character.HumanoidRootPart.Position) or "N/A"
    )

    TestInterface:Print(info)
end

--[[
    Utility Functions
]]
function TestInterface:SetOutputCallback(callback)
    outputCallback = callback
end

function TestInterface:SetAutoScroll(enabled)
    autoScroll = enabled
end

function TestInterface:Print(message)
    if outputCallback then
        outputCallback(message)
    else
        print("[TestGUI] " .. message)
    end
end

function TestInterface:GetPerformanceMetrics()
    return {
        FPS = math.floor(workspace:GetRealFPS()),
        MemoryUsage = math.floor(collectgarbage("count") / 1000),
        ActiveWindows = #windows
    }
end

function TestInterface:Notify(config)
    TestInterface:Print("Notification: " .. (config.Title or "") .. " - " .. (config.Content or ""))
end

function TestInterface:EnableAnalytics(config)
    TestInterface:Print("Analytics enabled")
end

return TestInterface