local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ==========================================
-- ЗАГРУЗКА МАКРО СИСТЕМЫ
-- ==========================================
local MacroSystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/zeexHubLua/zeexHub/refs/heads/main/macroLogic.lua"))()
local macroLogic = setmetatable({}, MacroSystem)

-- ==========================================
-- ЦВЕТА
-- ==========================================
local colors = {
    mainBg = Color3.fromRGB(15, 0, 25),
    panelBg = Color3.fromRGB(25, 0, 40),
    -- и т.д.

-- ==========================================
-- ЦВЕТА
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

-- ==========================================
-- РАБОЧАЯ ОБЛАСТЬ
-- ==========================================
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

-- ==========================================
-- КОНТЕЙНЕРЫ
-- ==========================================
local mainContainer = Instance.new("ScrollingFrame")
mainContainer.Parent = contentArea
mainContainer.Size = UDim2.new(1, -5, 1, -5)
mainContainer.Position = UDim2.new(0, 2, 0, 2)
mainContainer.BackgroundTransparency = 1
mainContainer.Visible = true
mainContainer.ZIndex = 6
mainContainer.ScrollBarThickness = 4
mainContainer.ScrollBarImageColor3 = colors.accent
mainContainer.CanvasSize = UDim2.new(0, 0, 0, 600)
mainContainer.BorderSizePixel = 0

local macroContainer = Instance.new("ScrollingFrame")
macroContainer.Parent = contentArea
macroContainer.Size = UDim2.new(1, -5, 1, -5)
macroContainer.Position = UDim2.new(0, 2, 0, 2)
macroContainer.BackgroundTransparency = 1
macroContainer.Visible = false
macroContainer.ZIndex = 6
macroContainer.ScrollBarThickness = 4
macroContainer.ScrollBarImageColor3 = colors.accent
macroContainer.CanvasSize = UDim2.new(0, 0, 0, 600)
macroContainer.BorderSizePixel = 0

local settingsContainer = Instance.new("ScrollingFrame")
settingsContainer.Parent = contentArea
settingsContainer.Size = UDim2.new(1, -5, 1, -5)
settingsContainer.Position = UDim2.new(0, 2, 0, 2)
settingsContainer.BackgroundTransparency = 1
settingsContainer.Visible = false
settingsContainer.ZIndex = 6
settingsContainer.ScrollBarThickness = 4
settingsContainer.ScrollBarImageColor3 = colors.accent
settingsContainer.CanvasSize = UDim2.new(0, 0, 0, 300)
settingsContainer.BorderSizePixel = 0

-- ==========================================
-- MAIN ВКЛАДКА
-- ==========================================
local mainTitle = Instance.new("TextLabel")
mainTitle.Parent = mainContainer
mainTitle.Size = UDim2.new(1, -10, 0, 25)
mainTitle.Position = UDim2.new(0, 5, 0, 0)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = "⚡ MAIN"
mainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
mainTitle.Font = Enum.Font.GothamBold
mainTitle.TextSize = 16
mainTitle.ZIndex = 7

local function createToggle(text, yPos, parent)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Parent = parent
    toggleFrame.Size = UDim2.new(1, -20, 0, 40)
    toggleFrame.Position = UDim2.new(0, 10, 0, yPos)
    toggleFrame.BackgroundColor3 = colors.panelBg
    toggleFrame.BackgroundTransparency = 0.5
    toggleFrame.ZIndex = 7
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleFrame
    
    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Parent = toggleFrame
    toggleStroke.Color = colors.accent
    toggleStroke.Thickness = 1
    toggleStroke.Transparency = 0.5
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Parent = toggleFrame
    toggleLabel.Size = UDim2.new(1, -80, 1, 0)
    toggleLabel.Position = UDim2.new(0, 10, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = text
    toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleLabel.Font = Enum.Font.GothamBold
    toggleLabel.TextSize = 13
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.ZIndex = 8
    
    local switchTrack = Instance.new("Frame")
    switchTrack.Parent = toggleFrame
    switchTrack.Size = UDim2.new(0, 45, 0, 22)
    switchTrack.Position = UDim2.new(1, -55, 0.5, -11)
    switchTrack.BackgroundColor3 = colors.toggleBg
    switchTrack.ZIndex = 8
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = switchTrack
    
    local switchButton = Instance.new("Frame")
    switchButton.Parent = switchTrack
    switchButton.Size = UDim2.new(0, 18, 0, 18)
    switchButton.Position = UDim2.new(0, 2, 0.5, -9)
    switchButton.BackgroundColor3 = colors.toggleOff
    switchButton.ZIndex = 9
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = switchButton
    
    local buttonShadow = Instance.new("UIStroke")
    buttonShadow.Parent = switchButton
    buttonShadow.Color = Color3.fromRGB(0, 0, 0)
    buttonShadow.Thickness = 2
    buttonShadow.Transparency = 0.7
    
    local isEnabled = false
    
    local clickButton = Instance.new("TextButton")
    clickButton.Parent = toggleFrame
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.ZIndex = 10
    
    clickButton.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        
        if isEnabled then
            TweenService:Create(switchButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Position = UDim2.new(1, -20, 0.5, -9),
                BackgroundColor3 = colors.toggleOn
            }):Play()
            
            TweenService:Create(switchTrack, TweenInfo.new(0.3), {
                BackgroundColor3 = Color3.fromRGB(0, 150, 50)
            }):Play()
            
            TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
                Transparency = 0,
                Color = colors.toggleOn
            }):Play()
        else
            TweenService:Create(switchButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Position = UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = colors.toggleOff
            }):Play()
            
            TweenService:Create(switchTrack, TweenInfo.new(0.3), {
                BackgroundColor3 = colors.toggleBg
            }):Play()
            
            TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
                Transparency = 0.5,
                Color = colors.accent
            }):Play()
        end
        
        print(text .. ":", isEnabled and "ВКЛ ✅" or "ВЫКЛ ⭕")
    end)
    
    clickButton.MouseEnter:Connect(function()
        TweenService:Create(toggleFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.3
        }):Play()
        TweenService:Create(switchButton, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 20, 0, 20)
        }):Play()
    end)
    
    clickButton.MouseLeave:Connect(function()
        TweenService:Create(toggleFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.5
        }):Play()
        TweenService:Create(switchButton, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 18, 0, 18)
        }):Play()
    end)
    
    return toggleFrame, clickButton
end

createToggle("Auto Skip", 35, mainContainer)
createToggle("Auto x2 Speed", 85, mainContainer)
createToggle("Auto x3 Speed", 135, mainContainer)
createToggle("Auto Play Again", 185, mainContainer)

-- AUTO MODE С ВЫБОРОМ ВОЛНЫ
local autoModeFrame = Instance.new("Frame")
autoModeFrame.Parent = mainContainer
autoModeFrame.Size = UDim2.new(1, -20, 0, 40)
autoModeFrame.Position = UDim2.new(0, 10, 0, 235)
autoModeFrame.BackgroundColor3 = colors.panelBg
autoModeFrame.BackgroundTransparency = 0.5
autoModeFrame.ZIndex = 7

local autoModeCorner = Instance.new("UICorner")
autoModeCorner.CornerRadius = UDim.new(0, 8)
autoModeCorner.Parent = autoModeFrame

local autoModeStroke = Instance.new("UIStroke")
autoModeStroke.Parent = autoModeFrame
autoModeStroke.Color = colors.accent
autoModeStroke.Thickness = 1
autoModeStroke.Transparency = 0.5

local autoModeLabel = Instance.new("TextLabel")
autoModeLabel.Parent = autoModeFrame
autoModeLabel.Size = UDim2.new(0, 100, 1, 0)
autoModeLabel.Position = UDim2.new(0, 10, 0, 0)
autoModeLabel.BackgroundTransparency = 1
autoModeLabel.Text = "Auto Mode"
autoModeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
autoModeLabel.Font = Enum.Font.GothamBold
autoModeLabel.TextSize = 13
autoModeLabel.TextXAlignment = Enum.TextXAlignment.Left
autoModeLabel.ZIndex = 8

-- ОКНО ВЫБОРА ВОЛНЫ
local waveSelector = Instance.new("Frame")
waveSelector.Parent = autoModeFrame
waveSelector.Size = UDim2.new(0, 180, 0, 30)
waveSelector.Position = UDim2.new(1, -190, 0.5, -15)
waveSelector.BackgroundColor3 = colors.toggleBg
waveSelector.BackgroundTransparency = 0.3
waveSelector.ZIndex = 8

local waveSelectorCorner = Instance.new("UICorner")
waveSelectorCorner.CornerRadius = UDim.new(0, 6)
waveSelectorCorner.Parent = waveSelector

local waveLabel = Instance.new("TextLabel")
waveLabel.Parent = waveSelector
waveLabel.Size = UDim2.new(1, -30, 1, 0)
waveLabel.Position = UDim2.new(0, 10, 0, 0)
waveLabel.BackgroundTransparency = 1
waveLabel.Text = "Easy"
waveLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
waveLabel.Font = Enum.Font.Gotham
waveLabel.TextSize = 12
waveLabel.TextXAlignment = Enum.TextXAlignment.Left
waveLabel.ZIndex = 9

local waveArrow = Instance.new("TextLabel")
waveArrow.Parent = waveSelector
waveArrow.Size = UDim2.new(0, 20, 1, 0)
waveArrow.Position = UDim2.new(1, -25, 0, 0)
waveArrow.BackgroundTransparency = 1
waveArrow.Text = "▼"
waveArrow.TextColor3 = Color3.fromRGB(180, 180, 180)
waveArrow.Font = Enum.Font.GothamBold
waveArrow.TextSize = 10
waveArrow.ZIndex = 9

-- ВЫПАДАЮЩИЙ СПИСОК ВОЛН
local waveDropdown = Instance.new("ScrollingFrame")
waveDropdown.Parent = mainContainer
waveDropdown.Size = UDim2.new(0, 180, 0, 200)
waveDropdown.Position = UDim2.new(1, -195, 0, 280)
waveDropdown.BackgroundColor3 = colors.mainBg
waveDropdown.BackgroundTransparency = 0.1
waveDropdown.Visible = false
waveDropdown.ZIndex = 50
waveDropdown.ScrollBarThickness = 3
waveDropdown.ScrollBarImageColor3 = colors.accent
waveDropdown.CanvasSize = UDim2.new(0, 0, 0, 240)
waveDropdown.BorderSizePixel = 0

local waveDropdownCorner = Instance.new("UICorner")
waveDropdownCorner.CornerRadius = UDim.new(0, 8)
waveDropdownCorner.Parent = waveDropdown

local waveDropdownStroke = Instance.new("UIStroke")
waveDropdownStroke.Parent = waveDropdown
waveDropdownStroke.Color = colors.accent
waveDropdownStroke.Thickness = 2

-- СПИСОК ВОЛН
local waves = {"Easy", "Normal", "Hard", "Insane", "Impossible", "Apocalypse"}

for i, wave in ipairs(waves) do
    local waveItem = Instance.new("Frame")
    waveItem.Parent = waveDropdown
    waveItem.Size = UDim2.new(1, -10, 0, 35)
    waveItem.Position = UDim2.new(0, 5, 0, (i-1) * 40 + 5)
    waveItem.BackgroundColor3 = colors.panelBg
    waveItem.BackgroundTransparency = 0.5
    waveItem.ZIndex = 51
    
    local waveItemCorner = Instance.new("UICorner")
    waveItemCorner.CornerRadius = UDim.new(0, 6)
    waveItemCorner.Parent = waveItem
    
    local waveItemLabel = Instance.new("TextLabel")
    waveItemLabel.Parent = waveItem
    waveItemLabel.Size = UDim2.new(1, -10, 1, 0)
    waveItemLabel.Position = UDim2.new(0, 10, 0, 0)
    waveItemLabel.BackgroundTransparency = 1
    waveItemLabel.Text = wave
    waveItemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    waveItemLabel.Font = Enum.Font.GothamBold
    waveItemLabel.TextSize = 12
    waveItemLabel.TextXAlignment = Enum.TextXAlignment.Left
    waveItemLabel.ZIndex = 52
    
    local waveItemBtn = Instance.new("TextButton")
    waveItemBtn.Parent = waveItem
    waveItemBtn.Size = UDim2.new(1, 0, 1, 0)
    waveItemBtn.BackgroundTransparency = 1
    waveItemBtn.Text = ""
    waveItemBtn.ZIndex = 53
    
    waveItemBtn.MouseButton1Click:Connect(function()
        selectedWave = wave
        waveLabel.Text = wave
        waveLabel.TextColor3 = colors.toggleOn
        waveDropdown.Visible = false
        print("✅ Выбрана волна:", wave)
    end)
    
    waveItemBtn.MouseEnter:Connect(function()
        waveItem.BackgroundTransparency = 0.3
    end)
    
    waveItemBtn.MouseLeave:Connect(function()
        waveItem.BackgroundTransparency = 0.5
    end)
end

-- КЛИК ПО СЕЛЕКТОРУ ОТКРЫВАЕТ СПИСОК
local waveSelectorBtn = Instance.new("TextButton")
waveSelectorBtn.Parent = waveSelector
waveSelectorBtn.Size = UDim2.new(1, 0, 1, 0)
waveSelectorBtn.BackgroundTransparency = 1
waveSelectorBtn.Text = ""
waveSelectorBtn.ZIndex = 10

waveSelectorBtn.MouseButton1Click:Connect(function()
    waveDropdown.Visible = not waveDropdown.Visible
end)

waveSelectorBtn.MouseEnter:Connect(function()
    waveSelector.BackgroundTransparency = 0.1
end)

waveSelectorBtn.MouseLeave:Connect(function()
    waveSelector.BackgroundTransparency = 0.3
end)

-- ==========================================
-- MACRO ВКЛАДКА
-- ==========================================
local macroTitle = Instance.new("TextLabel")
macroTitle.Parent = macroContainer
macroTitle.Size = UDim2.new(1, -10, 0, 25)
macroTitle.Position = UDim2.new(0, 5, 0, 0)
macroTitle.BackgroundTransparency = 1
macroTitle.Text = "⚡ MACRO"
macroTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
macroTitle.Font = Enum.Font.GothamBold
macroTitle.TextSize = 16
macroTitle.ZIndex = 7

-- ЛЕВАЯ ЧАСТЬ
local macroLeftSection = Instance.new("Frame")
macroLeftSection.Parent = macroContainer
macroLeftSection.Size = UDim2.new(1, -10, 1, -35)
macroLeftSection.Position = UDim2.new(0, 5, 0, 30)
macroLeftSection.BackgroundTransparency = 1
macroLeftSection.ZIndex = 7

-- ОКНО СОЗДАНИЯ МАКРОСА
local createWindow = Instance.new("Frame")
createWindow.Parent = screenGui
createWindow.Size = UDim2.new(0, 300, 0, 150)
createWindow.Position = UDim2.new(0.5, -150, 0.5, -75)
createWindow.BackgroundColor3 = colors.mainBg
createWindow.BackgroundTransparency = 0.1
createWindow.Visible = false
createWindow.ZIndex = 200

local createCorner = Instance.new("UICorner")
createCorner.CornerRadius = UDim.new(0, 12)
createCorner.Parent = createWindow

local createStroke = Instance.new("UIStroke")
createStroke.Parent = createWindow
createStroke.Color = colors.accent
createStroke.Thickness = 3

local createTitle = Instance.new("TextLabel")
createTitle.Parent = createWindow
createTitle.Size = UDim2.new(1, -20, 0, 30)
createTitle.Position = UDim2.new(0, 10, 0, 10)
createTitle.BackgroundTransparency = 1
createTitle.Text = "📁 CREATE MACRO"
createTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
createTitle.Font = Enum.Font.GothamBold
createTitle.TextSize = 16
createTitle.ZIndex = 201

local macroNameBox = Instance.new("TextBox")
macroNameBox.Parent = createWindow
macroNameBox.Size = UDim2.new(1, -40, 0, 35)
macroNameBox.Position = UDim2.new(0, 20, 0, 50)
macroNameBox.BackgroundColor3 = colors.panelBg
macroNameBox.BackgroundTransparency = 0.3
macroNameBox.Text = ""
macroNameBox.PlaceholderText = "Введите название макроса..."
macroNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
macroNameBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
macroNameBox.Font = Enum.Font.Gotham
macroNameBox.TextSize = 14
macroNameBox.ZIndex = 201

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 8)
boxCorner.Parent = macroNameBox

local createConfirmBtn = Instance.new("TextButton")
createConfirmBtn.Parent = createWindow
createConfirmBtn.Size = UDim2.new(0, 120, 0, 35)
createConfirmBtn.Position = UDim2.new(0.5, -125, 1, -45)
createConfirmBtn.BackgroundColor3 = colors.toggleOn
createConfirmBtn.Text = "✓ CREATE"
createConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
createConfirmBtn.Font = Enum.Font.GothamBold
createConfirmBtn.TextSize = 14
createConfirmBtn.ZIndex = 201

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 8)
confirmCorner.Parent = createConfirmBtn

local createCancelBtn = Instance.new("TextButton")
createCancelBtn.Parent = createWindow
createCancelBtn.Size = UDim2.new(0, 120, 0, 35)
createCancelBtn.Position = UDim2.new(0.5, 5, 1, -45)
createCancelBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 100)
createCancelBtn.Text = "✕ CANCEL"
createCancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
createCancelBtn.Font = Enum.Font.GothamBold
createCancelBtn.TextSize = 14
createCancelBtn.ZIndex = 201

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 8)
cancelCorner.Parent = createCancelBtn

-- ВЫПАДАЮЩИЙ СПИСОК
local macroDropdown = Instance.new("ScrollingFrame")
macroDropdown.Parent = macroLeftSection
macroDropdown.Size = UDim2.new(0, 200, 0, 150)
macroDropdown.Position = UDim2.new(0, 125, 0, 100)
macroDropdown.BackgroundColor3 = colors.mainBg
macroDropdown.BackgroundTransparency = 0.1
macroDropdown.Visible = false
macroDropdown.ZIndex = 50
macroDropdown.ScrollBarThickness = 3
macroDropdown.ScrollBarImageColor3 = colors.accent
macroDropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
macroDropdown.BorderSizePixel = 0

local dropdownCorner = Instance.new("UICorner")
dropdownCorner.CornerRadius = UDim.new(0, 8)
dropdownCorner.Parent = macroDropdown

local dropdownStroke = Instance.new("UIStroke")
dropdownStroke.Parent = macroDropdown
dropdownStroke.Color = colors.accent
dropdownStroke.Thickness = 2

-- ФУНКЦИЯ ОБНОВЛЕНИЯ СПИСКА
local function updateMacroDropdown()
    for _, child in pairs(macroDropdown:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for i, macro in ipairs(macros) do
        local macroItem = Instance.new("Frame")
        macroItem.Parent = macroDropdown
        macroItem.Size = UDim2.new(1, -10, 0, 35)
        macroItem.Position = UDim2.new(0, 5, 0, (i-1) * 40 + 5)
        macroItem.BackgroundColor3 = colors.panelBg
        macroItem.BackgroundTransparency = 0.5
        macroItem.ZIndex = 51
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 6)
        itemCorner.Parent = macroItem
        
        local macroLabel = Instance.new("TextLabel")
        macroLabel.Parent = macroItem
        macroLabel.Size = UDim2.new(1, -10, 1, 0)
        macroLabel.Position = UDim2.new(0, 10, 0, 0)
        macroLabel.BackgroundTransparency = 1
        macroLabel.Text = "📄 " .. macro.name
        macroLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        macroLabel.Font = Enum.Font.GothamBold
        macroLabel.TextSize = 12
        macroLabel.TextXAlignment = Enum.TextXAlignment.Left
        macroLabel.ZIndex = 52
        
        local selectBtn = Instance.new("TextButton")
        selectBtn.Parent = macroItem
        selectBtn.Size = UDim2.new(1, 0, 1, 0)
        selectBtn.BackgroundTransparency = 1
        selectBtn.Text = ""
        selectBtn.ZIndex = 53
        
        selectBtn.MouseButton1Click:Connect(function()
            selectedMacro = macro.name
            for _, child in pairs(macroLeftSection:GetChildren()) do
                if child.Name == "MacroSelector" then
                    local label = child:FindFirstChild("TextLabel")
                    if label then
                        label.Text = "📄 " .. selectedMacro
                        label.TextColor3 = colors.toggleOn
                    end
                end
            end
            macroDropdown.Visible = false
            print("✅ Выбран макрос:", selectedMacro)
        end)
        
        selectBtn.MouseEnter:Connect(function()
            macroItem.BackgroundTransparency = 0.3
        end)
        
        selectBtn.MouseLeave:Connect(function()
            macroItem.BackgroundTransparency = 0.5
        end)
    end
    
    macroDropdown.CanvasSize = UDim2.new(0, 0, 0, #macros * 40 + 10)
end

-- ОБРАБОТЧИКИ CREATE WINDOW
createConfirmBtn.MouseButton1Click:Connect(function()
    local macroName = macroNameBox.Text
    if macroName ~= "" then
        table.insert(macros, {
            name = macroName,
            actions = {}
        })
        print("✅ Макрос создан:", macroName)
        createWindow.Visible = false
        updateMacroDropdown()
        saveMacros()
    else
        print("❌ Введите название макроса!")
    end
end)

createCancelBtn.MouseButton1Click:Connect(function()
    createWindow.Visible = false
end)

-- ФУНКЦИЯ ДЛЯ КНОПОК
local function createMacroButton(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Parent = macroLeftSection
    btn.Size = UDim2.new(0, 110, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = colors.button
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 8
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = colors.buttonAlt
        btn.BackgroundTransparency = 0
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = colors.button
        btn.BackgroundTransparency = 0.2
    end)
    
    return btn
end

-- КНОПКА CREATE
local createBtn = createMacroButton("📁 Create", 10)
createBtn.MouseButton1Click:Connect(function()
    createWindow.Visible = true
    macroNameBox.Text = ""
end)

-- КНОПКА REFRESH
local refreshBtn = createMacroButton("🔄 Refresh", 55)
refreshBtn.MouseButton1Click:Connect(function()
    updateMacroDropdown()
    print("🔄 Список обновлен")
end)

-- НАДПИСЬ "List"
local listLabel = Instance.new("TextLabel")
listLabel.Parent = macroLeftSection
listLabel.Size = UDim2.new(0, 110, 0, 35)
listLabel.Position = UDim2.new(0, 5, 0, 100)
listLabel.BackgroundColor3 = colors.button
listLabel.BackgroundTransparency = 0.2
listLabel.Text = "📋 List"
listLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
listLabel.Font = Enum.Font.GothamBold
listLabel.TextSize = 12
listLabel.ZIndex = 8

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = listLabel

-- ОКНО ВЫБОРА МАКРОСА
local macroSelector = Instance.new("Frame")
macroSelector.Name = "MacroSelector"
macroSelector.Parent = macroLeftSection
macroSelector.Size = UDim2.new(0, 200, 0, 35)
macroSelector.Position = UDim2.new(0, 125, 0, 100)
macroSelector.BackgroundColor3 = colors.panelBg
macroSelector.BackgroundTransparency = 0.5
macroSelector.ZIndex = 8

local selectorCorner = Instance.new("UICorner")
selectorCorner.CornerRadius = UDim.new(0, 6)
selectorCorner.Parent = macroSelector

local selectorLabel = Instance.new("TextLabel")
selectorLabel.Parent = macroSelector
selectorLabel.Size = UDim2.new(1, -30, 1, 0)
selectorLabel.Position = UDim2.new(0, 10, 0, 0)
selectorLabel.BackgroundTransparency = 1
selectorLabel.Text = "Выберите макрос..."
selectorLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
selectorLabel.Font = Enum.Font.Gotham
selectorLabel.TextSize = 11
selectorLabel.TextXAlignment = Enum.TextXAlignment.Left
selectorLabel.ZIndex = 9

local arrowLabel = Instance.new("TextLabel")
arrowLabel.Parent = macroSelector
arrowLabel.Size = UDim2.new(0, 20, 1, 0)
arrowLabel.Position = UDim2.new(1, -25, 0, 0)
arrowLabel.BackgroundTransparency = 1
arrowLabel.Text = "▼"
arrowLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
arrowLabel.Font = Enum.Font.GothamBold
arrowLabel.TextSize = 10
arrowLabel.ZIndex = 9

local selectorBtn = Instance.new("TextButton")
selectorBtn.Parent = macroSelector
selectorBtn.Size = UDim2.new(1, 0, 1, 0)
selectorBtn.BackgroundTransparency = 1
selectorBtn.Text = ""
selectorBtn.ZIndex = 10

selectorBtn.MouseButton1Click:Connect(function()
    macroDropdown.Visible = not macroDropdown.Visible
    updateMacroDropdown()
end)

selectorBtn.MouseEnter:Connect(function()
    macroSelector.BackgroundTransparency = 0.3
end)

selectorBtn.MouseLeave:Connect(function()
    macroSelector.BackgroundTransparency = 0.5
end)

-- ФУНКЦИЯ ДЛЯ ШИРОКИХ ПЕРЕКЛЮЧАТЕЛЕЙ
local function createWideToggle(text, yPos, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Parent = macroLeftSection
    toggleFrame.Size = UDim2.new(1, -15, 0, 40)
    toggleFrame.Position = UDim2.new(0, 5, 0, yPos)
    toggleFrame.BackgroundColor3 = colors.panelBg
    toggleFrame.BackgroundTransparency = 0.5
    toggleFrame.ZIndex = 7
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleFrame
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Parent = toggleFrame
    toggleLabel.Size = UDim2.new(1, -80, 1, 0)
    toggleLabel.Position = UDim2.new(0, 10, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = text
    toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleLabel.Font = Enum.Font.GothamBold
    toggleLabel.TextSize = 13
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.ZIndex = 8
    
    local switchTrack = Instance.new("Frame")
    switchTrack.Parent = toggleFrame
    switchTrack.Size = UDim2.new(0, 45, 0, 22)
    switchTrack.Position = UDim2.new(1, -55, 0.5, -11)
    switchTrack.BackgroundColor3 = colors.toggleBg
    switchTrack.ZIndex = 8
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = switchTrack
    
    local switchButton = Instance.new("Frame")
    switchButton.Parent = switchTrack
    switchButton.Size = UDim2.new(0, 18, 0, 18)
    switchButton.Position = UDim2.new(0, 2, 0.5, -9)
    switchButton.BackgroundColor3 = colors.toggleOff
    switchButton.ZIndex = 9
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = switchButton
    
    local isEnabled = false
    
    local clickButton = Instance.new("TextButton")
    clickButton.Parent = toggleFrame
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.ZIndex = 10
    
    clickButton.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        
        if isEnabled then
            TweenService:Create(switchButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Position = UDim2.new(1, -20, 0.5, -9),
                BackgroundColor3 = colors.toggleOn
            }):Play()
            
            TweenService:Create(switchTrack, TweenInfo.new(0.3), {
                BackgroundColor3 = Color3.fromRGB(0, 150, 50)
            }):Play()
        else
            TweenService:Create(switchButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Position = UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = colors.toggleOff
            }):Play()
            
            TweenService:Create(switchTrack, TweenInfo.new(0.3), {
                BackgroundColor3 = colors.toggleBg
            }):Play()
        end
        
        if callback then
            callback(isEnabled)
        end
        
        print(text .. ":", isEnabled and "ВКЛ ✅" or "ВЫКЛ ⭕")
    end)
    
    return toggleFrame
end

-- ПЕРЕКЛЮЧАТЕЛИ
createWideToggle("⏺️ Record Macro", 145, function(enabled)
    isRecording = enabled
end)

createWideToggle("▶️ Play Macro", 195, function(enabled)
    isPlaying = enabled
    if useHotkey then
        hotkeyButton.Visible = enabled
    end
end)

createWideToggle("⏱️ Time Placement", 245, function(enabled)
    print("Time Placement:", enabled)
end)

createWideToggle("📍 Unit Placement", 295, function(enabled)
    print("Unit Placement:", enabled)
end)

createWideToggle("🔁 Loop Mode", 345, function(enabled)
    loopMode = enabled
end)

createWideToggle("⌨️ Hotkey", 395, function(enabled)
    useHotkey = enabled
    if enabled and isPlaying then
        hotkeyButton.Visible = true
    else
        hotkeyButton.Visible = false
    end
end)

-- ==========================================
-- SETTINGS ВКЛАДКА
-- ==========================================
local settingsTitle = Instance.new("TextLabel")
settingsTitle.Parent = settingsContainer
settingsTitle.Size = UDim2.new(1, -10, 0, 25)
settingsTitle.Position = UDim2.new(0, 5, 0, 0)
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

-- ==========================================
-- НАВИГАЦИЯ
-- ==========================================
mainBtn.MouseButton1Click:Connect(function()
    mainContainer.Visible = true
    macroContainer.Visible = false
    settingsContainer.Visible = false
end)

macroBtn.MouseButton1Click:Connect(function()
    mainContainer.Visible = false
    macroContainer.Visible = true
    settingsContainer.Visible = false
    updateMacroDropdown()
end)

settingsBtn.MouseButton1Click:Connect(function()
    mainContainer.Visible = false
    macroContainer.Visible = false
    settingsContainer.Visible = true
end)

-- ==========================================
-- ФУТЕР
-- ==========================================
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

-- ЗАГРУЖАЕМ СОХРАНЕННЫЕ МАКРОСЫ
loadMacros()
updateMacroDropdown()

print("✅ UI ЗАГРУЖЕН ПОЛНОСТЬЮ")
print("📌 Функционал MACRO готов")
print("💾 Автосохранение включено")
print("🌈 RGB обводка активирована")
print("⚡ ZeexHub by zeenixxs")
