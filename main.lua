-- =========================================================
-- yuh5710t专属至尊版（去广告/去卡密/狂暴刷钱版）
-- =========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

-- 坐标定位
local maskBaseLocation = CFrame.new(604.114014, 5.09485245, -1018.1275)
local idleLocation = CFrame.new(1653.397216796875, -16.95315170288086, -530.3738403320312)
local grenadeBuyLocation = CFrame.new(659.044739, 5.77163315, -706.697632, -1.1920929e-07, 0, -1.00000012, 0, 1, 0, 1.00000012, 0, -1.1920929e-07)
local bombThrowLocation = CFrame.new(1129.0994873046875, 14.843579292297363, -354.19488525390625)
local bombTargetPosition = Vector3.new(1124.0853271484, 5.3128666877747, -357.68710327148)
local afterExplosionWaitLocation = CFrame.new(1112.95142, 16.6149864, -331.99646, 0, 0, -1, 0, 1, 0, 1, 0, 0)

-- 功能开关
local idleTeleportEnabled = true
local busy = false
local maskBuying = false
local autoBalloon = true
local autoPrinter = true
local autoSell = true
local autoCash = true
local autoMask = true
local autoCycle = true
local cycleRunning = true
local cycleThread = nil

local Remotes, Inventory
pcall(function()
    Remotes = require(ReplicatedStorage.devv.client.Helpers.remotes.Signal)
    Inventory = require(ReplicatedStorage.devv).load("v3item").inventory
end)
local FireServer = Remotes and Remotes.FireServer
local InvokeServer = Remotes and Remotes.InvokeServer

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 2,
        })
    end)
end

local itemMap = {}
local function updateCache()
    local itemPickup = Workspace.Game.Entities:FindFirstChild("ItemPickup")
    if not itemPickup then itemMap = {} return end
    itemMap = {}
    for _, model in pairs(itemPickup:GetChildren()) do
        for _, v in pairs(model:GetChildren()) do
            if v:IsA("MeshPart") or v:IsA("Part") then
                local prompt = v:FindFirstChildOfClass("ProximityPrompt")
                if prompt and prompt.ObjectText then
                    itemMap[prompt.ObjectText] = { part = v, prompt = prompt }
                end
            end
        end
    end
end
updateCache()
local itemPickupFolder = Workspace.Game.Entities:FindFirstChild("ItemPickup")
if itemPickupFolder then
    itemPickupFolder.ChildAdded:Connect(updateCache)
    itemPickupFolder.ChildRemoved:Connect(updateCache)
end

local itemFailCounts = {}
local function Autoitem(itemName)
    local itemData = itemMap[itemName]
    if not itemData then
        itemFailCounts[itemName] = (itemFailCounts[itemName] or 0) + 1
        return false
    end
    local char = LocalPlayer.Character
    if not char then
        itemFailCounts[itemName] = (itemFailCounts[itemName] or 0) + 1
        return false
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        itemFailCounts[itemName] = (itemFailCounts[itemName] or 0) + 1
        return false
    end
    root.CFrame = itemData.part.CFrame
    itemData.prompt.RequiresLineOfSight = false
    itemData.prompt.HoldDuration = 0
    fireproximityprompt(itemData.prompt)
    itemFailCounts[itemName] = 0
    return true
end

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), CurrentCamera.CFrame)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.K then
        idleTeleportEnabled = not idleTeleportEnabled
    end
end)

local function buyMaskOnce()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if char:FindFirstChild("Black Bandana") then return end
    local offsetX = math.random(-8, 8)
    local offsetZ = math.random(-8, 8)
    local randomPos = maskBaseLocation.Position + Vector3.new(offsetX, 0, offsetZ)
    root.CFrame = CFrame.new(randomPos)
    task.wait(0.5)
    local Signal = require(ReplicatedStorage.devv).load("Signal")
    local b1 = require(ReplicatedStorage.devv).load("v3item").inventory.items
    Signal.InvokeServer("attemptPurchase", "Black Bandana")
    task.wait(0.3)
    for _, v in pairs(b1) do
        if v.name == "Black Bandana" then
            Signal.FireServer("equip", v.guid)
            Signal.FireServer("wearMask", v.guid)
            break
        end
    end
    notify("yuh5710t专属", "已尝试购买并装备黑色面罩")
end

local function ensureMask()
    while autoMask do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Black Bandana") then
            return true
        end
        pcall(buyMaskOnce)
        task.wait(0.5)
    end
end

local function maskRoutine()
    maskBuying = true
    ensureMask()
    task.wait(2)
    maskBuying = false
end

LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("HumanoidRootPart", 10)
    busy = false
    maskBuying = false
    if autoMask then
        task.spawn(maskRoutine)
    end
end)

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function collectNearbyCash()
    local root = getRoot()
    if not root then return end
    local cb = Workspace:FindFirstChild("Game") and Workspace.Game.Entities:FindFirstChild("CashBundle")
    if not cb then return end
    for _, cash in pairs(cb:GetChildren()) do
        local part = cash:FindFirstChildOfClass("Part")
        if part then
            local distance = (root.Position - part.Position).Magnitude
            if distance <= 90 then
                local cd = cash:FindFirstChildOfClass("ClickDetector")
                if cd then
                    fireclickdetector(cd)
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        if autoCash then
            local root = getRoot()
            if root then
                local cb = Workspace:FindFirstChild("Game") and Workspace.Game.Entities:FindFirstChild("CashBundle")
                if cb then
                    local collected = false
                    for _, cash in pairs(cb:GetChildren()) do
                        local part = cash:FindFirstChildOfClass("Part")
                        if part then
                            local distance = (root.Position - part.Position).Magnitude
                            if distance <= 90 then
                                local cd = cash:FindFirstChildOfClass("ClickDetector")
                                if cd then
                                    fireclickdetector(cd)
                                    collected = true
                                end
                            end
                        end
                    end
                    if collected then
                        notify("yuh5710t专属", "已自动拾取附近现金")
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if autoBalloon and not busy then
            for _, name in ipairs({"Bunny Balloon", "Ghost Balloon", "Clover Balloon", "Bat Balloon", "Gold Clover Balloon", "Golden Rose", "Black Rose", "Heart Balloon"}) do
                local success = Autoitem(name)
                if success then
                    notify("yuh5710t专属", "自动捡到了 " .. name)
                    task.wait(0.2)
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if autoPrinter and not busy then
            if (itemFailCounts["Money Printer"] or 0) < 12 then
                local success = Autoitem("Money Printer")
                if success then
                    notify("yuh5710t专属", "自动捡到了印钞机")
                    task.wait(0.2)
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    local Signal = require(ReplicatedStorage.devv).load("Signal")
    local itemModule = require(ReplicatedStorage.devv).load("v3item")
    while true do
        if autoSell then
            local soldCount = 0
            for _, v in pairs(itemModule.inventory.items) do
                pcall(function()
                    Signal.FireServer("equip", v.guid)
                    Signal.FireServer("sellItem", v.guid)
                    soldCount = soldCount + 1
                end)
            end
            if soldCount > 0 then
                notify("yuh5710t专属", "已自动卖出 " .. soldCount .. " 件物品")
            end
        end
        task.wait(1)
    end
end)

local function runATMPhase()
    local atms = workspace:FindFirstChild("ATMs")
    if not atms then return end
    local root = getRoot()
    if not root then return end
    busy = true
    notify("yuh5710t专属", "开始狂暴攻击ATM")
    local originalCFrame = root.CFrame
    local currentTarget = nil
    local stop = false
    local lockConn = nil
    local canSearch = true
    local function clearLock()
        if lockConn then
            lockConn:Disconnect()
            lockConn = nil
        end
    end
    local moveThread = task.spawn(function()
        while not stop do
            if canSearch then
                local nearestATM, nearestDist = nil, math.huge
                for _, atm in ipairs(atms:GetChildren()) do
                    if atm:IsA("Model") and (atm:GetAttribute("health") or 0) ~= 0 then
                       
