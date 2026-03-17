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
-- REMOTE'Ы ИГРЫ
-- ==========================================
local Remotes = {
    -- RemoteFunctions
    PlaceUnit = ReplicatedStorage.RemoteFunctions.PlaceUnit,
    UpgradeUnit = ReplicatedStorage.RemoteFunctions.UpgradeUnit,
    SellUnit = ReplicatedStorage.RemoteFunctions.SellUnit,
    BuyUnitBox = ReplicatedStorage.RemoteFunctions.BuyUnitBox,
    BuyUnitWithSeeds = ReplicatedStorage.RemoteFunctions.BuyUnitWithSeeds,
    BuyUnitWithRobux = ReplicatedStorage.RemoteFunctions.BuyUnitWithRobux,
    SetUnitEquipped = ReplicatedStorage.RemoteFunctions.SetUnitEquipped,
    UpgradeAll = ReplicatedStorage.RemoteFunctions.UpgradeAll,
    LockUnit = ReplicatedStorage.RemoteFunctions.LockUnit,
    ToggleAutoUpgrade = ReplicatedStorage.RemoteFunctions.ToggleAutoUpgrade,
    ToggleAutoUpgradePriority = ReplicatedStorage.RemoteFunctions.ToggleAutoUpgradePriority,
    ActivateUnitAbility = ReplicatedStorage.RemoteFunctions.ActivateUnitAbility,
    ChangeTrialsStep = ReplicatedStorage.RemoteFunctions.ChangeTrialsStep,
    PlaceDifficultyVote = ReplicatedStorage.RemoteFunctions.PlaceDifficultyVote,
    DeleteUnit = ReplicatedStorage.RemoteFunctions.DeleteUnit,
    PromptDeveloperProduct = ReplicatedStorage.RemoteFunctions.PromptDeveloperProduct,
    
    -- RemoteEvents
    UpdateUnitInventory = ReplicatedStorage.RemoteEvents.UpdateUnitInventory,
    BanFromUnitBox = ReplicatedStorage.RemoteEvents.BanFromUnitBox,
    StartDifficultyVote = ReplicatedStorage.RemoteEvents.StartDifficultyVote,
    PlayerPickUnits = ReplicatedStorage.RemoteEvents.PlayerPickUnits,
    UpdateTDVotes = ReplicatedStorage.RemoteEvents.UpdateTDVotes,
    TradeStartCountdown = ReplicatedStorage.RemoteEvents.TradeStartCountdown,
    TradeStopCountdown = ReplicatedStorage.RemoteEvents.TradeStopCountdown,
    WTDecreaseValueNow = ReplicatedStorage.RemoteEvents.WTDecreaseValueNow
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
local recordingConnections = {}
local playbackCoroutine = nil

local placedUnits = {}
local lastPlacedPosition = nil
local lastPlacedUnit = nil

-- ==========================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ==========================================

local function CFtoString(cf)
    local components = {cf:GetComponents()}
    return table.concat(components, ", ")
end

local function StringToCF(str)
    local components = {}
    for num in string.gmatch(str, "[^,]+") do
        table.insert(components, tonumber(num))
    end
    return CFrame.new(unpack(components))
end

local function Vec3ToString(vec)
    return string.format("%s, %s, %s", vec.X, vec.Y, vec.Z)
end

local function StringToVec3(str)
    local x, y, z = str:match("([^,]+), ([^,]+), ([^,]+)")
    return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

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
    
    for _, connection in pairs(recordingConnections) do
        connection:Disconnect()
    end
    recordingConnections = {}
    
    Log("⏹️ ЗАПИСЬ ОСТАНОВЛЕНА")
    Log("📊 Записано действий: " .. #currentMacro.actions)
    
    return currentMacro
end

function MacroSystem:ConnectRecordingEvents()
    -- Хукаем PlaceUnit
    local oldPlaceUnit = Remotes.PlaceUnit.InvokeServer
    Remotes.PlaceUnit.InvokeServer = function(self, unitName, position, ...)
        lastPlacedPosition = position
        lastPlacedUnit = unitName
        
        if isRecording then
            MacroSystem:RecordPlaceUnit(unitName, position)
        end
        
        return oldPlaceUnit(self, unitName, position, ...)
    end
    
    -- Хукаем UpgradeUnit
    local oldUpgradeUnit = Remotes.UpgradeUnit.InvokeServer
    Remotes.UpgradeUnit.InvokeServer = function(self, unitInstance, ...)
        if isRecording then
            MacroSystem:RecordUpgradeUnit(unitInstance)
        end
        
        return oldUpgradeUnit(self, unitInstance, ...)
    end
    
    -- Хукаем SellUnit
    local oldSellUnit = Remotes.SellUnit.InvokeServer
    Remotes.SellUnit.InvokeServer = function(self, unitInstance, ...)
        if isRecording then
            MacroSystem:RecordSellUnit(unitInstance)
        end
        
        return oldSellUnit(self, unitInstance, ...)
    end
    
    Log("🔗 Хуки установлены")
end

function MacroSystem:RecordPlaceUnit(unitName, position)
    currentMacro.unitCounter = currentMacro.unitCounter + 1
    local unitID = currentMacro.unitCounter
    
    local timeSinceStart = math.floor(tick() - currentMacro.startTime)
    
    -- Определяем CF
    local cf = CFrame.new(position)
    
    local action = {
        Type = "PlaceUnit",
        Time = timeSinceStart,
        ID = unitID,
        Unit = unitName,
        Position = Vec3ToString(position),
        CF = CFtoString(cf)
    }
    
    table.insert(currentMacro.actions, action)
    
    -- Сохраняем для отслеживания
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
        Log("⚠️ Юнит для улучшения не найден в списке", true)
        return
    end
    
    local action = {
        Type = "UpgradeUnit",
        ID = unitID,
        Price = 0 -- Игра сама определит цену
    }
    
    table.insert(currentMacro.actions, action)
    
    Log(string.format("⬆️ Улучшение ID:%d", unitID))
end

function MacroSystem:RecordSellUnit(unitInstance)
    local unitID = nil
    
    for id, unit in pairs(placedUnits) do
        if unit == unitInstance then
            unitID = id
            break
        end
    end
    
    if not unitID then
        Log("⚠️ Юнит для продажи не найден", true)
        return
    end
    
    local action = {
        Type = "SellUnit",
        ID = unitID
    }
    
    table.insert(currentMacro.actions, action)
    
    placedUnits[unitID] = nil
    
    Log(string.format("💰 Продажа ID:%d", unitID))
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
        
        local success, err = pcall(function()
            self:ExecuteAction(action)
        end)
        
        if not success then
            Log(string.format("Ошибка [%d]: %s", i, err), true)
        end
        
        Log(string.format("▶️ [%d/%d] %s", i, #macro.actions, action.Type))
    end
end

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

function MacroSystem:PlaceTower(action)
    local position = StringToVec3(action.Position)
    position = ApplyRandomOffset(position)
    
    Log(string.format("🏗️ Размещаю: %s", action.Unit))
    
    local success, result = pcall(function()
        return Remotes.PlaceUnit:InvokeServer(action.Unit, position)
    end)
    
    if success and result then
        task.wait(0.5)
        
        local workspace = game:GetService("Workspace")
        local unitsFolder = workspace:FindFirstChild("Units")
        
        if unitsFolder then
            local closestUnit = nil
            local closestDistance = math.huge
            
            for _, unit in pairs(unitsFolder:GetChildren()) do
                if unit:IsA("Model") and unit.PrimaryPart then
                    local distance = (unit.PrimaryPart.Position - position).Magnitude
                    if distance < closestDistance and distance < 10 then
                        closestDistance = distance
                        closestUnit = unit
                    end
                end
            end
            
            if closestUnit then
                placedUnits[action.ID] = closestUnit
                Log("✅ Юнит размещён ID:" .. action.ID)
            end
        end
    else
        Log("❌ Ошибка размещения: " .. tostring(result), true)
    end
end

function MacroSystem:UpgradeTower(action)
    local unit = placedUnits[action.ID]
    
    if not unit or not unit.Parent then
        Log(string.format("❌ Юнит ID:%d не найден!", action.ID), true)
        return
    end
    
    Log(string.format("⬆️ Улучшаю ID:%d", action.ID))
    
    local success, err = pcall(function()
        Remotes.UpgradeUnit:InvokeServer(unit)
    end)
    
    if not success then
        Log("❌ Ошибка улучшения: " .. tostring(err), true)
    end
    
    task.wait(SETTINGS.upgradeDelay)
end

function MacroSystem:SellTower(action)
    local unit = placedUnits[action.ID]
    
    if not unit or not unit.Parent then
        Log(string.format("❌ Юнит ID:%d не найден!", action.ID), true)
        return
    end
    
    Log(string.format("💰 Продаю ID:%d", action.ID))
    
    pcall(function()
        Remotes.SellUnit:InvokeServer(unit)
    end)
    
    placedUnits[action.ID] = nil
end

-- ==========================================
-- СОХРАНЕНИЕ И ЗАГРУЗКА
-- ==========================================

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

return MacroSystem
