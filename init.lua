-- Hammerspoon 自动连点器
-- 功能：在指定坐标处以高频率进行连点，支持快捷键启动/停止

-- 初始化全局变量
local clickerPosition = nil  -- 记录主要点击坐标（右下角按钮）
local continueButtonPosition = nil  -- 记录"继续尝试"按钮坐标
local clickDuration = nil    -- 记录点击持续时间（秒）
local clickerTimer = nil     -- 连点计时器
local startTime = nil        -- 记录开始时间
local isClicking = false     -- 连点状态标志
local clickCounter = 0       -- 点击计数器，用于减少时间检查频率
local clickInterval = 0.02   -- 点击间隔，默认0.05秒(20次/秒)
local checkInterval = 5      -- 检查"继续尝试"按钮的间隔（点击次数）

-- 调试开关：如需查看调试日志可改为 true
local DEBUG = false
local function dprint(...)
    if DEBUG then print(...) end
end

-- 提前创建鼠标事件，提高效率
local mouseDownEvent = nil
local mouseUpEvent = nil
local continueDownEvent = nil
local continueUpEvent = nil

-- 辅助函数：显示通知
local function showNotification(title, message)
    hs.notify.new({title = title, informativeText = message}):send()
end

-- 记录鼠标当前位置作为主要点击坐标
local function recordPosition()
    -- 获取当前鼠标位置
    clickerPosition = hs.mouse.absolutePosition()
    
    -- 显示通知
    local message = string.format("已记录主按钮坐标：X=%.0f, Y=%.0f", 
                                  clickerPosition.x, 
                                  clickerPosition.y)
    showNotification("自动连点器", message)
    
    -- 在控制台输出信息
    print(message)
end

-- 记录"继续尝试"按钮位置
local function recordContinuePosition()
    -- 获取当前鼠标位置
    continueButtonPosition = hs.mouse.absolutePosition()
    
    -- 显示通知
    local message = string.format("已记录\"继续尝试\"按钮坐标：X=%.0f, Y=%.0f", 
                                  continueButtonPosition.x, 
                                  continueButtonPosition.y)
    showNotification("自动连点器", message)
    
    -- 在控制台输出信息
    print(message)
end

-- 输入点击持续时间
local function inputDuration()
    -- 创建输入框让用户输入持续时间
    local inputButton, inputText = hs.dialog.textPrompt(
        "设置连点时长", 
        "请输入连点持续时间（秒，正整数）：", 
        clickDuration and tostring(clickDuration) or "", 
        "确定", 
        "取消"
    )
    
    -- 处理用户输入
    if inputButton == "确定" and inputText and inputText ~= "" then
        -- 尝试转换为数字
        local duration = tonumber(inputText)
        
        -- 验证输入是否为正整数
        if duration and duration > 0 and duration == math.floor(duration) then
            clickDuration = duration
            showNotification("自动连点器", "已设置连点时长：" .. clickDuration .. " 秒")
            return true
        else
            -- 输入无效，显示错误信息
            showNotification("自动连点器", "请输入有效的正整数！")
            return false
        end
    end
    
    return false
end

-- 输入点击间隔设置
local function inputInterval()
    -- 创建输入框让用户输入点击间隔
    local inputButton, inputText = hs.dialog.textPrompt(
        "设置点击间隔", 
        "请输入点击间隔（秒，如0.02表示50次/秒，0.1表示10次/秒）：", 
        tostring(clickInterval), 
        "确定", 
        "取消"
    )
    
    -- 处理用户输入
    if inputButton == "确定" and inputText and inputText ~= "" then
        -- 尝试转换为数字
        local interval = tonumber(inputText)
        
        -- 验证输入是否为正数
        if interval and interval > 0 then
            clickInterval = interval
            showNotification("自动连点器", "已设置点击间隔：" .. clickInterval .. " 秒")
            return true
        else
            -- 输入无效，显示错误信息
            showNotification("自动连点器", "请输入有效的正数！")
            return false
        end
    end
    
    return false
end

-- 输入检查间隔设置
local function inputCheckInterval()
    -- 创建输入框让用户输入检查间隔
    local inputButton, inputText = hs.dialog.textPrompt(
        "设置检查间隔", 
        "请输入检查\"继续尝试\"按钮的间隔（点击次数）：", 
        tostring(checkInterval), 
        "确定", 
        "取消"
    )
    
    -- 处理用户输入
    if inputButton == "确定" and inputText and inputText ~= "" then
        -- 尝试转换为数字
        local interval = tonumber(inputText)
        
        -- 验证输入是否为正整数
        if interval and interval > 0 and interval == math.floor(interval) then
            checkInterval = interval
            showNotification("自动连点器", "已设置检查间隔：每" .. checkInterval .. "次点击")
            return true
        else
            -- 输入无效，显示错误信息
            showNotification("自动连点器", "请输入有效的正整数！")
            return false
        end
    end
    
    return false
end

-- 停止连点
local function stopClicking()
    if isClicking then
        -- 停止定时器
        if clickerTimer then
            clickerTimer:stop()
            clickerTimer = nil
        end
        
        -- 更新状态
        isClicking = false
        
        -- 清理事件对象
        mouseDownEvent = nil
        mouseUpEvent = nil
        continueDownEvent = nil
        continueUpEvent = nil
        
        -- 显示通知
        showNotification("自动连点器", "已手动停止连点")
        print("已停止连点")
    end
end

-- 点击"继续尝试"按钮
local function clickContinueButton()
    -- 检查是否有"继续尝试"按钮位置
    if not continueButtonPosition then
        dprint("未设置\"继续尝试\"按钮位置，跳过")
        return
    end

    dprint("点击\"继续尝试\"按钮")

    -- 直接发送点击事件（无需移动鼠标指针）
    continueDownEvent:post()
    continueUpEvent:post()
end

-- 执行点击操作 - 优化版本
local function doClick()
    -- 检查是否仍然处于点击状态
    if not isClicking then
        return
    end
    
    -- 执行点击（使用预先创建的事件）
    mouseDownEvent:post()
    mouseUpEvent:post()
    
    -- 增加计数器
    clickCounter = clickCounter + 1
    
    -- 每checkInterval次点击检测一次"继续尝试"按钮
    if continueButtonPosition and clickCounter % checkInterval == 0 then
        clickContinueButton()
    end
    
    -- 每10次点击检查一次时间，减少检查频率
    if clickCounter % 10 == 0 then
        -- 检查是否达到设定的时长
        local currentTime = os.time()
        if currentTime - startTime >= clickDuration then
            -- 时间到，停止连点
            stopClicking()
            showNotification("自动连点器", "已自动停止连点")
        end
    end
end

-- 开始连点
local function startClicking()
    -- 检查坐标是否已记录
    if not clickerPosition then
        showNotification("自动连点器", "请先使用 Option+R 记录主按钮位置")
        return
    end
    
    -- 检查时长是否已设置，如果没有则请求输入
    if not clickDuration then
        if not inputDuration() then
            return
        end
    end
    
    -- 如果已经在点击，不要重复启动
    if isClicking then
        showNotification("自动连点器", "连点已在进行中")
        return
    end
    
    -- 记录开始时间
    startTime = os.time()
    
    -- 设置状态为正在点击
    isClicking = true
    
    -- 重置计数器
    clickCounter = 0
    
    -- 移动鼠标到目标位置（只移动一次）  -- 移除指针移动以减少开销
    -- hs.mouse.absolutePosition(clickerPosition)
    
    -- 创建鼠标事件（只创建一次）
    mouseDownEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, clickerPosition)
    mouseUpEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, clickerPosition)
    
    -- 如果有"继续尝试"按钮位置，也创建对应的事件
    if continueButtonPosition then
        continueDownEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, continueButtonPosition)
        continueUpEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, continueButtonPosition)
    end
    
    -- 创建定时器，按照设定的间隔执行点击
    clickerTimer = hs.timer.doWhile(
        function() return isClicking end,
        doClick,
        clickInterval
    )
    
    -- 显示通知
    local message = "开始连点，时长：" .. clickDuration .. " 秒，间隔：" .. clickInterval .. " 秒"
    if continueButtonPosition then
        message = message .. "\n已设置\"继续尝试\"按钮位置，每" .. checkInterval .. "次点击检查一次"
    end
    showNotification("自动连点器", message)
    print(message)
end

-- 显示设置菜单
local function showSettingsMenu()
    local choices = {
        {title = "记录主按钮位置", subText = "记录当前鼠标位置作为主要点击位置"},
        {title = "记录\"继续尝试\"按钮位置", subText = "记录当前鼠标位置作为\"继续尝试\"按钮位置"},
        {title = "设置点击时长", subText = "设置连点持续的时间（秒）"},
        {title = "设置点击间隔", subText = "设置点击的间隔时间（秒）"},
        {title = "设置检查间隔", subText = "设置检查\"继续尝试\"按钮的间隔（点击次数）"},
        {title = "开始连点", subText = "开始在记录的坐标处连续点击"},
        {title = "停止连点", subText = "停止正在进行的连点"}
    }
    
    local chooser = hs.chooser.new(function(choice)
        if not choice then return end
        
        if choice.title == "记录主按钮位置" then
            recordPosition()
        elseif choice.title == "记录\"继续尝试\"按钮位置" then
            recordContinuePosition()
        elseif choice.title == "设置点击时长" then
            inputDuration()
        elseif choice.title == "设置点击间隔" then
            inputInterval()
        elseif choice.title == "设置检查间隔" then
            inputCheckInterval()
        elseif choice.title == "开始连点" then
            startClicking()
        elseif choice.title == "停止连点" then
            stopClicking()
        end
    end)
    
    chooser:choices(choices)
    chooser:show()
end

-- 注册快捷键

-- 记录主按钮位置：Option + R
hs.hotkey.bind({"alt"}, "R", recordPosition)

-- 记录"继续尝试"按钮位置：Option + C
hs.hotkey.bind({"alt"}, "C", recordContinuePosition)

-- 启动连点：Option + Command + T
hs.hotkey.bind({"alt", "cmd"}, "T", startClicking)

-- 停止连点：Option + Command + Y
hs.hotkey.bind({"alt", "cmd"}, "Y", stopClicking)

-- 显示设置菜单：Option + Command + ,
hs.hotkey.bind({"alt", "cmd"}, ",", showSettingsMenu)

-- 初始化完成通知
showNotification("自动连点器", "初始化完成，可以使用以下快捷键：\n- Option+R：记录主按钮位置\n- Option+C：记录\"继续尝试\"按钮位置\n- Option+⌘+T：开始连点\n- Option+⌘+Y：停止连点\n- Option+⌘+,：显示设置")
