-- =================================================================
-- SMART GK AUTO SAVE - FIX JOYSTICK CAMERA ROTATION ISSUE
-- =================================================================

-- 1. LOAD THƯ VIỆN PITAYA UI
local PitayaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pitaya-real/PitayaUI/refs/heads/main/Pitayauisource.lua"))()

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
-- CẤU HÌNH & BIẾN TOÀN CỤC
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

-- ---------------------------------------------------------
-- 3. NHẬN DIỆN THIẾT BỊ (MOBILE VS PC)
-- ---------------------------------------------------------
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ---------------------------------------------------------
-- 4. KHỞI TẠO CỬA SỔ CHÍNH (PITAYA UI WINDOW)
-- ---------------------------------------------------------
local Window = PitayaUI:CreateWindow({
	Title = "Smart GK System | No Cam Drift",
	Logo = "rbxassetid://73866843639743",
	Theme = "PitayaUI",
	Font = "Gotham",
	Loading = true,
	LoadingTitle = "<b>Smart GK v4.2</b> Fixed Touch"
})

-- ---------------------------------------------------------
-- 5. CHÈN UI VÀO COREGUI / PLAYERGUI
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
-- 6. TẠO CÁC NÚT BẤM BÊN PHẢI (CHẮN CLICK SANG CAM)
-- ---------------------------------------------------------

local touchRegistry = {}

local function createSeamlessButton(name, text, pos, size, bgColor, onPress, onRelease)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = 0.3
    btn.ZIndex = 60
    btn.AutoButtonColor = false
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold
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

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            touchRegistry[input] = {
                btn = btn,
                onRelease = onRelease
            }
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

-- Nút Shift
createSeamlessButton("ShiftBtn", "Shift", UDim2.new(0.58, 0, 0.68, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(200, 100, 30), 
    function(btn)
        isSprinting = not isSprinting
        btn.BackgroundColor3 = isSprinting and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(200, 100, 30)
        VirtualInputManager:SendKeyEvent(isSprinting, Enum.KeyCode.LeftShift, false, game)
    end, nil
)

-- Nút Nhảy
createSeamlessButton("JumpBtn", "Nhảy", UDim2.new(0.85, 0, 0.65, 0), UDim2.new(0, 68, 0, 68), Color3.fromRGB(40, 40, 40),
    function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end,
    function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end
)

-- Nút Bay người
createSeamlessButton("DiveBtn", "Bay người", UDim2.new(0.72, 0, 0.68, 0), UDim2.new(0, 64, 0, 64), Color3.fromRGB(30, 30, 30),
    function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game) end,
    function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game) end
)

-- Nút Sút
createSeamlessButton("ShootBtn", "Sút", UDim2.new(0.74, 0, 0.45, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(30, 30, 30),
    function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0) end,
    function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0) end
)

-- Nút Chuyền
createSeamlessButton("PassBtn", "Chuyền", UDim2.new(0.85, 0, 0.42, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(30, 30, 30),
    function() VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0) end,
    function() VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0) end
)

-- ---------------------------------------------------------
-- JOYSTICK CHỐNG BỊ XOAY CAMERA (ISOLATED INPUT)
-- ---------------------------------------------------------
local moveVector = Vector2.zero
local joystickTouchObject = nil

local TouchBase = Instance.new("ImageButton")
TouchBase.Name = "JoystickBase"
TouchBase.Size = UDim2.new(0, 140, 0, 140)
TouchBase.Position = UDim2.new(0.05, 0, 0.50, 0)
TouchBase.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TouchBase.BackgroundTransparency = 0.5
TouchBase.ZIndex = 60
TouchBase.Active = true -- Khóa không cho sự kiện chạm xuyên xuống Camera
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
Thumb.Size = UDim2.new(0, 54, 0, 54)
Thumb.Position = UDim2.new(0.5, -27, 0.5, -27)
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
    Thumb.Position = UDim2.new(0.5, -27, 0.5, -27)
end

TouchBase.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and not joystickTouchObject then
        joystickTouchObject = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if joystickTouchObject and input == joystickTouchObject then
        local baseCenter = TouchBase.AbsolutePosition + (TouchBase.AbsoluteSize / 2)
        local inputPos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = inputPos - baseCenter
        local radius = TouchBase.AbsoluteSize.X / 2
        
        if delta.Magnitude > radius then
            delta = delta.Unit * radius
        end

        Thumb.Position = UDim2.new(0.5, delta.X - 27, 0.5, delta.Y - 27)
        moveVector = delta / radius
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == joystickTouchObject then
        resetJoystick()
    end
end)

-- ---------------------------------------------------------
-- 7. TAB TRÊN PITAYA UI
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

-- TAB VISUALS
local VisualTab = Window:CreateTab("Hiển Thị", "👁️")

VisualTab:AddLabel("--- ESP Tinh Gọn (Minimalist) ---", {BoldText = true})

VisualTab:AddToggle({
	Text = "ESP Trái Bóng (Mini Ball Marker)",
	BoldText = true,
	Default = false,
	Callback = function(state)
		espBallEnabled = state
		Window:Notify("ESP", "ESP Bóng: " .. (state and "<b>ĐÃ BẬT</b>" or "<b>ĐÃ TẮT</b>"), 2)
	end
})

VisualTab:AddToggle({
	Text = "ESP Cầu Thủ (Leaderboard Team ESP)",
	BoldText = true,
	Default = false,
	Callback = function(state)
		espPlayersEnabled = state
		Window:Notify("ESP", "ESP Cầu Thủ: " .. (state and "<b>ĐÃ BẬT</b>" or "<b>ĐÃ TẮT</b>"), 2)
	end
})

-- TAB CONTROLS
local ControlsTab = Window:CreateTab("Điều Khiển", "🎮")

ControlsTab:AddLabel("--- Phím Tắt Ảo Mobile ---", {BoldText = true})

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

ControlsTab:AddButton({
	Text = "Reset Vị Trí Joystick",
	BoldText = true,
	Callback = function()
		resetJoystick()
		Window:Notify("Hệ Thống", "Đã đặt lại Joystick!", 2)
	end
})

-- ---------------------------------------------------------
-- 8. TỰ ĐỘNG ẨN GIAO DIỆN GAME GỐC
-- ---------------------------------------------------------
task.spawn(function()
    local pGui = LocalPlayer:WaitForChild("PlayerGui")
    local function hideGameGuis()
        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") and not gui.Name:find("Protect") and gui.Name ~= "PitayaUI" then
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
-- 9. HÀM HỖ TRỢ GAMEPLAY & PHÂN TEAM
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

local function getPlayerTeam(player)
    if not player then return nil end
    if player.Team then return player.Team.Name end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local teamVal = leaderstats:FindFirstChild("Team") or leaderstats:FindFirstChild("Đội")
        if teamVal then return tostring(teamVal.Value) end
    end
    
    local customTeam = player:FindFirstChild("TeamValue") or player:FindFirstChild("TeamName")
    if customTeam then return tostring(customTeam.Value) end

    return "NoTeam"
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
-- 10. HỆ THỐNG ESP MINIMALIST
-- ---------------------------------------------------------

local function createCleanPlayerESP(player)
    local bg = Instance.new("BillboardGui")
    bg.Name = "CleanPlayerESP"
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 100, 0, 24)
    bg.ExtentsOffset = Vector3.new(0, 2.5, 0)

    local txt = Instance.new("TextLabel")
    txt.Name = "ESPLabel"
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = player.DisplayName .. "\n[0m]"
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 10
    txt.TextStrokeTransparency = 0.2
    txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    txt.Parent = bg

    return bg
end

local function createCleanBallESP()
    local bg = Instance.new("BillboardGui")
    bg.Name = "CleanBallESP"
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 80, 0, 20)
    bg.ExtentsOffset = Vector3.new(0, 1.8, 0)

    local txt = Instance.new("TextLabel")
    txt.Name = "BallLabel"
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = "⚽ BÓNG [0m]"
    txt.TextColor3 = Color3.fromRGB(255, 220, 50)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 11
    txt.TextStrokeTransparency = 0.2
    txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    txt.Parent = bg

    return bg
end

RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

    -- ESP Bóng
    local ball = getBall()
    if ball and espBallEnabled then
        local ballTargetPart = ball:IsA("Model") and (ball.PrimaryPart or ball:FindFirstChildWhichIsA("BasePart")) or ball
        if ballTargetPart then
            local ballGui = ballTargetPart:FindFirstChild("CleanBallESP")
            if not ballGui then
                ballGui = createCleanBallESP()
                ballGui.Parent = ballTargetPart
            end

            local highlight = ballTargetPart:FindFirstChild("BallHighlight")
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "BallHighlight"
                highlight.FillColor = Color3.fromRGB(255, 200, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.4
                highlight.Parent = ballTargetPart
            end

            if myHrp then
                local dist = math.floor((ballTargetPart.Position - myHrp.Position).Magnitude / 3)
                ballGui.BallLabel.Text = "⚽ BÓNG [" .. tostring(dist) .. "m]"
            end
        end
    else
        if ball then
            local ballTargetPart = ball:IsA("Model") and (ball.PrimaryPart or ball:FindFirstChildWhichIsA("BasePart")) or ball
            if ballTargetPart then
                if ballTargetPart:FindFirstChild("CleanBallESP") then ballTargetPart.CleanBallESP:Destroy() end
                if ballTargetPart:FindFirstChild("BallHighlight") then ballTargetPart.BallHighlight:Destroy() end
            end
        end
    end

    -- ESP Người chơi
    local myTeam = getPlayerTeam(LocalPlayer)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pChar = plr.Character
            local pHrp = pChar.HumanoidRootPart

            if espPlayersEnabled then
                local pGui = pHrp:FindFirstChild("CleanPlayerESP")
                if not pGui then
                    pGui = createCleanPlayerESP(plr)
                    pGui.Parent = pHrp
                end

                local plrTeam = getPlayerTeam(plr)
                local isTeammate = (myTeam ~= "NoTeam" and plrTeam ~= "NoTeam") and (myTeam == plrTeam)
                
                local teamColor = isTeammate and Color3.fromRGB(50, 180, 255) or Color3.fromRGB(255, 50, 50)
                pGui.ESPLabel.TextColor3 = teamColor

                local circle = pChar:FindFirstChild("TeamCircle")
                if not circle then
                    circle = Instance.new("Highlight")
                    circle.Name = "TeamCircle"
                    circle.FillTransparency = 0.6
                    circle.OutlineTransparency = 0.2
                    circle.Parent = pChar
                end
                circle.FillColor = teamColor
                circle.OutlineColor = teamColor

                if myHrp then
                    local dist = math.floor((pHrp.Position - myHrp.Position).Magnitude / 3)
                    pGui.ESPLabel.Text = plr.DisplayName .. "\n[" .. tostring(dist) .. "m]"
                end
            else
                if pHrp:FindFirstChild("CleanPlayerESP") then pHrp.CleanPlayerESP:Destroy() end
                if pChar:FindFirstChild("TeamCircle") then pChar.TeamCircle:Destroy() end
            end
        end
    end
end)

-- ---------------------------------------------------------
-- 11. VÒNG LẶP DI CHUYỂN & LOGIC GK
-- ---------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    -- Di chuyển bằng Joystick độc lập
    if isMobile and mobileControlsEnabled and joystickTouchObject and moveVector.Magnitude > 0.05 and hum then
        local camCFrame = Camera.CFrame
        local forward = camCFrame.LookVector
        local right = camCFrame.RightVector
        
        forward = Vector3.new(forward.X, 0, forward.Z).Unit
        right = Vector3.new(right.X, 0, right.Z).Unit
        
        local moveDirection = (right * moveVector.X) + (forward * (-moveVector.Y))
        hum:Move(moveDirection, false)
    end

    -- Tính vận tốc bóng
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

    -- Cam Lock Ball (Chỉ bật khi chọn toggle)
    if cameraTrackEnabled and ballPos then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, ballPos)
    end

    if not hrp or not hum then return end

    local goal = getDefendingGoal()
    local goalPos = goal and getPosition(goal)

    -- Auto Position
    if autoPositionEnabled and ballPos and goalPos and not joystickTouchObject and not isDiving then
        local distBallToGoal = (ballPos - goalPos).Magnitude
        if distBallToGoal <= CONFIG.POSITIONING_DIST then
            local targetPos = goalPos + (ballPos - goalPos).Unit * 6
            local moveDir = (targetPos - hrp.Position)
            
            if moveDir.Magnitude > 1.2 then
                hum:Move(moveDir.Unit, false)
            end
        end
    end

    -- Auto Save
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
