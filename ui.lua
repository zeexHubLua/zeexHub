local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ==========================================
-- ЦВЕТА (ТОЛЬКО ОДИН РАЗ!)
-- ==========================================
local colors = {
    mainBg = Color3.fromRGB(15, 0, 25),
    panelBg = Color3.fromRGB(25, 0, 40),
    button = Color3.fromRGB(80, 0, 130),
    buttonAlt = Color3.fromRGB(120, 0, 180),
    text = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(160, 0, 255),
    toggleOn = Color3.fromRGB(0, 255, 100),
    toggleOff = Color3.fromRGB(100, 100, 100),
    toggleBg = Color3.fromRGB(40, 40, 40)
}

-- ==========================================
-- СИСТЕМА СОХРАНЕНИЯ МАКРОСОВ
-- ==========================================
local macros = {}
local selectedMacro = nil
local isRecording = false
local isPlaying = false
local loopMode = false
local useHotkey = false
local selectedWave = "Easy"

-- Сохранение макросов
local function saveMacros()
    local success, err = pcall(function()
        if writefile then
            local data = game:GetService("HttpService"):JSONEncode(macros)
            writefile("zeexhub_macros.json", data)
            print("✅ Макросы сохранены")
        end
    end)
    if not success then
        warn("❌ Ошибка сохранения:", err)
    end
end

-- Загрузка макросов
local function loadMacros()
    local success, err = pcall(function()
        if readfile and isfile and isfile("zeexhub_macros.json") then
            local data = readfile("zeexhub_macros.json")
            macros = game:GetService("HttpService"):JSONDecode(data)
            print("✅ Макросы загружены:", #macros, "шт.")
        end
    end)
    if not success then
        warn("❌ Ошибка загрузки:", err)
    end
end

-- ==========================================
-- ГЛАВНЫЙ GUI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZeexHub"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999

-- Удаляем старую версию если есть
if player.PlayerGui:FindFirstChild("ZeexHub") then
    player.PlayerGui.ZeexHub:Destroy()
    wait(0.1)
end

screenGui.Parent = player:WaitForChild("PlayerGui")

-- ОСНОВНОЕ ОКНО
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = colors.mainBg
mainFrame.BackgroundTransparency = 0.3
mainFrame.Size = UDim2.new(0, 450, 0, 300)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
mainFrame.Active = true
mainFrame.Selectable = true
mainFrame.ClipsDescendants = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = mainFrame

-- RGB ОБВОДКА
local stroke = Instance.new("UIStroke")
stroke.Parent = mainFrame
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(255, 0, 0)

-- RGB АНИМАЦИЯ
local hue = 0
RunService.RenderStepped:Connect(function()
    hue = (hue + 0.005) % 1
    stroke.Color = Color3.fromHSV(hue, 1, 1)
end)

-- ==========================================
-- ВЕРХНЯЯ ПОЛОСКА
-- ==========================================
local titleBar = Instance.new("Frame")
titleBar.Parent = mainFrame
titleBar.BackgroundColor3 = colors.panelBg
titleBar.BackgroundTransparency = 0.2
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.ZIndex = 2
titleBar.Active = true

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 15)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Parent = titleBar
titleText.Size = UDim2.new(0, 150, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "⚡ ZEEXHUB"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16

local authorText = Instance.new("TextLabel")
authorText.Parent = titleBar
authorText.Size = UDim2.new(0, 150, 1, 0)
authorText.Position = UDim2.new(1, -160, 0, 0)
authorText.BackgroundTransparency = 1
authorText.Text = "by: zeenixxs"
authorText.TextColor3 = Color3.fromRGB(180, 180, 255)
authorText.TextXAlignment = Enum.TextXAlignment.Right
authorText.Font = Enum.Font.GothamBold
authorText.TextSize = 11
authorText.TextTransparency = 0.3

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

-- ПЕРЕТАСКИВАНИЕ
local dragging = false
local dragInput, mousePos, framePos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        mainFrame.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

-- КНОПКА ОТКРЫТИЯ (TAB)
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

-- HOTKEY КНОПКА НА ЭКРАНЕ
local hotkeyButton = Instance.new("TextButton")
hotkeyButton.Parent = screenGui
hotkeyButton.Size = UDim2.new(0, 50, 0, 50)
hotkeyButton.Position = UDim2.new(1, -70, 0, 50)
hotkeyButton.BackgroundColor3 = colors.toggleOn
hotkeyButton.Text = "▶"
hotkeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hotkeyButton.Font = Enum.Font.GothamBold
hotkeyButton.TextSize = 24
hotkeyButton.Visible = false
hotkeyButton.ZIndex = 100

local hotkeyCorner = Instance.new("UICorner")
hotkeyCorner.CornerRadius = UDim.new(0, 10)
hotkeyCorner.Parent = hotkeyButton

hotkeyButton.MouseButton1Click:Connect(function()
    isPlaying = not isPlaying
    if isPlaying then
        hotkeyButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        hotkeyButton.Text = "⏸"
        print("⏸ Макро остановлен")
    else
        hotkeyButton.BackgroundColor3 = colors.toggleOn
        hotkeyButton.Text = "▶"
        print("▶ Макро запущен")
    end
end)

-- ==========================================
-- ЛЕВАЯ ПАНЕЛЬ
-- ==========================================
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

-- Продолжение в следующем сообщении...
