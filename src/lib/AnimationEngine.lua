--[[
    Animation Engine
    Smooth animations with 30+ easing functions and performance optimization

    @author Advanced UI Library Team
    @version 1.0.0
--]]

local AnimationEngine = {}
AnimationEngine.__index = AnimationEngine

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Animation registry
local activeAnimations = {}
local animationId = 0

-- Easing functions
local EasingFunctions = {
    Linear = function(t) return t end,
    QuadIn = function(t) return t * t end,
    QuadOut = function(t) return t * (2 - t) end,
    QuadInOut = function(t) return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t end,
    CubicIn = function(t) return t * t * t end,
    CubicOut = function(t) return 1 + (t - 1) ^ 3 end,
    CubicInOut = function(t) return t < 0.5 and 4 * t * t * t or (t - 1) * (2 * t - 2) * (2 * t - 2) + 1 end,
    QuartIn = function(t) return t * t * t * t end,
    QuartOut = function(t) return 1 - (t - 1) ^ 4 end,
    QuartInOut = function(t) return t < 0.5 and 8 * t * t * t * t else 1 - 8 * (t - 1) ^ 4 end,
    QuintIn = function(t) return t * t * t * t * t end,
    QuintOut = function(t) return 1 + (t - 1) ^ 5 end,
    QuintInOut = function(t) return t < 0.5 and 16 * t * t * t * t * t else 1 + 16 * (t - 1) ^ 5 end,
    SineIn = function(t) return 1 - math.cos((t * math.pi) / 2) end,
    SineOut = function(t) return math.sin((t * math.pi) / 2) end,
    SineInOut = function(t) return -(math.cos(math.pi * t) - 1) / 2 end,
    ExpoIn = function(t) return t == 0 and 0 or 2 ^ (10 * t - 10) end,
    ExpoOut = function(t) return t == 1 and 1 or 1 - 2 ^ (-10 * t) end,
    ExpoInOut = function(t) return t == 0 and 0 or t == 1 and 1 or t < 0.5 and 2 ^ (20 * t - 10) / 2 else (2 - 2 ^ (-20 * t + 10)) / 2 end,
    CircIn = function(t) return 1 - math.sqrt(1 - t ^ 2) end,
    CircOut = function(t) return math.sqrt(1 - (t - 1) ^ 2) end,
    CircInOut = function(t) return t < 0.5 and (1 - math.sqrt(1 - 4 * t ^ 2)) / 2 else (math.sqrt(1 - (-2 * t + 2) ^ 2) + 1) / 2 end,
    BackIn = function(t) local c1 = 1.70158; local c3 = c1 + 1; return c3 * t * t * t - c1 * t * t end,
    BackOut = function(t) local c1 = 1.70158; local c3 = c1 + 1; return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2 end,
    BackInOut = function(t) local c1 = 1.70158; local c2 = c1 * 1.525; return t < 0.5 and (4 * t * t * ((c2 + 1) * 2 * t - c2)) / 2 else (4 * (t - 2) * t * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2 end,
    ElasticIn = function(t) local c4 = (2 * math.pi) / 3; return t == 0 and 0 or t == 1 and 1 or -2 ^ (10 * t - 10) * math.sin((t * 10 - 10.75) * c4) end,
    ElasticOut = function(t) local c4 = (2 * math.pi) / 3; return t == 0 and 0 or t == 1 and 1 else 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1 end,
    ElasticInOut = function(t) local c5 = (2 * math.pi) / 4.5; return t == 0 and 0 or t == 1 and 1 or t < 0.5 and -(2 ^ (20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2 else (2 ^ (-20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 + 1 end,
    BounceIn = function(t) return 1 - AnimationEngine.BounceOut(1 - t) end,
    BounceOut = function(t)
        local n1 = 7.5625
        local d1 = 2.75
        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            t = t - 1.5 / d1
            return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then
            t = t - 2.25 / d1
            return n1 * t * t + 0.9375
        else
            t = t - 2.625 / d1
            return n1 * t * t + 0.984375
        end
    end,
    BounceInOut = function(t) return t < 0.5 and (1 - AnimationEngine.BounceOut(1 - 2 * t)) / 2 or (1 + AnimationEngine.BounceOut(2 * t - 1)) / 2 end
}

-- Performance settings
local isMobile = UserInputService.TouchEnabled
local maxConcurrentAnimations = isMobile and 20 or 50

--[[
    Create a simple property animation
]]
function AnimationEngine.Tween(object, properties, duration, easing, callback)
    local easingFunction = EasingFunctions[easing] or EasingFunctions.QuadOut
    local startTime = tick()
    local startValues = {}

    -- Capture start values
    for property, _ in pairs(properties) do
        if object[property] then
            startValues[property] = object[property]
        end
    end

    -- Create animation
    local animId = animationId + 1
    animationId = animId

    local animation = {
        id = animId,
        object = object,
        properties = properties,
        startValues = startValues,
        duration = duration,
        easingFunction = easingFunction,
        startTime = startTime,
        callback = callback,
        completed = false
    }

    activeAnimations[animId] = animation

    -- Performance check
    if #activeAnimations > maxConcurrentAnimations then
        AnimationEngine._cleanupCompletedAnimations()
    end

    return animation
end

--[[
    Create hover animation
]]
function AnimationEngine.Hover(object, targetColor, duration)
    local currentColor = object.BackgroundColor3
    local animation = AnimationEngine.Tween(
        object,
        {BackgroundColor3 = targetColor},
        duration,
        "QuadOut"
    )
    return animation
end

--[[
    Create unhover animation
]]
function AnimationEngine.Unhover(object, originalColor, duration)
    local animation = AnimationEngine.Tween(
        object,
        {BackgroundColor3 = originalColor},
        duration,
        "QuadOut"
    )
    return animation
end

--[[
    Create scale animation
]]
function AnimationEngine.Scale(object, targetScale, duration, easing)
    local animation = AnimationEngine.Tween(
        object,
        {Size = UDim2.new(targetScale, object.Size.X.Offset, targetScale, object.Size.Y.Offset)},
        duration,
        easing or "QuadOut"
    )
    return animation
end

--[[
    Create fade animation
]]
function AnimationEngine.Fade(object, targetTransparency, duration, easing)
    local animation = AnimationEngine.Tween(
        object,
        {BackgroundTransparency = targetTransparency},
        duration,
        easing or "QuadOut"
    )
    return animation
end

--[[
    Create slide animation
]]
function AnimationEngine.Slide(object, targetPosition, duration, easing)
    local animation = AnimationEngine.Tween(
        object,
        {Position = targetPosition},
        duration,
        easing or "QuadOut"
    )
    return animation
end

--[[
    Create rotation animation
]]
function AnimationEngine.Rotate(object, targetRotation, duration, easing)
    local animation = AnimationEngine.Tween(
        object,
        {Rotation = targetRotation},
        duration,
        easing or "QuadOut"
    )
    return animation
end

--[[
    Create color transition animation
]]
function AnimationEngine.ColorTransition(object, targetColor, duration, easing)
    local animation = AnimationEngine.Tween(
        object,
        {BackgroundColor3 = targetColor},
        duration,
        easing or "QuadOut"
    )
    return animation
end

--[[
    Create stagger animation for multiple objects
]]
function AnimationEngine.Stagger(objects, properties, duration, staggerDelay, easing)
    local animations = {}
    local individualDuration = duration - (#objects - 1) * staggerDelay

    if individualDuration <= 0 then
        individualDuration = duration / #objects
        staggerDelay = 0
    end

    for i, object in ipairs(objects) do
        local delay = (i - 1) * staggerDelay
        local animation = AnimationEngine.Tween(
            object,
            properties,
            individualDuration,
            easing or "QuadOut"
        )
        animation.delay = delay
        table.insert(animations, animation)
    end

    return animations
end

--[[
    Create sequence animation
]]
function AnimationEngine.Sequence(animations)
    local sequenceAnimations = {}
    local currentTime = 0

    for i, animData in ipairs(animations) do
        local delay = animData.delay or 0
        local duration = animData.duration or 0.3
        local totalDelay = currentTime + delay

        local animation = AnimationEngine.Tween(
            animData.object,
            animData.properties,
            duration,
            animData.easing or "QuadOut",
            animData.callback
        )

        animation.delay = totalDelay
        table.insert(sequenceAnimations, animation)

        currentTime = totalDelay + duration
    end

    return sequenceAnimations
end

--[[
    Stop animation
]]
function AnimationEngine.Stop(animation)
    if animation and not animation.completed then
        animation.completed = true
        activeAnimations[animation.id] = nil
    end
end

--[[
    Stop all animations
]]
function AnimationEngine.StopAll()
    for _, animation in pairs(activeAnimations) do
        animation.completed = true
    end
    activeAnimations = {}
end

--[[
    Get active animation count
]]
function AnimationEngine.GetActiveAnimationCount()
    local count = 0
    for _ in pairs(activeAnimations) do
        count = count + 1
    end
    return count
end

--[[
    Update animations (called every frame)
]]
function AnimationEngine.Update()
    local currentTime = tick()
    local completedAnimations = {}

    for animId, animation in pairs(activeAnimations) do
        if animation.completed then
            table.insert(completedAnimations, animId)
        else
            local elapsed = currentTime - animation.startTime - (animation.delay or 0)

            if elapsed >= 0 then
                local progress = math.min(elapsed / animation.duration, 1)
                local easedProgress = animation.easingFunction(progress)

                -- Update properties
                for property, targetValue in pairs(animation.properties) do
                    local startValue = animation.startValues[property]

                    if startValue and typeof(targetValue) == typeof(startValue) then
                        if typeof(targetValue) == "UDim2" then
                            animation.object[property] = UDim2.new(
                                startValue.X.Scale + (targetValue.X.Scale - startValue.X.Scale) * easedProgress,
                                startValue.X.Offset + (targetValue.X.Offset - startValue.X.Offset) * easedProgress,
                                startValue.Y.Scale + (targetValue.Y.Scale - startValue.Y.Scale) * easedProgress,
                                startValue.Y.Offset + (targetValue.Y.Offset - startValue.Y.Offset) * easedProgress
                            )
                        elseif typeof(targetValue) == "Color3" then
                            animation.object[property] = Color3.new(
                                startValue.R + (targetValue.R - startValue.R) * easedProgress,
                                startValue.G + (targetValue.G - startValue.G) * easedProgress,
                                startValue.B + (targetValue.B - startValue.B) * easedProgress
                            )
                        elseif typeof(targetValue) == "number" then
                            animation.object[property] = startValue + (targetValue - startValue) * easedProgress
                        end
                    end
                end

                -- Check completion
                if progress >= 1 then
                    animation.completed = true
                    table.insert(completedAnimations, animId)

                    if animation.callback then
                        animation.callback()
                    end
                end
            end
        end
    end

    -- Clean up completed animations
    for _, animId in ipairs(completedAnimations) do
        activeAnimations[animId] = nil
    end
end

--[[
    Private: Clean up completed animations
]]
function AnimationEngine._cleanupCompletedAnimations()
    local toRemove = {}
    for animId, animation in pairs(activeAnimations) do
        if animation.completed then
            table.insert(toRemove, animId)
        end
    end

    for _, animId in ipairs(toRemove) do
        activeAnimations[animId] = nil
    end
end

-- Connect update loop
RunService.Heartbeat:Connect(AnimationEngine.Update)

-- Export easing functions
AnimationEngine.EasingFunctions = EasingFunctions

return AnimationEngine