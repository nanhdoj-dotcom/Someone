local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Fly vars
local superMode = false
local flySpeed = 50
local bodyVelocity = nil
local flyConnection = nil

-- Tạo GUI HUD (mọi người đều thấy)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SuperModeGui"
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 150, 0, 50)
frame.Position = UDim2.new(1, -160, 0, 10)  -- Góc trên phải
frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- Đỏ khi OFF
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "SUPER MODE"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

-- Hàm start fly
local function startFly()
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = humanoidRootPart
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not superMode then return end
        
        local camera = workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end
        
        bodyVelocity.Velocity = moveDir * flySpeed
    end)
end

-- Hàm stop fly
local function stopFly()
    superMode = false
    if bodyVelocity then bodyVelocity:Destroy() end
    if flyConnection then flyConnection:Disconnect() end
end

-- Toggle super mode
local function toggleSuper()
    local event = ReplicatedStorage:WaitForChild("SuperModeEvent")
    
    if superMode then
        -- Tắt
        stopFly()
        event:FireServer("deactivate")
        frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        title.Text = "SUPER MODE\n(OFF)"
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "❌ Super Mode OFF";
            Color = Color3.fromRGB(255, 0, 0);
        })
    else
        -- Bật
        superMode = true
        startFly()
        event:FireServer("activate")
        frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        title.Text = "SUPER MODE\n(ON)"
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "✅ Super Mode ON! (WASD + Space/Shift bay)";
            Color = Color3.fromRGB(0, 255, 0);
        })
    end
end

-- Click nút
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleSuper()
    end
end)

-- Respawn handler
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    if superMode then
        wait(0.1)
        startFly()  -- Restart fly nếu đang ON
    end
end)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerSpeeds = {}  -- Lưu speed per player (giữ sau respawn)

-- Tạo RemoteEvent
local superModeEvent = Instance.new("RemoteEvent")
superModeEvent.Name = "SuperModeEvent"
superModeEvent.Parent = ReplicatedStorage

superModeEvent.OnServerEvent:Connect(function(player, action)
    -- Không kiểm tra admin nữa → Ai cũng dùng được
    
    if action == "activate" then
        playerSpeeds[player.UserId] = 50
    elseif action == "deactivate" then
        playerSpeeds[player.UserId] = nil
    end
    
    -- Áp dụng ngay
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local speed = playerSpeeds[player.UserId] or 16
            humanoid.WalkSpeed = speed
        end
    end
end)

-- Tự set speed sau respawn (cho mọi người)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        wait(0.1)
        local speed = playerSpeeds[player.UserId] or 16
        humanoid.WalkSpeed = speed
    end)
end)