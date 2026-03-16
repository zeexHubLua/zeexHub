-- macro.lua (упрощенный тест)
local MacroAPI = {
    create = function() print("CREATE нажата") end,
    list = function() print("LIST нажата") end,
    refresh = function() print("REFRESH нажата") end,
    load = function() print("LOAD нажата") end,
    record = function(btn) print("RECORD нажата") end,
    start = function() print("START нажата") end
}
return MacroAPI
