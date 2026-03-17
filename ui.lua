print("========== ТЕСТ НАЧАТ ==========")
warn("⚠️ ЭТО ПРЕДУПРЕЖДЕНИЕ")
print("✅ Executor работает!")
print("✅ Player:", game.Players.LocalPlayer.Name)

-- Создаём GUI
local sg = Instance.new("ScreenGui")
sg.Parent = game.Players.LocalPlayer.PlayerGui
print("✅ ScreenGui создан")

local frame = Instance.new("Frame")
frame.Parent = sg
frame.Size = UDim2.new(0, 500, 0, 300)
frame.Position = UDim2.new(0.5, -250, 0.5, -150)
frame.BackgroundColor3 = Color3.new(1, 0, 0) -- КРАСНЫЙ!
frame.BorderSizePixel = 5
frame.BorderColor3 = Color3.new(0, 1, 0) -- ЗЕЛЁНАЯ ОБВОДКА!
print("✅ Frame создан")

local text = Instance.new("TextLabel")
text.Parent = frame
text.Size = UDim2.new(1, 0, 1, 0)
text.BackgroundTransparency = 1
text.Text = "ЕСЛИ ВИДИШЬ МЕНЯ - ВСЁ РАБОТАЕТ!"
text.TextColor3 = Color3.new(1, 1, 1)
text.TextSize = 20
text.Font = Enum.Font.GothamBold
text.TextWrapped = true
print("✅ TextLabel создан")

print("========== ТЕСТ ЗАВЕРШЁН ==========")
print("📍 СМОТРИ В ЦЕНТР ЭКРАНА!")
print("🔴 Должен быть КРАСНЫЙ прямоугольник")
print("🟢 С ЗЕЛЁНОЙ обводкой")
