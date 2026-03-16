--[[
    MACRO.LUA - ТОЛЬКО ДЕЙСТВИЯ ДЛЯ CREATE, LIST, REFRESH, LOAD
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==========================================
-- ДАННЫЕ
-- ==========================================
local macros = {}  -- Хранилище макросов
local selectedMacro = nil

-- ==========================================
-- ФУНКЦИЯ СОЗДАНИЯ МАКРОСА
-- ==========================================
local function createMacro(name)
    return {
        name = name,
        actions = {},
        createdAt = os.time()
    }
end

-- ==========================================
-- API ДЛЯ UI (ТОЛЬКО 4 КНОПКИ)
-- ==========================================
local MacroAPI = {
    -- CREATE - создает новый макрос и возвращает его
    create = function(name, notifCallback)
        if name and name ~= "" then
            local newMacro = createMacro(name)
            table.insert(macros, newMacro)
            if notifCallback then 
                notifCallback("✨ Макрос создан: " .. name, 2) 
            end
            return newMacro
        else
            if notifCallback then 
                notifCallback("⚠️ Введите имя макроса", 2) 
            end
            return nil
        end
    end,
    
    -- LIST - возвращает список всех макросов
    list = function(notifCallback)
        if #macros == 0 then
            if notifCallback then 
                notifCallback("📋 Список макросов пуст", 2) 
            end
            return {}
        else
            if notifCallback then 
                notifCallback("📋 Загружено " .. #macros .. " макросов", 1) 
            end
            return macros
        end
    end,
    
    -- REFRESH - просто уведомление (логика обновления в UI)
    refresh = function(notifCallback)
        if notifCallback then 
            notifCallback("🔄 Список обновлен", 1) 
        end
        return macros  -- возвращаем текущий список на всякий случай
    end,
    
    -- LOAD - выбирает макрос для загрузки
    load = function(macro, notifCallback)
        if macro then
            selectedMacro = macro
            if notifCallback then 
                notifCallback("📂 Загружен: " .. macro.name, 2) 
            end
            return true
        else
            if notifCallback then 
                notifCallback("⚠️ Сначала выберите макрос в LIST", 2) 
            end
            return false
        end
    end,
    
    -- Геттер для выбранного макроса (если понадобится)
    getSelected = function()
        return selectedMacro
    end,
    
    -- Геттер для всех макросов
    getAll = function()
        return macros
    end
}

return MacroAPI
