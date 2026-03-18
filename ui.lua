-- Фиксы:
-- 1. Добавлена кнопка Delete для удаления конфигов
-- 2. Исправлен баг с выбором только одного конфига
-- 3. Улучшены размеры для мобильных устройств
-- 4. Оптимизирован UI для телефонов

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Адаптивные размеры
local WINDOW_SIZE = isMobile and UDim2.new(0, 360, 0, 500) or UDim2.new(0, 500, 0, 310)
local PADDING = isMobile and 6 or 8
local BUTTON_HEIGHT = isMobile and 32 or 28
local FONT_SIZE = isMobile and 14 or 13

local sg = Instance.new("ScreenGui")
sg.Name = "ModernHubV3"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = game.CoreGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = WINDOW_SIZE
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.ZIndex = 1
main.Parent = sg

local uic1 = Instance.new("UICorner")
uic1.CornerRadius = UDim.new(0, isMobile and 12 : 16)
uic1.Parent = main

local topbar = Instance.new("Frame")
topbar.Name = "TopBar"
topbar.Size = UDim2.new(1, 0, 0, isMobile and 40 : 36)
topbar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
topbar.BorderSizePixel = 0
topbar.ZIndex = 2
topbar.Parent = main

local uic2 = Instance.new("UICorner")
uic2.CornerRadius = UDim.new(0, isMobile and 12 : 16)
uic2.Parent = topbar

local cover = Instance.new("Frame")
cover.Name = "Cover"
cover.Size = UDim2.new(1, 0, 0, isMobile and 12 : 16)
cover.Position = UDim2.new(0, 0, 1, isMobile and -12 : -16)
cover.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
cover.BorderSizePixel = 0
cover.ZIndex = 2
cover.Parent = topbar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, isMobile and -80 : -70, 1, 0)
title.Position = UDim2.new(0, isMobile and 12 : 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Modern Hub"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = isMobile and 16 : 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = topbar

local minimize = Instance.new("TextButton")
minimize.Name = "Minimize"
minimize.Size = UDim2.new(0, isMobile and 34 : 30, 0, isMobile and 34 : 30)
minimize.Position = UDim2.new(1, isMobile and -70 : -60, 0.5, 0)
minimize.AnchorPoint = Vector2.new(0, 0.5)
minimize.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
minimize.BorderSizePixel = 0
minimize.Text = "−"
minimize.TextColor3 = Color3.fromRGB(200, 200, 210)
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = isMobile and 20 : 18
minimize.ZIndex = 10
minimize.Parent = topbar

local uic3 = Instance.new("UICorner")
uic3.CornerRadius = UDim.new(0, isMobile and 8 : 6)
uic3.Parent = minimize

local close = Instance.new("TextButton")
close.Name = "Close"
close.Size = UDim2.new(0, isMobile and 34 : 30, 0, isMobile and 34 : 30)
close.Position = UDim2.new(1, isMobile and -32 : -28, 0.5, 0)
close.AnchorPoint = Vector2.new(0, 0.5)
close.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
close.BorderSizePixel = 0
close.Text = "✕"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBold
close.TextSize = isMobile and 18 : 16
close.ZIndex = 10
close.Parent = topbar

local uic4 = Instance.new("UICorner")
uic4.CornerRadius = UDim.new(0, isMobile and 8 : 6)
uic4.Parent = close

local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(0, isMobile and 80 : 100, 1, isMobile and -46 : -42)
tabContainer.Position = UDim2.new(0, PADDING, 0, (isMobile and 40 : 36) + PADDING/2)
tabContainer.BackgroundTransparency = 1
tabContainer.ZIndex = 2
tabContainer.Parent = main

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, isMobile and -96 : -116, 1, isMobile and -52 : -50)
contentFrame.Position = UDim2.new(0, (isMobile and 80 : 100) + PADDING*2, 0, (isMobile and 40 : 36) + PADDING)
contentFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
contentFrame.BorderSizePixel = 0
contentFrame.ClipsDescendants = true
contentFrame.ZIndex = 2
contentFrame.Parent = main

local uic5 = Instance.new("UICorner")
uic5.CornerRadius = UDim.new(0, isMobile and 10 : 12)
uic5.Parent = contentFrame

local tabs = {}
local currentTab = nil
local toggleStates = {}
local toggleSetters = {}
local configList = {}

close.Activated:Connect(function()
    sg:Destroy()
end)

local minimized = false
minimize.Activated:Connect(function()
    minimized = not minimized
    local targetSize = minimized and UDim2.new(0, WINDOW_SIZE.X.Offset, 0, isMobile and 40 : 36) or WINDOW_SIZE
    TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = targetSize}):Play()
    minimize.Text = minimized and "+" or "−"
end)

local dragging, dragInput, startPos
topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        startPos = main.Position
        local startInputPos = input.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - (dragInput or input.Position)
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local library = {}

function library:CreateTab(name, icon)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name
    tabButton.Size = UDim2.new(1, 0, 0, isMobile and 42 : 38)
    tabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    tabButton.BorderSizePixel = 0
    tabButton.Text = ""
    tabButton.AutoButtonColor = false
    tabButton.ZIndex = 3
    tabButton.Parent = tabContainer

    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, isMobile and 8 : 10)
    uic.Parent = tabButton

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(1, 0, 0.5, 0)
    iconLabel.Position = UDim2.new(0, 0, 0, isMobile and 4 : 2)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon or "📋"
    iconLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.TextSize = isMobile and 18 : 16
    iconLabel.ZIndex = 4
    iconLabel.Parent = tabButton

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.5, isMobile and -2 : 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = isMobile and 11 : 9
    nameLabel.ZIndex = 4
    nameLabel.Parent = tabButton

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = name .. "Content"
    scrollFrame.Size = UDim2.new(1, -PADDING*2, 1, -PADDING*2)
    scrollFrame.Position = UDim2.new(0, PADDING, 0, PADDING)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = isMobile and 4 : 3
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 100)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Visible = false
    scrollFrame.ZIndex = 3
    scrollFrame.Parent = contentFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, PADDING)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + PADDING)
    end)

    tabs[name] = {button = tabButton, content = scrollFrame}

    local function selectTab()
        for _, t in pairs(tabs) do
            t.button.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
            t.button.Icon.TextColor3 = Color3.fromRGB(180, 180, 190)
            t.button.Name.TextColor3 = Color3.fromRGB(180, 180, 190)
            t.content.Visible = false
        end
        tabButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        scrollFrame.Visible = true
        currentTab = name
    end

    tabButton.Activated:Connect(selectTab)

    if not currentTab then
        selectTab()
    end

    local tabFuncs = {}

    function tabFuncs:AddToggle(opts)
        local key = opts.key or opts.text
        local state = opts.default or false
        toggleStates[key] = state

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT)
        holder.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        holder.BorderSizePixel = 0
        holder.ZIndex = 4
        holder.Parent = scrollFrame

        local uic = Instance.new("UICorner")
        uic.CornerRadius = UDim.new(0, isMobile and 7 : 8)
        uic.Parent = holder

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, isMobile and -50 : -60, 1, 0)
        label.Position = UDim2.new(0, isMobile and 8 : 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = opts.text
        label.TextColor3 = Color3.fromRGB(220, 220, 230)
        label.Font = Enum.Font.Gotham
        label.TextSize = FONT_SIZE
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = holder

        local switch = Instance.new("Frame")
        switch.Name = "Switch"
        switch.Size = UDim2.new(0, isMobile and 42 : 38, 0, isMobile and 20 : 18)
        switch.Position = UDim2.new(1, isMobile and -46 : -42, 0.5, 0)
        switch.AnchorPoint = Vector2.new(0, 0.5)
        switch.BackgroundColor3 = state and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(50, 50, 58)
        switch.BorderSizePixel = 0
        switch.ZIndex = 5
        switch.Parent = holder

        local uic2 = Instance.new("UICorner")
        uic2.CornerRadius = UDim.new(1, 0)
        uic2.Parent = switch

        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.Size = UDim2.new(0, isMobile and 14 : 12, 0, isMobile and 14 : 12)
        knob.Position = state and UDim2.new(1, isMobile and -17 : -15, 0.5, 0) or UDim2.new(0, isMobile and 3 : 3, 0.5, 0)
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 6
        knob.Parent = switch

        local uic3 = Instance.new("UICorner")
        uic3.CornerRadius = UDim.new(1, 0)
        uic3.Parent = knob

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 7
        btn.Parent = holder

        local function toggle()
            state = not state
            toggleStates[key] = state
            TweenService:Create(switch, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = state and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(50, 50, 58)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Position = state and UDim2.new(1, isMobile and -17 : -15, 0.5, 0) or UDim2.new(0, isMobile and 3 : 3, 0.5, 0)
            }):Play()
            if opts.callback then
                opts.callback(state)
            end
        end

        btn.Activated:Connect(toggle)

        toggleSetters[key] = function(val)
            if val ~= state then
                toggle()
            end
        end

        return {
            SetValue = function(_, val)
                if val ~= state then
                    toggle()
                end
            end
        }
    end

    function tabFuncs:AddButton(opts)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT)
        holder.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        holder.BorderSizePixel = 0
        holder.ZIndex = 4
        holder.Parent = scrollFrame

        local uic = Instance.new("UICorner")
        uic.CornerRadius = UDim.new(0, isMobile and 7 : 8)
        uic.Parent = holder

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = opts.text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = FONT_SIZE
        btn.ZIndex = 5
        btn.Parent = holder

        btn.Activated:Connect(function()
            TweenService:Create(holder, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(78, 91, 222)}):Play()
            wait(0.1)
            TweenService:Create(holder, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
            if opts.callback then
                opts.callback()
            end
        end)
    end

    function tabFuncs:AddLabel(text)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT - (isMobile and 6 : 8))
        holder.BackgroundTransparency = 1
        holder.ZIndex = 4
        holder.Parent = scrollFrame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(160, 160, 170)
        label.Font = Enum.Font.Gotham
        label.TextSize = FONT_SIZE - 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = holder

        return {
            SetText = function(_, txt)
                label.Text = txt
            end
        }
    end

    return tabFuncs
end

-- TAB КОНФИГОВ С ФИКСАМИ
local settingsTab = library:CreateTab("Settings", "⚙️")

settingsTab:AddLabel("「 Config Manager 」")

local configInput
local configDropdown
local configListFrame
local selectedConfig = nil

-- Input для имени конфига
local inputHolder = Instance.new("Frame")
inputHolder.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT)
inputHolder.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
inputHolder.BorderSizePixel = 0
inputHolder.ZIndex = 4
inputHolder.Parent = settingsTab.content or contentFrame:FindFirstChild("SettingsContent")

local uicInput = Instance.new("UICorner")
uicInput.CornerRadius = UDim.new(0, isMobile and 7 : 8)
uicInput.Parent = inputHolder

configInput = Instance.new("TextBox")
configInput.Size = UDim2.new(1, isMobile and -16 : -20, 1, 0)
configInput.Position = UDim2.new(0, isMobile and 8 : 10, 0, 0)
configInput.BackgroundTransparency = 1
configInput.PlaceholderText = "Config Name..."
configInput.Text = ""
configInput.TextColor3 = Color3.fromRGB(220, 220, 230)
configInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
configInput.Font = Enum.Font.Gotham
configInput.TextSize = FONT_SIZE
configInput.TextXAlignment = Enum.TextXAlignment.Left
configInput.ClearTextOnFocus = false
configInput.ZIndex = 5
configInput.Parent = inputHolder

-- Create Config Button
settingsTab:AddButton({
    text = "➕ Create Config",
    callback = function()
        local cfgName = configInput.Text
        if cfgName ~= "" then
            local snapshot = {}
            for k, v in pairs(toggleStates) do
                snapshot[k] = v
            end
            configList[cfgName] = snapshot
                        configInput.Text = ""
            print("✅ Config created:", cfgName)
            updateConfigList()
        else
            warn("❌ Please enter a config name!")
        end
    end
})

-- Dropdown для списка конфигов
local dropdownHolder = Instance.new("Frame")
dropdownHolder.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT)
dropdownHolder.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
dropdownHolder.BorderSizePixel = 0
dropdownHolder.ZIndex = 4
dropdownHolder.ClipsDescendants = false
dropdownHolder.Parent = settingsTab.content or contentFrame:FindFirstChild("SettingsContent")

local uicDrop = Instance.new("UICorner")
uicDrop.CornerRadius = UDim.new(0, isMobile and 7 : 8)
uicDrop.Parent = dropdownHolder

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1, 0, 1, 0)
dropdownBtn.BackgroundTransparency = 1
dropdownBtn.Text = ""
dropdownBtn.ZIndex = 5
dropdownBtn.Parent = dropdownHolder

local dropdownLabel = Instance.new("TextLabel")
dropdownLabel.Size = UDim2.new(1, isMobile and -50 : -60, 1, 0)
dropdownLabel.Position = UDim2.new(0, isMobile and 8 : 10, 0, 0)
dropdownLabel.BackgroundTransparency = 1
dropdownLabel.Text = selectedConfig or "Select Config..."
dropdownLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
dropdownLabel.Font = Enum.Font.Gotham
dropdownLabel.TextSize = FONT_SIZE
dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
dropdownLabel.ZIndex = 6
dropdownLabel.Parent = dropdownHolder

local dropdownArrow = Instance.new("TextLabel")
dropdownArrow.Size = UDim2.new(0, isMobile and 20 : 20, 1, 0)
dropdownArrow.Position = UDim2.new(1, isMobile and -28 : -30, 0, 0)
dropdownArrow.BackgroundTransparency = 1
dropdownArrow.Text = "▼"
dropdownArrow.TextColor3 = Color3.fromRGB(180, 180, 190)
dropdownArrow.Font = Enum.Font.Gotham
dropdownArrow.TextSize = isMobile and 12 : 10
dropdownArrow.ZIndex = 6
dropdownArrow.Parent = dropdownHolder

-- Список конфигов (выпадающий)
configListFrame = Instance.new("ScrollingFrame")
configListFrame.Name = "ConfigList"
configListFrame.Size = UDim2.new(1, 0, 0, 0)
configListFrame.Position = UDim2.new(0, 0, 1, PADDING/2)
configListFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
configListFrame.BorderSizePixel = 0
configListFrame.ScrollBarThickness = isMobile and 3 : 2
configListFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 100)
configListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
configListFrame.Visible = false
configListFrame.ClipsDescendants = true
configListFrame.ZIndex = 15
configListFrame.Parent = dropdownHolder

local uicList = Instance.new("UICorner")
uicList.CornerRadius = UDim.new(0, isMobile and 7 : 8)
uicList.Parent = configListFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, PADDING/2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = configListFrame

local dropdownOpen = false

dropdownBtn.Activated:Connect(function()
    dropdownOpen = not dropdownOpen
    local targetSize = dropdownOpen and UDim2.new(1, 0, 0, math.min(150, #configList * (BUTTON_HEIGHT + PADDING/2) + PADDING)) or UDim2.new(1, 0, 0, 0)
    
    configListFrame.Visible = true
    TweenService:Create(configListFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = targetSize}):Play()
    TweenService:Create(dropdownArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Rotation = dropdownOpen and 180 or 0}):Play()
    
    if not dropdownOpen then
        wait(0.2)
        configListFrame.Visible = false
    end
end)

function updateConfigList()
    for _, child in ipairs(configListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local count = 0
    for cfgName, _ in pairs(configList) do
        count = count + 1
        
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -PADDING, 0, BUTTON_HEIGHT - 4)
        itemFrame.BackgroundColor3 = (selectedConfig == cfgName) and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(30, 30, 38)
        itemFrame.BorderSizePixel = 0
        itemFrame.ZIndex = 16
        itemFrame.Parent = configListFrame
        
        local uicItem = Instance.new("UICorner")
        uicItem.CornerRadius = UDim.new(0, isMobile and 6 : 7)
        uicItem.Parent = itemFrame
        
        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(1, isMobile and -36 : -40, 1, 0)
        itemBtn.BackgroundTransparency = 1
        itemBtn.Text = cfgName
        itemBtn.TextColor3 = (selectedConfig == cfgName) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210)
        itemBtn.Font = Enum.Font.Gotham
        itemBtn.TextSize = FONT_SIZE - 1
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.TextTruncate = Enum.TextTruncate.AtEnd
        itemBtn.ZIndex = 17
        itemBtn.Parent = itemFrame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, isMobile and 6 : 8)
        padding.Parent = itemBtn
        
        -- Кнопка Delete
        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Size = UDim2.new(0, isMobile and 28 : 32, 0, isMobile and 20 : 22)
        deleteBtn.Position = UDim2.new(1, isMobile and -30 : -34, 0.5, 0)
        deleteBtn.AnchorPoint = Vector2.new(0, 0.5)
        deleteBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
        deleteBtn.BorderSizePixel = 0
        deleteBtn.Text = "🗑"
        deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteBtn.Font = Enum.Font.Gotham
        deleteBtn.TextSize = isMobile and 14 : 12
        deleteBtn.ZIndex = 18
        deleteBtn.Parent = itemFrame
        
        local uicDelete = Instance.new("UICorner")
        uicDelete.CornerRadius = UDim.new(0, isMobile and 5 : 6)
        uicDelete.Parent = deleteBtn
        
        -- Выбор конфига
        itemBtn.Activated:Connect(function()
            -- Сброс предыдущего выбора
            for _, otherItem in ipairs(configListFrame:GetChildren()) do
                if otherItem:IsA("Frame") and otherItem ~= itemFrame then
                    otherItem.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
                    local btn = otherItem:FindFirstChildOfClass("TextButton")
                    if btn then
                        btn.TextColor3 = Color3.fromRGB(200, 200, 210)
                    end
                end
            end
            
            -- Выбор нового
            selectedConfig = cfgName
            itemFrame.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            dropdownLabel.Text = cfgName
            dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            -- Закрыть dropdown
            dropdownOpen = false
            TweenService:Create(configListFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 0)}):Play()
            TweenService:Create(dropdownArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Rotation = 0}):Play()
            wait(0.2)
            configListFrame.Visible = false
        end)
        
        -- Удаление конфига
        deleteBtn.Activated:Connect(function()
            configList[cfgName] = nil
            if selectedConfig == cfgName then
                selectedConfig = nil
                dropdownLabel.Text = "Select Config..."
                dropdownLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
            end
            updateConfigList()
            print("🗑 Config deleted:", cfgName)
        end)
    end
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        configListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + PADDING)
    end)
    
    if dropdownOpen then
        local targetSize = UDim2.new(1, 0, 0, math.min(150, count * (BUTTON_HEIGHT + PADDING/2) + PADDING))
        configListFrame.Size = targetSize
    end
end

-- Load Config Button
settingsTab:AddButton({
    text = "📥 Load Config",
    callback = function()
        if selectedConfig and configList[selectedConfig] then
            local cfg = configList[selectedConfig]
            for key, value in pairs(cfg) do
                if toggleSetters[key] then
                    toggleSetters[key](value)
                end
            end
            print("✅ Config loaded:", selectedConfig)
        else
            warn("❌ Please select a config first!")
        end
    end
})

-- Delete Config Button (альтернативный способ)
settingsTab:AddButton({
    text = "🗑 Delete Selected Config",
    callback = function()
        if selectedConfig then
            configList[selectedConfig] = nil
            print("🗑 Config deleted:", selectedConfig)
            selectedConfig = nil
            dropdownLabel.Text = "Select Config..."
            dropdownLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
            updateConfigList()
        else
            warn("❌ No config selected!")
        end
    end
})

settingsTab:AddLabel("━━━━━━━━━━━━━━")

-- Пример табов
local mainTab = library:CreateTab("Main", "🏠")
mainTab:AddLabel("「 Features 」")

mainTab:AddToggle({
    key = "feature1",
    text = "Feature 1",
    default = false,
    callback = function(val)
        print("Feature 1:", val)
    end
})

mainTab:AddToggle({
    key = "feature2",
    text = "Feature 2",
    default = false,
    callback = function(val)
        print("Feature 2:", val)
    end
})

mainTab:AddToggle({
    key = "autoFarm",
    text = "Auto Farm",
    default = false,
    callback = function(val)
        print("Auto Farm:", val)
    end
})

local combatTab = library:CreateTab("Combat", "⚔️")
combatTab:AddLabel("「 Combat Settings 」")

combatTab:AddToggle({
    key = "aimbot",
    text = "Aimbot",
    default = false,
    callback = function(val)
        print("Aimbot:", val)
    end
})

combatTab:AddToggle({
    key = "esp",
    text = "ESP",
    default = false,
    callback = function(val)
        print("ESP:", val)
    end
})

return library
