local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local StatusUI = {}
StatusUI.BackgroundEnabled = true
StatusUI.Status = "Initializing"
StatusUI.ActionStatus = "Starting script..."
StatusUI.ScriptCompleted = false
StatusUI.StartTime = tick()

local gui, frame, statusLabel, timerLabel, rebirthLabel, speedLabel, actionLabel, targetLabel

local function createLabel(name, size, pos, text, color, fontSize, parent)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = pos
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextSize = fontSize or 30
    label.TextScaled = true
    label.Font = Enum.Font.Cartoon
    label.Parent = parent
    return label
end

function StatusUI.Create()
    gui = Instance.new("ScreenGui")
    gui.Name = "KaitunStatusUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    statusLabel = createLabel("StatusLabel", UDim2.new(1, 0, 0.08, 0), UDim2.new(0, 0, 0, 0), "Status: INITIALIZING", nil, 40, frame)
    timerLabel = createLabel("TimerLabel", UDim2.new(1, 0, 0.06, 0), UDim2.new(0, 0, 0.08, 0), "00:00:00", Color3.fromRGB(0, 255, 0), 32, frame)
    
    createLabel("InfoSection", UDim2.new(1, 0, 0.05, 0), UDim2.new(0, 0, 0.18, 0), "INFORMAÇÕES", nil, 30, frame)
    
    rebirthLabel = createLabel("RebirthLabel", UDim2.new(0.48, 0, 0.08, 0), UDim2.new(0.01, 0, 0.25, 0), "Rebirth: 0/20", Color3.fromRGB(255, 200, 100), 28, frame)
    speedLabel = createLabel("SpeedLabel", UDim2.new(0.48, 0, 0.08, 0), UDim2.new(0.51, 0, 0.25, 0), "Speed: 0/300", Color3.fromRGB(100, 200, 255), 28, frame)
    
    createLabel("TargetSection", UDim2.new(1, 0, 0.05, 0), UDim2.new(0, 0, 0.38, 0), "OBJETIVO ATUAL", nil, 30, frame)
    targetLabel = createLabel("TargetLabel", UDim2.new(1, 0, 0.15, 0), UDim2.new(0, 0, 0.45, 0), "Aguardando...", Color3.fromRGB(200, 200, 200), 32, frame)
    
    actionLabel = createLabel("ActionLabel", UDim2.new(1, 0, 0.08, 0), UDim2.new(0, 0, 0.65, 0), "Initializing...", nil, 28, frame)
    
    local infoLabel = createLabel("InfoLabel", UDim2.new(1, 0, 0.04, 0), UDim2.new(0, 0, 0.96, 0), "Pressione F1 para esconder/mostrar o fundo", Color3.fromRGB(150, 150, 150), 18, frame)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F1 then
            StatusUI.BackgroundEnabled = not StatusUI.BackgroundEnabled
            frame.BackgroundTransparency = StatusUI.BackgroundEnabled and 0 or 1
        end
    end)
end

function StatusUI.UpdateStatus(status)
    StatusUI.Status = status
end

function StatusUI.UpdateAction(action)
    StatusUI.ActionStatus = action
end

function StatusUI.Update(currentRebirth, currentSpeed, targetRebirth, targetSpeed)
    if not gui or not statusLabel then return end
    
    local statusColors = {
        Initializing = Color3.fromRGB(255, 165, 0),
        Running = Color3.fromRGB(100, 200, 255),
        Rebirthing = Color3.fromRGB(255, 150, 0),
        Upgrading = Color3.fromRGB(150, 100, 255),
        Collecting = Color3.fromRGB(100, 255, 150),
        Completed = Color3.fromRGB(100, 255, 100),
        Error = Color3.fromRGB(255, 100, 100)
    }
    
    local elapsed = tick() - StatusUI.StartTime
    timerLabel.Text = string.format("%02d:%02d:%02d", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), math.floor(elapsed % 60))
    
    statusLabel.TextColor3 = statusColors[StatusUI.Status] or Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "Status: " .. StatusUI.Status:upper()
    
    local rebirthProgress = math.min((currentRebirth / targetRebirth) * 100, 100)
    rebirthLabel.Text = string.format("Rebirth: %d/%d (%.1f%%)", currentRebirth, targetRebirth, rebirthProgress)
    rebirthLabel.TextColor3 = currentRebirth >= targetRebirth and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
    
    local speedProgress = math.min((currentSpeed / targetSpeed) * 100, 100)
    speedLabel.Text = string.format("Speed: %d/%d (%.1f%%)", currentSpeed, targetSpeed, speedProgress)
    speedLabel.TextColor3 = currentSpeed >= targetSpeed and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 200, 255)
    
    if currentRebirth >= targetRebirth and currentSpeed >= targetSpeed then
        targetLabel.Text = "🎉 OBJETIVO COMPLETO! 🎉\n\nRebirth 20 e Speed 300 atingidos"
        targetLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif currentRebirth < targetRebirth then
        targetLabel.Text = string.format("Progredindo para Rebirth %d\n\nFaltam %d rebirths", targetRebirth, targetRebirth - currentRebirth)
        targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    else
        targetLabel.Text = string.format("Aumentando Speed para %d\n\nFaltam %d de speed", targetSpeed, targetSpeed - currentSpeed)
        targetLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    end
    
    actionLabel.Text = StatusUI.ActionStatus
end

function StatusUI.StartUpdateLoop()
    task.spawn(function()
        while not StatusUI.ScriptCompleted do
            task.wait(0.5)
        end
    end)
end

function StatusUI.Destroy()
    if gui then
        gui:Destroy()
    end
end

return StatusUI
