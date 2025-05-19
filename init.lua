-- Hammerspoon 自动连点器
-- 功能：在指定坐标处以高频率进行连点，支持快捷键启动/停止

-- 初始化全局变量
local clickerPosition = nil  -- 记录点击坐标
local clickDuration = nil    -- 记录点击持续时间（秒）
local clickerTimer = nil     -- 连点计时器
local startTime = nil        -- 记录开始时间
local isClicking = false     -- 连点状态标志
local clickCounter = 0       -- 点击计数器，用于减少时间检查频率
local clickInterval = 0.05   -- 点击间隔，默认0.02秒(50次/秒)

-- 提前创建鼠标事件，提高效率
local mouseDownEvent = nil
local mouseUpEvent = nil

-- 辅助函数：显示通知
local function showNotification(title, message)
    hs.notify.new({title = title, informativeText = message}):send()
end

-- 记录鼠标当前位置作为点击坐标
local function recordPosition()
    -- 获取当前鼠标位置
    clickerPosition = hs.mouse.absolutePosition()
    
    -- 显示通知
    local message = string.format("已记录坐标：X=%.0f, Y=%.0f", 
                                  clickerPosition.x, 
                                  clickerPosition.y)
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
        
        -- 显示通知
        showNotification("自动连点器", "已手动停止连点")
        print("已停止连点")
    end
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
        showNotification("自动连点器", "请先使用 Option+R 记录点击坐标")
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
    
    -- 移动鼠标到目标位置（只移动一次）
    hs.mouse.absolutePosition(clickerPosition)
    
    -- 创建鼠标事件（只创建一次）
    mouseDownEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, clickerPosition)
    mouseUpEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, clickerPosition)
    
    -- 创建定时器，按照设定的间隔执行点击
    clickerTimer = hs.timer.doWhile(
        function() return isClicking end,
        doClick,
        clickInterval
    )
    
    -- 显示通知
    showNotification("自动连点器", "开始连点，时长：" .. clickDuration .. " 秒")
    print("开始连点，时长：" .. clickDuration .. " 秒，间隔：" .. clickInterval .. " 秒")
end

-- 显示设置菜单
local function showSettingsMenu()
    local choices = {
        {title = "记录点击坐标", subText = "记录当前鼠标位置作为点击坐标"},
        {title = "设置点击时长", subText = "设置连点持续的时间（秒）"},
        {title = "设置点击间隔", subText = "设置点击的间隔时间（秒）"},
        {title = "开始连点", subText = "开始在记录的坐标处连续点击"},
        {title = "停止连点", subText = "停止正在进行的连点"}
    }
    
    local chooser = hs.chooser.new(function(choice)
        if not choice then return end
        
        if choice.title == "记录点击坐标" then
            recordPosition()
        elseif choice.title == "设置点击时长" then
            inputDuration()
        elseif choice.title == "设置点击间隔" then
            inputInterval()
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

-- 记录坐标：Option + R
hs.hotkey.bind({"alt"}, "R", recordPosition)

-- 启动连点：Option + Command + T
hs.hotkey.bind({"alt", "cmd"}, "T", startClicking)

-- 停止连点：Option + Command + Y
hs.hotkey.bind({"alt", "cmd"}, "Y", stopClicking)

-- 显示设置菜单：Option + Command + ,
hs.hotkey.bind({"alt", "cmd"}, ",", showSettingsMenu)

-- 初始化完成通知
showNotification("自动连点器", "初始化完成，可以使用以下快捷键：\n- Option+R：记录坐标\n- Option+⌘+T：开始连点\n- Option+⌘+Y：停止连点\n- Option+⌘+,：显示设置")
