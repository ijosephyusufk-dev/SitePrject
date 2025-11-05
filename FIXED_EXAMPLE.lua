--[[
    Advanced Roblox GUI Library - WORKING Example
    This script fixes the loading issues and provides a working example

    INSTRUCTIONS:
    1. Create a Folder in ReplicatedStorage named "AdvancedUILib"
    2. Create a ModuleScript inside that folder named "Main"
    3. Copy the FIXED_MAIN_MODULE.lua content into that ModuleScript
    4. Put this script in StarterGui as a LocalScript
    5. Run the game!
--]]

-- Method 1: Using ModuleScript (RECOMMENDED - Most Reliable)
-- First, create the ModuleScript as described above
local Library = require(game.ReplicatedStorage:WaitForChild("AdvancedUILib"):WaitForChild("Main"))

-- Method 2: Direct Loadstring (Alternative - May have issues)
-- Uncomment this and comment out the line above if you want to use GitHub
--[[
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ijosephyusufk-dev/SitePrject/main/src/init.lua"))()
end)

if not success then
    warn("Failed to load Advanced GUI Library: " .. tostring(Library))
    return
end
--]]

-- Check if library loaded successfully
if not Library then
    warn("Failed to load Advanced GUI Library!")
    return
end

-- ================================================
-- WORKING GUI EXAMPLE
-- ================================================

-- Create a simple window
local MyWindow = Library:CreateWindow({
    Name = "My GUI",
    Theme = "Default",
    Size = UDim2.new(0, 400, 0, 300),
    Position = UDim2.new(0.5, -200, 0.5, -150)
})

-- Create a tab
local MainTab = MyWindow:CreateTab("Main")

-- Add a button
MainTab:CreateButton({
    Name = "Click Me!",
    Callback = function()
        print("Button was clicked!")

        -- Try to show notification if available
        if Library.Notify then
            Library:Notify({
                Title = "Success!",
                Content = "The button was clicked!",
                Duration = 2
            })
        else
            warn("Notification system not available - using print instead")
        end
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
MyWindow:Show()

print("GUI loaded successfully!")