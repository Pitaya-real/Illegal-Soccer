-- =================================================================
-- SMART GK AUTO SAVE - ACCURATE DIVE & PREDICITON (v4.4 FIXED)
-- =================================================================

-- 1. LOAD THƯ VIỆN PITAYA UI
local PitayaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pitaya-real/PitayaUI/refs/heads/main/Pitayauisource.lua?v=" .. tick()))()

-- 2. KHỞI TẠO CÁC SERVICE ROBLOX
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ---------------------------------------------------------
-- CẤU HÌNH ĐÃ ĐƯỢC CÂN BẰNG LẠI CHUẨN XÁC
-- ---------------------------------------------------------
local CONFIG = {
    GOAL_DETECTION_DIST = 120,
    BALL_SAVE_DIST = 35,          -- Khoảng cách từ bóng đến khung thành để vào trạng thái báo động
    MIN_BALL_SPEED = 18,           -- Tốc độ bóng tối thiểu (Studs/s) mới tính là CÚ SÚT (Chống bay bậy khi bóng lăn chậm)
    PREDICTION_TIME = 0.25,        -- Thời gian dự đoán bóng tới
    COOLDOWN = 1.0,
    CATCH_RADIUS = 3.2,            -- Nếu bóng trong tầm tay thì không cần bay người
    POSITIONING_DIST = 45
}

local autoSaveEnabled = false
local cameraTrackEnabled = false
local autoPositionEnabled = false
local mobileControlsEnabled = true
local espBallEnabled = false
local practiceModeEnabled = true

local isDiving = false
local isSprinting = false

local lastBallPos = nil
local lastBallTime = 0
local ballVelocity = Vector3.zero

-- ---------------------------------------------------------
-- 3. NHẬN DIỆN THIẾT BỊ
-- ---------------------------------------------------------
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ---------------------------------------------------------
-- 4. PITAYA UI WINDOW
-- ---------------------------------------------------------
local Window = PitayaUI:CreateWindow({
	Title = "Smart GK System | Dynamic Fixed",
	Logo = "rbxassetid://73866843639743",
	Theme = "PitayaUI",
	Font = "Gotham",
	Loading = true,
	LoadingTitle = "<b>Smart GK v4.4</b> Fixed Auto Dive Logic"
})

-- ---------------------------------------------------------
-- 5. CHÈN UI CONTAINER
-- ---------------------------------------------------------
local parentContainer
if gethui then
    parentContainer = gethui()
elseif syn and syn.protect_gui then
    parentContainer = Instance.new("Folder")
    syn.protect_gui(parentContainer)
    parentContainer.Parent = CoreGui
else
    local success, _ = pcall(function() local a = CoreGui.Name end)
    if success then
        parentContainer = CoreGui
    else
        parentContainer = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local MobileControlsGui = Instance.new("ScreenGui")
MobileControlsGui.Name = "SmartGKMobileControls_Protect"
MobileControlsGui.ResetOnSpawn = false
MobileControlsGui.DisplayOrder = 9999
MobileControlsGui.Parent = parentContainer

if not isMobile then
    MobileControlsGui.Enabled = false
end

-- ---------------------------------------------------------
-- 6. TẠO CÁC NÚT BẤM CẢM ỨNG
-- ---------------------------------------------------------
local touchRegistry = {}

local function createSeamlessButton(name, text, pos, size, bgColor, onPress, onRelease)
    local btn = Instance.new("Frame")
    btn.Name = name
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = 0.3
    btn.ZIndex = 60
    btn.Parent = MobileControlsGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = btn

    local txtLabel = Instance.new("TextLabel")
    txtLabel.Size = UDim2.new(1, 0, 1, 0)
    txtLabel.BackgroundTransparency = 1
    txtLabel.Text = text
    txtLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    txtLabel.TextSize = 13
    txtLabel.Font = Enum.Font.SourceSansBold
    txtLabel.ZIndex = 61
    txtLabel.Parent = btn

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            touchRegistry[input] = { btn = btn, onRelease = onRelease }
            if onPress then onPress(btn) end
        end
    end)

    return btn
end

UserInputService.InputEnded:Connect(function(input)
    if touchRegistry[input] then
        local data = touchRegistry[input]
        if data.onRelease then data.onRelease(data.btn) end
        touchRegistry[input] = nil
    end
end)

createSeamlessButton("ShiftBtn", "Shift", UDim2.new(0.58, 0, 0.68, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(200, 100, 30), 
    function(btn)
        isSprinting = not isSprinting
        btn.BackgroundColor3 = isSprinting and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(200, 100, 30)
        VirtualInputManager:SendKeyEvent(isSprinting, Enum.KeyCode.LeftShift, false, game)
    end, nil
)

createSeamlessButton("JumpBtn", "Nhảy", UDim2.new(0.85, 0, 0.65, 0), UDim2.new(0, 68, 0, 68), Color3.fromRGB(40, 40, 40),
    function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end,
    function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end
)

createSeamlessButton("DiveBtn", "Bay người", UDim2.new(0.72, 0, 0.68, 0), UDim2.new(0, 64, 0, 64), Color3.fromRGB(30, 30, 30),
    function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game) end,
    function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game) end
)

createSeamlessButton("ShootBtn", "Sút", UDim2.new(0.74, 0, 0.45, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(30, 30, 30),
    function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0) end,
    function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0) end
)

createSeamlessButton("PassBtn", "Chuyền", UDim2.new(0.85, 0, 0.42, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(30, 30, 30),
    function() VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0) end,
    function() VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0) end
)

-- JOYSTICK KHÓA XOAY CAM
local moveVector = Vector2.zero
local joystickTouchObject = nil

local TouchBase = Instance.new("ImageButton")
TouchBase.Name = "JoystickBase"
TouchBase.Size = UDim2.new(0, 130, 0, 130)
TouchBase.Position = UDim2.new(0.05, 0, 0.52, 0)
TouchBase.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TouchBase.BackgroundTransparency = 0.5
TouchBase.ZIndex = 60
TouchBase.Active = true
TouchBase.Modal = true
TouchBase.AutoButtonColor = false
TouchBase.Image = ""
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

local function resetJoystick()
    joystickTouchObject = nil
    moveVector = Vector2.zero
    Thumb.Position = UDim2.new(0.5, -25, 0.5, -25)
end

TouchBase.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and not joystickTouchObject then
        joystickTouchObject = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if joystickTouchObject and (input == joystickTouchObject or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local baseCenter = TouchBase.AbsolutePosition + (TouchBase.AbsoluteSize / 2)
        local inputPos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = inputPos - baseCenter
        local radius = TouchBase.AbsoluteSize.X / 2
        
        if delta.Magnitude > radius then delta = delta.Unit * radius end
        Thumb.Position = UDim2.new(0.5, delta.X - 25, 0.5, delta.Y - 25)
        moveVector = delta / radius
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == joystickTouchObject or input.UserInputType == Enum.UserInputType.MouseButton1 then
        resetJoystick()
    end
end)

-- ---------------------------------------------------------
-- 7. PITAYA UI MENU
-- ---------------------------------------------------------
local GKTab = Window:CreateTab("Smart GK", "⚽")
GKTab:AddLabel("--- Tự Động Thủ Môn (v4.4 Fixed) ---", {BoldText = true})

GKTab:AddToggle({
	Text = "Chế Độ Tập Luyện (Practice Mode)",
	BoldText = true,
	Default = true,
	Callback = function(state)
		practiceModeEnabled = state
		Window:Notify("Smart GK", "Chế độ tập luyện: " .. (state and "<b>ĐÃ BẬT</b>" or "<b>ĐÃ TẮT</b>"), 2)
	end
})

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
	Text = "Tự Động Khép Góc Khung Thành",
	BoldText = true,
	Default = false,
	Callback = function(state)
		autoPositionEnabled = state
		Window:Notify("Smart GK", "Tự Khép Góc: " .. (state and "<b>ĐÃ BẬT</b>" or "<b>ĐÃ TẮT</b>"), 2)
	end
})

GKTab:AddToggle({
	Text = "Khóa Camera Vào Bóng (Cam Lock)",
	BoldText = true,
	Default = false,
	Callback = function(state)
		cameraTrackEnabled = state
		Window:Notify("Smart GK", "Cam Lock: " .. (state and "<b>ĐÃ BẬT</b>" or "<b>ĐÃ TẮT</b>"), 2)
	end
})

local VisualTab = Window:CreateTab("Hiển Thị", "👁️")
VisualTab:AddToggle({
	Text = "ESP Trái Bóng (Mini Ball Marker)",
	BoldText = true,
	Default = false,
	Callback = function(state) espBallEnabled = state end
})

local ControlsTab = Window:CreateTab("Điều Khiển", "🎮")
ControlsTab:AddToggle({
	Text = "Hiển Thị Nút Điều Khiển Mobile",
	BoldText = true,
	Default = isMobile,
	Callback = function(state)
		mobileControlsEnabled = state
		MobileControlsGui.Enabled = state and isMobile
		if not state then resetJoystick() end
	end
})

-- ---------------------------------------------------------
-- 8. TÌM BÓNG & KHUNG THÀNH CHÍNH XÁC
-- ---------------------------------------------------------
local function getPosition(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position
    elseif inst:IsA("Model") then 
        local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        return part and part.Position or inst:GetPivot().Position 
    end
    return nil
end

local function getBallPart(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

local function getBall()
    local char = LocalPlayer.Character
    local hrpPos = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position

    if practiceModeEnabled then
        local foundBalls = {}
        local searchFolders = {
            Workspace:FindFirstChild("Misc"),
            Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Misc")
        }

        for _, parentFolder in ipairs(searchFolders) do
            if parentFolder then
                local visuals = parentFolder:FindFirstChild("Visuals")
                if visuals then
                    for _, child in ipairs(visuals:GetChildren()) do
                        if string.find(child.Name, "ClientBall_Practice") then
                            local bPart = getBallPart(child)
                            if bPart then table.insert(foundBalls, bPart) end
                        end
                    end
                end
            end
        end

        if #foundBalls > 0 then
            if not hrpPos then return foundBalls[1] end
            local closestBall = nil
            local shortestDist = math.huge
            for _, bPart in ipairs(foundBalls) do
                local dist = (bPart.Position - hrpPos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestBall = bPart
                end
            end
            return closestBall
        end
    end

    local misc = Workspace:FindFirstChild("Misc")
    if misc then
        local visuals = misc:FindFirstChild("Visuals")
        if visuals then
            local mainBall = visuals:FindFirstChild("ClientBall_MainMatch")
            if mainBall then return getBallPart(mainBall) end
        end
    end
    return nil
end

local function getDefendingGoal()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrpPos = getPosition(char:FindFirstChild("HumanoidRootPart"))
    if not hrpPos then return nil end

    if practiceModeEnabled then
        local lobby = Workspace:FindFirstChild("Lobby")
        if lobby then
            local practice = lobby:FindFirstChild("Practice")
            if practice then
                local goalsFolder = practice:FindFirstChild("Goals")
                if goalsFolder then
                    local defence = goalsFolder:FindFirstChild("Defence")
                    if defence then
                        local goalMesh = defence:FindFirstChild("GoalMesh") or defence:FindFirstChild("Goal")
                        if goalMesh then return goalMesh end
                    end
                end
            end
        end
    end

    local map = Workspace:FindFirstChild("Map")
    if not map or not map:FindFirstChild("Data") then return nil end
    
    local closestGoal = nil
    local shortestDist = CONFIG.GOAL_DETECTION_DIST
    for _, teamName in ipairs({"Team1", "Team2"}) do
        local teamFolder = map.Data:FindFirstChild(teamName)
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

-- ---------------------------------------------------------
-- 9. THUẬT TOÁN BAY NGƯỜI CHUẨN XÁC HƯỚNG BÓNG (v4.4 FIXED)
-- ---------------------------------------------------------
local function performSmartDive(targetPos, isLeft, isRight, isHigh)
    if isDiving then return end
    isDiving = true
    
    task.spawn(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then isDiving = false return end

        -- 1. Xoay người đối diện trực diện với điểm bóng chuẩn bị tới
        local lookAtPos = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
        hrp.CFrame = CFrame.new(hrp.Position, lookAtPos)

        -- 2. Nhảy nếu bóng tầm cao
        if isHigh then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end

        -- 3. Xác định phím di chuyển chuẩn xác theo hướng bóng sang trái/phải
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
        
        -- Kích hoạt kỹ năng bay người bắt bóng (Phím E / Mouse)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.04)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        
        if dirKey then
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, dirKey, false, game)
        end
        
        task.wait(CONFIG.COOLDOWN)
        isDiving = false
    end)
end

-- ---------------------------------------------------------
-- 10. MAIN LOOP (RENDER STEPPED)
-- ---------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    -- Di chuyển bằng Joystick Mobile
    if isMobile and mobileControlsEnabled and joystickTouchObject and moveVector.Magnitude > 0.05 and hum then
        local camCFrame = Camera.CFrame
        local forward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
        local right = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit
        hum:Move((right * moveVector.X) + (forward * (-moveVector.Y)), false)
    end

    -- Tính toán vận tốc thực của bóng
    local ballPart = getBall()
    local ballPos = getPosition(ballPart)
    local now = tick()
    
    if ballPos and lastBallPos then
        local timeDiff = now - lastBallTime
        if timeDiff > 0 then
            ballVelocity = (ballPos - lastBallPos) / timeDiff
        end
    else
        ballVelocity = Vector3.zero
    end
    lastBallPos = ballPos
    lastBallTime = now

    -- Cam Lock
    if cameraTrackEnabled and ballPos then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, ballPos)
    end

    if not hrp or not hum then return end

    local goal = getDefendingGoal()
    local goalPos = goal and getPosition(goal)

    -- Auto Position (Khép góc khi bóng đi chậm hoặc được dẫn đến gần)
    if autoPositionEnabled and ballPos and goalPos and not joystickTouchObject and not isDiving then
        local distBallToGoal = (ballPos - goalPos).Magnitude
        if distBallToGoal <= CONFIG.POSITIONING_DIST then
            local targetPos = goalPos + (ballPos - goalPos).Unit * 5.5
            local moveDir = (targetPos - hrp.Position)
            if moveDir.Magnitude > 1.2 then
                hum:Move(moveDir.Unit, false)
            end
        end
    end

    -- Auto Save Logic (Tính toán cản phá cú sút)
    if autoSaveEnabled and ballPos and goalPos and not isDiving then
        local currentBallSpeed = ballVelocity.Magnitude

        -- KIỂM TRA 1: Bóng phải đang di chuyển nhanh (Đã được sút bóng thực sự)
        if currentBallSpeed >= CONFIG.MIN_BALL_SPEED then
            
            -- KIỂM TRA 2: Bóng đang bay HƯỚNG VỀ PHÍA KHUNG THÀNH
            local ballToGoalDir = (goalPos - ballPos).Unit
            local ballMoveDir = ballVelocity.Unit
            local isHeadingToGoal = ballMoveDir:Dot(ballToGoalDir) > 0.35 -- Góc nghiêng hợp lệ hướng về môn
            
            if isHeadingToGoal then
                local predictedBallPos = ballPos + (ballVelocity * CONFIG.PREDICTION_TIME)
                local distToGoal = (predictedBallPos - goalPos).Magnitude

                -- KIỂM TRA 3: Quỹ đạo nằm trong khoảng nguy hiểm của khung thành
                if distToGoal <= CONFIG.BALL_SAVE_DIST then
                    local relPos = hrp.CFrame:PointToObjectSpace(predictedBallPos)
                    local distToKeeper = (predictedBallPos - hrp.Position).Magnitude

                    -- Chỉ nhảy khi bóng nằm ngoài tầm với đứng yên
                    if distToKeeper > CONFIG.CATCH_RADIUS then
                        local isLeft = relPos.X < -1.5
                        local isRight = relPos.X > 1.5
                        local isHigh = relPos.Y > 2.5

                        performSmartDive(predictedBallPos, isLeft, isRight, isHigh)
                    end
                end
            end
        end
    end
end)
