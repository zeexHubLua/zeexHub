--[[
    ZEEXHUB - КОМПАКТНАЯ ВЕРСИЯ 450x300
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ЦВЕТА
local colors = {
    mainBg = Color3.fromRGB(15, 0, 25),
    panelBg = Color3.fromRGB(25, 0, 40),
    button = Color3.fromRGB(80, 0, 130),
    text = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(160, 0, 255)
}

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZeexHub"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999

-- ОСНОВНОЕ ОКНО (450x300)
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

-- КНОПКА ВОЗВРАТА (тоже уменьшил)
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

-- ЛЕВАЯ ПАНЕЛЬ (уже)
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

-- Кнопки навигации (поменьше)
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

-- MACRO ВКЛАДКА (кнопки тоже уменьшил)
local macroTitle = Instance.new("TextLabel")
macroTitle.Parent = macroContainer
macroTitle.Size = UDim2.new(1, 0, 0, 25)
macroTitle.BackgroundTransparency = 1
macroTitle.Text = "⚡ MACRO"
macroTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
macroTitle.Font = Enum.Font.GothamBold
macroTitle.TextSize = 16

local function createMacroButton(text, x, y, parent)
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
    
    return btn
end

-- Ряд 1 (сместил под размеры)
createMacroButton("📁 CREATE", 15, 30, macroContainer)
createMacroButton("📋 LIST", 125, 30, macroContainer)
createMacroButton("🔄 REFRESH", 235, 30, macroContainer)

-- Ряд 2
createMacroButton("📂 LOAD", 15, 70, macroContainer)
createMacroButton("⏺️ RECORD", 125, 70, macroContainer)
createMacroButton("▶️ START", 235, 70, macroContainer)

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

print("✅ КОМПАКТ 450x300 | Все кнопки на месте")
