-- main.lua - ЭТО ЕДИНСТВЕННОЕ ЧТО ТЫ ВСТАВЛЯЕШЬ В ИНЖЕКТОР

-- Загружаем все модули (они должны лежать в той же папке что и main.lua)
local Settings = loadfile("settings.lua")()
local Storage = loadfile("storage.lua")()
local MacroCore = loadfile("macro_core.lua")()

-- Загружаем сохраненные макросы
local savedMacros = Storage:LoadMacros(Settings.Macro.savePath)

-- Внедряем все в глобальную таблицу (чтобы ui.lua видел)
_G.ZeexLUA = {
    Settings = Settings,
    Storage = Storage,
    MacroCore = MacroCore,
    macros = savedMacros,
    selectedMacro = nil,
    isRecording = false
}

-- Загружаем интерфейс
loadfile("ui.lua")()

print("✅ ZeexLUA загружен | Макросов: " .. #savedMacros)
