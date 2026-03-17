-- ==========================================
-- MACRO LOGIC для Garden Tower Defense
-- ==========================================

local MacroSystem = {}
MacroSystem.__index = MacroSystem

-- Сервисы
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ==========================================
-- НАСТРОЙКИ
-- ==========================================
local SETTINGS = {
    -- Античит: случайное смещение позиций
    randomOffset = true,
    offsetRange = 2.5, -- Радиус смещения в studs
    
    -- Задержки
    actionDelay = 0.1, -- Задержка между действиями
    upgradeDelay = 0.3, -- Задержка после улучшения
    
    -- Отладка
    debug = true
}

-- ==========================================
-- ДАННЫЕ МАКРОСА
-- ==========================================
local currentMacro = {
    name = "",
    actions = {},
    startTime = 0,
    unitCounter = 0
}

local isRecording = false
local isPlaying = false
local isPaused = false
local recordingConnections = {}
local playbackCoroutine = nil

-- Временное хранилище юнитов
local placedUnits = {} -- [ID] = unitInstance
local selectedUnit = nil
local currentUnitType = nil

-- ==========================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ==========================================

-- Преобразовать CFrame в строку
local function CFtoString(cf)
    local components = {cf:GetComponents()}
    return table.concat(components, ", ")
end

-- Преобразовать строку в CFrame
local function StringToCF(str)
    local components = {}
    for num in string.gmatch(str, "[^,]+") do
        table.insert(components, tonumber(num))
    end
    return CFrame.new(unpack(components))
end

-- Преобразовать Vector3 в строку
local function Vec3ToString(vec)
    return string.format("%s, %s, %s", vec.X, vec.Y, vec.Z)
end

-- Применить случайное смещение
local function ApplyRandomOffset(position)
    if not SETTINGS.randomOffset then
        return position
    end
    
    local angle = math.random() * math.pi * 2
    local distance = math.random() * SETTINGS.offsetRange
    
    local offsetX = math.cos(angle) * distance
    local offsetZ = math.sin(angle) * distance
    
    return Vector3.new(
        position.X + offsetX,
        position.Y,
        position.Z + offsetZ
    )
end

-- Логирование
local function Log(message, isError)
    if SETTINGS.debug then
        if isError then
            warn("❌ [MACRO]", message)
        else
            print("✅ [MACRO]", message)
        end
    end
end

-- ==========================================
-- СИСТЕМА ЗАПИСИ
-- ==========================================

-- Начать запись
function MacroSystem:StartRecording(macroName)
    if isRecording then
        Log("Запись уже идёт!", true)
        return false
    end
    
    currentMacro = {
        name = macroName,
        actions = {},
        startTime = tick(),
        unitCounter = 0
    }
    
    placedUnits = {}
    isRecording = true
    
    Log("🔴 ЗАПИСЬ НАЧАТА: " .. macroName)
    
    -- Подключаем отслеживание
    self:ConnectRecordingEvents()
    
    return true
end

-- Остановить запись
function MacroSystem:StopRecording()
    if not isRecording then
        Log("Запись не идёт!", true)
        return nil
    end
    
    isRecording = false
    
    -- Отключаем все события
    for _, connection in pairs(recordingConnections) do
        connection:Disconnect()
    end
    recordingConnections = {}
    
    Log("⏹️ ЗАПИСЬ ОСТАНОВЛЕНА")
    Log("📊 Записано действий: " .. #currentMacro.actions)
    
    return currentMacro
end

-- Подключить события записи
function MacroSystem:ConnectRecordingEvents()
    -- Отслеживание размещения юнитов
    local placeConnection = ReplicatedStorage.Remotes.Towers.Place.OnClientEvent:Connect(function(...)
        if isRecording then
            self:RecordPlaceUnit(...)
        end
    end)
    table.insert(recordingConnections, placeConnection)
    
    -- Отслеживание улучшений
    local upgradeConnection = ReplicatedStorage.Remotes.Towers.Upgrade.OnClientEvent:Connect(function(...)
        if isRecording then
            self:RecordUpgradeUnit(...)
        end
    end)
    table.insert(recordingConnections, upgradeConnection)
    
    -- Отслеживание кликов для выбора юнита
    local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not isRecording or gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local target = mouse.Target
            if target then
                -- Проверяем, кликнули ли по юниту
                local unit = target:FindFirstAncestorOfClass("Model")
                if unit and unit:FindFirstChild("HumanoidRootPart") then
                    selectedUnit = unit
                end
            end
        end
    end)
    table.insert(recordingConnections, inputConnection)
end

-- Записать размещение юнита
function MacroSystem:RecordPlaceUnit(unitType, position, rotation, pathIndex)
    currentMacro.unitCounter = currentMacro.unitCounter + 1
    local unitID = currentMacro.unitCounter
    
    local timeSinceStart = tick() - currentMacro.startTime
    
    local action = {
        Type = "PlaceUnit",
        Time = math.floor(timeSinceStart),
        ID = unitID,
        Unit = unitType,
        Position = Vec3ToString(position),
        CF = CFtoString(CFrame.new(position) * rotation)
    }
    
    if pathIndex then
        action.PathIndex = pathIndex
    end
    
    table.insert(currentMacro.actions, action)
    
    -- Сохраняем для отслеживания улучшений
    task.wait(0.5) -- Ждём создания юнита
    placedUnits[unitID] = selectedUnit
    
    Log(string.format("🏗️ [%.1fs] Размещён: %s (ID: %d)", timeSinceStart, unitType, unitID))
end

-- Записать улучшение юнита
function MacroSystem:RecordUpgradeUnit(unitInstance, price)
    if not selectedUnit then return end
    
    -- Находим ID юнита
    local unitID = nil
    for id, unit in pairs(placedUnits) do
        if unit == unitInstance or unit == selectedUnit then
            unitID = id
            break
        end
    end
    
    if not unitID then
        Log("Не найден ID юнита для улучшения", true)
        return
    end
    
    local action = {
        Type = "UpgradeUnit",
        ID = unitID,
        Price = price or 0
    }
    
    table.insert(currentMacro.actions, action)
    
    Log(string.format("⬆️ Улучшение юнита ID:%d (Цена: %d)", unitID, price or 0))
end

-- ==========================================
-- СИСТЕМА ВОСПРОИЗВЕДЕНИЯ
-- ==========================================

-- Запустить воспроизведение
function MacroSystem:StartPlayback(macro, loopMode)
    if isPlaying then
        Log("Воспроизведение уже идёт!", true)
        return false
    end
    
    if not macro or not macro.actions or #macro.actions == 0 then
        Log("Макрос пустой!", true)
        return false
    end
    
    isPlaying = true
    isPaused = false
    placedUnits = {}
    
    Log("▶️ ВОСПРОИЗВЕДЕНИЕ: " .. macro.name)
    Log("📊 Действий: " .. #macro.actions)
    
    playbackCoroutine = coroutine.create(function()
        repeat
            self:ExecuteMacro(macro)
            
            if loopMode and isPlaying then
                Log("🔁 Повторяю макрос...")
                task.wait(3)
            end
        until not loopMode or not isPlaying
        
        isPlaying = false
        Log("⏹️ ВОСПРОИЗВЕДЕНИЕ ЗАВЕРШЕНО")
    end)
    
    coroutine.resume(playbackCoroutine)
    
    return true
end

-- Остановить воспроизведение
function MacroSystem:StopPlayback()
    if not isPlaying then
        Log("Воспроизведение не идёт!", true)
        return false
    end
    
    isPlaying = false
    isPaused = false
    
    if playbackCoroutine then
        playbackCoroutine = nil
    end
    
    placedUnits = {}
    
    Log("⏹️ ВОСПРОИЗВЕДЕНИЕ ОСТАНОВЛЕНО")
    return true
end

-- Пауза/Возобновление
function MacroSystem:TogglePause()
    isPaused = not isPaused
    Log(isPaused and "⏸️ ПАУЗА" or "▶️ ПРОДОЛЖЕНИЕ")
    return isPaused
end

-- Выполнить макрос
function MacroSystem:ExecuteMacro(macro)
    local startTime = tick()
    local lastActionTime = 0
    
    for i, action in ipairs(macro.actions) do
        -- Проверка на остановку
        if not isPlaying then
            Log("Остановлено пользователем")
            break
        end
        
        -- Пауза
        while isPaused and isPlaying do
            task.wait(0.1)
        end
        
        -- Ждём до нужного времени
        if action.Time then
            local targetTime = startTime + action.Time
            local currentTime = tick()
            
            if currentTime < targetTime then
                task.wait(targetTime - currentTime)
            end
        else
            -- Минимальная задержка между действиями
            task.wait(SETTINGS.actionDelay)
        end
        
        -- Выполняем действие
        local success, err = pcall(function()
            self:ExecuteAction(action)
        end)
        
        if not success then
            Log(string.format("Ошибка выполнения действия %d: %s", i, err), true)
        end
        
        Log(string.format("▶️ [%d/%d] %s", i, #macro.actions, action.Type))
        
        lastActionTime = tick()
    end
end

-- Выполнить действие
function MacroSystem:ExecuteAction(action)
    if action.Type == "PlaceUnit" then
        self:PlaceTower(action)
        
    elseif action.Type == "UpgradeUnit" then
        self:UpgradeTower(action)
        
    elseif action.Type == "SellUnit" then
        self:SellTower(action)
    end
end

-- ==========================================
-- ИГРОВЫЕ ДЕЙСТВИЯ
-- ==========================================

-- Поставить башню
function MacroSystem:PlaceTower(action)
    -- Парсим позицию
    local posX, posY, posZ = action.Position:match("([^,]+), ([^,]+), ([^,]+)")
    local position = Vector3.new(tonumber(posX), tonumber(posY), tonumber(posZ))
    
    -- Применяем смещение
    position = ApplyRandomOffset(position)
    
    -- Парсим CFrame (если нужно)
    local cf = StringToCF(action.CF)
    
    Log(string.format("🏗️ Размещаю: %s на позиции %s", action.Unit, Vec3ToString(position)))
    
    -- Вызываем Remote для размещения
    local success, result = pcall(function()
        -- АДАПТИРУЙ ПОД СВОЮ ИГРУ!
        -- Пример вызова:
        ReplicatedStorage.Remotes.Towers.Place:FireServer(
            action.Unit,
            position,
            action.PathIndex or nil
        )
    end)
    
    if success then
        -- Ждём создания юнита
        task.wait(0.5)
        
        -- Находим созданный юнит и сохраняем
        -- АДАПТИРУЙ: логика поиска созданного юнита
        local workspace = game:GetService("Workspace")
        local towers = workspace:FindFirstChild("Towers") or workspace
        
        -- Ищем ближайший юнит к позиции
        local closestUnit = nil
        local closestDistance = math.huge
        
        for _, obj in pairs(towers:GetChildren()) do
            if obj:IsA("Model") and obj.PrimaryPart then
                local distance = (obj.PrimaryPart.Position - position).Magnitude
                if distance < closestDistance and distance < 10 then
                    closestDistance = distance
                    closestUnit = obj
                end
            end
        end
        
        if closestUnit then
            placedUnits[action.ID] = closestUnit
            Log("✅ Юнит сохранён с ID: " .. action.ID)
        else
            Log("⚠️ Не удалось найти созданный юнит", true)
        end
    else
        Log("❌ Ошибка размещения: " .. tostring(result), true)
    end
end

-- Улучшить башню
function MacroSystem:UpgradeTower(action)
    local unit = placedUnits[action.ID]
    
    if not unit or not unit.Parent then
        Log(string.format("❌ Юнит ID:%d не найден!", action.ID), true)
        return
    end
    
    Log(string.format("⬆️ Улучшаю юнит ID:%d", action.ID))
    
    -- Вызываем Remote для улучшения
    local success, err = pcall(function()
        -- АДАПТИРУЙ ПОД СВОЮ ИГРУ!
        ReplicatedStorage.Remotes.Towers.Upgrade:FireServer(unit)
    end)
    
    if not success then
        Log("❌ Ошибка улучшения: " .. tostring(err), true)
    end
    
    task.wait(SETTINGS.upgradeDelay)
end

-- Продать башню
function MacroSystem:SellTower(action)
    local unit = placedUnits[action.ID]
    
    if not unit or not unit.Parent then
        Log(string.format("❌ Юнит ID:%d не найден!", action.ID), true)
        return
    end
    
    Log(string.format("💰 Продаю юнит ID:%d", action.ID))
    
    -- АДАПТИРУЙ ПОД СВОЮ ИГРУ!
    ReplicatedStorage.Remotes.Towers.Sell:FireServer(unit)
    
    placedUnits[action.ID] = nil
end

-- ==========================================
-- СОХРАНЕНИЕ И ЗАГРУЗКА
-- ==========================================

-- Сохранить макрос
function MacroSystem:SaveMacro(macro)
    local success, result = pcall(function()
        if not writefile then
            error("writefile не поддерживается")
        end
        
        local filename = "zeexhub_macro_" .. macro.name:gsub("[^%w_]", "_") .. ".json"
        local jsonData = HttpService:JSONEncode(macro.actions)
        
        writefile(filename, jsonData)
        Log("💾 Макрос сохранён: " .. filename)
        
        return true
    end)
    
    if not success then
        Log("❌ Ошибка сохранения: " .. tostring(result), true)
        return false
    end
    
    return true
end

-- Загрузить макрос
function MacroSystem:LoadMacro(macroName)
    local success, result = pcall(function()
        if not readfile or not isfile then
            error("readfile не поддерживается")
        end
        
        local filename = "zeexhub_macro_" .. macroName:gsub("[^%w_]", "_") .. ".json"
        
        if not isfile(filename) then
            error("Файл не найден: " .. filename)
        end
        
        local jsonData = readfile(filename)
        local actions = HttpService:JSONDecode(jsonData)
        
        local macro = {
            name = macroName,
            actions = actions
        }
        
        Log("📂 Макрос загружен: " .. macroName .. " (" .. #actions .. " действий)")
        return macro
    end)
    
    if not success then
        Log("❌ Ошибка загрузки: " .. tostring(result), true)
        return nil
    end
    
    return result
end

-- ==========================================
-- ЭКСПОРТ
-- ==========================================

return MacroSystem
