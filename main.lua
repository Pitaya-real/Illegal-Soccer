-- =================================================================
-- SMART GK AUTO SAVE - INTEGRATED WITH PITAYA UI
-- =================================================================

-- 1. LOAD THƯ VIỆN PITAYA UI
local PitayaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pitaya-real/PitayaUI/refs/heads/main/Pitayauisource.lua"))()

-- 2. KHỞI TẠO CÁC SERVICE ROBLOX
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ---------------------------------------------------------
-- CẤU HÌNH & BIẾN TOÀN CỤC CỦA HỆ THỐNG SMART GK
-- ---------------------------------------------------------
local CONFIG = {
    GOAL_DETECTION_DIST = 70,
    BALL_SAVE_DIST = 32,
    PREDICTION_TIME = 0.25,
    COOLDOWN = 1.2,
    LEFT_RIGHT_THRESHOLD = 1.8,
    HIGH_SHOT_THRESHOLD = 2.5
}

local autoSaveEnabled = false
local cameraTrackEnabled = false
local mobileControlsEnabled = true -- Biến quản lý bật/tắt nút điều khiển ảo
local isDiving = false

local lastBallPos = nil
local lastBallTime = 0
local ballVelocity = Vector3.zero

-- ---------------------------------------------------------
-- 3. KHỞI TẠO CỬA SỔ CHÍNH (PITAYA UI WINDOW)
-- ---------------------------------------------------------
local Window = PitayaUI:CreateWindow({
	Title = "Smart GK System | Pitaya Hub",
	Logo = "rbxassetid://73866843639743",
	Theme = "PitayaUI",
	Font = "Gotham",
	Loading = true,
	LoadingTitle = "<b>Smart GK System</b>"
})

-- ---------------------------------------------------------
-- 4. TẠO CÁC NÚT ĐIỀU KHIỂN ẢO DÀNH CHO MOBILE
-- ---------------------------------------------------------
local MobileControlsGui = Instance.new("ScreenGui")
MobileControlsGui.Name = "SmartGKMobileControls"
MobileControlsGui.ResetOnSpawn = false
MobileControlsGui.DisplayOrder = 9999
MobileControlsGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Hàm tạo Nút bấm bên phải
local function createActionButton(name, text, pos, size, bgColor, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = size
    btn.Position = pos
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.SourceSansBold
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = 0.25
    btn.ZIndex = 60
    btn.Active = true
    btn.Parent = MobileControlsGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = btn

    callback(btn)
    return btn
end

-- Nút Nhảy
createActionButton("JumpBtn", "Nhảy", UDim2.new(0.85, 0, 0.65, 0), UDim2.new(0, 70, 0, 70), Color3.fromRGB(40, 40, 40), function(btn)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end)
end)

-- Nút Bay người
createActionButton("DiveBtn", "Bay người", UDim2.new(0.68, 0, 0.68, 0), UDim2.new(0, 68, 0, 68), Color3.fromRGB(30, 30, 30), function(btn)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end)

-- Nút Sút
createActionButton("ShootBtn", "Sút", UDim2.new(0.72, 0, 0.45, 0), UDim2.new(0, 60, 0, 60), Color3.fromRGB(30, 30, 30), function(btn)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
    end)
end)

-- Nút Chuyền
createActionButton("PassBtn", "Chuyền", UDim2.new(0.85, 0, 0.42, 0), UDim2.new(0, 60, 0, 60), Color3.fromRGB(30, 30, 30), function(btn)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
        end
    end)
end)

-- Nút Joystick
local TouchBase = Instance.new("TextButton")
TouchBase.Name = "JoystickBase"
TouchBase.Size = UDim2.new(0, 130, 0, 130)
TouchBase.Position = UDim2.new(0.05, 0, 0.52, 0)
TouchBase.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TouchBase.BackgroundTransparency = 0.4
TouchBase.Text = ""
TouchBase.ZIndex = 60
TouchBase.Active = true
TouchBase.Parent = MobileControlsGui

local BaseCorner = Instance.new("UICorner")
BaseCorner.CornerRadius = UDim.new(1, 0)
BaseCorner.Parent = TouchBase

local BaseStroke = Instance.new("UIStroke")
BaseStroke.Color = Color3.fromRGB(255, 255, 255)
BaseStroke.Thickness = 2
BaseStroke.Transparency = 0.4
BaseStroke.Parent = TouchBase

local Thumb = Instance.new("Frame")
Thumb.Name = "JoystickThumb"
Thumb.Size = UDim2.new(0, 50, 0, 50)
Thumb.Position = UDim2.new(0.5, -25, 0.5, -25)
Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Thumb.BackgroundTransparency = 0.2
Thumb.ZIndex = 61
Thumb.Parent = TouchBase

local ThumbCorner = Instance.new("UICorner")
ThumbCorner.CornerRadius = UDim.new(1, 0)
ThumbCorner.Parent = Thumb

local moveVector = Vector2.zero
local dragging = false
local touchInputObject = nil

local function resetJoystick()
    dragging = false
    touchInputObject = nil
    moveVector = Vector2.zero
    Thumb.Position = UDim2.new(0.5, -25, 0.5, -25)
end

TouchBase.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and not dragging then
        dragging = true
        touchInputObject = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input == touchInputObject or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local baseCenter = TouchBase.AbsolutePosition + (TouchBase.AbsoluteSize / 2)
        local inputPos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = inputPos - baseCenter
        local radius = TouchBase.AbsoluteSize.X / 2
        
        if delta.Magnitude > radius then
            delta = delta.Unit * radius
        end

        Thumb.Position = UDim2.new(0.5, delta.X - 25, 0.5, delta.Y - 25)
        moveVector = delta / radius
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == touchInputObject or input.UserInputType == Enum.UserInputType.MouseButton1 then
        resetJoystick()
    end
end)

-- ---------------------------------------------------------
-- 5. ĐỊNH NGHĨA CÁC TAB TRÊN PITAYA UI
-- ---------------------------------------------------------

-- TAB 1: SMART GK (TỰ ĐỘNG BẮT BÓNG & CAMERA)
local GKTab = Window:CreateTab("Smart GK", "⚽")

GKTab:AddLabel("--- Tự Động Thủ Môn ---", {BoldText = true})

GKTab:AddToggle({
	Text = "Tự Động Bắt Bóng (Auto Save)",
	BoldText = true,
	Default = false,
	Callback = function(state)
		autoSaveEnabled = state
		Window:Notify("Smart GK", "Auto Save: " .. (state and "<b>ĐÃ BẬT</b>" or "<b>ĐÃ TẮT</b>"), 2)
	end
})

GKTab:AddToggle({
	Text = "Khóa Camera Vào Bóng (Cam Lock Ball)",
	BoldText = true,
	Default = false,
	Callback = function(state)
		cameraTrackEnabled = state
		Window:Notify("Smart GK", "Cam Lock Ball: " .. (state and "<b>ĐÃ BẬT</b>" or "<b>ĐÃ TẮT</b>"), 2)
	end
})

-- TAB 2: NÚT ĐIỀU KHIỂN (CONTROLS TOGGLE)
local ControlsTab = Window:CreateTab("Điều Khiển", "🎮")

ControlsTab:AddLabel("--- Phím Tắt Ảo Mobile ---", {BoldText = true})

-- NÚT BẬT/TẮT TOÀN BỘ CÁC NÚT ĐIỀU KHIỂNẢO
ControlsTab:AddToggle({
	Text = "Hiển Thị Nút Điều Khiển (Mobile Controls)",
	BoldText = true,
	Default = true,
	Callback = function(state)
		mobileControlsEnabled = state
		MobileControlsGui.Enabled = state
		if not state then
			resetJoystick()
		end
		Window:Notify("Điều Khiển", "Các nút điều khiển: " .. (state and "<b>ĐÃ HIỆN</b>" or "<b>ĐÃ ẨN</b>"), 2)
	end
})

ControlsTab:AddButton({
	Text = "Căn Lại Vị Trí Joystick",
	BoldText = true,
	Callback = function()
		resetJoystick()
		Window:Notify("Hệ Thống", "Đã reset lại vị trí cần gạt Joystick!", 2)
	end
})

-- TAB 3: CÀI ĐẶT UI (SETTINGS)
local SettingsTab = Window:CreateTab("Cài Đặt", "⚙️")

SettingsTab:AddLabel("--- Tùy Chỉnh UI ---", {BoldText = true})

SettingsTab:AddDropdown({
	Text = "Chủ Đề",
	BoldText = true,
	Items = Window:GetThemes(),
	Default = "PitayaUI",
	Callback = function(selectedTheme)
		Window:SetTheme(selectedTheme)
		Window:Notify("Theme", "Đã chuyển giao diện sang: <b>" .. selectedTheme .. "</b>", 2)
	end
})

SettingsTab:AddDropdown({
	Text = "Phông Chữ",
	BoldText = true,
	Items = Window:GetFonts(),
	Default = "Gotham",
	Callback = function(selectedFont)
		Window:SetFont(selectedFont)
		Window:Notify("Phông Chữ", "Đã cập nhật Font: <b>" .. selectedFont .. "</b>", 2)
	end
})

-- ---------------------------------------------------------
-- 6. TỰ ĐỘNG ẨN GIAO DIỆN PHÍM TẮT MẶC ĐỊNH CỦA GAME GỐC
-- ---------------------------------------------------------
task.spawn(function()
    local pGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local function hideGameGuis()
        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "PitayaUI" and gui.Name ~= "SmartGKMobileControls" then
                for _, child in ipairs(gui:GetDescendants()) do
                    if child:IsA("GuiObject") then
                        local name = child.Name:lower()
                        if name:find("key") or name:find("bind") or name:find("pc") or name:find("control") then
                            child.Visible = false
                        end
                    end
                end
            end
        end
    end

    hideGameGuis()
    pGui.ChildAdded:Connect(function()
        task.wait(0.3)
        hideGameGuis()
    end)
end)

-- ---------------------------------------------------------
-- 7. LOGIC XỬ LÝ GAMEPLAY & VÒNG LẶP RENDER
-- ---------------------------------------------------------
local function getPosition(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") then
        return inst:GetPivot().Position
    end
    return nil
end

local function getBall()
    local misc = Workspace:FindFirstChild("Misc")
    if misc then
        local visuals = misc:FindFirstChild("Visuals")
        if visuals then
            return visuals:FindFirstChild("ClientBall_MainMatch") or visuals:FindFirstChildWhichIsA("BasePart")
        end
    end
    return nil
end

local function getDefendingGoal()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrpPos = getPosition(char:FindFirstChild("HumanoidRootPart"))
    if not hrpPos then return nil end
    local map = Workspace:FindFirstChild("Map")
    if not map or not map:FindFirstChild("Data") then return nil end
    local data = map.Data
    local closestGoal = nil
    local shortestDist = CONFIG.GOAL_DETECTION_DIST
    for _, teamName in ipairs({"Team1", "Team2"}) do
        local teamFolder = data:FindFirstChild(teamName)
        if teamFolder then
            local goalObj = teamFolder:FindFirstChild("GoalMesh") or teamFolder:FindFirstChild("Goal") or teamFolder:FindFirstChild("Goalkeeper")
            if goalObj then
                local gPos = getPosition(goalObj)
                if gPos then
                    local dist = (hrpPos - gPos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestGoal = goalObj
                    end
                end
            end
        end
    end
    return closestGoal
end

local function performSmartDive(predictedPos, isLeft, isRight, isHigh)
    if isDiving then return end
    isDiving = true
    task.spawn(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(predictedPos.X, hrp.Position.Y, predictedPos.Z))
        end
        if isHigh then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            task.wait(0.04)
        end
        local dirKey = nil
        if isLeft then
            dirKey = Enum.KeyCode.A
        elseif isRight then
            dirKey = Enum.KeyCode.D
        end
        if dirKey then
            VirtualInputManager:SendKeyEvent(true, dirKey, false, game)
            task.wait(0.02)
        end
        
        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
        
        if dirKey then
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, dirKey, false, game)
        end
        
        task.wait(CONFIG.COOLDOWN)
        isDiving = false
    end)
end

RunService.RenderStepped:Connect(function(dt)
    -- Di chuyển bằng Joystick (Chỉ hoạt động khi Joystick được bật)
    if mobileControlsEnabled and dragging and moveVector.Magnitude > 0.05 then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local camCFrame = Camera.CFrame
            local forward = camCFrame.LookVector
            local right = camCFrame.RightVector
            
            forward = Vector3.new(forward.X, 0, forward.Z).Unit
            right = Vector3.new(right.X, 0, right.Z).Unit
            
            local moveDirection = (right * moveVector.X) + (forward * (-moveVector.Y))
            hum:Move(moveDirection, false)
        end
    end

    local ball = getBall()
    local ballPos = getPosition(ball)
    local now = tick()
    
    if ballPos and lastBallPos then
        local timeDiff = now - lastBallTime
        if timeDiff > 0 then
            ballVelocity = (ballPos - lastBallPos) / timeDiff
        end
    end
    lastBallPos = ballPos
    lastBallTime = now
    
    -- Cam Lock Ball
    if cameraTrackEnabled and ballPos then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, ballPos)
    end
    
    -- Auto Save
    if autoSaveEnabled then
        local goal = getDefendingGoal()
        local ballObj = getBall()
        local ballPosObj = getPosition(ballObj)
        
        if goal and ballPosObj then
            local goalPos = getPosition(goal)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if goalPos and hrp then
                local predictedBallPos = ballPosObj + (ballVelocity * CONFIG.PREDICTION_TIME)
                local distToGoal = (predictedBallPos - goalPos).Magnitude
                
                if distToGoal <= CONFIG.BALL_SAVE_DIST and not isDiving then
                    local relativePos = hrp.CFrame:PointToObjectSpace(predictedBallPos)
                    
                    local isLeft = relativePos.X < -CONFIG.LEFT_RIGHT_THRESHOLD
                    local isRight = relativePos.X > CONFIG.LEFT_RIGHT_THRESHOLD
                    local isHigh = relativePos.Y > CONFIG.HIGH_SHOT_THRESHOLD
                    
                    performSmartDive(predictedBallPos, isLeft, isRight, isHigh)
                end
            end
        end
    end
end)
