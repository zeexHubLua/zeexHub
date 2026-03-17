print("🔄 СТАРТ ТЕСТА")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("✅ Player:", player.Name)

-- Удаляем старый UI
if player.PlayerGui:FindFirstChild("ZeexHub") then
    player.PlayerGui.ZeexHub:Destroy()
    print("🗑️ Старый UI удален")
end

wait(0.5)

-- Создаем тестовое окно
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZeexHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(15, 0, 25)
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "✅ UI РАБОТАЕТ!"
label.TextColor3 = Color3.fromRGB(0, 255, 150)
label.TextSize = 24
label.Font = Enum.Font.GothamBold
label.Parent = frame

print("✅ ТЕСТОВОЕ ОКНО СОЗДАНО")
print("📍 Проверь центр экрана!")
