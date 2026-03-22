-- ==========================================
-- ZEEXHUB UI - ФИНАЛЬНАЯ ИСПРАВЛЕННАЯ ВЕРСИЯ
-- ==========================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local player   = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- ==========================================
-- КОНСТАНТЫ РАЗМЕРОВ
-- ==========================================
local W          = isMobile and 320  or 220
local H          = isMobile and 320  or 220  -- ← ТЕПЕРЬ 380 вместо 440
local TITLE_H    = isMobile and 40   or 34
local FOOTER_H   = 16
local BTN_SZ     = isMobile and 34   or 24
local LEFT_W     = isMobile and 80   or 82
local CONTENT_X  = LEFT_W + 8
local CONTENT_Y  = TITLE_H + 4
local CONTENT_H  = H - CONTENT_Y - FOOTER_H - 6
local CONTENT_W  = W - CONTENT_X - 6

-- ==========================================
-- ЦВЕТА
-- ==========================================
local C = {
    bg       = Color3.fromRGB(15,  0,  25),
    panel    = Color3.fromRGB(25,  0,  40),
    btn      = Color3.fromRGB(80,  0, 130),
    btnHover = Color3.fromRGB(120, 0, 180),
    accent   = Color3.fromRGB(160, 0, 255),
    on       = Color3.fromRGB(0,  220,  85),
    off      = Color3.fromRGB(100,100, 100),
    track    = Color3.fromRGB(40,  40,  40),
    trackOn  = Color3.fromRGB(0,  130,  40),
    white    = Color3.fromRGB(255,255, 255),
    danger   = Color3.fromRGB(220, 50, 60),
    dim      = Color3.fromRGB(160,160, 160),
}

-- ==========================================
-- СОСТОЯНИЯ
-- ==========================================
local toggleStates  = {}   -- [key] = bool
local toggleSetters = {}   -- [key] = function(bool, silent?)
local configs       = {}
local macros        = {}
local selectedConfig = nil
local selectedMacro  = nil
local selectedWave   = "Easy"
local isPlaying      = false
local isRecording    = false
local loopMode       = false
local useHotkey      = false

-- ==========================================
-- ФАЙЛЫ
-- ==========================================
local function tryRead(file)
    if not (isfile and readfile) then return nil end
    local ok, data = pcall(function()
        if isfile(file) then return readfile(file) end
    end)
    return ok and data or nil
end

local function tryWrite(file, data)
    if not (writefile) then return end
    pcall(writefile, file, data)
end

local function saveMacros()
    if #macros > 0 then
        tryWrite("zeexhub_macros.json", HttpService:JSONEncode(macros))
    end
end

local function loadMacros()
    local d = tryRead("zeexhub_macros.json")
    if d and #d > 2 then
        local ok, t = pcall(HttpService.JSONDecode, HttpService, d)
        if ok and type(t) == "table" then macros = t end
    end
end

local function saveConfigs()
    tryWrite("zeexhub_configs.json", HttpService:JSONEncode(configs))
end

local function loadConfigs()
    local d = tryRead("zeexhub_configs.json")
    if d and #d > 2 then
        local ok, t = pcall(HttpService.JSONDecode, HttpService, d)
        if ok and type(t) == "table" then configs = t end
    end
end

-- ==========================================
-- HELPERS
-- ==========================================
local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Parent       = parent
    s.Color        = color or C.accent
    s.Thickness    = thickness or 2
    s.Transparency = transparency or 0
    return s
end

-- ==========================================
-- SCREEN GUI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ZeexHub"
screenGui.Parent         = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder   = 999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ==========================================
-- MAIN FRAME — ФИКСИРОВАННЫЙ ПРЯМОУГОЛЬНИК
-- ==========================================
local mainFrame = Instance.new("Frame")
mainFrame.Parent               = screenGui
mainFrame.BackgroundColor3     = C.bg
mainFrame.BackgroundTransparency = 0.05
mainFrame.Size                 = UDim2.new(0, W, 0, H)
mainFrame.Position             = UDim2.new(0.5, -W/2, 0.5, -H/2)
mainFrame.Active               = true
mainFrame.ClipsDescendants     = true
addCorner(mainFrame, 14)

local rgbStroke = addStroke(mainFrame, C.accent, 3)
local hue = 0
RunService.RenderStepped:Connect(function()
    hue = (hue + 0.005) % 1
    rgbStroke.Color = Color3.fromHSV(hue, 1, 1)
end)

-- ==========================================
-- TITLE BAR
-- ==========================================
local titleBar = Instance.new("Frame")
titleBar.Parent               = mainFrame
titleBar.BackgroundColor3     = C.panel
titleBar.BackgroundTransparency = 0.1
titleBar.Size                 = UDim2.new(1, 0, 0, TITLE_H)
titleBar.ZIndex               = 2
titleBar.Active               = true
addCorner(titleBar, 14)

local titleLbl = Instance.new("TextLabel")
titleLbl.Parent             = titleBar
titleLbl.Size               = UDim2.new(0, 180, 1, 0)
titleLbl.Position           = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text               = "⚡ ZEEXHUB"
titleLbl.TextColor3         = C.white
titleLbl.Font               = Enum.Font.GothamBold
titleLbl.TextSize           = isMobile and 14 or 15
titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
titleLbl.ZIndex             = 3

local authorLbl = Instance.new("TextLabel")
authorLbl.Parent             = titleBar
authorLbl.Size               = UDim2.new(0, 100, 1, 0)
authorLbl.Position           = UDim2.new(1, -(BTN_SZ*2 + 18 + 100), 0, 0)
authorLbl.BackgroundTransparency = 1
authorLbl.Text               = "by: zeenixxs"
authorLbl.TextColor3         = Color3.fromRGB(180, 180, 255)
authorLbl.Font               = Enum.Font.GothamBold
authorLbl.TextSize           = 10
authorLbl.TextTransparency   = 0.3
authorLbl.TextXAlignment     = Enum.TextXAlignment.Right
authorLbl.ZIndex             = 3

-- HIDE / CLOSE КНОПКИ (ZIndex = 10 — поверх всего в titleBar)
local function makeTitleBtn(text, xOff, bg)
    local b = Instance.new("TextButton")
    b.Parent          = titleBar
    b.Size            = UDim2.new(0, BTN_SZ, 0, BTN_SZ)
    b.Position        = UDim2.new(1, xOff, 0.5, -BTN_SZ/2)
    b.BackgroundColor3 = bg
    b.Text            = text
    b.TextColor3      = C.white
    b.Font            = Enum.Font.GothamBold
    b.TextSize        = isMobile and 20 or 15
    b.ZIndex          = 10
    addCorner(b, 6)
    return b
end

local hideBtn  = makeTitleBtn("−", -(BTN_SZ*2 + 10), C.btn)
local closeBtn = makeTitleBtn("✕", -(BTN_SZ   +  5), C.danger)

-- DRAGGING
local drag = {on=false, input=nil, mpos=nil, fpos=nil}

titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        drag.on   = true
        drag.mpos = inp.Position
        drag.fpos = mainFrame.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then drag.on = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        drag.input = inp
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if inp == drag.input and drag.on then
        local d = inp.Position - drag.mpos
        mainFrame.Position = UDim2.new(
            drag.fpos.X.Scale, drag.fpos.X.Offset + d.X,
            drag.fpos.Y.Scale, drag.fpos.Y.Offset + d.Y
        )
    end
end)

-- TAB BUTTON (когда окно свёрнуто)
local tabBtn = Instance.new("TextButton")
tabBtn.Parent          = screenGui
tabBtn.Size            = UDim2.new(0, 44, 0, 44)
tabBtn.Position        = UDim2.new(1, -54, 0.5, -22)
tabBtn.BackgroundColor3 = C.accent
tabBtn.Text            = "⚡"
tabBtn.TextColor3      = C.white
tabBtn.Font            = Enum.Font.GothamBold
tabBtn.TextSize        = 22
tabBtn.Visible         = false
tabBtn.ZIndex          = 100
addCorner(tabBtn, 10)

hideBtn.Activated:Connect(function()
    mainFrame.Visible = false
    tabBtn.Visible    = true
end)
tabBtn.Activated:Connect(function()
    mainFrame.Visible = true
    tabBtn.Visible    = false
end)
closeBtn.Activated:Connect(function()
    screenGui:Destroy()
end)

-- HOTKEY FLOATING BUTTON
local hotkeyBtn = Instance.new("TextButton")
hotkeyBtn.Parent          = screenGui
hotkeyBtn.Size            = UDim2.new(0, 48, 0, 48)
hotkeyBtn.Position        = UDim2.new(1, -62, 0, 54)
hotkeyBtn.BackgroundColor3 = C.on
hotkeyBtn.Text            = "▶"
hotkeyBtn.TextColor3      = C.white
hotkeyBtn.Font            = Enum.Font.GothamBold
hotkeyBtn.TextSize        = 22
hotkeyBtn.Visible         = false
hotkeyBtn.ZIndex          = 100
addCorner(hotkeyBtn, 10)

hotkeyBtn.Activated:Connect(function()
    isPlaying = not isPlaying
    hotkeyBtn.BackgroundColor3 = isPlaying and Color3.fromRGB(220,40,40) or C.on
    hotkeyBtn.Text             = isPlaying and "⏸" or "▶"
end)

-- ==========================================
-- LEFT PANEL
-- ==========================================
local leftPanel = Instance.new("Frame")
leftPanel.Parent               = mainFrame
leftPanel.Size                 = UDim2.new(0, LEFT_W, 0, CONTENT_H)
leftPanel.Position             = UDim2.new(0, 4, 0, CONTENT_Y)
leftPanel.BackgroundColor3     = C.panel
leftPanel.BackgroundTransparency = 0.2
leftPanel.ZIndex               = 49
addCorner(leftPanel, 10)
addStroke(leftPanel, C.accent, 2)

local function navBtn(text, yPos)
    local b = Instance.new("TextButton")
    b.Parent          = leftPanel
    b.Size            = UDim2.new(1, -8, 0, 26)
    b.Position        = UDim2.new(0, 4, 0, yPos)
    b.BackgroundColor3 = C.btn
    b.Text            = text
    b.TextColor3      = C.white
    b.Font            = Enum.Font.GothamBold
    b.TextSize        = isMobile and 9 or 11
    b.ZIndex          = 50
    b.Active          = true  -- ← ДОБАВЬ ЭТУ СТРОКУ
    addCorner(b, 6)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = C.btnHover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = C.btn      end)
    return b
end

local navMain     = navBtn("MAIN",  8)
local navMacro    = navBtn("MACRO", 38)
local navSettings = navBtn("SET",   68)
local navChannels = navBtn("CHAN",  98)

-- ==========================================
-- CONTENT AREA
-- ==========================================
local contentArea = Instance.new("Frame")
contentArea.Parent               = mainFrame
contentArea.Size                 = UDim2.new(0, CONTENT_W, 0, CONTENT_H)
contentArea.Position             = UDim2.new(0, CONTENT_X, 0, CONTENT_Y)
contentArea.BackgroundColor3     = C.panel
contentArea.BackgroundTransparency = 0.25
contentArea.ClipsDescendants     = true
contentArea.ZIndex               = 2
addCorner(contentArea, 10)
addStroke(contentArea, C.accent, 2)

local function makeScroll(visible, canvasH)
    local sf = Instance.new("ScrollingFrame")
    sf.Parent               = contentArea
    sf.Size                 = UDim2.new(1, -4, 1, -4)
    sf.Position             = UDim2.new(0, 2, 0, 2)
    sf.BackgroundTransparency = 1
    sf.Visible              = visible
    sf.ZIndex               = 3
    sf.ScrollBarThickness   = 3
    sf.ScrollBarImageColor3 = C.accent
    sf.BorderSizePixel      = 0
    sf.CanvasSize           = UDim2.new(0, 0, 0, canvasH or 500)
    return sf
end

local scrollMain     = makeScroll(true,  480)
local scrollMacro    = makeScroll(false, 480)
local scrollSettings = makeScroll(false, 620)
local scrollChannels = makeScroll(false, 330)

-- ==========================================
-- TOGGLE FACTORY
-- ==========================================
local function makeToggle(parent, key, label, yPos, callback)
    local frame = Instance.new("Frame")
    frame.Parent               = parent
    frame.Size                 = UDim2.new(1, -14, 0, 33)
    frame.Position             = UDim2.new(0, 7, 0, yPos)
    frame.BackgroundColor3     = C.panel
    frame.BackgroundTransparency = 0.35
    frame.ZIndex               = 4
    addCorner(frame, 8)
    local stroke = addStroke(frame, C.accent, 1, 0.65)

    local lbl = Instance.new("TextLabel")
    lbl.Parent             = frame
    lbl.Size               = UDim2.new(1, -62, 1, 0)
    lbl.Position           = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextColor3         = C.white
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = isMobile and 11 or 12
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 5

    local track = Instance.new("Frame")
    track.Parent          = frame
    track.Size            = UDim2.new(0, 40, 0, 18)
    track.Position        = UDim2.new(1, -48, 0.5, -9)
    track.BackgroundColor3 = C.track
    track.ZIndex          = 5
    addCorner(track, 9)

    local knob = Instance.new("Frame")
    knob.Parent          = track
    knob.Size            = UDim2.new(0, 14, 0, 14)
    knob.Position        = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = C.off
    knob.ZIndex          = 6
    addCorner(knob, 7)

    local hitbox = Instance.new("TextButton")
    hitbox.Parent             = frame
    hitbox.Size               = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text               = ""
    hitbox.ZIndex             = 7

    local isOn = false
    toggleStates[key] = false

    local function applyVisual(v)
        local ti = TweenInfo.new(0.22, Enum.EasingStyle.Quad)
        if v then
            TweenService:Create(knob,  ti, {Position = UDim2.new(1,-16,0.5,-7), BackgroundColor3 = C.on}):Play()
            TweenService:Create(track, ti, {BackgroundColor3 = C.trackOn}):Play()
            TweenService:Create(stroke,TweenInfo.new(0.18),{Transparency=0, Color=C.on}):Play()
        else
            TweenService:Create(knob,  ti, {Position = UDim2.new(0,2,0.5,-7), BackgroundColor3 = C.off}):Play()
            TweenService:Create(track, ti, {BackgroundColor3 = C.track}):Play()
            TweenService:Create(stroke,TweenInfo.new(0.18),{Transparency=0.65, Color=C.accent}):Play()
        end
    end

    local function setEnabled(v, silent)
        isOn = v
        toggleStates[key] = v
        applyVisual(v)
        if not silent and callback then callback(v) end
    end

    hitbox.Activated:Connect(function() setEnabled(not isOn) end)
    hitbox.MouseEnter:Connect(function() frame.BackgroundTransparency = 0.15 end)
    hitbox.MouseLeave:Connect(function() frame.BackgroundTransparency = 0.35 end)

    toggleSetters[key] = setEnabled
    return setEnabled
end

-- ==========================================
-- ВКЛАДКА: MAIN
-- ==========================================
local function sectionTitle(parent, text, yPos)
    local l = Instance.new("TextLabel")
    l.Parent             = parent
    l.Size               = UDim2.new(1,-14,0,20)
    l.Position           = UDim2.new(0,7,0,yPos)
    l.BackgroundTransparency = 1
    l.Text               = text
    l.TextColor3         = C.white
    l.Font               = Enum.Font.GothamBold
    l.TextSize           = 14
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.ZIndex             = 4
    return l
end

sectionTitle(scrollMain, "⚡ MAIN", 4)

makeToggle(scrollMain, "Auto Skip",       "Auto Skip",       28,  function() end)
makeToggle(scrollMain, "Auto x2 Speed",   "Auto x2 Speed",   65,  function() end)
makeToggle(scrollMain, "Auto x3 Speed",   "Auto x3 Speed",   102, function() end)
makeToggle(scrollMain, "Auto Play Again", "Auto Play Again", 139, function() end)

-- AUTO MODE ROW
local autoRow = Instance.new("Frame")
autoRow.Parent               = scrollMain
autoRow.Size                 = UDim2.new(1,-14,0,33)
autoRow.Position             = UDim2.new(0,7,0,176)
autoRow.BackgroundColor3     = C.panel
autoRow.BackgroundTransparency = 0.35
autoRow.ZIndex               = 4
addCorner(autoRow, 8)
addStroke(autoRow, C.accent, 1, 0.65)

local autoLbl = Instance.new("TextLabel")
autoLbl.Parent             = autoRow
autoLbl.Size               = UDim2.new(0,80,1,0)
autoLbl.Position           = UDim2.new(0,8,0,0)
autoLbl.BackgroundTransparency = 1
autoLbl.Text               = "Auto Mode"
autoLbl.TextColor3         = C.white
autoLbl.Font               = Enum.Font.GothamBold
autoLbl.TextSize           = isMobile and 11 or 12
autoLbl.TextXAlignment     = Enum.TextXAlignment.Left
autoLbl.ZIndex             = 5

local wavePickBtn = Instance.new("TextButton")
wavePickBtn.Parent          = autoRow
wavePickBtn.Size            = UDim2.new(0,120,0,22)
wavePickBtn.Position        = UDim2.new(1,-128,0.5,-11)
wavePickBtn.BackgroundColor3 = C.track
wavePickBtn.Text            = "Easy  ▼"
wavePickBtn.TextColor3      = C.dim
wavePickBtn.Font            = Enum.Font.Gotham
wavePickBtn.TextSize        = 11
wavePickBtn.ZIndex          = 5
addCorner(wavePickBtn, 6)

-- WAVE DROPDOWN
local waveDD = Instance.new("Frame")
waveDD.Parent               = scrollMain
waveDD.Size                 = UDim2.new(0,120,0,0)
waveDD.Position             = UDim2.new(1,-128,0,212)
waveDD.BackgroundColor3     = C.bg
waveDD.BackgroundTransparency = 0.05
waveDD.Visible              = false
waveDD.ClipsDescendants     = true
waveDD.ZIndex               = 40
addCorner(waveDD, 8)
addStroke(waveDD, C.accent, 2)

local waves   = {"Easy","Normal","Hard","Insane","Impossible","Apocalypse"}
local waveIH  = 28
for i, w in ipairs(waves) do
    local item = Instance.new("TextButton")
    item.Parent          = waveDD
    item.Size            = UDim2.new(1,-8,0,waveIH-4)
    item.Position        = UDim2.new(0,4,0,(i-1)*waveIH+4)
    item.BackgroundColor3 = C.panel
    item.BackgroundTransparency = 0.4
    item.Text            = w
    item.TextColor3      = C.white
    item.Font            = Enum.Font.GothamBold
    item.TextSize        = 11
    item.ZIndex          = 41
    addCorner(item, 5)
    local wName = w
    item.Activated:Connect(function()
        selectedWave         = wName
        wavePickBtn.Text     = wName .. "  ▼"
        wavePickBtn.TextColor3 = C.on
        TweenService:Create(waveDD,TweenInfo.new(0.18),{Size=UDim2.new(0,120,0,0)}):Play()
        task.delay(0.18, function() waveDD.Visible = false end)
    end)
    item.MouseEnter:Connect(function() item.BackgroundTransparency = 0.15 end)
    item.MouseLeave:Connect(function() item.BackgroundTransparency = 0.4  end)
end

local waveDDH = #waves * waveIH + 8
wavePickBtn.Activated:Connect(function()
    if waveDD.Visible then
        TweenService:Create(waveDD,TweenInfo.new(0.18),{Size=UDim2.new(0,120,0,0)}):Play()
        task.delay(0.18, function() waveDD.Visible = false end)
    else
        waveDD.Visible = true
        waveDD.Size    = UDim2.new(0,120,0,0)
        TweenService:Create(waveDD,TweenInfo.new(0.18),{Size=UDim2.new(0,120,0,waveDDH)}):Play()
    end
end)

-- ==========================================
-- POPUP HELPER FUNCTIONS
-- ==========================================
local function popupTitle(win, text)
    local l = Instance.new("TextLabel")
    l.Parent             = win
    l.Size               = UDim2.new(1,-16,0,26)
    l.Position           = UDim2.new(0,8,0,8)
    l.BackgroundTransparency = 1
    l.Text               = text
    l.TextColor3         = C.white
    l.Font               = Enum.Font.GothamBold
    l.TextSize           = 13
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.ZIndex             = 251
    return l
end

local function popupBox(win, placeholder)
    local box = Instance.new("TextBox")
    box.Parent          = win
    box.Size            = UDim2.new(1,-20,0,30)
    box.Position        = UDim2.new(0,10,0,40)
    box.BackgroundColor3 = C.panel
    box.BackgroundTransparency = 0.2
    box.Text            = ""
    box.PlaceholderText = placeholder
    box.TextColor3      = C.white
    box.PlaceholderColor3 = C.dim
    box.Font            = Enum.Font.Gotham
    box.TextSize        = 12
    box.ZIndex          = 251
    addCorner(box, 7)
    return box
end

local function popupBtns(win, onConfirm, onCancel)
    local confirm = Instance.new("TextButton")
    confirm.Parent          = win
    confirm.Size            = UDim2.new(0,110,0,28)
    confirm.Position        = UDim2.new(0,10,1,-38)
    confirm.BackgroundColor3 = C.on
    confirm.Text            = "✓ SAVE"
    confirm.TextColor3      = C.white
    confirm.Font            = Enum.Font.GothamBold
    confirm.TextSize        = 12
    confirm.ZIndex          = 251
    addCorner(confirm, 7)

    local cancel = Instance.new("TextButton")
    cancel.Parent          = win
    cancel.Size            = UDim2.new(0,110,0,28)
    cancel.Position        = UDim2.new(1,-120,1,-38)
    cancel.BackgroundColor3 = C.danger
    cancel.Text            = "✕ CANCEL"
    cancel.TextColor3      = C.white
    cancel.Font            = Enum.Font.GothamBold
    cancel.TextSize        = 12
    cancel.ZIndex          = 251
    addCorner(cancel, 7)

    confirm.Activated:Connect(onConfirm)
    cancel.Activated:Connect(onCancel)
    
    return confirm, cancel
end
-- ==========================================
-- ВКЛАДКА: MACRO (ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ)
-- ==========================================
sectionTitle(scrollMacro, "⚡ MACRO", 4)

-- TOGGLES СВЕРХУ
makeToggle(scrollMacro, "Record Macro",   "⏺ Record Macro",   28,  function(v) isRecording = v end)
makeToggle(scrollMacro, "Play Macro",     "▶ Play Macro",      65,  function(v)
    isPlaying = v
    if useHotkey then hotkeyBtn.Visible = v end
end)
makeToggle(scrollMacro, "Time Placement", "⏱ Time Placement",  102, function(v) end)
makeToggle(scrollMacro, "Loop Mode",      "🔁 Loop Mode",       139, function(v) loopMode = v end)
makeToggle(scrollMacro, "Hotkey",         "⌨ Hotkey",          176, function(v)
    useHotkey = v
    hotkeyBtn.Visible = v and isPlaying
end)

-- SEPARATOR
local macroSep = Instance.new("Frame")
macroSep.Parent          = scrollMacro
macroSep.Size            = UDim2.new(1,-14,0,1)
macroSep.Position        = UDim2.new(0,7,0,216)
macroSep.BackgroundColor3 = C.accent
macroSep.BackgroundTransparency = 0.7
macroSep.BorderSizePixel = 0
macroSep.ZIndex          = 4

-- SECTION TITLE
sectionTitle(scrollMacro, "📁 MACRO FILES", 224)

-- Small action buttons
local function smallBtn(parent, text, x, y, w, h)
    local b = Instance.new("TextButton")
    b.Parent          = parent
    b.Size            = UDim2.new(0,w or 90,0,h or 26)
    b.Position        = UDim2.new(0,x,0,y)
    b.BackgroundColor3 = C.btn
    b.Text            = text
    b.TextColor3      = C.white
    b.Font            = Enum.Font.GothamBold
    b.TextSize        = 10
    b.ZIndex          = 4
    addCorner(b, 6)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = C.btnHover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = C.btn      end)
    return b
end

local mCreateBtn  = smallBtn(scrollMacro, "📁 Create",  7, 248, 90, 26)
local mRefreshBtn = smallBtn(scrollMacro, "🔄 Refresh", 7, 278, 90, 26)

-- LIST LABEL
local listFrame = Instance.new("Frame")
listFrame.Parent          = scrollMacro
listFrame.Size            = UDim2.new(0,90,0,26)
listFrame.Position        = UDim2.new(0,7,0,308)
listFrame.BackgroundColor3 = C.btn
listFrame.BackgroundTransparency = 0.2
listFrame.ZIndex          = 4
addCorner(listFrame, 6)

local listFrameLbl = Instance.new("TextLabel")
listFrameLbl.Parent             = listFrame
listFrameLbl.Size               = UDim2.new(1,0,1,0)
listFrameLbl.BackgroundTransparency = 1
listFrameLbl.Text               = "📋 List"
listFrameLbl.TextColor3         = C.white
listFrameLbl.Font               = Enum.Font.GothamBold
listFrameLbl.TextSize           = 10
listFrameLbl.ZIndex             = 5

-- MACRO SELECTOR BUTTON
local macroSelBtn = Instance.new("TextButton")
macroSelBtn.Parent          = scrollMacro
macroSelBtn.Size            = UDim2.new(1,-104,0,26)
macroSelBtn.Position        = UDim2.new(0,100,0,308)
macroSelBtn.BackgroundColor3 = C.panel
macroSelBtn.BackgroundTransparency = 0.3
macroSelBtn.Text            = ""
macroSelBtn.ZIndex          = 4
addCorner(macroSelBtn, 6)

local macroSelLbl = Instance.new("TextLabel")
macroSelLbl.Parent             = macroSelBtn
macroSelLbl.Size               = UDim2.new(1,-20,1,0)
macroSelLbl.Position           = UDim2.new(0,8,0,0)
macroSelLbl.BackgroundTransparency = 1
macroSelLbl.Text               = "Выберите макрос..."
macroSelLbl.TextColor3         = C.dim
macroSelLbl.Font               = Enum.Font.Gotham
macroSelLbl.TextSize           = 10
macroSelLbl.TextXAlignment     = Enum.TextXAlignment.Left
macroSelLbl.ZIndex             = 5

local macroSelArrow = Instance.new("TextLabel")
macroSelArrow.Parent             = macroSelBtn
macroSelArrow.Size               = UDim2.new(0,16,1,0)
macroSelArrow.Position           = UDim2.new(1,-18,0,0)
macroSelArrow.BackgroundTransparency = 1
macroSelArrow.Text               = "▼"
macroSelArrow.TextColor3         = C.dim
macroSelArrow.Font               = Enum.Font.GothamBold
macroSelArrow.TextSize           = 9
macroSelArrow.ZIndex             = 5

macroSelBtn.MouseEnter:Connect(function() macroSelBtn.BackgroundTransparency = 0.1 end)
macroSelBtn.MouseLeave:Connect(function() macroSelBtn.BackgroundTransparency = 0.3 end)

-- MACRO DROPDOWN (в screenGui для перекрытия всего)
local macroDD = Instance.new("ScrollingFrame")
macroDD.Parent               = screenGui
macroDD.Size                 = UDim2.new(0, CONTENT_W - 104, 0, 0)
macroDD.BackgroundColor3     = C.bg
macroDD.BackgroundTransparency = 0.05
macroDD.Visible              = false
macroDD.ZIndex               = 200
macroDD.ScrollBarThickness   = 3
macroDD.ScrollBarImageColor3 = C.accent
macroDD.BorderSizePixel      = 0
macroDD.ClipsDescendants     = true
addCorner(macroDD, 8)
addStroke(macroDD, C.accent, 2)

-- Функция обновления позиции dropdown
local function updateMacroDropdownPos()
    local btnPos = macroSelBtn.AbsolutePosition
    macroDD.Position = UDim2.new(0, btnPos.X, 0, btnPos.Y + 29)
end

-- Refresh Macro Dropdown
local function refreshMacroDD()
    for _, ch in pairs(macroDD:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    
    for i, mac in ipairs(macros) do
        local isSel = (mac.name == selectedMacro)
        
        local itemFrame = Instance.new("Frame")
        itemFrame.Parent          = macroDD
        itemFrame.Size            = UDim2.new(1,-8,0,30)
        itemFrame.Position        = UDim2.new(0,4,0,(i-1)*34+4)
        itemFrame.BackgroundColor3 = isSel and Color3.fromRGB(88, 101, 242) or C.panel
        itemFrame.BackgroundTransparency = isSel and 0.05 or 0.4
        itemFrame.ZIndex          = 201
        addCorner(itemFrame, 5)
        
        local itemBtn = Instance.new("TextButton")
        itemBtn.Parent          = itemFrame
        itemBtn.Size            = UDim2.new(1,-40,1,0)
        itemBtn.Position        = UDim2.new(0,0,0,0)
        itemBtn.BackgroundTransparency = 1
        itemBtn.Text            = "📄 "..mac.name
        itemBtn.TextColor3      = isSel and C.on or C.white
        itemBtn.Font            = Enum.Font.GothamBold
        itemBtn.TextSize        = 10
        itemBtn.TextXAlignment  = Enum.TextXAlignment.Left
        itemBtn.ZIndex          = 202
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0,8)
        padding.Parent = itemBtn
        
        -- DELETE BUTTON
        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Parent          = itemFrame
        deleteBtn.Size            = UDim2.new(0,32,0,22)
        deleteBtn.Position        = UDim2.new(1,-34,0.5,-11)
        deleteBtn.BackgroundColor3 = C.danger
        deleteBtn.Text            = "🗑"
        deleteBtn.TextColor3      = C.white
        deleteBtn.Font            = Enum.Font.GothamBold
        deleteBtn.TextSize        = 12
        deleteBtn.ZIndex          = 203
        addCorner(deleteBtn, 5)
        
        local n = mac.name
        
        -- SELECT MACRO
        itemBtn.Activated:Connect(function()
            selectedMacro       = n
            macroSelLbl.Text    = "📄 "..n
            macroSelLbl.TextColor3 = C.on
            macroDD.Visible     = false
            refreshMacroDD()
        end)
        
        -- DELETE MACRO
        deleteBtn.Activated:Connect(function()
            for idx, m in ipairs(macros) do
                if m.name == n then
                    table.remove(macros, idx)
                    break
                end
            end
            if selectedMacro == n then
                selectedMacro = nil
                macroSelLbl.Text = "Выберите макрос..."
                macroSelLbl.TextColor3 = C.dim
            end
            saveMacros()
            refreshMacroDD()
            print("🗑 Macro deleted:", n)
        end)
        
        itemBtn.MouseEnter:Connect(function() 
            if selectedMacro ~= mac.name then 
                itemFrame.BackgroundTransparency = 0.2 
            end 
        end)
        itemBtn.MouseLeave:Connect(function() 
            if selectedMacro ~= mac.name then 
                itemFrame.BackgroundTransparency = 0.4 
            end 
        end)
    end
    
    macroDD.CanvasSize = UDim2.new(0,0,0,#macros*34+8)
end

-- Toggle Dropdown
macroSelBtn.Activated:Connect(function()
    if macroDD.Visible then
        macroDD.Visible = false
    else
        refreshMacroDD()
        updateMacroDropdownPos()
        macroDD.Visible = true
        local targetH = math.min(#macros*34+8, 150)
        macroDD.Size = UDim2.new(0, CONTENT_W - 104, 0, targetH)
    end
end)

-- CREATE MACRO WINDOW
local createMacroWin = Instance.new("Frame")
createMacroWin.Parent          = screenGui
createMacroWin.Size            = UDim2.new(0,270,0,138)
createMacroWin.Position        = UDim2.new(0.5,-135,0.5,-69)
createMacroWin.BackgroundColor3 = C.bg
createMacroWin.BackgroundTransparency = 0.05
createMacroWin.Visible         = false
createMacroWin.ZIndex          = 250
addCorner(createMacroWin, 12)
addStroke(createMacroWin, C.accent, 3)

popupTitle(createMacroWin, "📁 CREATE MACRO")
local macroNameBox = popupBox(createMacroWin, "Название макроса...")

-- Fix ZIndex для popup элементов
macroNameBox.ZIndex = 251
for _, child in pairs(createMacroWin:GetDescendants()) do
    if child:IsA("GuiObject") then
        child.ZIndex = math.max(child.ZIndex, 251)
    end
end

popupBtns(createMacroWin,
    function()
        local n = macroNameBox.Text
        if n ~= "" then
            table.insert(macros, {name=n, actions={}})
            createMacroWin.Visible = false
            macroNameBox.Text = ""
            refreshMacroDD()
            saveMacros()
            print("✅ Macro created:", n)
        end
    end,
    function()
        createMacroWin.Visible = false
        macroNameBox.Text = ""
    end
)

mCreateBtn.Activated:Connect(function()
    createMacroWin.Visible = true
    macroNameBox.Text = ""
end)

mRefreshBtn.Activated:Connect(function()
    loadMacros()
    refreshMacroDD()
    print("🔄 Macros refreshed")
end)

-- Обновлять позицию dropdown при драге окна
local originalDragConnect = drag
RunService.RenderStepped:Connect(function()
    if macroDD.Visible then
        updateMacroDropdownPos()
    end
end)

-- ==========================================
-- ВКЛАДКА: CHANNELS (ИСПРАВЛЕННАЯ)
-- ==========================================

-- TITLE
local chanTitle = Instance.new("TextLabel")
chanTitle.Parent             = scrollChannels
chanTitle.Size               = UDim2.new(1,-14,0,20)
chanTitle.Position           = UDim2.new(0,7,0,4)
chanTitle.BackgroundTransparency = 1
chanTitle.Text               = "📢 КАНАЛЫ"
chanTitle.TextColor3         = C.white
chanTitle.Font               = Enum.Font.GothamBold
chanTitle.TextSize           = 14
chanTitle.TextXAlignment     = Enum.TextXAlignment.Left
chanTitle.ZIndex             = 4

-- TG CHANNEL BUTTON
local tgBtn = Instance.new("TextButton")
tgBtn.Parent          = scrollChannels
tgBtn.Size            = UDim2.new(1, -14, 0, 60)
tgBtn.Position        = UDim2.new(0, 7, 0, 32)
tgBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
tgBtn.BackgroundTransparency = 0.1
tgBtn.Text            = ""
tgBtn.ZIndex          = 4
tgBtn.AutoButtonColor = false
addCorner(tgBtn, 12)

-- RGB STROKE
local tgStroke = addStroke(tgBtn, C.accent, 3)
local tgHue = 0
RunService.RenderStepped:Connect(function()
    tgHue = (tgHue + 0.008) % 1
    tgStroke.Color = Color3.fromHSV(tgHue, 1, 1)
end)

-- ОГОНЬ СЛЕВА 🔥
local fire1 = Instance.new("TextLabel")
fire1.Parent             = tgBtn
fire1.Size               = UDim2.new(0, 50, 1, 0)
fire1.Position           = UDim2.new(0, 8, 0, 0)
fire1.BackgroundTransparency = 1
fire1.Text               = "🔥"
fire1.TextColor3         = Color3.fromRGB(255, 100, 50)
fire1.Font               = Enum.Font.GothamBold
fire1.TextSize           = 32
fire1.ZIndex             = 5

-- ТЕКСТ
local tgText = Instance.new("TextLabel")
tgText.Parent             = tgBtn
tgText.Size               = UDim2.new(1, -120, 1, 0)
tgText.Position           = UDim2.new(0, 60, 0, 0)
tgText.BackgroundTransparency = 1
tgText.Text               = "TG Channel"
tgText.TextColor3         = C.white
tgText.Font               = Enum.Font.GothamBold
tgText.TextSize           = isMobile and 14 or 16
tgText.ZIndex             = 5

-- ОГОНЬ СПРАВА 🔥
local fire2 = Instance.new("TextLabel")
fire2.Parent             = tgBtn
fire2.Size               = UDim2.new(0, 50, 1, 0)
fire2.Position           = UDim2.new(1, -58, 0, 0)
fire2.BackgroundTransparency = 1
fire2.Text               = "🔥"
fire2.TextColor3         = Color3.fromRGB(255, 100, 50)
fire2.Font               = Enum.Font.GothamBold
fire2.TextSize           = 32
fire2.ZIndex             = 5

-- HOVER
tgBtn.MouseEnter:Connect(function()
    TweenService:Create(tgBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
end)
tgBtn.MouseLeave:Connect(function()
    TweenService:Create(tgBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
end)

-- КЛИК (ТОЛЬКО КОПИРОВАНИЕ)
tgBtn.Activated:Connect(function()
    local url = "https://t.me/zeenixs"
    
    if setclipboard then
        setclipboard(url)
        tgText.Text = "✅ Скопировано!"
        tgText.TextColor3 = C.on
        task.wait(1.5)
        tgText.Text = "TG Channel"
        tgText.TextColor3 = C.white
    else
        print("❌ Функция setclipboard недоступна")
    end
    
    print("📱 Telegram: " .. url)
end)

-- ОПИСАНИЕ
local descLbl = Instance.new("TextLabel")
descLbl.Parent             = scrollChannels
descLbl.Size               = UDim2.new(1, -14, 0, 50)
descLbl.Position           = UDim2.new(0, 7, 0, 100)
descLbl.BackgroundTransparency = 1
descLbl.Text               = "🔥 Нажми чтобы скопировать ссылку!\n\nПодпишись на Telegram канал\nи получай обновления первым"
descLbl.TextColor3         = Color3.fromRGB(180, 180, 220)
descLbl.Font               = Enum.Font.Gotham
descLbl.TextSize           = 11
descLbl.TextWrapped        = true
descLbl.TextYAlignment     = Enum.TextYAlignment.Top
descLbl.ZIndex             = 4

-- SEPARATOR
local chanSep = Instance.new("Frame")
chanSep.Parent          = scrollChannels
chanSep.Size            = UDim2.new(1, -14, 0, 1)
chanSep.Position        = UDim2.new(0, 7, 0, 158)
chanSep.BackgroundColor3 = C.accent
chanSep.BackgroundTransparency = 0.7
chanSep.BorderSizePixel = 0
chanSep.ZIndex          = 4

-- CREDITS
local creditsLbl2 = Instance.new("TextLabel")
creditsLbl2.Parent             = scrollChannels
creditsLbl2.Size               = UDim2.new(1, -14, 0, 50)
creditsLbl2.Position           = UDim2.new(0, 7, 0, 170)
creditsLbl2.BackgroundTransparency = 1
creditsLbl2.Text               = "⚡ ZeexHub by zeenixxs ⚡\n\nMade with passion\n© 2025"
creditsLbl2.TextColor3         = Color3.fromRGB(180, 160, 255)
creditsLbl2.TextTransparency   = 0.4
creditsLbl2.Font               = Enum.Font.Gotham
creditsLbl2.TextSize           = 10
creditsLbl2.TextYAlignment     = Enum.TextYAlignment.Top
creditsLbl2.ZIndex             = 4

-- ==========================================
-- ==========================================
-- ВКЛАДКА: SETTINGS (С ПОЛНЫМИ ИСПРАВЛЕНИЯМИ)
-- ==========================================
sectionTitle(scrollSettings, "⚡ SETTINGS", 4)

-- CONFIG INPUT BOX
local cfgInputFrame = Instance.new("Frame")
cfgInputFrame.Parent               = scrollSettings
cfgInputFrame.Size                 = UDim2.new(1,-14,0,33)
cfgInputFrame.Position             = UDim2.new(0,7,0,28)
cfgInputFrame.BackgroundColor3     = C.panel
cfgInputFrame.BackgroundTransparency = 0.35
cfgInputFrame.ZIndex               = 4
addCorner(cfgInputFrame, 8)
addStroke(cfgInputFrame, C.accent, 1, 0.65)

local cfgInputBox = Instance.new("TextBox")
cfgInputBox.Parent          = cfgInputFrame
cfgInputBox.Size            = UDim2.new(1,-16,1,0)
cfgInputBox.Position        = UDim2.new(0,8,0,0)
cfgInputBox.BackgroundTransparency = 1
cfgInputBox.PlaceholderText = "Config Name..."
cfgInputBox.Text            = ""
cfgInputBox.TextColor3      = C.white
cfgInputBox.PlaceholderColor3 = C.dim
cfgInputBox.Font            = Enum.Font.Gotham
cfgInputBox.TextSize        = isMobile and 11 or 12
cfgInputBox.TextXAlignment  = Enum.TextXAlignment.Left
cfgInputBox.ClearTextOnFocus = false
cfgInputBox.ZIndex          = 5

-- CONFIG ROW (Create | List | Load)
local cfgRow = Instance.new("Frame")
cfgRow.Parent               = scrollSettings
cfgRow.Size                 = UDim2.new(1,-14,0,33)
cfgRow.Position             = UDim2.new(0,7,0,68)
cfgRow.BackgroundColor3     = C.panel
cfgRow.BackgroundTransparency = 0.35
cfgRow.ZIndex               = 4
addCorner(cfgRow, 8)
addStroke(cfgRow, C.accent, 1, 0.65)

local cfgRowLbl = Instance.new("TextLabel")
cfgRowLbl.Parent             = cfgRow
cfgRowLbl.Size               = UDim2.new(0,55,1,0)
cfgRowLbl.Position           = UDim2.new(0,8,0,0)
cfgRowLbl.BackgroundTransparency = 1
cfgRowLbl.Text               = "Config"
cfgRowLbl.TextColor3         = C.white
cfgRowLbl.Font               = Enum.Font.GothamBold
cfgRowLbl.TextSize           = isMobile and 11 or 12
cfgRowLbl.TextXAlignment     = Enum.TextXAlignment.Left
cfgRowLbl.ZIndex             = 5

-- 3 КНОПКИ
local BW = 56
local GAP = 4
local cfgCreateBtn = Instance.new("TextButton")
cfgCreateBtn.Parent          = cfgRow
cfgCreateBtn.Size            = UDim2.new(0,BW,0,22)
cfgCreateBtn.Position        = UDim2.new(1,-(BW*3+GAP*2+6),0.5,-11)
cfgCreateBtn.BackgroundColor3 = C.btn
cfgCreateBtn.Text            = "Create"
cfgCreateBtn.TextColor3      = C.white
cfgCreateBtn.Font            = Enum.Font.GothamBold
cfgCreateBtn.TextSize        = 10
cfgCreateBtn.ZIndex          = 5
addCorner(cfgCreateBtn, 5)
cfgCreateBtn.MouseEnter:Connect(function() cfgCreateBtn.BackgroundColor3 = C.btnHover end)
cfgCreateBtn.MouseLeave:Connect(function() cfgCreateBtn.BackgroundColor3 = C.btn      end)

local cfgListBtn = Instance.new("TextButton")
cfgListBtn.Parent          = cfgRow
cfgListBtn.Size            = UDim2.new(0,BW,0,22)
cfgListBtn.Position        = UDim2.new(1,-(BW*2+GAP*1+6),0.5,-11)
cfgListBtn.BackgroundColor3 = C.btn
cfgListBtn.Text            = "List"
cfgListBtn.TextColor3      = C.white
cfgListBtn.Font            = Enum.Font.GothamBold
cfgListBtn.TextSize        = 10
cfgListBtn.ZIndex          = 5
addCorner(cfgListBtn, 5)
cfgListBtn.MouseEnter:Connect(function() cfgListBtn.BackgroundColor3 = C.btnHover end)
cfgListBtn.MouseLeave:Connect(function() cfgListBtn.BackgroundColor3 = C.btn      end)

local cfgLoadBtn = Instance.new("TextButton")
cfgLoadBtn.Parent          = cfgRow
cfgLoadBtn.Size            = UDim2.new(0,BW,0,22)
cfgLoadBtn.Position        = UDim2.new(1,-(BW+6),0.5,-11)
cfgLoadBtn.BackgroundColor3 = C.btn
cfgLoadBtn.Text            = "Load"
cfgLoadBtn.TextColor3      = C.white
cfgLoadBtn.Font            = Enum.Font.GothamBold
cfgLoadBtn.TextSize        = 10
cfgLoadBtn.ZIndex          = 5
addCorner(cfgLoadBtn, 5)
cfgLoadBtn.MouseEnter:Connect(function() cfgLoadBtn.BackgroundColor3 = C.btnHover end)
cfgLoadBtn.MouseLeave:Connect(function() cfgLoadBtn.BackgroundColor3 = C.btn      end)

-- СТАТУС ВЫБРАННОГО КОНФИГА
local cfgStatusLbl = Instance.new("TextLabel")
cfgStatusLbl.Parent             = scrollSettings
cfgStatusLbl.Size               = UDim2.new(1,-14,0,16)
cfgStatusLbl.Position           = UDim2.new(0,7,0,108)
cfgStatusLbl.BackgroundTransparency = 1
cfgStatusLbl.Text               = "Конфиг не выбран"
cfgStatusLbl.TextColor3         = C.dim
cfgStatusLbl.Font               = Enum.Font.Gotham
cfgStatusLbl.TextSize           = 10
cfgStatusLbl.TextXAlignment     = Enum.TextXAlignment.Left
cfgStatusLbl.ZIndex             = 4

-- CONFIG DROPDOWN (ИСПРАВЛЕННЫЙ)
local cfgDD = Instance.new("ScrollingFrame")
cfgDD.Parent               = scrollSettings
cfgDD.Size                 = UDim2.new(1,-14,0,0)
cfgDD.Position             = UDim2.new(0,7,0,128)
cfgDD.BackgroundColor3     = C.bg
cfgDD.BackgroundTransparency = 0.05
cfgDD.Visible              = false
cfgDD.ClipsDescendants     = true
cfgDD.ZIndex               = 50
cfgDD.ScrollBarThickness   = 3
cfgDD.ScrollBarImageColor3 = C.accent
cfgDD.BorderSizePixel      = 0
addCorner(cfgDD, 8)
addStroke(cfgDD, C.accent, 2)

local function refreshCfgDD()
    for _, ch in pairs(cfgDD:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    
    for i, cfg in ipairs(configs) do
        local isSel = (cfg.name == selectedConfig)
        
        local itemFrame = Instance.new("Frame")
        itemFrame.Parent          = cfgDD
        itemFrame.Size            = UDim2.new(1,-8,0,30)
        itemFrame.Position        = UDim2.new(0,4,0,(i-1)*34+4)
        itemFrame.BackgroundColor3 = isSel and Color3.fromRGB(88, 101, 242) or C.panel
        itemFrame.BackgroundTransparency = isSel and 0.05 or 0.4
        itemFrame.ZIndex          = 51
        addCorner(itemFrame, 5)
        
        local itemBtn = Instance.new("TextButton")
        itemBtn.Parent          = itemFrame
        itemBtn.Size            = UDim2.new(1,-40,1,0)
        itemBtn.Position        = UDim2.new(0,0,0,0)
        itemBtn.BackgroundTransparency = 1
        itemBtn.Text            = "⚙️ "..cfg.name
        itemBtn.TextColor3      = isSel and C.on or C.white
        itemBtn.Font            = Enum.Font.GothamBold
        itemBtn.TextSize        = 10
        itemBtn.TextXAlignment  = Enum.TextXAlignment.Left
        itemBtn.ZIndex          = 52
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0,8)
        padding.Parent = itemBtn
        
        -- DELETE BUTTON
        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Parent          = itemFrame
        deleteBtn.Size            = UDim2.new(0,32,0,22)
        deleteBtn.Position        = UDim2.new(1,-34,0.5,-11)
        deleteBtn.BackgroundColor3 = C.danger
        deleteBtn.Text            = "🗑"
        deleteBtn.TextColor3      = C.white
        deleteBtn.Font            = Enum.Font.GothamBold
        deleteBtn.TextSize        = 12
        deleteBtn.ZIndex          = 53
        addCorner(deleteBtn, 5)
        
        local n = cfg.name
        
        -- SELECT CONFIG
        itemBtn.Activated:Connect(function()
            selectedConfig      = n
            cfgStatusLbl.Text   = "Выбран: "..n
            cfgStatusLbl.TextColor3 = C.on
            refreshCfgDD()
        end)
        
        -- DELETE CONFIG
        deleteBtn.Activated:Connect(function()
            for idx, c in ipairs(configs) do
                if c.name == n then
                    table.remove(configs, idx)
                    break
                end
            end
            if selectedConfig == n then
                selectedConfig = nil
                cfgStatusLbl.Text = "Конфиг не выбран"
                cfgStatusLbl.TextColor3 = C.dim
            end
            saveConfigs()
            refreshCfgDD()
            print("🗑 Config deleted:", n)
        end)
        
        itemBtn.MouseEnter:Connect(function() 
            if selectedConfig ~= cfg.name then 
                itemFrame.BackgroundTransparency = 0.2 
            end 
        end)
        itemBtn.MouseLeave:Connect(function() 
            if selectedConfig ~= cfg.name then 
                itemFrame.BackgroundTransparency = 0.4 
            end 
        end)
    end
    
    cfgDD.CanvasSize = UDim2.new(0,0,0,#configs*34+8)
    
    if cfgDD.Visible then
        local targetH = math.min(#configs*34+8, 150)
        TweenService:Create(cfgDD,TweenInfo.new(0.18),{Size=UDim2.new(1,-14,0,targetH)}):Play()
    end
end

-- LIST BUTTON
cfgListBtn.Activated:Connect(function()
    if cfgDD.Visible then
        TweenService:Create(cfgDD,TweenInfo.new(0.18),{Size=UDim2.new(1,-14,0,0)}):Play()
        task.delay(0.18, function() cfgDD.Visible = false end)
    else
        cfgDD.Visible = true
        cfgDD.Size    = UDim2.new(1,-14,0,0)
        refreshCfgDD()
    end
end)

-- CREATE CONFIG
cfgCreateBtn.Activated:Connect(function()
    local n = cfgInputBox.Text
    if n == "" then 
        print("❌ Введите название конфига!")
        return 
    end
    
    -- Снапшот всех состояний
    local snapshot = {}
    for k, v in pairs(toggleStates) do
        snapshot[k] = v
    end
    snapshot["_wave"] = selectedWave
    
    -- Перезаписать если существует
    local found = false
    for i, cfg in ipairs(configs) do
        if cfg.name == n then
            configs[i].states = snapshot
            found = true
            break
        end
    end
    if not found then
        table.insert(configs, {name=n, states=snapshot})
    end
    
    cfgInputBox.Text = ""
    saveConfigs()
    refreshCfgDD()
    print("✅ Config saved:", n)
end)

-- LOAD CONFIG
cfgLoadBtn.Activated:Connect(function()
    if not selectedConfig then
        print("❌ Сначала выберите конфиг в List!")
        return
    end
    
    for _, cfg in ipairs(configs) do
        if cfg.name == selectedConfig then
            for key, val in pairs(cfg.states) do
                if key == "_wave" then
                    selectedWave           = val
                    wavePickBtn.Text       = val.."  ▼"
                    wavePickBtn.TextColor3 = C.on
                elseif toggleSetters[key] then
                    toggleSetters[key](val, false)
                end
            end
            print("✅ Config loaded:", selectedConfig)
            return
        end
    end
end)

-- DELETE SELECTED CONFIG BUTTON
local cfgDelRow = Instance.new("Frame")
cfgDelRow.Parent               = scrollSettings
cfgDelRow.Size                 = UDim2.new(1,-14,0,33)
cfgDelRow.Position             = UDim2.new(0,7,0,290)
cfgDelRow.BackgroundColor3     = C.danger
cfgDelRow.BackgroundTransparency = 0.3
cfgDelRow.ZIndex               = 4
addCorner(cfgDelRow, 8)
addStroke(cfgDelRow, C.danger, 1, 0.5)

local cfgDelBtn = Instance.new("TextButton")
cfgDelBtn.Parent          = cfgDelRow
cfgDelBtn.Size            = UDim2.new(1,0,1,0)
cfgDelBtn.BackgroundTransparency = 1
cfgDelBtn.Text            = "🗑 Delete Selected Config"
cfgDelBtn.TextColor3      = C.white
cfgDelBtn.Font            = Enum.Font.GothamBold
cfgDelBtn.TextSize        = isMobile and 11 or 12
cfgDelBtn.ZIndex          = 5

cfgDelBtn.Activated:Connect(function()
    if not selectedConfig then
        print("❌ Сначала выберите конфиг!")
        return
    end
    
    for i, cfg in ipairs(configs) do
        if cfg.name == selectedConfig then
            table.remove(configs, i)
            break
        end
    end
    
    print("🗑 Config deleted:", selectedConfig)
    selectedConfig = nil
    cfgStatusLbl.Text = "Конфиг не выбран"
    cfgStatusLbl.TextColor3 = C.dim
    saveConfigs()
    refreshCfgDD()
end)

cfgDelBtn.MouseEnter:Connect(function() cfgDelRow.BackgroundTransparency = 0.15 end)
cfgDelBtn.MouseLeave:Connect(function() cfgDelRow.BackgroundTransparency = 0.3  end)

-- SEPARATOR
local sep1 = Instance.new("Frame")
sep1.Parent          = scrollSettings
sep1.Size            = UDim2.new(1,-14,0,1)
sep1.Position        = UDim2.new(0,7,0,330)
sep1.BackgroundColor3 = C.accent
sep1.BackgroundTransparency = 0.7
sep1.BorderSizePixel = 0
sep1.ZIndex          = 4

-- ADDITIONAL SETTINGS
sectionTitle(scrollSettings, "⚙️ OTHER", 340)

makeToggle(scrollSettings, "AutoSave",     "💾 Auto Save Configs",  364, function(v) end)
makeToggle(scrollSettings, "Notifications", "🔔 Notifications",      401, function(v) end)
makeToggle(scrollSettings, "RainbowUI",    "🌈 Rainbow UI Border",  438, function(v)
    if v then
        rgbStroke.Enabled = true
    else
        rgbStroke.Enabled = false
        rgbStroke.Color = C.accent
    end
end)

-- RESET ALL BUTTON
local resetRow = Instance.new("Frame")
resetRow.Parent               = scrollSettings
resetRow.Size                 = UDim2.new(1,-14,0,33)
resetRow.Position             = UDim2.new(0,7,0,478)
resetRow.BackgroundColor3     = Color3.fromRGB(200,50,50)
resetRow.BackgroundTransparency = 0.3
resetRow.ZIndex               = 4
addCorner(resetRow, 8)
addStroke(resetRow, Color3.fromRGB(255,80,80), 1, 0.5)

local resetBtn = Instance.new("TextButton")
resetBtn.Parent          = resetRow
resetBtn.Size            = UDim2.new(1,0,1,0)
resetBtn.BackgroundTransparency = 1
resetBtn.Text            = "⚠️ Reset All Settings"
resetBtn.TextColor3      = C.white
resetBtn.Font            = Enum.Font.GothamBold
resetBtn.TextSize        = isMobile and 11 or 12
resetBtn.ZIndex          = 5

resetBtn.Activated:Connect(function()
    for key, setter in pairs(toggleSetters) do
        setter(false, false)
    end
    selectedWave = "Easy"
    wavePickBtn.Text = "Easy  ▼"
    wavePickBtn.TextColor3 = C.dim
    print("⚠️ All settings reset!")
end)

resetBtn.MouseEnter:Connect(function() resetRow.BackgroundTransparency = 0.15 end)
resetBtn.MouseLeave:Connect(function() resetRow.BackgroundTransparency = 0.3  end)

-- CREDITS
local creditsLbl = Instance.new("TextLabel")
creditsLbl.Parent             = scrollSettings
creditsLbl.Size               = UDim2.new(1,-14,0,30)
creditsLbl.Position           = UDim2.new(0,7,0,518)
creditsLbl.BackgroundTransparency = 1
creditsLbl.Text               = "Made with ❤️ by zeenixxs\nZeexHub v1.0"
creditsLbl.TextColor3         = Color3.fromRGB(180,160,255)
creditsLbl.TextTransparency   = 0.4
creditsLbl.Font               = Enum.Font.Gotham
creditsLbl.TextSize           = 9
creditsLbl.TextYAlignment     = Enum.TextYAlignment.Top
creditsLbl.ZIndex             = 4

-- UPDATE CANVAS SIZE
scrollSettings.CanvasSize = UDim2.new(0,0,0,560)

-- ==========================================
-- NAVIGATION
-- ==========================================
local function showTab(name)
    scrollMain.Visible     = name == "main"
    scrollMacro.Visible    = name == "macro"
    scrollSettings.Visible = name == "settings"
    scrollChannels.Visible = name == "channels"
    -- закрыть все дропдауны
    waveDD.Visible  = false
    macroDD.Visible = false
    if name ~= "settings" then
        cfgDD.Visible = false
    end
end

navMain.Activated:Connect(function()     showTab("main")     end)
navMacro.Activated:Connect(function()    showTab("macro")    end)
navSettings.Activated:Connect(function() showTab("settings") end)
navChannels.Activated:Connect(function() showTab("channels") end)

-- ==========================================
-- FOOTER
-- ==========================================
local footer = Instance.new("TextLabel")
footer.Parent             = mainFrame
footer.Size               = UDim2.new(1,0,0,FOOTER_H)
footer.Position           = UDim2.new(0,0,1,-FOOTER_H)
footer.BackgroundTransparency = 1
footer.Text               = "⚡ zeexHub  by zeenixxs ⚡"
footer.TextColor3         = Color3.fromRGB(200,180,255)
footer.TextTransparency   = 0.35
footer.Font               = Enum.Font.Gotham
footer.TextSize           = 9
footer.ZIndex             = 2

-- ==========================================
-- ЗАКРЫТИЕ ДРОПДАУНОВ ПРИ КЛИКЕ СНАРУЖИ
-- ==========================================
UserInputService.InputBegan:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1
    and inp.UserInputType ~= Enum.UserInputType.Touch then return end
    
    local p = inp.Position
    
    local function isInside(el)
        if not el.Visible then return false end
        local ep, es = el.AbsolutePosition, el.AbsoluteSize
        return p.X >= ep.X and p.X <= ep.X+es.X and p.Y >= ep.Y and p.Y <= ep.Y+es.Y
    end
    
    -- Закрывать ТОЛЬКО если клик ВНЕ элемента
    if waveDD.Visible and not isInside(waveDD) and not isInside(wavePickBtn) then
        TweenService:Create(waveDD,TweenInfo.new(0.15),{Size=UDim2.new(0,120,0,0)}):Play()
        task.delay(0.15, function() waveDD.Visible = false end)
    end
    
    if macroDD.Visible and not isInside(macroDD) and not isInside(macroSelBtn) then
        macroDD.Visible = false
    end
    
    if cfgDD.Visible and not isInside(cfgDD) and not isInside(cfgListBtn) then
        TweenService:Create(cfgDD,TweenInfo.new(0.15),{Size=UDim2.new(1,-14,0,0)}):Play()
        task.delay(0.15, function() cfgDD.Visible = false end)
    end
end)
-- ==========================================
-- KEYBOARD SHORTCUTS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- ESC - закрыть все дропдауны
    if input.KeyCode == Enum.KeyCode.Escape then
        waveDD.Visible = false
        macroDD.Visible = false
        cfgDD.Visible = false
        createMacroWin.Visible = false
    end
    
    -- INSERT - toggle main window
    if input.KeyCode == Enum.KeyCode.Insert then
        mainFrame.Visible = not mainFrame.Visible
        tabBtn.Visible = not mainFrame.Visible
    end
    
    -- F1 - quick toggle hotkey
    if input.KeyCode == Enum.KeyCode.F1 and useHotkey then
        isPlaying = not isPlaying
        hotkeyBtn.BackgroundColor3 = isPlaying and Color3.fromRGB(220,40,40) or C.on
        hotkeyBtn.Text = isPlaying and "⏸" or "▶"
    end
end)

-- ==========================================
-- AUTO SAVE (каждые 60 секунд)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(60)
        if toggleStates["AutoSave"] then
            saveConfigs()
            saveMacros()
            print("💾 Auto-saved configs & macros")
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
loadMacros()
loadConfigs()
refreshMacroDD()
refreshCfgDD()

-- Применить дефолтные значения
toggleSetters["AutoSave"](true, true)
toggleSetters["Notifications"](true, true)
toggleSetters["RainbowUI"](true, true)

-- ==========================================
-- AUTO SKIP - IGNORE WARNING + SELECT
-- ==========================================

local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local gui = player:WaitForChild("PlayerGui")

task.wait(3)

local function activate()
    local btn = nil
    
    pcall(function()
        btn = gui.GameGui.Screen.Middle.SandboxMenu.SandboxMenu.Frame.Items.Items.Waves.GoToWave.Items.Items.Button
    end)
    
    if not btn or not btn.Visible then
        if toggleStates and toggleStates["Notifications"] then
            warn("❌ Кнопка не найдена")
        end
        return false
    end
    
    local success = false
    
    pcall(function()
        -- Делаем Selectable (уже true, но на всякий)
        btn.Selectable = true
        btn.Active = true
        
        task.wait(0.1)
        
        -- ВЫБИРАЕМ (игнорим warning)
        GuiService.SelectedObject = btn
        
        task.wait(0.3)
        
        -- Проверяем что РЕАЛЬНО выбрана
        if GuiService.SelectedObject == btn then
            if toggleStates and toggleStates["Notifications"] then
                print("✅ Кнопка выбрана (warning игнорирован)")
            end
            
            task.wait(0.2)
            
            -- ENTER DOWN
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            
            task.wait(0.1)
            
            -- ENTER UP
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            
            success = true
            
            if toggleStates and toggleStates["Notifications"] then
                warn("✅ ENTER отправлен!")
            end
            
            task.wait(0.3)
        else
            if toggleStates and toggleStates["Notifications"] then
                warn("❌ Кнопка НЕ выбрана!")
            end
        end
        
        -- Очистка
        GuiService.SelectedObject = nil
    end)
    
    return success
end

-- ОДИН РАЗ
local done = false

RunService.Heartbeat:Connect(function()
    if not toggleStates or not toggleStates["Auto Skip"] then
        done = false
        return
    end
    
    if not done then
        task.wait(1)
        
        if activate() then
            if toggleStates and toggleStates["Notifications"] then
                print("========================================")
                warn("✅✅✅ AUTO SKIP АКТИВИРОВАН!")
                print("========================================")
            end
        end
        
        done = true
    end
end)

-- Респавн
player.CharacterAdded:Connect(function()
    task.wait(3)
    done = false
end)

print("========================================")
print("✅ AUTO SKIP")
print("   1. SelectedObject = button (ignore warning)")
print("   2. SendKeyEvent(Return)")
print("========================================")

print("📋 Configs:", #configs, "| 📄 Macros:", #macros)
print("========================================")
