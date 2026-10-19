-- ==========================================
-- 1. 顶级白名单保护壳（无需修改，直接复制）
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local GOD_USERNAME = "yuh5710t"

local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
    end)
    print(("[%s] %s"):format(title, text))
end

-- 验证身份
local isPassed = false
if LocalPlayer.Name == GOD_USERNAME then
    isPassed = true
end

-- 如果没通过，直接停止运行，后面的代码全都不执行
if not isPassed then
    notify("白名单拦截", "你不是顶级权限，无法运行此脚本。")
    return 
end

notify("白名单", "验证通过，顶级权限已解锁！正在加载功能...")

-- ==========================================
-- 2. 把你要塞进来的脚本代码，全部粘贴在下面！
-- ==========================================



-- 示例：这里我随便写个测试代码
print("这是我的第一个内嵌功能！")
game:GetService("StarterGui"):SetCore("SendNotification", {Title="功能", Text="功能加载成功！", Duration=5})


-- ==========================================
-- 代码结束
-- ==========================================
