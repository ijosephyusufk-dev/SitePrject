--[[
    Input Handler
    Unified input handling for mouse, keyboard, touch, and gamepad

    @author Advanced UI Library Team
    @version 1.0.0
--]]

local InputHandler = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

-- Input types
local INPUT_TYPES = {
    Mouse = "Mouse",
    Keyboard = "Keyboard",
    Touch = "Touch",
    Gamepad = "Gamepad"
}

-- Gesture recognition
local GESTURES = {
    Tap = "Tap",
    DoubleTap = "DoubleTap",
    LongPress = "LongPress",
    Swipe = "Swipe",
    Pinch = "Pinch"
}

-- Input state
local inputState = {
    currentInputs = {},
    gestures = {},
    lastTap = {},
    longPressTimers = {},
    swipeStart = nil
}

--[[
    Initialize input handler
]]
function InputHandler.Initialize()
    -- Connect input events
    UserInputService.InputBegan:Connect(InputHandler._onInputBegan)
    UserInputService.InputEnded:Connect(InputHandler._onInputEnded)
    UserInputService.InputChanged:Connect(InputHandler._onInputChanged)
    UserInputService.TouchLongPress:Connect(InputHandler._onTouchLongPress)
    UserInputService.TouchSwipe:Connect(InputHandler._onTouchSwipe)
    UserInputService.TouchPinch:Connect(InputHandler._onTouchPinch)
end

--[[
    Get input type
]]
function InputHandler.GetInputType(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.MouseButton2 or
       input.UserInputType == Enum.UserInputType.MouseButton3 or
       input.UserInputType == Enum.UserInputType.MouseMovement then
        return INPUT_TYPES.Mouse
    elseif input.UserInputType == Enum.UserInputType.Touch then
        return INPUT_TYPES.Touch
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        return INPUT_TYPES.Keyboard
    elseif string.find(tostring(input.UserInputType), "Gamepad") then
        return INPUT_TYPES.Gamepad
    end
    return "Unknown"
end

--[[
    Check if touch device
]]
function InputHandler.IsTouchDevice()
    return UserInputService.TouchEnabled
end

--[[
    Check if gamepad connected
]]
function InputHandler.IsGamepadConnected()
    for _, gamepad in ipairs(UserInputService:GetConnectedGamepads()) do
        if gamepad then
            return true
        end
    end
    return false
end

--[[
    Handle input began
]]
function InputHandler._onInputBegan(input, gameProcessedEvent)
    local inputType = InputHandler.GetInputType(input)

    -- Track input
    inputState.currentInputs[input.KeyCode] = {
        input = input,
        startTime = tick(),
        processed = gameProcessedEvent
    }

    -- Handle gestures
    if inputType == INPUT_TYPES.Touch then
        InputHandler._handleTouchBegan(input)
    end
end

--[[
    Handle input ended
]]
function InputHandler._onInputEnded(input, gameProcessedEvent)
    local inputType = InputHandler.GetInputType(input)

    -- Remove from tracking
    inputState.currentInputs[input.KeyCode] = nil

    -- Handle gestures
    if inputType == INPUT_TYPES.Touch then
        InputHandler._handleTouchEnded(input)
    end
end

--[[
    Handle input changed
]]
function InputHandler._onInputChanged(input, gameProcessedEvent)
    local inputType = InputHandler.GetInputType(input)

    if inputType == INPUT_TYPES.Touch then
        InputHandler._handleTouchChanged(input)
    end
end

--[[
    Handle touch began
]]
function InputHandler._handleTouchBegan(input)
    local position = input.Position
    local currentTime = tick()

    -- Check for double tap
    local lastTap = inputState.lastTap[input.UserInputType]
    if lastTap and (currentTime - lastTap.time) < 0.5 then
        InputHandler._triggerGesture(GESTURES.DoubleTap, position, input)
        inputState.lastTap[input.UserInputType] = nil
    else
        -- Record tap
        inputState.lastTap[input.UserInputType] = {
            time = currentTime,
            position = position
        }

        -- Setup long press timer
        local timer = spawn(function()
            wait(0.5)
            if inputState.currentInputs[input.UserInputType] then
                InputHandler._triggerGesture(GESTURES.LongPress, position, input)
            end
        end)
        inputState.longPressTimers[input.UserInputType] = timer

        -- Record swipe start
        inputState.swipeStart = {
            position = position,
            time = currentTime
        }
    end
end

--[[
    Handle touch ended
]]
function InputHandler._handleTouchEnded(input)
    local position = input.Position
    local currentTime = tick()

    -- Cancel long press timer
    if inputState.longPressTimers[input.UserInputType] then
        inputState.longPressTimers[input.UserInputType] = nil
    end

    -- Check for tap (if not long press)
    local swipeStart = inputState.swipeStart
    if swipeStart then
        local distance = (position - swipeStart.position).magnitude
        local duration = currentTime - swipeStart.time

        if distance < 10 and duration < 0.5 then
            InputHandler._triggerGesture(GESTURES.Tap, position, input)
        end

        inputState.swipeStart = nil
    end
end

--[[
    Handle touch changed
]]
function InputHandler._handleTouchChanged(input)
    -- Track movement for swipe detection
    if inputState.swipeStart then
        local position = input.Position
        local swipeStart = inputState.swipeStart
        local distance = (position - swipeStart.position).magnitude
        local duration = tick() - swipeStart.time

        -- Trigger swipe if moved far enough
        if distance > 50 and duration < 1 then
            local direction = (position - swipeStart.position).unit
            InputHandler._triggerGesture(GESTURES.Swipe, position, input, {direction = direction})
            inputState.swipeStart = nil
        end
    end
end

--[[
    Handle touch long press
]]
function InputHandler._onTouchLongPress(touchPositions, state, input)
    if state == Enum.UserInputState.Begin then
        InputHandler._triggerGesture(GESTURES.LongPress, touchPositions[1], input)
    end
end

--[[
    Handle touch swipe
]]
function InputHandler._onTouchSwipe(swipeDirection, numberOfTouches, input)
    InputHandler._triggerGesture(GESTURES.Swipe, input.Position, input, {direction = swipeDirection})
end

--[[
    Handle touch pinch
]]
function InputHandler._onTouchPinch(touchPositions, scale, input)
    InputHandler._triggerGesture(GESTURES.Pinch, touchPositions[1], input, {scale = scale})
end

--[[
    Trigger gesture event
]]
function InputHandler._triggerGesture(gestureType, position, input, extraData)
    local gestureData = {
        type = gestureType,
        position = position,
        input = input,
        extraData = extraData or {},
        timestamp = tick()
    }

    table.insert(inputState.gestures, gestureData)

    -- Emit gesture event (would integrate with event system)
    if _G.DEBUG_INPUT then
        print("InputHandler: Gesture detected", gestureType, position)
    end
end

--[[
    Get current input state
]]
function InputHandler.GetInputState()
    return {
        activeInputs = #inputState.currentInputs,
        touchEnabled = UserInputService.TouchEnabled,
        gamepadConnected = InputHandler.IsGamepadConnected(),
        mouseLocation = UserInputService.GetMouseLocation()
    }
end

-- Initialize the input handler
InputHandler.Initialize()

return InputHandler