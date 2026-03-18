-- ==========================================
-- ZEEXHUB UI - ПК + МОБИЛЬНАЯ ВЕРСИЯ (ИСПРАВЛЕНО)
-- ==========================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ОПРЕДЕЛЯЕМ УСТРОЙСТВО
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- ==========================================
-- ЦВЕТА
-- ==========================================
local colors = {
    mainBg    = Color3.fromRGB(15, 0, 25),
    panelBg   = Color3.fromRGB(25, 0, 40),
    button    = Color3.fromRGB(80, 0, 130),
    buttonAlt = Color3.fromRGB(120, 0, 180),
    text      = Color3.fromRGB(255, 255, 255),
    accent    = Color3.fromRGB(160, 0, 255),
    toggleOn  = Color3.fromRGB(0, 255, 100),
    toggleOff = Color3.fromRGB(100, 100, 100),
    toggleBg  = Color3.fromRGB(40, 40, 40)
}

-- ==========================================
-- СИСТЕМА СОХРАНЕНИЯ МАКРОСОВ
-- ==========================================
local macros        = {}
local selectedMacro = nil
local isRecording   = false
local isPlaying     = false
local loopMode      = false
local useHotkey     = false
local selectedWave  = "Easy"

local function saveMacros()
    if not (writefile and type(writefile) == "function") then
        print("⚠️ writefile недоступна")
        return
    end
    local ok, err = pcall(function()
        if macros and #macros > 0 then
            local data = game:GetService("HttpService"):JSONEncode(macros)
            if data then writefile("zeexhub_macros.json", data) end
        end
    end)
    if not ok then warn("❌ Ошибка сохранения:", err) end
end

local function loadMacros()
    if not (readfile and isfile and type(readfile) == "function" and type(isfile) == "function") then return end
    local ok, err = pcall(function()
        if isfile("zeexhub_macros.json") then
            local data = readfile("zeexhub_macros.json")
            if data and #data > 0 then
                local decoded = game:GetService("HttpService"):JSONDecode(data)
                if decoded and type(decoded) == "table" then
                    macros = decoded
                end
            end
        end
    end)
    if not ok then warn("❌ Ошибка загрузки:", err) end
end

-- ==========================================
-- ГЛАВНЫЙ GUI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "ZeexHub"
screenGui.Parent          = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.DisplayOrder    = 999
-- [ИСПРАВЛЕНО] Sibling — ZIndex работает внутри каждой ветки отдельно
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling

-- ОСНОВНОЕ ОКНО
local mainFrame = Instance.new("Frame")
mainFrame.Parent               = screenGui
mainFrame.BackgroundColor3     = colors.mainBg
mainFrame.BackgroundTransparency = 0.3
mainFrame.ClipsDescendants     = true
mainFrame.Active               = true

-- [ИСПРАВЛЕНО] Мобильный: компактный размер вместо на весь экран
if isMobile then
    mainFrame.Size     = UDim2.new(0, 340, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -170, 0.5, -250)
else
    mainFrame.Size     = UDim2.new(0, 450, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
end

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = mainFrame

-- RGB ОБВОДКА
local stroke = Instance.new("UIStroke")
stroke.Parent    = mainFrame
stroke.Thickness = 3
stroke.Color     = Color3.fromRGB(255, 0, 0)

local hue = 0
RunService.RenderStepped:Connect(function()
    hue = (hue + 0.005) % 1
    stroke.Color = Color3.fromHSV(hue, 1, 1)
end)

-- ==========================================
-- ВЕРХНЯЯ ПОЛОСКА
-- ==========================================
local titleBarH = isMobile and 55 or 35

local titleBar = Instance.new("Frame")
titleBar.Parent               = mainFrame
titleBar.BackgroundColor3     = colors.panelBg
titleBar.BackgroundTransparency = 0.2
titleBar.Size                 = UDim2.new(1, 0, 0, titleBarH)
titleBar.Active               = true

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 15)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Parent              = titleBar
titleText.Size                = UDim2.new(0, 150, 1, 0)
titleText.Position            = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text                = "⚡ ZEEXHUB"
titleText.TextColor3          = Color3.fromRGB(255, 255, 255)
titleText.TextXAlignment      = Enum.TextXAlignment.Left
titleText.Font                = Enum.Font.GothamBold
titleText.TextSize            = isMobile and 14 or 16

local authorText = Instance.new("TextLabel")
authorText.Parent             = titleBar
authorText.Size               = UDim2.new(0, 150, 1, 0)
authorText.Position           = UDim2.new(1, -160, 0, 0)
authorText.BackgroundTransparency = 1
authorText.Text               = "by: zeenixxs"
authorText.TextColor3         = Color3.fromRGB(180, 180, 255)
authorText.TextXAlignment     = Enum.TextXAlignment.Right
authorText.Font               = Enum.Font.GothamBold
authorText.TextSize           = 11
authorText.TextTransparency   = 0.3

-- [ИСПРАВЛЕНО] ZIndex кнопок выше titleBar + используем Activated
local btnSize = isMobile and 45 or 25

local hideBtn = Instance.new("TextButton")
hideBtn.Parent          = titleBar
hideBtn.Size            = UDim2.new(0, btnSize, 0, btnSize)
hideBtn.Position        = UDim2.new(1, isMobile and -100 or -62, 0.5, -btnSize/2)
hideBtn.BackgroundColor3 = colors.button
hideBtn.Text            = "−"
hideBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
hideBtn.Font            = Enum.Font.GothamBold
hideBtn.TextSize        = isMobile and 24 or 18
hideBtn.ZIndex          = 10   -- [ИСПРАВЛЕНО]

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 6)
hideCorner.Parent = hideBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Parent          = titleBar
closeBtn.Size            = UDim2.new(0, btnSize, 0, btnSize)
closeBtn.Position        = UDim2.new(1, isMobile and -50 or -32, 0.5, -btnSize/2)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 100)
closeBtn.Text            = "✕"
closeBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
closeBtn.Font            = Enum.Font.GothamBold
closeBtn.TextSize        = isMobile and 20 or 14
closeBtn.ZIndex          = 10   -- [ИСПРАВЛЕНО]

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- ==========================================
-- ПЕРЕТАСКИВАНИЕ
-- ==========================================
local dragging  = false
local dragInput = nil
local mousePos  = nil
local framePos  = nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
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
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        mainFrame.Position = UDim2.new(
            framePos.X.Scale, framePos.X.Offset + delta.X,
            framePos.Y.Scale, framePos.Y.Offset + delta.Y
        )
    end
end)

-- ==========================================
-- КНОПКА ОТКРЫТИЯ (когда свёрнуто)
-- ==========================================
local tabButton = Instance.new("TextButton")
tabButton.Parent          = screenGui
tabButton.Size            = UDim2.new(0, 40, 0, 40)
tabButton.Position        = UDim2.new(1, -50, 0.5, -20)
tabButton.BackgroundColor3 = colors.accent
tabButton.Text            = "⚡"
tabButton.TextColor3      = Color3.fromRGB(255, 255, 255)
tabButton.Font            = Enum.Font.GothamBold
tabButton.TextSize        = 20
tabButton.Visible         = false
tabButton.ZIndex          = 100

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 10)
tabCorner.Parent = tabButton

-- ==========================================
-- [ИСПРАВЛЕНО] Все кнопки через Activated (ПК + мобильные)
-- ==========================================
hideBtn.Activated:Connect(function()
    mainFrame.Visible  = false
    tabButton.Visible  = true
end)

tabButton.Activated:Connect(function()
    mainFrame.Visible  = true
    tabButton.Visible  = false
end)

closeBtn.Activated:Connect(function()
    screenGui:Destroy()
end)

-- HOTKEY КНОПКА
local hotkeyButton = Instance.new("TextButton")
hotkeyButton.Parent          = screenGui
hotkeyButton.Size            = UDim2.new(0, 50, 0, 50)
hotkeyButton.Position        = UDim2.new(1, -70, 0, 50)
hotkeyButton.BackgroundColor3 = colors.toggleOn
hotkeyButton.Text            = "▶"
hotkeyButton.TextColor3      = Color3.fromRGB(255, 255, 255)
hotkeyButton.Font            = Enum.Font.GothamBold
hotkeyButton.TextSize        = 24
hotkeyButton.Visible         = false
hotkeyButton.ZIndex          = 100

local hotkeyCorner = Instance.new("UICorner")
hotkeyCorner.CornerRadius = UDim.new(0, 10)
hotkeyCorner.Parent = hotkeyButton

hotkeyButton.Activated:Connect(function()
    isPlaying = not isPlaying
    if isPlaying then
        hotkeyButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        hotkeyButton.Text = "⏸"
    else
        hotkeyButton.BackgroundColor3 = colors.toggleOn
        hotkeyButton.Text = "▶"
    end
end)

-- ==========================================
-- ЛЕВАЯ ПАНЕЛЬ
-- ==========================================
local leftPanelW = isMobile and 100 or 90
local contentOffsetY = titleBarH + 5

local leftPanel = Instance.new("Frame")
leftPanel.Parent               = mainFrame
leftPanel.Size                 = UDim2.new(0, leftPanelW, 1, -contentOffsetY - 18)
leftPanel.Position             = UDim2.new(0, 5, 0, contentOffsetY)
leftPanel.BackgroundColor3     = colors.panelBg
leftPanel.BackgroundTransparency = 0.3
leftPanel.ZIndex               = 2

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 10)
leftCorner.Parent = leftPanel

local leftStroke = Instance.new("UIStroke")
leftStroke.Parent    = leftPanel
leftStroke.Color     = colors.accent
leftStroke.Thickness = 2

local function createNavButton(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Parent               = leftPanel
    btn.Size                 = UDim2.new(1, -10, 0, 30)
    btn.Position             = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3     = colors.button
    btn.BackgroundTransparency = 0.1
    btn.Text                 = text
    btn.TextColor3           = Color3.fromRGB(255, 255, 255)
    btn.Font                 = Enum.Font.GothamBold
    btn.TextSize             = isMobile and 10 or 12
    btn.ZIndex               = 3

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = colors.buttonAlt end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = colors.button end)

    return btn
end

local mainBtn     = createNavButton("MAIN",  10)
local macroBtn    = createNavButton("MACRO", 45)
local settingsBtn = createNavButton("SET",   80)

-- ==========================================
-- РАБОЧАЯ ОБЛАСТЬ
-- ==========================================
local contentArea = Instance.new("Frame")
contentArea.Parent               = mainFrame
contentArea.Size                 = UDim2.new(1, -(leftPanelW + 15), 1, -contentOffsetY - 18)
contentArea.Position             = UDim2.new(0, leftPanelW + 10, 0, contentOffsetY)
contentArea.BackgroundColor3     = colors.panelBg
contentArea.BackgroundTransparency = 0.4
contentArea.ClipsDescendants     = true
contentArea.ZIndex               = 2

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 10)
contentCorner.Parent = contentArea

local contentStroke = Instance.new("UIStroke")
contentStroke.Parent    = contentArea
contentStroke.Color     = colors.accent
contentStroke.Thickness = 2

-- ==========================================
-- КОНТЕЙНЕРЫ
-- ==========================================
local function makeScroll(visible)
    local sf = Instance.new("ScrollingFrame")
    sf.Parent               = contentArea
    sf.Size                 = UDim2.new(1, -5, 1, -5)
    sf.Position             = UDim2.new(0, 2, 0, 2)
    sf.BackgroundTransparency = 1
    sf.Visible              = visible
    sf.ZIndex               = 3
    sf.ScrollBarThickness   = 4
    sf.ScrollBarImageColor3 = colors.accent
    sf.BorderSizePixel      = 0
    sf.CanvasSize           = UDim2.new(0, 0, 0, 600)
    return sf
end

local mainContainer     = makeScroll(true)
local macroContainer    = makeScroll(false)
local settingsContainer = makeScroll(false)
settingsContainer.CanvasSize = UDim2.new(0, 0, 0, 300)

-- ==========================================
-- MAIN ВКЛАДКА
-- ==========================================
local mainTitle = Instance.new("TextLabel")
mainTitle.Parent             = mainContainer
mainTitle.Size               = UDim2.new(1, -10, 0, 25)
mainTitle.Position           = UDim2.new(0, 5, 0, 0)
mainTitle.BackgroundTransparency = 1
mainTitle.Text               = "⚡ MAIN"
mainTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
mainTitle.Font               = Enum.Font.GothamBold
mainTitle.TextSize           = 16
mainTitle.ZIndex             = 4

-- ФУНКЦИЯ СОЗДАНИЯ TOGGLE
local function createToggle(text, yPos, parent)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Parent               = parent
    toggleFrame.Size                 = UDim2.new(1, -20, 0, 40)
    toggleFrame.Position             = UDim2.new(0, 10, 0, yPos)
    toggleFrame.BackgroundColor3     = colors.panelBg
    toggleFrame.BackgroundTransparency = 0.5
    toggleFrame.ZIndex               = 4

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = toggleFrame

    local ts = Instance.new("UIStroke")
    ts.Parent       = toggleFrame
    ts.Color        = colors.accent
    ts.Thickness    = 1
    ts.Transparency = 0.5

    local label = Instance.new("TextLabel")
    label.Parent             = toggleFrame
    label.Size               = UDim2.new(1, -80, 1, 0)
    label.Position           = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text               = text
    label.TextColor3         = Color3.fromRGB(255, 255, 255)
    label.Font               = Enum.Font.GothamBold
    label.TextSize           = 13
    label.TextXAlignment     = Enum.TextXAlignment.Left
    label.ZIndex             = 5

    local track = Instance.new("Frame")
    track.Parent          = toggleFrame
    track.Size            = UDim2.new(0, 45, 0, 22)
    track.Position        = UDim2.new(1, -55, 0.5, -11)
    track.BackgroundColor3 = colors.toggleBg
    track.ZIndex          = 5

    local trc = Instance.new("UICorner")
    trc.CornerRadius = UDim.new(1, 0)
    trc.Parent = track

    local knob = Instance.new("Frame")
    knob.Parent          = track
    knob.Size            = UDim2.new(0, 18, 0, 18)
    knob.Position        = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = colors.toggleOff
    knob.ZIndex          = 6

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob

    local isEnabled = false

    -- [ИСПРАВЛЕНО] Прозрачная кнопка поверх всего
    local hitbox = Instance.new("TextButton")
    hitbox.Parent             = toggleFrame
    hitbox.Size               = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text               = ""
    hitbox.ZIndex             = 7

    local function toggle()
        isEnabled = not isEnabled
        local onPos  = UDim2.new(1, -20, 0.5, -9)
        local offPos = UDim2.new(0, 2, 0.5, -9)
        if isEnabled then
            TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                {Position = onPos, BackgroundColor3 = colors.toggleOn}):Play()
            TweenService:Create(track, TweenInfo.new(0.3),
                {BackgroundColor3 = Color3.fromRGB(0, 150, 50)}):Play()
            TweenService:Create(ts, TweenInfo.new(0.2),
                {Transparency = 0, Color = colors.toggleOn}):Play()
        else
            TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                {Position = offPos, BackgroundColor3 = colors.toggleOff}):Play()
            TweenService:Create(track, TweenInfo.new(0.3),
                {BackgroundColor3 = colors.toggleBg}):Play()
            TweenService:Create(ts, TweenInfo.new(0.2),
                {Transparency = 0.5, Color = colors.accent}):Play()
        end
        print(text .. ":", isEnabled and "ВКЛ ✅" or "ВЫКЛ ⭕")
    end

    -- [ИСПРАВЛЕНО] Только Activated
    hitbox.Activated:Connect(toggle)

    hitbox.MouseEnter:Connect(function()
        TweenService:Create(toggleFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
    end)
    hitbox.MouseLeave:Connect(function()
        TweenService:Create(toggleFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
    end)

    return toggleFrame, hitbox
end

createToggle("Auto Skip",       35,  mainContainer)
createToggle("Auto x2 Speed",   85,  mainContainer)
createToggle("Auto x3 Speed",   135, mainContainer)
createToggle("Auto Play Again", 185, mainContainer)

-- AUTO MODE + ВЫБОР ВОЛНЫ
local autoModeFrame = Instance.new("Frame")
autoModeFrame.Parent               = mainContainer
autoModeFrame.Size                 = UDim2.new(1, -20, 0, 40)
autoModeFrame.Position             = UDim2.new(0, 10, 0, 235)
autoModeFrame.BackgroundColor3     = colors.panelBg
autoModeFrame.BackgroundTransparency = 0.5
autoModeFrame.ZIndex               = 4

local amc = Instance.new("UICorner")
amc.CornerRadius = UDim.new(0, 8)
amc.Parent = autoModeFrame

local autoModeLabel = Instance.new("TextLabel")
autoModeLabel.Parent             = autoModeFrame
autoModeLabel.Size               = UDim2.new(0, 100, 1, 0)
autoModeLabel.Position           = UDim2.new(0, 10, 0, 0)
autoModeLabel.BackgroundTransparency = 1
autoModeLabel.Text               = "Auto Mode"
autoModeLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
autoModeLabel.Font               = Enum.Font.GothamBold
autoModeLabel.TextSize           = 13
autoModeLabel.TextXAlignment     = Enum.TextXAlignment.Left
autoModeLabel.ZIndex             = 5

local waveSelector = Instance.new("Frame")
waveSelector.Parent          = autoModeFrame
waveSelector.Size            = UDim2.new(0, 150, 0, 30)
waveSelector.Position        = UDim2.new(1, -160, 0.5, -15)
waveSelector.BackgroundColor3 = colors.toggleBg
waveSelector.BackgroundTransparency = 0.3
waveSelector.ZIndex          = 5

local wsc = Instance.new("UICorner")
wsc.CornerRadius = UDim.new(0, 6)
wsc.Parent = waveSelector

local waveLabel = Instance.new("TextLabel")
waveLabel.Parent             = waveSelector
waveLabel.Size               = UDim2.new(1, -30, 1, 0)
waveLabel.Position           = UDim2.new(0, 10, 0, 0)
waveLabel.BackgroundTransparency = 1
waveLabel.Text               = "Easy"
waveLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
waveLabel.Font               = Enum.Font.Gotham
waveLabel.TextSize           = 12
waveLabel.TextXAlignment     = Enum.TextXAlignment.Left
waveLabel.ZIndex             = 6

local waveArrow = Instance.new("TextLabel")
waveArrow.Parent             = waveSelector
waveArrow.Size               = UDim2.new(0, 20, 1, 0)
waveArrow.Position           = UDim2.new(1, -25, 0, 0)
waveArrow.BackgroundTransparency = 1
waveArrow.Text               = "▼"
waveArrow.TextColor3         = Color3.fromRGB(180, 180, 180)
waveArrow.Font               = Enum.Font.GothamBold
waveArrow.TextSize           = 10
waveArrow.ZIndex             = 6

-- ВЫПАДАЮЩИЙ СПИСОК ВОЛН
local waveDropdown = Instance.new("ScrollingFrame")
waveDropdown.Parent          = mainContainer
waveDropdown.Size            = UDim2.new(0, 150, 0, 200)
waveDropdown.Position        = UDim2.new(1, -165, 0, 300)
waveDropdown.BackgroundColor3 = colors.mainBg
waveDropdown.BackgroundTransparency = 0.1
waveDropdown.Visible         = false
waveDropdown.ZIndex          = 20
waveDropdown.ScrollBarThickness = 3
waveDropdown.ScrollBarImageColor3 = colors.accent
waveDropdown.CanvasSize      = UDim2.new(0, 0, 0, 240)
waveDropdown.BorderSizePixel = 0

local wdc = Instance.new("UICorner")
wdc.CornerRadius = UDim.new(0, 8)
wdc.Parent = waveDropdown

local wds = Instance.new("UIStroke")
wds.Parent    = waveDropdown
wds.Color     = colors.accent
wds.Thickness = 2

local waves = {"Easy","Normal","Hard","Insane","Impossible","Apocalypse"}

for i, wave in ipairs(waves) do
    local item = Instance.new("Frame")
    item.Parent          = waveDropdown
    item.Size            = UDim2.new(1, -10, 0, 35)
    item.Position        = UDim2.new(0, 5, 0, (i-1)*40 + 5)
    item.BackgroundColor3 = colors.panelBg
    item.BackgroundTransparency = 0.5
    item.ZIndex          = 21

    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(0, 6)
    ic.Parent = item

    local il = Instance.new("TextLabel")
    il.Parent             = item
    il.Size               = UDim2.new(1, -10, 1, 0)
    il.Position           = UDim2.new(0, 10, 0, 0)
    il.BackgroundTransparency = 1
    il.Text               = wave
    il.TextColor3         = Color3.fromRGB(255, 255, 255)
    il.Font               = Enum.Font.GothamBold
    il.TextSize           = 12
    il.TextXAlignment     = Enum.TextXAlignment.Left
    il.ZIndex             = 22

    local ib = Instance.new("TextButton")
    ib.Parent             = item
    ib.Size               = UDim2.new(1, 0, 1, 0)
    ib.BackgroundTransparency = 1
    ib.Text               = ""
    ib.ZIndex             = 23

    ib.Activated:Connect(function()      -- [ИСПРАВЛЕНО]
        selectedWave = wave
        waveLabel.Text      = wave
        waveLabel.TextColor3 = colors.toggleOn
        waveDropdown.Visible = false
    end)
    ib.MouseEnter:Connect(function() item.BackgroundTransparency = 0.3 end)
    ib.MouseLeave:Connect(function() item.BackgroundTransparency = 0.5 end)
end

local waveSelectorBtn = Instance.new("TextButton")
waveSelectorBtn.Parent             = waveSelector
waveSelectorBtn.Size               = UDim2.new(1, 0, 1, 0)
waveSelectorBtn.BackgroundTransparency = 1
waveSelectorBtn.Text               = ""
waveSelectorBtn.ZIndex             = 7

waveSelectorBtn.Activated:Connect(function()    -- [ИСПРАВЛЕНО]
    waveDropdown.Visible = not waveDropdown.Visible
end)
waveSelectorBtn.MouseEnter:Connect(function() waveSelector.BackgroundTransparency = 0.1 end)
waveSelectorBtn.MouseLeave:Connect(function() waveSelector.BackgroundTransparency = 0.3 end)

-- ==========================================
-- MACRO ВКЛАДКА
-- ==========================================
local macroTitle = Instance.new("TextLabel")
macroTitle.Parent             = macroContainer
macroTitle.Size               = UDim2.new(1, -10, 0, 25)
macroTitle.Position           = UDim2.new(0, 5, 0, 0)
macroTitle.BackgroundTransparency = 1
macroTitle.Text               = "⚡ MACRO"
macroTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
macroTitle.Font               = Enum.Font.GothamBold
macroTitle.TextSize           = 16
macroTitle.ZIndex             = 4

local macroLeftSection = Instance.new("Frame")
macroLeftSection.Parent           = macroContainer
macroLeftSection.Size             = UDim2.new(1, -10, 1, -35)
macroLeftSection.Position         = UDim2.new(0, 5, 0, 30)
macroLeftSection.BackgroundTransparency = 1
macroLeftSection.ZIndex           = 4

-- ОКНО СОЗДАНИЯ МАКРОСА
local createWindow = Instance.new("Frame")
createWindow.Parent          = screenGui
createWindow.Size            = UDim2.new(0, 300, 0, 150)
createWindow.Position        = UDim2.new(0.5, -150, 0.5, -75)
createWindow.BackgroundColor3 = colors.mainBg
createWindow.BackgroundTransparency = 0.1
createWindow.Visible         = false
createWindow.ZIndex          = 50

local cwc = Instance.new("UICorner")
cwc.CornerRadius = UDim.new(0, 12)
cwc.Parent = createWindow

local cws = Instance.new("UIStroke")
cws.Parent    = createWindow
cws.Color     = colors.accent
cws.Thickness = 3

local createTitle = Instance.new("TextLabel")
createTitle.Parent             = createWindow
createTitle.Size               = UDim2.new(1, -20, 0, 30)
createTitle.Position           = UDim2.new(0, 10, 0, 10)
createTitle.BackgroundTransparency = 1
createTitle.Text               = "📁 CREATE MACRO"
createTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
createTitle.Font               = Enum.Font.GothamBold
createTitle.TextSize           = 16
createTitle.ZIndex             = 51

local macroNameBox = Instance.new("TextBox")
macroNameBox.Parent           = createWindow
macroNameBox.Size             = UDim2.new(1, -40, 0, 35)
macroNameBox.Position         = UDim2.new(0, 20, 0, 50)
macroNameBox.BackgroundColor3 = colors.panelBg
macroNameBox.BackgroundTransparency = 0.3
macroNameBox.Text             = ""
macroNameBox.PlaceholderText  = "Введите название..."
macroNameBox.TextColor3       = Color3.fromRGB(255, 255, 255)
macroNameBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
macroNameBox.Font             = Enum.Font.Gotham
macroNameBox.TextSize         = 14
macroNameBox.ZIndex           = 51

local mnbc = Instance.new("UICorner")
mnbc.CornerRadius = UDim.new(0, 8)
mnbc.Parent = macroNameBox

local createConfirmBtn = Instance.new("TextButton")
createConfirmBtn.Parent          = createWindow
createConfirmBtn.Size            = UDim2.new(0, 120, 0, 35)
createConfirmBtn.Position        = UDim2.new(0.5, -125, 1, -45)
createConfirmBtn.BackgroundColor3 = colors.toggleOn
createConfirmBtn.Text            = "✓ CREATE"
createConfirmBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
createConfirmBtn.Font            = Enum.Font.GothamBold
createConfirmBtn.TextSize        = 14
createConfirmBtn.ZIndex          = 51

local ccbc = Instance.new("UICorner")
ccbc.CornerRadius = UDim.new(0, 8)
ccbc.Parent = createConfirmBtn

local createCancelBtn = Instance.new("TextButton")
createCancelBtn.Parent          = createWindow
createCancelBtn.Size            = UDim2.new(0, 120, 0, 35)
createCancelBtn.Position        = UDim2.new(0.5, 5, 1, -45)
createCancelBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 100)
createCancelBtn.Text            = "✕ CANCEL"
createCancelBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
createCancelBtn.Font            = Enum.Font.GothamBold
createCancelBtn.TextSize        = 14
createCancelBtn.ZIndex          = 51

local cxbc = Instance.new("UICorner")
cxbc.CornerRadius = UDim.new(0, 8)
cxbc.Parent = createCancelBtn

-- ВЫПАДАЮЩИЙ СПИСОК МАКРОСОВ
local macroDropdown = Instance.new("ScrollingFrame")
macroDropdown.Parent          = macroLeftSection
macroDropdown.Size            = UDim2.new(0, 200, 0, 150)
macroDropdown.Position        = UDim2.new(0, 125, 0, 100)
macroDropdown.BackgroundColor3 = colors.mainBg
macroDropdown.BackgroundTransparency = 0.1
macroDropdown.Visible         = false
macroDropdown.ZIndex          = 20
macroDropdown.ScrollBarThickness = 3
macroDropdown.ScrollBarImageColor3 = colors.accent
macroDropdown.CanvasSize      = UDim2.new(0, 0, 0, 0)
macroDropdown.BorderSizePixel = 0

local mdc = Instance.new("UICorner")
mdc.CornerRadius = UDim.new(0, 8)
mdc.Parent = macroDropdown

local mds = Instance.new("UIStroke")
mds.Parent    = macroDropdown
mds.Color     = colors.accent
mds.Thickness = 2

-- ОБНОВЛЕНИЕ СПИСКА МАКРОСОВ
local function updateMacroDropdown()
    for _, child in pairs(macroDropdown:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for i, macro in ipairs(macros) do
        local item = Instance.new("Frame")
        item.Parent          = macroDropdown
        item.Size            = UDim2.new(1, -10, 0, 35)
        item.Position        = UDim2.new(0, 5, 0, (i-1)*40 + 5)
        item.BackgroundColor3 = colors.panelBg
        item.BackgroundTransparency = 0.5
        item.ZIndex          = 21

        local ic = Instance.new("UICorner")
        ic.CornerRadius = UDim.new(0, 6)
        ic.Parent = item

        local il = Instance.new("TextLabel")
        il.Parent             = item
        il.Size               = UDim2.new(1, -10, 1, 0)
        il.Position           = UDim2.new(0, 10, 0, 0)
        il.BackgroundTransparency = 1
        il.Text               = "📄 " .. macro.name
        il.TextColor3         = Color3.fromRGB(255, 255, 255)
        il.Font               = Enum.Font.GothamBold
        il.TextSize           = 12
        il.TextXAlignment     = Enum.TextXAlignment.Left
        il.ZIndex             = 22

        local ib = Instance.new("TextButton")
        ib.Parent             = item
        ib.Size               = UDim2.new(1, 0, 1, 0)
        ib.BackgroundTransparency = 1
        ib.Text               = ""
        ib.ZIndex             = 23

        local name = macro.name
        ib.Activated:Connect(function()      -- [ИСПРАВЛЕНО]
            selectedMacro = name
            for _, ch in pairs(macroLeftSection:GetChildren()) do
                if ch.Name == "MacroSelector" then
                    local lbl = ch:FindFirstChild("TextLabel")
                    if lbl then
                        lbl.Text      = "📄 " .. selectedMacro
                        lbl.TextColor3 = colors.toggleOn
                    end
                end
            end
            macroDropdown.Visible = false
        end)
        ib.MouseEnter:Connect(function() item.BackgroundTransparency = 0.3 end)
        ib.MouseLeave:Connect(function() item.BackgroundTransparency = 0.5 end)
    end

    macroDropdown.CanvasSize = UDim2.new(0, 0, 0, #macros * 40 + 10)
end

-- ОБРАБОТЧИКИ ОКНА СОЗДАНИЯ
createConfirmBtn.Activated:Connect(function()      -- [ИСПРАВЛЕНО]
    local macroName = macroNameBox.Text
    if macroName ~= "" then
        table.insert(macros, {name = macroName, actions = {}})
        createWindow.Visible = false
        updateMacroDropdown()
        saveMacros()
        macroNameBox.Text = ""
    end
end)

createCancelBtn.Activated:Connect(function()       -- [ИСПРАВЛЕНО]
    createWindow.Visible = false
    macroNameBox.Text    = ""
end)

-- КНОПКИ MACRO ВКЛАДКИ
local function createMacroButton(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Parent          = macroLeftSection
    btn.Size            = UDim2.new(0, 110, 0, 35)
    btn.Position        = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = colors.button
    btn.BackgroundTransparency = 0.2
    btn.Text            = text
    btn.TextColor3      = Color3.fromRGB(255, 255, 255)
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = 12
    btn.ZIndex          = 5

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = colors.buttonAlt; btn.BackgroundTransparency = 0 end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = colors.button;    btn.BackgroundTransparency = 0.2 end)

    return btn
end

local createBtn  = createMacroButton("📁 Create",  10)
local refreshBtn = createMacroButton("🔄 Refresh", 55)

createBtn.Activated:Connect(function()    -- [ИСПРАВЛЕНО]
    createWindow.Visible = true
    macroNameBox.Text    = ""
end)

refreshBtn.Activated:Connect(function()  -- [ИСПРАВЛЕНО]
    updateMacroDropdown()
    print("🔄 Список обновлён")
end)

-- НАДПИСЬ LIST
local listLabel = Instance.new("TextLabel")
listLabel.Parent          = macroLeftSection
listLabel.Size            = UDim2.new(0, 110, 0, 35)
listLabel.Position        = UDim2.new(0, 5, 0, 100)
listLabel.BackgroundColor3 = colors.button
listLabel.BackgroundTransparency = 0.2
listLabel.Text            = "📋 List"
listLabel.TextColor3      = Color3.fromRGB(255, 255, 255)
listLabel.Font            = Enum.Font.GothamBold
listLabel.TextSize        = 12
listLabel.ZIndex          = 5

local llc = Instance.new("UICorner")
llc.CornerRadius = UDim.new(0, 6)
llc.Parent = listLabel

-- СЕЛЕКТОР МАКРОСА
local macroSelector = Instance.new("Frame")
macroSelector.Name          = "MacroSelector"
macroSelector.Parent        = macroLeftSection
macroSelector.Size          = UDim2.new(0, 200, 0, 35)
macroSelector.Position      = UDim2.new(0, 125, 0, 100)
macroSelector.BackgroundColor3 = colors.panelBg
macroSelector.BackgroundTransparency = 0.5
macroSelector.ZIndex        = 5

local msc = Instance.new("UICorner")
msc.CornerRadius = UDim.new(0, 6)
msc.Parent = macroSelector

local selectorLabel = Instance.new("TextLabel")
selectorLabel.Parent         = macroSelector
selectorLabel.Size           = UDim2.new(1, -30, 1, 0)
selectorLabel.Position       = UDim2.new(0, 10, 0, 0)
selectorLabel.BackgroundTransparency = 1
selectorLabel.Text           = "Выберите макрос..."
selectorLabel.TextColor3     = Color3.fromRGB(180, 180, 180)
selectorLabel.Font           = Enum.Font.Gotham
selectorLabel.TextSize       = 11
selectorLabel.TextXAlignment = Enum.TextXAlignment.Left
selectorLabel.ZIndex         = 6

local arrowLabel = Instance.new("TextLabel")
arrowLabel.Parent             = macroSelector
arrowLabel.Size               = UDim2.new(0, 20, 1, 0)
arrowLabel.Position           = UDim2.new(1, -25, 0, 0)
arrowLabel.BackgroundTransparency = 1
arrowLabel.Text               = "▼"
arrowLabel.TextColor3         = Color3.fromRGB(180, 180, 180)
arrowLabel.Font               = Enum.Font.GothamBold
arrowLabel.TextSize           = 10
arrowLabel.ZIndex             = 6

local selectorBtn = Instance.new("TextButton")
selectorBtn.Parent             = macroSelector
selectorBtn.Size               = UDim2.new(1, 0, 1, 0)
selectorBtn.BackgroundTransparency = 1
selectorBtn.Text               = ""
selectorBtn.ZIndex             = 7

selectorBtn.Activated:Connect(function()    -- [ИСПРАВЛЕНО]
    macroDropdown.Visible = not macroDropdown.Visible
    updateMacroDropdown()
end)
selectorBtn.MouseEnter:Connect(function() macroSelector.BackgroundTransparency = 0.3 end)
selectorBtn.MouseLeave:Connect(function() macroSelector.BackgroundTransparency = 0.5 end)

-- ШИРОКИЕ ТОГГЛЫ ДЛЯ MACRO
local function createWideToggle(text, yPos, callback)
    local tf = Instance.new("Frame")
    tf.Parent               = macroLeftSection
    tf.Size                 = UDim2.new(1, -15, 0, 40)
    tf.Position             = UDim2.new(0, 5, 0, yPos)
    tf.BackgroundColor3     = colors.panelBg
    tf.BackgroundTransparency = 0.5
    tf.ZIndex               = 4

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = tf

    local lbl = Instance.new("TextLabel")
    lbl.Parent             = tf
    lbl.Size               = UDim2.new(1, -80, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.TextColor3         = Color3.fromRGB(255, 255, 255)
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 13
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 5

    local track = Instance.new("Frame")
    track.Parent          = tf
    track.Size            = UDim2.new(0, 45, 0, 22)
    track.Position        = UDim2.new(1, -55, 0.5, -11)
    track.BackgroundColor3 = colors.toggleBg
    track.ZIndex          = 5

    local trc = Instance.new("UICorner")
    trc.CornerRadius = UDim.new(1, 0)
    trc.Parent = track

    local knob = Instance.new("Frame")
    knob.Parent          = track
    knob.Size            = UDim2.new(0, 18, 0, 18)
    knob.Position        = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = colors.toggleOff
    knob.ZIndex          = 6

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob

    local isEnabled = false

    local hitbox = Instance.new("TextButton")
    hitbox.Parent             = tf
    hitbox.Size               = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text               = ""
    hitbox.ZIndex             = 7

    hitbox.Activated:Connect(function()     -- [ИСПРАВЛЕНО]
        isEnabled = not isEnabled
        if isEnabled then
            TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = colors.toggleOn}):Play()
            TweenService:Create(track, TweenInfo.new(0.3),
                {BackgroundColor3 = Color3.fromRGB(0, 150, 50)}):Play()
        else
            TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = colors.toggleOff}):Play()
            TweenService:Create(track, TweenInfo.new(0.3),
                {BackgroundColor3 = colors.toggleBg}):Play()
        end
        if callback then callback(isEnabled) end
    end)

    return tf
end

createWideToggle("⏺️ Record Macro",  145, function(e) isRecording = e end)
createWideToggle("▶️ Play Macro",    195, function(e)
    isPlaying = e
    if useHotkey then hotkeyButton.Visible = e end
end)
createWideToggle("⏱️ Time Placement", 245, function(e) print("Time Placement:", e) end)
createWideToggle("📍 Unit Placement", 295, function(e) print("Unit Placement:", e) end)
createWideToggle("🔁 Loop Mode",      345, function(e) loopMode = e end)
createWideToggle("⌨️ Hotkey",         395, function(e)
    useHotkey = e
    hotkeyButton.Visible = e and isPlaying
end)

-- ==========================================
-- SETTINGS ВКЛАДКА
-- ==========================================
local settingsTitle = Instance.new("TextLabel")
settingsTitle.Parent             = settingsContainer
settingsTitle.Size               = UDim2.new(1, -10, 0, 25)
settingsTitle.Position           = UDim2.new(0, 5, 0, 0)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text               = "⚡ SETTINGS"
settingsTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
settingsTitle.Font               = Enum.Font.GothamBold
settingsTitle.TextSize           = 16
settingsTitle.ZIndex             = 4

local settingsPlaceholder = Instance.new("TextLabel")
settingsPlaceholder.Parent           = settingsContainer
settingsPlaceholder.Size             = UDim2.new(1, 0, 0, 40)
settingsPlaceholder.Position         = UDim2.new(0, 0, 0.4, -20)
settingsPlaceholder.BackgroundTransparency = 1
settingsPlaceholder.Text             = "Скоро будет..."
settingsPlaceholder.TextColor3       = Color3.fromRGB(200, 200, 255)
settingsPlaceholder.TextTransparency = 0.3
settingsPlaceholder.Font             = Enum.Font.Gotham
settingsPlaceholder.TextSize         = 14
settingsPlaceholder.ZIndex           = 4

-- ==========================================
-- НАВИГАЦИЯ
-- ==========================================
local function showMain()
    mainContainer.Visible     = true
    macroContainer.Visible    = false
    settingsContainer.Visible = false
end

local function showMacro()
    mainContainer.Visible     = false
    macroContainer.Visible    = true
    settingsContainer.Visible = false
    updateMacroDropdown()
end

local function showSettings()
    mainContainer.Visible     = false
    macroContainer.Visible    = false
    settingsContainer.Visible = true
end

-- [ИСПРАВЛЕНО] Activated вместо MouseButton1Click + TouchTap
mainBtn.Activated:Connect(showMain)
macroBtn.Activated:Connect(showMacro)
settingsBtn.Activated:Connect(showSettings)

-- ==========================================
-- ФУТЕР
-- ==========================================
local footer = Instance.new("TextLabel")
footer.Parent             = mainFrame
footer.Size               = UDim2.new(1, 0, 0, 18)
footer.Position           = UDim2.new(0, 0, 1, -18)
footer.BackgroundTransparency = 1
footer.Text               = "⚡ zeexHub ⚡"
footer.TextColor3         = Color3.fromRGB(200, 180, 255)
footer.TextTransparency   = 0.2
footer.Font               = Enum.Font.Gotham
footer.TextSize           = 10
footer.ZIndex             = 2

-- ==========================================
-- ЗАКРЫТИЕ ДРОПДАУНОВ ПРИ КЛИКЕ ВНЕ
-- ==========================================
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        local pos = UserInputService:GetMouseLocation()

        local function outsideDrop(drop)
            if not drop.Visible then return false end
            local p = drop.AbsolutePosition
            local s = drop.AbsoluteSize
            return pos.X < p.X or pos.X > p.X + s.X
                or pos.Y < p.Y or pos.Y > p.Y + s.Y
        end

        if outsideDrop(waveDropdown)  then waveDropdown.Visible  = false end
        if outsideDrop(macroDropdown) then macroDropdown.Visible = false end
    end
end)

-- ==========================================
-- ИНИЦИАЛИЗАЦИЯ
-- ==========================================
loadMacros()
updateMacroDropdown()

print("========================================")
print("✅ ZeexHub загружен")
print(isMobile and "📱 Мобильная версия" or "🖥️ ПК версия")
print("⚡ by zeenixxs")
print("========================================")
