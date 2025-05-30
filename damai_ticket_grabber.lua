-- 大麦抢票神器 v2.0 智能学习版 (清除重置版)
-- 专为iPhone镜像优化的高速抢票脚本
-- 新增：实时坐标学习功能
-- 特性：每次加载执行完整清理，确保全新状态
-- 作者：AI助手 & Eric

print("=== 大麦抢票神器 v2.0 智能学习版 (清除重置版) ===")

-- ========== 脚本加载时的完整清理机制 ==========
print("[清理] 开始执行脚本重置...")

-- 1. 清理可能存在的全局变量和旧状态
if _G.damaiGrabber then
    -- 停止可能运行中的定时器
    if _G.damaiGrabber.grabTimer then
        _G.damaiGrabber.grabTimer:stop()
        _G.damaiGrabber.grabTimer = nil
        print("[清理] 已停止旧的定时器")
    end
    
    -- 清理事件对象
    if _G.damaiGrabber.mouseEvents then
        for k, v in pairs(_G.damaiGrabber.mouseEvents) do
            _G.damaiGrabber.mouseEvents[k] = nil
        end
        print("[清理] 已清理旧的鼠标事件")
    end
    
    -- 解绑旧的快捷键
    if _G.damaiGrabber.hotkeys then
        for _, hotkey in ipairs(_G.damaiGrabber.hotkeys) do
            if hotkey and hotkey.delete then
                hotkey:delete()
            end
        end
        print("[清理] 已解绑旧的快捷键")
    end
    
    -- 清理整个全局表
    _G.damaiGrabber = nil
end

-- 2. 强制垃圾回收
collectgarbage("collect")
collectgarbage("collect") -- 执行两次确保彻底清理
print("[清理] 已执行垃圾回收")

-- 3. 创建新的全局容器
_G.damaiGrabber = {
    hotkeys = {},
    mouseEvents = {},
    grabTimer = nil
}

print("[清理] 脚本重置完成，开始初始化...")
print("=====================================\n")

-- ========== 以下是原始脚本内容 ==========

-- 按钮坐标配置（支持动态更新）
local buttonCoords = {
    mainButton = nil,                  -- 主按钮：提交抢票预约/提交订单/支付
    errorButton = nil,                 -- 错误处理：继续尝试/返回重试（动态学习）
}

-- 抢票参数配置
local config = {
    clickInterval = 0.05,           -- 疯狂模式：每0.05秒点击(20次/秒)
    isGrabbing = false,             -- 抢票状态标志
    grabTimer = nil,                -- 抢票定时器
    clickCounter = 0,               -- 点击计数器
    startTime = nil,                -- 开始时间
    maxRunTime = 600,               -- 最大运行时间10分钟（防止无限运行）
    DEBUG = true,                   -- 调试模式
    hasErrorButton = false,         -- 是否已学会错误按钮位置
}

-- 预创建的鼠标事件（高性能）
local mouseEvents = {
    mainDown = nil,
    mainUp = nil,
    errorDown = nil,
    errorUp = nil,
}

-- 调试输出函数
local function dprint(message)
    if config.DEBUG then
        print(string.format("[%s] %s", os.date("%H:%M:%S"), message))
    end
end

-- 显示通知
local function showNotification(title, message, duration)
    hs.notify.new({
        title = title,
        informativeText = message,
        autoWithdraw = true,
        withdrawAfter = duration or 3
    }):send()
end

-- 安全的事件创建函数
local function createMouseEvent(eventType, position)
    if not position or not position.x or not position.y then
        return nil
    end
    
    return hs.eventtap.event.newMouseEvent(eventType, position)
end

-- 初始化/更新鼠标事件
local function updateMouseEvents()
    dprint("更新鼠标事件...")
    
    -- 先清理旧的事件对象
    if _G.damaiGrabber.mouseEvents then
        for k, v in pairs(_G.damaiGrabber.mouseEvents) do
            _G.damaiGrabber.mouseEvents[k] = nil
        end
    end
    
    -- 创建主按钮点击事件
    if buttonCoords.mainButton then
        mouseEvents.mainDown = createMouseEvent(
            hs.eventtap.event.types.leftMouseDown, 
            buttonCoords.mainButton
        )
        mouseEvents.mainUp = createMouseEvent(
            hs.eventtap.event.types.leftMouseUp, 
            buttonCoords.mainButton
        )
        -- 同步到全局容器
        _G.damaiGrabber.mouseEvents.mainDown = mouseEvents.mainDown
        _G.damaiGrabber.mouseEvents.mainUp = mouseEvents.mainUp
    end
    
    -- 创建错误处理按钮点击事件
    if buttonCoords.errorButton then
        mouseEvents.errorDown = createMouseEvent(
            hs.eventtap.event.types.leftMouseDown, 
            buttonCoords.errorButton
        )
        mouseEvents.errorUp = createMouseEvent(
            hs.eventtap.event.types.leftMouseUp, 
            buttonCoords.errorButton
        )
        config.hasErrorButton = true
        -- 同步到全局容器
        _G.damaiGrabber.mouseEvents.errorDown = mouseEvents.errorDown
        _G.damaiGrabber.mouseEvents.errorUp = mouseEvents.errorUp
    else
        config.hasErrorButton = false
    end
    
    dprint("鼠标事件更新完成")
end

-- 记录主按钮坐标
local function recordMainButton()
    local pos = hs.mouse.absolutePosition()
    buttonCoords.mainButton = pos
    
    -- 立即更新事件（如果正在抢票）
    if config.isGrabbing then
        mouseEvents.mainDown = createMouseEvent(
            hs.eventtap.event.types.leftMouseDown, pos)
        mouseEvents.mainUp = createMouseEvent(
            hs.eventtap.event.types.leftMouseUp, pos)
    end
    
    local message = string.format("已记录主按钮位置: X=%.0f, Y=%.0f", pos.x, pos.y)
    showNotification("坐标记录", message, 3)
    dprint(message)
end

-- 记录错误按钮坐标（智能学习）
local function recordErrorButton()
    local pos = hs.mouse.absolutePosition()
    buttonCoords.errorButton = pos
    
    -- 立即更新事件（如果正在抢票）
    if config.isGrabbing then
        mouseEvents.errorDown = createMouseEvent(
            hs.eventtap.event.types.leftMouseDown, pos)
        mouseEvents.errorUp = createMouseEvent(
            hs.eventtap.event.types.leftMouseUp, pos)
        config.hasErrorButton = true
    end
    
    local message = string.format("已学会错误按钮位置: X=%.0f, Y=%.0f", pos.x, pos.y)
    showNotification("智能学习", message, 3)
    dprint(message)
end

-- 执行点击操作（优化版）
local function doClick(buttonType)
    if not config.isGrabbing then return end
    
    if buttonType == "main" and mouseEvents.mainDown and mouseEvents.mainUp then
        mouseEvents.mainDown:post()
        mouseEvents.mainUp:post()
        dprint("点击主按钮")
    elseif buttonType == "error" and config.hasErrorButton and mouseEvents.errorDown and mouseEvents.errorUp then
        mouseEvents.errorDown:post()
        mouseEvents.errorUp:post()
        dprint("点击错误处理按钮")
    end
end

-- 抢票核心逻辑（智能版）
local function ticketGrabLoop()
    if not config.isGrabbing then return end
    
    -- 增加计数器
    config.clickCounter = config.clickCounter + 1
    
    -- 检查最大运行时间
    if os.time() - config.startTime > config.maxRunTime then
        stopGrabbing("超时停止：已运行" .. config.maxRunTime .. "秒")
        return
    end
    
    -- 智能点击策略
    if config.hasErrorButton then
        -- 已学会错误处理：主按钮1次，错误处理2次
        local cycle = config.clickCounter % 3
        if cycle == 1 then
            doClick("main")
        elseif cycle == 2 or cycle == 0 then
            doClick("error")
        end
    else
        -- 未学会错误处理：只点击主按钮
        doClick("main")
    end
    
    -- 每100次点击显示一次状态
    if config.clickCounter % 100 == 0 then
        local elapsed = os.time() - config.startTime
        local errorStatus = config.hasErrorButton and "已学会" or "学习中"
        showNotification(
            "抢票进行中", 
            string.format("已运行%d秒，点击%d次\n错误处理：%s", elapsed, config.clickCounter, errorStatus),
            2
        )
    end
end

-- 开始抢票
local function startGrabbing()
    if config.isGrabbing then
        showNotification("提示", "抢票已在进行中！", 2)
        return
    end
    
    -- 检查必要条件
    if not buttonCoords.mainButton then
        showNotification("错误", "请先使用 Option+R 记录主按钮位置！", 4)
        return
    end
    
    dprint("开始抢票...")
    
    -- 初始化
    config.isGrabbing = true
    config.clickCounter = 0
    config.startTime = os.time()
    
    -- 初始化鼠标事件
    updateMouseEvents()
    
    -- 创建高频定时器
    config.grabTimer = hs.timer.doWhile(
        function() return config.isGrabbing end,
        ticketGrabLoop,
        config.clickInterval
    )
    
    -- 保存到全局容器
    _G.damaiGrabber.grabTimer = config.grabTimer
    
    local errorStatus = config.hasErrorButton and 
        string.format("错误处理：(%.0f,%.0f)", buttonCoords.errorButton.x, buttonCoords.errorButton.y) or
        "错误处理：等待学习"
        
    local message = string.format(
        "🚀 抢票开始！\n疯狂模式：%.0f次/秒\n主按钮：(%.0f,%.0f)\n%s",
        1/config.clickInterval,
        buttonCoords.mainButton.x, buttonCoords.mainButton.y,
        errorStatus
    )
    
    showNotification("大麦抢票神器", message, 5)
    print(message)
end

-- 停止抢票
function stopGrabbing(reason)
    if not config.isGrabbing then
        showNotification("提示", "抢票未在运行", 2)
        return
    end
    
    dprint("停止抢票: " .. (reason or "手动停止"))
    
    -- 停止定时器
    if config.grabTimer then
        config.grabTimer:stop()
        config.grabTimer = nil
    end
    
    -- 更新状态
    config.isGrabbing = false
    
    -- 保留坐标信息，清理事件对象
    mouseEvents.mainDown = nil
    mouseEvents.mainUp = nil
    mouseEvents.errorDown = nil
    mouseEvents.errorUp = nil
    
    -- 计算统计信息
    local elapsed = os.time() - (config.startTime or os.time())
    local avgSpeed = config.clickCounter / math.max(elapsed, 1)
    local errorStatus = config.hasErrorButton and "已掌握" or "未学习"
    
    local message = string.format(
        "⏹️ 抢票停止\n运行时长：%d秒\n总点击：%d次\n平均速度：%.1f次/秒\n错误处理：%s\n停止原因：%s",
        elapsed, config.clickCounter, avgSpeed, errorStatus, reason or "手动停止"
    )
    
    showNotification("抢票结果", message, 8)
    print(message)
end

-- 切换调试模式
local function toggleDebug()
    config.DEBUG = not config.DEBUG
    local status = config.DEBUG and "开启" or "关闭"
    showNotification("调试模式", "调试模式已" .. status, 2)
    print("调试模式：" .. status)
end

-- 显示当前状态
local function showStatus()
    local status = config.isGrabbing and "运行中" or "已停止"
    local mainStatus = buttonCoords.mainButton and 
        string.format("(%.0f,%.0f)", buttonCoords.mainButton.x, buttonCoords.mainButton.y) or "未记录"
    local errorStatus = config.hasErrorButton and 
        string.format("(%.0f,%.0f)", buttonCoords.errorButton.x, buttonCoords.errorButton.y) or "等待学习"
    
    local message = string.format(
        "📊 抢票状态：%s\n点击间隔：%s秒\n调试模式：%s\n主按钮：%s\n错误处理：%s",
        status,
        config.clickInterval,
        config.DEBUG and "开启" or "关闭",
        mainStatus,
        errorStatus
    )
    
    showNotification("状态信息", message, 6)
    print(message)
end

-- 紧急停止（快速响应）
local function emergencyStop()
    config.isGrabbing = false
    if config.grabTimer then
        config.grabTimer:stop()
        config.grabTimer = nil
    end
    showNotification("紧急停止", "抢票已紧急停止！", 3)
    print("🚨 紧急停止执行")
end

-- 快捷键绑定
print("\n📋 快捷键说明：")
print("Option + R : 记录主按钮位置 🎯")
print("Option + E : 记录错误按钮(智能学习) 🧠")
print("Option + G : 开始抢票 🚀")
print("Option + S : 停止抢票 ⏹️") 
print("Option + Q : 紧急停止 🚨")
print("Option + I : 显示状态 📊")
print("Option + D : 切换调试 🔧")

-- 绑定快捷键
_G.damaiGrabber.hotkeys = {
    hs.hotkey.bind({"alt"}, "R", recordMainButton),
    hs.hotkey.bind({"alt"}, "E", recordErrorButton),
    hs.hotkey.bind({"alt"}, "G", startGrabbing),
    hs.hotkey.bind({"alt"}, "S", function() stopGrabbing("手动停止") end),
    hs.hotkey.bind({"alt"}, "Q", emergencyStop),
    hs.hotkey.bind({"alt"}, "I", showStatus),
    hs.hotkey.bind({"alt"}, "D", toggleDebug)
}

-- 初始化完成
showNotification(
    "大麦抢票神器 v2.0", 
    "🎯 智能学习版已就绪！\n1. Option+R 记录主按钮\n2. Option+G 开始抢票\n3. 遇到错误时 Option+E 学习", 
    8
)

print("\n🎉 大麦抢票神器 v2.0 智能学习版准备就绪！")
print("💡 使用流程：")
print("1. 先用 Option+R 记录'提交抢票预约'位置")
print("2. 用 Option+G 开始抢票")
print("3. 遇到错误弹窗时，手动处理后用 Option+E 学习位置")
print("4. 脚本会立即学会并自动处理后续相同错误")
print("5. 看到支付页面立即按 Option+S 停止")
print("6. 遇到新错误继续用 Option+E 学习") 