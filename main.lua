--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.9) ~  Much Love, Ferib 

]]--

local v0 = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pitaya-real/PitayaUI/refs/heads/main/Pitayauisource.lua"))();
local v1 = game:GetService("Players");
local v2 = game:GetService("RunService");
local v3 = game:GetService("VirtualInputManager");
local v4 = game:GetService("UserInputService");
local v5 = game:GetService("Workspace");
local v6 = game:GetService("CoreGui");
local v7 = v1.LocalPlayer;
local v8 = v5.CurrentCamera;
local v9 = {GOAL_DETECTION_DIST=70,BALL_SAVE_DIST=35,PREDICTION_TIME=0.32,COOLDOWN=1,LEFT_RIGHT_THRESHOLD=2,HIGH_SHOT_THRESHOLD=2.5,CATCH_RADIUS=4.5,POSITIONING_DIST=45,MIN_BALL_SPEED=6,GRAVITY=196.2};
local v10 = false;
local v11 = false;
local v12 = false;
local v13 = true;
local v14 = false;
local v15 = false;
local v16 = false;
local v17 = false;
local v18 = nil;
local v19 = 0;
local v20 = Vector3.zero;
local v21 = v4.TouchEnabled and not v4.KeyboardEnabled;
local v22 = v0:CreateWindow({Title="Smart GK System | PITAYA HUB",Logo="rbxassetid://73866843639743",Theme="PitayaUI",Font="Gotham",Loading=true,LoadingTitle="<b>Smart GK BETA</b> PITAYA REAL"});
local v23;
if gethui then
	v23 = gethui();
elseif ((syn and syn.protect_gui) or (4593 <= 2672)) then
	v23 = Instance.new("Folder");
	syn.protect_gui(v23);
	v23.Parent = v6;
else
	local v219, v220 = pcall(function()
		local v227 = v6.Name;
	end);
	if v219 then
		v23 = v6;
	else
		v23 = v7:WaitForChild("PlayerGui");
	end
end
local v24 = Instance.new("ScreenGui");
v24.Name = "SmartGKMobileControls_Protect";
v24.ResetOnSpawn = false;
v24.DisplayOrder = 9999;
v24.Parent = v23;
if not v21 then
	v24.Enabled = false;
end
local v29 = {};
local function v30(v75, v76, v77, v78, v79, v80, v81)
	local v82 = Instance.new("Frame");
	v82.Name = v75;
	v82.Size = v78;
	v82.Position = v77;
	v82.BackgroundColor3 = v79;
	v82.BackgroundTransparency = 0.3;
	v82.ZIndex = 60;
	v82.Parent = v24;
	local v90 = Instance.new("UICorner");
	v90.CornerRadius = UDim.new(1, 0);
	v90.Parent = v82;
	local v93 = Instance.new("UIStroke");
	v93.Color = Color3.fromRGB(255, 255, 255);
	v93.Thickness = 2;
	v93.Transparency = 0.3;
	v93.Parent = v82;
	local v98 = Instance.new("TextLabel");
	v98.Size = UDim2.new(1, 0, 1, 0);
	v98.BackgroundTransparency = 1;
	v98.Text = v76;
	v98.TextColor3 = Color3.fromRGB(255, 255, 255);
	v98.TextSize = 13;
	v98.Font = Enum.Font.SourceSansBold;
	v98.ZIndex = 61;
	v98.Parent = v82;
	v82.InputBegan:Connect(function(v189)
		if ((v189.UserInputType == Enum.UserInputType.Touch) or (v189.UserInputType == Enum.UserInputType.MouseButton1) or (1168 > 3156)) then
			v29[v189] = {btn=v82,onRelease=v81};
			if (v80 or (572 > 4486)) then
				v80(v82);
			end
		end
	end);
	return v82;
end
v4.InputEnded:Connect(function(v108)
	if v29[v108] then
		local v198 = v29[v108];
		if v198.onRelease then
			v198.onRelease(v198.btn);
		end
		v29[v108] = nil;
	end
end);
v30("ShiftBtn", "Shift", UDim2.new(0.58, 0, 0.68, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(200, 100, 30), function(v109)
	v17 = not v17;
	v109.BackgroundColor3 = (v17 and Color3.fromRGB(50, 180, 50)) or Color3.fromRGB(200, 100, 30);
	v3:SendKeyEvent(v17, Enum.KeyCode.LeftShift, false, game);
end, nil);
v30("JumpBtn", "Nhảy", UDim2.new(0.85, 0, 0.65, 0), UDim2.new(0, 68, 0, 68), Color3.fromRGB(40, 40, 40), function()
	v3:SendKeyEvent(true, Enum.KeyCode.Space, false, game);
end, function()
	v3:SendKeyEvent(false, Enum.KeyCode.Space, false, game);
end);
v30("DiveBtn", "Bay người", UDim2.new(0.72, 0, 0.68, 0), UDim2.new(0, 64, 0, 64), Color3.fromRGB(30, 30, 30), function()
	v3:SendKeyEvent(true, Enum.KeyCode.E, false, game);
end, function()
	v3:SendKeyEvent(false, Enum.KeyCode.E, false, game);
end);
v30("ShootBtn", "Sút", UDim2.new(0.74, 0, 0.45, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(30, 30, 30), function()
	v3:SendMouseButtonEvent(0, 0, 0, true, game, 0);
end, function()
	v3:SendMouseButtonEvent(0, 0, 0, false, game, 0);
end);
v30("PassBtn", "Chuyền", UDim2.new(0.85, 0, 0.42, 0), UDim2.new(0, 58, 0, 58), Color3.fromRGB(30, 30, 30), function()
	v3:SendMouseButtonEvent(0, 0, 1, true, game, 0);
end, function()
	v3:SendMouseButtonEvent(0, 0, 1, false, game, 0);
end);
local v31 = Vector2.zero;
local v32 = nil;
local v33 = Instance.new("ImageButton");
v33.Name = "JoystickBase";
v33.Size = UDim2.new(0, 130, 0, 130);
v33.Position = UDim2.new(0.05, 0, 0.52, 0);
v33.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
v33.BackgroundTransparency = 0.5;
v33.ZIndex = 60;
v33.Active = true;
v33.Modal = true;
v33.AutoButtonColor = false;
v33.Image = "";
v33.Parent = v24;
local v45 = Instance.new("UICorner");
v45.CornerRadius = UDim.new(1, 0);
v45.Parent = v33;
local v48 = Instance.new("UIStroke");
v48.Color = Color3.fromRGB(255, 255, 255);
v48.Thickness = 2;
v48.Transparency = 0.4;
v48.Parent = v33;
local v53 = Instance.new("Frame");
v53.Name = "JoystickThumb";
v53.Size = UDim2.new(0, 50, 0, 50);
v53.Position = UDim2.new(0.5, -25, 0.5, -25);
v53.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
v53.BackgroundTransparency = 0.2;
v53.ZIndex = 61;
v53.Parent = v33;
local v61 = Instance.new("UICorner");
v61.CornerRadius = UDim.new(1, 0);
v61.Parent = v53;
local function v64()
	v32 = nil;
	v31 = Vector2.zero;
	v53.Position = UDim2.new(0.5, -25, 0.5, -25);
end
v33.InputBegan:Connect(function(v113)
	if ((1404 == 1404) and ((v113.UserInputType == Enum.UserInputType.Touch) or (v113.UserInputType == Enum.UserInputType.MouseButton1)) and not v32) then
		v32 = v113;
	end
end);
v4.InputChanged:Connect(function(v114)
	if ((v32 and ((v114 == v32) or (v114.UserInputType == Enum.UserInputType.MouseMovement))) or (3748 < 2212)) then
		local v200 = v33.AbsolutePosition + (v33.AbsoluteSize / 2);
		local v201 = Vector2.new(v114.Position.X, v114.Position.Y);
		local v202 = v201 - v200;
		local v203 = v33.AbsoluteSize.X / 2;
		if (v202.Magnitude > v203) then
			v202 = v202.Unit * v203;
		end
		v53.Position = UDim2.new(0.5, v202.X - 25, 0.5, v202.Y - 25);
		v31 = v202 / v203;
	end
end);
v4.InputEnded:Connect(function(v115)
	if ((v115 == v32) or (v115.UserInputType == Enum.UserInputType.MouseButton1) or (1180 == 2180)) then
		v64();
	end
end);
local v65 = v22:CreateTab("Smart GK", "⚽");
v65:AddLabel("--- Tự Động Thủ Môn ---", {BoldText=true});
v65:AddToggle({Text="Tự Động Bắt Bóng (Auto Save)",BoldText=true,Default=false,Callback=function(v116)
	v10 = v116;
	v22:Notify("Smart GK", "Auto Save: " .. ((v116 and "<b>ĐÃ BẬT</b>") or "<b>ĐÃ TẮT</b>"), 2);
end});
v65:AddToggle({Text="Tự Động Khép Góc Khung Thành",BoldText=true,Default=false,Callback=function(v117)
	v12 = v117;
	v22:Notify("Smart GK", "Tự Khép Góc: " .. ((v117 and "<b>ĐÃ BẬT</b>") or "<b>ĐÃ TẮT</b>"), 2);
end});
v65:AddToggle({Text="Khóa Camera Vào Bóng (Cam Lock)",BoldText=true,Default=false,Callback=function(v118)
	v11 = v118;
	v22:Notify("Smart GK", "Cam Lock: " .. ((v118 and "<b>ĐÃ BẬT</b>") or "<b>ĐÃ TẮT</b>"), 2);
end});
local v66 = v22:CreateTab("Hiển Thị", "👁️");
v66:AddLabel("--- ESP Tinh Gọn (Minimalist) ---", {BoldText=true});
v66:AddToggle({Text="ESP Trái Bóng (Mini Ball Marker)",BoldText=true,Default=false,Callback=function(v119)
	v14 = v119;
	v22:Notify("ESP", "ESP Bóng: " .. ((v119 and "<b>ĐÃ BẬT</b>") or "<b>ĐÃ TẮT</b>"), 2);
end});
v66:AddToggle({Text="ESP Cầu Thủ (Leaderboard Team ESP)",BoldText=true,Default=false,Callback=function(v120)
	v15 = v120;
	v22:Notify("ESP", "ESP Cầu Thủ: " .. ((v120 and "<b>ĐÃ BẬT</b>") or "<b>ĐÃ TẮT</b>"), 2);
end});
local v67 = v22:CreateTab("Điều Khiển", "🎮");
v67:AddLabel("--- Phím Tắt Ảo Mobile ---", {BoldText=true});
v67:AddToggle({Text="Hiển Thị Nút Điều Khiển Mobile",BoldText=true,Default=v21,Callback=function(v121)
	v13 = v121;
	v24.Enabled = v121 and v21;
	if ((4090 < 4653) and not v121) then
		v64();
	end
end});
v67:AddButton({Text="Reset Vị Trí Joystick",BoldText=true,Callback=function()
	v64();
	v22:Notify("Hệ Thống", "Đã đặt lại Joystick!", 2);
end});
task.spawn(function()
	local v123 = v7:WaitForChild("PlayerGui");
	local function v124()
		for v205, v206 in ipairs(v123:GetChildren()) do
			if ((v206:IsA("ScreenGui") and not v206.Name:find("Protect") and (v206.Name ~= "PitayaUI")) or (2652 < 196)) then
				for v236, v237 in ipairs(v206:GetDescendants()) do
					if v237:IsA("GuiObject") then
						local v259 = v237.Name:lower();
						if ((4135 < 4817) and (v259:find("key") or v259:find("bind") or v259:find("pc") or v259:find("control"))) then
							v237.Visible = false;
						end
					end
				end
			end
		end
	end
	v124();
	v123.ChildAdded:Connect(function()
		task.wait(0.3);
		v124();
	end);
end);
local function v68(v125)
	if ((272 == 272) and not v125) then
		return nil;
	end
	if ((100 <= 3123) and v125:IsA("BasePart")) then
		return v125.Position;
	elseif v125:IsA("Model") then
		return (v125.PrimaryPart and v125.PrimaryPart.Position) or v125:GetPivot().Position;
	end
	return nil;
end
local function v69()
	local v126 = v5:FindFirstChild("Misc");
	if v126 then
		local v207 = v126:FindFirstChild("Visuals");
		if (v207 or (1369 > 4987)) then
			local v228 = v207:FindFirstChild("ClientBall_MainMatch");
			if (v228 or (863 >= 4584)) then
				if v228:IsA("BasePart") then
					return v228;
				end
				if v228:IsA("Model") then
					return v228.PrimaryPart or v228:FindFirstChildWhichIsA("BasePart") or v228;
				end
			end
			return v207:FindFirstChildWhichIsA("BasePart");
		end
	end
	return nil;
end
local function v70(v127)
	if not v127 then
		return nil;
	end
	if v127.Team then
		return v127.Team.Name;
	end
	local v128 = v127:FindFirstChild("leaderstats");
	if (v128 or (724 >= 1668)) then
		local v208 = v128:FindFirstChild("Team") or v128:FindFirstChild("Đội");
		if v208 then
			return tostring(v208.Value);
		end
	end
	local v129 = v127:FindFirstChild("TeamValue") or v127:FindFirstChild("TeamName");
	if ((428 < 1804) and v129) then
		return tostring(v129.Value);
	end
	return "NoTeam";
end
local function v71()
	local v130 = v7.Character;
	if (not v130 or (3325 > 4613)) then
		return nil;
	end
	local v131 = v68(v130:FindFirstChild("HumanoidRootPart"));
	if (not v131 or (4950 <= 4553)) then
		return nil;
	end
	local v132 = v5:FindFirstChild("Map");
	if ((2665 <= 3933) and (not v132 or not v132:FindFirstChild("Data"))) then
		return nil;
	end
	local v133 = nil;
	local v134 = v9.GOAL_DETECTION_DIST;
	for v190, v191 in ipairs({"Team1","Team2"}) do
		local v192 = v132.Data:FindFirstChild(v191);
		if ((3273 == 3273) and v192) then
			local v222 = v192:FindFirstChild("GoalMesh") or v192:FindFirstChild("Goal") or v192:FindFirstChild("Goalkeeper");
			if ((3824 > 409) and v222) then
				local v238 = v68(v222);
				if v238 then
					local v260 = (v131 - v238).Magnitude;
					if ((2087 == 2087) and (v260 < v134)) then
						v134 = v260;
						v133 = v222;
					end
				end
			end
		end
	end
	return v133;
end
local function v72(v135, v136, v137, v138, v139)
	if v16 then
		return;
	end
	v16 = true;
	task.spawn(function()
		local v193 = v7.Character;
		local v194 = v193 and v193:FindFirstChild("HumanoidRootPart");
		if v194 then
			v194.CFrame = CFrame.new(v194.Position, Vector3.new(v135.X, v194.Position.Y, v135.Z));
		end
		if (v139 or (3404 > 4503)) then
			if (v138 or (3506 <= 1309)) then
				v3:SendKeyEvent(true, Enum.KeyCode.Space, false, game);
				task.wait(0.03);
				v3:SendKeyEvent(false, Enum.KeyCode.Space, false, game);
			end
			v3:SendMouseButtonEvent(0, 0, 0, true, game, 0);
			task.wait(0.05);
			v3:SendMouseButtonEvent(0, 0, 0, false, game, 0);
			task.wait(0.4);
			v16 = false;
			return;
		end
		if ((2955 == 2955) and v138) then
			v3:SendKeyEvent(true, Enum.KeyCode.Space, false, game);
			task.wait(0.03);
			v3:SendKeyEvent(false, Enum.KeyCode.Space, false, game);
			task.wait(0.03);
		end
		local v195 = nil;
		if (v136 or (2903 == 1495)) then
			v195 = Enum.KeyCode.A;
		elseif v137 then
			v195 = Enum.KeyCode.D;
		end
		if v195 then
			v3:SendKeyEvent(true, v195, false, game);
			task.wait(0.02);
		end
		v3:SendMouseButtonEvent(0, 0, 1, true, game, 0);
		task.wait(0.05);
		v3:SendMouseButtonEvent(0, 0, 1, false, game, 0);
		if ((4546 >= 2275) and v195) then
			task.wait(0.03);
			v3:SendKeyEvent(false, v195, false, game);
		end
		task.wait(v9.COOLDOWN);
		v16 = false;
	end);
end
local function v73(v140)
	local v141 = Instance.new("BillboardGui");
	v141.Name = "CleanPlayerESP";
	v141.AlwaysOnTop = true;
	v141.Size = UDim2.new(0, 100, 0, 24);
	v141.ExtentsOffset = Vector3.new(0, 2.5, 0);
	local v146 = Instance.new("TextLabel");
	v146.Name = "ESPLabel";
	v146.Size = UDim2.new(1, 0, 1, 0);
	v146.BackgroundTransparency = 1;
	v146.Text = v140.DisplayName .. "\n[0m]";
	v146.TextColor3 = Color3.fromRGB(255, 255, 255);
	v146.Font = Enum.Font.GothamBold;
	v146.TextSize = 10;
	v146.TextStrokeTransparency = 0.2;
	v146.TextStrokeColor3 = Color3.fromRGB(0, 0, 0);
	v146.Parent = v141;
	return v141;
end
local function v74()
	local v158 = Instance.new("BillboardGui");
	v158.Name = "CleanBallESP";
	v158.AlwaysOnTop = true;
	v158.Size = UDim2.new(0, 80, 0, 20);
	v158.ExtentsOffset = Vector3.new(0, 1.8, 0);
	local v163 = Instance.new("TextLabel");
	v163.Name = "BallLabel";
	v163.Size = UDim2.new(1, 0, 1, 0);
	v163.BackgroundTransparency = 1;
	v163.Text = "⚽ BÓNG [0m]";
	v163.TextColor3 = Color3.fromRGB(255, 220, 50);
	v163.Font = Enum.Font.GothamBold;
	v163.TextSize = 11;
	v163.TextStrokeTransparency = 0.2;
	v163.TextStrokeColor3 = Color3.fromRGB(0, 0, 0);
	v163.Parent = v158;
	return v158;
end
v2.Heartbeat:Connect(function()
	local v175 = v7.Character;
	local v176 = v175 and v175:FindFirstChild("HumanoidRootPart");
	local v177 = v69();
	if ((819 >= 22) and v177 and v14) then
		local v209 = (v177:IsA("Model") and (v177.PrimaryPart or v177:FindFirstChildWhichIsA("BasePart"))) or v177;
		if ((3162 == 3162) and v209) then
			local v229 = v209:FindFirstChild("CleanBallESP") or v74();
			v229.Parent = v209;
			local v231 = v209:FindFirstChild("BallHighlight");
			if (not v231 or (2369 > 4429)) then
				v231 = Instance.new("Highlight");
				v231.Name = "BallHighlight";
				v231.FillColor = Color3.fromRGB(255, 200, 0);
				v231.OutlineColor = Color3.fromRGB(255, 255, 255);
				v231.FillTransparency = 0.4;
				v231.Parent = v209;
			end
			if v176 then
				local v254 = math.floor((v209.Position - v176.Position).Magnitude / 3);
				v229.BallLabel.Text = "⚽ BÓNG [" .. tostring(v254) .. "m]";
			end
		end
	elseif ((4095 >= 3183) and v177) then
		local v232 = (v177:IsA("Model") and (v177.PrimaryPart or v177:FindFirstChildWhichIsA("BasePart"))) or v177;
		if v232 then
			if v232:FindFirstChild("CleanBallESP") then
				v232.CleanBallESP:Destroy();
			end
			if (v232:FindFirstChild("BallHighlight") or (3711 < 1008)) then
				v232.BallHighlight:Destroy();
			end
		end
	end
	local v178 = v70(v7);
	for v196, v197 in ipairs(v1:GetPlayers()) do
		if ((v197 ~= v7) and v197.Character and v197.Character:FindFirstChild("HumanoidRootPart")) then
			local v225 = v197.Character;
			local v226 = v225.HumanoidRootPart;
			if (v15 or (1049 <= 906)) then
				local v240 = v226:FindFirstChild("CleanPlayerESP") or v73(v197);
				v240.Parent = v226;
				local v242 = v70(v197);
				local v243 = (v178 ~= "NoTeam") and (v242 ~= "NoTeam") and (v178 == v242);
				local v244 = (v243 and Color3.fromRGB(50, 180, 255)) or Color3.fromRGB(255, 50, 50);
				v240.ESPLabel.TextColor3 = v244;
				local v246 = v225:FindFirstChild("TeamCircle");
				if not v246 then
					v246 = Instance.new("Highlight");
					v246.Name = "TeamCircle";
					v246.FillTransparency = 0.6;
					v246.OutlineTransparency = 0.2;
					v246.Parent = v225;
				end
				v246.FillColor = v244;
				v246.OutlineColor = v244;
				if v176 then
					local v265 = math.floor((v226.Position - v176.Position).Magnitude / 3);
					v240.ESPLabel.Text = v197.DisplayName .. "\n[" .. tostring(v265) .. "m]";
				end
			else
				if ((4513 > 2726) and v226:FindFirstChild("CleanPlayerESP")) then
					v226.CleanPlayerESP:Destroy();
				end
				if v225:FindFirstChild("TeamCircle") then
					v225.TeamCircle:Destroy();
				end
			end
		end
	end
end);
v2.RenderStepped:Connect(function(v179)
	local v180 = v7.Character;
	local v181 = v180 and v180:FindFirstChildOfClass("Humanoid");
	local v182 = v180 and v180:FindFirstChild("HumanoidRootPart");
	if (v21 and v13 and v32 and (v31.Magnitude > 0.05) and v181) then
		local v210 = v8.CFrame;
		local v211 = Vector3.new(v210.LookVector.X, 0, v210.LookVector.Z).Unit;
		local v212 = Vector3.new(v210.RightVector.X, 0, v210.RightVector.Z).Unit;
		local v213 = (v212 * v31.X) + (v211 * -v31.Y);
		v181:Move(v213, false);
	end
	local v183 = v69();
	local v184 = v68(v183);
	local v185 = tick();
	if ((v184 and v18) or (1481 >= 2658)) then
		local v214 = v185 - v19;
		if (v214 > 0) then
			v20 = (v184 - v18) / v214;
		end
	end
	v18 = v184;
	v19 = v185;
	if ((v11 and v184) or (3220 == 1364)) then
		v8.CFrame = CFrame.new(v8.CFrame.Position, v184);
	end
	if (not v182 or not v181 or (1054 > 3392)) then
		return;
	end
	local v186 = v71();
	local v187 = v186 and v68(v186);
	if ((v12 and v184 and v187 and not v32 and not v16) or (676 >= 1642)) then
		local v216 = (v184 - v187).Magnitude;
		if (v216 <= v9.POSITIONING_DIST) then
			local v233 = v187 + ((v184 - v187).Unit * 6);
			local v234 = v233 - v182.Position;
			if (v234.Magnitude > 1.2) then
				v181:Move(v234.Unit, false);
			end
		end
	end
	if ((4136 > 2397) and v10 and v184 and v187 and not v16) then
		local v217 = v20.Magnitude;
		if ((v217 >= v9.MIN_BALL_SPEED) or (4334 == 4245)) then
			local v235 = (v187 - v184).Unit;
			if ((v20.Unit:Dot(v235) > 0.15) or (4276 <= 3031)) then
				local v256 = v9.PREDICTION_TIME;
				local v257 = v184 + (v20 * v256) + Vector3.new(0, -0.5 * v9.GRAVITY * (v256 ^ 2), 0);
				local v258 = (v257 - v187).Magnitude;
				if ((v258 <= v9.BALL_SAVE_DIST) or (4782 <= 1199)) then
					local v267 = v182.CFrame;
					local v268 = v267:PointToObjectSpace(v257);
					local v269 = (v257 - v182.Position).Magnitude;
					if ((v269 <= v9.CATCH_RADIUS) or (4864 < 1902)) then
						local v271 = v268.Y > v9.HIGH_SHOT_THRESHOLD;
						v72(v257, false, false, v271, true);
					else
						local v272 = v268.X < -v9.LEFT_RIGHT_THRESHOLD;
						local v273 = v268.X > v9.LEFT_RIGHT_THRESHOLD;
						local v274 = v268.Y > v9.HIGH_SHOT_THRESHOLD;
						if ((4839 >= 3700) and (v272 or v273 or v274)) then
							v72(v257, v272, v273, v274, false);
						end
					end
				end
			end
		end
	end
end);
