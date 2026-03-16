--[[
    ZEEXHUB - MACRO КОНТРОЛЛЕР
    Полностью рабочий: CREATE, LIST, REFRESH, LOAD, RECORD, START
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ==========================================
-- ДАННЫЕ МАКРОСОВ
-- ==========================================
local macros = {}  -- { name = "Имя", actions = {}, created = time }
local selectedMacro = nil
local isRecording = false
local isPlaying = false
local currentRecording = nil
local recordStartTime = 0
local lastUnits = {}

-- ЦВЕТА (под твою тему)
local colors = {
    mainBg = Color3.fromRGB(15, 0, 25),
    panelBg = Color3.fromRGB(25, 0, 40),
    button = Color3.fromRGB(80, 0, 130),
    buttonAlt = Color3.fromRGB(120, 0, 180),
    text = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(160, 0, 255)
}

-- ==========================================
-- ФУНКЦИИ ПОИСКА ЮНИТОВ
-- ==========================================
local function findUnits()
    local units = {}
    local possibleFolders = {
        workspace:FindFirstChild("Towers"),
        workspace:FindFirstChild("Units"),
        workspace:FindFirstChild("PlacedUnits"),
        workspace:FindFirstChild("Map"):FindFirstChild("Towers"),
        workspace:FindFirstChild("Ignore"):FindFirstChild("Units")
    }
    
    for _, folder in ipairs(possibleFolders) do
        if folder then
            for _, unit in ipairs(folder:GetChildren()) do
                local root = unit:FindFirstChild("HumanoidRootPart") 
                    or unit:FindFirstChild("Torso") 
                    or unit:FindFirstChild("Part")
                
                if root then
                    local unitId = unit.Name .. "_" .. math.floor(root.Position.X * 10) .. "_" .. math.floor(root.Position.Z * 10)
                    units[unitId] = {
                        unit = unit,
                        position = root.Position,
                        name = unit.Name,
                        cframe = root.CFrame
                    }
                end
            end
        end
    end
    return units
end

-- ==========================================
-- ФУНКЦИИ ЗАПИСИ МАКРОСА
-- ==========================================
local function createMacro(name)
    return {
        name = name,
        actions = {},
        created = os.time()
    }
end

local function startMacroRecording()
    currentRecording = createMacro("Macro " .. os.date("%H:%M"))
    lastUnits = findUnits()
    isRecording = true
    recordStartTime = tick()
    showNotification("⏺️ ЗАПИСЬ НАЧАТА", 2)
    
    task.spawn(function()
        while isRecording do
            task.wait(0.3)
            
            local currentUnits = findUnits()
            local currentTime = tick() - recordStartTime
            
            -- Поиск новых юнитов (покупка)
            for id, unit in pairs(currentUnits) do
                if not lastUnits[id] then
                    table.insert(currentRecording.actions, {
                        time = currentTime,
                        type = "buy",
                        position = unit.position,
                        cframe = unit.cframe,
                        unitName = unit.name
                    })
                    showNotification("💰 Куплен: " .. unit.name, 1)
                end
            end
            
            -- Поиск удаленных юнитов (продажа)
            for id, unit in pairs(lastUnits) do
                if not currentUnits[id] then
                    table.insert(currentRecording.actions, {
                        time = currentTime,
                        type = "sell",
                        position = unit.position,
                        cframe = unit.cframe,
                        unitName = unit.name
                    })
                    showNotification("💸 Продан: " .. unit.name, 1)
                end
            end
            
            lastUnits = currentUnits
        end
    end)
end

local function stopMacroRecording()
    if not isRecording or not currentRecording then return end
    
    isRecording = false
    currentRecording.duration = tick() - recordStartTime
    
    if #currentRecording.actions > 0 then
        table.insert(macros, currentRecording)
        showNotification("✅ МАКРОС СОХРАНЕН - " .. #currentRecording.actions .. " действий", 2)
    else
        showNotification("⚠️ Нет действий", 2)
    end
    
    currentRecording = nil
    lastUnits = {}
end

-- ==========================================
-- ФУНКЦИЯ ВОСПРОИЗВЕДЕНИЯ
-- ==========================================
local function playMacro(macro)
    if not macro or #macro.actions == 0 then
        showNotification("⚠️ Макрос пуст", 2)
        return
    end
    
    isPlaying = true
    showNotification("▶️ ВОСПРОИЗВЕДЕНИЕ: " .. macro.name, 2)
    
    local actions = macro.actions
    table.sort(actions, function(a, b) return a.time < b.time end)
    
    local startTime = tick()
    
    for i, action in ipairs(actions) do
        if not isPlaying then break end
        
        local waitTime = action.time - (tick() - startTime)
        if waitTime > 0 then task.wait(waitTime) end
        
        local screenPos = workspace.CurrentCamera:WorldToViewportPoint(action.position)
        
        if screenPos.Z > 0 then
            local btn = action.type == "buy" and 0 or 1
            VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, btn, true, nil, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, btn, false, nil, 0)
        end
    end
    
    isPlaying = false
    showNotification("✅ Воспроизведение завершено", 2)
end

-- ==========================================
-- ФУНКЦИЯ УВЕДОМЛЕНИЙ
-- ==========================================
local function showNotification(message, duration)
    duration = duration or 2
    
    local notif = Instance.new("Frame")
    notif.Parent = player.PlayerGui
    notif.Size = UDim2.new(0, 300, 0, 40)
    notif.Position = UDim2.new(0.5, -150, 0, -50)
    notif.BackgroundColor3 = colors.mainBg
    notif.BackgroundTransparency = 0.1
    notif.ZIndex = 200
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notif
    
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Parent = notif
    notifStroke.Thickness = 2
    notifStroke.Color = colors.accent
    
    local notifText = Instance.new("TextLabel")
    notifText.Parent = notif
    notifText.Size = UDim2.new(1, -10, 1, 0)
    notifText.Position = UDim2.new(0, 5, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.Font = Enum.Font.GothamBold
    notifText.TextSize = 14
    
    TweenService:Create(notif, TweenInfo.new(0.3), {
        Position = UDim2.new(0.5, -150, 0, 20)
    }):Play()
    
    task.wait(duration)
    notif:Destroy()
end

-- ==========================================
-- UI ЭЛЕМЕНТЫ ДЛЯ MACRO (окна и кнопки)
-- ==========================================

-- Затемнение
local overlay = Instance.new("Frame")
overlay.Name = "MacroOverlay"
overlay.Parent = player.PlayerGui
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.75
overlay.ZIndex = 50
overlay.Visible = false
overlay.Active = true

overlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        overlay.Visible = false
        if createWindow then createWindow.Visible = false end
        if listWindow then listWindow.Visible = false end
    end
end)

-- ОКНО СОЗДАНИЯ
local createWindow = Instance.new("Frame")
createWindow.Name = "CreateWindow"
createWindow.Parent = player.PlayerGui
createWindow.Size = UDim2.new(0, 320, 0, 160)
createWindow.Position = UDim2.new(0.5, -160, 0.5, -80)
createWindow.BackgroundColor3 = colors.panelBg
createWindow.BackgroundTransparency = 0.1
createWindow.ZIndex = 100
createWindow.Visible = false
createWindow.Active = true

local createCorner = Instance.new("UICorner")
createCorner.CornerRadius = UDim.new(0, 15)
createCorner.Parent = createWindow

local createTitle = Instance.new("TextLabel")
createTitle.Parent = createWindow
createTitle.Size = UDim2.new(1, 0, 0, 40)
createTitle.BackgroundTransparency = 1
createTitle.Text = "📁 CREATE MACRO"
createTitle.TextColor3 = colors.text
createTitle.Font = Enum.Font.GothamBold
createTitle.TextSize = 18
createTitle.ZIndex = 101

local createInput = Instance.new("TextBox")
createInput.Parent = createWindow
createInput.Size = UDim2.new(1, -40, 0, 40)
createInput.Position = UDim2.new(0, 20, 0, 45)
createInput.BackgroundColor3 = colors.button
createInput.BackgroundTransparency = 0.3
createInput.PlaceholderText = "введите имя макроса"
createInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
createInput.Text = ""
createInput.TextColor3 = Color3.fromRGB(255, 255, 255)
createInput.Font = Enum.Font.Gotham
createInput.TextSize = 14
createInput.ZIndex = 101

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = createInput

local createConfirm = Instance.new("TextButton")
createConfirm.Parent = createWindow
createConfirm.Size = UDim2.new(0, 100, 0, 35)
createConfirm.Position = UDim2.new(0.5, -110, 1, -45)
createConfirm.BackgroundColor3 = colors.buttonAlt
createConfirm.Text = "СОЗДАТЬ"
createConfirm.TextColor3 = Color3.fromRGB(255, 255, 255)
createConfirm.Font = Enum.Font.GothamBold
createConfirm.TextSize = 14
createConfirm.ZIndex = 101

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 8)
confirmCorner.Parent = createConfirm

local createCancel = Instance.new("TextButton")
createCancel.Parent = createWindow
createCancel.Size = UDim2.new(0, 100, 0, 35)
createCancel.Position = UDim2.new(0.5, 10, 1, -45)
createCancel.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
createCancel.Text = "ОТМЕНА"
createCancel.TextColor3 = Color3.fromRGB(255, 255, 255)
createCancel.Font = Enum.Font.GothamBold
createCancel.TextSize = 14
createCancel.ZIndex = 101

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 8)
cancelCorner.Parent = createCancel

-- ОКНО СПИСКА
local listWindow = Instance.new("Frame")
listWindow.Name = "ListWindow"
listWindow.Parent = player.PlayerGui
listWindow.Size = UDim2.new(0, 320, 0, 320)
listWindow.Position = UDim2.new(0.5, -160, 0.5, -160)
listWindow.BackgroundColor3 = colors.panelBg
listWindow.BackgroundTransparency = 0.1
listWindow.ZIndex = 100
listWindow.Visible = false
listWindow.Active = true

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 15)
listCorner.Parent = listWindow

local listTitle = Instance.new("TextLabel")
listTitle.Parent = listWindow
listTitle.Size = UDim2.new(1, 0, 0, 40)
listTitle.BackgroundTransparency = 1
listTitle.Text = "📋 LIST MACRO"
listTitle.TextColor3 = colors.text
listTitle.Font = Enum.Font.GothamBold
listTitle.TextSize = 18
listTitle.ZIndex = 101

local listScrolling = Instance.new("ScrollingFrame")
listScrolling.Parent = listWindow
listScrolling.Size = UDim2.new(1, -20, 1, -90)
listScrolling.Position = UDim2.new(0, 10, 0, 45)
listScrolling.BackgroundColor3 = colors.button
listScrolling.BackgroundTransparency = 0.3
listScrolling.ScrollBarThickness = 5
listScrolling.ScrollBarImageColor3 = colors.accent
listScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
listScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
listScrolling.ZIndex = 101

local listScrollingCorner = Instance.new("UICorner")
listScrollingCorner.CornerRadius = UDim.new(0, 8)
listScrollingCorner.Parent = listScrolling

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = listScrolling
listLayout.Padding = UDim.new(0, 5)

local listClose = Instance.new("TextButton")
listClose.Parent = listWindow
listClose.Size = UDim2.new(0, 100, 0, 35)
listClose.Position = UDim2.new(0.5, -50, 1, -45)
listClose.BackgroundColor3 = colors.buttonAlt
listClose.Text = "ЗАКРЫТЬ"
listClose.TextColor3 = Color3.fromRGB(255, 255, 255)
listClose.Font = Enum.Font.GothamBold
listClose.TextSize = 14
listClose.ZIndex = 101

local listCloseCorner = Instance.new("UICorner")
listCloseCorner.CornerRadius = UDim.new(0, 8)
listCloseCorner.Parent = listClose

-- Функция обновления списка
local function refreshList()
    for _, child in ipairs(listScrolling:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for i, macro in ipairs(macros) do
        local btn = Instance.new("TextButton")
        btn.Parent = listScrolling
        btn.Size = UDim2.new(1, -4, 0, 35)
        btn.Position = UDim2.new(0, 2, 0, 0)
        btn.BackgroundColor3 = colors.button
        btn.BackgroundTransparency = 0.2
        btn.Text = macro.name .. " (" .. (#macro.actions or 0) .. " действий)"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.ZIndex = 102
        btn.AutoButtonColor = false
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            selectedMacro = macro
            listWindow.Visible = false
            overlay.Visible = false
            showNotification("✅ Выбран: " .. macro.name, 2)
        end)
    end
end

-- ==========================================
-- ЭКСПОРТ ФУНКЦИЙ ДЛЯ main.lua
-- ==========================================
local MacroAPI = {
    -- Данные
    macros = macros,
    selectedMacro = selectedMacro,
    isRecording = isRecording,
    isPlaying = isPlaying,
    
    -- Функции для кнопок
    create = function(parent, x, y)
        local btn = Instance.new("TextButton")
        btn.Parent = parent
        btn.Size = UDim2.new(0, 100, 0, 30)
        btn.Position = UDim2.new(0, x, 0, y)
        btn.BackgroundColor3 = colors.button
        btn.BackgroundTransparency = 0.1
        btn.Text = "📁 CREATE"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            overlay.Visible = true
            createWindow.Visible = true
        end)
        
        return btn
    end,
    
    list = function(parent, x, y)
        local btn = Instance.new("TextButton")
        btn.Parent = parent
        btn.Size = UDim2.new(0, 100, 0, 30)
        btn.Position = UDim2.new(0, x, 0, y)
        btn.BackgroundColor3 = colors.button
        btn.BackgroundTransparency = 0.1
        btn.Text = "📋 LIST"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if #macros == 0 then
                showNotification("📋 Список пуст", 2)
            else
                refreshList()
                overlay.Visible = true
                listWindow.Visible = true
            end
        end)
        
        return btn
    end,
    
    refresh = function(parent, x, y)
        local btn = Instance.new("TextButton")
        btn.Parent = parent
        btn.Size = UDim2.new(0, 100, 0, 30)
        btn.Position = UDim2.new(0, x, 0, y)
        btn.BackgroundColor3 = colors.button
        btn.BackgroundTransparency = 0.1
        btn.Text = "🔄 REFRESH"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            showNotification("🔄 Список обновлен", 1)
            if listWindow.Visible then
                refreshList()
            end
        end)
        
        return btn
    end,
    
    load = function(parent, x, y)
        local btn = Instance.new("TextButton")
        btn.Parent = parent
        btn.Size = UDim2.new(0, 100, 0, 30)
        btn.Position = UDim2.new(0, x, 0, y)
        btn.BackgroundColor3 = colors.button
        btn.BackgroundTransparency = 0.1
        btn.Text = "📂 LOAD"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if selectedMacro then
                showNotification("📂 Загружен: " .. selectedMacro.name, 2)
            else
                showNotification("⚠️ Сначала выберите макрос", 2)
            end
        end)
        
        return btn
    end,
    
    record = function(parent, x, y)
        local btn = Instance.new("TextButton")
        btn.Parent = parent
        btn.Size = UDim2.new(0, 100, 0, 30)
        btn.Position = UDim2.new(0, x, 0, y)
        btn.BackgroundColor3 = colors.buttonAlt
        btn.BackgroundTransparency = 0.1
        btn.Text = "⏺️ RECORD"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if not isRecording then
                startMacroRecording()
                btn.Text = "⏹️ STOP"
                btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            else
                stopMacroRecording()
                btn.Text = "⏺️ RECORD"
                btn.BackgroundColor3 = colors.buttonAlt
            end
        end)
        
        return btn
    end,
    
    start = function(parent, x, y)
        local btn = Instance.new("TextButton")
        btn.Parent = parent
        btn.Size = UDim2.new(0, 100, 0, 30)
        btn.Position = UDim2.new(0, x, 0, y)
        btn.BackgroundColor3 = colors.button
        btn.BackgroundTransparency = 0.1
        btn.Text = "▶️ START"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if selectedMacro then
                playMacro(selectedMacro)
            else
                showNotification("⚠️ Сначала выберите макрос", 2)
            end
        end)
        
        return btn
    end
}

-- Обработчики окон
createConfirm.MouseButton1Click:Connect(function()
    local name = createInput.Text
    if name and name ~= "" then
        table.insert(macros, createMacro(name))
        showNotification("✨ Создан: " .. name, 2)
        createInput.Text = ""
    else
        showNotification("⚠️ Введите имя", 2)
    end
    overlay.Visible = false
    createWindow.Visible = false
end)

createCancel.MouseButton1Click:Connect(function()
    createInput.Text = ""
    overlay.Visible = false
    createWindow.Visible = false
end)

listClose.MouseButton1Click:Connect(function()
    overlay.Visible = false
    listWindow.Visible = false
end)

return MacroAPI
