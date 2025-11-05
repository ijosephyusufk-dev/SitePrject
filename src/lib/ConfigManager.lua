--[[
    Configuration Manager
    Persistent settings storage with auto-save and version control

    @author Advanced UI Library Team
    @version 1.0.0
--]]

local ConfigManager = {}
ConfigManager.__index = ConfigManager

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Constants
local CONFIG_VERSION = "1.0.0"
local AUTO_SAVE_INTERVAL = 30 -- seconds
local MAX_CONFIG_SIZE = 100000 -- bytes

-- Storage locations
local STORAGE_LOCATIONS = {
    LocalStorage = "LocalStorage",
    DataStore = "DataStore",
    SessionStorage = "SessionStorage",
    CloudStorage = "CloudStorage"
}

-- Config cache
local configCache = {}
local autoSaveTimers = {}
local isStudio = game:GetService("RunService"):IsStudio()

--[[
    Initialize the configuration manager
]]
function ConfigManager.Initialize()
    -- Initialize config cache
    configCache = {}

    -- Setup cleanup on game end
    if game:GetService("RunService"):IsStudio() then
        game:BindToClose(function()
            ConfigManager.SaveAllConfigs()
        end)
    end
end

--[[
    Save configuration data
]]
function ConfigManager.SaveConfig(configName, data, options)
    options = options or {}
    local storageLocation = options.StorageLocation or STORAGE_LOCATIONS.LocalStorage
    local autoSave = options.AutoSave ~= false

    -- Validate input
    if not configName or type(configName) ~= "string" then
        error("Config name must be a non-empty string")
    end

    if not data or type(data) ~= "table" then
        error("Config data must be a table")
    end

    -- Prepare configuration data
    local configData = {
        version = CONFIG_VERSION,
        timestamp = os.time(),
        data = data,
        metadata = {
            storageLocation = storageLocation,
            autoSave = autoSave,
            userId = Players.LocalPlayer and Players.LocalPlayer.UserId or -1,
            gameId = game.GameId
        }
    }

    -- Add version control
    if options.Version then
        configData.metadata.version = options.Version
    end

    -- Validate config size
    local configString = HttpService:JSONEncode(configData)
    if #configString > MAX_CONFIG_SIZE then
        error("Configuration size exceeds maximum limit of " .. MAX_CONFIG_SIZE .. " bytes")
    end

    -- Save to cache
    configCache[configName] = configData

    -- Save to storage
    local success, errorMessage = ConfigManager._saveToStorage(configName, configData, storageLocation)
    if not success then
        warn("Failed to save config '" .. configName .. "': " .. tostring(errorMessage))
        return false
    end

    -- Setup auto-save timer
    if autoSave then
        ConfigManager._setupAutoSave(configName, storageLocation)
    end

    return true
end

--[[
    Load configuration data
]]
function ConfigManager.LoadConfig(configName, options)
    options = options or {}
    local storageLocation = options.StorageLocation or STORAGE_LOCATIONS.LocalStorage

    -- Check cache first
    if configCache[configName] then
        local cachedConfig = configCache[configName]

        -- Verify storage location matches
        if cachedConfig.metadata.storageLocation == storageLocation then
            return cachedConfig.data, cachedConfig
        end
    end

    -- Load from storage
    local success, configData = ConfigManager._loadFromStorage(configName, storageLocation)
    if not success then
        -- Return default config if provided
        if options.Default then
            return options.Default, nil
        end
        return nil, nil
    end

    -- Validate and migrate config if needed
    local validatedConfig = ConfigManager._validateAndMigrate(configData, options)

    -- Cache the config
    configCache[configName] = validatedConfig

    return validatedConfig.data, validatedConfig
end

--[[
    Delete configuration
]]
function ConfigManager.DeleteConfig(configName, options)
    options = options or {}
    local storageLocation = options.StorageLocation or STORAGE_LOCATIONS.LocalStorage

    -- Remove from cache
    configCache[configName] = nil

    -- Cancel auto-save timer
    if autoSaveTimers[configName] then
        autoSaveTimers[configName]:Disconnect()
        autoSaveTimers[configName] = nil
    end

    -- Delete from storage
    return ConfigManager._deleteFromStorage(configName, storageLocation)
end

--[[
    Check if configuration exists
]]
function ConfigManager.ConfigExists(configName, options)
    options = options or {}
    local storageLocation = options.StorageLocation or STORAGE_LOCATIONS.LocalStorage

    -- Check cache
    if configCache[configName] then
        return true
    end

    -- Check storage
    return ConfigManager._existsInStorage(configName, storageLocation)
end

--[[
    Get all configuration names
]]
function ConfigManager.GetConfigNames(options)
    options = options or {}
    local storageLocation = options.StorageLocation or STORAGE_LOCATIONS.LocalStorage

    -- Get from storage
    return ConfigManager._getConfigNamesFromStorage(storageLocation)
end

--[[
    Export configuration to JSON
]]
function ConfigManager.ExportConfig(configName, options)
    local configData, fullConfig = ConfigManager.LoadConfig(configName, options)
    if not configData then
        return nil
    end

    -- Prepare export data
    local exportData = {
        name = configName,
        exportedAt = os.time(),
        version = fullConfig and fullConfig.version or CONFIG_VERSION,
        data = configData
    end

    return HttpService:JSONEncode(exportData)
end

--[[
    Import configuration from JSON
]]
function ConfigManager.ImportConfig(jsonString, options)
    options = options or {}
    local overwrite = options.Overwrite or false

    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)

    if not success then
        error("Invalid JSON format: " .. tostring(data))
    end

    -- Validate import data
    if not data.name or not data.data then
        error("Invalid import data format")
    end

    -- Check if config already exists
    if not overwrite and ConfigManager.ConfigExists(data.name) then
        error("Configuration '" .. data.name .. "' already exists. Use overwrite option to replace it.")
    end

    -- Import the config
    return ConfigManager.SaveConfig(data.name, data.data, options)
end

--[[
    Save all cached configurations
]]
function ConfigManager.SaveAllConfigs()
    local successCount = 0
    local failCount = 0

    for configName, configData in pairs(configCache) do
        local success = ConfigManager._saveToStorage(configName, configData, configData.metadata.storageLocation)
        if success then
            successCount = successCount + 1
        else
            failCount = failCount + 1
            warn("Failed to auto-save config: " .. configName)
        end
    end

    return successCount, failCount
end

--[[
    Clear configuration cache
]]
function ConfigManager.ClearCache(configName)
    if configName then
        configCache[configName] = nil
        if autoSaveTimers[configName] then
            autoSaveTimers[configName]:Disconnect()
            autoSaveTimers[configName] = nil
        end
    else
        -- Clear all cache
        for timerName, timer in pairs(autoSaveTimers) do
            timer:Disconnect()
        end
        autoSaveTimers = {}
        configCache = {}
    end
end

--[[
    Get configuration statistics
]]
function ConfigManager.GetStats()
    local stats = {
        CachedConfigs = 0,
        AutoSaveTimers = 0,
        TotalSize = 0,
        StorageLocations = {}
    }

    for configName, configData in pairs(configCache) do
        stats.CachedConfigs = stats.CachedConfigs + 1

        local configSize = #HttpService:JSONEncode(configData)
        stats.TotalSize = stats.TotalSize + configSize

        local storageLocation = configData.metadata.storageLocation
        stats.StorageLocations[storageLocation] = (stats.StorageLocations[storageLocation] or 0) + 1
    end

    stats.AutoSaveTimers = 0
    for _ in pairs(autoSaveTimers) do
        stats.AutoSaveTimers = stats.AutoSaveTimers + 1
    end

    return stats
end

--[[
    Private: Save to storage location
]]
function ConfigManager._saveToStorage(configName, configData, storageLocation)
    local success, errorMessage = false, "Unknown storage location"

    if storageLocation == STORAGE_LOCATIONS.LocalStorage then
        success, errorMessage = ConfigManager._saveToLocalStorage(configName, configData)
    elseif storageLocation == STORAGE_LOCATIONS.DataStore then
        success, errorMessage = ConfigManager._saveToDataStore(configName, configData)
    elseif storageLocation == STORAGE_LOCATIONS.SessionStorage then
        success, errorMessage = ConfigManager._saveToSessionStorage(configName, configData)
    elseif storageLocation == STORAGE_LOCATIONS.CloudStorage then
        success, errorMessage = ConfigManager._saveToCloudStorage(configName, configData)
    end

    return success, errorMessage
end

--[[
    Private: Load from storage location
]]
function ConfigManager._loadFromStorage(configName, storageLocation)
    local success, data = false, nil

    if storageLocation == STORAGE_LOCATIONS.LocalStorage then
        success, data = ConfigManager._loadFromLocalStorage(configName)
    elseif storageLocation == STORAGE_LOCATIONS.DataStore then
        success, data = ConfigManager._loadFromDataStore(configName)
    elseif storageLocation == STORAGE_LOCATIONS.SessionStorage then
        success, data = ConfigManager._loadFromSessionStorage(configName)
    elseif storageLocation == STORAGE_LOCATIONS.CloudStorage then
        success, data = ConfigManager._loadFromCloudStorage(configName)
    end

    return success, data
end

--[[
    Private: Save to local storage (using PlayerGui)
]]
function ConfigManager._saveToLocalStorage(configName, configData)
    local player = Players.LocalPlayer
    if not player then return false, "No local player" end

    local success, errorMessage = pcall(function()
        local jsonString = HttpService:JSONEncode(configData)

        -- Create a StringValue in PlayerGui to store the config
        local configFolder = player:FindFirstChild("UILibConfigs")
        if not configFolder then
            configFolder = Instance.new("Folder")
            configFolder.Name = "UILibConfigs"
            configFolder.Parent = player
        end

        local configValue = configFolder:FindFirstChild(configName)
        if not configValue then
            configValue = Instance.new("StringValue")
            configValue.Name = configName
            configValue.Parent = configFolder
        end

        configValue.Value = jsonString
    end)

    return success, errorMessage
end

--[[
    Private: Load from local storage
]]
function ConfigManager._loadFromLocalStorage(configName)
    local player = Players.LocalPlayer
    if not player then return false, "No local player" end

    local success, data = pcall(function()
        local configFolder = player:FindFirstChild("UILibConfigs")
        if not configFolder then return nil end

        local configValue = configFolder:FindFirstChild(configName)
        if not configValue or configValue.Value == "" then return nil end

        return HttpService:JSONDecode(configValue.Value)
    end)

    return success, data
end

--[[
    Private: Save to DataStore (placeholder for Roblox DataStore implementation)
]]
function ConfigManager._saveToDataStore(configName, configData)
    -- This would integrate with Roblox DataStoreService
    -- For now, we'll use local storage as fallback
    if isStudio then
        return ConfigManager._saveToLocalStorage(configName, configData)
    end

    warn("DataStore storage not implemented in this version. Using LocalStorage.")
    return ConfigManager._saveToLocalStorage(configName, configData)
end

--[[
    Private: Load from DataStore
]]
function ConfigManager._loadFromDataStore(configName)
    -- This would integrate with Roblox DataStoreService
    if isStudio then
        return ConfigManager._loadFromLocalStorage(configName)
    end

    return ConfigManager._loadFromLocalStorage(configName)
end

--[[
    Private: Save to session storage (memory only)
]]
function ConfigManager._saveToSessionStorage(configName, configData)
    -- Session storage is just the config cache
    configCache[configName] = configData
    return true
end

--[[
    Private: Load from session storage
]]
function ConfigManager._loadFromSessionStorage(configName)
    if configCache[configName] then
        return true, configCache[configName]
    end
    return false, nil
end

--[[
    Private: Save to cloud storage (placeholder)
]]
function ConfigManager._saveToCloudStorage(configName, configData)
    warn("Cloud storage not implemented. Using LocalStorage.")
    return ConfigManager._saveToLocalStorage(configName, configData)
end

--[[
    Private: Load from cloud storage
]]
function ConfigManager._loadFromCloudStorage(configName)
    warn("Cloud storage not implemented. Using LocalStorage.")
    return ConfigManager._loadFromLocalStorage(configName)
end

--[[
    Private: Delete from storage
]]
function ConfigManager._deleteFromStorage(configName, storageLocation)
    if storageLocation == STORAGE_LOCATIONS.LocalStorage then
        local player = Players.LocalPlayer
        if player then
            local configFolder = player:FindFirstChild("UILibConfigs")
            if configFolder then
                local configValue = configFolder:FindFirstChild(configName)
                if configValue then
                    configValue:Destroy()
                    return true
                end
            end
        end
    end

    -- For other storage types, this would need implementation
    return false
end

--[[
    Private: Check if config exists in storage
]]
function ConfigManager._existsInStorage(configName, storageLocation)
    if storageLocation == STORAGE_LOCATIONS.LocalStorage then
        local player = Players.LocalPlayer
        if player then
            local configFolder = player:FindFirstChild("UILibConfigs")
            if configFolder then
                return configFolder:FindFirstChild(configName) ~= nil
            end
        end
    elseif storageLocation == STORAGE_LOCATIONS.SessionStorage then
        return configCache[configName] ~= nil
    end

    return false
end

--[[
    Private: Get config names from storage
]]
function ConfigManager._getConfigNamesFromStorage(storageLocation)
    local configNames = {}

    if storageLocation == STORAGE_LOCATIONS.LocalStorage then
        local player = Players.LocalPlayer
        if player then
            local configFolder = player:FindFirstChild("UILibConfigs")
            if configFolder then
                for _, child in ipairs(configFolder:GetChildren()) do
                    if child:IsA("StringValue") then
                        table.insert(configNames, child.Name)
                    end
                end
            end
        end
    elseif storageLocation == STORAGE_LOCATIONS.SessionStorage then
        for configName, _ in pairs(configCache) do
            table.insert(configNames, configName)
        end
    end

    return configNames
end

--[[
    Private: Setup auto-save timer
]]
function ConfigManager._setupAutoSave(configName, storageLocation)
    -- Cancel existing timer
    if autoSaveTimers[configName] then
        autoSaveTimers[configName]:Disconnect()
    end

    -- Create new timer
    autoSaveTimers[configName] = spawn(function()
        while true do
            wait(AUTO_SAVE_INTERVAL)

            if configCache[configName] then
                local success = ConfigManager._saveToStorage(configName, configCache[configName], storageLocation)
                if not success then
                    warn("Auto-save failed for config: " .. configName)
                end
            else
                break -- Config was removed
            end
        end
    end)
end

--[[
    Private: Validate and migrate configuration
]]
function ConfigManager._validateAndMigrate(configData, options)
    if not configData then
        error("Invalid config data")
    end

    -- Check version
    local currentVersion = configData.version or "0.0.0"
    local targetVersion = CONFIG_VERSION

    -- Migrate if needed
    if currentVersion ~= targetVersion then
        configData = ConfigManager._migrateConfig(configData, currentVersion, targetVersion)
    end

    -- Validate data structure
    if not configData.data then
        configData.data = {}
    end

    -- Apply default values if provided
    if options.DefaultValues then
        ConfigManager._applyDefaults(configData.data, options.DefaultValues)
    end

    return configData
end

--[[
    Private: Migrate configuration to new version
]]
function ConfigManager._migrateConfig(configData, fromVersion, toVersion)
    -- This would contain version-specific migration logic
    -- For now, we'll just update the version number
    configData.version = toVersion
    configData.migratedAt = os.time()
    configData.previousVersion = fromVersion

    return configData
end

--[[
    Private: Apply default values to config
]]
function ConfigManager._applyDefaults(configData, defaults)
    for key, defaultValue in pairs(defaults) do
        if configData[key] == nil then
            configData[key] = defaultValue
        elseif type(defaultValue) == "table" and type(configData[key]) == "table" then
            ConfigManager._applyDefaults(configData[key], defaultValue)
        end
    end
end

-- Initialize the config manager
ConfigManager.Initialize()

return ConfigManager