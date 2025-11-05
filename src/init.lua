--[[
    Advanced Roblox GUI Library
    A modern, feature-rich GUI library that surpasses existing solutions

    Features:
    - 25+ UI components
    - Real-time collaboration
    - Advanced theming system
    - Smooth animations
    - Mobile-first design
    - Performance optimization

    @author Advanced UI Library Team
    @version 1.0.0
    @license MIT
--]]

local AdvancedUILib = {}
AdvancedUILib.__index = AdvancedUILib

-- Constants
local VERSION = "1.0.0"
local PERFORMANCE_TARGETS = {
    Desktop = 60,
    Mobile = 30
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Import core modules
local Window = require(script.lib.Window)
local ThemeEngine = require(script.lib.ThemeEngine)
local ConfigManager = require(script.lib.ConfigManager)
local AnimationEngine = require(script.lib.AnimationEngine)
local Collaboration = require(script.lib.Collaboration)

-- Import components
local Button = require(script.components.Basic.Button)
local Toggle = require(script.components.Basic.Toggle)
local Slider = require(script.components.Basic.Slider)
local TextBox = require(script.components.Basic.TextBox)
local Label = require(script.components.Basic.Label)
local Dropdown = require(script.components.Basic.Dropdown)

local ColorPicker = require(script.components.Advanced.ColorPicker)
local Keybind = require(script.components.Advanced.Keybind)
local ProgressBar = require(script.components.Advanced.ProgressBar)
local Notification = require(script.components.Advanced.Notification)
local SearchBox = require(script.components.Advanced.SearchBox)

-- Import utilities
local InputHandler = require(script.utils.InputHandler)
local Network = require(script.utils.Network)
local Validation = require(script.utils.Validation)

-- Private variables
local _config = {
    DefaultTheme = "Default",
    AutoSave = true,
    Performance = {
        MaxFPS = 60,
        MobileOptimized = true
    },
    Collaboration = {
        Enabled = false,
        Server = nil
    }
}

local _windows = {}
local _activeTheme = nil
local _isInitialized = false

--[[
    Initialize the library with optional configuration
]]
function AdvancedUILib:SetConfig(config)
    if type(config) ~= "table" then
        error("Config must be a table")
    end

    -- Merge with default config
    for key, value in pairs(config) do
        if type(_config[key]) == "table" and type(value) == "table" then
            for subKey, subValue in pairs(value) do
                _config[key][subKey] = subValue
            end
        else
            _config[key] = value
        end
    end

    -- Initialize theme engine with default theme
    if not _activeTheme then
        _activeTheme = ThemeEngine:GetTheme(_config.DefaultTheme)
    end

    -- Initialize collaboration if enabled
    if _config.Collaboration.Enabled and _config.Collaboration.Server then
        Collaboration:Initialize(_config.Collaboration)
    end

    _isInitialized = true
end

--[[
    Create a new window with the specified configuration
]]
function AdvancedUILib:CreateWindow(config)
    if not _isInitialized then
        self:SetConfig({})
    end

    -- Validate configuration
    Validation:ValidateWindowConfig(config)

    -- Create window
    local window = Window.new(config, _activeTheme, _config)
    table.insert(_windows, window)

    -- Setup collaboration if enabled
    if config.Collaboration and config.Collaboration.Enabled then
        window:EnableCollaboration(config.Collaboration)
    end

    return window
end

--[[
    Get the current theme
]]
function AdvancedUILib:GetTheme()
    return _activeTheme
end

--[[
    Set a new theme
]]
function AdvancedUILib:SetTheme(themeName)
    local theme = ThemeEngine:GetTheme(themeName)
    if theme then
        _activeTheme = theme

        -- Update all windows with new theme
        for _, window in ipairs(_windows) do
            window:SetTheme(theme)
        end

        return true
    end
    return false
end

--[[
    Get available themes
]]
function AdvancedUILib:GetAvailableThemes()
    return ThemeEngine:GetAvailableThemes()
end

--[[
    Enable performance monitoring
]]
function AdvancedUILib:EnableAnalytics(config)
    if not config then config = {} end

    local analytics = {
        TrackPerformance = config.TrackPerformance ~= false,
        TrackUserInteractions = config.TrackUserInteractions ~= false,
        TrackErrors = config.TrackErrors ~= false,
        ReportToServer = config.ReportToServer or false,
        LogLevel = config.LogLevel or "Info"
    }

    -- Setup performance tracking
    if analytics.TrackPerformance then
        self:_SetupPerformanceTracking()
    end

    -- Setup error tracking
    if analytics.TrackErrors then
        self:_SetupErrorTracking()
    end

    return analytics
end

--[[
    Get current performance metrics
]]
function AdvancedUILib:GetPerformanceMetrics()
    local metrics = {
        FPS = workspace:GetRealFPS(),
        MemoryUsage = collectgarbage("count"),
        ActiveComponents = 0,
        ActiveWindows = #_windows,
        Timestamp = os.time()
    }

    -- Count active components
    for _, window in ipairs(_windows) do
        metrics.ActiveComponents = metrics.ActiveComponents + window:GetComponentCount()
    end

    return metrics
end

--[[
    Show a notification
]]
function AdvancedUILib:Notify(config)
    local notification = Notification.new(config, _activeTheme)
    notification:Show()
    return notification
end

--[[
    Get library version
]]
function AdvancedUILib:GetVersion()
    return VERSION
end

--[[
    Cleanup and destroy all windows
]]
function AdvancedUILib:Destroy()
    for _, window in ipairs(_windows) do
        window:Destroy()
    end

    _windows = {}
    Collaboration:Disconnect()

    _isInitialized = false
end

--[[
    Private: Setup performance tracking
]]
function AdvancedUILib:_SetupPerformanceTracking()
    local lastTime = tick()
    local frameCount = 0

    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()

        if currentTime - lastTime >= 1 then
            local fps = frameCount / (currentTime - lastTime)
            frameCount = 0
            lastTime = currentTime

            -- Check performance targets
            local targetFPS = UserInputService.TouchEnabled and PERFORMANCE_TARGETS.Mobile or PERFORMANCE_TARGETS.Desktop

            if fps < targetFPS * 0.8 then
                warn(string.format("Low FPS detected: %.1f (target: %d)", fps, targetFPS))
            end
        end
    end)
end

--[[
    Private: Setup error tracking
]]
function AdvancedUILib:_SetupErrorTracking()
    -- Override error handling for better debugging
    local originalError = error
    _G.error = function(message, level)
        warn(string.format("[AdvancedUILib Error] %s", tostring(message)))
        return originalError(message, level)
    end
end

--[[
    Export component constructors for direct access
]]
AdvancedUILib.Components = {
    Button = Button,
    Toggle = Toggle,
    Slider = Slider,
    TextBox = TextBox,
    Label = Label,
    Dropdown = Dropdown,
    ColorPicker = ColorPicker,
    Keybind = Keybind,
    ProgressBar = ProgressBar,
    Notification = Notification,
    SearchBox = SearchBox
}

--[[
    Export utilities
]]
AdvancedUILib.Utils = {
    InputHandler = InputHandler,
    Network = Network,
    Validation = Validation
}

return AdvancedUILib