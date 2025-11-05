--[[
    Advanced Roblox GUI Library - Example Script
    Copy and paste this into a LocalScript in StarterGui

    Installation:
    1. Create a Folder in ReplicatedStorage named "AdvancedUILib"
    2. Copy all source files from the GitHub repository into this folder
    3. Place this script in StarterGui
    4. Run the game!
--]]

-- Method 1: Using ModuleScript (Recommended)
-- Create a ModuleScript in ReplicatedStorage named "AdvancedUILib"
-- Copy all the source code into it
local Library = require(game.ReplicatedStorage:WaitForChild("AdvancedUILib"))

-- Method 2: Using GitHub (Alternative)
-- Uncomment the lines below and comment out the line above
--[[
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ijosephyusufk-dev/SitePrject/main/src/init.lua"))()
end)

if not success then
    warn("Failed to load Advanced GUI Library: " .. tostring(Library))
    return
end
--]]

-- ================================================
-- BASIC GUI EXAMPLE
-- ================================================

-- Create a main window
local MainWindow = Library:CreateWindow({
    Name = "Advanced GUI Demo",
    Theme = "Default",
    Size = UDim2.new(0, 600, 0, 500),
    Position = UDim2.new(0.5, -300, 0.5, -250),
    Resizable = true,
    Minimizable = true,
    Draggable = true,
    SaveConfig = true,
    ConfigName = "DemoGUI_Config"
})

-- Create tabs
local GeneralTab = MainWindow:CreateTab({
    Name = "General",
    Icon = "rbxassetid://7778263872" -- Settings icon
})

local PlayerTab = MainWindow:CreateTab({
    Name = "Player",
    Icon = "rbxassetid://7778265040" -- Player icon
})

local VisualTab = MainWindow:CreateTab({
    Name = "Visual",
    Icon = "rbxassetid://7778265989" -- Visual icon
})

-- ================================================
-- GENERAL TAB CONTENT
-- ================================================

local WelcomeSection = GeneralTab:CreateSection({
    Name = "Welcome",
    Collapsible = false
})

WelcomeSection:CreateLabel({
    Name = "Welcome to Advanced GUI Library!",
    Description = "This is a demonstration of the powerful features available. Try the different tabs and options!"
})

WelcomeSection:CreateButton({
    Name = "Show Notification",
    Callback = function()
        Library:Notify({
            Title = "Hello!",
            Content = "This is a notification from the Advanced GUI Library!",
            Duration = 3
        })
    end
})

WelcomeSection:CreateButton({
    Name = "Change Theme",
    Callback = function()
        local themes = {"Default", "Dark", "Light", "Neon", "Minimal"}
        local currentTheme = Library:GetTheme().Name or "Default"
        local currentIndex = 1

        for i, theme in ipairs(themes) do
            if theme == currentTheme then
                currentIndex = i
                break
            end
        end

        local nextIndex = (currentIndex % #themes) + 1
        local nextTheme = themes[nextIndex]

        Library:SetTheme(nextTheme)
        Library:Notify({
            Title = "Theme Changed",
            Content = "Theme is now: " .. nextTheme,
            Duration = 2
        })
    end
})

local SettingsSection = GeneralTab:CreateSection({
    Name = "Settings",
    Collapsible = true
})

SettingsSection:CreateToggle({
    Name = "Auto-Save Settings",
    Default = true,
    Callback = function(state)
        Library:Notify({
            Title = "Auto-Save",
            Content = state and "Enabled" or "Disabled",
            Duration = 2
        })
    end
})

SettingsSection:CreateToggle({
    Name = "Show Performance Info",
    Default = false,
    Callback = function(state)
        if state then
            -- Enable performance monitoring
            Library:EnableAnalytics({
                TrackPerformance = true,
                LogLevel = "Info"
            })
        end
    end
})

-- ================================================
-- PLAYER TAB CONTENT
-- ================================================

local CharacterSection = PlayerTab:CreateSection({
    Name = "Character Controls"
})

CharacterSection:CreateSlider({
    Name = "Walk Speed",
    Min = 5,
    Max = 50,
    Default = 16,
    ValueDisplay = "%d",
    Callback = function(value)
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = value
        end
    end
})

CharacterSection:CreateSlider({
    Name = "Jump Power",
    Min = 10,
    Max = 100,
    Default = 50,
    ValueDisplay = "%d",
    Callback = function(value)
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.JumpPower = value
        end
    end
})

CharacterSection:CreateSlider({
    Name = "Health Regeneration",
    Min = 0,
    Max = 100,
    Default = 0,
    ValueDisplay = "%d%%",
    Callback = function(value)
        if value > 0 then
            local player = game.Players.LocalPlayer
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.Health = math.min(player.Character.Humanoid.MaxHealth, player.Character.Humanoid.Health + value)
            end
        end
    end
})

local MovementSection = PlayerTab:CreateSection({
    Name = "Movement Options"
})

MovementSection:CreateToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer
        local UserInputService = game:GetService("UserInputService")

        if state then
            local connection
            connection = UserInputService.JumpRequest:Connect(function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)

            -- Store connection for cleanup
            player:SetAttribute("InfiniteJumpConnection", connection)
        else
            local connection = player:GetAttribute("InfiniteJumpConnection")
            if connection then
                connection:Disconnect()
                player:SetAttribute("InfiniteJumpConnection", nil)
            end
        end
    end
})

MovementSection:CreateButton({
    Name = "Reset Character",
    Callback = function()
        game.Players.LocalPlayer:LoadCharacter()
        Library:Notify({
            Title = "Character Reset",
            Content = "Your character has been reset!",
            Duration = 2
        })
    end
})

-- ================================================
-- VISUAL TAB CONTENT
-- ================================================

local CameraSection = VisualTab:CreateSection({
    Name = "Camera Settings"
})

CameraSection:CreateSlider({
    Name = "Field of View",
    Min = 70,
    Max = 120,
    Default = 70,
    ValueDisplay = "%d°",
    Callback = function(value)
    workspace.CurrentCamera.FieldOfView = value
    end
})

CameraSection:CreateSlider({
    Name = "Camera Distance",
    Min = 5,
    Max = 50,
    Default = 15,
    ValueDisplay = "%d studs",
    Callback = function(value)
        -- This would require camera manipulation
        -- Implementation depends on your camera type
    end
})

local LightingSection = VisualTab:CreateSection({
    Name = "Lighting"
})

LightingSection:CreateSlider({
    Name = "Brightness",
    Min = 0,
    Max = 3,
    Default = 1,
    ValueDisplay = "%.1f",
    Callback = function(value)
        game.Lighting.Brightness = value
    end
})

LightingSection:CreateSlider({
    Name = "Time of Day",
    Min = 0,
    Max = 24,
    Default = 14,
    ValueDisplay = "%.1f:00",
    Callback = function(value)
        game.Lighting.ClockTime = value
    end
})

LightingSection:CreateColorPicker({
    Name = "Ambient Color",
    Default = game.Lighting.Ambient,
    Callback = function(color)
        game.Lighting.Ambient = color
    end
})

-- ================================================
-- SHOW THE WINDOW
-- ================================================

MainWindow:Show()

-- ================================================
-- BONUS: Performance Monitor
-- ================================================

-- Create a performance monitor
spawn(function()
    while true do
        wait(5) -- Check every 5 seconds

        local metrics = Library:GetPerformanceMetrics()

        -- Notify if performance is poor
        if metrics.FPS < 30 then
            Library:Notify({
                Title = "Performance Warning",
                Content = "Low FPS: " .. math.floor(metrics.FPS),
                Duration = 3
            })
        end
    end
end)

-- ================================================
-- WELCOME MESSAGE
-- ================================================

Library:Notify({
    Title = "GUI Loaded!",
    Content = "Advanced GUI Library is ready to use. Check out all the tabs and features!",
    Duration = 5
})

print("Advanced GUI Library Demo loaded successfully!")