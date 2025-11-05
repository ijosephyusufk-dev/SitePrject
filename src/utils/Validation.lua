--[[
    Validation Utilities
    Input validation and sanitization for GUI components

    @author Advanced UI Library Team
    @version 1.0.0
--]]

local Validation = {}

--[[
    Validate window configuration
]]
function Validation.ValidateWindowConfig(config)
    if not config then
        error("Window config is required")
    end

    if not config.Name or type(config.Name) ~= "string" or config.Name == "" then
        error("Window name is required and must be a non-empty string")
    end

    if config.Size and typeof(config.Size) ~= "UDim2" then
        error("Window size must be a UDim2")
    end

    if config.Position and typeof(config.Position) ~= "UDim2" then
        error("Window position must be a UDim2")
    end

    if config.Theme and type(config.Theme) ~= "string" then
        error("Window theme must be a string")
    end

    return true
end

--[[
    Validate component configuration
]]
function Validation.ValidateComponentConfig(config, componentType)
    if not config then
        error("Component config is required")
    end

    if not config.Name or type(config.Name) ~= "string" or config.Name == "" then
        error("Component name is required and must be a non-empty string")
    end

    -- Component-specific validation
    if componentType == "Slider" then
        if config.Min == nil or config.Max == nil then
            error("Slider requires Min and Max values")
        end
        if config.Min >= config.Max then
            error("Slider Min value must be less than Max value")
        end
        if config.Default and (config.Default < config.Min or config.Default > config.Max) then
            error("Slider Default value must be between Min and Max")
        end
    elseif componentType == "TextBox" then
        if config.MaxLength and type(config.MaxLength) ~= "number" then
            error("TextBox MaxLength must be a number")
        end
        if config.MaxLength and config.MaxLength <= 0 then
            error("TextBox MaxLength must be greater than 0")
        end
    elseif componentType == "Dropdown" then
        if not config.Options or type(config.Options) ~= "table" or #config.Options == 0 then
            error("Dropdown requires at least one option")
        end
    end

    return true
end

--[[
    Sanitize text input
]]
function Validation.SanitizeText(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end

    -- Remove potentially dangerous characters
    local sanitized = string.gsub(text, "[%c%z]", "")

    -- Limit length
    if #sanitized > 1000 then
        sanitized = string.sub(sanitized, 1, 1000)
    end

    return sanitized
end

--[[
    Validate color input
]]
function Validation.ValidateColor(color)
    if typeof(color) ~= "Color3" then
        return false
    end

    -- Check if color values are valid
    if color.R < 0 or color.R > 1 or color.G < 0 or color.G > 1 or color.B < 0 or color.B > 1 then
        return false
    end

    return true
end

--[[
    Validate numeric input within range
]]
function Validation.ValidateNumber(value, min, max)
    local num = tonumber(value)
    if not num then
        return false
    end

    if min and num < min then
        return false
    end

    if max and num > max then
        return false
    end

    return true, num
end

return Validation