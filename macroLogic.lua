-- ==========================================
-- MACRO SYSTEM для ZeexHub
-- Garden Tower Defense
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

-- ==========================================
-- REMOTE'Ы ИГРЫ
-- ==========================================
local Remotes = {
    PlaceUnit = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("PlaceUnit"),
    UpgradeUnit = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("UpgradeUnit"),
    SellUnit = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("SellUnit"),
}

-- ==========================================
-- НАСТРОЙКИ
-- ==========================================
local SETTINGS = {
    randomOffset = true,
    offsetRange = 2.5,
    actionDelay = 0.1,
    upgradeDelay = 0.3,
    debug = true
}

-- ==========================================
-- ДАННЫЕ
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
local placedUnits = {}
local savedMacros = {}

-- ==========================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ==========================================

local function Vec3ToString(vec)
    return string.format("%.2f,%.2f,%.2f", vec.X, vec.Y, vec.Z)
end

local function StringToVec3(str)
    local x, y, z = str:match("([^,]+),([^,]+),([^,]+)")
    return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

local function ApplyRandomOffset(position)
    if not SETTINGS.randomOffset then return position end
    
    local angle = math.random() * math.pi * 2
    local distance = math.random() * SETTINGS.offsetRange
    
    return Vector3.new(
        position.X + math.cos(angle) * distance,
        position.Y,
        position.Z + math.sin(angle) * distance
    )
end

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
-- ЗАПИСЬ МАКРОСОВ
-- ==========================================

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
    self:HookRemotes()
    
    return true
end

function MacroSystem:StopRecording()
    if not isRecording then
        Log("Запись не идёт!", true)
        return nil
    end
    
    isRecording = false
    
    Log("⏹️ ЗАПИСЬ ОСТАНОВЛЕНА")
    Log("📊 Записано действий: " .. #currentMacro.actions)
    
    return currentMacro
end

function MacroSystem:HookRemotes()
    -- Хук на размещение юнита
    if not getgenv().OriginalPlaceUnit then
        getgenv().OriginalPlaceUnit = Remotes.PlaceUnit.InvokeServer
        
        Remotes.PlaceUnit.InvokeServer = function(self, unitName, position, ...)
            if isRecording then
                MacroSystem:RecordPlaceUnit(unitName, position)
            end
            return getgenv().OriginalPlaceUnit(self, unitName, position, ...)
        end
    end
    
    -- Хук на улучшение юнита
    if not getgenv().OriginalUpgradeUnit then
        getgenv().OriginalUpgradeUnit = Remotes.UpgradeUnit.InvokeServer
        
        Remotes.UpgradeUnit.InvokeServer = function(self, unitInstance, ...)
            if isRecording then
                MacroSystem:RecordUpgradeUnit(unitInstance)
            end
            return getgenv().OriginalUpgradeUnit(self, unitInstance, ...)
        end
    end
    
    Log("🔗 Хуки установлены")
end

function MacroSystem:RecordPlaceUnit(unitName, position)
    currentMacro.unitCounter = currentMacro.unitCounter + 1
    local unitID = currentMacro.unitCounter
    local timeSinceStart = math.floor((tick() - currentMacro.startTime) * 10) / 10
    
    local action = {
        Type = "PlaceUnit",
        Time = timeSinceStart,
        ID = unitID,
        Unit = unitName,
        Position = Vec3ToString(position)
    }
    
    table.insert(currentMacro.actions, action)
    
    -- Находим юнит в workspace
    task.wait(0.3)
    
    local workspace = game:GetService("Workspace")
    local unitsFolder = workspace:FindFirstChild("Units")
    
    if unitsFolder then
        for _, unit in pairs(unitsFolder:GetChildren()) do
            if unit:IsA("Model") and unit.PrimaryPart then
                local distance = (unit.PrimaryPart.Position - position).Magnitude
                if distance < 5 then
                    placedUnits[unitID] = unit
                    Log(string.format("🏗️ [%.1fs] %s (ID:%d)", timeSinceStart, unitName, unitID))
                    break
                end
            end
        end
    end
end

function MacroSystem:RecordUpgradeUnit(unitInstance)
    local unitID = nil
    
    for id, unit in pairs(placedUnits) do
        if unit == unitInstance then
            unitID = id
            break
        end
    end
    
    if not unitID then
        Log("⚠️ Юнит для улучшения не найден", true)
        return
    end
    
    local timeSinceStart = math.floor((tick() - currentMacro.startTime) * 10) / 10
    
    local action = {
        Type = "UpgradeUnit",
        Time = timeSinceStart,
        ID = unitID
    }
    
    table.insert(currentMacro.actions, action)
    Log(string.format("⬆️ [%.1fs] Улучшение ID:%d", timeSinceStart, unitID))
end

-- ==========================================
-- ВОСПРОИЗВЕДЕНИЕ МАКРОСОВ
-- ==========================================

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
    
    task.spawn(function()
        repeat
            self:ExecuteMacro(macro)
            if loopMode and isPlaying then
                Log("🔁 Повторяю макрос...")
                task.wait(2)
            end
        until not loopMode or not isPlaying
        
        isPlaying = false
        Log("⏹️ ЗАВЕРШЕНО")
    end)
    
    return true
end

function MacroSystem:StopPlayback()
    isPlaying = false
    isPaused = false
    placedUnits = {}
    Log("⏹️ ОСТАНОВЛЕНО")
    return true
end

function MacroSystem:TogglePause()
    isPaused = not isPaused
    Log(isPaused and "⏸️ ПАУЗА" or "▶️ ПРОДОЛЖЕНИЕ")
    return isPaused
end

function MacroSystem:ExecuteMacro(macro)
    local startTime = tick()
    
    for i, action in ipairs(macro.actions) do
        if not isPlaying then break end
        
        -- Ожидание паузы
        while isPaused and isPlaying do
            task.wait(0.1)
        end
        
        -- Ожидание нужного времени
        if action.Time then
            local targetTime = startTime + action.Time
            local currentTime = tick()
            if currentTime < targetTime then
                task.wait(targetTime - currentTime)
            end
        end
        
        -- Выполнение действия
        local success, err = pcall(function()
            self:ExecuteAction(action)
        end)
        
        if not success then
            Log(string.format("❌ Ошибка на шаге %d: %s", i, err), true)
        end
        
        task.wait(SETTINGS.actionDelay)
    end
end

function MacroSystem:ExecuteAction(action)
    if action.Type == "PlaceUnit" then
        self:PlaceTower(action)
    elseif action.Type == "UpgradeUnit" then
        self:UpgradeTower(action)
    end
end

function MacroSystem:PlaceTower(action)
    local position = StringToVec3(action.Position)
    position = ApplyRandomOffset(position)
    
    Log(string.format("🏗️ Размещаю: %s (ID:%d)", action.Unit, action.ID))
    
    local success, result = pcall(function()
        return Remotes.PlaceUnit:InvokeServer(action.Unit, position)
    end)
    
    if not success then
        Log("❌ Ошибка размещения: " .. tostring(result), true)
        return
    end
    
    task.wait(0.3)
    
    -- Находим размещённый юнит
    local workspace = game:GetService("Workspace")
    local unitsFolder = workspace:FindFirstChild("Units")
    
    if unitsFolder then
        for _, unit in pairs(unitsFolder:GetChildren()) do
            if unit:IsA("Model") and unit.PrimaryPart then
                local distance = (unit.PrimaryPart.Position - position).Magnitude
                if distance < 10 then
                    placedUnits[action.ID] = unit
                    Log("✅ Размещён ID:" .. action.ID)
                    break
                end
            end
        end
    end
end

function MacroSystem:UpgradeTower(action)
    local unit = placedUnits[action.ID]
    
    if not unit or not unit.Parent then
        Log(string.format("❌ Юнит ID:%d не найден!", action.ID), true)
        return
    end
    
    Log(string.format("⬆️ Улучшаю ID:%d", action.ID))
    
    local success, result = pcall(function()
        return Remotes.UpgradeUnit:InvokeServer(unit)
    end)
    
    if not success then
        Log("❌ Ошибка улучшения: " .. tostring(result), true)
    end
    
    task.wait(SETTINGS.upgradeDelay)
end

-- ==========================================
-- СОХРАНЕНИЕ И ЗАГРУЗКА
-- ==========================================

function MacroSystem:SaveMacro(macro)
    table.insert(savedMacros, macro)
    
    pcall(function()
        if writefile then
            local filename = "zeexhub_macro_" .. macro.name:gsub("[^%w_]", "_") .. ".json"
            local data = HttpService:JSONEncode({
                name = macro.name,
                actions = macro.actions
            })
            writefile(filename, data)
            Log("💾 Сохранён в файл: " .. filename)
        end
    end)
    
    return true
end

function MacroSystem:LoadMacro(macroName)
    -- Проверяем в памяти
    for _, macro in ipairs(savedMacros) do
        if macro.name == macroName then
            Log("📂 Загружен из памяти: " .. macroName)
            return macro
        end
    end
    
    -- Пробуем загрузить из файла
    local success, result = pcall(function()
        if not readfile or not isfile then
            error("readfile не поддерживается")
        end
        
        local filename = "zeexhub_macro_" .. macroName:gsub("[^%w_]", "_") .. ".json"
        
        if not isfile(filename) then
            error("Файл не найден")
        end
        
        local data = readfile(filename)
        local macro = HttpService:JSONDecode(data)
        
        table.insert(savedMacros, macro)
        return macro
    end)
    
    if success then
        Log("📂 Загружен из файла: " .. macroName)
        return result
    else
        Log("❌ Ошибка загрузки: " .. tostring(result), true)
        return nil
    end
end

function MacroSystem:GetAllMacros()
    return savedMacros
end

function MacroSystem:DeleteMacro(macroName)
    for i, macro in ipairs(savedMacros) do
        if macro.name == macroName then
            table.remove(savedMacros, i)
            
            pcall(function()
                if delfile and isfile then
                    local filename = "zeexhub_macro_" .. macroName:gsub("[^%w_]", "_") .. ".json"
                    if isfile(filename) then
                        delfile(filename)
                    end
                end
            end)
            
            Log("🗑️ Удалён: " .. macroName)
            return true
        end
    end
    
    return false
end

-- ==========================================
-- ГЕТТЕРЫ
-- ==========================================

function MacroSystem:IsRecording()
    return isRecording
end

function MacroSystem:IsPlaying()
    return isPlaying
end

function MacroSystem:IsPaused()
    return isPaused
end

function MacroSystem:GetCurrentMacro()
    return currentMacro
end

-- ==========================================
-- ИНИЦИАЛИЗАЦИЯ
-- ==========================================

Log("⚡ MacroSystem загружен")

return MacroSystem
