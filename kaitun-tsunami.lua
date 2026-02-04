repeat task.wait() until game:IsLoaded()

pcall(function() 
    UserSettings():GetService("UserGameSettings").MasterVolume = 0 
    UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local EconomyMath = require(ReplicatedStorage.Shared.utils.EconomyMath)
local ClientGlobals = require(ReplicatedStorage.Client.Modules.ClientGlobals)
local BrainrotModule = require(ReplicatedStorage.SharedModules.BrainrotModule)

local StatusUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/estevao1098/Ultimate-Bloxx---FarmSync/refs/heads/main/tsunami-ui.lua"))()

local TARGET_REBIRTH = 20
local TARGET_SPEED = 300

local function CheckRebirth()
    return LocalPlayer:GetAttribute("Rebirth") or 0
end

local function CheckSpeed()
    return LocalPlayer:GetAttribute("CurrentSpeed") or 0
end

local function GetCurrentGenRate()
    local totalGen = 0
    if not (ClientGlobals.Plots and ClientGlobals.Plots.Data) then return totalGen end
    
    for _, plotData in pairs(ClientGlobals.Plots.Data) do
        if plotData.player ~= LocalPlayer then continue end
        local stands = ClientGlobals.Plots:TryIndex({_, "data", "Stands"})
        if not stands then break end
        for _, stand in pairs(stands) do
            totalGen = totalGen + (stand.brainrot and stand.brainrot.rate or 0)
        end
        break
    end
    
    return totalGen
end

local function GetDivineCount()
    local divineCount = 0
    if not (ClientGlobals.Plots and ClientGlobals.Plots.Data) then return divineCount end
    
    for _, plotData in pairs(ClientGlobals.Plots.Data) do
        if plotData.player ~= LocalPlayer then continue end
        local stands = ClientGlobals.Plots:TryIndex({_, "data", "Stands"})
        if not stands then break end
        for _, stand in pairs(stands) do
            local isDivine = stand.brainrot and stand.brainrot.name and BrainrotModule.GetBrainrotClass(stand.brainrot.name) == "Divine"
            divineCount = divineCount + (isDivine and 1 or 0)
        end
        break
    end
    
    return divineCount
end

local function CanRebirth()
    local currentRebirth = CheckRebirth()
    local nextRebirth = currentRebirth + 1
    
    if currentRebirth >= EconomyMath.GetMaxRebirth() then return false, "Max rebirth reached" end
    if CheckSpeed() < EconomyMath.GetRebirthRequiredSpeed(nextRebirth) then return false, "Insufficient speed" end
    
    local minGen = EconomyMath.GetRebirthMinGen(nextRebirth)
    if minGen > 0 and GetCurrentGenRate() < minGen then return false, "Insufficient generation" end
    
    local divineReq = EconomyMath.GetRebirthDivineRequirement(nextRebirth)
    if divineReq > 0 and GetDivineCount() < divineReq then return false, "Insufficient divines" end
    
    return true, "OK"
end

local function TryRebirth()
    local can, reason = CanRebirth()
    if not can then
        StatusUI.UpdateAction("Waiting for requirements: " .. reason)
        return false
    end
    
    StatusUI.UpdateAction("Executing rebirth...")
    StatusUI.UpdateStatus("Rebirthing")
    
    local success, result = pcall(function()
        return ReplicatedStorage.RemoteFunctions.Rebirth:InvokeServer()
    end)
    
    if success and result == "Success" then
        StatusUI.UpdateAction("Rebirth complete! New rebirth: " .. CheckRebirth())
        return true
    end
    
    StatusUI.UpdateAction("Failed to rebirth")
    return false
end

local function IncreaseSpeed(value)
    StatusUI.UpdateAction("Increasing speed by " .. value)
    StatusUI.UpdateStatus("Upgrading")
    
    pcall(function()
        return ReplicatedStorage.RemoteFunctions.UpgradeSpeed:InvokeServer(value)
    end)
end

local function GetPlayerBase()
    for _, base in pairs(workspace.Bases:GetChildren()) do
        local playerNameLabel = base:FindFirstChild("Title", true) 
            and base.Title:FindFirstChild("TitleGui", true) 
            and base.Title.TitleGui:FindFirstChild("Frame", true) 
            and base.Title.TitleGui.Frame:FindFirstChild("PlayerName")
        
        if playerNameLabel and playerNameLabel.ContentText == LocalPlayer.Name then
            return base
        end
    end
    
    return nil
end

local function CollectMoney(baseId, slotId)
    pcall(function()
        ReplicatedStorage.Packages.Net["RF/Plot.PlotAction"]:InvokeServer("Collect Money", baseId, slotId)
    end)
end

local function AccountsCompleted()
    StatusUI.UpdateStatus("Completed")
    StatusUI.UpdateAction("Script finished successfully!")
    StatusUI.ScriptCompleted = true
    
    getgenv().client:ChangeToFolder(
        "229de7eb108b539d4975a9a96c3f226d499e537de8b60016d74851193b94422d", 
        "6d63dcef53e4317807ff1f6264bb2b8181a161fbc8135ec6646d5fd9b1d2fe3f", 
        false, 
        nil
    )
end

StatusUI.Create()

task.spawn(function()
    while not StatusUI.ScriptCompleted do
        StatusUI.Update(CheckRebirth(), CheckSpeed(), TARGET_REBIRTH, TARGET_SPEED)
        task.wait(0.5)
    end
end)

task.spawn(function()
    StatusUI.UpdateStatus("Running")
    
    while task.wait(2) do
        local currentRebirth = CheckRebirth()
        local currentSpeed = CheckSpeed()
        
        if currentRebirth >= TARGET_REBIRTH and currentSpeed >= TARGET_SPEED then
            AccountsCompleted()
            break
        end

        if currentRebirth < TARGET_REBIRTH then
            TryRebirth()
            task.wait(1)
        elseif currentSpeed < TARGET_SPEED then
            IncreaseSpeed(10)
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        local playerBase = GetPlayerBase()
        if not playerBase then continue end
        
        StatusUI.UpdateStatus("Collecting")
        StatusUI.UpdateAction("Collecting money from base...")
        
        for i = 1, 10 do
            CollectMoney(playerBase.Name, i)
        end
        
        StatusUI.UpdateStatus("Running")
    end
end)
