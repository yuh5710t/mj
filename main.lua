-- =========================================================
-- yuh5710t专属至尊版（精简防卡死版）
-- =========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local idleLocation = CFrame.new(1653.397216796875, -16.95315170288086, -530.3738403320312)
local maskBaseLocation = CFrame.new(604.114014, 5.09485245, -1018.1275)

local busy = false
local autoBalloon = true
local autoPrinter = true
local autoSell = true
local autoCash = true
local autoMask = true
local cycleRunning = true

local Remotes, Inventory
pcall(function()
    Remotes = require(ReplicatedStorage.devv.client.Helpers.remotes.Signal)
    Inventory = require(ReplicatedStorage.devv).load("v3item").inventory
end)
local FireServer = Remotes and Remotes.FireServer
local InvokeServer = Remotes and Remotes.InvokeServer

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 2 })
    end)
end

local itemMap = {}
local function updateCache()
    if not Workspace:FindFirstChild("Game") then return end
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

task.spawn(function()
    while true do
        pcall(updateCache)
        task.wait(2)
    end
end)

local function Autoitem(itemName)
    local itemData = itemMap[itemName]
    if not itemData then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    root.CFrame = itemData.part.CFrame
    itemData.prompt.RequiresLineOfSight = false
    itemData.prompt.HoldDuration = 0
    fireproximityprompt(itemData.prompt)
    return true
end

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
        if part and (root.Position - part.Position).Magnitude <= 90 then
            local cd = cash:FindFirstChildOfClass("ClickDetector")
            if cd then fireclickdetector(cd) end
        end
    end
end

task.spawn(function()
    while true do
        if autoCash then pcall(collectNearbyCash) end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if autoBalloon and not busy then
            for _, name in ipairs({"Bunny Balloon", "Ghost Balloon", "Clover Balloon", "Bat Balloon", "Gold Clover Balloon", "Golden Rose", "Black Rose", "Heart Balloon"}) do
                pcall(Autoitem, name)
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if autoPrinter and not busy then
            pcall(Autoitem, "Money Printer")
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if autoSell then
            pcall(function()
                local Signal = require(ReplicatedStorage.devv).load("Signal")
                local itemModule = require(ReplicatedStorage.devv).load("v3item")
                for _, v in pairs(itemModule.inventory.items) do
                    Signal.FireServer("equip", v.guid)
                    Signal.FireServer("sellItem", v.guid)
                end
            end)
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while cycleRunning do
        pcall(function()
            local atms = workspace:FindFirstChild("ATMs")
            if atms then
                local root = getRoot()
                if root then
                    for _, atm in ipairs(atms:GetChildren()) do
                        if atm:IsA("Model") and (atm:GetAttribute("health") or 0) ~= 0 then
                            local main = atm:FindFirstChild("Main")
                            if main then
                                root.CFrame = CFrame.new(main.Position - Vector3.new(0, 4, 0)) * CFrame.Angles(math.rad(90), 0, 0)
                                atm:SetAttribute("health", 0)
                                collectNearbyCash()
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char and autoMask then
            if not char:FindFirstChild("Black Bandana") then
                pcall(function()
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = CFrame.new(maskBaseLocation.Position + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
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
                    end
                end)
            end
        end
        task.wait(3)
    end
end)

task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if not busy then
            local root = getRoot()
            if root then
                root.CFrame = idleLocation
                root.Velocity = Vector3.zero
                root.RotVelocity = Vector3.zero
            end
        end
    end)
end)

notify("yuh5710t专属", "狂暴模式已启动！")
