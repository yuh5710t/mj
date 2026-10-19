-- 偷蛋脚本 - 高级反检测版
-- 游戏：Roblox Steal an Egg
-- 手机端适配，包含高级反作弊绕过

-- ==================== 高级反检测初始化 ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ==================== 高级绕过模块 ====================
local bypass = {}

-- 1. Hook Metamethod 绕过
function bypass:hookMetamethod()
    if not hookmetamethod then return end
    
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    local oldNewindex = mt.__newindex
    
    setreadonly(mt, false)
    
    -- Hook __namecall 拦截服务器调用检测
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- 拦截踢出事件
        if method == "FireServer" then
            local name = self.Name:lower()
            if name:find("kick") or name:find("ban") or 
               name:find("detect") or name:find("cheat") or
               name:find("exploit") or name:find("log") then
                return -- 阻止
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    -- Hook __index 拦断属性读取
    mt.__index = newcclosure(function(self, key)
        -- 拦截反作弊读取
        if typeof(self) == "Instance" then
            if key == "Character" or key == "HumanoidRootPart" then
                return oldIndex(self, key)
            end
        end
        return oldIndex(self, key)
    end)
    
    setreadonly(mt, true)
end

-- 2. Hook Function 绕过
function bypass:hookFunctions()
    if not hookfunction then return end
    
    -- 保存原始函数
    local oldFindPartOnRay = Workspace.FindPartOnRayWithIgnoreList
    local oldFindPartsInRegion = Workspace.FindPartsInRegion3
    
    -- Hook 网络检测
    pcall(function()
        hookfunction(getrawmetatable(game).__namecall, function(...)
            return oldFindPartOnRay
        end)
    end)
end

-- 3. 禁用反作弊脚本
function bypass:disableAntiCheat()
    -- 查找并禁用反作弊脚本
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            local name = obj.Name:lower()
            if name:find("anticheat") or name:find("anti_cheat") or
               name:find("detect") or name:find("exploit") or
               name:find("kick") or name:find("ban") or
               name:find("security") or name:find("protect") then
                pcall(function()
                    if obj:IsA("LocalScript") then
                        obj.Disabled = true
                    end
                    -- 强制禁用ModuleScript
                    pcall(function()
                        obj.Parent = nil
                    end)
                end)
                print("禁用反作弊: " .. obj.Name)
            end
        end
    end
end

-- 4. 网络所有权绕过
function bypass:networkOwnership()
    pcall(function()
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root:SetNetworkOwner(player)
            end
        end
    end)
end

-- 5. 速度检测绕过
function bypass:walkSpeedBypass()
    pcall(function()
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                -- 使用 hookfunction 绕过WalkSpeed检测
                if hookfunction then
                    local originalWalkSpeed
                    pcall(function()
                        originalWalkSpeed = humanoid.WalkSpeed
                    end)
                end
            end
        end
    end)
end

-- 6. 位置检测绕过
function bypass:positionBypass()
    -- 拦截位置检测
    if hookmetamethod then
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        
        local oldNewindex = mt.__newindex
        mt.__newindex = newcclosure(function(self, key, value)
            if self == player.Character and key == "CFrame" then
                -- 允许修改
                return oldNewindex(self, key, value)
            end
            return oldNewindex(self, key, value)
        end)
        
        setreadonly(mt, true)
    end
end

-- 7. 全面防护执行
function bypass:executeAll()
    print("=== 启动高级反检测绕过 ===")
    pcall(self.hookMetamethod, self)
    pcall(self.hookFunctions, self)
    pcall(self.disableAntiCheat, self)
    pcall(self.networkOwnership, self)
    pcall(self.walkSpeedBypass, self)
    pcall(self.positionBypass, self)
    print("=== 反检测绕过完成 ===")
end

-- ==================== 蛋识别模块 ====================
local eggFinder = {}

-- 查找所有蛋
function eggFinder:findAllEggs()
    local eggs = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("egg") or name:find("蛋") then
                local part = obj
                if obj:IsA("Model") then
                    part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                end
                
                if part then
                    table.insert(eggs, {
                        object = obj,
                        part = part,
                        position = part.Position,
                        name = obj.Name
                    })
                end
            end
        end
    end
    
    return eggs
end

-- 查找最近的蛋
function eggFinder:findNearestEgg()
    local char = player.Character
    if not char then return nil end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local eggs = self:findAllEggs()
    if #eggs == 0 then return nil end
    
    local nearest = nil
    local minDist = math.huge
    
    for _, egg in ipairs(eggs) do
        local dist = (egg.position - root.Position).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = egg
        end
    end
    
    return nearest, minDist
end

-- 查找基地位置
function eggFinder:findBase()
    -- 查找基地
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("base") or name:find("spawn") or
               name:find("home") or name:find("nest") or
               name:find("delivery") or name:find("basket") then
                return obj
            end
        end
    end
    
    -- 查找玩家自己的SpawnLocation
    local spawn = Workspace:FindFirstChild("SpawnLocation")
    return spawn
end

-- ==================== 自动偷蛋模块 ====================
local autoSteal = {
    enabled = false,
    currentTarget = nil,
    collectedCount = 0
}

-- 拾取蛋
function autoSteal:pickupEgg(egg)
    if not egg or not egg.part then return false end
    
    -- 方法1：触发TouchInterest
    pcall(function()
        firetouchinterest(player.Character.HumanoidRootPart, egg.part, 0)
        wait(0.1)
        firetouchinterest(player.Character.HumanoidRootPart, egg.part, 1)
    end)
    
    -- 方法2：触发ClickDetector
    pcall(function()
        local clickDetector = egg.part:FindFirstChild("ClickDetector") or
                              egg.object:FindFirstChild("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
        end
    end)
    
    -- 方法3：触发ProximityPrompt
    pcall(function()
        local prompt = egg.part:FindFirstChild("ProximityPrompt") or
                       egg.object:FindFirstChild("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
    end)
    
    -- 方法4：触发RemoteEvent
    pcall(function()
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                if name:find("egg") or name:find("pickup") or
                   name:find("collect") or name:find("steal") then
                    if obj:IsA("RemoteEvent") then
                        obj:FireServer(egg.object)
                    else
                        obj:InvokeServer(egg.object)
                    end
                end
            end
        end
    end)
    
    -- 方法5：直接拾取（把蛋放进背包）
    pcall(function()
        local args = {
            [1] = egg.object,
            [2] = egg.part
        }
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                if obj.Name:find("Pick") or obj.Name:find("Grab") then
                    obj:FireServer(unpack(args))
                end
            end
        end
    end)
    
    self.collectedCount = self.collectedCount + 1
    print("偷取蛋: " .. egg.name .. " (总计: " .. self.collectedCount .. ")")
    return true
end

-- 传送到蛋位置
function autoSteal:teleportToEgg(egg)
    if not egg or not egg.part then return end
    
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- 清除Body对象
    for _, child in pairs(root:GetChildren()) do
        if child:IsA("BodyPosition") or child:IsA("BodyVelocity") or
           child:IsA("BodyGyro") then
            child:Destroy()
        end
    end
    
    -- 重置速度
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
    
    -- 传送（稍微抬高，防止卡住）
    local targetPos = egg.position + Vector3.new(0, 5, 0)
    char:PivotTo(CFrame.new(targetPos))
    
    -- 锁定位置
    local lockPos = Instance.new("BodyPosition")
    lockPos.Name = "TeleportLock"
    lockPos.Position = targetPos
    lockPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    lockPos.P = 10000
    lockPos.Parent = root
end

-- 传送回基地
function autoSteal:t
