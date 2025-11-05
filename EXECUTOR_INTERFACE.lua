--[[
    Test Server GUI Interface
    Advanced GUI for legitimate testing, debugging, and development

    INSTRUCTIONS:
    1. Create Folder in ReplicatedStorage named "TestGUI"
    2. Create ModuleScript inside named "TestInterface"
    3. Copy the TEST_INTERFACE_MODULE.lua content into it
    4. Put this script in StarterGui as a LocalScript
    5. Use only on your test server for educational purposes!
--]]

local TestGUI = require(game.ReplicatedStorage:WaitForChild("TestGUI"):WaitForChild("TestInterface"))

-- Create the main executor interface
local ExecutorWindow = TestGUI:CreateWindow({
    Name = "Test Server Interface",
    Theme = "Dark",
    Size = UDim2.new(0, 800, 0, 600),
    Position = UDim2.new(0.5, -400, 0.5, -300),
    SaveConfig = true,
    ConfigName = "TestInterface_Config"
})

-- Create main tabs
local ScriptTab = ExecutorWindow:CreateTab({
    Name = "Scripts",
    Icon = "rbxassetid://7778263872"
})

local PlayerTab = ExecutorWindow:CreateTab({
    Name = "Player",
    Icon = "rbxassetid://7778265040"
})

local WorldTab = ExecutorWindow:CreateTab({
    Name = "World",
    Icon = "rbxassetid://7778265989"
})

local ToolsTab = ExecutorWindow:CreateTab({
    Name = "Tools",
    Icon = "rbxassetid://7778267026"
})

local DebugTab = ExecutorWindow:CreateTab({
    Name = "Debug",
    Icon = "rbxassetid://7778268154"
})

-- ================================================
-- SCRIPTS TAB - Script Execution Interface
-- ================================================

local ScriptSection = ScriptTab:CreateSection({
    Name = "Script Execution",
    Collapsible = false
})

-- Script input area
local scriptInput = ScriptSection:CreateTextBox({
    Name = "Script Input",
    Placeholder = "-- Enter your test script here...",
    Multiline = true,
    Height = 200,
    Callback = function(value)
        TestGUI:SetCurrentScript(value)
    end
})

-- Script execution buttons
local buttonRow = ScriptSection:CreateComponent("ButtonRow", {
    Name = "Actions",
    Buttons = {
        {
            Name = "Execute",
            Style = "Success",
            Callback = function()
                local script = TestGUI:GetCurrentScript()
                TestGUI:ExecuteScript(script)
            end
        },
        {
            Name = "Clear",
            Style = "Secondary",
            Callback = function()
                TestGUI:ClearScript()
                scriptInput:SetValue("")
            end
        },
        {
            Name = "Load",
            Style = "Primary",
            Callback = function()
                TestGUI:LoadScriptDialog()
            end
        }
    }
})

-- Script history
local HistorySection = ScriptTab:CreateSection({
    Name = "Script History",
    Collapsible = true
})

local historyDropdown = HistorySection:CreateDropdown({
    Name = "Previous Scripts",
    Options = {},
    Callback = function(option)
        local script = TestGUI:GetScriptFromHistory(option)
        if script then
            scriptInput:SetValue(script)
        end
    end
})

-- ================================================
-- PLAYER TAB - Player Controls
-- ================================================

local CharacterSection = PlayerTab:CreateSection({
    Name = "Character Controls"
})

CharacterSection:CreateSlider({
    Name = "Walk Speed",
    Min = 0,
    Max = 100,
    Default = 16,
    Callback = function(value)
        TestGUI:SetWalkSpeed(value)
    end
})

CharacterSection:CreateSlider({
    Name = "Jump Power",
    Min = 0,
    Max = 200,
    Default = 50,
    Callback = function(value)
        TestGUI:SetJumpPower(value)
    end
})

CharacterSection:CreateSlider({
    Name = "Health",
    Min = 0,
    Max = 100,
    Default = 100,
    Callback = function(value)
        TestGUI:SetHealth(value)
    end
})

CharacterSection:CreateToggle({
    Name = "God Mode",
    Default = false,
    Callback = function(state)
        TestGUI:SetGodMode(state)
    end
})

CharacterSection:CreateToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(state)
        TestGUI:SetInfiniteJump(state)
    end
})

CharacterSection:CreateButton({
    Name = "Reset Character",
    Callback = function()
        TestGUI:ResetCharacter()
    end
})

-- Movement section
local MovementSection = PlayerTab:CreateSection({
    Name = "Movement",
    Collapsible = true
})

MovementSection:CreateToggle({
    Name = "NoClip",
    Default = false,
    Callback = function(state)
        TestGUI:SetNoClip(state)
    end
})

MovementSection:CreateToggle({
    Name = "Fly",
    Default = false,
    Callback = function(state)
        TestGUI:SetFly(state)
    end
})

MovementSection:CreateSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Callback = function(value)
        TestGUI:SetFlySpeed(value)
    end
})

-- ================================================
-- WORLD TAB - World Manipulation
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
    Callback = function(value)
        TestGUI:SetTimeOfDay(value)
    end
})

LightingSection:CreateSlider({
    Name = "Brightness",
    Min = 0,
    Max = 5,
    Default = 1,
    ValueDisplay = "%.1f",
    Callback = function(value)
        TestGUI:SetBrightness(value)
    end
})

LightingSection:CreateSlider({
    Name = "Fog End",
    Min = 100,
    Max = 10000,
    Default = 1000,
    ValueDisplay = "%d",
    Callback = function(value)
        TestGUI:SetFogEnd(value)
    end
})

-- Camera section
local CameraSection = WorldTab:CreateSection({
    Name = "Camera Controls"
})

CameraSection:CreateSlider({
    Name = "Field of View",
    Min = 30,
    Max = 120,
    Default = 70,
    ValueDisplay = "%d°",
    Callback = function(value)
        TestGUI:SetFieldOfView(value)
    end
})

CameraSection:CreateToggle({
    Name = "Free Camera",
    Default = false,
    Callback = function(state)
        TestGUI:SetFreeCamera(state)
    end
})

CameraSection:CreateButton({
    Name = "Reset Camera",
    Callback = function()
        TestGUI:ResetCamera()
    end
})

-- ================================================
-- TOOLS TAB - Development Tools
-- ================================================

local ToolsSection = ToolsTab:CreateSection({
    Name = "Development Tools"
})

ToolsSection:CreateButton({
    Name = "Explorer (View Instances)",
    Callback = function()
        TestGUI:OpenExplorer()
    end
})

ToolsSection:CreateButton({
    Name = "Properties Inspector",
    Callback = function()
        TestGUI:OpenProperties()
    end
})

ToolsSection:CreateButton({
    Name = "Remote Spy",
    Callback = function()
        TestGUI:OpenRemoteSpy()
    end
})

ToolsSection:CreateButton({
    Name = "Performance Monitor",
    Callback = function()
        TestGUI:OpenPerformanceMonitor()
    end
})

-- Utility section
local UtilitySection = ToolsTab:CreateSection({
    Name = "Utilities",
    Collapsible = true
})

UtilitySection:CreateButton({
    Name = "Clear All Effects",
    Callback = function()
        TestGUI:ClearAllEffects()
    end
})

UtilitySection:CreateButton({
    Name = "Teleport to Spawn",
    Callback = function()
        TestGUI:TeleportToSpawn()
    end
})

UtilitySection:CreateButton({
    Name = "Copy CFrame",
    Callback = function()
        TestGUI:CopyCFrame()
    end
})

UtilitySection:CreateButton({
    Name = "Print Player Info",
    Callback = function()
        TestGUI:PrintPlayerInfo()
    end
})

-- ================================================
-- DEBUG TAB - Debugging Tools
-- ================================================

local ConsoleSection = DebugTab:CreateSection({
    Name = "Console Output"
})

local consoleOutput = ConsoleSection:CreateTextBox({
    Name = "Console",
    Multiline = true,
    Height = 150,
    ReadOnly = true,
    Value = "Test Server Interface Loaded Successfully!\n"
})

local ConsoleSection = DebugTab:CreateSection({
    Name = "Console Controls"
})

ConsoleSection:CreateButton({
    Name = "Clear Console",
    Callback = function()
        consoleOutput:SetValue("Console Cleared!\n")
    end
})

ConsoleSection:CreateToggle({
    Name = "Auto-Scroll",
    Default = true,
    Callback = function(state)
        TestGUI:SetAutoScroll(state)
    end
})

-- Performance section
local PerformanceSection = DebugTab:CreateSection({
    Name = "Performance Monitor"
})

local fpsLabel = PerformanceSection:CreateLabel({
    Name = "FPS: 60",
    Description = "Current frame rate"
})

local memoryLabel = PerformanceSection:CreateLabel({
    Name = "Memory: 0 MB",
    Description = "Current memory usage"
})

local pingLabel = PerformanceSection:CreateLabel({
    Name = "Ping: 0 ms",
    Description = "Network latency"
})

-- Update performance metrics
spawn(function()
    while true do
        wait(1)

        local fps = math.floor(workspace:GetRealFPS())
        local memory = math.floor(collectgarbage("count") / 1000)
        local ping = "N/A"

        fpsLabel:SetValue("FPS: " .. fps)
        memoryLabel:SetValue("Memory: " .. memory .. " MB")
        pingLabel:SetValue("Ping: " .. ping)
    end
end)

-- ================================================
-- SETUP AND SHOW
-- ================================================

-- Set up the GUI
TestGUI:SetOutputCallback(function(message)
    local current = consoleOutput:GetValue()
    consoleOutput:SetValue(current .. "[" .. os.date("%H:%M:%S") .. "] " .. message .. "\n")
end)

-- Load saved scripts
TestGUI:LoadScriptHistory()

-- Show the interface
ExecutorWindow:Show()

-- Welcome message
TestGUI:Print("=== Test Server Interface Loaded ===")
TestGUI:Print("Type scripts in the Scripts tab to execute")
TestGUI:Print("Use Player and World tabs for character/environment control")
TestGUI:Print("Debug tab provides console output and performance monitoring")
TestGUI:Print("Use Tools tab for advanced development utilities")