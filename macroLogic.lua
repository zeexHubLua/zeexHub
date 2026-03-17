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

-- ==========================================
-- REMOTE'Ы ИГРЫ
-- ==========================================
local Remotes = {
    PlaceUnit = ReplicatedStorage.RemoteFunctions.PlaceUnit,
    UpgradeUnit = ReplicatedStorage.RemoteFunctions.UpgradeUnit,
    SellUnit = ReplicatedStorage.RemoteFunctions.SellUnit,
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
local placedUnits = {}

-- ==========================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ==========================================

local function Vec3ToString(vec)
    return string.format("%s, %s, %s", vec.X, vec.Y, vec.Z)
end

local function StringToVec3(str)
    local x, y, z = str:match("([^,]+), ([^,]+), ([^,]+)")
    return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

local function CFtoString(cf)
    local components = {cf:GetComponents()}
    return table.concat(components, ", ")
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
-- СИСТЕМА ЗАПИСИ
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
    self:ConnectRecordingEvents()
    
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

function MacroSystem:ConnectRecordingEvents()
    -- Хук PlaceUnit
    if not getgenv().originalPlaceUnit then
        getgenv().originalPlaceUnit = Remotes.PlaceUnit.InvokeServer
    end
    
    Remotes.PlaceUnit.InvokeServer = function(self, unitName, position, ...)
        if isRecording then
            MacroSystem:RecordPlaceUnit(unitName, position)
        end
        return getgenv().originalPlaceUnit(self, unitName, position, ...)
    end
    
    -- Хук UpgradeUnit
    if not getgenv().originalUpgradeUnit then
        getgenv().originalUpgradeUnit = Remotes.UpgradeUnit.InvokeServer
    end
    
    Remotes.UpgradeUnit.InvokeServer = function(self, unitInstance, ...)
        if isRecording then
            MacroSystem:RecordUpgradeUnit(unitInstance)
        end
        return getgenv().originalUpgradeUnit(self, unitInstance, ...)
    end
    
    Log("🔗 Хуки установлены")
end

function MacroSystem:RecordPlaceUnit(unitName, position)
    currentMacro.unitCounter = currentMacro.unitCounter + 1
    local unitID = currentMacro.unitCounter
    local timeSinceStart = math.floor(tick() - currentMacro.startTime)
    
    local action = {
        Type = "PlaceUnit",
        Time = timeSinceStart,
        ID = unitID,
        Unit = unitName,
        Position = Vec3ToString(position),
        CF = CFtoString(CFrame.new(position))
    }
    
    table.insert(currentMacro.actions, action)
    
    task.wait(0.5)
    
    local workspace = game:GetService("Workspace")
    local unitsFolder = workspace:FindFirstChild("Units")
    
    if unitsFolder then
        local closestUnit = nil
        local closestDistance = math.huge
        
        for _, unit in pairs(unitsFolder:GetChildren()) do
            if unit:IsA("Model") and unit.PrimaryPart then
                local distance = (unit.PrimaryPart.Position - position).Magnitude
                if distance < closestDistance and distance < 5 then
                    closestDistance = distance
                    closestUnit = unit
                end
            end
        end
        
        if closestUnit then
            placedUnits[unitID] = closestUnit
            Log(string.format("🏗️ [%.1fs] %s (ID:%d)", timeSinceStart, unitName, unitID))
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
    
    local action = {
        Type = "UpgradeUnit",
        ID = unitID,
        Price = 0
    }
    
    table.insert(currentMacro.actions, action)
    Log(string.format("⬆️ Улучшение ID:%d", unitID))
end

-- ==========================================
-- СИСТЕМА ВОСПРОИЗВЕДЕНИЯ
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
                task.wait(3)
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
        
        while isPaused and isPlaying do
            task.wait(0.1)
        end
        
        if action.Time then
            local targetTime = startTime + action.Time
            local currentTime = tick()
            if currentTime < targetTime then
                task.wait(targetTime - currentTime)
            end
        else
            task.wait(SETTINGS.actionDelay)
        end
        
        pcall(function()
            self:ExecuteAction(action)
        end)
        
        Log(string.format("▶️ [%d/%d] %s", i, #macro.actions, action.Type))
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
    
    Log(string.format("🏗️ Размещаю: %s", action.Unit))
    
    pcall(function()
        Remotes.PlaceUnit:InvokeServer(action.Unit, position)
    end)
    
    task.wait(0.5)
    
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
    
    pcall(function()
        Remotes.UpgradeUnit:InvokeServer(unit)
    end)
    
    task.wait(SETTINGS.upgradeDelay)
end

-- ==========================================
-- СОХРАНЕНИЕ И ЗАГРУЗКА
-- ==========================================

function MacroSystem:SaveMacro(macro)
    pcall(function()
        if writefile then
            local filename = "zeexhub_macro_" .. macro.name:gsub("[^%w_]", "_") .. ".json"
            writefile(filename, HttpService:JSONEncode(macro.actions))
            Log("💾 Сохранён: " .. filename)
        end
    end)
    return true
end

function MacroSystem:LoadMacro(macroName)
    local success, result = pcall(function()
        if not readfile or not isfile then
            error("readfile не поддерживается")
        end
        
        local filename = "zeexhub_macro_" .. macroName:gsub("[^%w_]", "_") .. ".json"
        
        if not isfile(filename) then
            error("Файл не найден")
        end
        
        local actions = HttpService:JSONDecode(readfile(filename))
        
        return {
            name = macroName,
            actions = actions
        }
    end)
    
    if success then
        Log("📂 Загружен: " .. macroName)
        return result
    else
        Log("❌ Ошибка загрузки: " .. tostring(result), true)
        return nil
    end
end

return MacroSystem
