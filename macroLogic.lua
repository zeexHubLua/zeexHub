local MacroSystem = {}
MacroSystem.__index = MacroSystem

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function MacroSystem:StartRecording(name)
    print("🔴 Запись:", name)
    return true
end

function MacroSystem:StopRecording()
    print("⏹️ Остановка")
    return {name = "test", actions = {}}
end

function MacroSystem:SaveMacro(macro)
    print("💾 Сохранение:", macro.name)
    return true
end

function MacroSystem:LoadMacro(name)
    print("📂 Загрузка:", name)
    return {name = name, actions = {}}
end

function MacroSystem:StartPlayback(macro, loop)
    print("▶️ Воспроизведение:", macro.name)
    return true
end

function MacroSystem:StopPlayback()
    print("⏹️ Стоп")
    return true
end

function MacroSystem:TogglePause()
    print("⏸️ Пауза")
    return false
end

print("✅ MacroSystem загружен с GitHub")

return MacroSystem
