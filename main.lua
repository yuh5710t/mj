local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 2 })
    end)
end

notify("yuh5710t专属", "极致纯净版启动成功！")

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
    if not itemData then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    root.CFrame = itemData.part.CFrame
    itemData.prompt.RequiresLineOfSight = false
    itemData.prompt.HoldDuration = 0
    fireproximityprompt(itemData.prompt)
end

local function collectNearbyCash()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
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

-- 自动捡气球、印钞机、捡钱
task.spawn(function()
    while true do
        pcall(function()
            collectNearbyCash()
            for _, name in ipairs({"Money Printer", "Bunny Balloon", "Ghost Balloon", "Clover Balloon", "Bat Balloon", "Gold Clover Balloon", "Golden Rose", "Black Rose", "Heart Balloon"}) do
                Autoitem(name)
            end
        end)
        task.wait(0.1)
    end
end)

-- 自动卖东西
task.spawn(function()
    while true do
        pcall(function()
            local Signal = require(ReplicatedStorage.devv).load("Signal")
            local itemModule = require(ReplicatedStorage.devv).load("v3item")
            for _, v in pairs(itemModule.inventory.items) do
                Signal.FireServer("equip", v.guid)
                Signal.FireServer("sellItem", v.guid)
            end
        end)
        task.wait(1)
    end
end)

-- 自动买面罩防踢
task.spawn(function()
    while true do
        pcall(function()
            local char = LocalPlayer.Character
            if char and not char:FindFirstChild("Black Bandana") then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = CFrame.new(604.114014, 5.09485245, -1018.1275)
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
            end
        end)
        task.wait(3)
    end
end)
