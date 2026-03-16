-- macro_core.lua
local MacroCore = {}
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

function MacroCore:New(name)
    return {
        name = name or "Macro " .. os.date("%H:%M"),
        actions = {},
        createdAt = os.time()
    }
end

function MacroCore:StartRecording()
    self.isRecording = true
    self.recordStartTime = tick()
    self.currentMacro = self:New()
    self.trackedUnits = {}
    self.nextId = 1
    
    -- Запускаем сканирование
    task.spawn(function()
        local lastUnits = {}
        
        while self.isRecording do
            task.wait(0.2)
            
            local currentUnits = self:ScanUnits()
            local currentTime = tick() - self.recordStartTime
            
            -- Поиск новых юнитов
            for id, unit in pairs(currentUnits) do
                if not lastUnits[id] and not self.trackedUnits[id] then
                    local newId = self.nextId
                    self.nextId = self.nextId + 1
                    self.trackedUnits[id] = newId
                    
                    table.insert(self.currentMacro.actions, {
                        ID = newId,
                        Type = "PlaceUnit",
                        Unit = unit.name,
                        Time = math.floor(currentTime * 10) / 10,
                        Position = string.format("%.6f, %.6f, %.6f", 
                            unit.position.X, unit.position.Y, unit.position.Z),
                        CF = self:CFrameToString(unit.cframe)
                    })
                end
            end
            
            lastUnits = currentUnits
        end
    end)
    
    return self.currentMacro
end

function MacroCore:StopRecording()
    self.isRecording = false
    return self.currentMacro
end

function MacroCore:ScanUnits()
    local units = {}
    local folders = {
        workspace:FindFirstChild("Towers"),
        workspace:FindFirstChild("Units"),
        workspace:FindFirstChild("PlacedUnits")
    }
    
    for _, folder in ipairs(folders) do
        if folder then
            for _, unit in ipairs(folder:GetChildren()) do
                local cframe = unit:GetPivot()
                local root = unit:FindFirstChild("HumanoidRootPart") or unit:FindFirstChild("Torso")
                local pos = root and root.Position or cframe.Position
                local id = math.floor(pos.X * 10) .. "_" .. math.floor(pos.Z * 10)
                
                units[id] = {
                    unit = unit,
                    position = pos,
                    cframe = cframe,
                    name = unit.Name
                }
            end
        end
    end
    return units
end

function MacroCore:CFrameToString(cf)
    local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
    return string.format("%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f",
        x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
end

function MacroCore:StringToPosition(str)
    local nums = {}
    for num in string.gmatch(str or "", "[-]?%d+%.?%d*") do
        table.insert(nums, tonumber(num))
    end
    if #nums >= 3 then
        return Vector3.new(nums[1], nums[2], nums[3])
    end
    return Vector3.new(0,0,0)
end

function MacroCore:PlayMacro(macro)
    if not macro or #macro.actions == 0 then return end
    
    local actions = macro.actions
    table.sort(actions, function(a,b) return (a.Time or 0) < (b.Time or 0) end)
    
    local startTime = tick()
    
    for i, action in ipairs(actions) do
        local waitTime = (action.Time or 0) - (tick() - startTime)
        if waitTime > 0 then task.wait(waitTime) end
        
        if action.Type == "PlaceUnit" then
            local pos = self:StringToPosition(action.Position)
            local screenPos = workspace.CurrentCamera:WorldToViewportPoint(pos)
            
            if screenPos.Z > 0 then
                VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, nil, 0)
                task.wait(0.03)
                VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, nil, 0)
            end
        end
    end
end

return MacroCore
