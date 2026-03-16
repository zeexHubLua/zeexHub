--[[
    ZEEXHUB - ПОЛНОСТЬЮ РАБОЧИЙ ОБЪЕДИНЕННЫЙ СКРИПТ
    Всё в одном: MAIN, MACRO, SETTINGS + полная логика
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ==========================================
-- ЦВЕТА
-- ==========================================
local colors = {
    mainBg = Color3.fromRGB(15, 0, 25),
    panelBg = Color3.fromRGB(25, 0, 40),
    button = Color3.fromRGB(80, 0, 130),
    buttonAlt = Color3.fromRGB(120, 0, 180),
    text = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(160, 0, 255)
}

-- ==========================================
-- ДАННЫЕ МАКРОСОВ
-- ==========================================
local macros = {}  -- Хранилище макросов
local selectedMacro = nil
local isRecording = false
local isPlaying = false
local currentRecording = nil
local recordStartTime = 0
local nextUnitId = 1
local trackedUnits = {}

-- ==========================================
-- ФУНКЦИИ МАКРОСОВ
-- ==========================================

-- Поиск юнитов
local function scanUnits()
    local units = {}
    local possibleFolders = {
        workspace:FindFirstChild("Towers"),
        workspace:FindFirstChild("Units"),
        workspace:FindFirstChild("PlacedUnits"),
        workspace:FindFirstChild("Map"):FindFirstChild("Towers")
    }
    
    for _, folder in ipairs(possibleFolders) do
        if folder then
            for _, unit in ipairs(folder:GetChildren()) do
                local cframe = unit:GetPivot()
                local root = unit:FindFirstChild("HumanoidRootPart") or unit:FindFirstChild("Torso") or unit:FindFirstChild("Part")
                
                if root or cframe then
                    local pos = root and root.Position or cframe.Position
                    local cf = cframe or (root and root.CFrame)
                    
                    if cf then
                        local unitKey = unit.Name .. "_" .. math.floor(pos.X * 10) .. "_" .. math.floor(pos.Z * 10)
                        
                        local cfComponents = {cf:GetComponents()}
                        local cfString = string.format("%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f",
                            cfComponents[1], cfComponents[2], cfComponents[3],
                            cfComponents[4], cfComponents[5], cfComponents[6],
                            cfComponents[7], cfComponents[8], cfComponents[9],
                            cfComponents[10], cfComponents[11], cfComponents[12])
                        
                        units[unitKey] = {
                            unit = unit,
                            position = pos,
                            positionStr = string.format("%.6f, %.6f, %.6f", pos.X, pos.Y, pos.Z),
                            cframe = cf,
                            cframeStr = cfString,
                            name = unit.Name,
                            key = unitKey
                        }
                    end
                end
            end
        end
    end
    return units
end

-- Создание макроса
local function createMacro(name)
    return {
        name = name,
        actions = {},
        createdAt = os.time()
    }
end

-- Начать запись
local function startRecording(notifCallback)
    currentRecording = createMacro("Macro " .. os.date("%H:%M"))
    isRecording = true
    recordStartTime = tick()
    nextUnitId = 1
    trackedUnits = {}
    
    local startUnits = scanUnits()
    for key, unitData in pairs(startUnits) do
        trackedUnits[key] = {
            id = nextUnitId,
            name = unitData.name
        }
        nextUnitId = nextUnitId + 1
    end
    
    if notifCallback then notifCallback("⏺️ ЗАПИСЬ НАЧАТА", 2) end
    
    task.spawn(function()
        while isRecording do
            task.wait(0.2)
            
            local currentUnits = scanUnits()
            local currentTime = tick() - recordStartTime
            
            for key, unitData in pairs(currentUnits) do
                if not trackedUnits[key] then
                    local newId = nextUnitId
                    nextUnitId = nextUnitId + 1
                    trackedUnits[key] = {
                        id = newId,
                        name = unitData.name
                    }
                    
                    local placeAction = {
                        ID = newId,
                        Type = "PlaceUnit",
                        Unit = unitData.name,
                        Time = math.floor(currentTime * 10) / 10,
                        Position = unitData.positionStr,
                        CF = unitData.cframeStr
                    }
                    
                    table.insert(currentRecording.actions, placeAction)
                    
                    if notifCallback then 
                        notifCallback("➕ PlaceUnit: " .. unitData.name .. " (ID: " .. newId .. ")", 1) 
                    end
                end
            end
        end
    end)
end

-- Остановить запись
local function stopRecording(notifCallback)
    if not isRecording or not currentRecording then return end
    
    isRecording = false
    
    if #currentRecording.actions > 0 then
        table.insert(macros, currentRecording)
        if notifCallback then 
            notifCallback("✅ МАКРОС СОХРАНЕН - " .. #currentRecording.actions .. " действий", 2) 
        end
    else
        if notifCallback then 
            notifCallback("⚠️ Нет действий для сохранения", 2) 
        end
    end
    
    currentRecording = nil
    trackedUnits = {}
end

-- Воспроизвести макрос
local function playMacro(macro, notifCallback)
    if not macro or #macro.actions == 0 then
        if notifCallback then notifCallback("⚠️ Макрос пуст", 2) end
        return
    end
    
    isPlaying = true
    if notifCallback then notifCallback("▶️ ВОСПРОИЗВЕДЕНИЕ: " .. macro.name, 2) end
    
    local actions = macro.actions
    table.sort(actions, function(a, b) return (a.Time or 0) < (b.Time or 0) end)
    
    local startTime = tick()
    
    for i, action in ipairs(actions) do
        if not isPlaying then break end
        
        local waitTime = (action.Time or 0) - (tick() - startTime)
        if waitTime > 0 then task.wait(waitTime) end
        
        if action.Type == "PlaceUnit" then
            local posParts = {}
            for num in string.gmatch(action.Position or "", "[-]?%d+%.?%d*") do
                table.insert(posParts, tonumber(num))
            end
            
            if #posParts >= 3 then
                local targetPos = Vector3.new(posParts[1], posParts[2], posParts[3])
                local screenPos = workspace.CurrentCamera:WorldToViewportPoint(targetPos)
                
                if screenPos.Z > 0 then
                    VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, nil, 0)
                    task.wait(0.03)
                    VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, nil, 0)
                end
            end
        end
    end
    
    isPlaying = false
    if notifCallback then notifCallback("✅ Воспроизведение завершено", 2) end
end

-- ==========================================
-- RGB УВЕДОМЛЕНИЯ
-- ==========================================
local function showNotification(message, duration)
    duration = duration or 2
    
    local notif = Instance.new("Frame")
    notif.Parent = player.PlayerGui
    notif.Size = UDim2.new(0, 300, 0, 45)
    notif.Position = UDim2.new(0.5, -150, 0, -50)
    notif.BackgroundColor3 = colors.mainBg
    notif.BackgroundTransparency = 0.1
    notif.ZIndex = 200
    notif.ClipsDescendants = true
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 12)
    notifCorner.Parent = notif
    
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Parent = notif
    notifStroke.Thickness = 3
    
    local notifText = Instance.new("TextLabel")
    notifText.Parent = notif
    notifText.Size = UDim2.new(1, -10, 1, 0)
    notifText.Position = UDim2.new(0, 5, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.Font = Enum.Font.GothamBold
    notifText.TextSize = 14
    notifText.ZIndex = 201
    
    -- RGB анимация обводки
    spawn(function()
        local hue = 0
        while notif.Parent do
            hue = (hue + 0.01) % 1
            notifStroke.Color = Color3.fromHSV(hue, 1, 1)
            wait(0.02)
        end
    end)
    
    TweenService:Create(notif, TweenInfo.new(0.3), {
        Position = UDim2.new(0.5, -150, 0, 20)
    }):Play()
    
    task.wait(duration)
    
    if notif.Parent then
        TweenService:Create(notif, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, -150, 0, -50),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.3)
        notif:Destroy()
    end
end

-- ==========================================
-- GUI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZeexHub"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999

-- ОСНОВНОЕ ОКНО
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = colors.mainBg
mainFrame.BackgroundTransparency = 0.3
mainFrame.Size = UDim2.new(0, 450, 0, 300)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Selectable = true
mainFrame.ClipsDescendants = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Parent = mainFrame
stroke.Thickness = 3
stroke.Color = colors.accent

-- ВЕРХНЯЯ ПОЛОСКА
local titleBar = Instance.new("Frame")
titleBar.Parent = mainFrame
titleBar.BackgroundColor3 = colors.panelBg
titleBar.BackgroundTransparency = 0.2
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.ZIndex = 2

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 15)
titleCorner.Parent = titleBar

-- НАЗВАНИЕ
local titleText = Instance.new("TextLabel")
titleText.Parent = titleBar
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "⚡ ZEEXHUB"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16

-- КНОПКА СКРЫТИЯ
local hideBtn = Instance.new("TextButton")
hideBtn.Parent = titleBar
hideBtn.Size = UDim2.new(0, 25, 0, 25)
hideBtn.Position = UDim2.new(1, -60, 0.5, -12.5)
hideBtn.BackgroundColor3 = colors.button
hideBtn.Text = "−"
hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 18

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 6)
hideCorner.Parent = hideBtn

-- КРЕСТИК
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = titleBar
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0.5, -12.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 100)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- КНОПКА ВОЗВРАТА
local tabButton = Instance.new("TextButton")
tabButton.Parent = screenGui
tabButton.Size = UDim2.new(0, 40, 0, 40)
tabButton.Position = UDim2.new(1, -50, 0.5, -20)
tabButton.BackgroundColor3 = colors.accent
tabButton.Text = "⚡"
tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
tabButton.Font = Enum.Font.GothamBold
tabButton.TextSize = 20
tabButton.Visible = false
tabButton.ZIndex = 100

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 10)
tabCorner.Parent = tabButton

-- Функции скрытия/показа
hideBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    tabButton.Visible = true
end)

tabButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    tabButton.Visible = false
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ЛЕВАЯ ПАНЕЛЬ
local leftPanel = Instance.new("Frame")
leftPanel.Parent = mainFrame
leftPanel.Size = UDim2.new(0, 90, 1, -45)
leftPanel.Position = UDim2.new(0, 8, 0, 40)
leftPanel.BackgroundColor3 = colors.panelBg
leftPanel.BackgroundTransparency = 0.3
leftPanel.ZIndex = 5

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 10)
leftCorner.Parent = leftPanel

local leftStroke = Instance.new("UIStroke")
leftStroke.Parent = leftPanel
leftStroke.Color = colors.accent
leftStroke.Thickness = 2

-- Кнопки навигации
local function createNavButton(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Parent = leftPanel
    btn.Size = UDim2.new(0, 75, 0, 30)
    btn.Position = UDim2.new(0, 7, 0, yPos)
    btn.BackgroundColor3 = colors.button
    btn.BackgroundTransparency = 0.1
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 6
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    return btn
end

local mainBtn = createNavButton("MAIN", 10)
local macroBtn = createNavButton("MACRO", 45)
local settingsBtn = createNavButton("SET", 80)

-- РАБОЧАЯ ОБЛАСТЬ
local contentArea = Instance.new("Frame")
contentArea.Parent = mainFrame
contentArea.Size = UDim2.new(1, -110, 1, -45)
contentArea.Position = UDim2.new(0, 100, 0, 40)
contentArea.BackgroundColor3 = colors.panelBg
contentArea.BackgroundTransparency = 0.4
contentArea.ZIndex = 5
contentArea.ClipsDescendants = true

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 10)
contentCorner.Parent = contentArea

local contentStroke = Instance.new("UIStroke")
contentStroke.Parent = contentArea
contentStroke.Color = colors.accent
contentStroke.Thickness = 2

-- КОНТЕЙНЕРЫ ДЛЯ ВКЛАДОК
local mainContainer = Instance.new("Frame")
mainContainer.Parent = contentArea
mainContainer.Size = UDim2.new(1, -15, 1, -15)
mainContainer.Position = UDim2.new(0, 7, 0, 7)
mainContainer.BackgroundTransparency = 1
mainContainer.Visible = true
mainContainer.ZIndex = 6

local macroContainer = Instance.new("Frame")
macroContainer.Parent = contentArea
macroContainer.Size = UDim2.new(1, -15, 1, -15)
macroContainer.Position = UDim2.new(0, 7, 0, 7)
macroContainer.BackgroundTransparency = 1
macroContainer.Visible = false
macroContainer.ZIndex = 6

local settingsContainer = Instance.new("Frame")
settingsContainer.Parent = contentArea
settingsContainer.Size = UDim2.new(1, -15, 1, -15)
settingsContainer.Position = UDim2.new(0, 7, 0, 7)
settingsContainer.BackgroundTransparency = 1
settingsContainer.Visible = false
settingsContainer.ZIndex = 6

-- MAIN ВКЛАДКА
local mainTitle = Instance.new("TextLabel")
mainTitle.Parent = mainContainer
mainTitle.Size = UDim2.new(1, 0, 0, 25)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = "⚡ MAIN"
mainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
mainTitle.Font = Enum.Font.GothamBold
mainTitle.TextSize = 16

local mainPlaceholder = Instance.new("TextLabel")
mainPlaceholder.Parent = mainContainer
mainPlaceholder.Size = UDim2.new(1, 0, 0, 40)
mainPlaceholder.Position = UDim2.new(0, 0, 0.4, -20)
mainPlaceholder.BackgroundTransparency = 1
mainPlaceholder.Text = "Здесь пока пусто"
mainPlaceholder.TextColor3 = Color3.fromRGB(200, 200, 255)
mainPlaceholder.TextTransparency = 0.3
mainPlaceholder.Font = Enum.Font.Gotham
mainPlaceholder.TextSize = 14

-- MACRO ВКЛАДКА
local macroTitle = Instance.new("TextLabel")
macroTitle.Parent = macroContainer
macroTitle.Size = UDim2.new(1, 0, 0, 25)
macroTitle.BackgroundTransparency = 1
macroTitle.Text = "⚡ MACRO"
macroTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
macroTitle.Font = Enum.Font.GothamBold
macroTitle.TextSize = 16

-- ==========================================
-- ЗАТЕМНЕНИЕ И ОКНА
-- ==========================================
local overlay = Instance.new("Frame")
overlay.Parent = screenGui
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
createWindow.Parent = screenGui
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
createTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
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
listWindow.Parent = screenGui
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
listTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
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
-- MACRO КНОПКИ
-- ==========================================
local function createMacroButton(text, x, y, parent, actionType)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(0, 100, 0, 30)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = colors.button
    btn.BackgroundTransparency = 0.1
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 8
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    -- Анимация
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = colors.buttonAlt,
            Size = UDim2.new(0, 105, 0, 32)
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = colors.button,
            Size = UDim2.new(0, 100, 0, 30)
        }):Play()
    end)
    
    -- Логика кнопок
    if actionType == "create" then
        btn.MouseButton1Click:Connect(function()
            overlay.Visible = true
            createWindow.Visible = true
        end)
        
    elseif actionType == "list" then
        btn.MouseButton1Click:Connect(function()
            if #macros == 0 then
                showNotification("📋 Список макросов пуст", 2)
            else
                refreshList()
                overlay.Visible = true
                listWindow.Visible = true
            end
        end)
        
    elseif actionType == "refresh" then
        btn.MouseButton1Click:Connect(function()
            if listWindow.Visible then
                refreshList()
            end
            showNotification("🔄 Список обновлен", 1)
        end)
        
    elseif actionType == "load" then
        btn.MouseButton1Click:Connect(function()
            if selectedMacro then
                showNotification("📂 Загружен: " .. selectedMacro.name, 2)
            else
                showNotification("⚠️ Сначала выберите макрос в LIST", 2)
            end
        end)
        
    elseif actionType == "record" then
        btn.MouseButton1Click:Connect(function()
            if not isRecording then
                startRecording(showNotification)
                btn.Text = "⏹️ STOP"
                btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            else
                stopRecording(showNotification)
                btn.Text = "⏺️ RECORD"
                btn.BackgroundColor3 = colors.button
            end
        end)
        
    elseif actionType == "start" then
        btn.MouseButton1Click:Connect(function()
            if selectedMacro then
                playMacro(selectedMacro, showNotification)
            else
                showNotification("⚠️ Сначала выберите макрос в LIST", 2)
            end
        end)
    end
    
    return btn
end

-- Создаем кнопки
createMacroButton("📁 CREATE", 15, 30, macroContainer, "create")
createMacroButton("📋 LIST", 125, 30, macroContainer, "list")
createMacroButton("🔄 REFRESH", 235, 30, macroContainer, "refresh")
createMacroButton("📂 LOAD", 15, 70, macroContainer, "load")
createMacroButton("⏺️ RECORD", 125, 70, macroContainer, "record")
createMacroButton("▶️ START", 235, 70, macroContainer, "start")

-- SETTINGS ВКЛАДКА
local settingsTitle = Instance.new("TextLabel")
settingsTitle.Parent = settingsContainer
settingsTitle.Size = UDim2.new(1, 0, 0, 25)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "⚡ SETTINGS"
settingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 16

local settingsPlaceholder = Instance.new("TextLabel")
settingsPlaceholder.Parent = settingsContainer
settingsPlaceholder.Size = UDim2.new(1, 0, 0, 40)
settingsPlaceholder.Position = UDim2.new(0, 0, 0.4, -20)
settingsPlaceholder.BackgroundTransparency = 1
settingsPlaceholder.Text = "Скоро будет"
settingsPlaceholder.TextColor3 = Color3.fromRGB(200, 200, 255)
settingsPlaceholder.TextTransparency = 0.3
settingsPlaceholder.Font = Enum.Font.Gotham
settingsPlaceholder.TextSize = 14

-- НАВИГАЦИЯ
mainBtn.MouseButton1Click:Connect(function()
    mainContainer.Visible = true
    macroContainer.Visible = false
    settingsContainer.Visible = false
end)

macroBtn.MouseButton1Click:Connect(function()
    mainContainer.Visible = false
    macroContainer.Visible = true
    settingsContainer.Visible = false
end)

settingsBtn.MouseButton1Click:Connect(function()
    mainContainer.Visible = false
    macroContainer.Visible = false
    settingsContainer.Visible = true
end)

-- Обработчики окон
createConfirm.MouseButton1Click:Connect(function()
    local name = createInput.Text
    if name and name ~= "" then
        local newMacro = {
            name = name,
            actions = {},
            createdAt = os.time()
        }
        table.insert(macros, newMacro)
        showNotification("✨ Макрос создан: " .. name, 2)
        createInput.Text = ""
    else
        showNotification("⚠️ Введите имя макроса", 2)
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

-- ФУТЕР
local footer = Instance.new("TextLabel")
footer.Parent = mainFrame
footer.Size = UDim2.new(1, 0, 0, 18)
footer.Position = UDim2.new(0, 0, 1, -18)
footer.BackgroundTransparency = 1
footer.Text = "⚡ zeexHub ⚡"
footer.TextColor3 = Color3.fromRGB(200, 180, 255)
footer.TextTransparency = 0.2
footer.Font = Enum.Font.Gotham
footer.TextSize = 10

print("✅ ZEEXHUB ОБЪЕДИНЕННЫЙ | Все кнопки работают")
