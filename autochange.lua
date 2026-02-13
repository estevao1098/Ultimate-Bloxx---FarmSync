repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

getgenv().AutoChange = {}

local function safeInvoke(remote, timeout, ...)
    local result = nil
    local done = false
    local args = {...}
    
    task.spawn(function()
        pcall(function()
            result = remote:InvokeServer(unpack(args))
        end)
        done = true
    end)
    
    local start = tick()
    while not done and (tick() - start) < (timeout or 5) do
        task.wait(0.1)
    end
    
    return result
end

getgenv().AutoChange.getAccountData = function()
    local HttpService = game:GetService("HttpService")
    local Player = game.Players.LocalPlayer
    local CommF = game.ReplicatedStorage.Remotes.CommF_
    local Data = Player:FindFirstChild("Data")
    local PlaceId = game.PlaceId

    local account = {
        Player = { Name = Player.Name, DisplayName = Player.DisplayName, UserId = Player.UserId },
        Level = Data and Data.Level.Value or 0,
        Beli = Data and Data.Beli.Value or 0,
        Fragments = Data and Data.Fragments.Value or 0,
        BountyHonor = 0,
        Sea = PlaceId == 2753915549 and 1 or PlaceId == 4442272183 and 2 or PlaceId == 7449423635 and 3 or 0,
        Race = { Name = Data and Data.Race.Value or "", Version = 1, Full = false },
        Fruit = { Name = Data and Data.DevilFruit.Value or "", Mastery = 0, Awakened = false, AwakenedSkills = {} },
        Swords = {}, Melees = {}, Guns = {}, Fruits = {}, Accessories = {}, Materials = {},
        PullLever = false
    }

    pcall(function()
        account.BountyHonor = Player.leaderstats and Player.leaderstats:FindFirstChild("Bounty/Honor") and Player.leaderstats["Bounty/Honor"].Value or 0
    end)

    local inventory = safeInvoke(CommF, 10, 'getInventory')
    if inventory and type(inventory) == "table" then
        for _, item in pairs(inventory) do
            pcall(function()
                if item.Type == "Sword" then table.insert(account.Swords, {Name = item.Name, Mastery = item.Mastery or 0})
                elseif item.Type == "Gun" then table.insert(account.Guns, {Name = item.Name, Mastery = item.Mastery or 0})
                elseif item.Type == "Blox Fruit" or item.Type == "Fruit" then table.insert(account.Fruits, item.Name)
                elseif item.Type == "Wear" then table.insert(account.Accessories, item.Name)
                elseif item.Type == "Material" then table.insert(account.Materials, {Name = item.Name, Count = item.Count or 1})
                end
            end)
        end
    end

    pcall(function()
        local fruit = Data and Data:FindFirstChild("DevilFruit")
        if fruit and fruit.Value ~= "" then
            local tool = Player:FindFirstChild("Backpack") and Player.Backpack:FindFirstChild(fruit.Value)
            if tool and tool:FindFirstChild("Level") then account.Fruit.Mastery = tool.Level.Value end
        end
    end)

    local skills = safeInvoke(CommF, 5, "getAwakenedAbilities")
    if skills and type(skills) == "table" then
        local totalSkills = 0
        local awakenedCount = 0
        for _, s in pairs(skills) do
            pcall(function()
                totalSkills = totalSkills + 1
                if s.Awakened then 
                    table.insert(account.Fruit.AwakenedSkills, s.Key) 
                    awakenedCount = awakenedCount + 1
                end
            end)
        end

        account.Fruit.Awakened = totalSkills > 0 and awakenedCount == totalSkills
    end

    for _, m in pairs({"Superhuman", "ElectricClaw", "DragonTalon", "SharkmanKarate", "DeathStep", "Godhuman", "SanguineArt"}) do
        local status = safeInvoke(CommF, 3, "Buy" .. m, true)
        if status == 1 then table.insert(account.Melees, m) end
    end

    local pullLever = safeInvoke(CommF, 3, "CheckTempleDoor")
    if pullLever then account.PullLever = pullLever end

    pcall(function()
        local hasV4 = Player.Character and Player.Character:FindFirstChild("RaceTransformed")
        if hasV4 then 
            account.Race.Version = 4
            -- Verifica se V4 está completo (status 5 = Full Gear, Full 5 Training Sessions)
            local upgradeStatus = safeInvoke(CommF, 3, "UpgradeRace", "Check")
            account.Race.Full = (upgradeStatus == 5)
        else
            local wenlock = safeInvoke(CommF, 3, "Wenlocktoad", "1")
            if wenlock == -2 then 
                account.Race.Version = 3
            else
                local alchemist = safeInvoke(CommF, 3, "Alchemist", "1")
                if alchemist == -2 then 
                    account.Race.Version = 2
                end
            end
            account.Race.Full = false
        end
    end)

    return HttpService:JSONEncode(account)
end

getgenv().AutoChange.MythicalFruits = {
    "Kitsune-Kitsune", "Control-Control", "Dragon-Dragon", "Yeti-Yeti", "Dough-Dough",
    "Gas-Gas", "T-Rex-T-Rex", "Tiger-Tiger", "Mammoth-Mammoth", "Spirit-Spirit",
    "Venom-Venom", "Gravity-Gravity"
}

getgenv().AutoChange.Any = function(items)
    return { _any = true, items = items }
end

getgenv().AutoChange.Skip = function(items)
    return { _skip = true, items = items }
end

getgenv().AutoChange.Exclude = function(items)
    return { _exclude = true, items = items }
end

getgenv().AutoChange.checkRequirements = function(data, requirements)
    local skipList = {}
    if requirements['Fruits'] and type(requirements['Fruits']) == "table" and requirements['Fruits']._skip then
        skipList = requirements['Fruits'].items or {}
    end
    
    for key, required in pairs(requirements) do
        local value = data[key]
        
        if key == "MythicalFruits" then
            local count = 0
            local fruits = data["Fruits"] or {}
            for _, fruit in pairs(fruits) do
                local fruitName = type(fruit) == "table" and fruit.Name or fruit
                local isMythical = table.find(getgenv().AutoChange.MythicalFruits, fruitName)
                local isSkipped = table.find(skipList, fruitName)
                if isMythical and not isSkipped then
                    count = count + 1
                end
            end
            if count < required then return false end
        elseif key == "Race" and type(required) == "table" then
            local race = data["Race"] or {}
            if required.Version and (race.Version or 0) < required.Version then return false end
            if required.Full ~= nil and race.Full ~= required.Full then return false end
            if required.Name and race.Name ~= required.Name then return false end
        elseif type(required) == "table" and required._skip then
            -- Skip é usado junto com MythicalFruits, já processado acima
        elseif type(required) == "table" and required._exclude then
            -- Exclude: se a conta tiver QUALQUER um dos itens, retorna false
            local items = required.items or {}
            for _, excludeItem in pairs(items) do
                for _, v in pairs(value or {}) do
                    local itemName = type(v) == "table" and v.Name or v
                    if itemName == excludeItem then
                        return false
                    end
                end
            end
        elseif type(required) == "number" then
            if (tonumber(value) or 0) < required then return false end
        elseif type(required) == "string" then
            local actualValue = type(value) == "table" and value.Name or value
            if actualValue ~= required then return false end
        elseif type(required) == "table" and type(value) == "table" then
            local isAny = required._any == true
            local items = isAny and required.items or required
            
            if isAny then
                local anyFound = false
                for _, req in pairs(items) do
                    if type(req) == "table" and req.Name then
                        for _, v in pairs(value) do
                            if type(v) == "table" and v.Name == req.Name then
                                local itemValue = v.Mastery or v.Count or 0
                                if itemValue >= (req.Value or 0) then anyFound = true break end
                            end
                        end
                    else
                        for _, v in pairs(value) do
                            if (type(v) == "table" and v.Name or v) == req then anyFound = true break end
                        end
                    end
                    if anyFound then break end
                end
                if not anyFound then return false end
            else
                for _, req in pairs(items) do
                    local found = false
                    if type(req) == "table" and req.Name then
                        for _, v in pairs(value) do
                            if type(v) == "table" and v.Name == req.Name then
                                local itemValue = v.Mastery or v.Count or 0
                                if itemValue >= (req.Value or 0) then found = true break end
                            end
                        end
                    else
                        for _, v in pairs(value) do
                            if (type(v) == "table" and v.Name or v) == req then found = true break end
                        end
                    end
                    if not found then return false end
                end
            end
        end
    end
    return true
end

-- Função para verificar requisitos com log detalhado
getgenv().AutoChange.checkRequirementsWithLog = function(data, requirements, filterName)
    local skipList = {}
    if requirements['Fruits'] and type(requirements['Fruits']) == "table" and requirements['Fruits']._skip then
        skipList = requirements['Fruits'].items or {}
    end
    
    local missing = {}
    
    for key, required in pairs(requirements) do
        local value = data[key]
        local passed = true
        local reason = ""
        
        if key == "MythicalFruits" then
            local count = 0
            local fruits = data["Fruits"] or {}
            for _, fruit in pairs(fruits) do
                local fruitName = type(fruit) == "table" and fruit.Name or fruit
                local isMythical = table.find(getgenv().AutoChange.MythicalFruits, fruitName)
                local isSkipped = table.find(skipList, fruitName)
                if isMythical and not isSkipped then
                    count = count + 1
                end
            end
            if count < required then 
                passed = false
                reason = "MythicalFruits: " .. count .. "/" .. required
            end
        elseif key == "Race" and type(required) == "table" then
            local race = data["Race"] or {}
            if required.Version and (race.Version or 0) < required.Version then 
                passed = false
                reason = "Race Version: " .. (race.Version or 0) .. "/" .. required.Version
            end
        elseif type(required) == "table" and required._exclude then
            local items = required.items or {}
            for _, excludeItem in pairs(items) do
                for _, v in pairs(value or {}) do
                    local itemName = type(v) == "table" and v.Name or v
                    if itemName == excludeItem then
                        passed = false
                        reason = "Exclude: tem " .. excludeItem
                        break
                    end
                end
                if not passed then break end
            end
        elseif type(required) == "number" then
            if (tonumber(value) or 0) < required then 
                passed = false
                reason = key .. ": " .. (tonumber(value) or 0) .. "/" .. required
            end
        elseif type(required) == "string" then
            local actualValue = type(value) == "table" and value.Name or value
            if actualValue ~= required then 
                passed = false
                reason = key .. ": " .. tostring(actualValue) .. " != " .. required
            end
        elseif type(required) == "table" and type(value) == "table" and not required._skip then
            local items = required._any and required.items or required
            
            for _, req in pairs(items) do
                local found = false
                if type(req) == "table" and req.Name then
                    for _, v in pairs(value) do
                        if type(v) == "table" and v.Name == req.Name then
                            local itemValue = v.Mastery or v.Count or 0
                            if itemValue >= (req.Value or 0) then 
                                found = true 
                            else
                                reason = req.Name .. " Mastery: " .. itemValue .. "/" .. (req.Value or 0)
                            end
                            break
                        end
                    end
                    if not found and reason == "" then
                        reason = "Falta: " .. req.Name
                    end
                else
                    for _, v in pairs(value) do
                        if (type(v) == "table" and v.Name or v) == req then found = true break end
                    end
                    if not found then
                        reason = "Falta: " .. tostring(req)
                    end
                end
                if not found then 
                    passed = false
                    if not required._any then break end
                elseif required._any then
                    passed = true
                    break
                end
            end
        end
        
        if not passed and reason ~= "" then
            table.insert(missing, reason)
        end
    end
    
    return #missing == 0, missing
end

getgenv().AutoChange.checkData = function(filters, debug)
    local success, data = pcall(function()
        return getgenv().AutoChange.getAccountData()
    end)
    
    if not success or not data then
        if debug then print("❌ [AutoChange] Erro ao coletar dados") end
        return false, nil, nil, nil
    end
    
    local ok, account = pcall(function()
        return game:GetService("HttpService"):JSONDecode(data)
    end)
    
    if not ok or not account then
        if debug then print("❌ [AutoChange] Erro ao decodificar dados") end
        return false, nil, nil, nil
    end

    if debug then
        print("📊 [AutoChange] Dados da conta:")
        print("   Level: " .. (account.Level or 0))
        print("   Melees: " .. table.concat(account.Melees or {}, ", "))
        local swords = {}
        for _, s in pairs(account.Swords or {}) do
            table.insert(swords, s.Name .. "(" .. (s.Mastery or 0) .. ")")
        end
        print("   Swords: " .. table.concat(swords, ", "))
        local guns = {}
        for _, g in pairs(account.Guns or {}) do
            table.insert(guns, g.Name .. "(" .. (g.Mastery or 0) .. ")")
        end
        print("   Guns: " .. table.concat(guns, ", "))
        local mats = {}
        for _, m in pairs(account.Materials or {}) do
            table.insert(mats, m.Name)
        end
        print("   Materials: " .. table.concat(mats, ", "))
        print("   Accessories: " .. table.concat(account.Accessories or {}, ", "))
    end

    for _, filter in pairs(filters) do
        local match = pcall(function()
            return getgenv().AutoChange.checkRequirements(account, filter.Requirements)
        end)
        
        if match then
            local reqMet = getgenv().AutoChange.checkRequirements(account, filter.Requirements)
            if reqMet then
                return true, filter.Folders.Input, filter.Folders.Output, filter.Name
            elseif debug then
                local _, missing = getgenv().AutoChange.checkRequirementsWithLog(account, filter.Requirements, filter.Name)
                print("❌ " .. filter.Name .. ": " .. table.concat(missing, " | "))
            end
        end
    end
    
    return false, nil, nil, nil
end

return getgenv().AutoChange
