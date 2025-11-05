--[[
    Theme Engine
    Comprehensive theming system with dynamic theme switching and customization

    @author Advanced UI Library Team
    @version 1.0.0
--]]

local ThemeEngine = {}
ThemeEngine.__index = ThemeEngine

-- Theme storage
local themes = {}
local activeTheme = nil
local customThemes = {}

-- Default theme structure template
local DEFAULT_THEME_STRUCTURE = {
    Colors = {
        Primary = Color3.new(0, 0.4, 0.8),
        Secondary = Color3.new(0.9, 0.9, 0.9),
        Background = Color3.new(0.1, 0.1, 0.1),
        Surface = Color3.new(0.15, 0.15, 0.15),
        Text = Color3.new(1, 1, 1),
        TextSecondary = Color3.new(0.7, 0.7, 0.7),
        Border = Color3.new(0.3, 0.3, 0.3),
        Success = Color3.new(0, 0.8, 0),
        Warning = Color3.new(1, 0.8, 0),
        Error = Color3.new(0.8, 0, 0),
        Info = Color3.new(0, 0.6, 1)
    },
    Typography = {
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TitleSize = 18,
        HeaderSize = 16,
        SubtitleSize = 12,
        LineHeight = 1.4
    },
    Spacing = {
        XS = 4,
        S = 8,
        M = 16,
        L = 24,
        XL = 32,
        XXL = 48
    },
    BorderRadius = {
        Small = 4,
        Medium = 8,
        Large = 12,
        XLarge = 16
    },
    Shadows = {
        Light = Color3.new(0, 0, 0, 0.1),
        Medium = Color3.new(0, 0, 0, 0.2),
        Heavy = Color3.new(0, 0, 0, 0.3)
    },
    Animations = {
        DefaultEasing = "QuadOut",
        DefaultDuration = 0.3,
        FastDuration = 0.15,
        SlowDuration = 0.6,
        HoverDuration = 0.2
    },
    Accessibility = {
        HighContrast = false,
        ReducedMotion = false,
        ColorBlindFriendly = false
    }
}

--[[
    Initialize the theme engine with default themes
]]
function ThemeEngine.Initialize()
    -- Register default themes
    ThemeEngine:RegisterTheme("Default", ThemeEngine.CreateDefaultTheme())
    ThemeEngine:RegisterTheme("Dark", ThemeEngine.CreateDarkTheme())
    ThemeEngine:RegisterTheme("Light", ThemeEngine.CreateLightTheme())
    ThemeEngine:RegisterTheme("Neon", ThemeEngine.CreateNeonTheme())
    ThemeEngine:RegisterTheme("Minimal", ThemeEngine.CreateMinimalTheme())

    -- Set default theme as active
    activeTheme = themes.Default
end

--[[
    Register a new theme
]]
function ThemeEngine.RegisterTheme(name, theme)
    -- Validate theme structure
    ThemeEngine.ValidateTheme(theme)

    themes[name] = theme

    -- Emit theme registered event
    ThemeEngine._emitEvent("ThemeRegistered", {name = name, theme = theme})
end

--[[
    Get a theme by name
]]
function ThemeEngine.GetTheme(name)
    return themes[name]
end

--[[
    Get all available themes
]]
function ThemeEngine.GetAvailableThemes()
    local themeList = {}
    for name, _ in pairs(themes) do
        table.insert(themeList, name)
    end
    return themeList
end

--[[
    Get the currently active theme
]]
function ThemeEngine.GetActiveTheme()
    return activeTheme
end

--[[
    Set the active theme
]]
function ThemeEngine.SetActiveTheme(name)
    local theme = themes[name]
    if theme then
        local oldTheme = activeTheme
        activeTheme = theme

        -- Emit theme changed event
        ThemeEngine._emitEvent("ThemeChanged", {
            oldTheme = oldTheme,
            newTheme = theme,
            themeName = name
        })

        return true
    end
    return false
end

--[[
    Create a custom theme
]]
function ThemeEngine.CreateCustomTheme(baseTheme, overrides)
    local base = themes[baseTheme] or activeTheme
    if not base then
        error("Base theme not found: " .. tostring(baseTheme))
    end

    -- Deep copy base theme
    local customTheme = ThemeEngine.DeepCopy(base)

    -- Apply overrides
    if overrides then
        ThemeEngine.DeepMerge(customTheme, overrides)
    end

    -- Generate unique name if not provided
    local customName = overrides and overrides.Name or ("Custom_" .. tick())

    -- Register custom theme
    customThemes[customName] = customTheme
    ThemeEngine.RegisterTheme(customName, customTheme)

    return customTheme, customName
end

--[[
    Validate theme structure
]]
function ThemeEngine.ValidateTheme(theme)
    if type(theme) ~= "table" then
        error("Theme must be a table")
    end

    -- Check required sections
    local requiredSections = {"Colors", "Typography", "Spacing", "BorderRadius", "Shadows", "Animations"}
    for _, section in ipairs(requiredSections) do
        if not theme[section] then
            error("Theme missing required section: " .. section)
        end
    end

    -- Validate colors
    local requiredColors = {"Primary", "Secondary", "Background", "Surface", "Text", "TextSecondary"}
    for _, color in ipairs(requiredColors) do
        if not theme.Colors[color] or typeof(theme.Colors[color]) ~= "Color3" then
            error("Theme missing or invalid color: " .. color)
        end
    end

    return true
end

--[[
    Deep copy a table
]]
function ThemeEngine.DeepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = ThemeEngine.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

--[[
    Deep merge tables
]]
function ThemeEngine.DeepMerge(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            ThemeEngine.DeepMerge(target[key], value)
        else
            target[key] = value
        end
    end
    return target
end

--[[
    Export theme to JSON string
]]
function ThemeEngine.ExportTheme(name)
    local theme = themes[name]
    if not theme then
        return nil
    end

    -- Convert Color3 to RGB values for JSON serialization
    local exportable = ThemeEngine.DeepCopy(theme)
    ThemeEngine._convertColorsForExport(exportable)

    local HttpService = game:GetService("HttpService")
    return HttpService:JSONEncode(exportable)
end

--[[
    Import theme from JSON string
]]
function ThemeEngine.ImportTheme(name, jsonString)
    local HttpService = game:GetService("HttpService")
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)

    if not success then
        error("Invalid JSON format: " .. tostring(data))
    end

    -- Convert RGB values back to Color3
    ThemeEngine._convertColorsFromImport(data)

    -- Validate and register theme
    ThemeEngine.ValidateTheme(data)
    ThemeEngine.RegisterTheme(name, data)

    return data
end

--[[
    Create default theme
]]
function ThemeEngine.CreateDefaultTheme()
    return ThemeEngine.DeepCopy(DEFAULT_THEME_STRUCTURE)
end

--[[
    Create dark theme
]]
function ThemeEngine.CreateDarkTheme()
    local theme = ThemeEngine.DeepCopy(DEFAULT_THEME_STRUCTURE)

    theme.Name = "Dark"
    theme.Colors = {
        Primary = Color3.new(0.1, 0.3, 0.6),
        Secondary = Color3.new(0.2, 0.2, 0.2),
        Background = Color3.new(0.05, 0.05, 0.05),
        Surface = Color3.new(0.1, 0.1, 0.1),
        Text = Color3.new(0.95, 0.95, 0.95),
        TextSecondary = Color3.new(0.6, 0.6, 0.6),
        Border = Color3.new(0.2, 0.2, 0.2),
        Success = Color3.new(0.1, 0.7, 0.1),
        Warning = Color3.new(0.9, 0.7, 0.1),
        Error = Color3.new(0.7, 0.1, 0.1),
        Info = Color3.new(0.1, 0.5, 0.9)
    }

    theme.Shadows = {
        Light = Color3.new(0, 0, 0, 0.2),
        Medium = Color3.new(0, 0, 0, 0.4),
        Heavy = Color3.new(0, 0, 0, 0.6)
    }

    return theme
end

--[[
    Create light theme
]]
function ThemeEngine.CreateLightTheme()
    local theme = ThemeEngine.DeepCopy(DEFAULT_THEME_STRUCTURE)

    theme.Name = "Light"
    theme.Colors = {
        Primary = Color3.new(0, 0.6, 1),
        Secondary = Color3.new(0.95, 0.95, 0.95),
        Background = Color3.new(0.98, 0.98, 0.98),
        Surface = Color3.new(0.9, 0.9, 0.9),
        Text = Color3.new(0.1, 0.1, 0.1),
        TextSecondary = Color3.new(0.4, 0.4, 0.4),
        Border = Color3.new(0.7, 0.7, 0.7),
        Success = Color3.new(0.1, 0.8, 0.1),
        Warning = Color3.new(1, 0.7, 0),
        Error = Color3.new(0.9, 0.1, 0.1),
        Info = Color3.new(0, 0.5, 1)
    }

    theme.Shadows = {
        Light = Color3.new(0, 0, 0, 0.05),
        Medium = Color3.new(0, 0, 0, 0.1),
        Heavy = Color3.new(0, 0, 0, 0.15)
    }

    return theme
end

--[[
    Create neon/cyberpunk theme
]]
function ThemeEngine.CreateNeonTheme()
    local theme = ThemeEngine.DeepCopy(DEFAULT_THEME_STRUCTURE)

    theme.Name = "Neon"
    theme.Colors = {
        Primary = Color3.new(1, 0, 1),
        Secondary = Color3.new(0, 1, 1),
        Background = Color3.new(0.02, 0, 0.05),
        Surface = Color3.new(0.05, 0, 0.1),
        Text = Color3.new(0, 1, 0.8),
        TextSecondary = Color3.new(0.8, 0, 1),
        Border = Color3.new(1, 0, 0.8),
        Success = Color3.new(0, 1, 0),
        Warning = Color3.new(1, 1, 0),
        Error = Color3.new(1, 0.2, 0.2),
        Info = Color3.new(0, 0.8, 1)
    }

    theme.Typography.Font = Enum.Font.RobotoMono
    theme.Shadows = {
        Light = Color3.new(1, 0, 1, 0.3),
        Medium = Color3.new(0, 1, 1, 0.5),
        Heavy = Color3.new(1, 0, 0.8, 0.7)
    }
    theme.Animations.DefaultDuration = 0.4
    theme.Animations.DefaultEasing = "ElasticOut"

    return theme
end

--[[
    Create minimal theme
]]
function ThemeEngine.CreateMinimalTheme()
    local theme = ThemeEngine.DeepCopy(DEFAULT_THEME_STRUCTURE)

    theme.Name = "Minimal"
    theme.Colors = {
        Primary = Color3.new(0.3, 0.3, 0.3),
        Secondary = Color3.new(0.95, 0.95, 0.95),
        Background = Color3.new(1, 1, 1),
        Surface = Color3.new(0.98, 0.98, 0.98),
        Text = Color3.new(0.2, 0.2, 0.2),
        TextSecondary = Color3.new(0.5, 0.5, 0.5),
        Border = Color3.new(0.85, 0.85, 0.85),
        Success = Color3.new(0.2, 0.7, 0.2),
        Warning = Color3.new(0.8, 0.6, 0),
        Error = Color3.new(0.7, 0.2, 0.2),
        Info = Color3.new(0.2, 0.5, 0.8)
    }

    theme.BorderRadius = {
        Small = 2,
        Medium = 4,
        Large = 6,
        XLarge = 8
    }
    theme.Shadows = {
        Light = Color3.new(0, 0, 0, 0.03),
        Medium = Color3.new(0, 0, 0, 0.06),
        Heavy = Color3.new(0, 0, 0, 0.1)
    }
    theme.Animations.DefaultDuration = 0.2
    theme.Animations.DefaultEasing = "Linear"

    return theme
end

--[[
    Get theme colors for accessibility
]]
function ThemeEngine.GetAccessibleColors(theme, colorBlindType)
    local accessible = ThemeEngine.DeepCopy(theme.Colors)

    if colorBlindType == "protanopia" then
        -- Red-blind: Red becomes gray, adjust primary colors
        accessible.Primary = Color3.new(0, 0.4, 0.8)
        accessible.Error = Color3.new(0.6, 0.4, 0)
    elseif colorBlindType == "deuteranopia" then
        -- Green-blind: Green becomes gray
        accessible.Success = Color3.new(0, 0.5, 0.8)
    elseif colorBlindType == "tritanopia" then
        -- Blue-blind: Blue becomes gray
        accessible.Primary = Color3.new(0.8, 0.4, 0)
        accessible.Info = Color3.new(0.8, 0.4, 0)
    end

    return accessible
end

--[[
    Create high contrast version of theme
]]
function ThemeEngine.CreateHighContrastTheme(baseTheme)
    local theme = ThemeEngine.DeepCopy(themes[baseTheme] or activeTheme)

    -- Increase contrast ratios
    theme.Colors.Text = Color3.new(1, 1, 1)
    theme.Colors.Background = Color3.new(0, 0, 0)
    theme.Colors.Surface = Color3.new(0.1, 0.1, 0.1)
    theme.Colors.Border = Color3.new(0.8, 0.8, 0.8)
    theme.Accessibility.HighContrast = true

    return theme
end

--[[
    Create reduced motion version of theme
]]
function ThemeEngine.CreateReducedMotionTheme(baseTheme)
    local theme = ThemeEngine.DeepCopy(themes[baseTheme] or activeTheme)

    theme.Animations.DefaultDuration = 0
    theme.Animations.FastDuration = 0
    theme.Animations.SlowDuration = 0
    theme.Animations.HoverDuration = 0
    theme.Animations.DefaultEasing = "Linear"
    theme.Accessibility.ReducedMotion = true

    return theme
end

--[[
    Private: Convert colors to RGB for export
]]
function ThemeEngine._convertColorsForExport(theme)
    if theme.Colors then
        for key, color in pairs(theme.Colors) do
            if typeof(color) == "Color3" then
                theme.Colors[key] = {
                    R = color.R,
                    G = color.G,
                    B = color.B
                }
            end
        end
    end
end

--[[
    Private: Convert RGB back to Color3 for import
]]
function ThemeEngine._convertColorsFromImport(theme)
    if theme.Colors then
        for key, colorData in pairs(theme.Colors) do
            if type(colorData) == "table" and colorData.R and colorData.G and colorData.B then
                theme.Colors[key] = Color3.new(colorData.R, colorData.G, colorData.B)
            end
        end
    end
end

--[[
    Private: Emit events (simplified event system)
]]
function ThemeEngine._emitEvent(eventName, data)
    -- This would integrate with a proper event system
    -- For now, we'll just print debug info
    if _G.DEBUG_THEME_EVENTS then
        print("ThemeEngine Event:", eventName, data)
    end
end

--[[
    Get theme statistics
]]
function ThemeEngine.GetThemeStats()
    return {
        TotalThemes = 0,
        CustomThemes = 0,
        DefaultThemes = 0,
        ActiveTheme = activeTheme and "Default" or "None"
    }
end

--[[
    Generate color palette from theme
]]
function ThemeEngine.GenerateColorPalette(themeName)
    local theme = themes[themeName] or activeTheme
    if not theme then return nil end

    local palette = {
        Primary = {
            Light = ThemeEngine.LightenColor(theme.Colors.Primary, 0.2),
            Default = theme.Colors.Primary,
            Dark = ThemeEngine.DarkenColor(theme.Colors.Primary, 0.2)
        },
        Secondary = {
            Light = ThemeEngine.LightenColor(theme.Colors.Secondary, 0.2),
            Default = theme.Colors.Secondary,
            Dark = ThemeEngine.DarkenColor(theme.Colors.Secondary, 0.2)
        },
        Semantic = {
            Success = theme.Colors.Success,
            Warning = theme.Colors.Warning,
            Error = theme.Colors.Error,
            Info = theme.Colors.Info
        },
        Neutral = {
            White = Color3.new(1, 1, 1),
            LightGray = Color3.new(0.9, 0.9, 0.9),
            MediumGray = Color3.new(0.5, 0.5, 0.5),
            DarkGray = Color3.new(0.2, 0.2, 0.2),
            Black = Color3.new(0, 0, 0)
        }
    }

    return palette
end

--[[
    Lighten a color by amount (0-1)
]]
function ThemeEngine.LightenColor(color, amount)
    return Color3.new(
        math.min(1, color.R + amount),
        math.min(1, color.G + amount),
        math.min(1, color.B + amount)
    )
end

--[[
    Darken a color by amount (0-1)
]]
function ThemeEngine.DarkenColor(color, amount)
    return Color3.new(
        math.max(0, color.R - amount),
        math.max(0, color.G - amount),
        math.max(0, color.B - amount)
    )
end

-- Initialize the theme engine
ThemeEngine.Initialize()

return ThemeEngine