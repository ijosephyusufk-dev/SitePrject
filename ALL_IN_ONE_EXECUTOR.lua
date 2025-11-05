--[[
    ALL-IN-ONE EXECUTOR INTERFACE
    Complete test server GUI in a single file - No setup required!

    INSTRUCTIONS:
    1. Create a LocalScript in StarterGui
    2. Copy this entire script into it
    3. Run the game on your test server
    4. The interface will appear automatically!

    FOR EDUCATIONAL AND TESTING PURPOSES ONLY
    Use only on your private test servers
--]]

-- ================================================
-- SERVICES AND VARIABLES
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = game:GetService("Workspace").CurrentCamera
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local currentScript = ""
local scriptHistory = {}
local autoScroll = true
local flyEnabled = false
local noClipEnabled = false
local godModeEnabled = false
local infiniteJumpEnabled = false
local freeCameraEnabled = false

-- ================================================
-- THEME DEFINITIONS
-- ================================================

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

-- ================================================
-- UTILITY FUNCTIONS
-- ================================================

local function createWindow(config)
    local window = {}
    window.Name = config.Name or "Window"
    window.Theme = config.Theme or currentTheme
    window.Size = config.Size or UDim2.new(0, 600, 0, 500)
    window.Position = config.Position or UDim2.new(0.5, -300, 0.5, -250)
    window.Visible = false
    window.Tabs = {}

    -- Create ScreenGui
    window.ScreenGui = Instance.new("ScreenGui")
    window.ScreenGui.Name = window.Name
    window.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    window.ScreenGui.IgnoreGuiInset = true
    window.ScreenGui.Parent = player:WaitForChild("PlayerGui")

    -- Create main frame
    window.MainFrame = Instance.new("Frame")
    window.MainFrame.Name = "MainFrame"
    window.MainFrame.Size = window.Size
    window.MainFrame.Position = window.Position
    window.MainFrame.BackgroundColor3 = window.Theme.Background
    window.MainFrame.BorderSizePixel = 1
    window.MainFrame.BorderColor3 = window.Theme.Border
    window.MainFrame.Parent = window.ScreenGui

    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = window.MainFrame

    -- Create title bar
    window.TitleBar = Instance.new("Frame")
    window.TitleBar.Name = "TitleBar"
    window.TitleBar.Size = UDim2.new(1, 0, 0, 35)
    window.TitleBar.Position = UDim2.new(0, 0, 0, 0)
    window.TitleBar.BackgroundColor3 = window.Theme.Surface
    window.TitleBar.BorderSizePixel = 0
    window.TitleBar.Parent = window.MainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 6)
    titleCorner.Parent = window.TitleBar

    -- Create title label
    window.TitleLabel = Instance.new("TextLabel")
    window.TitleLabel.Name = "TitleLabel"
    window.TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    window.TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    window.TitleLabel.BackgroundTransparency = 1
    window.TitleLabel.Font = Enum.Font.Code
    window.TitleLabel.Text = window.Name
    window.TitleLabel.TextColor3 = window.Theme.Text
    window.TitleLabel.TextSize = 14
    window.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    window.TitleLabel.Parent = window.TitleBar

    -- Create close button
    window.CloseButton = Instance.new("TextButton")
    window.CloseButton.Name = "CloseButton"
    window.CloseButton.Size = UDim2.new(0, 25, 0, 25)
    window.CloseButton.Position = UDim2.new(1, -30, 0, 5)
    window.CloseButton.BackgroundColor3 = window.Theme.Error
    window.CloseButton.BorderSizePixel = 0
    window.CloseButton.Font = Enum.Font.Code
    window.CloseButton.Text = "×"
    window.CloseButton.TextColor3 = Color3.new(1, 1, 1)
    window.CloseButton.TextSize = 16
    window.CloseButton.Parent = window.TitleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 3)
    closeCorner.Parent = window.CloseButton

    -- Create content area
    window.ContentArea = Instance.new("Frame")
    window.ContentArea.Name = "ContentArea"
    window.ContentArea.Size = UDim2.new(1, -16, 1, -51)
    window.ContentArea.Position = UDim2.new(0, 8, 0, 43)
    window.ContentArea.BackgroundTransparency = 1
    window.ContentArea.Parent = window.MainFrame

    -- Create tab container
    window.TabContainer = Instance.new("Frame")
    window.TabContainer.Name = "TabContainer"
    window.TabContainer.Size = UDim2.new(1, 0, 0, 35)
    window.TabContainer.Position = UDim2.new(0, 0, 0, 0)
    window.TabContainer.BackgroundColor3 = window.Theme.Surface
    window.TabContainer.BorderSizePixel = 0
    window.TabContainer.Parent = window.ContentArea

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 4)
    tabCorner.Parent = window.TabContainer

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = window.TabContainer

    -- Create tab content area
    window.TabContent = Instance.new("ScrollingFrame")
    window.TabContent.Name = "TabContent"
    window.TabContent.Size = UDim2.new(1, 0, 1, -35)
    window.TabContent.Position = UDim2.new(0, 0, 0, 35)
    window.TabContent.BackgroundTransparency = 1
    window.TabContent.BorderSizePixel = 0
    window.TabContent.ScrollBarThickness = 8
    window.TabContent.ScrollBarImageColor3 = window.Theme.Border
    window.TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    window.TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    window.TabContent.Parent = window.ContentArea

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 6)
    contentLayout.Parent = window.TabContent

    -- Setup dragging
    local dragging = false
    local dragStart = nil
    local startPos = nil

    window.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.MainFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.MainFrame.Position = UDim2.new(
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

    -- Close button
    window.CloseButton.MouseButton1Click:Connect(function()
        window:Hide()
    end)

    -- Close button hover effect
    window.CloseButton.MouseEnter:Connect(function()
        window.CloseButton.BackgroundColor3 = Color3.new(1, 0.2, 0.2)
    end)

    window.CloseButton.MouseLeave:Connect(function()
        window.CloseButton.BackgroundColor3 = window.Theme.Error
    end)

    -- Tab creation function
    function window:CreateTab(config)
        local tab = {}
        tab.Name = config.Name or "Tab"
        tab.Components = {}

        -- Create tab button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tab.Name .. "Tab"
        TabButton.Size = UDim2.new(0, 80, 1, 0)
        TabButton.BackgroundColor3 = window.Theme.Surface
        TabButton.BorderSizePixel = 0
        TabButton.Font = Enum.Font.Code
        TabButton.Text = tab.Name
        TabButton.TextColor3 = window.Theme.TextSecondary
        TabButton.TextSize = 12
        TabButton.Parent = window.TabContainer

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 4)
        tabCorner.Parent = TabButton

        -- Create tab content
        local TabContent = Instance.new("Frame")
        TabContent.Name = tab.Name .. "Content"
        TabContent.Size = UDim2.new(1, 0, 0, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Visible = false
        TabContent.Parent = window.TabContent

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0, 8)
        contentLayout.Parent = TabContent

        -- Section creation
        function tab:CreateSection(config)
            local section = {}
            section.Name = config.Name or "Section"
            section.Components = {}

            -- Create section frame
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = section.Name .. "Section"
            SectionFrame.Size = UDim2.new(1, 0, 0, 0)
            SectionFrame.BackgroundColor3 = window.Theme.Surface
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
            SectionHeader.BackgroundColor3 = window.Theme.Primary
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
            SectionTitle.Text = section.Name
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
            function section:CreateButton(config)
                local button = Instance.new("TextButton")
                button.Name = config.Name or "Button"
                button.Size = UDim2.new(1, 0, 0, 25)
                button.BackgroundColor3 = config.Style == "Success" and window.Theme.Success or
                                           config.Style == "Error" and window.Theme.Error or
                                           config.Style == "Warning" and window.Theme.Warning or
                                           window.Theme.Primary
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
                    button.BackgroundColor3 = config.Style == "Success" and window.Theme.Success or
                                               config.Style == "Error" and window.Theme.Error or
                                               config.Style == "Warning" and window.Theme.Warning or
                                               window.Theme.Primary
                end)

                section:_updateSize()

                local ButtonComponent = {
                    SetValue = function() end,
                    GetValue = function() return true end
                }

                table.insert(section.Components, ButtonComponent)
                return ButtonComponent
            end

            function section:CreateToggle(config)
                local toggle = Instance.new("Frame")
                toggle.Name = config.Name or "Toggle"
                toggle.Size = UDim2.new(1, 0, 0, 25)
                toggle.BackgroundColor3 = window.Theme.Background
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
                label.TextColor3 = window.Theme.Text
                label.TextSize = 11
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = toggle

                local toggleButton = Instance.new("TextButton")
                toggleButton.Size = UDim2.new(0, 35, 0, 18)
                toggleButton.Position = UDim2.new(1, -40, 0, 3.5)
                toggleButton.BackgroundColor3 = config.Default and window.Theme.Success or window.Theme.Border
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
                    toggleButton.BackgroundColor3 = state and window.Theme.Success or window.Theme.Border
                    toggleButton.Text = state and "✓" or ""

                    if config.Callback then
                        config.Callback(state)
                    end
                end)

                section:_updateSize()

                local ToggleComponent = {
                    SetValue = function(value)
                        state = value
                        toggleButton.BackgroundColor3 = state and window.Theme.Success or window.Theme.Border
                        toggleButton.Text = state and "✓" or ""
                    end,
                    GetValue = function() return state end
                }

                table.insert(section.Components, ToggleComponent)
                return ToggleComponent
            end

            function section:CreateSlider(config)
                local slider = Instance.new("Frame")
                slider.Name = config.Name or "Slider"
                slider.Size = UDim2.new(1, 0, 0, 40)
                slider.BackgroundColor3 = window.Theme.Background
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
                label.TextColor3 = window.Theme.Text
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
                valueLabel.TextColor3 = window.Theme.TextSecondary
                valueLabel.TextSize = 10
                valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                valueLabel.Parent = slider

                -- Slider track
                local track = Instance.new("Frame")
                track.Name = "Track"
                track.Size = UDim2.new(1, -16, 0, 4)
                track.Position = UDim2.new(0, 8, 0, 25)
                track.BackgroundColor3 = window.Theme.Border
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
                fill.BackgroundColor3 = window.Theme.Primary
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

                section:_updateSize()

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

                table.insert(section.Components, SliderComponent)
                return SliderComponent
            end

            function section:CreateLabel(config)
                local label = Instance.new("TextLabel")
                label.Name = config.Name or "Label"
                label.Size = UDim2.new(1, 0, 0, 20)
                label.BackgroundColor3 = window.Theme.Background
                label.BorderSizePixel = 0
                label.Font = Enum.Font.Code
                label.Text = config.Name or "Label"
                label.TextColor3 = window.Theme.Text
                label.TextSize = 11
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = SectionContent

                local labelCorner = Instance.new("UICorner")
                labelCorner.CornerRadius = UDim.new(0, 3)
                labelCorner.Parent = label

                section:_updateSize()

                local LabelComponent = {
                    SetValue = function(newValue)
                        label.Text = newValue
                    end,
                    GetValue = function() return label.Text end
                }

                table.insert(section.Components, LabelComponent)
                return LabelComponent
            end

            function section:CreateTextBox(config)
                local textBox = Instance.new("Frame")
                textBox.Name = config.Name or "TextBox"
                textBox.Size = UDim2.new(1, 0, 0, config.Height or 100)
                textBox.BackgroundColor3 = window.Theme.Background
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
                label.TextColor3 = window.Theme.Text
                label.TextSize = 10
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = textBox

                -- Text input
                local input = Instance.new("TextBox")
                input.Size = UDim2.new(1, -4, 1, -20)
                input.Position = UDim2.new(0, 2, 0, 18)
                input.BackgroundColor3 = window.Theme.Console
                input.BorderSizePixel = 0
                input.Font = Enum.Font.Code
                input.PlaceholderText = config.Placeholder or ""
                input.Text = ""
                input.TextColor3 = window.Theme.ConsoleText
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

                section:_updateSize()

                local TextBoxComponent = {
                    SetValue = function(value)
                        input.Text = value
                    end,
                    GetValue = function() return input.Text end
                }

                table.insert(section.Components, TextBoxComponent)
                return TextBoxComponent
            end

            function section:_updateSize()
                local contentSize = SectionContent.AbsoluteContentSize
                SectionFrame.Size = UDim2.new(1, 0, 0, contentSize.Y + 35)
                tab:_updateSize()
            end

            table.insert(tab.Sections, section)
            tab:_updateSize()

            return section
        end

        function tab:_updateSize()
            local totalSize = 0
            for _, section in pairs(self.Sections or {}) do
                totalSize = totalSize + section.Frame.AbsoluteSize.Y + 8
            end
            TabContent.Size = UDim2.new(1, 0, 0, totalSize)
            self:_updateCanvasSize()
        end

        function tab:_updateCanvasSize()
            window.TabContent.CanvasSize = UDim2.new(0, 0, 0, window.TabContent.AbsoluteContentSize.Y)
        end

        -- Tab switching
        TabButton.MouseButton1Click:Connect(function()
            -- Hide all other tabs
            for _, otherTab in pairs(window.Tabs) do
                if otherTab.Content then
                    otherTab.Content.Visible = false
                end
                if otherTab.Button then
                    otherTab.Button.TextColor3 = window.Theme.TextSecondary
                    otherTab.Button.BackgroundColor3 = window.Theme.Surface
                end
            end

            -- Show this tab
            TabContent.Visible = true
            TabButton.TextColor3 = window.Theme.Text
            TabButton.BackgroundColor3 = window.Theme.Primary
        end)

        tab.Button = TabButton
        tab.Content = TabContent
        tab.Sections = {}

        table.insert(window.Tabs, tab)

        -- Auto-select first tab
        if #window.Tabs == 1 then
            TabContent.Visible = true
            TabButton.TextColor3 = window.Theme.Text
            TabButton.BackgroundColor3 = window.Theme.Primary
        end

        window:_updateCanvasSize()

        return tab
    end

    function window:_updateCanvasSize()
        window.TabContent.CanvasSize = UDim2.new(0, 0, 0, window.TabContent.AbsoluteContentSize.Y)
    end

    function window:Show()
        if not window.Visible then
            window.Visible = true
            window.ScreenGui.Enabled = true

            -- Animate appearance
            window.MainFrame.Size = UDim2.new(0, 0, 0, 0)
            window.MainFrame:TweenSize(
                window.Size,
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Back,
                0.3,
                true
            )
        end
    end

    function window:Hide()
        if window.Visible then
            window.Visible = false
            window.ScreenGui.Enabled = false
        end
    end

    return window
end

-- ================================================
-- EXECUTOR FUNCTIONS
-- ================================================

local function executeScript(script)
    if not script or script == "" then
        print("[Executor] Error: No script to execute")
        return
    end

    print("[Executor] Executing script...")

    local success, error = pcall(function()
        local func = loadstring(script)
        if func then
            func()
            print("[Executor] Script executed successfully")
        else
            error("Failed to compile script")
        end
    end)

    if not success then
        print("[Executor] Script error: " .. tostring(error))
    end

    -- Add to history
    for i, histScript in ipairs(scriptHistory) do
        if histScript == script then
            table.remove(scriptHistory, i)
            break
        end
    end

    table.insert(scriptHistory, 1, script)

    while #scriptHistory > 10 do
        table.remove(scriptHistory, #scriptHistory)
    end
end

local function setWalkSpeed(speed)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = speed
        print("[Executor] Walk speed set to: " .. speed)
    end
end

local function setJumpPower(power)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.JumpPower = power
        print("[Executor] Jump power set to: " .. power)
    end
end

local function setHealth(health)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = health
        print("[Executor] Health set to: " .. health)
    end
end

local function setGodMode(enabled)
    godModeEnabled = enabled

    if enabled then
        spawn(function()
            while godModeEnabled do
                wait(0.1)
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
                end
            end
        end)
        print("[Executor] God mode enabled")
    else
        print("[Executor] God mode disabled")
    end
end

local function setInfiniteJump(enabled)
    infiniteJumpEnabled = enabled

    if enabled then
        local connection
        connection = UserInputService.JumpRequest:Connect(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)

        player:SetAttribute("InfiniteJumpConnection", connection)
        print("[Executor] Infinite jump enabled")
    else
        local connection = player:GetAttribute("InfiniteJumpConnection")
        if connection then
            connection:Disconnect()
            player:SetAttribute("InfiniteJumpConnection", nil)
        end
        print("[Executor] Infinite jump disabled")
    end
end

local function setNoClip(enabled)
    noClipEnabled = enabled

    if enabled then
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

            if player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end)
        print("[Executor] No-clip enabled")
    else
        print("[Executor] No-clip disabled")
    end
end

local function setTimeOfDay(time)
    Lighting.ClockTime = time
    print("[Executor] Time of day set to: " .. string.format("%.1f:00", time))
end

local function setBrightness(brightness)
    Lighting.Brightness = brightness
    print("[Executor] Brightness set to: " .. brightness)
end

local function setFogEnd(fogEnd)
    Lighting.FogEnd = fogEnd
    print("[Executor] Fog end set to: " .. fogEnd)
end

local function setFieldOfView(fov)
    Camera.FieldOfView = fov
    print("[Executor] Field of view set to: " .. fov .. "°")
end

local function resetCharacter()
    player:LoadCharacter()
    print("[Executor] Character reset")
end

local function clearAllEffects()
    setGodMode(false)
    setInfiniteJump(false)
    setNoClip(false)
    setWalkSpeed(16)
    setJumpPower(50)
    setHealth(100)
    print("[Executor] All effects cleared")
end

local function teleportToSpawn()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
        print("[Executor] Teleported to spawn")
    end
end

local function printPlayerInfo()
    local info = string.format([[
Player: %s
UserID: %d
Health: %d/%d
WalkSpeed: %d
JumpPower: %d
Position: %s
    ]],
        player.Name,
        player.UserId,
        player.Character and player.Character:FindFirstChild("Humanoid") and math.floor(player.Character.Humanoid.Health) or 0,
        player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.MaxHealth or 0,
        player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.WalkSpeed or 0,
        player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.JumpPower or 0,
        player.Character and player.Character:FindFirstChild("HumanoidRootPart") and tostring(player.Character.HumanoidRootPart.Position) or "N/A"
    )

    print(info)
end

-- ================================================
-- CREATE THE MAIN INTERFACE
-- ================================================

-- Create main window
local ExecutorWindow = createWindow({
    Name = "Test Server Executor",
    Theme = "Executor",
    Size = UDim2.new(0, 800, 0, 600),
    Position = UDim2.new(0.5, -400, 0.5, -300)
})

-- Create tabs
local ScriptTab = ExecutorWindow:CreateTab({
    Name = "Scripts"
})

local PlayerTab = ExecutorWindow:CreateTab({
    Name = "Player"
})

local WorldTab = ExecutorWindow:CreateTab({
    Name = "World"
})

local ToolsTab = ExecutorWindow:CreateTab({
    Name = "Tools"
})

-- ================================================
-- SCRIPTS TAB
-- ================================================

local ScriptSection = ScriptTab:CreateSection({
    Name = "Script Execution"
})

local scriptInput = ScriptSection:CreateTextBox({
    Name = "Script Input",
    Placeholder = "-- Enter your test script here...",
    Multiline = true,
    Height = 150,
    Callback = function(value)
        currentScript = value
    end
})

ScriptSection:CreateButton({
    Name = "Execute Script",
    Style = "Success",
    Callback = function()
        executeScript(currentScript)
    end
})

ScriptSection:CreateButton({
    Name = "Clear Script",
    Callback = function()
        currentScript = ""
        scriptInput:SetValue("")
    end
})

ScriptSection:CreateButton({
    Name = "Basic Teleport Script",
    Callback = function()
        local script = [[
-- Basic teleport script
local player = game.Players.LocalPlayer
if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
    player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
    print("Teleported to (0, 50, 0)")
end
]]
        scriptInput:SetValue(script)
        currentScript = script
    end
})

-- ================================================
-- PLAYER TAB
-- ================================================

local CharacterSection = PlayerTab:CreateSection({
    Name = "Character Controls"
})

CharacterSection:CreateSlider({
    Name = "Walk Speed",
    Min = 0,
    Max = 100,
    Default = 16,
    Callback = setWalkSpeed
})

CharacterSection:CreateSlider({
    Name = "Jump Power",
    Min = 0,
    Max = 200,
    Default = 50,
    Callback = setJumpPower
})

CharacterSection:CreateSlider({
    Name = "Health",
    Min = 0,
    Max = 100,
    Default = 100,
    Callback = setHealth
})

CharacterSection:CreateToggle({
    Name = "God Mode",
    Default = false,
    Callback = setGodMode
})

CharacterSection:CreateToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = setInfiniteJump
})

CharacterSection:CreateToggle({
    Name = "NoClip",
    Default = false,
    Callback = setNoClip
})

CharacterSection:CreateButton({
    Name = "Reset Character",
    Callback = resetCharacter
})

-- ================================================
-- WORLD TAB
-- ================================================

local LightingSection = WorldTab:CreateSection({
    Name = "Lighting Controls"
})

LightingSection:CreateSlider({
    Name = "Time of Day",
    Min = 0,
    Max = 24,
    Default = 14,
    ValueDisplay = "%.1f:00",
    Callback = setTimeOfDay
})

LightingSection:CreateSlider({
    Name = "Brightness",
    Min = 0,
    Max = 5,
    Default = 1,
    ValueDisplay = "%.1f",
    Callback = setBrightness
})

LightingSection:CreateSlider({
    Name = "Fog End",
    Min = 100,
    Max = 10000,
    Default = 1000,
    Callback = setFogEnd
})

local CameraSection = WorldTab:CreateSection({
    Name = "Camera Controls"
})

CameraSection:CreateSlider({
    Name = "Field of View",
    Min = 30,
    Max = 120,
    Default = 70,
    ValueDisplay = "%d°",
    Callback = setFieldOfView
})

-- ================================================
-- TOOLS TAB
-- ================================================

local UtilitySection = ToolsTab:CreateSection({
    Name = "Utilities"
})

UtilitySection:CreateButton({
    Name = "Clear All Effects",
    Callback = clearAllEffects
})

UtilitySection:CreateButton({
    Name = "Teleport to Spawn",
    Callback = teleportToSpawn
})

UtilitySection:CreateButton({
    Name = "Print Player Info",
    Callback = printPlayerInfo
})

UtilitySection:CreateLabel({
    Name = "Performance Monitor",
    Description = "Real-time performance metrics"
})

local fpsLabel = UtilitySection:CreateLabel({
    Name = "FPS: 60"
})

local memoryLabel = UtilitySection:CreateLabel({
    Name = "Memory: 0 MB"
})

-- Update performance metrics
spawn(function()
    while true do
        wait(1)

        local fps = math.floor(workspace:GetRealFPS())
        local memory = math.floor(collectgarbage("count") / 1000)

        fpsLabel:SetValue("FPS: " .. fps)
        memoryLabel:SetValue("Memory: " .. memory .. " MB")
    end
end)

-- ================================================
-- SHOW THE INTERFACE
-- ================================================

-- Show the main window
ExecutorWindow:Show()

-- Welcome message
print("=== Test Server Executor Loaded ===")
print("Use the Scripts tab to execute Lua code")
print("Use Player and World tabs for character/environment control")
print("Tools tab provides utilities and performance monitoring")
print("For educational and testing purposes only!")

-- Load a basic example script
local exampleScript = [[
-- Welcome to the Test Server Executor!
-- This is a basic example script

print("Hello from the executor!")

-- You can run any Lua code here
-- Try modifying your character or the world

game.Lighting.ClockTime = 12
print("Set time to noon!")]]

scriptInput:SetValue(exampleScript)
currentScript = exampleScript

print("Example script loaded in the Scripts tab")