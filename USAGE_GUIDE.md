# How to Use the Advanced Roblox GUI Library

## 📋 Prerequisites

1. **Roblox Studio** (latest version recommended)
2. **Basic Lua knowledge**
3. **A Roblox game** (place to add the GUI)

## 🎯 Installation Methods

### Method 1: Direct Download (Recommended for Beginners)

1. **Download the files**:
   - Go to https://github.com/ijosephyusufk-dev/SitePrject
   - Click the green "Code" button
   - Select "Download ZIP"
   - Extract the ZIP file to your computer

2. **Add to your game**:
   - Open Roblox Studio
   - Open your game/place
   - In the Explorer window, go to `ServerScriptService` or `ReplicatedStorage`
   - Right-click → `Insert Object` → `Folder`
   - Name the folder `AdvancedUILib`
   - Drag all the `src` files into this folder

### Method 2: GitHub Raw (Quick Setup)

1. **Create a LocalScript** in `StarterGui` or `StarterPlayerScripts`

2. **Add this code**:
```lua
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ijosephyusufk-dev/SitePrject/main/src/init.lua"))()
end)

if not success then
    warn("Failed to load Advanced GUI Library: " .. tostring(Library))
    return
end

-- Now you can use the Library!
```

### Method 3: ModuleScript (Advanced)

1. **Create a ModuleScript** in `ReplicatedStorage` named `AdvancedUILib`
2. **Copy all the source code** into the ModuleScript
3. **Use it in your scripts**:
```lua
local Library = require(game.ReplicatedStorage.AdvancedUILib)
```

## 🚀 Quick Start Examples

### Example 1: Basic GUI (5 minutes)

```lua
-- Put this in a LocalScript in StarterGui
local Library = require(game.ReplicatedStorage.AdvancedUILib) -- or use loadstring method

-- Create a window
local Window = Library:CreateWindow({
    Name = "My First GUI",
    Theme = "Default",
    Size = UDim2.new(0, 500, 0, 400),
    Position = UDim2.new(0.5, -250, 0.5, -200)
})

-- Create a tab
local MainTab = Window:CreateTab("Main")

-- Add a button
MainTab:CreateButton({
    Name = "Click Me!",
    Callback = function()
        print("Button was clicked!")
        Library:Notify({
            Title = "Success!",
            Content = "The button was clicked successfully!",
            Duration = 3
        })
    end
})

-- Add a toggle
MainTab:CreateToggle({
    Name = "Enable Feature",
    Default = false,
    Callback = function(state)
        print("Toggle is now:", state and "ON" or "OFF")
    end
})

-- Show the window
Window:Show()
```

### Example 2: Game Tools GUI

```lua
local Library = require(game.ReplicatedStorage.AdvancedUILib)

-- Create tools window
local ToolsWindow = Library:CreateWindow({
    Name = "Game Tools",
    Theme = "Dark",
    Size = UDim2.new(0, 400, 0, 500),
    Position = UDim2.new(0, 50, 0.5, -250),
    SaveConfig = true,
    ConfigName = "GameToolsConfig"
})

-- Player tab
local PlayerTab = ToolsWindow:CreateTab({
    Name = "Player",
    Icon = "rbxassetid://7778263872" -- Player icon
})

local PlayerSection = PlayerTab:CreateSection({
    Name = "Character Options",
    Collapsible = true
})

-- Speed slider
PlayerSection:CreateSlider({
    Name = "Walk Speed",
    Min = 5,
    Max = 50,
    Default = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

-- Jump power slider
PlayerSection:CreateSlider({
    Name = "Jump Power",
    Min = 10,
    Max = 100,
    Default = 50,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = value
    end
})

-- Visual tab
local VisualTab = ToolsWindow:CreateTab({
    Name = "Visual",
    Icon = "rbxassetid://7778265040" -- Visual icon
})

local VisualSection = VisualTab:CreateSection({
    Name = "Display Options"
})

-- FOV slider
VisualSection:CreateSlider({
    Name = "Field of View",
    Min = 70,
    Max = 120,
    Default = 70,
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end
})

-- Brightness slider
VisualSection:CreateSlider({
    Name = "Brightness",
    Min = 0,
    Max = 2,
    Default = 1,
    Callback = function(value)
        game.Lighting.Brightness = value
    end
})

ToolsWindow:Show()
```

### Example 3: Admin Panel

```lua
local Library = require(game.ReplicatedStorage.AdvancedUILib)

-- Check if player is admin
local player = game.Players.LocalPlayer
local isAdmin = player:GetRankInGroup(123456) >= 100 -- Replace with your group ID

if not isAdmin then
    player:Kick("Access denied")
    return
end

-- Create admin panel
local AdminWindow = Library:CreateWindow({
    Name = "Admin Panel",
    Theme = "Neon",
    Size = UDim2.new(0, 600, 0, 500)
})

-- Players tab
local PlayersTab = AdminWindow:CreateTab("Players")
local PlayersSection = PlayersTab:CreateSection("Player Management")

-- Player selector dropdown
local selectedPlayer = nil
PlayersSection:CreateDropdown({
    Name = "Select Player",
    Options = {},
    Callback = function(option)
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if plr.Name == option then
                selectedPlayer = plr
                break
            end
        end
    end
})

-- Update player list
local function updatePlayerList()
    local playerNames = {}
    for _, plr in ipairs(game.Players:GetPlayers()) do
        table.insert(playerNames, plr.Name)
    end
    -- Update dropdown options (implementation depends on dropdown component)
end

game.Players.PlayerAdded:Connect(updatePlayerList)
game.Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

-- Admin actions
local ActionsSection = PlayersTab:CreateSection("Actions")

ActionsSection:CreateButton({
    Name = "Kick Player",
    Callback = function()
        if selectedPlayer then
            selectedPlayer:Kick("Kicked by admin")
        end
    end
})

ActionsSection:CreateButton({
    Name = "Teleport to Me",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and player.Character then
            selectedPlayer.Character:SetPrimaryPartCFrame(player.Character.PrimaryPart.CFrame)
        end
    end
})

-- Server tab
local ServerTab = AdminWindow:CreateTab("Server")
local ServerSection = ServerTab:CreateSection("Server Control")

ServerSection:CreateButton({
    Name = "Announce Message",
    Callback = function()
        -- This would require RemoteEvents to communicate with server
        print("Announcement feature requires server-side implementation")
    end
})

AdminWindow:Show()
```

## 🎨 Theme Usage

### Switching Themes

```lua
local Library = require(game.ReplicatedStorage.AdvancedUILib)

-- Available themes: "Default", "Dark", "Light", "Neon", "Minimal"

-- Set default theme for all windows
Library:SetTheme("Dark")

-- Or set theme per window
local Window = Library:CreateWindow({
    Name = "Themed Window",
    Theme = "Neon"
})

-- Change theme dynamically
Library:SetTheme("Light")
```

### Creating Custom Themes

```lua
local Library = require(game.ReplicatedStorage.AdvancedUILib)

-- Create a custom theme
local customTheme, themeName = Library:CreateCustomTheme("Default", {
    Colors = {
        Primary = Color3.new(1, 0.5, 0), -- Orange
        Background = Color3.new(0.05, 0.05, 0.1), -- Dark blue
        Surface = Color3.new(0.1, 0.1, 0.15),
        Text = Color3.new(1, 1, 1),
        Success = Color3.new(0, 1, 0.5),
        Warning = Color3.new(1, 1, 0),
        Error = Color3.new(1, 0.2, 0.2)
    },
    Typography = {
        Font = Enum.Font.RobotoMono,
        TextSize = 14,
        TitleSize = 18
    },
    BorderRadius = {
        Medium = 6,
        Large = 10
    }
})

-- Use the custom theme
Library:SetTheme(themeName)
```

## ⚡ Performance Optimization

### Mobile Optimization

```lua
local Library = require(game.ReplicatedStorage.AdvancedUILib)

-- Configure for mobile
Library:SetConfig({
    Performance = {
        MaxFPS = 30, -- Lower for mobile
        MobileOptimized = true
    },
    DefaultTheme = "Dark" -- Better for battery life
})

-- Check if on mobile
if game:GetService("UserInputService").TouchEnabled then
    -- Use mobile-optimized settings
    local Window = Library:CreateWindow({
        Name = "Mobile GUI",
        Size = UDim2.new(1, -20, 0.6, 0), -- Full width
        Position = UDim2.new(0, 10, 1, -200) -- Bottom positioned
    })
end
```

### Performance Monitoring

```lua
local Library = require(game.ReplicatedStorage.AdvancedUILib)

-- Enable performance monitoring
Library:EnableAnalytics({
    TrackPerformance = true,
    TrackUserInteractions = true,
    LogLevel = "Info"
})

-- Monitor performance every 10 seconds
spawn(function()
    while true do
        wait(10)
        local metrics = Library:GetPerformanceMetrics()
        print("FPS:", metrics.FPS)
        print("Memory:", math.floor(metrics.MemoryUsage) .. " KB")
        print("Active Components:", metrics.ActiveComponents)

        -- Warn if performance is low
        if metrics.FPS < 30 then
            warn("Low FPS detected: " .. metrics.FPS)
        end
    end
end)
```

## 🔧 Configuration and Saving

### Auto-Save Settings

```lua
local Library = require(game.ReplicatedStorage.AdvancedUILib)

-- Create window with auto-save
local Window = Library:CreateWindow({
    Name = "Persistent GUI",
    SaveConfig = true,
    ConfigName = "MyPersistentGUI"
})

-- All component values will be automatically saved

-- Or manually save/load
local ConfigManager = Library.Utils.ConfigManager

-- Save custom data
ConfigManager.SaveConfig("MySettings", {
    playerName = game.Players.LocalPlayer.Name,
    lastUsed = os.time(),
    preferences = {
        theme = "Dark",
        windowSize = {500, 400}
    }
})

-- Load saved data
local settings = ConfigManager.LoadConfig("MySettings")
if settings then
    print("Welcome back,", settings.playerName)
end
```

## 🐛 Troubleshooting

### Common Issues

1. **Library not found**:
   ```lua
   -- Make sure the path is correct
   local Library = require(game.ReplicatedStorage.AdvancedUILib)
   -- or use loadstring method
   ```

2. **Window not showing**:
   ```lua
   -- Make sure to call Show()
   Window:Show()
   ```

3. **Components not working**:
   ```lua
   -- Check if components are imported correctly
   -- Make sure callback functions are valid
   ```

### Error Handling

```lua
local success, Library = pcall(function()
    return require(game.ReplicatedStorage.AdvancedUILib)
end)

if not success then
    warn("Failed to load GUI Library:", Library)
    return
end

-- Safe window creation
local success2, Window = pcall(function()
    return Library:CreateWindow({Name = "Test GUI"})
end)

if not success2 then
    warn("Failed to create window:", Window)
    return
end
```

## 📞 Getting Help

- **GitHub Issues**: Report bugs at the repository
- **Documentation**: Check the README.md file
- **Examples**: Look at the usage examples above
- **Community**: Share your creations and get feedback

## 🎯 Next Steps

1. **Try the basic examples** to get familiar with the API
2. **Explore different themes** to find your preferred style
3. **Build your first custom GUI** using the components
4. **Add collaboration features** to work with others
5. **Share your creations** with the community!

Happy GUI building! 🚀