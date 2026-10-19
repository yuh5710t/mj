-- =========================================================
-- MEJS 子追脚本（适配远程加载 / 稳定防崩溃版）
-- =========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FOVRadius = 120
local ShowFOV = false
local BulletTP = false
local ESPEnabled = false
local WallCheck = false
local TeamCheck = false
local LockNPC = false
local TargetPart = "Head"
local SelectedTarget = nil

-- 绘图对象
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Radius = FOVRadius
FOVCircle.Visible = false

local AimLine = Drawing.new("Line")
AimLine.Color = Color3.fromRGB(255, 255, 0)
AimLine.Thickness = 1.5
AimLine.Visible = false

local NameText = Drawing.new("Text")
NameText.Size = 16
NameText.Color = Color3.fromRGB(255, 255, 255)
NameText.Center = true
NameText.Outline = true
NameText.OutlineColor = Color3.fromRGB(0, 0, 0)
NameText.Visible = false

local HealthText = Drawing.new("Text")
HealthText.Size = 13
HealthText.Color = Color3.fromRGB(255, 255, 255)
HealthText.Center = true
HealthText.Outline = true
HealthText.OutlineColor = Color3.fromRGB(0, 0, 0)
HealthText.Visible = false

local ESPTable = {}
local PlayerListCache = {}
local LastUpdate = 0

local function GetPlayers()
    if tick() - LastUpdate < 0.5 then return PlayerListCache end
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then list[player.Character.Name] = true end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") and not list[obj.Name] then
            table.insert(list, obj)
        end
    end
    PlayerListCache = list
    LastUpdate = tick()
    return list
end

local function GetTargetPart(character)
    if not character then return nil end
    if TargetPart == "Head" then return character:FindFirstChild("Head") end
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
    return torso or character:FindFirstChild("Head")
end

local function IsTeammate(player)
    if not LocalPlayer.TeamColor or not player.TeamColor then return false end
    return LocalPlayer.TeamColor == player.TeamColor
end

local function GetRaycastIgnoreList()
    local ignore = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            for _, part in ipairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then table.insert(ignore, part) end
            end
        end
    end
    return ignore
end

local function IsWallBetween(part)
    if not LocalPlayer.Character then return false end
    local origin = LocalPlayer.Character:FindFirstChild("Head")
    if not origin then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = GetRaycastIgnoreList()
    local result = Workspace:Raycast(origin.Position, (part.Position - origin.Position).Unit * (part.Position - origin.Position).Magnitude, params)
    if result then return not result.Instance:IsDescendantOf(part.Parent) end
    return false
end

local function GetClosestTarget()
    local mouse = UserInputService:GetMouseLocation()
    local closest = nil
    local closestDist = FOVRadius
    
    if LockNPC then
        for _, model in ipairs(GetPlayers()) do
            if model.Parent then
                local humanoid = model:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local part = GetTargetPart(model)
                    if part and (not WallCheck or not IsWallBetween(part)) then
                        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closest = model
                            end
                        end
                    end
                end
            end
        end
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not (TeamCheck and IsTeammate(player)) then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local part = GetTargetPart(player.Character)
                        if part and (not WallCheck or not IsWallBetween(part)) then
                            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closest = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function GetPlayerColor(player)
    if player.TeamColor then return player.TeamColor.Color end
    return Color3.fromRGB(255, 255, 255)
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillColor = GetPlayerColor(player)
    highlight.Enabled = ESPEnabled
    highlight.Adornee = character
    highlight.Parent = character
    
    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 800, 0, 50)
    billboard.ExtentsOffset = Vector3.new(0, 1, 0)
    billboard.Parent = character
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.SciFi
    label.TextSize = 11
    label.TextColor3 = GetPlayerColor(player)
    label.Text = player.DisplayName
    label.Visible = ESPEnabled
    label.Parent = billboard
    
    local conn = player.CharacterAdded:Connect(function()
        task.wait(0.3)
        pcall(function() highlight:Destroy(); billboard:Destroy() end)
        CreateESP(player)
        conn:Disconnect()
    end)
    
    ESPTable[player] = { hl = highlight, bb = billboard, conn = conn }
end

local function UpdateESP(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    
    if TeamCheck and IsTeammate(player) then
        if ESPTable[player] then
            pcall(function()
                ESPTable[player].hl:Destroy()
                ESPTable[player].bb:Destroy()
                if ESPTable[player].conn then ESPTable[player].conn:Disconnect() end
            end)
            ESPTable[player] = nil
        end
        return
    end
    
    if not ESPTable[player] then
        CreateESP(player)
    else
        local data = ESPTable[player]
        if data.hl and data.hl.Parent then
            data.hl.FillColor = GetPlayerColor(player)
            data.hl.Enabled = ESPEnabled
        else
            pcall(function() data.hl:Destroy(); data.bb:Destroy() end)
            CreateESP(player)
        end
        if data.bb and data.bb.Parent then
            local label = data.bb:FindFirstChildOfClass("TextLabel")
            if label then
                label.Text = player.DisplayName
                label.TextColor3 = GetPlayerColor(player)
                label.Visible = ESPEnabled
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if ESPEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then UpdateESP(player) end
            end
        else
            for _, data in pairs(ESPTable) do
                if data.hl then data.hl.Enabled = false end
                if data.bb then
                    local label = data.bb:FindFirstChildOfClass("TextLabel")
                    if label then label.Visible = false end
                end
            end
        end
    end
end)

-- 核心拦截：子弹追踪 (加了防崩溃保护)
pcall(function()
    local oldNamecall
    local mt = getrawmetatable(game)
    if mt then
        oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = function(self, ...)
            local method = getnamecallmethod()
            if BulletTP and (method == "Raycast" or method == "FindPartOnRay") and self == Workspace then
                if SelectedTarget and SelectedTarget.Character then
                    local part = GetTargetPart(SelectedTarget.Character)
                    if part then
                        return { Instance = part, Position = part.Position, Normal = (part.Position - (...)[2]).Unit, Material = Enum.Material.Plastic }
                    end
                end
                if not SelectedTarget and (...)[2].Magnitude > 3 then
                    local target = GetClosestTarget()
                    if target then
                        local char = (LockNPC and target) or (target.Character)
                        if char then
                     
