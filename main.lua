-- =================================================================
-- SMART GK AUTO SAVE - OPTIMIZED WITH MODERN ESP & PITAYA UI
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
    PREDICTION_TIME = 0.28,
    COOLDOWN = 1.1,
    LEFT_RIGHT_THRESHOLD = 2.2,
    HIGH_SHOT_THRESHOLD = 3.0,
    CATCH_RADIUS = 3.8,
    POSITIONING_DIST = 45
}

local autoSaveEnabled = false
local cameraTrackEnabled = false
local autoPositionEnabled = false
local mobileControlsEnabled = true
local espBallEnabled = false
local espPlayersEnabled = false

local isDiving = false
local isSprinting = false

local lastBallPos = nil
local lastBallTime = 0
local ballVelocity = Vector3.zero

-- Container lưu trữ ESP Objects
local espObjects = {
    Ball = nil,
    Players = {}
}

-- ---------------------------------------------------------
-- 3. KHỞI TẠO CỬA SỔ CHÍNH (PITAYA UI WINDOW)
-- ---------------------------------------------------------
local Window = PitayaUI:CreateWindow({
	Title = "Smart GK System | Premium",
	Logo = "rbxassetid://73866843639743",
	Theme = "PitayaUI",
	Font = "Gotham",
	Loading = true,
	LoadingTitle = "<b>Smart GK v2.5</b> ESP Redesign"
})

-- ---------------------------------------------------------
-- 4. TẠO CÁC NÚT ĐIỀU KHIỂN ẢO DÀNH CHO MOBILE
-- ---------------------------------------------------------
local MobileControlsGui = Instance.new("ScreenGui")
MobileControlsGui.Name = "SmartGKMobileControls"
MobileControlsGui.ResetOnSpawn = false
MobileControlsGui.DisplayOrder = 9999
MobileControlsGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function createActionButton(name, text, pos, size, bgColor, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = size
    btn.Position = pos
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
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

-- Nút Shift (Chạy Nhanh)
createActionButton("ShiftBtn", "Shift", UDim2.new(0.58, 0, 0.68, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(200, 100, 30), function(btn)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isSprinting = not isSprinting
            btn.BackgroundColor3 = isSprinting and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(200, 100, 30)
            VirtualInputManager:SendKeyEvent(isSprinting, Enum.KeyCode.LeftShift, false, game)
        end
    end)
end)

-- Nút Nhảy
createActionButton("JumpBtn", "Nhảy", UDim2.new(0.85, 0, 0.65, 0), UDim2.new(0, 68, 0, 68), Color3.fromRGB(40, 40, 40), function(btn)
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
createActionButton("DiveBtn", "Bay người", UDim2.new(0.72, 0, 0.68, 0), UDim2.new(0, 64, 0, 64), Color3.fromRGB(30, 30, 30), function(btn)
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
createActionButton("ShootBtn", "Sút", UDim2.new(0.74, 0, 0.45, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(30, 30, 30), function(btn)
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
createActionButton("PassBtn", "Chuyền", UDim2.new(0.85, 0, 0.42, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(30, 30, 30), function(btn)
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

-- Joystick Cần Gạt
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
-- 5. TAB TRÊN PITAYA UI
-- ---------------------------------------------------------
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

-- TAB VISUALS (ESP MỚI)
local VisualTab = Window:CreateTab("Hiển Thị", "👁️")

VisualTab:AddLabel("--- Hệ Thống ESP Hiện Đại ---", {BoldText = true})

VisualTab:AddToggle({
	Text = "ESP Bóng Neon (Modern Ball ESP)",
	BoldText = true,
	Default = false,
	Callback = function(state)
		espBallEnabled = state
		Window:Notify("ESP", "ESP Bóng: " .. (state and "<b>ĐÃ BẬT</b>" or "<b>ĐÃ TẮT</b>"), 2)
	end
})

VisualTab:AddToggle({
	Text = "ESP Người Chơi UI (Modern Player ESP)",
	BoldText = true,
	Default = false,
	Callback = function(state)
		espPlayersEnabled = state
		Window:Notify("ESP", "ESP Người chơi: " .. (state and "<b>ĐÃ BẬT</b>" or "<b>ĐÃ TẮT</b>"), 2)
	end
})

-- TAB CONTROLS
local ControlsTab = Window:CreateTab("Điều Khiển", "🎮")

ControlsTab:AddLabel("--- Phím Tắt Ảo Mobile ---", {BoldText = true})

ControlsTab:AddToggle({
	Text = "Hiển Thị Nút Điều Khiển Mobile",
	BoldText = true,
	Default = true,
	Callback = function(state)
		mobileControlsEnabled = state
		MobileControlsGui.Enabled = state
		if not state then resetJoystick() end
	end
})

ControlsTab:AddButton({
	Text = "Reset Vị Trí Joystick",
	BoldText = true,
	Callback = function()
		resetJoystick()
		Window:Notify("Hệ Thống", "Đã đặt lại Joystick!", 2)
	end
})

-- ---------------------------------------------------------
-- 6. TỰ ĐỘNG ẨN GIAO DIỆN GAME GỐC
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
-- 7. HÀM HỖ TRỢ XỬ LÝ GAMEPLAY & TIM KIEM BONG
-- ---------------------------------------------------------
local function getPosition(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position
    elseif inst:IsA("Model") then 
        return inst.PrimaryPart and inst.PrimaryPart.Position or inst:GetPivot().Position 
    end
    return nil
end

local function getBall()
    local misc = Workspace:FindFirstChild("Misc")
    if misc then
        local visuals = misc:FindFirstChild("Visuals")
        if visuals then
            local mainBall = visuals:FindFirstChild("ClientBall_MainMatch")
            if mainBall then
                if mainBall:IsA("BasePart") then return mainBall end
                if mainBall:IsA("Model") then
                    return mainBall.PrimaryPart or mainBall:FindFirstChildWhichIsA("BasePart") or mainBall
                end
            end
            return visuals:FindFirstChildWhichIsA("BasePart")
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
            task.wait(0.03)
        end

        local dirKey = nil
        if isLeft then dirKey = Enum.KeyCode.A
        elseif isRight then dirKey = Enum.KeyCode.D end

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

-- ---------------------------------------------------------
-- 8. HỆ THỐNG ESP BÓNG & NGƯỜI CHƠI HYBRID HIỆN ĐẠI
-- ---------------------------------------------------------

-- Hàm tạo ESP UI hiện đại cho Người Chơi
local function createPlayerESP(player)
    local bg = Instance.new("BillboardGui")
    bg.Name = "ModernPlayerESP"
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 140, 0, 60)
    bg.ExtentsOffset = Vector3.new(0, 3, 0)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.Parent = bg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Name = "BorderStroke"
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 11
    nameLabel.Parent = frame

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distLabel.Position = UDim2.new(0, 0, 0.4, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 10
    distLabel.Parent = frame

    local hpBack = Instance.new("Frame")
    hpBack.Size = UDim2.new(0.85, 0, 0, 4)
    hpBack.Position = UDim2.new(0.075, 0, 0.78, 0)
    hpBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBack.BorderSizePixel = 0
    hpBack.Parent = frame

    local hpBar = Instance.new("Frame")
    hpBar.Name = "HPBar"
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = hpBack

    return bg
end

-- Hàm tạo ESP UI hiện đại cho Trái Bóng
local function createBallESP()
    local bg = Instance.new("BillboardGui")
    bg.Name = "ModernBallESP"
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 80, 0, 45)
    bg.ExtentsOffset = Vector3.new(0, 2, 0)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.4
    frame.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
    frame.Parent = bg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = frame

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 0.5, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "⚽ BÓNG"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 11
    icon.Parent = frame

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(255, 230, 230)
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = 10
    distLabel.Parent = frame

    return bg
end

-- Vòng lặp cập nhật ESP realtime
RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

    -- 1. XỬ LÝ ESP BÓNG
    local ball = getBall()
    if ball and espBallEnabled then
        local ballTargetPart = ball:IsA("Model") and (ball.PrimaryPart or ball:FindFirstChildWhichIsA("BasePart")) or ball
        if ballTargetPart then
            local ballGui = ballTargetPart:FindFirstChild("ModernBallESP")
            if not ballGui then
                ballGui = createBallESP()
                ballGui.Parent = ballTargetPart
            end

            -- Cập nhật Highlight cho bóng
            local ballHighlight = ballTargetPart:FindFirstChild("BallHighlight")
            if not ballHighlight then
                ballHighlight = Instance.new("Highlight")
                ballHighlight.Name = "BallHighlight"
                ballHighlight.FillColor = Color3.fromRGB(255, 50, 50)
                ballHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                ballHighlight.FillTransparency = 0.2
                ballHighlight.Parent = ballTargetPart
            end

            if myHrp then
                local dist = math.floor((ballTargetPart.Position - myHrp.Position).Magnitude / 3)
                ballGui.Frame.DistLabel.Text = tostring(dist) .. "m"
            end
        end
    else
        if ball then
            local ballTargetPart = ball:IsA("Model") and (ball.PrimaryPart or ball:FindFirstChildWhichIsA("BasePart")) or ball
            if ballTargetPart then
                if ballTargetPart:FindFirstChild("ModernBallESP") then ballTargetPart.ModernBallESP:Destroy() end
                if ballTargetPart:FindFirstChild("BallHighlight") then ballTargetPart.BallHighlight:Destroy() end
            end
        end
    end

    -- 2. XỬ LÝ ESP NGƯỜI CHƠI
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pChar = plr.Character
            local pHrp = pChar.HumanoidRootPart
            local pHum = pChar:FindFirstChildOfClass("Humanoid")

            if espPlayersEnabled and pHum and pHum.Health > 0 then
                local pGui = pHrp:FindFirstChild("ModernPlayerESP")
                if not pGui then
                    pGui = createPlayerESP(plr)
                    pGui.Parent = pHrp
                end

                -- Phân biệt Đội Bóng & Màu Sắc
                local isTeammate = (plr.Team == LocalPlayer.Team) and (LocalPlayer.Team ~= nil)
                local mainColor = isTeammate and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(255, 60, 60)
                
                pGui.Frame.BorderStroke.Color = mainColor
                pGui.Frame.NameLabel.TextColor3 = mainColor

                -- Tính khoảng cách
                if myHrp then
                    local dist = math.floor((pHrp.Position - myHrp.Position).Magnitude / 3)
                    pGui.Frame.DistLabel.Text = tostring(dist) .. "m"
                end

                -- Cập nhật Thanh Máu
                local hpPercent = math.clamp(pHum.Health / pHum.MaxHealth, 0, 1)
                pGui.Frame.HPBack.HPBar.Size = UDim2.new(hpPercent, 0, 1, 0)
            else
                if pHrp:FindFirstChild("ModernPlayerESP") then
                    pHrp.ModernPlayerESP:Destroy()
                end
            end
        end
    end
end)

-- ---------------------------------------------------------
-- 9. VÒNG LẶP RENDER STEPPED (XỬ LÝ GAMEPLAY CHÍNH)
-- ---------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    -- 1. Di chuyển bằng Joystick
    if mobileControlsEnabled and dragging and moveVector.Magnitude > 0.05 and hum then
        local camCFrame = Camera.CFrame
        local forward = camCFrame.LookVector
        local right = camCFrame.RightVector
        
        forward = Vector3.new(forward.X, 0, forward.Z).Unit
        right = Vector3.new(right.X, 0, right.Z).Unit
        
        local moveDirection = (right * moveVector.X) + (forward * (-moveVector.Y))
        hum:Move(moveDirection, false)
    end

    -- 2. Quỹ đạo bóng
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

    -- 3. Cam Lock Ball
    if cameraTrackEnabled and ballPos then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, ballPos)
    end

    if not hrp or not hum then return end

    local goal = getDefendingGoal()
    local goalPos = goal and getPosition(goal)

    -- 4. Auto Positioning
    if autoPositionEnabled and ballPos and goalPos and not dragging and not isDiving then
        local distBallToGoal = (ballPos - goalPos).Magnitude
        if distBallToGoal <= CONFIG.POSITIONING_DIST then
            local targetPos = goalPos + (ballPos - goalPos).Unit * 6
            local moveDir = (targetPos - hrp.Position)
            
            if moveDir.Magnitude > 1.2 then
                hum:Move(moveDir.Unit, false)
            end
        end
    end

    -- 5. Auto Save & Smart Dive
    if autoSaveEnabled and ballPos and goalPos then
        local predictedBallPos = ballPos + (ballVelocity * CONFIG.PREDICTION_TIME)
        local distToGoal = (predictedBallPos - goalPos).Magnitude
        
        if distToGoal <= CONFIG.BALL_SAVE_DIST and not isDiving then
            local relPos = hrp.CFrame:PointToObjectSpace(predictedBallPos)
            local totalDistToKeeper = (predictedBallPos - hrp.Position).Magnitude

            if totalDistToKeeper > CONFIG.CATCH_RADIUS then
                local isLeft = relPos.X < -CONFIG.LEFT_RIGHT_THRESHOLD
                local isRight = relPos.X > CONFIG.LEFT_RIGHT_THRESHOLD
                local isHigh = relPos.Y > CONFIG.HIGH_SHOT_THRESHOLD

                if isLeft or isRight or isHigh then
                    performSmartDive(predictedBallPos, isLeft, isRight, isHigh)
                end
            end
        end
    end
end)
